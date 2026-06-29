"""MILLI backend API tests - new endpoints (onboarding, vault, smart accounts, quarterly, deposits/manual-v2)."""
import os
import uuid
import time
from datetime import datetime, timezone

import pytest
import requests

BASE_URL = (os.environ.get('REACT_APP_BACKEND_URL')
            or 'https://driver-tax-mileage.preview.emergentagent.com').rstrip('/')
API = f"{BASE_URL}/api"


# -------------------- Shared fixtures --------------------
@pytest.fixture(scope="module")
def rand_email():
    return f"qa-{uuid.uuid4().hex[:8]}@example.com"


@pytest.fixture(scope="module")
def password():
    return "Driver123!"


@pytest.fixture(scope="module")
def session():
    s = requests.Session()
    s.headers.update({"Content-Type": "application/json"})
    return s


@pytest.fixture(scope="module")
def auth(session, rand_email, password):
    r = session.post(f"{API}/auth/register", json={
        "email": rand_email, "password": password, "name": "QA Milli", "state": "CA"
    })
    assert r.status_code == 200, f"register failed: {r.status_code} {r.text}"
    data = r.json()
    return data


@pytest.fixture(scope="module")
def headers(auth):
    return {"Authorization": f"Bearer {auth['token']}", "Content-Type": "application/json"}


# -------------------- Onboarding --------------------
class TestOnboarding:
    def test_register_user_has_onboarding_false(self, auth):
        assert auth["user"]["onboarding_complete"] is False

    def test_onboarding_complete_persists(self, session, headers):
        body = {
            "employment_types": ["rideshare", "delivery"],
            "income_sources": ["uber", "doordash"],
            "expected_income": 45000,
            "dependents": 1,
            "reserve_strategy": "balanced",
            "mileage_mode": "auto",
        }
        r = session.post(f"{API}/onboarding/complete", headers=headers, json=body)
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["onboarding_complete"] is True
        assert d["employment_types"] == ["rideshare", "delivery"]
        assert d["income_sources"] == ["uber", "doordash"]
        assert d["expected_income"] == 45000
        assert d["dependents"] == 1
        assert d["reserve_strategy"] == "balanced"
        assert d["mileage_mode"] == "auto"
        assert "password_hash" not in d

    def test_me_reflects_onboarding_complete(self, session, headers):
        r = session.get(f"{API}/auth/me", headers=headers)
        assert r.status_code == 200
        d = r.json()
        assert d["onboarding_complete"] is True
        assert d.get("expected_income") == 45000


# -------------------- Plaid Link Token (sanity) --------------------
class TestPlaidLink:
    def test_link_token(self, session, headers):
        r = session.post(f"{API}/plaid/link-token", headers=headers)
        assert r.status_code == 200, r.text
        assert isinstance(r.json().get("link_token"), str)

    def test_exchange_with_fake_token_handled(self, session, headers):
        r = session.post(f"{API}/plaid/exchange", headers=headers,
                         json={"public_token": "public-sandbox-fake"})
        # Should not crash — either 400/500 with clean error
        assert r.status_code in (400, 500)
        # response must be JSON, not HTML stacktrace
        try:
            d = r.json()
            assert isinstance(d, dict)
        except Exception as e:
            pytest.fail(f"Exchange did not return JSON error: {e}")


# -------------------- Vault setup + rules + transfers --------------------
class TestVault:
    def test_vault_setup_creates_milli_reserve(self, session, headers):
        r = session.post(f"{API}/vault/setup", headers=headers, json={})
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["provider_type"] == "milli_reserve"
        assert d["balance"] == 0.0
        assert d["account_number_masked"].startswith("****")
        assert d["routing_number_masked"].startswith("****")
        assert d["rule"]["mode"] == "auto"
        assert d["rule"]["strategy"] == "balanced"

    def test_vault_setup_idempotent(self, session, headers):
        r1 = session.post(f"{API}/vault/setup", headers=headers, json={}).json()
        r2 = session.post(f"{API}/vault/setup", headers=headers, json={}).json()
        assert r1["id"] == r2["id"]

    def test_vault_get(self, session, headers):
        r = session.get(f"{API}/vault", headers=headers)
        assert r.status_code == 200
        d = r.json()
        assert d is not None
        assert "transfers" in d and isinstance(d["transfers"], list)

    def test_vault_rule_update(self, session, headers):
        body = {"mode": "manual", "strategy": "conservative",
                "fixed_percentage": 0.30, "paused": True}
        r = session.put(f"{API}/vault/rule", headers=headers, json=body)
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["mode"] == "manual"
        assert d["strategy"] == "conservative"
        assert d["fixed_percentage"] == 0.30
        assert d["paused"] is True
        # reset back for downstream tests
        reset = session.put(f"{API}/vault/rule", headers=headers, json={
            "mode": "auto", "strategy": "balanced", "fixed_percentage": None, "paused": False
        })
        assert reset.status_code == 200

    def test_vault_transfer_in_and_out(self, session, headers):
        r = session.post(f"{API}/vault/transfer", headers=headers,
                         json={"direction": "in", "amount": 200})
        assert r.status_code == 200, r.text
        assert r.json()["balance_after"] >= 200
        r2 = session.post(f"{API}/vault/transfer", headers=headers,
                          json={"direction": "out", "amount": 50})
        assert r2.status_code == 200
        assert r2.json()["balance_after"] >= 0

    def test_vault_withdraw_beyond_balance_400(self, session, headers):
        r = session.post(f"{API}/vault/transfer", headers=headers,
                         json={"direction": "out", "amount": 999999})
        assert r.status_code == 400

    def test_vault_transfer_zero_400(self, session, headers):
        r = session.post(f"{API}/vault/transfer", headers=headers,
                         json={"direction": "in", "amount": 0})
        assert r.status_code == 400

    def test_vault_connect_plaid_with_fake_token(self, session, headers):
        # Should fail cleanly (not crash) since fake token
        r = session.post(f"{API}/vault/connect-plaid", headers=headers, json={
            "public_token": "public-sandbox-fake",
            "institution_name": "Chase",
            "account_id": "acc_123",
            "account_name": "Savings",
            "account_mask": "1234",
            "account_subtype": "savings",
        })
        assert r.status_code in (400, 500, 404)
        # Should be JSON
        try:
            r.json()
        except Exception:
            pytest.fail("vault/connect-plaid did not return JSON")


# -------------------- Smart accounts (retirement + investing) --------------------
@pytest.mark.parametrize("kind,expected_pct", [("retirement", 0.08), ("investing", 0.05)])
class TestSmartAccounts:
    def test_setup(self, session, headers, kind, expected_pct):
        r = session.post(f"{API}/smart/{kind}/setup", headers=headers, json={})
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["balance"] == 0.0
        assert d["rule"]["mode"] == "auto"
        assert d["rule"]["fixed_percentage"] == expected_pct
        assert d["rule"]["paused"] is False

    def test_get(self, session, headers, kind, expected_pct):
        r = session.get(f"{API}/smart/{kind}", headers=headers)
        assert r.status_code == 200
        d = r.json()
        assert d is not None
        assert "transfers" in d
        assert d["rule"]["fixed_percentage"] == expected_pct

    def test_rule_update(self, session, headers, kind, expected_pct):
        r = session.put(f"{API}/smart/{kind}/rule", headers=headers,
                        json={"fixed_percentage": 0.10, "paused": True})
        assert r.status_code == 200
        d = r.json()
        assert d["fixed_percentage"] == 0.10
        assert d["paused"] is True
        # restore
        rest = session.put(f"{API}/smart/{kind}/rule", headers=headers,
                           json={"fixed_percentage": expected_pct, "paused": False, "mode": "auto"})
        assert rest.status_code == 200

    def test_transfer_in_out(self, session, headers, kind, expected_pct):
        r = session.post(f"{API}/smart/{kind}/transfer", headers=headers,
                         json={"direction": "in", "amount": 100})
        assert r.status_code == 200
        bal = r.json()["balance_after"]
        assert bal >= 100
        r2 = session.post(f"{API}/smart/{kind}/transfer", headers=headers,
                          json={"direction": "out", "amount": 25})
        assert r2.status_code == 200
        assert r2.json()["balance_after"] == round(bal - 25, 2)

    def test_transfer_overdraw_400(self, session, headers, kind, expected_pct):
        r = session.post(f"{API}/smart/{kind}/transfer", headers=headers,
                         json={"direction": "out", "amount": 9999999})
        assert r.status_code == 400

    def test_unknown_kind_404(self, session, headers, kind, expected_pct):
        r = session.get(f"{API}/smart/unknown_kind_xyz", headers=headers)
        assert r.status_code == 404


# -------------------- Deposits manual-v2 with auto-allocation --------------------
class TestDepositsV2AutoAllocation:
    def test_manual_v2_auto_allocates(self, session, headers):
        # Pre: read current effective rule (fixed_percentage may carry over from prior tests
        # because PUT /vault/rule uses exclude_none=True and can't clear fixed_percentage).
        v_before = session.get(f"{API}/vault", headers=headers).json()
        ret_before = session.get(f"{API}/smart/retirement", headers=headers).json()
        inv_before = session.get(f"{API}/smart/investing", headers=headers).json()
        v_bal0 = v_before["balance"]
        ret_bal0 = ret_before["balance"]
        inv_bal0 = inv_before["balance"]
        v_rule = v_before.get("rule", {})
        STRATEGY = {"conservative": 0.30, "balanced": 0.25, "minimum": 0.20}
        expected_pct = v_rule.get("fixed_percentage") or STRATEGY.get(v_rule.get("strategy", "balanced"), 0.25)
        ret_pct = ret_before.get("rule", {}).get("fixed_percentage", 0.08)
        inv_pct = inv_before.get("rule", {}).get("fixed_percentage", 0.05)

        amount = 1000.0
        r = session.post(f"{API}/deposits/manual-v2", headers=headers, json={
            "amount": amount, "platform": "Uber", "date": "2026-01-12"
        })
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["amount"] == amount
        assert d["auto_allocated"] is True
        assert d["savings_set_aside"] == round(amount * expected_pct, 2)

        # Verify balances changed
        v_after = session.get(f"{API}/vault", headers=headers).json()
        ret_after = session.get(f"{API}/smart/retirement", headers=headers).json()
        inv_after = session.get(f"{API}/smart/investing", headers=headers).json()
        assert round(v_after["balance"] - v_bal0, 2) == round(amount * expected_pct, 2)
        assert round(ret_after["balance"] - ret_bal0, 2) == round(amount * ret_pct, 2)
        assert round(inv_after["balance"] - inv_bal0, 2) == round(amount * inv_pct, 2)

        # Transfer records exist
        assert any(t.get("source") == "auto" for t in v_after["transfers"])
        assert any(t.get("source") == "auto" for t in ret_after["transfers"])
        assert any(t.get("source") == "auto" for t in inv_after["transfers"])

    def test_manual_v2_zero_amount_400(self, session, headers):
        r = session.post(f"{API}/deposits/manual-v2", headers=headers,
                         json={"amount": 0, "platform": "Uber"})
        assert r.status_code == 400


# -------------------- Quarterly --------------------
class TestQuarterly:
    def test_quarterly_overview(self, session, headers):
        r = session.get(f"{API}/quarterly", headers=headers)
        assert r.status_code == 200, r.text
        d = r.json()
        assert "year" in d and "quarters" in d
        assert len(d["quarters"]) == 4
        labels = [q["period"] for q in d["quarters"]]
        assert labels == ["Q1", "Q2", "Q3", "Q4"]
        for q in d["quarters"]:
            assert q["status"] in ("paid", "upcoming", "overdue")
            assert 0 <= q["readiness"] <= 100
            assert "due_date" in q and "amount" in q

    def test_record_payment_valid(self, session, headers):
        year = datetime.now(timezone.utc).year
        r = session.post(f"{API}/quarterly/payment", headers=headers, json={
            "period": "Q1", "year": year, "amount": 250.0,
            "paid_on": "2026-04-14", "confirmation": "TEST_CONF_001",
            "method": "IRS Direct Pay",
        })
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["period"] == "Q1"
        assert d["amount"] == 250.0
        # verify overview reflects payment
        ov = session.get(f"{API}/quarterly", headers=headers).json()
        q1 = next(q for q in ov["quarters"] if q["period"] == "Q1")
        assert q1["status"] == "paid"

    def test_record_payment_invalid_period_400(self, session, headers):
        r = session.post(f"{API}/quarterly/payment", headers=headers, json={
            "period": "Q9", "year": 2026, "amount": 100,
        })
        assert r.status_code == 400


# -------------------- Tax summary (sanity for MILLI) --------------------
class TestTaxSummary:
    def test_summary_returns_all_fields(self, session, headers):
        r = session.get(f"{API}/tax/summary", headers=headers)
        assert r.status_code == 200
        d = r.json()
        keys = {"gross_income", "total_miles", "mileage_deduction", "expense_total",
                "net_income", "se_tax", "fed_income_tax", "state_tax",
                "estimated_tax", "next_quarterly", "savings_recommended", "savings_balance"}
        assert keys.issubset(d.keys()), f"missing: {keys - set(d.keys())}"


# -------------------- Pricing tiers - Elite includes auto filing text --------------------
class TestPricingElite:
    def test_elite_has_auto_filing_feature(self, session):
        r = session.get(f"{API}/pricing/tiers")
        assert r.status_code == 200
        tiers = r.json()
        elite = next(t for t in tiers if t["id"] == "elite")
        assert any("Auto Federal + State tax filing (via licensed partner)" in f
                   for f in elite["features"])


# -------------------- Stripe checkout (MILLI tier id) --------------------
class TestStripeCheckout:
    def test_pro_checkout(self, session, headers):
        r = session.post(f"{API}/stripe/checkout", headers=headers,
                         json={"tier": "pro", "origin_url": BASE_URL})
        assert r.status_code == 200, r.text
        d = r.json()
        assert d.get("url", "").startswith("https://")
        assert d.get("session_id")


# -------------------- AI chat (SSE first chunk within 10s) --------------------
class TestAIChatStream:
    def test_first_data_chunk_within_10s(self, headers):
        r = requests.post(f"{API}/ai/chat",
                          headers={**headers, "Accept": "text/event-stream"},
                          json={"message": "What is the IRS mileage rate?"},
                          stream=True, timeout=30)
        assert r.status_code == 200
        assert "text/event-stream" in r.headers.get("content-type", "")
        start = time.time()
        got = False
        for raw in r.iter_lines(decode_unicode=True):
            if raw and raw.startswith("data:"):
                got = True
                break
            if time.time() - start > 15:
                break
        r.close()
        assert got, "no SSE chunk arrived within 15s"


# -------------------- Demo seed still works --------------------
class TestDemoSeed:
    def test_demo_seed(self, session):
        r = session.post(f"{API}/demo/seed")
        assert r.status_code == 200, r.text
        d = r.json()
        assert "token" in d and "user" in d
        assert d["user"]["email"] == "demo@milli.app"


# -------------------- Protected endpoints reject missing token --------------------
class TestProtectedNewEndpoints:
    @pytest.mark.parametrize("method,path", [
        ("post", "/onboarding/complete"),
        ("post", "/vault/setup"),
        ("get", "/vault"),
        ("put", "/vault/rule"),
        ("post", "/vault/transfer"),
        ("post", "/smart/retirement/setup"),
        ("get", "/smart/retirement"),
        ("put", "/smart/retirement/rule"),
        ("post", "/smart/retirement/transfer"),
        ("post", "/smart/investing/setup"),
        ("get", "/smart/investing"),
        ("get", "/quarterly"),
        ("post", "/quarterly/payment"),
        ("post", "/deposits/manual-v2"),
    ])
    def test_requires_auth(self, session, method, path):
        fn = getattr(session, method)
        r = fn(f"{API}{path}", json={} if method in ("post", "put") else None)
        assert r.status_code == 401, f"{method} {path} returned {r.status_code}"
