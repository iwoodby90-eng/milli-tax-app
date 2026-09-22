"""PostgreSQL coverage for the authoritative payout-source selection.

Set TEST_DATABASE_URL to an expendable test database. Every test builds and
drops its own schema.
"""

import os
from contextlib import contextmanager
from pathlib import Path
from uuid import uuid4

import psycopg
import pytest
from fastapi.testclient import TestClient
from psycopg import sql

from app import db
from app.main import app
from app.routers import payout_source
from app.security import require_user


def _insert_account(conn, user_id, item_id, account_id, name):
    item_uuid = uuid4()
    conn.execute(
        """
        INSERT INTO plaid_items (id, user_id, item_id, access_token, institution_name)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (item_uuid, user_id, item_id, "access-token", "Test Bank"),
    )
    conn.execute(
        """
        INSERT INTO plaid_accounts (id, user_id, plaid_item_id, account_id, name, mask, type, subtype)
        VALUES (%s, %s, %s, %s, %s, '1234', 'depository', 'checking')
        """,
        (uuid4(), user_id, item_uuid, account_id, name),
    )
    return item_uuid


@pytest.fixture
def payout(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")
    schema = "milli_test_" + uuid4().hex
    user_id = uuid4()
    migrations = Path(__file__).parents[1] / "migrations"
    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))
        conn.execute((migrations / "003_create_plaid_and_tax_vault.sql").read_text())
        conn.execute((migrations / "006_add_plaid_transactions_cursor.sql").read_text())
        conn.commit()

        @contextmanager
        def connection():
            yield conn

        monkeypatch.setattr(db, "connection", connection)
        monkeypatch.setattr(payout_source, "_require_database", lambda: None)
        app.dependency_overrides[require_user] = lambda: user_id
        try:
            with TestClient(app) as client:
                yield client, conn, user_id
        finally:
            app.dependency_overrides.pop(require_user, None)
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def test_payout_source_is_unavailable_until_the_user_selects_one(payout):
    client, conn, user_id = payout
    _insert_account(conn, user_id, "item-a", "acct-a", "Everyday Checking")
    body = client.get("/plaid/payout-source").json()
    assert body["account"] is None
    assert body["data_state"] == "UNAVAILABLE"


def test_selection_is_persisted_and_exclusive(payout):
    client, conn, user_id = payout
    _insert_account(conn, user_id, "item-a", "acct-a", "Everyday Checking")
    _insert_account(conn, user_id, "item-b", "acct-b", "Savings")

    assert client.put("/plaid/payout-source", json={"account_id": "acct-a"}).status_code == 200
    assert client.put("/plaid/payout-source", json={"account_id": "acct-b"}).status_code == 200

    selected = conn.execute(
        "SELECT account_id FROM plaid_accounts WHERE user_id = %s AND is_payout_source",
        (user_id,),
    ).fetchall()
    assert selected == [("acct-b",)]
    assert client.get("/plaid/payout-source").json()["account"]["account_id"] == "acct-b"


def test_another_user_cannot_select_or_read_this_account(payout):
    client, conn, user_id = payout
    _insert_account(conn, user_id, "item-a", "acct-a", "Everyday Checking")
    assert client.put("/plaid/payout-source", json={"account_id": "acct-a"}).status_code == 200

    app.dependency_overrides[require_user] = lambda: uuid4()
    assert client.put("/plaid/payout-source", json={"account_id": "acct-a"}).status_code == 404
    assert client.get("/plaid/payout-source").json()["account"] is None
    assert conn.execute(
        "SELECT count(*) FROM plaid_accounts WHERE user_id = %s AND is_payout_source",
        (user_id,),
    ).fetchone()[0] == 1
