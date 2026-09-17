"""Client authentication.

The iOS app sends a shared client key plus the authenticated user id. Row-level
authorization is enforced here: every query is scoped to the user id resolved
from the request, never to a user id chosen freely by the client payload.
"""

from typing import Optional
from uuid import UUID

from fastapi import Header, HTTPException, status

from .config import get_settings


def require_user(
    x_milli_client_key: str = Header(default=""),
    x_milli_user_id: str = Header(default=""),
) -> UUID:
    settings = get_settings()
    if settings.client_api_key and x_milli_client_key != settings.client_api_key:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid client key")
    try:
        return UUID(x_milli_user_id)
    except ValueError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing or invalid X-Milli-User-Id")


def verify_client_key(
    x_milli_client_key: str = Header(default=""),
) -> None:
    """Verify only the client key, without requiring a user ID.

    Used by webhook endpoints and endpoints where the user_id comes
    from the request body rather than the header.
    """
    settings = get_settings()
    if settings.client_api_key and x_milli_client_key != settings.client_api_key:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid client key")
    return None