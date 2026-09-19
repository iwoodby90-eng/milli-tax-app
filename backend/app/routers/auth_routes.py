"""Authentication endpoints.

Only the Apple credential exchange creates a user session. Local/demo UI
credentials intentionally cannot mint financial-backend authorization.
"""

import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..auth_service import (
    create_apple_challenge,
    exchange_apple_identity,
    revoke_session,
    rotate_refresh_token,
)
from ..security import AuthenticatedSession, require_session

router = APIRouter(prefix="/auth", tags=["auth"])


class AppleChallengeOut(BaseModel):
    challenge_id: uuid.UUID
    nonce: str
    expires_at: str


class AppleExchangeIn(BaseModel):
    challenge_id: uuid.UUID
    identity_token: str = Field(min_length=40)


class RefreshIn(BaseModel):
    refresh_token: str = Field(min_length=40)


class SessionOut(BaseModel):
    user_id: uuid.UUID
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    access_expires_at: str
    refresh_expires_at: str
    is_new_user: bool = False


def _session_out(issued) -> SessionOut:
    return SessionOut(
        user_id=issued.user_id,
        access_token=issued.access_token,
        refresh_token=issued.refresh_token,
        access_expires_at=issued.access_expires_at.isoformat(),
        refresh_expires_at=issued.refresh_expires_at.isoformat(),
        is_new_user=issued.is_new_user,
    )


@router.post("/apple/challenge", response_model=AppleChallengeOut)
def apple_challenge() -> AppleChallengeOut:
    challenge_id, nonce, expires_at = create_apple_challenge()
    return AppleChallengeOut(
        challenge_id=challenge_id,
        nonce=nonce,
        expires_at=expires_at.isoformat(),
    )


@router.post("/apple/exchange", response_model=SessionOut)
def apple_exchange(body: AppleExchangeIn) -> SessionOut:
    return _session_out(exchange_apple_identity(body.challenge_id, body.identity_token))


@router.post("/refresh", response_model=SessionOut)
def refresh(body: RefreshIn) -> SessionOut:
    return _session_out(rotate_refresh_token(body.refresh_token))


@router.post("/logout", status_code=204)
def logout(session: AuthenticatedSession = Depends(require_session)) -> None:
    revoke_session(session.session_id)
    return None
