"""PostgreSQL coverage for email/password credentials.

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

from app import auth_service, db
from app.main import app
from app.passwords import hash_password, verify_password

PASSWORD = "Sequoia-River-42"


@pytest.fixture
def api(monkeypatch):
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")
    schema = "milli_test_" + uuid4().hex
    migrations = Path(__file__).parents[1] / "migrations"
    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))
        conn.execute((migrations / "003_create_plaid_and_tax_vault.sql").read_text())
        conn.execute((migrations / "004_create_server_auth.sql").read_text())
        conn.execute((migrations / "007_add_email_password_auth.sql").read_text())
        conn.commit()

        @contextmanager
        def connection():
            yield conn

        monkeypatch.setattr(db, "connection", connection)
        monkeypatch.setattr(auth_service, "_require_db", lambda: None)
        try:
            with TestClient(app) as client:
                yield client, conn
        finally:
            conn.rollback()
            conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
            conn.commit()


def test_signup_stores_only_a_digest_and_opens_a_session(api):
    client, conn = api
    response = client.post(
        "/auth/email/signup",
        json={"email": "Driver@Example.com", "password": PASSWORD},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["access_token"] and body["refresh_token"]

    stored = conn.execute("SELECT email, password_hash FROM milli_users").fetchall()
    assert len(stored) == 1
    email, digest = stored[0]
    assert email == "driver@example.com"
    assert PASSWORD not in digest
    assert digest.startswith("scrypt$")

    sessions = conn.execute(
        "SELECT access_token_hash, refresh_token_hash FROM auth_sessions"
    ).fetchall()
    assert len(sessions) == 1
    assert body["access_token"] not in sessions[0]
    assert body["refresh_token"] not in sessions[0]


def test_signup_rejects_a_duplicate_email_regardless_of_case(api):
    client, _ = api
    client.post("/auth/email/signup", json={"email": "a@example.com", "password": PASSWORD})
    duplicate = client.post(
        "/auth/email/signup",
        json={"email": "A@Example.com", "password": PASSWORD},
    )
    assert duplicate.status_code == 409


def test_signup_enforces_the_password_policy(api):
    client, _ = api
    weak = client.post("/auth/email/signup", json={"email": "b@example.com", "password": "password1234"})
    assert weak.status_code == 422
    short = client.post("/auth/email/signup", json={"email": "b@example.com", "password": "Abc1"})
    assert short.status_code == 422


def test_login_succeeds_and_rejects_a_wrong_password_identically_to_unknown_email(api):
    client, _ = api
    client.post("/auth/email/signup", json={"email": "c@example.com", "password": PASSWORD})

    good = client.post("/auth/email/login", json={"email": "c@example.com", "password": PASSWORD})
    assert good.status_code == 200
    assert good.json()["access_token"]

    wrong = client.post("/auth/email/login", json={"email": "c@example.com", "password": "Wrong-Password-1"})
    unknown = client.post("/auth/email/login", json={"email": "nobody@example.com", "password": "Wrong-Password-1"})
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json()


def test_repeated_failures_lock_the_account(api):
    client, conn = api
    client.post("/auth/email/signup", json={"email": "d@example.com", "password": PASSWORD})

    for _ in range(auth_service.MAX_LOGIN_FAILURES):
        assert client.post(
            "/auth/email/login",
            json={"email": "d@example.com", "password": "Wrong-Password-1"},
        ).status_code == 401

    locked = client.post("/auth/email/login", json={"email": "d@example.com", "password": PASSWORD})
    assert locked.status_code == 429

    locked_until = conn.execute("SELECT locked_until FROM milli_users").fetchone()[0]
    assert locked_until is not None


def test_apple_and_email_accounts_can_coexist(api):
    _, conn = api
    conn.execute(
        "INSERT INTO milli_users (id, apple_subject, email) VALUES (%s, %s, %s)",
        (uuid4(), "apple-subject-1", "shared@example.com"),
    )
    conn.execute(
        "INSERT INTO milli_users (id, email, password_hash) VALUES (%s, %s, %s)",
        (uuid4(), "shared@example.com", hash_password(PASSWORD)),
    )
    assert conn.execute("SELECT count(*) FROM milli_users").fetchone()[0] == 2


def test_a_user_row_requires_a_credential(api):
    _, conn = api
    with pytest.raises(psycopg.errors.CheckViolation):
        conn.execute("INSERT INTO milli_users (id, email) VALUES (%s, %s)", (uuid4(), "e@example.com"))
    conn.rollback()


def test_digests_are_salted_per_password(api):
    first = hash_password(PASSWORD)
    second = hash_password(PASSWORD)
    assert first != second
    assert verify_password(PASSWORD, first)
    assert verify_password(PASSWORD, second)
    assert not verify_password(PASSWORD.lower(), first)
