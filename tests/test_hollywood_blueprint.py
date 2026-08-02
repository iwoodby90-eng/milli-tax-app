"""
Tests for v4.2 Hollywood Blueprint - verifies file structure, 
asset presence, and component correctness.
"""
import os
import re

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRONTEND = os.path.join(REPO_ROOT, "frontend")
SRC = os.path.join(FRONTEND, "src")
PUBLIC = os.path.join(FRONTEND, "public")


def read_file(relpath):
    with open(os.path.join(REPO_ROOT, relpath), "r") as f:
        return f.read()


# --- Asset Tests ---

def test_ai_sphere_png_exists():
    path = os.path.join(PUBLIC, "weebo", "milli-ai-sphere.png")
    assert os.path.exists(path), "AI sphere PNG missing"
    assert os.path.getsize(path) > 10000, "AI sphere PNG too small"


def test_growth_tree_png_exists():
    path = os.path.join(PUBLIC, "weebo", "milli-growth-tree.png")
    assert os.path.exists(path), "Growth tree PNG missing"
    assert os.path.getsize(path) > 10000, "Growth tree PNG too small"


# --- MilliPrimitives Tests ---

def test_primitives_exports():
    code = read_file("frontend/src/components/MilliPrimitives.jsx")
    assert "export function TaxReadyGauge" in code
    assert "export function MilliCentsWidget" in code
    assert "export function EliteSpendCard" in code
    assert "export function FinancialTimeline" in code
    assert "export function TaxVaultCard" in code


def test_tax_ready_gauge_neon_glow():
    code = read_file("frontend/src/components/MilliPrimitives.jsx")
    assert "#00E5FF" in code, "Neon cyan missing"
    assert "gauge-glow" in code, "Glow filter missing"


def test_elite_spend_card_structure():
    code = read_file("frontend/src/components/MilliPrimitives.jsx")
    assert "Available to Spend" in code
    assert "VISA" in code
    assert "ELITE" in code
    assert "accountMask" in code or "account" in code


def test_milli_cents_cost_breakdown():
    code = read_file("frontend/src/components/MilliPrimitives.jsx")
    assert "Pickup" in code
    assert "Deadhead" in code
    assert "Gas" in code
    assert "Taxes" in code
    assert "Profit Score" in code


# --- Dashboard Tests ---

def test_dashboard_header():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "Good morning" in code
    assert "financial overview" in code


def test_dashboard_elite_card():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "EliteSpendCard" in code
    assert "dashboard-elite-card" in code


def test_dashboard_latest_payout():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "Latest Payout" in code
    assert "Gross" in code
    assert "Vault" in code


def test_dashboard_vault_score_row():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "TaxVaultCard" in code
    assert "TaxReadyGauge" in code
    assert "dashboard-vault-score-row" in code


def test_dashboard_timeline():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "Financial Timeline" in code
    assert "FinancialTimeline" in code
    assert "View All" in code


def test_dashboard_footer_grid():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "Mileage" in code
    assert "Retirement" in code
    assert "Investing" in code
    assert "dashboard-footer-grid" in code


def test_dashboard_floating_ai_sphere():
    code = read_file("frontend/src/pages/Dashboard.jsx")
    assert "floating-ai-sphere" in code
    assert "milli-ai-sphere.png" in code


# --- Retirement Tests ---

def test_retirement_hero_with_tree():
    code = read_file("frontend/src/pages/Retirement.jsx")
    assert "Projected Balance" in code
    assert "milli-growth-tree.png" in code
    assert "$330,000" in code


def test_retirement_growth_graph():
    code = read_file("frontend/src/pages/Retirement.jsx")
    assert "10-Year Projection" in code
    assert "GrowthGraph" in code


def test_retirement_grid():
    code = read_file("frontend/src/pages/Retirement.jsx")
    assert "Your Contribution" in code
    assert "Employer Match" in code
    assert "Goal Progress" in code


def test_retirement_scenarios():
    code = read_file("frontend/src/pages/Retirement.jsx")
    assert "Scenario Comparison" in code
    assert "Conservative" in code
    assert "Moderate" in code
    assert "Aggressive" in code


# --- Investing Tests ---

def test_investing_elite_card():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "EliteSpendCard" in code


def test_investing_candlestick():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "CandlestickChart" in code
    assert "Market Overview" in code
    assert "1D" in code and "1W" in code and "1M" in code and "1Y" in code


def test_investing_gain_buying():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "Today's Gain" in code
    assert "Buying Power" in code


def test_investing_watchlist():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "Watchlist" in code
    assert "AAPL" in code
    assert "NVDA" in code
    assert "TSLA" in code


def test_investing_asset_allocation():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "Asset Allocation" in code
    assert "DonutChart" in code
    assert "Stocks" in code and "ETFs" in code and "Cash" in code and "Crypto" in code


def test_investing_ai_insight():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "Milli AI Insight" in code
    assert "confidence" in code


def test_investing_floating_sphere():
    code = read_file("frontend/src/pages/Investing.jsx")
    assert "floating-ai-sphere" in code
    assert "milli-ai-sphere.png" in code


# --- Mileage Tests ---

def test_mileage_header_toggle():
    code = read_file("frontend/src/pages/Mileage.jsx")
    assert "Mileage Tracker" in code
    assert "Auto-Tracking" in code
    assert "auto-tracking-toggle" in code


def test_mileage_live_tracking():
    code = read_file("frontend/src/pages/Mileage.jsx")
    assert "LIVE Tracking Trip" in code
    assert "Stop Tracking" in code
    assert "Start Trip" in code


def test_mileage_map():
    code = read_file("frontend/src/pages/Mileage.jsx")
    assert "map-section" in code
    assert "Today's Miles" in code


def test_mileage_trip_history():
    code = read_file("frontend/src/pages/Mileage.jsx")
    assert "Trip History" in code
    assert "View All" in code


def test_mileage_monthly_summary():
    code = read_file("frontend/src/pages/Mileage.jsx")
    assert "monthly-summary" in code
    assert "Total Miles" in code
    assert "Est. Deduction" in code
    assert "Trips" in code
    assert "Tracked Time" in code


def test_mileage_floating_sphere():
    code = read_file("frontend/src/pages/Mileage.jsx")
    assert "floating-ai-sphere" in code
    assert "milli-ai-sphere.png" in code


# --- Cross-cutting: Color Palette Consistency ---

def test_cinematic_palette():
    """Verify the #0D0F12 dark background and #00E5FF neon cyan used consistently."""
    files = [
        "frontend/src/pages/Dashboard.jsx",
        "frontend/src/pages/Retirement.jsx",
        "frontend/src/pages/Investing.jsx",
        "frontend/src/pages/Mileage.jsx",
    ]
    for f in files:
        code = read_file(f)
        assert "#0D0F12" in code, f"Missing dark bg in {f}"
        assert "#00E5FF" in code, f"Missing neon cyan in {f}"
