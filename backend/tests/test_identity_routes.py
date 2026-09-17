"""Contract tests for the Apple Identity router.

Tests verify:
1. JWS decode and claim extraction
2. 503 when Apple Identity is not configured
3. 503 when DB is not configured
4. Model validation for verification methods
5. Column KYC fallback path
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
    monkeypatch.setenv("APPLE_IDENTITY_MERCHANT_ID", "merchant.com.milli")
    monkeypatch.setenv("APPLE_IDENTITY_PRIVATE_KEY", "fake_key")

    from app.config import get_settings
    get_settings.cache_clear()

    from app.main import app
    return TestClient(app)


@pytest.fixture
def no_identity_client(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://test:test@localhost/test")
    monkeypatch.setenv("CLIENT_API_KEY", "test-client-key")
    monkeypatch.delenv("APPLE_IDENTITY_MERCHANT_ID", raising=False)

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
    header = base64.urlsafe_b64encode(json.dumps({"alg": "ES256"}).encode()).rstrip(b"=").decode()
    body = base64.urlsafe_b64encode(json.dumps(payload).encode()).rstrip(b"=").decode()
    return f"{header}.{body}.fake_signature"


class TestJWSDecode:
    def test_decode_valid_identity_payload(self):
        from app.routers.identity_routes import _decode_jws_payload
        payload = {"familyName": "Doe", "givenName": "John", "dateOfBirth": "1990-01-01"}
        jws = _make_jws(payload)
        result = _decode_jws_payload(jws)
        assert result["familyName"] == "Doe"

    def test_decode_invalid_jws(self):
        from app.routers.identity_routes import _decode_jws_payload
        with pytest.raises(ValueError):
            _decode_jws_payload("invalid")


class TestWalletVerification:
    def test_verify_extracts_claims(self):
        from app.routers.identity_routes import _verify_apple_wallet_identity
        payload = {
            "familyName": "Doe",
            "givenName": "John",
            "dateOfBirth": "1990-01-01",
        }
        jws = _make_jws(payload)
        claims = _verify_apple_wallet_identity(jws)
        assert claims["family_name"] == "Doe"
        assert claims["given_name"] == "John"
        assert claims["date_of_birth"] == "1990-01-01"

    def test_verify_rejects_empty_claims(self):
        from app.routers.identity_routes import _verify_apple_wallet_identity
        jws = _make_jws({})
        with pytest.raises(ValueError, match="No verifiable claims"):
            _verify_apple_wallet_identity(jws)

    def test_verify_filters_none_claims(self):
        from app.routers.identity_routes import _verify_apple_wallet_identity
        payload = {"familyName": "Doe", "givenName": None}
        jws = _make_jws(payload)
        claims = _verify_apple_wallet_identity(jws)
        assert "family_name" in claims
        assert "given_name" not in claims


class TestIdentityEndpoints:
    def test_apple_wallet_503_without_identity_config(self, no_identity_client):
        resp = no_identity_client.post(
            "/identity/apple-wallet",
            json={
                "user_id": str(uuid.uuid4()),
                "jws_token": _make_jws({"familyName": "Doe"}),
            },
            headers=HEADERS,
        )
        assert resp.status_code == 503

    def test_apple_wallet_503_without_db(self, no_db_client):
        resp = no_db_client.post(
            "/identity/apple-wallet",
            json={
                "user_id": str(uuid.uuid4()),
                "jws_token": _make_jws({"familyName": "Doe"}),
            },
            headers=HEADERS,
        )
        assert resp.status_code == 503

    def test_column_kyc_503_without_db(self, no_db_client):
        resp = no_db_client.post(
            "/identity/column-kyc",
            json={
                "user_id": str(uuid.uuid4()),
                "column_entity_id": "ent_123",
            },
            headers=HEADERS,
        )
        assert resp.status_code == 503

    def test_list_verifications_503_without_db(self, no_db_client):
        resp = no_db_client.get(
            f"/identity/{uuid.uuid4()}",
            headers=HEADERS,
        )
        assert resp.status_code == 503


class TestModelValidation:
    def test_verification_method_must_be_valid(self):
        from app.routers.identity_routes import IdentityOut
        with pytest.raises(ValueError):
            IdentityOut(
                id=uuid.uuid4(),
                verification_method="invalid",  # type: ignore
                status="verified",
                audit_id="AUD-1",
                created_at=datetime.now(timezone.utc),
            )

    def test_status_must_be_valid(self):
        from app.routers.identity_routes import IdentityOut
        with pytest.raises(ValueError):
            IdentityOut(
                id=uuid.uuid4(),
                verification_method="apple_wallet",
                status="maybe",  # type: ignore
                audit_id="AUD-1",
                created_at=datetime.now(timezone.utc),
            )