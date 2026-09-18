"""PostgreSQL integration tests for Unit provider-state ingestion."""

import base64
import hashlib
import hmac
import json
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


@pytest.fixture
def unit_db_client(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")

    schema = "milli_unit_" + uuid4().hex
    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))

        root = Path(__file__).parents[1] / "migrations"
        conn.execute((root / "003_create_plaid_and_tax_vault.sql").read_text())
        conn.execute((root / "004_create_server_auth.sql").read_text())
        conn.execute((root / "005_create_unit_money_movement.sql").read_text())
        conn.commit()

        @contextmanager
        def connection():
            yield conn

        monkeypatch.setattr(db, "connection", connection)
        monkeypatch.setenv("DATABASE_URL", "postgresql://configured-for-test")
        monkeypatch.setenv("UNIT_WEBHOOK_SECRET", "unit-test-secret")
        get_settings.cache_clear()

        try:
            with TestClient(app) as client:
                yield client, conn
        finally:
            get_settings.cache_clear()
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def _signed_headers(raw: bytes) -> dict[str, str]:
    signature = base64.b64encode(
        hmac.new(b"unit-test-secret", raw, hashlib.sha1).digest()
    ).decode("ascii")
    return {
        "Content-Type": "application/json",
        "X-Unit-Signature": signature,
    }


def test_unit_webhook_is_idempotent_and_provider_authoritative(unit_db_client):
    client, conn = unit_db_client
    user_id = uuid4()
    movement_id = uuid4()
    request_id = uuid4()
    idempotency_key = uuid4()
    payment_id = "unit-payment-" + uuid4().hex

    with conn.cursor() as cur:
        cur.execute(
            """
            insert into milli_users (id, apple_subject)
            values (%s, %s)
            """,
            (user_id, "apple-" + uuid4().hex),
        )
        cur.execute(
            """
            insert into unit_money_movements
                (id, user_id, client_request_id, idempotency_key,
                 provider_payment_id, source_account_id, linked_account_id,
                 amount_cents, direction, status)
            values (%s, %s, %s, %s, %s, %s, %s, %s, 'Credit', 'pending')
            """,
            (
                movement_id,
                user_id,
                request_id,
                idempotency_key,
                payment_id,
                "unit-account-1",
                "unit-linked-1",
                2500,
            ),
        )
    conn.commit()

    event = {
        "data": [
            {
                "id": "evt-" + uuid4().hex,
                "type": "payment.sent",
                "attributes": {"amount": 2500, "direction": "Credit"},
                "relationships": {
                    "payment": {"data": {"type": "achPayment", "id": payment_id}}
                },
            }
        ]
    }
    raw = json.dumps(event, separators=(",", ":")).encode("utf-8")
    headers = _signed_headers(raw)

    first = client.post("/unit/webhook", content=raw, headers=headers)
    assert first.status_code == 200, first.text
    assert first.json()["new_events"] == 1

    with conn.cursor() as cur:
        cur.execute(
            "select status from unit_money_movements where id = %s",
            (movement_id,),
        )
        assert cur.fetchone()[0] == "sent"

    replay = client.post("/unit/webhook", content=raw, headers=headers)
    assert replay.status_code == 200, replay.text
    assert replay.json()["new_events"] == 0

    with conn.cursor() as cur:
        cur.execute(
            "select count(*) from unit_webhook_events where provider_payment_id = %s",
            (payment_id,),
        )
        assert cur.fetchone()[0] == 1
