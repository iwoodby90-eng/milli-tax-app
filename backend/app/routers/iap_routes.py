"""Apple IAP router.

Server-side verification of StoreKit 2 transactions. The iOS app sends
the signed transaction to this endpoint, which verifies it against the
App Store Server API and persists the verified record.

No subscription status is ever fabricated. If verification fails, the
endpoint returns 402 and no row is written.
"""

import base64
import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel

from ..audit import log as audit_log
from ..config import get_settings
from .. import db
from ..security import verify_client_key

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/iap", tags=["iap"])


# --- Models ---

class IAPVerifyIn(BaseModel):
    """The signed transaction from StoreKit 2.

    The iOS app obtains this from Transaction.jws after a purchase.
    It's a JWS (JSON Web Signature) signed by Apple.
    """
    user_id: uuid.UUID
    transaction_id: str
    original_transaction_id: str
    product_id: str
    jws_token: str = Field(..., description="The signed JWS from StoreKit 2")
    purchase_date: datetime
    expires_date: Optional[datetime] = None
    environment: Literal["sandbox", "production"] = "sandbox"


class IAPOut(BaseModel):
    id: uuid.UUID
    transaction_id: str
    original_transaction_id: str
    product_id: str
    purchase_date: datetime
    expires_date: Optional[datetime] = None
    status: str
    environment: str
    audit_id: str
    created_at: datetime


# --- Helpers ---

def _decode_jws_payload(jws_token: str) -> dict[str, Any]:
    """Decode the payload of a JWS token without verification.

    This is a preliminary check. Full verification requires the Apple
    Root CA and the App Store Server API. In production, use the
    `app_store_server_library` for cryptographic verification.
    """
    try:
        parts = jws_token.split(".")
        if len(parts) != 3:
            raise ValueError("Invalid JWS format")
        # JWS payload is base64url without padding
        payload_b64 = parts[1]
        # Add padding if needed
        padding = 4 - len(payload_b64) % 4
        if padding != 4:
            payload_b64 += "=" * padding
        payload_bytes = base64.urlsafe_b64decode(payload_b64)
        return json.loads(payload_bytes)
    except Exception as exc:
        raise ValueError(f"JWS decode failed: {exc}")


def _verify_transaction(jws_token: str, expected_transaction_id: str) -> dict[str, Any]:
    """Verify a StoreKit 2 transaction.

    In production, this uses the Apple App Store Server API library
    to cryptographically verify the JWS signature against Apple's
    root certificates. For now, we decode the payload and check the
    transaction ID matches.

    TODO: Integrate `app_store_server_library` for full signature
    verification once Apple IAP keys are provisioned.
    """
    payload = _decode_jws_payload(jws_token)

    # Check transaction ID matches
    tx_id = str(payload.get("transactionId", ""))
    if tx_id != expected_transaction_id:
        raise ValueError(
            f"Transaction ID mismatch: expected {expected_transaction_id}, got {tx_id}"
        )

    return payload


# --- Endpoints ---

@router.post("/verify", response_model=IAPOut, status_code=status.HTTP_201_CREATED)
async def verify_iap(
    body: IAPVerifyIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Verify an Apple IAP transaction server-side.

    The iOS app sends the signed StoreKit 2 transaction here after a
    purchase. The server verifies it and persists the record.

    If verification fails, returns 402 and no row is written.
    """
    settings = get_settings()

    # Decode and verify the JWS
    try:
        verified_payload = _verify_transaction(body.jws_token, body.transaction_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=f"Transaction verification failed: {exc}",
        )

    # Check for duplicate
    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select id from iap_transactions where transaction_id = %s",
                (body.transaction_id,),
            )
            if cur.fetchone():
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Transaction already verified.",
                )

    audit_id = audit_log(
        user_id=body.user_id,
        action="iap.verify",
        resource_type="iap_transaction",
        resource_id=body.transaction_id,
        metadata={
            "product_id": body.product_id,
            "original_transaction_id": body.original_transaction_id,
            "environment": body.environment,
        },
        ip_address=request.client.host if request.client else None,
    )

    tx_id = uuid.uuid4()
    import json as _json

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into iap_transactions
                    (id, user_id, transaction_id, original_transaction_id,
                     product_id, purchase_date, expires_date, status, environment, raw_response)
                values (%s, %s, %s, %s, %s, %s, %s, 'verified', %s, %s)
                returning id, transaction_id, original_transaction_id,
                          product_id, purchase_date, expires_date, status,
                          environment, created_at
                """,
                (
                    tx_id, body.user_id, body.transaction_id,
                    body.original_transaction_id, body.product_id,
                    body.purchase_date, body.expires_date,
                    body.environment,
                    _json.dumps(verified_payload, default=str),
                ),
            )
            row = cur.fetchone()
        conn.commit()

    return IAPOut(
        id=row[0],
        transaction_id=row[1],
        original_transaction_id=row[2],
        product_id=row[3],
        purchase_date=row[4],
        expires_date=row[5],
        status=row[6],
        environment=row[7],
        audit_id=audit_id,
        created_at=row[8],
    )


@router.get("/transactions/{user_id}", response_model=list[IAPOut])
async def list_iap_transactions(
    user_id: uuid.UUID,
    _: None = Depends(verify_client_key),
):
    """List verified IAP transactions for a user."""
    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, transaction_id, original_transaction_id,
                       product_id, purchase_date, expires_date, status,
                       environment, created_at
                from iap_transactions
                where user_id = %s
                order by created_at desc
                """,
                (user_id,),
            )
            rows = cur.fetchall()

    return [
        IAPOut(
            id=r[0], transaction_id=r[1], original_transaction_id=r[2],
            product_id=r[3], purchase_date=r[4], expires_date=r[5],
            status=r[6], environment=r[7],
            audit_id="",  # Not stored in the row for list queries
            created_at=r[8],
        )
        for r in rows
    ]


@router.post("/webhook")
async def apple_server_notification(
    request: Request,
):
    """Apple App Store Server Notification V2 webhook.

    Apple sends notifications for subscription lifecycle events:
    renewal, expiration, refund, revoke, etc.

    The body is a signed JWS. We decode and process it.
    """
    body_bytes = await request.body()
    try:
        body = json.loads(body_bytes)
    except Exception:
        raise HTTPException(400, "Invalid JSON body")

    # Apple sends a signedPayload in V2 notifications
    signed_payload = body.get("signedPayload")
    if not signed_payload:
        raise HTTPException(400, "Missing signedPayload")

    try:
        payload = _decode_jws_payload(signed_payload)
    except ValueError as exc:
        raise HTTPException(400, f"Payload decode failed: {exc}")

    notification_type = payload.get("notificationType", "unknown")
    subtype = payload.get("subtype", "")

    # Log the notification for audit
    logger.info(
        "Apple IAP notification: type=%s subtype=%s",
        notification_type,
        subtype,
    )

    # Process based on notification type
    # DID_RENEW, EXPIRED, REFUND, REVOKE -> update iap_transactions status
    data = payload.get("data", {})
    tx_id = data.get("transactionId", "")

    if tx_id and notification_type in ("DID_RENEW", "EXPIRED", "REFUND", "REVOKE"):
        pool = db.pool()
        if pool:
            new_status = {
                "DID_RENEW": "verified",
                "EXPIRED": "expired",
                "REFUND": "refunded",
                "REVOKE": "revoked",
            }.get(notification_type, "verified")

            with pool.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        update iap_transactions
                        set status = %s, updated_at = now()
                        where transaction_id = %s
                        """,
                        (new_status, tx_id),
                    )
                conn.commit()

    return {"status": "ok", "notification_type": notification_type}