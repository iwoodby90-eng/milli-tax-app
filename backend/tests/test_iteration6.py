"""Iteration 6 regression: Stripe portal + checkout + auth-gated endpoints + plan-gated PDF."""
import os
import uuid
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://driver-tax-mileage.preview.emergentagent.com").rstrip("/")
API = f"{BASE_URL}/api"


def _register(email_prefix="TEST_it6"):
    email = f"{email_prefix}_{uuid.uuid4().hex[:8]}@example.com"
    r = requests.post(f"{API}/auth/register", json={
        "name": "It6 Tester", "email": email, "password": "TestPass123!", "state": "TX"
    }, timeout=30)
    assert r.status_code == 200, f"register: {r.status_code} {r.text}"
    token = r.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}
    ob = {
        "employment_types": ["rideshare"],
        "income_sources": ["uber"],
        "expected_income": 50000,
        "dependents": 0,
        "reserve_strategy": "balanced",
        "mileage_mode": "auto",
    }
    r2 = requests.post(f"{API}/onboarding/complete", json=ob, headers=headers, timeout=30)
    assert r2.status_code == 200, r2.text
    return {"token": token, "headers": headers, "email": email}


@pytest.fixture(scope="module")
def trial_user():
    return _register("TEST_it6_trial")


@pytest.fixture(scope="module")
def pro_user():
    u = _register("TEST_it6_pro")
    # Upgrade to pro via sandbox IAP verify (server accepts sandbox txn optimistically)
    r = requests.post(f"{API}/subscriptions/verify-receipt", headers=u["headers"], json={
        "transactionId": f"sandbox_{uuid.uuid4().hex[:12]}",
        "productId": "milli.pro.monthly",
    }, timeout=30)
    if r.status_code != 200:
        pytest.skip(f"Cannot upgrade to pro in this env (verify-receipt returned {r.status_code}): {r.text[:150]}")
    assert r.json().get("plan") == "pro"
    return u


# ---- Stripe portal ----
def test_stripe_portal_returns_url_or_graceful_502(trial_user):
    r = requests.post(f"{API}/stripe/portal", headers=trial_user["headers"], json={
        "return_url": "https://drivemilli.com/app/settings"
    }, timeout=30)
    assert r.status_code in (200, 502), f"unexpected: {r.status_code} {r.text[:300]}"
    if r.status_code == 200:
        data = r.json()
        assert "url" in data
        assert "billing.stripe.com" in data["url"], f"portal url unexpected: {data['url']}"
    else:
        # Must be graceful — not a 500 stack trace; must reference dashboard config path
        body = r.text.lower()
        assert "stripe" in body
        assert "portal" in body
        assert "dashboard.stripe.com/test/settings/billing/portal" in body or "configure" in body


def test_stripe_portal_unauth():
    r = requests.post(f"{API}/stripe/portal", json={}, timeout=15)
    assert r.status_code in (401, 403)


# ---- Stripe checkout ----
def test_stripe_checkout_returns_stripe_url(trial_user):
    r = requests.post(f"{API}/stripe/checkout", headers=trial_user["headers"], json={
        "tier": "pro", "origin_url": "https://drivemilli.com"
    }, timeout=30)
    assert r.status_code == 200, f"{r.status_code} {r.text[:300]}"
    data = r.json()
    url = data.get("url") or data.get("checkout_url")
    assert url and "checkout.stripe.com" in url, f"unexpected: {data}"


# ---- Auth-gated regressions ----
def test_plaid_items_unauth():
    r = requests.get(f"{API}/plaid/items", timeout=15)
    assert r.status_code in (401, 403)


def test_subscriptions_status_unauth():
    r = requests.get(f"{API}/subscriptions/status", timeout=15)
    assert r.status_code in (401, 403)


# ---- Plan gating on Schedule C ----
def test_schedule_c_pdf_trial_402(trial_user):
    r = requests.get(f"{API}/reports/schedule-c.pdf?year=2026",
                     headers=trial_user["headers"], timeout=30)
    assert r.status_code == 402, f"expected 402 for trial, got {r.status_code}"


def test_schedule_c_pdf_pro_200(pro_user):
    r = requests.get(f"{API}/reports/schedule-c.pdf?year=2026",
                     headers=pro_user["headers"], timeout=30)
    assert r.status_code == 200, f"expected 200 for pro, got {r.status_code} {r.text[:200]}"
    assert "pdf" in r.headers.get("content-type", "").lower()
