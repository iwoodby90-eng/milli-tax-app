from __future__ import annotations
"""Bearer-only server-verified MILLI identity."""
from uuid import UUID
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from . import db
from .config import get_settings

bearer = HTTPBearer(auto_error=False)

def decode_access_token(token: str) -> dict:
    s = get_settings()
    if not s.auth_jwt_secret:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "authentication unavailable")
    try:
        claims = jwt.decode(
            token, s.auth_jwt_secret, algorithms=["HS256"],
            audience=s.auth_audience, issuer=s.auth_issuer,
            options={"require": ["exp","iat","sub","sid","aud","iss"]},
        )
    except jwt.PyJWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid or expired session")
    if claims.get("typ") != "access":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid session token type")
    return claims

def require_user(credentials: HTTPAuthorizationCredentials | None = Depends(bearer)) -> UUID:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer session")
    claims = decode_access_token(credentials.credentials)
    try:
        user_id, session_id = UUID(claims["sub"]), UUID(claims["sid"])
    except (ValueError, TypeError, KeyError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid session subject")

    if not get_settings().db_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "authentication database unavailable")
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                select 1 from auth_sessions s join users u on u.id=s.user_id
                 where s.id=%s and s.user_id=%s and s.revoked_at is null
                   and s.expires_at>now() and u.account_status='active'
                   and u.deleted_at is null
            """, (session_id, user_id))
            if cur.fetchone() is None:
                raise HTTPException(status.HTTP_401_UNAUTHORIZED, "session revoked or unavailable")
    return user_id
