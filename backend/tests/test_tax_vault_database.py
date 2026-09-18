"""Exercise the ledger HTTP routes against an isolated PostgreSQL schema.

Set TEST_DATABASE_URL to an expendable test database. No production settings
or pool are used; every test drops its unique schema during teardown.
"""

import os
from contextlib import contextmanager
from pathlib import Path
from uuid import uuid4

import psycopg
from psycopg import sql
import pytest
from fastapi.testclient import TestClient

from app import db
from app.main import app
from app.routers import tax_vault
from app.security import require_user


@pytest.fixture
def ledger(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")
    schema = "milli_test_" + uuid4().hex
    user_id = uuid4()
    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))
        migration = Path(__file__).parents[1] / "migrations/003_create_plaid_and_tax_vault.sql"
        conn.execute(migration.read_text())
        conn.commit()

        @contextmanager
        def connection():
            yield conn

        monkeypatch.setattr(db, "connection", connection)
        monkeypatch.setattr(tax_vault, "_require_db", lambda: None)
        app.dependency_overrides[require_user] = lambda: user_id
        try:
            with TestClient(app) as client:
                yield client, conn, user_id
        finally:
            app.dependency_overrides.pop(require_user, None)
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def test_create_entry_persists_and_stays_out_of_settled_balance(ledger):
    initial_status = "requested"
    client, conn, user_id = ledger
    response = client.post("/tax-vault/entries", json={
        "entry_type": "reserve", "amount_cents": 18742,
        "status": initial_status, "reserve_rate": 0.25,
        "tax_year": 2026, "quarter": 3, "memo": "Regression fixture",
    })
    assert response.status_code == 201, response.text
    entry = response.json()
    row = conn.execute(
        "SELECT user_id, amount_cents, status, settled_at, memo, audit_id "
        "FROM tax_vault_ledger WHERE id = %s", (entry["id"],),
    ).fetchone()
    assert row == (user_id, 18742, initial_status, None, "Regression fixture", entry["audit_id"])
    balance = client.get("/tax-vault/balance").json()
    assert balance["settled_cents"] == 0
    assert balance["pending_cents"] == 18742
    assert client.get("/tax-vault/entries").json()["entries"][0]["id"] == entry["id"]


def test_other_authenticated_user_cannot_read_created_entry(ledger):
    client, _, _ = ledger
    response = client.post("/tax-vault/entries", json={"entry_type": "reserve", "amount_cents": 500})
    assert response.status_code == 201
    other_user = uuid4()
    app.dependency_overrides[require_user] = lambda: other_user
    assert client.get("/tax-vault/entries").json()["entries"] == []
    assert client.get("/tax-vault/balance").json()["pending_cents"] == 0


@pytest.mark.parametrize("payload, status_code", [
    ({"entry_type": "reserve", "amount_cents": 500, "status": "processing"}, 422),
    ({"entry_type": "reserve", "amount_cents": 500, "status": "settled"}, 422),
    ({"entry_type": "reserve", "amount_cents": -500}, 400),
    ({"entry_type": "withdrawal", "amount_cents": 500}, 400),
])
def test_invalid_entries_do_not_write_rows(ledger, payload, status_code):
    client, conn, _ = ledger
    assert client.post("/tax-vault/entries", json=payload).status_code == status_code
    assert conn.execute("SELECT count(*) FROM tax_vault_ledger").fetchone()[0] == 0
