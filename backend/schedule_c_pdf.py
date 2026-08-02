"""
Milli — IRS-Ready Schedule C + Schedule SE PDF generator.

Produces a preparer-ready PDF that mirrors the layout of the actual IRS
forms (Schedule C — Profit or Loss From Business, Schedule SE —
Self-Employment Tax) using the numbers Milli already computed from
deposits, expenses, and mileage. Elite users can hand this directly to a
CPA, upload it as an attachment in FreeTaxUSA / TurboTax / H&R Block, or
mail it with Form 1040.

No third-party e-file API needed.
"""
from datetime import datetime
from io import BytesIO
from typing import Any

from reportlab.lib.colors import HexColor, black, white
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
from reportlab.platypus import Table, TableStyle

CYAN = HexColor("#00A5C0")
INK  = HexColor("#0A0C10")
GREY = HexColor("#586170")
LINE = HexColor("#BFC6CE")


def _fmt_money(n: float) -> str:
    if n is None: return "—"
    return f"${n:,.2f}"


def build_schedule_c_pdf(user: dict, summary: dict[str, Any]) -> bytes:
    """
    summary keys expected (all optional — 0 defaults):
      year, gross_receipts, other_income, returns_allowances, cogs,
      mileage_business_miles, mileage_deduction, expenses_by_category (dict),
      total_expenses, net_profit,
      se_tax, se_taxable_earnings,
    """
    buf = BytesIO()
    c = canvas.Canvas(buf, pagesize=LETTER)
    W, H = LETTER
    year = int(summary.get("year") or datetime.utcnow().year)

    # -------------------- Header --------------------
    c.setFillColor(INK)
    c.rect(0, H - 78, W, 78, fill=True, stroke=False)
    c.setFillColor(CYAN)
    c.setFont("Helvetica-Bold", 22)
    c.drawString(0.5 * inch, H - 40, "milli")
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 14)
    c.drawRightString(W - 0.5 * inch, H - 36, f"{year} Schedule C — Ready")
    c.setFont("Helvetica", 9)
    c.setFillColor(HexColor("#C9D0D9"))
    c.drawRightString(W - 0.5 * inch, H - 52,
        "Milli Tax Vault™ · Preparer-ready · Not filed with IRS")
    c.drawRightString(W - 0.5 * inch, H - 66,
        datetime.utcnow().strftime("Generated %B %d, %Y · %H:%M UTC"))

    # -------------------- Taxpayer strip --------------------
    y = H - 100
    c.setFillColor(INK)
    c.setFont("Helvetica-Bold", 11)
    c.drawString(0.5 * inch, y, "Taxpayer")
    c.setFont("Helvetica", 10)
    c.drawString(1.5 * inch, y, user.get("name") or "—")
    c.setFont("Helvetica-Bold", 11)
    c.drawRightString(W - 2.4 * inch, y, "State")
    c.setFont("Helvetica", 10)
    c.drawRightString(W - 1.8 * inch, y, user.get("state") or "—")
    c.setFont("Helvetica-Bold", 11)
    c.drawRightString(W - 1.2 * inch, y, "Filing")
    c.setFont("Helvetica", 10)
    c.drawRightString(W - 0.5 * inch, y, user.get("filing_status") or "single")

    c.setStrokeColor(LINE); c.setLineWidth(0.4)
    c.line(0.5 * inch, y - 6, W - 0.5 * inch, y - 6)

    # -------------------- Part I — Income --------------------
    y = _section(c, "Part I  ·  Income", y - 22)
    rows = [
        ("1", "Gross receipts / sales (all gig payouts)",  summary.get("gross_receipts", 0)),
        ("2", "Returns and allowances",                    summary.get("returns_allowances", 0)),
        ("3", "Subtract line 2 from line 1",               summary.get("gross_receipts", 0) - summary.get("returns_allowances", 0)),
        ("4", "Cost of goods sold",                        summary.get("cogs", 0)),
        ("5", "Gross profit (line 3 − line 4)",            summary.get("gross_receipts", 0) - summary.get("returns_allowances", 0) - summary.get("cogs", 0)),
        ("6", "Other income",                              summary.get("other_income", 0)),
        ("7", "Gross income (line 5 + line 6)",            summary.get("gross_receipts", 0) - summary.get("returns_allowances", 0) - summary.get("cogs", 0) + summary.get("other_income", 0)),
    ]
    y = _draw_rows(c, rows, y)

    # -------------------- Part II — Expenses --------------------
    y = _section(c, "Part II  ·  Expenses", y - 12)
    exp = summary.get("expenses_by_category") or {}
    exp_rows: list[tuple[str, str, float]] = [
        ("8",   "Advertising",                exp.get("advertising", 0)),
        ("9",   "Car & truck (mileage)",      summary.get("mileage_deduction", 0)),
        ("10",  "Commissions & fees",         exp.get("fees", 0)),
        ("11",  "Contract labor",             exp.get("contract_labor", 0)),
        ("13",  "Depreciation (Sec 179)",     exp.get("depreciation", 0)),
        ("14",  "Employee benefit programs",  exp.get("benefits", 0)),
        ("15",  "Insurance (other than health)", exp.get("insurance", 0)),
        ("16",  "Interest",                   exp.get("interest", 0)),
        ("17",  "Legal & professional",       exp.get("legal", 0)),
        ("18",  "Office expenses",            exp.get("office", 0)),
        ("20b", "Rent — other biz property",  exp.get("rent", 0)),
        ("21",  "Repairs & maintenance",      exp.get("repairs", 0)),
        ("22",  "Supplies",                   exp.get("supplies", 0)),
        ("23",  "Taxes & licenses",           exp.get("taxes_licenses", 0)),
        ("24a", "Travel",                     exp.get("travel", 0)),
        ("24b", "Meals (50%)",                exp.get("meals", 0)),
        ("25",  "Utilities",                  exp.get("utilities", 0)),
        ("27a", "Other expenses",             exp.get("other", 0)),
    ]
    y = _draw_rows(c, exp_rows, y, dense=True)
    total_exp = summary.get("total_expenses", sum(v for _, _, v in exp_rows))
    y = _draw_rows(c, [("28", "Total expenses (sum of above)", total_exp)], y, emphasize=True)

    # -------------------- Net profit / loss --------------------
    y -= 6
    gross_income = (summary.get("gross_receipts", 0) - summary.get("returns_allowances", 0) - summary.get("cogs", 0)) + summary.get("other_income", 0)
    net_profit = summary.get("net_profit", gross_income - total_exp)
    y = _draw_rows(c, [
        ("31", "Net profit or (loss)  =  line 7 − line 28", net_profit),
    ], y, emphasize=True, highlight=True)

    # -------------------- Schedule SE (short form) --------------------
    y = _section(c, "Schedule SE  ·  Self-Employment Tax", y - 12)
    se_taxable = summary.get("se_taxable_earnings", round(net_profit * 0.9235, 2))
    se_tax     = summary.get("se_tax",             round(se_taxable * 0.153, 2))
    se_rows = [
        ("1a", "Net SE earnings (line 31 from Sch C)",     net_profit),
        ("2",  "× 92.35% (line 1a × 0.9235)",               se_taxable),
        ("10", "Self-employment tax (line 2 × 15.3%)",     se_tax),
        ("13", "Deduction for 1/2 of SE tax  (line 10 × 50%)", round(se_tax * 0.5, 2)),
    ]
    y = _draw_rows(c, se_rows, y, emphasize=True)

    # -------------------- Footer --------------------
    c.setFillColor(GREY); c.setFont("Helvetica-Oblique", 8)
    footer = ("This worksheet is generated by Milli Tax Vault™ from user-connected banking, "
              "mileage, and expense data. Please review with your tax preparer before filing. "
              "Milli is not a tax preparer or CPA — no tax opinion is being rendered.")
    _wrap_text(c, footer, 0.5 * inch, 0.65 * inch, W - 1 * inch, 9)

    c.setFillColor(CYAN); c.setFont("Helvetica-Bold", 9)
    c.drawRightString(W - 0.5 * inch, 0.5 * inch, "milli.tax")

    c.showPage()
    c.save()
    return buf.getvalue()


# ------------------------------- helpers -------------------------------
def _section(c: canvas.Canvas, title: str, y: float) -> float:
    W, _ = LETTER
    c.setFillColor(CYAN); c.setFont("Helvetica-Bold", 10)
    c.drawString(0.5 * inch, y, title)
    c.setStrokeColor(CYAN); c.setLineWidth(0.6)
    c.line(0.5 * inch, y - 3, W - 0.5 * inch, y - 3)
    return y - 16


def _draw_rows(c: canvas.Canvas, rows: list, y: float,
               *, dense: bool = False, emphasize: bool = False, highlight: bool = False) -> float:
    W, _ = LETTER
    row_h = 14 if dense else 16
    for line_no, label, val in rows:
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold" if emphasize else "Helvetica", 9)
        c.drawString(0.5 * inch, y, f"Line {line_no}")
        c.drawString(1.2 * inch, y, label)
        if highlight:
            c.setFillColor(HexColor("#EAFDFF"))
            c.rect(W - 2.1 * inch, y - 3, 1.6 * inch, 12, fill=True, stroke=False)
            c.setFillColor(CYAN); c.setFont("Helvetica-Bold", 10)
        else:
            c.setFillColor(INK); c.setFont("Helvetica-Bold" if emphasize else "Helvetica", 9)
        c.drawRightString(W - 0.5 * inch, y, _fmt_money(val))
        y -= row_h
        c.setStrokeColor(LINE); c.setLineWidth(0.15)
        c.line(0.5 * inch, y + 8, W - 0.5 * inch, y + 8)
    return y


def _wrap_text(c: canvas.Canvas, text: str, x: float, y: float, max_w: float, font_size: int):
    c.setFont("Helvetica-Oblique", font_size)
    words = text.split()
    line = ""
    for w in words:
        test = f"{line} {w}".strip()
        if c.stringWidth(test, "Helvetica-Oblique", font_size) < max_w:
            line = test
        else:
            c.drawString(x, y, line)
            y -= 10
            line = w
    if line:
        c.drawString(x, y, line)
