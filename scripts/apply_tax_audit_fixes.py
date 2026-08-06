"""Apply deterministic tax-rule and async-test corrections."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch(path: Path, replacements: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    for old, new in replacements:
        count = text.count(old)
        if count != 1:
            raise RuntimeError(
                f"Expected one match in {path}, found {count}: {old[:100]!r}"
            )
        text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")


patch(
    ROOT / "backend" / "tax_engine.py",
    [
        (
            '    "qualifying_widow": 250_000,\n',
            '    "qualifying_widow": 200_000,\n',
        ),
        (
            '    "married_separate": [\n'
            '        (0.10, 11_925), (0.12, 48_475), (0.22, 103_350),\n'
            '        (0.24, 197_300), (0.32, 250_525), (0.35, 626_350),\n'
            '        (0.37, float("inf")),\n'
            '    ],\n',
            '    "married_separate": [\n'
            '        (0.10, 11_925), (0.12, 48_475), (0.22, 103_350),\n'
            '        (0.24, 197_300), (0.32, 250_525), (0.35, 375_800),\n'
            '        (0.37, float("inf")),\n'
            '    ],\n',
        ),
        (
            'def calc_additional_medicare(net_earnings: float, profile: TaxProfile) -> float:\n'
            '    """0.9% additional Medicare tax above filing-status threshold."""\n'
            '    threshold = ADDL_MEDICARE_THRESHOLD.get(profile.filing_status, 200_000)\n'
            '    excess = max(0.0, net_earnings * NET_EARNINGS_FACTOR - threshold)\n'
            '    return round(excess * ADDL_MEDICARE_RATE, 2)\n',
            'def calc_additional_medicare(\n'
            '    medicare_taxable_income: float,\n'
            '    profile: TaxProfile | FilingStatus,\n'
            ') -> float:\n'
            '    """Return 0.9% Additional Medicare Tax above the filing threshold.\n\n'
            '    ``medicare_taxable_income`` is the amount already subject to Medicare\n'
            '    tax (Schedule SE net earnings), not gross Schedule C profit.\n'
            '    """\n'
            '    filing_status = (\n'
            '        profile.filing_status if isinstance(profile, TaxProfile) else profile\n'
            '    )\n'
            '    threshold = ADDL_MEDICARE_THRESHOLD.get(filing_status, 200_000)\n'
            '    excess = max(0.0, float(medicare_taxable_income) - threshold)\n'
            '    return round(excess * ADDL_MEDICARE_RATE, 2)\n',
        ),
        (
            '    addl_medicare = calc_additional_medicare(net_se_income, profile)\n',
            '    addl_medicare = calc_additional_medicare(\n'
            '        net_se_income * NET_EARNINGS_FACTOR, profile\n'
            '    )\n',
        ),
    ],
)

patch(
    ROOT / "backend" / "tests" / "test_2025_tax_constants.py",
    [
        (
            '    def test_married_separate_matches_single(self):\n'
            '        assert FED_BRACKETS_2025["married_separate"] == FED_BRACKETS_2025["single"]\n',
            '    def test_married_separate_bracket_thresholds(self):\n'
            '        b = FED_BRACKETS_2025["married_separate"]\n'
            '        assert b[0] == (0.10, 11_925)\n'
            '        assert b[1] == (0.12, 48_475)\n'
            '        assert b[2] == (0.22, 103_350)\n'
            '        assert b[3] == (0.24, 197_300)\n'
            '        assert b[4] == (0.32, 250_525)\n'
            '        assert b[5] == (0.35, 375_800)\n'
            '        assert b[6] == (0.37, float("inf"))\n',
        ),
        (
            '    def test_single_50k_uses_2025_brackets(self):\n'
            '        """$50k single: 10% of $11,925 + 12% of ($50,000 − $11,925)."""\n'
            '        tax = calc_federal_income_tax(50_000, "single")\n'
            '        expected = round(11_925 * 0.10 + (50_000 - 11_925) * 0.12, 2)\n'
            '        assert tax == expected\n',
            '    def test_single_50k_uses_2025_brackets(self):\n'
            '        """$50k single spans the 10%, 12%, and 22% brackets."""\n'
            '        tax = calc_federal_income_tax(50_000, "single")\n'
            '        expected = round(\n'
            '            11_925 * 0.10\n'
            '            + (48_475 - 11_925) * 0.12\n'
            '            + (50_000 - 48_475) * 0.22,\n'
            '            2,\n'
            '        )\n'
            '        assert tax == expected\n',
        ),
    ],
)

pytest_ini = ROOT / "backend" / "pytest.ini"
pytest_ini.write_text(
    "[pytest]\n"
    "# Keep two deterministic workers while enabling native async fixtures.\n"
    "required_plugins = pytest-xdist pytest-asyncio\n"
    "addopts = -n 2 --dist loadscope\n"
    "asyncio_mode = auto\n"
    "asyncio_default_fixture_loop_scope = function\n",
    encoding="utf-8",
)

print("Applied tax and async-test corrections")
