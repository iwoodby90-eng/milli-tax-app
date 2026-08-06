"""
Tests for the 2025 IRS tax-engine constants and calculations.

Verifies that the federal brackets, standard deduction, SS wage base,
QBI thresholds, and the 37% top bracket are correct per official 2025
IRS/SSA publications.

Run with: pytest /app/backend/tests/test_2025_tax_constants.py -v
"""
import os
import sys

import pytest

sys.path.insert(0, "/app/backend")

from tax_engine import (
    TaxProfile, calc_se_tax, calc_federal_income_tax,
    calc_total_tax, calc_qbi_deduction, state_rate,
    quarterly_plan, mileage_deduction, profile_from_user,
    SE_TAX_RATE, SS_WAGE_BASE_2025, SS_RATE, MEDICARE_RATE,
    NET_EARNINGS_FACTOR, FED_BRACKETS_2025, STANDARD_DEDUCTION_2025,
    QBI_DEDUCTION_RATE, QBI_INCOME_LIMIT,
    IRS_MILEAGE_RATE_BUSINESS, IRS_MILEAGE_RATE_MEDICAL,
    IRS_MILEAGE_RATE_CHARITABLE,
)


# ============================================================================
# 2025 IRS constant correctness
# ============================================================================

class Test2025Constants:
    """Ensure the constants match official 2025 IRS/SSA figures."""

    def test_ss_wage_base_2025(self):
        assert SS_WAGE_BASE_2025 == 176_100.0

    def test_se_tax_rate(self):
        assert SE_TAX_RATE == 0.153
        assert SS_RATE == 0.124
        assert MEDICARE_RATE == 0.029

    def test_net_earnings_factor(self):
        assert NET_EARNINGS_FACTOR == 0.9235

    def test_standard_deduction_single(self):
        assert STANDARD_DEDUCTION_2025["single"] == 15_750

    def test_standard_deduction_married_joint(self):
        assert STANDARD_DEDUCTION_2025["married_joint"] == 31_500

    def test_standard_deduction_married_separate(self):
        assert STANDARD_DEDUCTION_2025["married_separate"] == 15_750

    def test_standard_deduction_head_of_household(self):
        assert STANDARD_DEDUCTION_2025["head_of_household"] == 23_625

    def test_standard_deduction_qualifying_widow(self):
        assert STANDARD_DEDUCTION_2025["qualifying_widow"] == 31_500

    def test_qbi_rate(self):
        assert QBI_DEDUCTION_RATE == 0.20

    def test_qbi_income_limit_single(self):
        assert QBI_INCOME_LIMIT["single"] == 197_300

    def test_qbi_income_limit_married_joint(self):
        assert QBI_INCOME_LIMIT["married_joint"] == 394_600

    def test_mileage_rates_2025(self):
        assert IRS_MILEAGE_RATE_BUSINESS == 0.70
        assert IRS_MILEAGE_RATE_MEDICAL == 0.21
        assert IRS_MILEAGE_RATE_CHARITABLE == 0.14


# ============================================================================
# Federal bracket structure — 7 brackets including 37% top
# ============================================================================

class Test2025FederalBrackets:
    """Verify all filing statuses have 7 brackets ending with 37%."""

    @pytest.mark.parametrize("filing_status", [
        "single", "married_joint", "married_separate",
        "head_of_household", "qualifying_widow",
    ])
    def test_has_seven_brackets(self, filing_status):
        brackets = FED_BRACKETS_2025[filing_status]
        assert len(brackets) == 7

    @pytest.mark.parametrize("filing_status", [
        "single", "married_joint", "married_separate",
        "head_of_household", "qualifying_widow",
    ])
    def test_top_bracket_is_37_percent(self, filing_status):
        brackets = FED_BRACKETS_2025[filing_status]
        assert brackets[-1][0] == 0.37
        assert brackets[-1][1] == float("inf")

    def test_single_bracket_thresholds(self):
        b = FED_BRACKETS_2025["single"]
        assert b[0] == (0.10, 11_925)
        assert b[1] == (0.12, 48_475)
        assert b[2] == (0.22, 103_350)
        assert b[3] == (0.24, 197_300)
        assert b[4] == (0.32, 250_525)
        assert b[5] == (0.35, 626_350)
        assert b[6] == (0.37, float("inf"))

    def test_married_joint_bracket_thresholds(self):
        b = FED_BRACKETS_2025["married_joint"]
        assert b[0] == (0.10, 23_850)
        assert b[1] == (0.12, 96_950)
        assert b[2] == (0.22, 206_700)
        assert b[3] == (0.24, 394_600)
        assert b[4] == (0.32, 501_050)
        assert b[5] == (0.35, 751_600)
        assert b[6] == (0.37, float("inf"))

    def test_head_of_household_bracket_thresholds(self):
        b = FED_BRACKETS_2025["head_of_household"]
        assert b[0] == (0.10, 17_000)
        assert b[1] == (0.12, 64_850)
        assert b[2] == (0.22, 103_350)
        assert b[3] == (0.24, 197_300)
        assert b[4] == (0.32, 250_500)
        assert b[5] == (0.35, 626_350)
        assert b[6] == (0.37, float("inf"))

    def test_married_separate_bracket_thresholds(self):
        b = FED_BRACKETS_2025["married_separate"]
        assert b[0] == (0.10, 11_925)
        assert b[1] == (0.12, 48_475)
        assert b[2] == (0.22, 103_350)
        assert b[3] == (0.24, 197_300)
        assert b[4] == (0.32, 250_525)
        assert b[5] == (0.35, 375_800)
        assert b[6] == (0.37, float("inf"))

    def test_qualifying_widow_matches_married_joint(self):
        assert FED_BRACKETS_2025["qualifying_widow"] == FED_BRACKETS_2025["married_joint"]


# ============================================================================
# Federal income tax calculation with 2025 brackets
# ============================================================================

class Test2025FederalIncomeTax:

    def test_single_50k_uses_2025_brackets(self):
        """$50k single spans the 10%, 12%, and 22% brackets."""
        tax = calc_federal_income_tax(50_000, "single")
        expected = round(
            11_925 * 0.10
            + (48_475 - 11_925) * 0.12
            + (50_000 - 48_475) * 0.22,
            2,
        )
        assert tax == expected

    def test_single_100k_uses_2025_brackets(self):
        """$100k single spans 10%, 12%, and into 22% bracket."""
        tax = calc_federal_income_tax(100_000, "single")
        expected = round(
            11_925 * 0.10
            + (48_475 - 11_925) * 0.12
            + (100_000 - 48_475) * 0.22,
            2,
        )
        assert tax == expected

    def test_single_700k_hits_37_percent_bracket(self):
        """$700k single should reach the 37% top bracket."""
        tax = calc_federal_income_tax(700_000, "single")
        # Manually compute
        expected = round(
            11_925 * 0.10
            + (48_475 - 11_925) * 0.12
            + (103_350 - 48_475) * 0.22
            + (197_300 - 103_350) * 0.24
            + (250_525 - 197_300) * 0.32
            + (626_350 - 250_525) * 0.35
            + (700_000 - 626_350) * 0.37,
            2,
        )
        assert tax == expected
        # Sanity: tax should be substantial
        assert tax > 200_000

    def test_married_joint_800k_hits_37_percent(self):
        """$800k MFJ should reach the 37% top bracket."""
        tax = calc_federal_income_tax(800_000, "married_joint")
        expected = round(
            23_850 * 0.10
            + (96_950 - 23_850) * 0.12
            + (206_700 - 96_950) * 0.22
            + (394_600 - 206_700) * 0.24
            + (501_050 - 394_600) * 0.32
            + (751_600 - 501_050) * 0.35
            + (800_000 - 751_600) * 0.37,
            2,
        )
        assert tax == expected

    def test_head_of_household_300k_hits_32_percent(self):
        """$300k HoH should reach the 32% bracket."""
        tax = calc_federal_income_tax(300_000, "head_of_household")
        expected = round(
            17_000 * 0.10
            + (64_850 - 17_000) * 0.12
            + (103_350 - 64_850) * 0.22
            + (197_300 - 103_350) * 0.24
            + (250_500 - 197_300) * 0.32
            + (300_000 - 250_500) * 0.35,
            2,
        )
        assert tax == expected

    def test_zero_income_zero_tax(self):
        assert calc_federal_income_tax(0, "single") == 0.0

    def test_negative_income_zero_tax(self):
        assert calc_federal_income_tax(-10_000, "single") == 0.0


# ============================================================================
# SE tax with 2025 SS wage base
# ============================================================================

class Test2025SETax:

    def test_se_tax_at_typical_gig_income(self):
        se, half = calc_se_tax(50_000, TaxProfile())
        # 50,000 * 0.9235 = 46,175 → SS on all (below 176,100)
        # SS: 46,175 * 0.124 = 5,725.70
        # Medicare: 46,175 * 0.029 = 1,339.075
        # Total: 7,064.775 → 7,064.78
        assert 6_900 < se < 7_200
        assert abs(half - se / 2) < 0.01

    def test_se_tax_caps_at_ss_wage_base(self):
        """Income above $176,100 / 0.9235 should not increase SS portion."""
        high_income = 300_000
        se_high, _ = calc_se_tax(high_income, TaxProfile())
        # Net earnings = 300,000 * 0.9235 = 277,050
        # SS tax capped: 176,100 * 0.124 = 21,836.40
        # Medicare: 277,050 * 0.029 = 8,034.45
        # Total: 29,870.85
        expected_ss = 176_100 * 0.124
        expected_medicare = round(300_000 * 0.9235 * 0.029, 2)
        expected_total = round(expected_ss + expected_medicare, 2)
        assert se_high == expected_total

    def test_se_tax_zero_when_no_income(self):
        se, half = calc_se_tax(0, TaxProfile())
        assert se == 0.0 and half == 0.0


# ============================================================================
# QBI deduction with 2025 thresholds
# ============================================================================

class Test2025QBI:

    def test_qbi_applies_below_threshold(self):
        profile = TaxProfile(filing_status="single", take_qbi=True)
        qbi = calc_qbi_deduction(50_000, 3_500, profile)
        # (50,000 − 3,500) * 0.20 = 9,300
        assert qbi == 9_300.0

    def test_qbi_zero_above_threshold_single(self):
        profile = TaxProfile(filing_status="single", take_qbi=True)
        qbi = calc_qbi_deduction(250_000, 10_000, profile)
        assert qbi == 0.0  # phased out above $197,300

    def test_qbi_zero_above_threshold_married_joint(self):
        profile = TaxProfile(filing_status="married_joint", take_qbi=True)
        qbi = calc_qbi_deduction(500_000, 20_000, profile)
        assert qbi == 0.0  # phased out above $394,600

    def test_qbi_zero_when_disabled(self):
        profile = TaxProfile(take_qbi=False)
        assert calc_qbi_deduction(50_000, 3_500, profile) == 0.0


# ============================================================================
# Full calc_total_tax integration with 2025 values
# ============================================================================

class Test2025TotalTax:

    def test_low_income_no_tax_state(self):
        profile = TaxProfile(home_state="TX")
        result = calc_total_tax(20_000, 3_000, profile)
        assert result.se_tax > 0
        assert result.state_income_tax == 0.0
        assert result.effective_rate < 0.25

    def test_high_income_california(self):
        profile = TaxProfile(home_state="CA")
        result = calc_total_tax(300_000, 20_000, profile)
        assert result.federal_income_tax > 0
        assert result.state_income_tax > 0
        assert result.effective_rate > 0.25

    def test_37_percent_bracket_reflected_in_total(self):
        """Very high income should produce a high effective rate (37% bracket)."""
        profile = TaxProfile(home_state="TX")
        result = calc_total_tax(800_000, 30_000, profile)
        # Federal taxable income should be high enough to hit 37%
        assert result.federal_taxable_income > 626_350
        assert result.effective_rate > 0.30


# ============================================================================
# Mileage deduction with 2025 rates
# ============================================================================

class Test2025Mileage:

    def test_business_mileage(self):
        result = mileage_deduction(1000)
        assert result["business_deduction"] == 700.0  # 1000 * 0.70

    def test_all_mileage_types(self):
        result = mileage_deduction(1000, 500, 200)
        assert result["business_deduction"] == 700.0
        assert result["medical_deduction"] == 105.0   # 500 * 0.21
        assert result["charitable_deduction"] == 28.0  # 200 * 0.14
        assert result["total_deduction"] == 833.0