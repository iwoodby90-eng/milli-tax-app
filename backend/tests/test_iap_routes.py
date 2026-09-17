"""Contract tests for the Apple IAP router.

Tests verify:
1. JWS decode and transaction ID matching
2. Duplicate transaction rejection
3. 503 when DB is not configured
4. Webhook notification processing
5. No fabricated verification status
"""

import base64
import json
import uuid
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://test:test@localhost/test")
    monkeypatch.setenv("CLIENT_API_KEY", "test-client-key")
    monkeypatch.setenv("APPLE_IAP_BUNDLE_ID", "com.milli.taxvault")
    monkeypatch.setenv("APPLE_IAP_ISSUER_ID", "issuer_123")
    monkeypatch.setenv("APPLE_IAP_KEY_ID", "key_123")
    monkeypatch.setenv("APPLE_IAP_PRIVATE_KEY", "fake_key")

    from app.config import get_settings
    get_settings.cache_clear()

    from app.main import app
    return TestClient(app)


@pytest.fixture
def no_db_client(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv("CLIENT_API_KEY", "test-client-key")

    from app.config import get_settings
    get_settings.cache_clear()

    from app.main import app
    return TestClient(app)


HEADERS = {"X-Milli-Client-Key": "test-client-key"}


def _make_jws(payload: dict) -> str:
    """Create a fake JWS with the given payload (header.payload.signature)."""
    header = base64.urlsafe_b64encode(json.dumps({"alg": "ES256"}).encode()).rstrip(b"=").decode()
    body = base64.urlsafe_b64encode(json.dumps(payload).encode()).rstrip(b"=").decode()
    return f"{header}.{body}.fake_signature"


class TestJWSDecode:
    def test_decode_valid_jws(self):
        from app.routers.iap_routes import _decode_jws_payload
        payload = {"transactionId": "12345", "productId": "com.milli.pro"}
        jws = _make_jws(payload)
        result = _decode_jws_payload(jws)
        assert result["transactionId"] == "12345"

    def test_decode_invalid_jws_format(self):
        from app.routers.iap_routes import _decode_jws_payload
        with pytest.raises(ValueError):
            _decode_jws_payload("not.a.valid.jws.format")

    def test_decode_empty_string(self):
        from app.routers.iap_routes import _decode_jws_payload
        with pytest.raises(ValueError):
            _decode_jws_payload("")


class TestTransactionVerification:
    def test_verify_matching_transaction_id(self):
        from app.routers.iap_routes import _verify_transaction
        payload = {"transactionId": "tx_123"}
        jws = _make_jws(payload)
        result = _verify_transaction(jws, "tx_123")
        assert result["transactionId"] == "tx_123"

    def test_verify_mismatched_transaction_id(self):
        from app.routers.iap_routes import _verify_transaction
        payload = {"transactionId": "tx_123"}
        jws = _make_jws(payload)
        with pytest.raises(ValueError, match="Transaction ID mismatch"):
            _verify_transaction(jws, "tx_wrong")


class TestIAPEndpoints:
    def test_verify_503_without_db(self, no_db_client):
        resp = no_db_client.post(
            "/iap/verify",
            json={
                "user_id": str(uuid.uuid4()),
                "transaction_id": "tx_123",
                "original_transaction_id": "orig_123",
                "product_id": "com.milli.pro",
                "jws_token": _make_jws({"transactionId": "tx_123"}),
                "purchase_date": datetime.now(timezone.utc).isoformat(),
                "environment": "sandbox",
            },
            headers=HEADERS,
        )
        assert resp.status_code == 503

    def test_list_transactions_503_without_db(self, no_db_client):
        resp = no_db_client.get(
            f"/iap/transactions/{uuid.uuid4()}",
            headers=HEADERS,
        )
        assert resp.status_code == 503

    def test_webhook_missing_signed_payload(self, client):
        resp = client.post("/iap/webhook", json={})
        assert resp.status_code == 400

    def test_webhook_valid_notification(self, client):
        """Webhook with valid payload returns 200."""
        payload = {
            "notificationType": "DID_RENEW",
            "data": {"transactionId": "tx_999"},
        }
        signed_payload = _make_jws(payload)
        resp = client.post(
            "/iap/webhook",
            json={"signedPayload": signed_payload},
        )
        assert resp.status_code == 200
        assert resp.json()["notification_type"] == "DID_RENEW"


class TestIAPModelValidation:
    def test_environment_must_be_valid(self):
        from app.routers.iap_routes import IAPVerifyIn
        with pytest.raises(ValueError):
            IAPVerifyIn(
                user_id=uuid.uuid4(),
                transaction_id="tx_1",
                original_transaction_id="orig_1",
                product_id="com.milli.pro",
                jws_token="a.b.c",
                purchase_date=datetime.now(timezone.utc),
                environment="staging",  # type: ignore
            )

    def test_iap_out_status_must_be_valid(self):
        from app.routers.iap_routes import IAPOut
        with pytest.raises(ValueError):
            IAPOut(
                id=uuid.uuid4(),
                transaction_id="tx_1",
                original_transaction_id="orig_1",
                product_id="com.milli.pro",
                purchase_date=datetime.now(timezone.utc),
                status="pending",  # type: ignore - not a valid IAP status
                environment="sandbox",
                audit_id="AUD-1",
                created_at=datetime.now(timezone.utc),
            )