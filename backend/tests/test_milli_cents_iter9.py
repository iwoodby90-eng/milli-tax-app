"""Iteration 9 — Milli Cents + redesign regression tests."""
import os
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://driver-tax-mileage.preview.emergentagent.com").rstrip("/")


@pytest.fixture(scope="module")
def token():
    r = requests.post(f"{BASE_URL}/api/demo/seed", timeout=30)
    assert r.status_code == 200, f"demo/seed failed: {r.status_code} {r.text}"
    data = r.json()
    assert "token" in data
    return data["token"]


@pytest.fixture(scope="module")
def auth_headers(token):
    return {"Authorization": f"Bearer {token}"}


# ---------------- Health / Auth basics ----------------
def test_health():
    r = requests.get(f"{BASE_URL}/api/health", timeout=15)
    assert r.status_code == 200


def test_login_demo():
    r = requests.post(f"{BASE_URL}/api/auth/login",
                      json={"email": "demo@milli.app", "password": "milli-demo-2026"}, timeout=15)
    assert r.status_code == 200
    assert "token" in r.json()


# ---------------- Milli Cents ----------------
SAMPLE_OFFER = {
    "platform": "uber",
    "payout": 22.5,
    "trip_miles": 10,
    "pickup_miles": 1,
    "deadhead_miles": 0.5,
    "return_miles": 3,
    "duration_min": 25,
}


def test_milli_cents_score_auth_required():
    r = requests.post(f"{BASE_URL}/api/milli-cents/score", json=SAMPLE_OFFER, timeout=15)
    assert r.status_code in (401, 403), f"expected 401/403 but got {r.status_code}"


def test_milli_cents_score_authed(auth_headers):
    r = requests.post(f"{BASE_URL}/api/milli-cents/score", json=SAMPLE_OFFER, headers=auth_headers, timeout=15)
    assert r.status_code == 200, r.text
    d = r.json()
    for k in ("score", "label", "verdict", "net_profit", "gas_cost", "wear_cost",
              "tax_cost", "total_cost", "per_mile", "per_hour"):
        assert k in d, f"missing field {k}"
    assert d["score"] >= 75, f"expected score>=75, got {d['score']}"
    assert d["verdict"] == "accept"


def test_milli_cents_compare(auth_headers):
    body = {"offers": [SAMPLE_OFFER, {**SAMPLE_OFFER, "payout": 6.0, "trip_miles": 12}]}
    r = requests.post(f"{BASE_URL}/api/milli-cents/compare", json=body, headers=auth_headers, timeout=15)
    assert r.status_code == 200, r.text
    d = r.json()
    assert d["count"] == 2
    assert d["offers"][0]["net_profit"] >= d["offers"][1]["net_profit"]


# ---------------- Referral / Voice ----------------
def test_referral_me(auth_headers):
    r = requests.get(f"{BASE_URL}/api/referral/me", headers=auth_headers, timeout=15)
    assert r.status_code == 200, r.text
    assert "code" in r.json()


def test_ai_voice(auth_headers):
    r = requests.post(f"{BASE_URL}/api/ai/voice", json={"text": "Hello driver"}, headers=auth_headers, timeout=60)
    # Some deployments may return 402 if quota; primarily verify not 5xx
    assert r.status_code < 500, f"voice endpoint 5xx: {r.status_code} {r.text[:200]}"
    if r.status_code == 200:
        ct = r.headers.get("content-type", "")
        assert "audio" in ct or "mpeg" in ct, f"unexpected content-type: {ct}"


# ---------------- Regression: existing endpoints ----------------
def test_subscription_status(auth_headers):
    r = requests.get(f"{BASE_URL}/api/subscriptions/status", headers=auth_headers, timeout=15)
    assert r.status_code == 200
    assert "plan" in r.json()


def test_vault(auth_headers):
    r = requests.get(f"{BASE_URL}/api/vault", headers=auth_headers, timeout=15)
    assert r.status_code == 200


def test_quarterly(auth_headers):
    r = requests.get(f"{BASE_URL}/api/quarterly", headers=auth_headers, timeout=15)
    assert r.status_code == 200
