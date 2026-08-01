"""
Test suite for v2.1 Elite Hardening changes.
Validates file content, structure, and key modifications.
"""
import ast
import os
import re

BASE = "/root/workspace/background/milli-v2-1-elite-hardening"

def read_file(rel_path):
    with open(os.path.join(BASE, rel_path), "r") as f:
        return f.read()

def test_nav_dial_button_has_milli_logo():
    """NavDialButton must import and render MilliLogo with glowOutline"""
    content = read_file("frontend/src/components/NavDialButton.jsx")
    assert "MilliLogo" in content
    assert "glowOutline" in content
    assert "neon cyan" in content.lower() or "00E5FF" in content or "cyan" in content.lower()

def test_milli_logo_glow_outline_prop():
    """MilliLogo must accept glowOutline prop and apply neon cyan stroke"""
    content = read_file("frontend/src/components/MilliLogo.jsx")
    assert "glowOutline" in content
    assert "rgba(0, 229, 255" in content
    assert "stroke=" in content

def test_weebo_avatar_no_square_bg():
    """WeeboAvatar must use CSS mask for transparent blend, no square background"""
    content = read_file("frontend/src/components/WeeboAvatar.jsx")
    assert "maskImage" in content or "mask-image" in content
    assert "WebkitMaskImage" in content
    assert 'background: "transparent"' in content

def test_gig_connections_conditional_display():
    """GigConnections must only show connected platforms + have Connect New Platform btn"""
    content = read_file("frontend/src/components/GigConnections.jsx")
    assert "connectedPlatforms" in content
    assert "Connect New Platform" in content
    assert "connect-new-platform-btn" in content
    assert "connect-platform-modal" in content
    # Verify it filters platforms
    assert "ALL_PLATFORMS.filter" in content

def test_dashboard_passes_connected_platforms():
    """Dashboard must pass connectedPlatforms prop to GigConnections"""
    content = read_file("frontend/src/pages/Dashboard.jsx")
    assert "connectedPlatforms" in content

def test_pricing_subscribe_button_text():
    """Pricing subscribe button must say 'Subscribe' not 'Subscribe with Apple'"""
    content = read_file("frontend/src/pages/Pricing.jsx")
    assert "Subscribe with Apple" not in content
    assert "Subscribe" in content  # plain Subscribe

def test_paywall_uses_storekit():
    """Paywall must still import and use useStoreKit"""
    content = read_file("frontend/src/pages/Paywall.jsx")
    assert "useStoreKit" in content

def test_retirement_plan_selector():
    """Retirement must have 401(k) type selector"""
    content = read_file("frontend/src/pages/Retirement.jsx")
    assert "Traditional 401(k)" in content or "Traditional" in content
    assert "Roth 401(k)" in content or "Roth" in content
    assert "Solo 401(k)" in content
    assert "PlanSelector" in content
    assert "plan-type-selector" in content

def test_retirement_growth_projection():
    """Retirement must have SVG line chart growth projection"""
    content = read_file("frontend/src/pages/Retirement.jsx")
    assert "GrowthProjectionGraph" in content
    assert "growth-projection-graph" in content
    assert "<svg" in content

def test_retirement_contribution_match():
    """Retirement must have 3% Contribution Match coming soon text"""
    content = read_file("frontend/src/pages/Retirement.jsx")
    assert "Coming Soon: 3% Contribution Match" in content
    assert "inputs up to 10%" in content

def test_investing_live_market_view():
    """Investing must have Live Market View with candlestick chart"""
    content = read_file("frontend/src/pages/Investing.jsx")
    assert "LiveMarketView" in content
    assert "live-market-view" in content
    assert "candl" in content.lower() or "MARKET_CANDLES" in content

def test_investing_search_bar():
    """Investing must have 'Search the Market' search bar"""
    content = read_file("frontend/src/pages/Investing.jsx")
    assert "Search the Market" in content
    assert "market-search-input" in content

def test_investing_daily_movers():
    """Investing must have Daily Movers (Gainers/Losers)"""
    content = read_file("frontend/src/pages/Investing.jsx")
    assert "DailyMovers" in content
    assert "daily-movers" in content
    assert "DAILY_GAINERS" in content
    assert "DAILY_LOSERS" in content
    assert "Gainers" in content
    assert "Losers" in content

def test_plaid_phone_removed():
    """Plaid link token must NOT pass phone_number"""
    content = read_file("backend/server.py")
    # Find the link token section
    idx = content.find("plaid_link_token")
    section = content[idx:idx+400]
    assert "phone_number" not in section
    assert "client_user_id" in section

def test_server_py_valid_python():
    """Backend server.py must be valid Python"""
    content = read_file("backend/server.py")
    ast.parse(content)

def test_all_jsx_balanced():
    """All modified JSX files must have balanced braces"""
    files = [
        "frontend/src/components/NavDialButton.jsx",
        "frontend/src/components/MilliLogo.jsx",
        "frontend/src/components/WeeboAvatar.jsx",
        "frontend/src/components/GigConnections.jsx",
        "frontend/src/pages/Pricing.jsx",
        "frontend/src/pages/Retirement.jsx",
        "frontend/src/pages/Investing.jsx",
        "frontend/src/pages/Dashboard.jsx",
    ]
    for f in files:
        content = read_file(f)
        braces = content.count("{") - content.count("}")
        parens = content.count("(") - content.count(")")
        brackets = content.count("[") - content.count("]")
        assert braces == 0, f"{f}: unbalanced braces ({braces})"
        assert parens == 0, f"{f}: unbalanced parens ({parens})"
        assert brackets == 0, f"{f}: unbalanced brackets ({brackets})"

if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-x", "-q"])
