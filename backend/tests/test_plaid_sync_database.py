"""PostgreSQL coverage for Plaid persistence boundaries.

`account_id` and `transaction_id` are unique across the whole table because
Plaid mints them globally, so an upsert keyed on them can reach another user's
row. These tests pin the owner guard, the retraction path, and the per-item
sync cursor. Set TEST_DATABASE_URL to an expendable test database.
"""

import os
from contextlib import contextmanager
from datetime import date
from pathlib import Path
from uuid import uuid4

import psycopg
import pytest
from psycopg import sql

from app import db
from app.routers import plaid_routes


class _FakeBalanceResponse:
    def __init__(self, accounts):
        self._accounts = accounts

    def to_dict(self):
        return {"accounts": self._accounts}


class _FakeClient:
    """Stands in for the Plaid SDK client; returns exactly what it is given."""

    def __init__(self, accounts):
        self._accounts = accounts

    def accounts_balance_get(self, _request):
        return _FakeBalanceResponse(self._accounts)


def _insert_item(conn, user_id, item_id):
    item_uuid = uuid4()
    conn.execute(
        """
        INSERT INTO plaid_items (id, user_id, item_id, access_token, institution_name)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (item_uuid, user_id, item_id, "access-token", "Test Bank"),
    )
    return item_uuid


def _insert_account(conn, user_id, item_uuid, account_id, current_balance):
    account_uuid = uuid4()
    conn.execute(
        """
        INSERT INTO plaid_accounts
            (id, user_id, plaid_item_id, account_id, name, mask, type, subtype, current_balance)
        VALUES (%s, %s, %s, %s, 'Checking', '1234', 'depository', 'checking', %s)
        """,
        (account_uuid, user_id, item_uuid, account_id, current_balance),
    )
    return account_uuid


def _transaction(account_id, transaction_id, amount, name):
    return {
        "account_id": account_id,
        "transaction_id": transaction_id,
        "amount": amount,
        "name": name,
        "date": date(2026, 1, 5),
        "pending": False,
        "iso_currency_code": "USD",
    }


@pytest.fixture
def plaid_db(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")
    schema = "milli_test_" + uuid4().hex
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
        try:
            yield conn
        finally:
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def test_account_upsert_never_overwrites_another_users_balance(plaid_db):
    owner, intruder = uuid4(), uuid4()
    owner_item = _insert_item(plaid_db, owner, "item-owner")
    intruder_item = _insert_item(plaid_db, intruder, "item-intruder")
    _insert_account(plaid_db, owner, owner_item, "acct-shared", 1200)

    client = _FakeClient(
        [{"account_id": "acct-shared", "name": "Spoofed", "balances": {"current": 1}}]
    )
    plaid_routes._sync_accounts(client, intruder_item, intruder, "access-token")

    rows = plaid_db.execute(
        "SELECT user_id, current_balance FROM plaid_accounts WHERE account_id = %s",
        ("acct-shared",),
    ).fetchall()
    assert rows == [(owner, 1200)]


def test_transaction_upsert_never_overwrites_another_users_row(plaid_db):
    owner, intruder = uuid4(), uuid4()
    owner_item = _insert_item(plaid_db, owner, "item-owner")
    intruder_item = _insert_item(plaid_db, intruder, "item-intruder")
    _insert_account(plaid_db, owner, owner_item, "acct-owner", 100)
    _insert_account(plaid_db, intruder, intruder_item, "acct-intruder", 100)

    plaid_routes._store_transactions(
        owner, [_transaction("acct-owner", "txn-shared", 42, "Fuel")]
    )
    plaid_routes._store_transactions(
        intruder, [_transaction("acct-intruder", "txn-shared", 9999, "Rewritten")]
    )

    rows = plaid_db.execute(
        "SELECT user_id, amount, name FROM plaid_transactions WHERE transaction_id = %s",
        ("txn-shared",),
    ).fetchall()
    assert rows == [(owner, 42, "Fuel")]


def test_removed_transactions_are_deleted_only_for_their_owner(plaid_db):
    owner, other = uuid4(), uuid4()
    owner_item = _insert_item(plaid_db, owner, "item-owner")
    other_item = _insert_item(plaid_db, other, "item-other")
    _insert_account(plaid_db, owner, owner_item, "acct-owner", 100)
    _insert_account(plaid_db, other, other_item, "acct-other", 100)
    plaid_routes._store_transactions(owner, [_transaction("acct-owner", "txn-a", 10, "Fuel")])
    plaid_routes._store_transactions(other, [_transaction("acct-other", "txn-b", 20, "Tolls")])

    plaid_routes._remove_transactions(
        owner, [{"transaction_id": "txn-a"}, {"transaction_id": "txn-b"}]
    )

    remaining = plaid_db.execute(
        "SELECT transaction_id, user_id FROM plaid_transactions ORDER BY transaction_id"
    ).fetchall()
    assert remaining == [("txn-b", other)]


def test_sync_cursor_is_persisted_per_item_and_scoped_to_its_owner(plaid_db):
    owner, other = uuid4(), uuid4()
    owner_item = _insert_item(plaid_db, owner, "item-owner")
    other_item = _insert_item(plaid_db, other, "item-other")

    plaid_routes._persist_cursor(owner, owner_item, "cursor-1")
    plaid_routes._persist_cursor(other, owner_item, "cursor-hijack")

    cursors = plaid_db.execute(
        "SELECT id, transactions_cursor FROM plaid_items"
    ).fetchall()
    assert dict(cursors) == {owner_item: "cursor-1", other_item: None}
