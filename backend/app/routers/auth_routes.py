"""Authentication endpoints.

Sessions come from an Apple credential exchange or a server-verified
email/password credential. The client never supplies its own user id, and a
local/demo UI credential cannot mint financial-backend authorization.
"""

import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel, EmailStr, Field

from ..auth_service import (
    authenticate_email_identity,
    create_apple_challenge,
    exchange_apple_identity,
    register_email_identity,
    revoke_session,
    rotate_refresh_token,
)
from ..passwords import MAX_PASSWORD_LENGTH, MIN_PASSWORD_LENGTH
from ..security import AuthenticatedSession, require_session

router = APIRouter(prefix="/auth", tags=["auth"])


class AppleChallengeOut(BaseModel):
    challenge_id: uuid.UUID
    nonce: str
    expires_at: str


class AppleExchangeIn(BaseModel):
    challenge_id: uuid.UUID
    identity_token: str = Field(min_length=40)


class EmailCredentialIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=MIN_PASSWORD_LENGTH, max_length=MAX_PASSWORD_LENGTH)


class RefreshIn(BaseModel):
    refresh_token: str = Field(min_length=40)


class SessionOut(BaseModel):
    user_id: uuid.UUID
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    access_expires_at: str
    refresh_expires_at: str


def _session_out(issued) -> SessionOut:
    return SessionOut(
        user_id=issued.user_id,
        access_token=issued.access_token,
        refresh_token=issued.refresh_token,
        access_expires_at=issued.access_expires_at.isoformat(),
        refresh_expires_at=issued.refresh_expires_at.isoformat(),
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


@router.post("/email/signup", response_model=SessionOut, status_code=201)
def email_signup(body: EmailCredentialIn) -> SessionOut:
    return _session_out(register_email_identity(str(body.email), body.password))


@router.post("/email/login", response_model=SessionOut)
def email_login(body: EmailCredentialIn) -> SessionOut:
    return _session_out(authenticate_email_identity(str(body.email), body.password))


@router.post("/refresh", response_model=SessionOut)
def refresh(body: RefreshIn) -> SessionOut:
    return _session_out(rotate_refresh_token(body.refresh_token))


@router.post("/logout", status_code=204)
def logout(session: AuthenticatedSession = Depends(require_session)) -> None:
    revoke_session(session.session_id)
    return None
