"""Security regression tests for the Unit money-rail boundary."""

import asyncio
import base64
import hashlib
import hmac
import json
import os
import sys
from uuid import uuid4

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402
from app.routers.unit_routes import _event_list, _verify_unit_webhook  # noqa: E402
from app.unit_client import UnitClient  # noqa: E402


def test_unit_webhook_rejects_missing_signature(monkeypatch):
    monkeypatch.setenv("UNIT_WEBHOOK_SECRET", "test-secret")
    get_settings.cache_clear()
    try:
        with pytest.raises(HTTPException) as exc:
            _verify_unit_webhook(b'{"data":[]}', None)
        assert exc.value.status_code == 401
    finally:
        get_settings.cache_clear()


def test_unit_webhook_accepts_exact_hmac_sha1_signature(monkeypatch):
    secret = "test-secret"
    raw = b'{"data":[{"id":"evt-1","type":"payment.sent"}]}'
    signature = base64.b64encode(
        hmac.new(secret.encode("utf-8"), raw, hashlib.sha1).digest()
    ).decode("ascii")
    monkeypatch.setenv("UNIT_WEBHOOK_SECRET", secret)
    get_settings.cache_clear()
    try:
        _verify_unit_webhook(raw, signature)
    finally:
        get_settings.cache_clear()


def test_unit_webhook_rejects_tampered_body(monkeypatch):
    secret = "test-secret"
    original = b'{"data":[{"id":"evt-1","type":"payment.sent"}]}'
    tampered = b'{"data":[{"id":"evt-1","type":"payment.returned"}]}'
    signature = base64.b64encode(
        hmac.new(secret.encode("utf-8"), original, hashlib.sha1).digest()
    ).decode("ascii")
    monkeypatch.setenv("UNIT_WEBHOOK_SECRET", secret)
    get_settings.cache_clear()
    try:
        with pytest.raises(HTTPException) as exc:
            _verify_unit_webhook(tampered, signature)
        assert exc.value.status_code == 401
    finally:
        get_settings.cache_clear()


def test_unit_webhook_caps_batch_size():
    document = {"data": [{"id": str(i), "type": "payment.created"} for i in range(101)]}
    with pytest.raises(HTTPException) as exc:
        _event_list(document)
    assert exc.value.status_code == 413


def test_unit_client_refuses_debit_without_authorization():
    client = UnitClient(base_url="https://api.s.unit.sh", api_token="not-used")

    async def attempt():
        return await client.create_ach_payment_to_linked_account(
            source_account_id="100",
            linked_account_id="200",
            amount_cents=2500,
            direction="Debit",
            description="TAXVAULT",
            idempotency_key=uuid4(),
            debit_authorization_id=None,
        )

    with pytest.raises(ValueError, match="authorization"):
        asyncio.run(attempt())


def test_unsigned_unit_webhook_endpoint_is_rejected(monkeypatch):
    monkeypatch.setenv("UNIT_WEBHOOK_SECRET", "test-secret")
    get_settings.cache_clear()
    try:
        with TestClient(app) as client:
            response = client.post(
                "/unit/webhook",
                content=json.dumps({"data": []}),
                headers={"Content-Type": "application/json"},
            )
        assert response.status_code == 401
    finally:
        get_settings.cache_clear()
