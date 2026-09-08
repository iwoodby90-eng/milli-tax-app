"""Contract tests that need no Plaid credentials and no database.

They prove the service degrades truthfully and that Plaid transaction direction
is interpreted correctly before anything is allowed to look like gig income.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402
from app.routers.plaid_routes import _classify_gig_payout  # noqa: E402

client = TestClient(app)

HEADERS = {"X-Milli-User-Id": "11111111-1111-1111-1111-111111111111"}


def setup_module(_module):
    get_settings.cache_clear()


def test_health_is_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_ready_reports_dependency_truth():
    body = client.get("/ready").json()
    assert "database" in body and "plaid" in body
    assert body["ready"] is False  # nothing configured in the test env


def test_root_advertises_health():
    assert client.get("/").json()["health"] == "/health"


def test_missing_user_header_is_unauthorized():
    assert client.get("/tax-vault/balance").status_code == 401


def test_vault_balance_unavailable_without_database():
    response = client.get("/tax-vault/balance", headers=HEADERS)
    assert response.status_code == 503
    assert "DATABASE_URL" in response.json()["detail"]


def test_link_token_unavailable_without_plaid_credentials():
    response = client.post("/plaid/link-token", headers=HEADERS)
    assert response.status_code == 503
    assert "Plaid" in response.json()["detail"]


def test_webhook_acknowledges_without_credentials():
    response = client.post(
        "/plaid/webhook",
        json={"webhook_type": "ITEM", "webhook_code": "ERROR", "item_id": "item-x"},
    )
    assert response.status_code == 200
    assert response.json()["received"] is True


def test_posted_negative_doordash_inflow_is_detected_as_payout():
    platform = _classify_gig_payout(
        {
            "pending": False,
            "amount": -187.42,
            "name": "DOORDASH PAY 83921",
            "merchant_name": "DoorDash",
        }
    )
    assert platform == "DoorDash"


def test_positive_doordash_outflow_is_not_income():
    platform = _classify_gig_payout(
        {
            "pending": False,
            "amount": 42.15,
            "name": "DOORDASH",
            "merchant_name": "DoorDash",
        }
    )
    assert platform is None


def test_pending_matching_inflow_is_not_authoritative_payout():
    platform = _classify_gig_payout(
        {
            "pending": True,
            "amount": -212.00,
            "name": "UBER PAY",
            "merchant_name": "Uber",
        }
    )
    assert platform is None


def test_unrelated_inflow_is_not_gig_payout():
    platform = _classify_gig_payout(
        {
            "pending": False,
            "amount": -900.00,
            "name": "TRANSFER FROM SAVINGS",
            "merchant_name": None,
        }
    )
    assert platform is None
