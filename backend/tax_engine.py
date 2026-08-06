"""
Milli Tax Engine
================

Dedicated tax calculation module. All tax logic lives here so brackets, rates,
and jurisdiction rules can evolve independently of the rest of the application.

Everything is a **pure function** — no HTTP, no DB — so the engine is trivially
unit-testable and swappable when we plug in a real provider (Avalara, TaxJar,
Corvee, Intuit ProTax, etc.) behind the ``TaxCalculator`` integration interface.

Numbers reflect current published US federal rates. Update the constants when
the IRS issues new schedules.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from typing import Iterable, Literal, Optional


# ============================================================================
# Constants — 2025 IRS reference (adjust yearly)
# ============================================================================

FilingStatus = Literal["single", "married_joint", "married_separate",
                       "head_of_household", "qualifying_widow"]
BusinessType = Literal["sole_prop", "llc", "s_corp", "partnership"]

# --- Self-Employment tax (Schedule SE) --------------------------------------
SE_TAX_RATE = 0.153               # 12.4% SS + 2.9% Medicare
SS_WAGE_BASE_2025 = 176_100.0
SS_RATE = 0.124
MEDICARE_RATE = 0.029
ADDL_MEDICARE_RATE = 0.009        # kicks in at high income
ADDL_MEDICARE_THRESHOLD = {
    "single": 200_000,
    "married_joint": 250_000,
    "married_separate": 125_000,
    "head_of_household": 200_000,
    "qualifying_widow": 200_000,
}
NET_EARNINGS_FACTOR = 0.9235     # 92.35% of net SE income is subject to SE tax

# --- Federal income tax brackets 2025 (marginal) ----------------------------
FED_BRACKETS_2025: dict[FilingStatus, list[tuple[float, float]]] = {
    "single": [
        (0.10, 11_925), (0.12, 48_475), (0.22, 103_350),
        (0.24, 197_300), (0.32, 250_525), (0.35, 626_350),
        (0.37, float("inf")),
    ],
    "married_joint": [
        (0.10, 23_850), (0.12, 96_950), (0.22, 206_700),
        (0.24, 394_600), (0.32, 501_050), (0.35, 751_600),
        (0.37, float("inf")),
    ],
    "married_separate": [
        (0.10, 11_925), (0.12, 48_475), (0.22, 103_350),
        (0.24, 197_300), (0.32, 250_525), (0.35, 375_800),
        (0.37, float("inf")),
    ],
    "head_of_household": [
        (0.10, 17_000), (0.12, 64_850), (0.22, 103_350),
        (0.24, 197_300), (0.32, 250_500), (0.35, 626_350),
        (0.37, float("inf")),
    ],
    "qualifying_widow": [
        (0.10, 23_850), (0.12, 96_950), (0.22, 206_700),
        (0.24, 394_600), (0.32, 501_050), (0.35, 751_600),
        (0.37, float("inf")),
    ],
}

# Standard deduction 2025
STANDARD_DEDUCTION_2025: dict[FilingStatus, float] = {
    "single": 15_750,
    "married_joint": 31_500,
    "married_separate": 15_750,
    "head_of_household": 23_625,
    "qualifying_widow": 31_500,
}

# QBI (Sec 199A) — pass-through deduction. Simplified: 20% of qualified biz
# income up to threshold. For gig income + sole prop / LLC, generally full 20%.
QBI_DEDUCTION_RATE = 0.20
QBI_INCOME_LIMIT = {
    "single": 197_300,
    "married_joint": 394_600,
    "married_separate": 197_300,
    "head_of_household": 197_300,
    "qualifying_widow": 394_600,
}

# --- State effective rates (simplified single-bracket) ---------------------
STATE_EFFECTIVE_RATES: dict[str, float] = {
    # 9 no-income-tax states
    "TX": 0.0, "FL": 0.0, "WA": 0.0, "TN": 0.0, "NV": 0.0,
    "SD": 0.0, "WY": 0.0, "AK": 0.0, "NH": 0.0,
    # Flat-tax states (2025)
    "CO": 0.044, "IL": 0.0495, "IN": 0.0315, "KY": 0.045,
    "MI": 0.0425, "NC": 0.0475, "PA": 0.0307, "UT": 0.0485,
    # Effective average for progressive states (rough)
    "CA": 0.093, "NY": 0.0685, "OR": 0.0875, "MA": 0.05,
    "NJ": 0.0637, "VA": 0.0575, "OH": 0.0399, "MN": 0.0785,
    "WI": 0.053, "MO": 0.054, "AZ": 0.025, "AR": 0.044,
    "GA": 0.0539, "IA": 0.057, "ID": 0.058, "KS": 0.057,
    "LA": 0.0425, "ME": 0.0715, "MD": 0.0575, "MS": 0.05,
    "MT": 0.059, "NE": 0.0684, "NM": 0.049, "ND": 0.049,
    "OK": 0.0475, "RI": 0.0599, "VT": 0.0875, "WV": 0.065,
    "CT": 0.0699, "DE": 0.066, "HI": 0.079, "SC": 0.0699,
    "DC": 0.0925, "AL": 0.05,
}
DEFAULT_STATE_RATE = 0.05

# --- Quarterly due dates (US calendar-year taxpayer) ------------------------
QUARTERLY_DUE_DATES = [
    (4, 15, "Q1"), (6, 15, "Q2"), (9, 15, "Q3"), (1, 15, "Q4"),
    # Note: Q4 is Jan 15 of *following* year
]

# --- Mileage (2025 IRS standard mileage rates) ------------------------------
IRS_MILEAGE_RATE_BUSINESS = 0.70
IRS_MILEAGE_RATE_MEDICAL = 0.21
IRS_MILEAGE_RATE_CHARITABLE = 0.14


# ============================================================================
# Data classes
# ============================================================================

@dataclass(frozen=True)
class TaxProfile:
    """User's tax profile — used for every tax calculation."""
    filing_status: FilingStatus = "single"
    business_type: BusinessType = "sole_prop"
    home_state: str = "TX"
    additional_states: tuple[str, ...] = ()
    dependents: int = 0
    additional_income: float = 0.0          # W-2, interest, etc.
    additional_withholding: float = 0.0     # already paid via W-2, prior payments
    take_qbi: bool = True


@dataclass
class TaxBreakdown:
    """Result of a full tax calculation for a given income + profile."""
    gross_income: float
    net_earnings_from_se: float
    se_tax: float
    se_tax_deductible_half: float
    federal_taxable_income: float
    federal_income_tax: float
    state_income_tax: float
    additional_medicare_tax: float
    qbi_deduction: float
    total_tax: float
    effective_rate: float
    breakdown_by_state: dict[str, float] = field(default_factory=dict)


@dataclass
class QuarterlyPlan:
    year: int
    annual_estimated_tax: float
    quarterly_amount: float
    already_paid: float
    remaining_owed: float
    quarters: list[dict]


# ============================================================================
# Core calculations
# ============================================================================

def state_rate(state_code: str) -> float:
    """Effective state income-tax rate. Returns 0 for no-tax states."""
    return STATE_EFFECTIVE_RATES.get((state_code or "").upper(), DEFAULT_STATE_RATE)


def calc_se_tax(net_se_income: float, profile: TaxProfile) -> tuple[float, float]:
    """Return (se_tax, deductible_half). Applies 92.35% factor + SS wage base."""
    if net_se_income <= 0:
        return 0.0, 0.0
    net_earnings = net_se_income * NET_EARNINGS_FACTOR
    ss_wages_taxable = min(net_earnings, SS_WAGE_BASE_2025)
    ss_tax = ss_wages_taxable * SS_RATE
    medicare_tax = net_earnings * MEDICARE_RATE
    se_tax = round(ss_tax + medicare_tax, 2)
    return se_tax, round(se_tax / 2, 2)


def calc_federal_income_tax(taxable_income: float, filing_status: FilingStatus) -> float:
    """Apply marginal 2025 federal brackets."""
    if taxable_income <= 0:
        return 0.0
    brackets = FED_BRACKETS_2025.get(filing_status, FED_BRACKETS_2025["single"])
    tax = 0.0
    prev_limit = 0.0
    for rate, top in brackets:
        if taxable_income <= top:
            tax += (taxable_income - prev_limit) * rate
            break
        tax += (top - prev_limit) * rate
        prev_limit = top
    return round(tax, 2)


def calc_additional_medicare(
    medicare_taxable_income: float,
    profile: TaxProfile | FilingStatus,
) -> float:
    """Return 0.9% Additional Medicare Tax above the filing threshold.

    ``medicare_taxable_income`` is the amount already subject to Medicare
    tax (Schedule SE net earnings), not gross Schedule C profit.
    """
    filing_status = (
        profile.filing_status if isinstance(profile, TaxProfile) else profile
    )
    threshold = ADDL_MEDICARE_THRESHOLD.get(filing_status, 200_000)
    excess = max(0.0, float(medicare_taxable_income) - threshold)
    return round(excess * ADDL_MEDICARE_RATE, 2)


def calc_qbi_deduction(net_se_income: float, se_tax_half: float,
                      profile: TaxProfile) -> float:
    """Simplified §199A: 20% of net SE income minus half SE tax."""
    if not profile.take_qbi or net_se_income <= 0:
        return 0.0
    limit = QBI_INCOME_LIMIT.get(profile.filing_status, 197_300)
    if net_se_income > limit:
        # Higher-income phaseout applies; keep it simple and return 0.
        return 0.0
    qbi_base = max(0.0, net_se_income - se_tax_half)
    return round(qbi_base * QBI_DEDUCTION_RATE, 2)


def calc_total_tax(gross_se_income: float, deductions: float,
                   profile: TaxProfile) -> TaxBreakdown:
    """Compute the full tax picture for a self-employed individual.

    ``gross_se_income`` is total gig receipts. ``deductions`` should include
    mileage deduction + expenses + any other Schedule C write-offs. The
    engine subtracts them to arrive at *net* SE income.
    """
    gross_se_income = max(0.0, float(gross_se_income))
    deductions = max(0.0, float(deductions))
    net_se_income = max(0.0, gross_se_income - deductions)

    # 1) SE tax + half-deduction
    se_tax, se_tax_half = calc_se_tax(net_se_income, profile)

    # 2) QBI deduction (simplified)
    qbi = calc_qbi_deduction(net_se_income, se_tax_half, profile)

    # 3) Federal taxable income = net SE + other income − std deduction
    #    − half SE tax − QBI deduction
    std = STANDARD_DEDUCTION_2025.get(profile.filing_status,
                                      STANDARD_DEDUCTION_2025["single"])
    federal_taxable = max(
        0.0,
        net_se_income + profile.additional_income - std - se_tax_half - qbi,
    )
    federal_income_tax = calc_federal_income_tax(federal_taxable,
                                                  profile.filing_status)

    # 4) Additional Medicare (above threshold)
    addl_medicare = calc_additional_medicare(
        net_se_income * NET_EARNINGS_FACTOR, profile
    )

    # 5) State tax — home state on net SE income (multi-state prorate later)
    home_rate = state_rate(profile.home_state)
    state_tax_amount = round(net_se_income * home_rate, 2)
    by_state = {profile.home_state.upper(): state_tax_amount}
    for st in profile.additional_states:
        by_state[st.upper()] = 0.0  # placeholder for multi-state proration

    # 6) Total
    total = round(
        se_tax + federal_income_tax + state_tax_amount + addl_medicare
        - profile.additional_withholding,
        2,
    )
    total = max(0.0, total)
    effective = round(total / gross_se_income, 4) if gross_se_income else 0.0

    return TaxBreakdown(
        gross_income=round(gross_se_income, 2),
        net_earnings_from_se=round(net_se_income, 2),
        se_tax=se_tax,
        se_tax_deductible_half=se_tax_half,
        federal_taxable_income=round(federal_taxable, 2),
        federal_income_tax=federal_income_tax,
        state_income_tax=state_tax_amount,
        additional_medicare_tax=addl_medicare,
        qbi_deduction=qbi,
        total_tax=total,
        effective_rate=effective,
        breakdown_by_state=by_state,
    )


def per_payout_reserve_rate(profile: TaxProfile,
                             projected_annual_gross: float = 0.0,
                             projected_annual_deductions: float = 0.0) -> dict:
    """Return the effective reserve rate to apply to a single payout.

    Uses a projected-annual approach when historical data is available;
    falls back to a conservative *marginal* rate for brand-new users.
    """
    if projected_annual_gross > 0:
        breakdown = calc_total_tax(projected_annual_gross,
                                   projected_annual_deductions, profile)
        return {
            "federal": round(breakdown.federal_income_tax / projected_annual_gross, 4),
            "se": round(breakdown.se_tax / projected_annual_gross, 4),
            "state": round(breakdown.state_income_tax / projected_annual_gross, 4),
            "total": max(0.0, min(0.45, breakdown.effective_rate)),
            "source": "projected_annual",
        }
    # Cold-start: conservative brackets
    fed = 0.12
    se = SE_TAX_RATE
    st = state_rate(profile.home_state)
    total = min(0.40, fed + se + st)
    return {"federal": fed, "se": se, "state": st, "total": total,
            "source": "cold_start"}


def quarterly_plan(year: int, profile: TaxProfile, ytd_gross: float,
                    ytd_deductions: float,
                    quarterly_payments_made: Iterable[dict],
                    today: Optional[date] = None) -> QuarterlyPlan:
    """Compute the four-quarter plan for the year."""
    today = today or date.today()
    # Project full-year based on YTD run-rate.
    day_of_year = today.timetuple().tm_yday
    daily_rate = ytd_gross / day_of_year if day_of_year > 0 else 0
    projected_annual = daily_rate * 365
    projected_deductions = (ytd_deductions / max(day_of_year, 1)) * 365

    breakdown = calc_total_tax(projected_annual, projected_deductions, profile)
    per_q = round(breakdown.total_tax / 4, 2)

    already_paid = sum((p.get("amount") or 0.0) for p in quarterly_payments_made
                       if p.get("year") == year)
    quarters = []
    paid_by_q = {p.get("period"): p
                 for p in quarterly_payments_made
                 if p.get("year") == year}
    for m, d, label in QUARTERLY_DUE_DATES:
        due_year = year + (1 if label == "Q4" else 0)
        due = date(due_year, m, d)
        paid = paid_by_q.get(label)
        quarters.append({
            "period": label,
            "due_date": due.isoformat(),
            "amount": per_q,
            "paid": bool(paid),
            "payment": paid,
            "days_until": (due - today).days,
        })
    return QuarterlyPlan(
        year=year,
        annual_estimated_tax=breakdown.total_tax,
        quarterly_amount=per_q,
        already_paid=round(already_paid, 2),
        remaining_owed=round(max(0.0, breakdown.total_tax - already_paid), 2),
        quarters=quarters,
    )


def mileage_deduction(business_miles: float, medical_miles: float = 0.0,
                      charitable_miles: float = 0.0) -> dict:
    """IRS standard mileage deduction (2025 rates)."""
    biz = round(business_miles * IRS_MILEAGE_RATE_BUSINESS, 2)
    med = round(medical_miles * IRS_MILEAGE_RATE_MEDICAL, 2)
    cha = round(charitable_miles * IRS_MILEAGE_RATE_CHARITABLE, 2)
    return {
        "business_miles": round(business_miles, 2),
        "medical_miles": round(medical_miles, 2),
        "charitable_miles": round(charitable_miles, 2),
        "business_deduction": biz,
        "medical_deduction": med,
        "charitable_deduction": cha,
        "total_deduction": round(biz + med + cha, 2),
        "rates": {
            "business": IRS_MILEAGE_RATE_BUSINESS,
            "medical": IRS_MILEAGE_RATE_MEDICAL,
            "charitable": IRS_MILEAGE_RATE_CHARITABLE,
        },
    }


# ============================================================================
# Helpers for the Autopilot engine (dict-in / dict-out)
# ============================================================================

def profile_from_user(user: dict) -> TaxProfile:
    """Build a TaxProfile from a user document (safe defaults)."""
    return TaxProfile(
        filing_status=(user.get("filing_status") or "single"),
        business_type=(user.get("business_type") or "sole_prop"),
        home_state=(user.get("state") or "TX"),
        additional_states=tuple(user.get("additional_states") or []),
        dependents=int(user.get("dependents") or 0),
        additional_income=float(user.get("additional_income") or 0.0),
        additional_withholding=float(user.get("additional_withholding") or 0.0),
        take_qbi=bool(user.get("take_qbi", True)),
    )