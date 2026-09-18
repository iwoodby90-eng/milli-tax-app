"""Authorization boundary for every user-scoped backend route.

The mobile app is untrusted. A client-provided UUID or embedded shared secret is
never proof of identity. User identity is derived only from an opaque server
session issued after cryptographic Sign in with Apple verification.
"""

from dataclasses import dataclass
import hashlib
import hmac
from uuid import UUID

from fastapi import Header, HTTPException, status

from . import db
from .config import get_settings


@dataclass(frozen=True)
class AuthenticatedSession:
    user_id: UUID
    session_id: UUID


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _extract_bearer(authorization: str) -> str:
    scheme, sep, token = authorization.partition(" ")
    if sep != " " or scheme.lower() != "bearer" or not token.strip():
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "missing or invalid bearer session",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return token.strip()


def require_session(authorization: str = Header(default="")) -> AuthenticatedSession:
    settings = get_settings()
    if not settings.db_configured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "authentication unavailable: DATABASE_URL is not configured",
        )

    access_token = _extract_bearer(authorization)
    digest = token_hash(access_token)

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, user_id
                  from auth_sessions
                 where access_token_hash = %s
                   and revoked_at is null
                   and access_expires_at > now()
                 limit 1
                """,
                (digest,),
            )
            row = cur.fetchone()
            if row is not None:
                cur.execute(
                    """
                    update auth_sessions
                       set last_seen_at = now()
                     where id = %s
                       and (last_seen_at is null or last_seen_at < now() - interval '5 minutes')
                    """,
                    (row[0],),
                )
        if row is not None:
            conn.commit()

    if row is None:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "session expired or invalid",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return AuthenticatedSession(session_id=row[0], user_id=row[1])


def require_user(authorization: str = Header(default="")) -> UUID:
    return require_session(authorization).user_id


def constant_time_equal(left: str, right: str) -> bool:
    return hmac.compare_digest(left.encode("utf-8"), right.encode("utf-8"))
