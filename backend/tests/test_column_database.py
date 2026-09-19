"""PostgreSQL integration coverage for the Plaid -> Column authority boundary."""

import os
from contextlib import contextmanager
from pathlib import Path
from uuid import uuid4

import psycopg
from psycopg import sql
import pytest
from fastapi.testclient import TestClient

from app import db
from app.config import get_settings
from app.main import app
from app.routers import column_routes
from app.security import require_user


class _DictResponse:
    def __init__(self, payload):
        self._payload = payload

    def to_dict(self):
        return self._payload


class FakePlaid:
    def __init__(self, provider_account_id):
        self.provider_account_id = provider_account_id

    def auth_get(self, _request):
        return _DictResponse(
            {
                "accounts": [
                    {
                        "account_id": self.provider_account_id,
                        "name": "Verified Checking",
                        "subtype": "checking",
                        "verification_status": None,
                    }
                ],
                "numbers": {
                    "ach": [
                        {
                            "account_id": self.provider_account_id,
                            "account": "123456789012",
                            "routing": "021000021",
                            "is_tokenized_account_number": False,
                        }
                    ]
                },
            }
        )


class FakeColumn:
    def __init__(self):
        self.bank_account_calls = []
        self.counterparty_calls = []
        self.transfer_calls = []
        self.counterparties = {}

    def create_bank_account(self, **kwargs):
        self.bank_account_calls.append(kwargs)
        return {
            "id": "bacc_test_1",
            "status": "open",
            "currency_code": "USD",
            "balances": {"available_amount": 0, "pending_amount": 0},
        }

    def get_bank_account(self, bank_account_id):
        return {
            "id": bank_account_id,
            "status": "open",
            "currency_code": "USD",
            "balances": {"available_amount": 0, "pending_amount": 0},
        }

    def create_counterparty(self, **kwargs):
        self.counterparty_calls.append(kwargs)
        provider_id = f"cpty_test_{len(self.counterparty_calls)}"
        self.counterparties[provider_id] = {
            "id": provider_id,
            "account_number": kwargs["account_number"],
            "routing_number": kwargs["routing_number"],
        }
        return self.counterparties[provider_id]

    def get_counterparty(self, counterparty_id):
        return self.counterparties[counterparty_id]

    def create_ach_transfer(self, **kwargs):
        self.transfer_calls.append(kwargs)
        return {
            "id": "acht_test_1",
            "status": "SUBMITTED",
        }

    def get_ach_transfer(self, ach_transfer_id):
        return {
            "id": ach_transfer_id,
            "status": "SETTLED",
            "settled_at": "2026-09-18T20:00:00Z",
        }


@pytest.fixture
def column_db(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")

    schema = "milli_column_" + uuid4().hex
    user_a = uuid4()
    user_b = uuid4()
    plaid_item_id = uuid4()
    plaid_account_id = uuid4()
    provider_account_id = "plaid-account-" + uuid4().hex
    fake_column = FakeColumn()
    fake_plaid = FakePlaid(provider_account_id)

    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))

        root = Path(__file__).parents[1] / "migrations"
        for migration in (
            "003_create_plaid_and_tax_vault.sql",
            "004_create_server_auth.sql",
            "005_create_column_money_rail.sql",
        ):
            conn.execute((root / migration).read_text())
        conn.commit()

        @contextmanager
        def connection():
            yield conn

        monkeypatch.setattr(db, "connection", connection)
        monkeypatch.setattr(column_routes, "_provider_client", lambda: fake_column)
        monkeypatch.setattr(column_routes, "get_plaid_client", lambda: fake_plaid)

        monkeypatch.setenv("DATABASE_URL", "postgresql://configured-for-test")
        monkeypatch.setenv("COLUMN_API_KEY", "test_column_key")
        monkeypatch.setenv("COLUMN_ENV", "sandbox")
        monkeypatch.setenv("COLUMN_BASE_URL", "https://api.column.com")
        monkeypatch.setenv("COLUMN_ACH_CREDIT_SEC_CODE", "PPD")
        monkeypatch.setenv("COLUMN_ACH_DEBIT_SEC_CODE", "WEB")
        get_settings.cache_clear()

        conn.execute(
            "insert into milli_users (id, apple_subject) values (%s, %s), (%s, %s)",
            (user_a, "apple-a-" + uuid4().hex, user_b, "apple-b-" + uuid4().hex),
        )
        conn.execute(
            """
            insert into plaid_items (id, user_id, item_id, access_token)
            values (%s, %s, %s, %s)
            """,
            (plaid_item_id, user_a, "item-" + uuid4().hex, "access-secret"),
        )
        conn.execute(
            """
            insert into plaid_accounts
                (id, user_id, plaid_item_id, account_id, name, mask, type, subtype)
            values (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                plaid_account_id,
                user_a,
                plaid_item_id,
                provider_account_id,
                "Verified Checking",
                "9012",
                "depository",
                "checking",
            ),
        )
        conn.commit()

        active_user = {"id": user_a}
        app.dependency_overrides[require_user] = lambda: active_user["id"]

        try:
            with TestClient(app) as client:
                yield {
                    "client": client,
                    "conn": conn,
                    "user_a": user_a,
                    "user_b": user_b,
                    "active_user": active_user,
                    "plaid_account_id": plaid_account_id,
                    "fake_column": fake_column,
                }
        finally:
            app.dependency_overrides.pop(require_user, None)
            get_settings.cache_clear()
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def test_account_creation_requires_server_owned_verified_kyc(column_db):
    client = column_db["client"]
    conn = column_db["conn"]
    user_a = column_db["user_a"]
    fake_column = column_db["fake_column"]

    body = {
        "request_id": str(uuid4()),
        "account_type": "checking",
    }
    blocked = client.post("/column/accounts", json=body)
    assert blocked.status_code == 409
    assert fake_column.bank_account_calls == []

    conn.execute(
        """
        insert into column_customer_profiles
            (user_id, column_entity_id, kyc_status, verified_at)
        values (%s, %s, 'verified', now())
        """,
        (user_a, "enti_server_owned"),
    )
    conn.commit()

    created = client.post("/column/accounts", json=body)
    assert created.status_code == 201, created.text
    assert fake_column.bank_account_calls[0]["entity_id"] == "enti_server_owned"

    injected = client.post(
        "/column/accounts",
        json={
            "request_id": str(uuid4()),
            "account_type": "checking",
            "column_entity_id": "enti_attacker_chosen",
        },
    )
    assert injected.status_code == 422


def test_plaid_auth_creates_counterparty_without_persisting_raw_numbers(column_db):
    client = column_db["client"]
    conn = column_db["conn"]
    plaid_account_id = column_db["plaid_account_id"]
    fake_column = column_db["fake_column"]

    response = client.post(
        "/column/counterparties/from-plaid",
        json={
            "request_id": str(uuid4()),
            "plaid_account_id": str(plaid_account_id),
        },
    )
    assert response.status_code == 201, response.text
    payload = response.json()
    assert payload["account_last_four"] == "9012"
    assert payload["routing_last_four"] == "0021"

    assert fake_column.counterparty_calls[0]["account_number"] == "123456789012"
    assert fake_column.counterparty_calls[0]["routing_number"] == "021000021"

    columns = {
        row[0]
        for row in conn.execute(
            """
            select column_name
              from information_schema.columns
             where table_schema = current_schema()
               and table_name = 'column_counterparties'
            """
        ).fetchall()
    }
    assert "account_number" not in columns
    assert "routing_number" not in columns

    stored = conn.execute(
        """
        select account_last_four, routing_last_four
          from column_counterparties
         where id = %s
        """,
        (payload["id"],),
    ).fetchone()
    assert stored == ("9012", "0021")


def test_other_user_cannot_turn_someone_elses_plaid_account_into_counterparty(column_db):
    client = column_db["client"]
    active_user = column_db["active_user"]
    active_user["id"] = column_db["user_b"]

    response = client.post(
        "/column/counterparties/from-plaid",
        json={
            "request_id": str(uuid4()),
            "plaid_account_id": str(column_db["plaid_account_id"]),
        },
    )
    assert response.status_code == 404


def test_transfer_sec_code_is_server_controlled_and_status_cannot_be_injected(column_db):
    client = column_db["client"]
    conn = column_db["conn"]
    user_a = column_db["user_a"]
    fake_column = column_db["fake_column"]

    conn.execute(
        """
        insert into column_customer_profiles
            (user_id, column_entity_id, kyc_status, verified_at)
        values (%s, %s, 'verified', now())
        """,
        (user_a, "enti_server_owned"),
    )
    conn.commit()

    account_response = client.post(
        "/column/accounts",
        json={"request_id": str(uuid4()), "account_type": "tax_vault"},
    )
    assert account_response.status_code == 201, account_response.text

    counterparty_response = client.post(
        "/column/counterparties/from-plaid",
        json={
            "request_id": str(uuid4()),
            "plaid_account_id": str(column_db["plaid_account_id"]),
        },
    )
    assert counterparty_response.status_code == 201, counterparty_response.text

    transfer_body = {
        "request_id": str(uuid4()),
        "bank_account_id": account_response.json()["id"],
        "counterparty_id": counterparty_response.json()["id"],
        "transfer_type": "DEBIT",
        "amount_cents": 18742,
        "description": "Tax Vault reserve",
    }
    transfer = client.post("/column/transfers", json=transfer_body)
    assert transfer.status_code == 201, transfer.text
    assert transfer.json()["status"] == "processing"
    assert transfer.json()["entry_class_code"] == "WEB"
    assert fake_column.transfer_calls[0]["amount_cents"] == 18742
    assert fake_column.transfer_calls[0]["entry_class_code"] == "WEB"

    injected = dict(transfer_body)
    injected["request_id"] = str(uuid4())
    injected["status"] = "settled"
    injected["entry_class_code"] = "PPD"
    assert client.post("/column/transfers", json=injected).status_code == 422
