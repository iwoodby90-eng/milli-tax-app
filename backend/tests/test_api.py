"""Public contract tests that require no provider credentials or database."""

import os
import sys
from uuid import UUID

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402
from app.security import require_user  # noqa: E402

client = TestClient(app)
TEST_USER = UUID("11111111-1111-1111-1111-111111111111")


def setup_module(_module):
    get_settings.cache_clear()


def teardown_function(_function):
    app.dependency_overrides.pop(require_user, None)


def test_health_is_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_ready_reports_dependency_truth():
    body = client.get("/ready").json()
    assert "database" in body and "plaid" in body and "apple_auth" in body
    assert body["ready"] is False


def test_root_advertises_health_without_docs():
    body = client.get("/").json()
    assert body["health"] == "/health"
    assert "docs" not in body


def test_legacy_identity_header_is_not_authentication():
    response = client.get(
        "/tax-vault/balance",
        headers={"X-Milli-User-Id": str(TEST_USER), "X-Milli-Client-Key": "anything"},
    )
    assert response.status_code in (401, 503)


def test_vault_balance_unavailable_without_database_after_auth_override():
    app.dependency_overrides[require_user] = lambda: TEST_USER
    response = client.get("/tax-vault/balance")
    assert response.status_code == 503
    assert "DATABASE_URL" in response.json()["detail"]


def test_link_token_unavailable_without_plaid_credentials_after_auth_override():
    app.dependency_overrides[require_user] = lambda: TEST_USER
    response = client.post("/plaid/link-token")
    assert response.status_code == 503
    assert "Plaid" in response.json()["detail"]


def test_unsigned_plaid_webhook_is_rejected():
    response = client.post(
        "/plaid/webhook",
        json={"webhook_type": "ITEM", "webhook_code": "ERROR", "item_id": "item-x"},
    )
    assert response.status_code == 401


def test_security_headers_are_applied_to_public_responses():
    response = client.get("/health")
    assert response.headers["cache-control"] == "no-store"
    assert response.headers["pragma"] == "no-cache"
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "no-referrer"
    assert response.headers["permissions-policy"] == "camera=(), microphone=(), geolocation=()"
    assert response.headers["cross-origin-resource-policy"] == "same-origin"
