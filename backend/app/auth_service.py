"""Server-side identity verification and opaque session issuance."""

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import hashlib
import secrets
import uuid
from typing import Any

import jwt
from jwt import PyJWKClient
from fastapi import HTTPException, status
from psycopg.errors import UniqueViolation

from . import db
from .config import get_settings
from .security import token_hash, constant_time_equal


APPLE_ISSUER = "https://appleid.apple.com"
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
_apple_jwks = PyJWKClient(APPLE_JWKS_URL, cache_keys=True, lifespan=3600)


@dataclass(frozen=True)
class IssuedSession:
    user_id: uuid.UUID
    access_token: str
    refresh_token: str
    access_expires_at: datetime
    refresh_expires_at: datetime


def _require_auth_config() -> None:
    settings = get_settings()
    if not settings.db_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "authentication unavailable: DATABASE_URL is not configured")
    if not settings.apple_auth_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "authentication unavailable: APPLE_SIGN_IN_AUDIENCE is not configured")


def create_apple_challenge() -> tuple[uuid.UUID, str, datetime]:
    _require_auth_config()
    settings = get_settings()
    challenge_id = uuid.uuid4()
    nonce = secrets.token_urlsafe(32)
    nonce_hash = hashlib.sha256(nonce.encode("utf-8")).hexdigest()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.auth_challenge_ttl_minutes)

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into auth_challenges (id, nonce_hash, expires_at)
                values (%s, %s, %s)
                """,
                (challenge_id, nonce_hash, expires_at),
            )
        conn.commit()
    return challenge_id, nonce, expires_at


def verify_apple_identity_token(identity_token: str) -> dict[str, Any]:
    """Verify Apple's signature and mandatory OpenID claims."""
    settings = get_settings()
    try:
        signing_key = _apple_jwks.get_signing_key_from_jwt(identity_token)
        claims = jwt.decode(
            identity_token,
            signing_key.key,
            algorithms=["RS256"],
            audience=settings.apple_sign_in_audience,
            issuer=APPLE_ISSUER,
            options={"require": ["exp", "iat", "iss", "aud", "sub", "nonce"]},
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Apple identity token verification failed") from exc

    if not claims.get("sub"):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Apple identity token is missing subject")
    return claims


def _as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() == "true"
    return False


def _new_session(cur, user_id: uuid.UUID) -> IssuedSession:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    access_expires = now + timedelta(minutes=settings.auth_access_ttl_minutes)
    refresh_expires = now + timedelta(days=settings.auth_refresh_ttl_days)
    access_token = secrets.token_urlsafe(48)
    refresh_token = secrets.token_urlsafe(64)

    cur.execute(
        """
        insert into auth_sessions
            (id, user_id, access_token_hash, refresh_token_hash,
             access_expires_at, refresh_expires_at)
        values (%s, %s, %s, %s, %s, %s)
        """,
        (
            uuid.uuid4(),
            user_id,
            token_hash(access_token),
            token_hash(refresh_token),
            access_expires,
            refresh_expires,
        ),
    )
    return IssuedSession(user_id, access_token, refresh_token, access_expires, refresh_expires)


def exchange_apple_identity(challenge_id: uuid.UUID, identity_token: str) -> IssuedSession:
    _require_auth_config()
    claims = verify_apple_identity_token(identity_token)
    nonce_claim = str(claims["nonce"])
    nonce_hash = hashlib.sha256(nonce_claim.encode("utf-8")).hexdigest()
    apple_subject = str(claims["sub"])
    email = claims.get("email")
    email_verified = _as_bool(claims.get("email_verified"))

    with db.connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    select nonce_hash, expires_at, used_at
                      from auth_challenges
                     where id = %s
                     for update
                    """,
                    (challenge_id,),
                )
                challenge = cur.fetchone()
                if challenge is None:
                    raise HTTPException(status.HTTP_401_UNAUTHORIZED, "authentication challenge is invalid")
                if challenge[2] is not None or challenge[1] <= datetime.now(timezone.utc):
                    raise HTTPException(status.HTTP_401_UNAUTHORIZED, "authentication challenge expired or already used")
                if not constant_time_equal(challenge[0], nonce_hash):
                    raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Apple identity nonce mismatch")

                cur.execute(
                    """
                    insert into milli_users (id, apple_subject, email, email_verified)
                    values (%s, %s, %s, %s)
                    on conflict (apple_subject) do update
                       set email = coalesce(excluded.email, milli_users.email),
                           email_verified = excluded.email_verified or milli_users.email_verified,
                           updated_at = now()
                    returning id
                    """,
                    (uuid.uuid4(), apple_subject, email, email_verified),
                )
                user_id = cur.fetchone()[0]

                cur.execute(
                    "update auth_challenges set used_at = now() where id = %s",
                    (challenge_id,),
                )
                issued = _new_session(cur, user_id)
            conn.commit()
            return issued
        except UniqueViolation as exc:
            conn.rollback()
            raise HTTPException(status.HTTP_409_CONFLICT, "authentication state conflict") from exc


def rotate_refresh_token(refresh_token: str) -> IssuedSession:
    _require_auth_config()
    digest = token_hash(refresh_token)
    settings = get_settings()
    now = datetime.now(timezone.utc)
    new_access = secrets.token_urlsafe(48)
    new_refresh = secrets.token_urlsafe(64)
    access_expires = now + timedelta(minutes=settings.auth_access_ttl_minutes)
    refresh_expires = now + timedelta(days=settings.auth_refresh_ttl_days)

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, user_id
                  from auth_sessions
                 where refresh_token_hash = %s
                   and revoked_at is null
                   and refresh_expires_at > now()
                 for update
                """,
                (digest,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh session expired or invalid")
            cur.execute(
                """
                update auth_sessions
                   set access_token_hash = %s,
                       refresh_token_hash = %s,
                       access_expires_at = %s,
                       refresh_expires_at = %s,
                       last_seen_at = now()
                 where id = %s
                """,
                (token_hash(new_access), token_hash(new_refresh), access_expires, refresh_expires, row[0]),
            )
        conn.commit()
    return IssuedSession(row[1], new_access, new_refresh, access_expires, refresh_expires)


def revoke_session(session_id: uuid.UUID) -> None:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "update auth_sessions set revoked_at = now() where id = %s and revoked_at is null",
                (session_id,),
            )
        conn.commit()
