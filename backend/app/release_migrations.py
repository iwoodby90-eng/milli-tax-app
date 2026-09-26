"""Controlled hosted-schema reconciliation for Milli releases.

This runner is deliberately opt-in through AUTO_MIGRATE_RELEASE_SCHEMA. It uses
an advisory transaction lock plus a durable migration marker so multiple Render
instances cannot race the same migration and successful migrations are never
re-applied accidentally.
"""

from __future__ import annotations

from pathlib import Path

import psycopg

from .config import get_settings


_MIGRATION_ID = "009_reconcile_render_schema"
_ADVISORY_LOCK_ID = 640_915_202_609_26


def apply_release_migrations() -> None:
    settings = get_settings()
    if not settings.auto_migrate_release_schema:
        return
    if not settings.database_url:
        raise RuntimeError(
            "AUTO_MIGRATE_RELEASE_SCHEMA is enabled but DATABASE_URL is not configured"
        )

    migration_path = (
        Path(__file__).resolve().parents[1]
        / "migrations"
        / "009_reconcile_render_schema.sql"
    )
    migration_sql = migration_path.read_text(encoding="utf-8")

    with psycopg.connect(settings.database_url, autocommit=False) as conn:
        with conn.cursor() as cur:
            cur.execute("select pg_advisory_xact_lock(%s)", (_ADVISORY_LOCK_ID,))
            cur.execute(
                """
                create table if not exists milli_schema_migrations (
                    migration_id text primary key,
                    applied_at timestamptz not null default now()
                )
                """
            )
            cur.execute(
                """
                select 1
                  from milli_schema_migrations
                 where migration_id = %s
                """,
                (_MIGRATION_ID,),
            )
            if cur.fetchone() is not None:
                conn.commit()
                return

            cur.execute(migration_sql)
            cur.execute(
                """
                insert into milli_schema_migrations (migration_id)
                values (%s)
                """,
                (_MIGRATION_ID,),
            )
        conn.commit()
