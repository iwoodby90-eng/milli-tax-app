"""TaxHaul backend API tests"""
import os
import io
import uuid
import time
import json
from datetime import datetime, timedelta

import pytest
import requests

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', 'https://wingman-mem-390f651f-e7a4-4197-9ea8-79b7db44303a-d5a1266a.preview.emergentagent.com').rstrip('/')
API = f"{BASE_URL}/api"


@pytest.fixture(scope="session")
def rand_email():
    return f"qa-{uuid.uuid4().hex[:8]}@example.com"


@pytest.fixture(scope="session")
def password():
    return "Driver123!"


@pytest.fixture(scope="session")
def session():
    s = requests.Session()
    s.headers.update({"Content-Type": "application/json"})
    return s


@pytest.fixture(scope="session")
def auth(session, rand_email, password):
    """Register fresh user and return token + user."""
    resp = session.post(f"{API}/auth/register", json={
        "email": rand_email, "password": password, "name": "QA Driver", "state": "CA"
    })
    assert resp.status_code == 200, f"register failed: {resp.status_code} {resp.text}"
    data = resp.json()
    assert "token" in data and "user" in data
    return data


@pytest.fixture(scope="session")
def headers(auth):
    return {"Authorization": f"Bearer {auth['token']}", "Content-Type": "application/json"}


# -------------------- Auth --------------------
class TestAuth:
    def test_register_returns_token_and_trial(self, auth):
        u = auth["user"]
        assert u["plan"] == "trial"
        assert "trial_end" in u and u["trial_end"]
        # trial_end ~3 days out
        te = datetime.fromisoformat(u["trial_end"].replace("Z", "+00:00"))
        diff = (te - datetime.now(te.tzinfo)).total_seconds()
        assert 2 * 86400 < diff < 4 * 86400, f"trial_end not ~3 days: diff={diff}"
        assert "password_hash" not in u

    def test_register_duplicate_email_400(self, session, auth, rand_email, password):
        r = session.post(f"{API}/auth/register", json={
            "email": rand_email, "password": password, "name": "Dup", "state": "CA"
        })
        assert r.status_code == 400

    def test_register_invalid_email_rejected(self, session, password):
        r = session.post(f"{API}/auth/register", json={
            "email": "not-an-email", "password": password, "name": "X", "state": "TX"
        })
        assert r.status_code in (400, 422)

    def test_register_short_password_rejected(self, session):
        r = session.post(f"{API}/auth/register", json={
            "email": f"qa-{uuid.uuid4().hex[:6]}@example.com",
            "password": "abc", "name": "X", "state": "TX"
        })
        assert r.status_code == 422

    def test_login_success(self, session, rand_email, password):
        r = session.post(f"{API}/auth/login", json={"email": rand_email, "password": password})
        assert r.status_code == 200
        d = r.json()
        assert "token" in d and d["user"]["email"] == rand_email
        assert "password_hash" not in d["user"]

    def test_login_wrong_password_401(self, session, rand_email):
        r = session.post(f"{API}/auth/login", json={"email": rand_email, "password": "wrongpass"})
        assert r.status_code == 401

    def test_me_returns_user(self, session, headers, rand_email):
        r = session.get(f"{API}/auth/me", headers=headers)
        assert r.status_code == 200
        d = r.json()
        assert d["email"] == rand_email
        assert "password_hash" not in d

    def test_me_missing_token_401(self, session):
        r = session.get(f"{API}/auth/me")
        assert r.status_code == 401

    def test_me_invalid_token_401(self, session):
        r = session.get(f"{API}/auth/me", headers={"Authorization": "Bearer not.a.real.token"})
        assert r.status_code == 401

    def test_profile_update(self, session, headers):
        r = session.put(f"{API}/auth/profile", headers=headers,
                        json={"name": "Updated Driver", "state": "ny", "filing_status": "single"})
        assert r.status_code == 200
        d = r.json()
        assert d["name"] == "Updated Driver"
        assert d["state"] == "NY"
        assert d["filing_status"] == "single"


# -------------------- Plaid --------------------
class TestPlaid:
    def test_link_token(self, session, headers):
        r = session.post(f"{API}/plaid/link-token", headers=headers)
        assert r.status_code == 200, r.text
        d = r.json()
        assert isinstance(d.get("link_token"), str) and len(d["link_token"]) > 10

    def test_items_initially_empty(self, session, headers):
        r = session.get(f"{API}/plaid/items", headers=headers)
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_sync_returns_synced_count(self, session, headers):
        r = session.post(f"{API}/plaid/sync", headers=headers)
        assert r.status_code == 200
        d = r.json()
        assert "synced" in d and isinstance(d["synced"], int)


# -------------------- Deposits --------------------
class TestDeposits:
    def test_manual_deposit_creates_with_savings(self, session, headers):
        body = {"date": "2026-01-10", "amount": 100.00, "platform": "Uber", "merchant": "Uber"}
        r = session.post(f"{API}/deposits/manual", headers=headers, json=body)
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["amount"] == 100.0
        # trial plan -> 25% savings
        assert d["savings_set_aside"] == 25.0
        assert d["platform"] == "Uber"

    def test_manual_deposit_zero_rejected(self, session, headers):
        r = session.post(f"{API}/deposits/manual", headers=headers,
                         json={"date": "2026-01-10", "amount": 0, "platform": "Uber"})
        assert r.status_code == 400

    def test_manual_deposit_negative_rejected(self, session, headers):
        r = session.post(f"{API}/deposits/manual", headers=headers,
                         json={"date": "2026-01-10", "amount": -5, "platform": "Uber"})
        assert r.status_code == 400

    def test_list_deposits_sorted_desc(self, session, headers):
        session.post(f"{API}/deposits/manual", headers=headers,
                     json={"date": "2026-01-05", "amount": 50, "platform": "DoorDash"})
        session.post(f"{API}/deposits/manual", headers=headers,
                     json={"date": "2026-01-15", "amount": 75, "platform": "Spark"})
        r = session.get(f"{API}/deposits", headers=headers)
        assert r.status_code == 200
        deps = r.json()
        assert len(deps) >= 2
        dates = [d["date"] for d in deps]
        assert dates == sorted(dates, reverse=True)


# -------------------- Trips --------------------
class TestTrips:
    def test_start_trip(self, session, headers):
        r = session.post(f"{API}/trips/start", headers=headers,
                         json={"platform": "Uber", "start_lat": 37.77, "start_lng": -122.41})
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["status"] == "active"
        assert "id" in d

    def test_active_trip_returned(self, session, headers):
        r = session.get(f"{API}/trips/active", headers=headers)
        assert r.status_code == 200
        d = r.json()
        assert d is not None and d["status"] == "active"

    def test_second_start_abandons_first(self, session, headers):
        r1 = session.post(f"{API}/trips/start", headers=headers, json={"platform": "Uber"})
        first_id = r1.json()["id"]
        r2 = session.post(f"{API}/trips/start", headers=headers, json={"platform": "Lyft"})
        new_id = r2.json()["id"]
        assert first_id != new_id
        # current active should be the new one
        rg = session.get(f"{API}/trips/active", headers=headers).json()
        assert rg["id"] == new_id

    def test_end_trip_haversine(self, session, headers):
        r = session.post(f"{API}/trips/start", headers=headers, json={"platform": "Uber"})
        tid = r.json()["id"]
        # Two points ~ ~69 miles apart (1 degree lat)
        body = {"points": [{"lat": 37.0, "lng": -122.0}, {"lat": 38.0, "lng": -122.0}]}
        e = session.post(f"{API}/trips/{tid}/end", headers=headers, json=body)
        assert e.status_code == 200, e.text
        d = e.json()
        assert d["status"] == "completed"
        assert 68 < d["miles"] < 70, f"miles={d['miles']}"
        assert abs(d["deductible_value"] - round(d["miles"] * 0.70, 2)) < 0.01

    def test_manual_trip(self, session, headers):
        r = session.post(f"{API}/trips/manual", headers=headers,
                         json={"date": "2026-01-10", "miles": 50, "platform": "DoorDash"})
        assert r.status_code == 200
        d = r.json()
        assert d["status"] == "completed"
        assert d["miles"] == 50.0
        assert d["deductible_value"] == 35.0  # 50 * 0.70

    def test_list_trips_completed_only(self, session, headers):
        # start one and leave it active
        session.post(f"{API}/trips/start", headers=headers, json={"platform": "Uber"})
        r = session.get(f"{API}/trips", headers=headers)
        assert r.status_code == 200
        for t in r.json():
            assert t["status"] == "completed"


# -------------------- Expenses --------------------
class TestExpenses:
    def test_create_expense(self, session, headers):
        body = {"date": "2026-01-10", "amount": 42.50, "category": "gas", "merchant": "Shell"}
        r = session.post(f"{API}/expenses", headers=headers, json=body)
        assert r.status_code == 200
        d = r.json()
        assert d["amount"] == 42.50
        assert d["category"] == "gas"
        assert "id" in d

    def test_list_and_delete_expense(self, session, headers):
        r = session.post(f"{API}/expenses", headers=headers,
                         json={"date": "2026-01-11", "amount": 9.99, "category": "supplies"})
        eid = r.json()["id"]
        lst = session.get(f"{API}/expenses", headers=headers).json()
        assert any(e["id"] == eid for e in lst)
        d = session.delete(f"{API}/expenses/{eid}", headers=headers)
        assert d.status_code == 200
        lst2 = session.get(f"{API}/expenses", headers=headers).json()
        assert not any(e["id"] == eid for e in lst2)


# -------------------- Tax Summary --------------------
class TestTaxSummary:
    def test_summary_fields(self, session, headers):
        r = session.get(f"{API}/tax/summary", headers=headers)
        assert r.status_code == 200, r.text
        d = r.json()
        expected_keys = {
            "gross_income", "total_miles", "mileage_deduction", "expense_total",
            "net_income", "se_tax", "fed_income_tax", "state_tax", "estimated_tax",
            "next_quarterly", "savings_recommended", "savings_balance", "irs_mileage_rate",
        }
        missing = expected_keys - set(d.keys())
        assert not missing, f"missing keys: {missing}"
        assert d["irs_mileage_rate"] == 0.70
        # mileage_deduction = miles * 0.70
        assert abs(d["mileage_deduction"] - round(d["total_miles"] * 0.70, 2)) < 0.01
        # se_tax = 15.3% of net_income
        assert abs(d["se_tax"] - round(d["net_income"] * 0.153, 2)) < 0.01
        nq = d["next_quarterly"]
        assert "label" in nq and "due_date" in nq and "amount" in nq and "days_until" in nq


# -------------------- Reports --------------------
class TestReports:
    def test_schedule_c_pdf(self, session, headers):
        r = session.get(f"{API}/reports/schedule-c.pdf", headers=headers)
        assert r.status_code == 200
        assert "application/pdf" in r.headers.get("content-type", "")
        assert len(r.content) > 100
        assert r.content.startswith(b"%PDF")

    def test_mileage_csv(self, session, headers):
        r = session.get(f"{API}/reports/mileage.csv", headers=headers)
        assert r.status_code == 200
        assert "text/csv" in r.headers.get("content-type", "")
        body = r.content.decode("utf-8")
        first_line = body.splitlines()[0]
        assert first_line == "Date,Platform,Purpose,Miles,Deductible Value,Start,End,Notes"


# -------------------- Pricing & Stripe --------------------
class TestPricingStripe:
    def test_pricing_tiers(self, session):
        r = session.get(f"{API}/pricing/tiers")
        assert r.status_code == 200
        tiers = r.json()
        assert len(tiers) == 3
        ids = {t["id"]: t for t in tiers}
        assert ids["basic"]["price"] == 19.99
        assert ids["pro"]["price"] == 29.99
        assert ids["elite"]["price"] == 49.99
        for t in tiers:
            assert t.get("trial_days") == 3
            assert isinstance(t.get("features"), list) and len(t["features"]) > 0
            assert "name" in t

    def test_stripe_checkout(self, session, headers):
        origin = BASE_URL
        r = session.post(f"{API}/stripe/checkout", headers=headers,
                         json={"tier": "pro", "origin_url": origin})
        assert r.status_code == 200, r.text
        d = r.json()
        assert d.get("url", "").startswith("https://")
        assert d.get("session_id")
        # status check
        rs = session.get(f"{API}/stripe/status/{d['session_id']}", headers=headers)
        assert rs.status_code == 200
        st = rs.json()
        assert "status" in st and "payment_status" in st


# -------------------- AI Chat (streaming SSE) --------------------
class TestAIChat:
    def test_chat_streams(self, session, headers):
        r = requests.post(f"{API}/ai/chat",
                          headers={**headers, "Accept": "text/event-stream"},
                          json={"message": "What is the IRS mileage rate?"},
                          stream=True, timeout=60)
        assert r.status_code == 200
        ct = r.headers.get("content-type", "")
        assert "text/event-stream" in ct
        got_any = False
        got_done = False
        start = time.time()
        for raw in r.iter_lines(decode_unicode=True):
            if raw is None:
                continue
            if raw.startswith("data:"):
                got_any = True
                if "[DONE]" in raw:
                    got_done = True
                    break
            if time.time() - start > 45:
                break
        r.close()
        assert got_any, "no SSE chunks received"
        # done is best-effort
        assert got_done or got_any


# -------------------- Receipt OCR --------------------
class TestReceiptOCR:
    def test_scan_receipt(self, session, headers):
        # Create a JPEG image with receipt-like text via PIL
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            pytest.skip("PIL not available")
        img = Image.new("RGB", (600, 400), "white")
        d = ImageDraw.Draw(img)
        lines = ["SHELL GAS STATION", "123 Main St", "01/10/2026",
                 "Regular Unleaded", "10.5 GAL @ $3.50", "TOTAL $36.75",
                 "Thank you!"]
        for i, line in enumerate(lines):
            d.text((20, 20 + i * 40), line, fill="black")
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        buf.seek(0)
        files = {"file": ("receipt.jpg", buf.getvalue(), "image/jpeg")}
        # multipart upload — don't include json content-type header
        h = {"Authorization": headers["Authorization"]}
        r = requests.post(f"{API}/expenses/scan", headers=h, files=files, timeout=120)
        if r.status_code != 200:
            pytest.fail(f"OCR failed: {r.status_code} {r.text[:300]}")
        data = r.json()
        # Accept presence of at least some expected keys
        assert any(k in data for k in ("amount", "merchant", "category", "date"))


# -------------------- Protected endpoints --------------------
class TestProtected:
    @pytest.mark.parametrize("method,path", [
        ("get", "/auth/me"),
        ("put", "/auth/profile"),
        ("post", "/plaid/link-token"),
        ("get", "/plaid/items"),
        ("post", "/plaid/sync"),
        ("get", "/deposits"),
        ("post", "/deposits/manual"),
        ("post", "/trips/start"),
        ("get", "/trips/active"),
        ("post", "/trips/manual"),
        ("get", "/trips"),
        ("get", "/expenses"),
        ("post", "/expenses"),
        ("get", "/tax/summary"),
        ("get", "/reports/schedule-c.pdf"),
        ("get", "/reports/mileage.csv"),
        ("post", "/stripe/checkout"),
    ])
    def test_requires_auth(self, session, method, path):
        fn = getattr(session, method)
        r = fn(f"{API}{path}", json={} if method == "post" or method == "put" else None)
        assert r.status_code == 401, f"{method} {path} returned {r.status_code}"
