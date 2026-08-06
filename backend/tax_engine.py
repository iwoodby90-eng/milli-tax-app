"""Milli tax and mileage calculation engine.

Pure functions only: no HTTP and no database access. Federal calculations are
explicitly keyed by tax year so historical reports remain reproducible.
"""
from __future__ import annotations

from dataclasses import dataclass, field, replace
from datetime import date
from typing import Iterable, Literal, Optional

FilingStatus = Literal[
    "single",
    "married_joint",
    "married_separate",
    "head_of_household",
    "qualifying_widow",
]
BusinessType = Literal["sole_prop", "llc", "s_corp", "partnership"]

SUPPORTED_TAX_YEARS = (2025, 2026)

SE_TAX_RATE = 0.153
SS_RATE = 0.124
MEDICARE_RATE = 0.029
ADDL_MEDICARE_RATE = 0.009
NET_EARNINGS_FACTOR = 0.9235
SS_WAGE_BASE_2025 = 176_100.0
SS_WAGE_BASE_2026 = 184_500.0

ADDL_MEDICARE_THRESHOLD: dict[FilingStatus, float] = {
    "single": 200_000,
    "married_joint": 250_000,
    "married_separate": 125_000,
    "head_of_household": 200_000,
    "qualifying_widow": 200_000,
}

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

FED_BRACKETS_2026: dict[FilingStatus, list[tuple[float, float]]] = {
    "single": [
        (0.10, 12_400), (0.12, 50_400), (0.22, 105_700),
        (0.24, 201_775), (0.32, 256_225), (0.35, 640_600),
        (0.37, float("inf")),
    ],
    "married_joint": [
        (0.10, 24_800), (0.12, 100_800), (0.22, 211_400),
        (0.24, 403_550), (0.32, 512_450), (0.35, 768_700),
        (0.37, float("inf")),
    ],
    "married_separate": [
        (0.10, 12_400), (0.12, 50_400), (0.22, 105_700),
        (0.24, 201_775), (0.32, 256_225), (0.35, 384_350),
        (0.37, float("inf")),
    ],
    "head_of_household": [
        (0.10, 17_700), (0.12, 67_450), (0.22, 105_700),
        (0.24, 201_750), (0.32, 256_200), (0.35, 640_600),
        (0.37, float("inf")),
    ],
    "qualifying_widow": [
        (0.10, 24_800), (0.12, 100_800), (0.22, 211_400),
        (0.24, 403_550), (0.32, 512_450), (0.35, 768_700),
        (0.37, float("inf")),
    ],
}

STANDARD_DEDUCTION_2025: dict[FilingStatus, float] = {
    "single": 15_750,
    "married_joint": 31_500,
    "married_separate": 15_750,
    "head_of_household": 23_625,
    "qualifying_widow": 31_500,
}
STANDARD_DEDUCTION_2026: dict[FilingStatus, float] = {
    "single": 16_100,
    "married_joint": 32_200,
    "married_separate": 16_100,
    "head_of_household": 24_150,
    "qualifying_widow": 32_200,
}

QBI_DEDUCTION_RATE = 0.20
QBI_INCOME_LIMIT_2025: dict[FilingStatus, float] = {
    "single": 197_300,
    "married_joint": 394_600,
    "married_separate": 197_300,
    "head_of_household": 197_300,
    "qualifying_widow": 394_600,
}
QBI_INCOME_LIMIT_2026: dict[FilingStatus, float] = {
    "single": 201_750,
    "married_joint": 403_500,
    "married_separate": 201_775,
    "head_of_household": 201_750,
    "qualifying_widow": 403_500,
}
QBI_INCOME_LIMIT = QBI_INCOME_LIMIT_2025

STATE_EFFECTIVE_RATES: dict[str, float] = {
    "TX": 0.0, "FL": 0.0, "WA": 0.0, "TN": 0.0, "NV": 0.0,
    "SD": 0.0, "WY": 0.0, "AK": 0.0, "NH": 0.0,
    "CO": 0.044, "IL": 0.0495, "IN": 0.0315, "KY": 0.045,
    "MI": 0.0425, "NC": 0.0475, "PA": 0.0307, "UT": 0.0485,
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

QUARTERLY_DUE_DATES = [
    (4, 15, "Q1"), (6, 15, "Q2"), (9, 15, "Q3"), (1, 15, "Q4"),
]

IRS_MILEAGE_RATE_BUSINESS = 0.70
IRS_MILEAGE_RATE_MEDICAL = 0.21
IRS_MILEAGE_RATE_CHARITABLE = 0.14
IRS_MILEAGE_RATES = (
    (date(2025, 1, 1), date(2025, 12, 31), {
        "business": 0.70, "medical": 0.21, "charitable": 0.14,
    }),
    (date(2026, 1, 1), date(2026, 6, 30), {
        "business": 0.725, "medical": 0.205, "charitable": 0.14,
    }),
    (date(2026, 7, 1), date(2026, 12, 31), {
        "business": 0.76, "medical": 0.235, "charitable": 0.14,
    }),
)


@dataclass(frozen=True)
class TaxProfile:
    filing_status: FilingStatus = "single"
    business_type: BusinessType = "sole_prop"
    home_state: str = "TX"
    additional_states: tuple[str, ...] = ()
    dependents: int = 0
    additional_income: float = 0.0
    additional_withholding: float = 0.0
    take_qbi: bool = True
    tax_year: int = 2025


@dataclass
class TaxBreakdown:
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


def _supported_tax_year(tax_year: int) -> int:
    year = int(tax_year)
    if year not in SUPPORTED_TAX_YEARS:
        raise ValueError(f"Unsupported tax year: {year}")
    return year


def federal_brackets_for_year(tax_year: int):
    return FED_BRACKETS_2026 if _supported_tax_year(tax_year) == 2026 else FED_BRACKETS_2025


def standard_deduction_for_year(tax_year: int):
    return STANDARD_DEDUCTION_2026 if _supported_tax_year(tax_year) == 2026 else STANDARD_DEDUCTION_2025


def ss_wage_base_for_year(tax_year: int) -> float:
    return SS_WAGE_BASE_2026 if _supported_tax_year(tax_year) == 2026 else SS_WAGE_BASE_2025


def qbi_income_limit_for_year(tax_year: int):
    return QBI_INCOME_LIMIT_2026 if _supported_tax_year(tax_year) == 2026 else QBI_INCOME_LIMIT_2025


def state_rate(state_code: str) -> float:
    return STATE_EFFECTIVE_RATES.get((state_code or "").upper(), DEFAULT_STATE_RATE)


def _coerce_date(value: date | str | None, default_year: int = 2025) -> date:
    if isinstance(value, date):
        return value
    if isinstance(value, str) and value:
        try:
            return date.fromisoformat(value[:10])
        except ValueError:
            pass
    return date(_supported_tax_year(default_year), 1, 1)


def mileage_rates_for_date(value: date | str | None, default_year: int = 2025) -> dict[str, float]:
    trip_date = _coerce_date(value, default_year)
    for start, end, rates in IRS_MILEAGE_RATES:
        if start <= trip_date <= end:
            return dict(rates)
    raise ValueError(f"Unsupported mileage date: {trip_date.isoformat()}")


def mileage_rate_for_date(
    value: date | str | None,
    classification: str = "business",
    default_year: int = 2025,
) -> float:
    return mileage_rates_for_date(value, default_year).get(classification, 0.0)


def calc_se_tax(net_se_income: float, profile: TaxProfile) -> tuple[float, float]:
    if net_se_income <= 0:
        return 0.0, 0.0
    net_earnings = net_se_income * NET_EARNINGS_FACTOR
    ss_wages_taxable = min(net_earnings, ss_wage_base_for_year(profile.tax_year))
    ss_tax = ss_wages_taxable * SS_RATE
    medicare_tax = net_earnings * MEDICARE_RATE
    se_tax = round(ss_tax + medicare_tax, 2)
    return se_tax, round(se_tax / 2, 2)


def calc_federal_income_tax(
    taxable_income: float,
    filing_status: FilingStatus,
    tax_year: int = 2025,
) -> float:
    if taxable_income <= 0:
        return 0.0
    table = federal_brackets_for_year(tax_year)
    brackets = table.get(filing_status, table["single"])
    tax = 0.0
    previous_limit = 0.0
    for rate, top in brackets:
        if taxable_income <= top:
            tax += (taxable_income - previous_limit) * rate
            break
        tax += (top - previous_limit) * rate
        previous_limit = top
    return round(tax, 2)


def calc_additional_medicare(
    medicare_taxable_income: float,
    profile: TaxProfile | FilingStatus,
) -> float:
    filing_status = profile.filing_status if isinstance(profile, TaxProfile) else profile
    threshold = ADDL_MEDICARE_THRESHOLD.get(filing_status, 200_000)
    return round(max(0.0, float(medicare_taxable_income) - threshold) * ADDL_MEDICARE_RATE, 2)


def calc_qbi_deduction(
    net_se_income: float,
    se_tax_half: float,
    profile: TaxProfile,
) -> float:
    if not profile.take_qbi or net_se_income <= 0:
        return 0.0
    limits = qbi_income_limit_for_year(profile.tax_year)
    if net_se_income > limits.get(profile.filing_status, limits["single"]):
        return 0.0
    return round(max(0.0, net_se_income - se_tax_half) * QBI_DEDUCTION_RATE, 2)


def calc_total_tax(
    gross_se_income: float,
    deductions: float,
    profile: TaxProfile,
) -> TaxBreakdown:
    _supported_tax_year(profile.tax_year)
    gross_se_income = max(0.0, float(gross_se_income))
    deductions = max(0.0, float(deductions))
    net_se_income = max(0.0, gross_se_income - deductions)

    se_tax, se_tax_half = calc_se_tax(net_se_income, profile)
    qbi = calc_qbi_deduction(net_se_income, se_tax_half, profile)
    deduction_table = standard_deduction_for_year(profile.tax_year)
    standard_deduction = deduction_table.get(profile.filing_status, deduction_table["single"])
    federal_taxable = max(
        0.0,
        net_se_income
        + profile.additional_income
        - standard_deduction
        - se_tax_half
        - qbi,
    )
    federal_income_tax = calc_federal_income_tax(
        federal_taxable,
        profile.filing_status,
        profile.tax_year,
    )
    additional_medicare = calc_additional_medicare(
        net_se_income * NET_EARNINGS_FACTOR,
        profile,
    )

    state_tax_amount = round(net_se_income * state_rate(profile.home_state), 2)
    by_state = {profile.home_state.upper(): state_tax_amount}
    for additional_state in profile.additional_states:
        by_state[additional_state.upper()] = 0.0

    total = max(
        0.0,
        round(
            se_tax
            + federal_income_tax
            + state_tax_amount
            + additional_medicare
            - profile.additional_withholding,
            2,
        ),
    )
    effective_rate = round(total / gross_se_income, 4) if gross_se_income else 0.0

    return TaxBreakdown(
        gross_income=round(gross_se_income, 2),
        net_earnings_from_se=round(net_se_income, 2),
        se_tax=se_tax,
        se_tax_deductible_half=se_tax_half,
        federal_taxable_income=round(federal_taxable, 2),
        federal_income_tax=federal_income_tax,
        state_income_tax=state_tax_amount,
        additional_medicare_tax=additional_medicare,
        qbi_deduction=qbi,
        total_tax=total,
        effective_rate=effective_rate,
        breakdown_by_state=by_state,
    )


def per_payout_reserve_rate(
    profile: TaxProfile,
    projected_annual_gross: float = 0.0,
    projected_annual_deductions: float = 0.0,
) -> dict:
    if projected_annual_gross > 0:
        breakdown = calc_total_tax(
            projected_annual_gross,
            projected_annual_deductions,
            profile,
        )
        return {
            "federal": round(breakdown.federal_income_tax / projected_annual_gross, 4),
            "se": round(breakdown.se_tax / projected_annual_gross, 4),
            "state": round(breakdown.state_income_tax / projected_annual_gross, 4),
            "total": max(0.0, min(0.45, breakdown.effective_rate)),
            "source": "projected_annual",
        }

    federal = 0.12
    self_employment = SE_TAX_RATE
    state = state_rate(profile.home_state)
    return {
        "federal": federal,
        "se": self_employment,
        "state": state,
        "total": min(0.40, federal + self_employment + state),
        "source": "cold_start",
    }


def quarterly_plan(
    year: int,
    profile: TaxProfile,
    ytd_gross: float,
    ytd_deductions: float,
    quarterly_payments_made: Iterable[dict],
    today: Optional[date] = None,
) -> QuarterlyPlan:
    year = _supported_tax_year(year)
    today = today or date.today()
    day_of_year = max(today.timetuple().tm_yday, 1)
    projected_annual = (ytd_gross / day_of_year) * 365
    projected_deductions = (ytd_deductions / day_of_year) * 365
    breakdown = calc_total_tax(
        projected_annual,
        projected_deductions,
        replace(profile, tax_year=year),
    )
    per_quarter = round(breakdown.total_tax / 4, 2)

    payments = [payment for payment in quarterly_payments_made if payment.get("year") == year]
    already_paid = sum(float(payment.get("amount") or 0.0) for payment in payments)
    paid_by_quarter = {payment.get("period"): payment for payment in payments}
    quarters = []
    for month, day, label in QUARTERLY_DUE_DATES:
        due_year = year + (1 if label == "Q4" else 0)
        due = date(due_year, month, day)
        payment = paid_by_quarter.get(label)
        quarters.append({
            "period": label,
            "due_date": due.isoformat(),
            "amount": per_quarter,
            "paid": bool(payment),
            "payment": payment,
            "days_until": (due - today).days,
        })

    return QuarterlyPlan(
        year=year,
        annual_estimated_tax=breakdown.total_tax,
        quarterly_amount=per_quarter,
        already_paid=round(already_paid, 2),
        remaining_owed=round(max(0.0, breakdown.total_tax - already_paid), 2),
        quarters=quarters,
    )


def mileage_deduction(
    business_miles: float,
    medical_miles: float = 0.0,
    charitable_miles: float = 0.0,
    trip_date: date | str | None = None,
    tax_year: int = 2025,
) -> dict:
    rates = mileage_rates_for_date(trip_date, tax_year)
    business = round(max(0.0, business_miles) * rates["business"], 2)
    medical = round(max(0.0, medical_miles) * rates["medical"], 2)
    charitable = round(max(0.0, charitable_miles) * rates["charitable"], 2)
    return {
        "business_miles": round(max(0.0, business_miles), 2),
        "medical_miles": round(max(0.0, medical_miles), 2),
        "charitable_miles": round(max(0.0, charitable_miles), 2),
        "business_deduction": business,
        "medical_deduction": medical,
        "charitable_deduction": charitable,
        "total_deduction": round(business + medical + charitable, 2),
        "rates": rates,
    }


def mileage_deduction_for_trips(trips: Iterable[dict], default_year: int) -> dict:
    default_year = _supported_tax_year(default_year)
    miles = {"business": 0.0, "medical": 0.0, "charitable": 0.0}
    deductions = {"business": 0.0, "medical": 0.0, "charitable": 0.0}
    periods: dict[tuple[str, float], dict] = {}

    for trip in trips:
        classification = trip.get("classification")
        if not classification:
            classification = {
                "delivery": "business",
                "rideshare": "business",
                "client_meeting": "business",
                "medical": "medical",
                "charitable": "charitable",
            }.get(trip.get("purpose"), "needs_review")
        if classification not in miles:
            continue

        trip_miles = max(0.0, float(trip.get("miles") or 0.0))
        raw_date = trip.get("start_time") or trip.get("date") or trip.get("created_at")
        trip_date = _coerce_date(raw_date, default_year)
        rates = mileage_rates_for_date(trip_date, default_year)
        rate = rates[classification]
        miles[classification] += trip_miles
        deductions[classification] += trip_miles * rate
        periods[(trip_date.isoformat(), rate)] = {
            "date": trip_date.isoformat(),
            "classification": classification,
            "rate": rate,
        }

    return {
        "business_miles": round(miles["business"], 2),
        "medical_miles": round(miles["medical"], 2),
        "charitable_miles": round(miles["charitable"], 2),
        "business_deduction": round(deductions["business"], 2),
        "medical_deduction": round(deductions["medical"], 2),
        "charitable_deduction": round(deductions["charitable"], 2),
        "total_deduction": round(sum(deductions.values()), 2),
        "rate_periods": list(periods.values()),
    }


def profile_from_user(user: dict) -> TaxProfile:
    return TaxProfile(
        filing_status=(user.get("filing_status") or "single"),
        business_type=(user.get("business_type") or "sole_prop"),
        home_state=(user.get("state") or "TX"),
        additional_states=tuple(user.get("additional_states") or []),
        dependents=int(user.get("dependents") or 0),
        additional_income=float(user.get("additional_income") or 0.0),
        additional_withholding=float(user.get("additional_withholding") or 0.0),
        take_qbi=bool(user.get("take_qbi", True)),
        tax_year=int(user.get("tax_year") or date.today().year),
    )
