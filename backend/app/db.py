"""Postgres access via a lazily-created psycopg connection pool."""

from contextlib import contextmanager
from typing import Iterator, Optional

from psycopg_pool import ConnectionPool

from .config import get_settings

_pool: Optional[ConnectionPool] = None


def pool() -> Optional[ConnectionPool]:
    global _pool
    settings = get_settings()
    if not settings.db_configured:
        return None
    if _pool is None:
        _pool = ConnectionPool(
            conninfo=settings.database_url,
            min_size=1,
            max_size=5,
            open=True,
            kwargs={"autocommit": False},
        )
    return _pool


@contextmanager
def connection() -> Iterator[object]:
    p = pool()
    if p is None:
        raise RuntimeError("DATABASE_URL is not configured")
    with p.connection() as conn:
        yield conn


def healthy() -> bool:
    """True only if a real round-trip to Postgres succeeds."""
    try:
        with connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                return cur.fetchone()[0] == 1
    except Exception:
        return False
