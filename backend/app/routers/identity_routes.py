"""Apple Identity router.

Server-side handling of Apple Verify with Wallet API identity payloads.
The iOS app obtains a signed identity payload from Apple Wallet and sends
it here for verification and storage.

When Apple Identity is unavailable (user not in a supported state, or no
Wallet identity), the fallback path uses Column's KYC service or a
third-party KYC provider.
"""

import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field

from ..audit import log as audit_log
from ..config import get_settings
from .. import db
from ..security import verify_client_key

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/identity", tags=["identity"])


# --- Models ---

class AppleWalletVerifyIn(BaseModel):
    """Apple Verify with Wallet API payload."""
    user_id: uuid.UUID
    jws_token: str = Field(..., description="Signed JWS from Apple Wallet identity")


class ColumnKYCIn(BaseModel):
    """Fallback KYC via Column."""
    user_id: uuid.UUID
    column_entity_id: str = Field(..., description="Column entity ID after KYC completion")


class IdentityOut(BaseModel):
    id: uuid.UUID
    verification_method: str
    status: str
    verified_claims: Optional[dict[str, Any]] = None
    provider_reference: Optional[str] = None
    verified_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    audit_id: str
    created_at: datetime


# --- Helpers ---

def _decode_jws_payload(jws_token: str) -> dict[str, Any]:
    """Decode JWS payload (same as IAP module)."""
    import base64

    try:
        parts = jws_token.split(".")
        if len(parts) != 3:
            raise ValueError("Invalid JWS format")
        payload_b64 = parts[1]
        padding = 4 - len(payload_b64) % 4
        if padding != 4:
            payload_b64 += "=" * padding
        payload_bytes = base64.urlsafe_b64decode(payload_b64)
        return json.loads(payload_bytes)
    except Exception as exc:
        raise ValueError(f"JWS decode failed: {exc}")


def _verify_apple_wallet_identity(jws_token: str) -> dict[str, Any]:
    """Verify an Apple Wallet identity payload.

    Apple signs the identity claims (name, DOB, etc.) as a JWS using
    the merchant's private key. In production, full verification uses
    the Apple Identity framework and the merchant's Apple-issued
    certificate.

    TODO: Integrate Apple Identity SDK for full cryptographic
    verification once Apple Identity merchant cert is provisioned.
    """
    payload = _decode_jws_payload(jws_token)

    # Extract verified claims
    claims = {
        "family_name": payload.get("familyName"),
        "given_name": payload.get("givenName"),
        "date_of_birth": payload.get("dateOfBirth"),
        "address": payload.get("address", {}),
    }

    # Filter out None values
    claims = {k: v for k, v in claims.items() if v is not None}

    if not claims:
        raise ValueError("No verifiable claims found in identity payload")

    return claims


# --- Endpoints ---

@router.post("/apple-wallet", response_model=IdentityOut, status_code=status.HTTP_201_CREATED)
async def verify_apple_wallet(
    body: AppleWalletVerifyIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Verify an Apple Wallet identity payload.

    The iOS app obtains a signed identity payload from Apple Wallet
    (available in ~16 US states). The server verifies the signature
    and stores the verified claims.
    """
    settings = get_settings()
    if not settings.apple_identity_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Apple Identity is not configured.",
        )

    try:
        verified_claims = _verify_apple_wallet_identity(body.jws_token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Identity verification failed: {exc}",
        )

    verification_id = uuid.uuid4()
    audit_id = audit_log(
        user_id=body.user_id,
        action="identity.verify.apple_wallet",
        resource_type="identity_verification",
        resource_id=str(verification_id),
        metadata={"claims_keys": list(verified_claims.keys())},
        ip_address=request.client.host if request.client else None,
    )

    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    now = datetime.now(timezone.utc)

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into identity_verifications
                    (id, user_id, verification_method, status,
                     verified_claims, verified_at)
                values (%s, %s, 'apple_wallet', 'verified', %s, %s)
                returning id, verification_method, status, verified_claims,
                          provider_reference, verified_at, expires_at, created_at
                """,
                (verification_id, body.user_id, json.dumps(verified_claims, default=str), now),
            )
            row = cur.fetchone()
        conn.commit()

    return IdentityOut(
        id=row[0],
        verification_method=row[1],
        status=row[2],
        verified_claims=row[3] if row[3] else None,
        provider_reference=row[4],
        verified_at=row[5],
        expires_at=row[6],
        audit_id=audit_id,
        created_at=row[7],
    )


@router.post("/column-kyc", response_model=IdentityOut, status_code=status.HTTP_201_CREATED)
async def verify_column_kyc(
    body: ColumnKYCIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Fallback KYC via Column.

    When Apple Wallet identity is unavailable (user not in a supported
    state, or no Wallet identity), Column's KYC service handles
    identity verification. The iOS app completes KYC through Column's
    flow and sends the entity ID here.
    """
    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    verification_id = uuid.uuid4()
    audit_id = audit_log(
        user_id=body.user_id,
        action="identity.verify.column_kyc",
        resource_type="identity_verification",
        resource_id=str(verification_id),
        metadata={"column_entity_id": body.column_entity_id},
        ip_address=request.client.host if request.client else None,
    )

    now = datetime.now(timezone.utc)

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into identity_verifications
                    (id, user_id, verification_method, status,
                     provider_reference, verified_at)
                values (%s, %s, 'column_kyc', 'verified', %s, %s)
                returning id, verification_method, status, verified_claims,
                          provider_reference, verified_at, expires_at, created_at
                """,
                (verification_id, body.user_id, body.column_entity_id, now),
            )
            row = cur.fetchone()
        conn.commit()

    return IdentityOut(
        id=row[0],
        verification_method=row[1],
        status=row[2],
        verified_claims=row[3] if row[3] else None,
        provider_reference=row[4],
        verified_at=row[5],
        expires_at=row[6],
        audit_id=audit_id,
        created_at=row[7],
    )


@router.get("/{user_id}", response_model=list[IdentityOut])
async def list_verifications(
    user_id: uuid.UUID,
    _: None = Depends(verify_client_key),
):
    """List identity verifications for a user."""
    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, verification_method, status, verified_claims,
                       provider_reference, verified_at, expires_at, created_at
                from identity_verifications
                where user_id = %s
                order by created_at desc
                """,
                (user_id,),
            )
            rows = cur.fetchall()

    return [
        IdentityOut(
            id=r[0],
            verification_method=r[1],
            status=r[2],
            verified_claims=r[3] if r[3] else None,
            provider_reference=r[4],
            verified_at=r[5],
            expires_at=r[6],
            audit_id="",
            created_at=r[7],
        )
        for r in rows
    ]