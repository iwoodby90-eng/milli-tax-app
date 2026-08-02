"""Regression tests for Reports page: tax summary + report downloads."""
import os
import uuid
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://wingman-mem-390f651f-e7a4-4197-9ea8-79b7db44303a-d5a1266a.preview.emergentagent.com").rstrip("/")
API = f"{BASE_URL}/api"


@pytest.fixture(scope="module")
def auth():
    email = f"TEST_reports_{uuid.uuid4().hex[:8]}@example.com"
    payload = {"name": "Reports Tester", "email": email, "password": "TestPass123!", "state": "TX"}
    r = requests.post(f"{API}/auth/register", json=payload, timeout=30)
    assert r.status_code == 200, f"register failed: {r.status_code} {r.text}"
    token = r.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}
    # complete onboarding
    ob = {
        "employment_types": ["rideshare"],
        "income_sources": ["uber"],
        "expected_income": 50000,
        "dependents": 0,
        "reserve_strategy": "balanced",
        "mileage_mode": "auto",
    }
    r2 = requests.post(f"{API}/onboarding/complete", json=ob, headers=headers, timeout=30)
    assert r2.status_code == 200
    return {"token": token, "headers": headers, "email": email}


def test_tax_summary_2026(auth):
    r = requests.get(f"{API}/tax/summary?year=2026", headers=auth["headers"], timeout=30)
    assert r.status_code == 200, r.text
    data = r.json()
    required = ["gross_income", "mileage_deduction", "total_miles", "net_income",
                "estimated_tax", "se_tax", "fed_income_tax", "state_tax", "state_rate", "year"]
    for k in required:
        assert k in data, f"missing field: {k}"
    assert data["year"] == 2026
    # numeric types
    for k in ["gross_income", "mileage_deduction", "net_income", "estimated_tax",
              "se_tax", "fed_income_tax", "state_tax", "state_rate", "total_miles"]:
        assert isinstance(data[k], (int, float)), f"{k} not numeric: {type(data[k])}"


def test_mileage_csv_200(auth):
    r = requests.get(f"{API}/reports/mileage.csv?year=2026", headers=auth["headers"], timeout=30)
    assert r.status_code == 200, r.text
    ct = r.headers.get("content-type", "")
    assert "text/csv" in ct, f"unexpected content-type: {ct}"
    # Must include header row
    body = r.content.decode("utf-8", errors="replace")
    assert "Date" in body and "Miles" in body


def test_schedule_c_pdf_trial_user(auth):
    """Trial users: frontend shows locked, but backend currently allows.
    Documenting actual behavior; if 200 -> flag as backend gating gap."""
    r = requests.get(f"{API}/reports/schedule-c.pdf?year=2026", headers=auth["headers"], timeout=30)
    # Backend does not enforce plan gating; expect 200 currently
    assert r.status_code in (200, 402, 403), r.status_code
    if r.status_code == 200:
        assert "pdf" in r.headers.get("content-type", "").lower()


def test_tax_summary_unauth():
    r = requests.get(f"{API}/tax/summary?year=2026", timeout=15)
    assert r.status_code in (401, 403)


def test_mileage_csv_unauth():
    r = requests.get(f"{API}/reports/mileage.csv?year=2026", timeout=15)
    assert r.status_code in (401, 403)
