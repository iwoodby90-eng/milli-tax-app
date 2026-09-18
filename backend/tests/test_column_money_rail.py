"""Security and provider-contract tests for the Plaid -> Column money rail."""

import uuid

import httpx
import pytest

from app.column_client import ColumnClient, ColumnRequestFailed, ColumnUnavailable
from app.config import get_settings
from app.routers.column_routes import (
    AccountCreateIn,
    PlaidCounterpartyCreateIn,
    TransferCreateIn,
    _idempotency_key,
    _local_transfer_status,
)


def test_client_models_cannot_choose_financial_authority():
    assert "user_id" not in AccountCreateIn.model_fields
    assert "column_entity_id" not in AccountCreateIn.model_fields

    assert "user_id" not in PlaidCounterpartyCreateIn.model_fields
    assert "account_number" not in PlaidCounterpartyCreateIn.model_fields
    assert "routing_number" not in PlaidCounterpartyCreateIn.model_fields
    assert set(PlaidCounterpartyCreateIn.model_fields) == {"request_id", "plaid_account_id"}

    assert "user_id" not in TransferCreateIn.model_fields
    assert "status" not in TransferCreateIn.model_fields
    assert "provider_status" not in TransferCreateIn.model_fields
    assert "entry_class_code" not in TransferCreateIn.model_fields


def test_transfer_idempotency_key_is_stable_and_user_scoped():
    user_a = uuid.uuid4()
    user_b = uuid.uuid4()
    request_id = uuid.uuid4()

    first = _idempotency_key("ach", user_a, request_id)
    assert first == _idempotency_key("ach", user_a, request_id)
    assert first != _idempotency_key("ach", user_b, request_id)


@pytest.mark.parametrize(
    "provider_status, expected",
    [
        ("PRE_REVIEW", "processing"),
        ("INITIATED", "processing"),
        ("HOLD", "processing"),
        ("PENDING_SUBMISSION", "processing"),
        ("SUBMITTED", "processing"),
        ("SCHEDULED", "processing"),
        ("SETTLED", "settled"),
        ("COMPLETED", "settled"),
        ("RETURNED", "returned"),
        ("PENDING_RETURN", "returned"),
        ("CANCELED", "canceled"),
        ("A_NEW_COLUMN_STATE", "processing"),
    ],
)
def test_provider_state_mapping_fails_closed(provider_status, expected):
    assert _local_transfer_status(provider_status) == expected


def test_column_client_uses_basic_auth_integer_cents_sec_code_and_idempotency(monkeypatch):
    captured = {}

    class Response:
        status_code = 200

        @staticmethod
        def json():
            return {"id": "acht_test", "status": "INITIATED"}

    def fake_request(method, url, **kwargs):
        captured.update({"method": method, "url": url, **kwargs})
        return Response()

    monkeypatch.setattr(httpx, "request", fake_request)

    client = ColumnClient(base_url="https://api.column.com", api_key="test_secret")
    payload = client.create_ach_transfer(
        bank_account_id="bacc_test",
        counterparty_id="cpty_test",
        transfer_type="CREDIT",
        amount_cents=18742,
        description="Tax reserve",
        entry_class_code="PPD",
        idempotency_key="milli.ach.test",
    )

    assert payload["id"] == "acht_test"
    assert captured["auth"] == ("", "test_secret")
    assert captured["url"] == "https://api.column.com/transfers/ach"
    assert captured["data"]["amount"] == 18742
    assert isinstance(captured["data"]["amount"], int)
    assert captured["data"]["entry_class_code"] == "PPD"
    assert captured["headers"]["Idempotency-Key"] == "milli.ach.test"


def test_counterparty_creation_does_not_send_undocumented_idempotency_header(monkeypatch):
    captured = {}

    class Response:
        status_code = 200

        @staticmethod
        def json():
            return {"id": "cpty_test"}

    def fake_request(method, url, **kwargs):
        captured.update({"method": method, "url": url, **kwargs})
        return Response()

    monkeypatch.setattr(httpx, "request", fake_request)

    client = ColumnClient(base_url="https://api.column.com", api_key="test_secret")
    client.create_counterparty(
        account_number="123456789",
        routing_number="021000021",
        account_type="checking",
        name="Test Member",
        description="MILLI Plaid-verified ACH account",
    )

    assert captured["url"] == "https://api.column.com/counterparties"
    assert "Idempotency-Key" not in captured["headers"]


def test_provider_error_body_is_not_reflected(monkeypatch):
    class Response:
        status_code = 400
        text = "sensitive provider detail"

        @staticmethod
        def json():
            return {"message": "sensitive provider detail"}

    monkeypatch.setattr(httpx, "request", lambda *args, **kwargs: Response())

    client = ColumnClient(base_url="https://api.column.com", api_key="test_secret")
    with pytest.raises(ColumnRequestFailed) as exc:
        client.get_bank_account("bacc_test")

    assert "sensitive provider detail" not in str(exc.value)
    assert "HTTP 400" in str(exc.value)


def test_column_configuration_fails_closed_on_wrong_key_mode(monkeypatch):
    monkeypatch.setenv("COLUMN_API_KEY", "live_wrong_for_sandbox")
    monkeypatch.setenv("COLUMN_ENV", "sandbox")
    monkeypatch.setenv("COLUMN_BASE_URL", "https://api.column.com")
    get_settings.cache_clear()
    try:
        with pytest.raises(ColumnUnavailable):
            ColumnClient.configured()
    finally:
        get_settings.cache_clear()


def test_column_ach_configuration_requires_server_sec_policy(monkeypatch):
    monkeypatch.setenv("COLUMN_API_KEY", "test_valid")
    monkeypatch.setenv("COLUMN_ENV", "sandbox")
    monkeypatch.setenv("COLUMN_BASE_URL", "https://api.column.com")
    monkeypatch.delenv("COLUMN_ACH_CREDIT_SEC_CODE", raising=False)
    monkeypatch.delenv("COLUMN_ACH_DEBIT_SEC_CODE", raising=False)
    get_settings.cache_clear()
    try:
        assert get_settings().column_configured is True
        assert get_settings().column_ach_configured is False
    finally:
        get_settings.cache_clear()
