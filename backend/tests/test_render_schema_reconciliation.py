"""Integration coverage for the hosted legacy -> canonical schema reconciliation."""

import os
from pathlib import Path
from uuid import uuid4

import psycopg
from psycopg import sql
import pytest


def test_render_legacy_schema_reconciles_without_losing_user_or_plaid_ownership():
    dsn = os.environ.get("TEST_DATABASE_URL")
    if not dsn:
        pytest.skip("TEST_DATABASE_URL is required for PostgreSQL integration tests")

    schema = "milli_reconcile_" + uuid4().hex
    user_id = uuid4()
    plaid_item_id = uuid4()
    plaid_account_id = uuid4()

    root = Path(__file__).parents[1] / "migrations"

    with psycopg.connect(dsn) as conn:
        conn.execute(sql.SQL("create schema {}").format(sql.Identifier(schema)))
        conn.execute(sql.SQL("set search_path to {}").format(sql.Identifier(schema)))

        # Recreate the important shape of the currently hosted legacy database.
        conn.execute((root / "003_create_plaid_and_tax_vault.sql").read_text())
        conn.execute(
            """
            create table users (
                id uuid primary key,
                apple_subject text not null unique,
                email text,
                display_name text,
                account_status text not null default 'active',
                last_login_at timestamptz,
                created_at timestamptz not null default now(),
                updated_at timestamptz not null default now(),
                deleted_at timestamptz
            )
            """
        )
        conn.execute(
            """
            create table auth_sessions (
                id uuid primary key,
                user_id uuid not null references users(id) on delete cascade,
                refresh_token_hash text not null,
                token_generation integer not null default 0,
                created_at timestamptz not null default now(),
                last_used_at timestamptz,
                expires_at timestamptz not null,
                revoked_at timestamptz
            )
            """
        )
        conn.execute(
            """
            create index auth_sessions_user_active_idx
                on auth_sessions(user_id, expires_at desc)
                where revoked_at is null
            """
        )

        conn.execute(
            """
            insert into users (id, apple_subject, email)
            values (%s, %s, %s)
            """,
            (user_id, "legacy-apple-subject", "legacy@example.com"),
        )
        conn.execute(
            """
            insert into auth_sessions
                (id, user_id, refresh_token_hash, expires_at)
            values (%s, %s, %s, now() + interval '1 day')
            """,
            (uuid4(), user_id, "legacy-refresh-digest"),
        )
        conn.execute(
            """
            insert into plaid_items (id, user_id, item_id, access_token)
            values (%s, %s, %s, %s)
            """,
            (plaid_item_id, user_id, "legacy-item", "legacy-access-token"),
        )
        conn.execute(
            """
            insert into plaid_accounts
                (id, user_id, plaid_item_id, account_id, name, type, subtype)
            values (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                plaid_account_id,
                user_id,
                plaid_item_id,
                "legacy-plaid-account",
                "Legacy Checking",
                "depository",
                "checking",
            ),
        )
        conn.commit()

        conn.execute(sql.SQL("set search_path to {}").format(sql.Identifier(schema)))
        conn.execute((root / "009_reconcile_render_schema.sql").read_text())
        conn.commit()

        canonical_user = conn.execute(
            """
            select id, apple_subject, email
              from milli_users
             where id = %s
            """,
            (user_id,),
        ).fetchone()
        assert canonical_user == (
            user_id,
            "legacy-apple-subject",
            "legacy@example.com",
        )

        # Existing Plaid ownership remains bound to the exact same UUID.
        assert conn.execute(
            "select user_id from plaid_items where id = %s",
            (plaid_item_id,),
        ).fetchone()[0] == user_id
        assert conn.execute(
            "select user_id from plaid_accounts where id = %s",
            (plaid_account_id,),
        ).fetchone()[0] == user_id

        # The legacy session is preserved for audit/recovery but cannot
        # authorize the new backend; the canonical table begins empty.
        assert conn.execute(
            "select count(*) from auth_sessions_legacy_20260926"
        ).fetchone()[0] == 1
        assert conn.execute(
            "select count(*) from auth_sessions"
        ).fetchone()[0] == 0

        session_columns = {
            row[0]
            for row in conn.execute(
                """
                select column_name
                  from information_schema.columns
                 where table_schema = %s
                   and table_name = 'auth_sessions'
                """,
                (schema,),
            ).fetchall()
        }
        assert {
            "access_token_hash",
            "refresh_token_hash",
            "access_expires_at",
            "refresh_expires_at",
            "last_seen_at",
        }.issubset(session_columns)

        plaid_columns = {
            row[0]
            for row in conn.execute(
                """
                select column_name
                  from information_schema.columns
                 where table_schema = %s
                   and table_name = 'plaid_items'
                """,
                (schema,),
            ).fetchall()
        }
        assert "transactions_cursor" in plaid_columns

        required_tables = {
            "column_customer_profiles",
            "column_bank_accounts",
            "column_counterparties",
            "column_ach_transfers",
            "financial_audit_log",
            "column_card_programs",
            "column_card_accounts",
            "column_cards",
        }
        actual_tables = {
            row[0]
            for row in conn.execute(
                """
                select table_name
                  from information_schema.tables
                 where table_schema = %s
                """,
                (schema,),
            ).fetchall()
        }
        assert required_tables.issubset(actual_tables)

        # A second execution must be harmless.
        conn.execute((root / "009_reconcile_render_schema.sql").read_text())
        conn.commit()
        assert conn.execute(
            "select count(*) from milli_users where id = %s",
            (user_id,),
        ).fetchone()[0] == 1

        conn.execute(sql.SQL("drop schema {} cascade").format(sql.Identifier(schema)))
        conn.commit()
