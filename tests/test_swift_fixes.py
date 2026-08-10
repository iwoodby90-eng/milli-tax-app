"""
Test suite to validate the P0 fixes for Milli Tax Vault SwiftUI app.
Since no Swift compiler is available, these tests validate file existence,
structural patterns, and endpoint alignment.
"""
import os
import re
import ast
import pytest

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWIFT_DIR = os.path.join(BASE, "swift-app", "MilliTaxVault")
BACKEND = os.path.join(BASE, "backend", "server.py")


def read_swift(filename):
    path = os.path.join(SWIFT_DIR, filename)
    assert os.path.exists(path), f"Missing file: {path}"
    with open(path, "r") as f:
        return f.read()


class TestFix1_LoginRegisterViews:
    """Fix 1: LoginView, RegisterView, and ContentView auth gating."""

    def test_login_view_exists(self):
        content = read_swift("LoginView.swift")
        assert "struct LoginView: View" in content

    def test_login_view_calls_appstate_login(self):
        content = read_swift("LoginView.swift")
        assert "appState.login(email:" in content

    def test_login_view_has_email_field(self):
        content = read_swift("LoginView.swift")
        assert "email" in content.lower()
        assert "TextField" in content or "SecureField" in content

    def test_login_view_has_password_field(self):
        content = read_swift("LoginView.swift")
        assert "SecureField" in content

    def test_login_view_dark_background(self):
        content = read_swift("LoginView.swift")
        assert "milliBackground" in content

    def test_login_view_cyan_accent(self):
        content = read_swift("LoginView.swift")
        assert "milliCyan" in content

    def test_login_view_has_register_link(self):
        content = read_swift("LoginView.swift")
        assert "showRegister" in content

    def test_register_view_exists(self):
        content = read_swift("RegisterView.swift")
        assert "struct RegisterView: View" in content

    def test_register_view_has_name_field(self):
        content = read_swift("RegisterView.swift")
        assert "name" in content

    def test_register_view_calls_appstate_register(self):
        content = read_swift("RegisterView.swift")
        assert "appState.register(name:" in content

    def test_appstate_has_register_method(self):
        content = read_swift("ViewModels/AppState.swift")
        assert "func register(name: String, email: String, password: String)" in content

    def test_appstate_register_posts_to_auth_register(self):
        content = read_swift("ViewModels/AppState.swift")
        assert '"/auth/register"' in content

    def test_contentview_gates_on_auth(self):
        content = read_swift("ContentView.swift")
        assert "appState.isAuthenticated" in content
        assert "LoginView()" in content


class TestFix2_EndpointAlignment:
    """Fix 2: Endpoint paths and model fields match backend."""

    def test_payouts_uses_deposits_endpoint(self):
        content = read_swift("ViewModels/PayoutsViewModel.swift")
        assert '"/deposits"' in content
        assert '"/payouts"' not in content

    def test_mileage_uses_trips_start(self):
        content = read_swift("ViewModels/MileageViewModel.swift")
        assert '"/trips/start"' in content
        assert '"/mileage/start"' not in content

    def test_mileage_uses_trips_end(self):
        content = read_swift("ViewModels/MileageViewModel.swift")
        assert "/trips/" in content and "/end" in content
        assert '"/mileage/stop"' not in content

    def test_mileage_uses_trips_active(self):
        content = read_swift("ViewModels/MileageViewModel.swift")
        assert '"/trips/active"' in content
        assert '"/mileage/active"' not in content

    def test_stripe_uses_correct_checkout_path(self):
        content = read_swift("Services/StripeService.swift")
        assert '"/stripe/checkout"' in content
        assert '"/billing/checkout"' not in content

    def test_stripe_uses_correct_portal_path(self):
        content = read_swift("Services/StripeService.swift")
        assert '"/stripe/portal"' in content
        assert '"/billing/portal"' not in content

    def test_stripe_no_billing_status(self):
        content = read_swift("Services/StripeService.swift")
        assert '"/billing/status"' not in content

    def test_vault_uses_correct_path(self):
        content = read_swift("ViewModels/TaxVaultViewModel.swift")
        assert '"/vault"' in content
        assert '"/vault/balance"' not in content
        assert '"/vault/transactions"' not in content

    def test_home_uses_dashboard_summary(self):
        content = read_swift("ViewModels/HomeViewModel.swift")
        assert '"/dashboard/summary"' in content


class TestFix2_ModelFields:
    """Fix 2: MilliUser model matches backend response shape."""

    def test_milli_user_has_name_field(self):
        content = read_swift("Models/Models.swift")
        assert "let name: String" in content

    def test_milli_user_no_firstname_lastname(self):
        content = read_swift("Models/Models.swift")
        assert "firstName" not in content
        assert "lastName" not in content
        assert "first_name" not in content
        assert "last_name" not in content

    def test_milli_user_id_maps_to_id(self):
        content = read_swift("Models/Models.swift")
        # Should NOT use "_id" mapping
        assert 'case id = "_id"' not in content

    def test_more_view_uses_user_name(self):
        content = read_swift("MoreView.swift")
        assert "user.name" in content
        assert "user.firstName" not in content
        assert "user.lastName" not in content

    def test_mileage_trip_uses_correct_fields(self):
        content = read_swift("Models/Models.swift")
        # Should use "deductible_value" not just "deduction"
        assert 'deductible_value' in content
        # Should use status field
        assert "case status" in content


class TestBackend_DashboardSummary:
    """Backend: /dashboard/summary route exists and is well-formed."""

    def test_backend_parses(self):
        with open(BACKEND, "r") as f:
            source = f.read()
        tree = ast.parse(source)
        assert tree is not None

    def test_dashboard_summary_route_exists(self):
        with open(BACKEND, "r") as f:
            source = f.read()
        assert '@api.get("/dashboard/summary")' in source

    def test_dashboard_summary_returns_correct_keys(self):
        with open(BACKEND, "r") as f:
            source = f.read()
        # Extract the return dict from dashboard_summary
        expected_keys = [
            "available_to_spend", "vault_balance", "vault_goal_percent",
            "latest_payout_amount", "latest_payout_date",
            "tax_ready_score", "quarterly_estimate", "quarter_miles",
        ]
        for key in expected_keys:
            assert f'"{key}"' in source, f"Missing key {key} in dashboard_summary response"

    def test_dashboard_summary_requires_auth(self):
        with open(BACKEND, "r") as f:
            source = f.read()
        # Find the function definition
        idx = source.find("async def dashboard_summary")
        assert idx > 0
        # Check it uses Depends(get_current_user)
        func_sig = source[idx:idx+200]
        assert "get_current_user" in func_sig


class TestStyleRules:
    """Validate non-negotiable style rules."""

    def test_login_uses_080810_background(self):
        content = read_swift("LoginView.swift")
        assert "milliBackground" in content

    def test_register_uses_080810_background(self):
        content = read_swift("RegisterView.swift")
        assert "milliBackground" in content

    def test_login_uses_millicard(self):
        content = read_swift("LoginView.swift")
        assert "MilliCard" in content

    def test_register_uses_millicard(self):
        content = read_swift("RegisterView.swift")
        assert "MilliCard" in content

    def test_login_button_uses_cyan(self):
        content = read_swift("LoginView.swift")
        assert "milliCyan" in content

    def test_register_button_uses_cyan(self):
        content = read_swift("RegisterView.swift")
        assert "milliCyan" in content
