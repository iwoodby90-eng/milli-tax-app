"""PostgreSQL integration tests for the server-authenticated financial boundary."""

import os
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

import psycopg
from psycopg import sql
import pytest
from fastapi.testclient import TestClient

from app import auth_service, db
from app.config import get_settings
from app.main import app


@pytest.fixture
def auth_client(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")

    schema = "milli_auth_" + uuid4().hex
    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))

        root = Path(__file__).parents[1] / "migrations"
        conn.execute((root / "003_create_plaid_and_tax_vault.sql").read_text())
        conn.execute((root / "004_create_server_auth.sql").read_text())
        conn.commit()

        @contextmanager
        def connection():
            yield conn

        monkeypatch.setattr(db, "connection", connection)
        monkeypatch.setenv("DATABASE_URL", "postgresql://configured-for-test")
        monkeypatch.setenv("APPLE_SIGN_IN_AUDIENCE", "com.milli.taxvault")
        get_settings.cache_clear()

        try:
            with TestClient(app) as client:
                yield client
        finally:
            get_settings.cache_clear()
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def _mint_session(client, monkeypatch, subject=None):
    challenge = client.post("/auth/apple/challenge")
    assert challenge.status_code == 200, challenge.text
    payload = challenge.json()

    fake_claims = {
        "iss": "https://appleid.apple.com",
        "aud": "com.milli.taxvault",
        "sub": subject or ("apple-user-" + uuid4().hex),
        "iat": int(datetime.now(timezone.utc).timestamp()),
        "exp": int((datetime.now(timezone.utc) + timedelta(minutes=5)).timestamp()),
        "nonce": payload["nonce"],
        "email": "member@privaterelay.appleid.com",
        "email_verified": "true",
    }
    monkeypatch.setattr(auth_service, "verify_apple_identity_token", lambda _token: fake_claims)

    exchanged = client.post(
        "/auth/apple/exchange",
        json={"challenge_id": payload["challenge_id"], "identity_token": "x" * 80},
    )
    assert exchanged.status_code == 200, exchanged.text
    return payload, exchanged.json()


def test_legacy_client_uuid_cannot_authorize_financial_rows(auth_client):
    response = auth_client.get(
        "/tax-vault/balance",
        headers={
            "X-Milli-User-Id": str(uuid4()),
            "X-Milli-Client-Key": "embedded-app-secret",
        },
    )
    assert response.status_code == 401


def test_verified_apple_exchange_mints_bearer_session(auth_client, monkeypatch):
    _, session = _mint_session(auth_client, monkeypatch)
    assert session["is_new_user"] is True
    response = auth_client.get(
        "/tax-vault/balance",
        headers={"Authorization": f"Bearer {session['access_token']}"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["settled_cents"] == 0




def test_apple_exchange_routes_new_then_returning_user_from_server_truth(auth_client, monkeypatch):
    subject = "apple-stable-" + uuid4().hex

    _, first = _mint_session(auth_client, monkeypatch, subject=subject)
    _, second = _mint_session(auth_client, monkeypatch, subject=subject)

    assert first["user_id"] == second["user_id"]
    assert first["is_new_user"] is True
    assert second["is_new_user"] is False


def test_auth_challenge_is_single_use(auth_client, monkeypatch):
    challenge, session = _mint_session(auth_client, monkeypatch)
    assert session["access_token"]

    replay = auth_client.post(
        "/auth/apple/exchange",
        json={"challenge_id": challenge["challenge_id"], "identity_token": "x" * 80},
    )
    assert replay.status_code == 401


def test_refresh_rotates_token_and_old_refresh_cannot_replay(auth_client, monkeypatch):
    _, session = _mint_session(auth_client, monkeypatch)
    first_refresh = session["refresh_token"]

    rotated = auth_client.post("/auth/refresh", json={"refresh_token": first_refresh})
    assert rotated.status_code == 200, rotated.text
    rotated_session = rotated.json()
    assert rotated_session["is_new_user"] is False
    assert rotated_session["refresh_token"] != first_refresh
    assert rotated_session["access_token"] != session["access_token"]

    replay = auth_client.post("/auth/refresh", json={"refresh_token": first_refresh})
    assert replay.status_code == 401


def test_logout_revokes_access_token(auth_client, monkeypatch):
    _, session = _mint_session(auth_client, monkeypatch)
    headers = {"Authorization": f"Bearer {session['access_token']}"}

    assert auth_client.post("/auth/logout", headers=headers).status_code == 204
    assert auth_client.get("/tax-vault/balance", headers=headers).status_code == 401
