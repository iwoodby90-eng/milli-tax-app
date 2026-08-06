from datetime import date
from tax_engine import FED_BRACKETS_2026, QBI_INCOME_LIMIT_2026, SS_WAGE_BASE_2026, STANDARD_DEDUCTION_2026, TaxProfile, calc_federal_income_tax, calc_se_tax, calc_total_tax, mileage_deduction, mileage_deduction_for_trips, mileage_rates_for_date

def test_2026_constants():
    assert FED_BRACKETS_2026["single"][0] == (0.10, 12_400)
    assert FED_BRACKETS_2026["single"][-2] == (0.35, 640_600)
    assert FED_BRACKETS_2026["married_joint"][-2] == (0.35, 768_700)
    assert FED_BRACKETS_2026["married_separate"][-2] == (0.35, 384_350)
    assert STANDARD_DEDUCTION_2026 == {"single": 16_100, "married_joint": 32_200, "married_separate": 16_100, "head_of_household": 24_150, "qualifying_widow": 32_200}
    assert QBI_INCOME_LIMIT_2026["married_joint"] == 403_500
    assert SS_WAGE_BASE_2026 == 184_500.0

def test_2026_se_and_federal_tax():
    se_tax, _ = calc_se_tax(300_000, TaxProfile(tax_year=2026))
    assert se_tax == round(184_500 * 0.124 + (300_000 * 0.9235) * 0.029, 2)
    assert calc_federal_income_tax(60_000, "single", 2026) == round(12_400 * .10 + (50_400 - 12_400) * .12 + (60_000 - 50_400) * .22, 2)
    assert calc_total_tax(100_000, 10_000, TaxProfile(home_state="TX", tax_year=2026)).federal_income_tax > 0

def test_2026_mileage_boundary():
    assert mileage_rates_for_date(date(2026, 6, 30))["business"] == 0.725
    assert mileage_rates_for_date(date(2026, 7, 1))["business"] == 0.76
    assert mileage_deduction(100, trip_date="2026-06-30", tax_year=2026)["business_deduction"] == 72.50
    assert mileage_deduction(100, trip_date="2026-07-01", tax_year=2026)["business_deduction"] == 76.00
    trips = [{"start_time": "2026-06-30T12:00:00Z", "classification": "business", "miles": 100}, {"start_time": "2026-07-01T12:00:00Z", "classification": "business", "miles": 100}]
    assert mileage_deduction_for_trips(trips, 2026)["business_deduction"] == 148.50
