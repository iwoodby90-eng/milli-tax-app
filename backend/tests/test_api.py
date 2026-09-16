"""Contract tests that need no Plaid credentials and no database.

They prove the two properties that matter most: the service is alive, and it
degrades truthfully (503 UNAVAILABLE) instead of fabricating financial data.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402

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
