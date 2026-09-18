"""Unit provider webhook boundary.

Unit is the authority for provider payment lifecycle state. The mobile client
cannot post provider statuses. Webhook bodies are authenticated before JSON
parsing, deduplicated by provider event id, and only minimal metadata is stored.
"""

import base64
import hashlib
import hmac
import json
from typing import Any

from fastapi import APIRouter, HTTPException, Request, status

from .. import db
from ..config import get_settings

router = APIRouter(prefix="/unit", tags=["unit"])

_EVENT_TO_STATUS = {
    "payment.created": "pending",
    "payment.pendingReview": "pending_review",
    "payment.clearing": "clearing",
    "payment.sent": "sent",
    "payment.canceled": "canceled",
    "payment.rejected": "rejected",
    "payment.returned": "returned",
}


def _verify_unit_webhook(raw_body: bytes, signature: str | None) -> None:
    settings = get_settings()
    secret = settings.unit_webhook_secret
    if not secret:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Unit webhook verification is not configured",
        )
    if not signature:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "missing X-Unit-Signature",
        )

    expected = base64.b64encode(
        hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha1).digest()
    ).decode("ascii")
    if not hmac.compare_digest(expected, signature.strip()):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "invalid Unit webhook signature",
        )


def _event_list(document: Any) -> list[dict[str, Any]]:
    if not isinstance(document, dict):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid Unit webhook document")
    data = document.get("data")
    if isinstance(data, dict):
        events = [data]
    elif isinstance(data, list):
        events = data
    else:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unit webhook data is missing")
    if len(events) > 100:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "too many Unit events")
    if not all(isinstance(event, dict) for event in events):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid Unit event")
    return events


def _payment_id(event: dict[str, Any]) -> str | None:
    try:
        value = event["relationships"]["payment"]["data"]["id"]
    except (KeyError, TypeError):
        return None
    return str(value) if value is not None else None


@router.post("/webhook")
async def unit_webhook(request: Request) -> dict:
    raw_body = await request.body()
    _verify_unit_webhook(raw_body, request.headers.get("X-Unit-Signature"))

    if not get_settings().db_configured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "DATABASE_URL is not configured",
        )

    try:
        document = json.loads(raw_body)
    except json.JSONDecodeError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid Unit webhook JSON") from exc

    events = _event_list(document)
    payload_digest = hashlib.sha256(raw_body).hexdigest()
    accepted = 0

    with db.connection() as conn:
        with conn.cursor() as cur:
            for event in events:
                event_id = str(event.get("id") or "").strip()
                event_type = str(event.get("type") or "").strip()
                if not event_id or not event_type:
                    raise HTTPException(
                        status.HTTP_400_BAD_REQUEST,
                        "Unit event id and type are required",
                    )

                payment_id = _payment_id(event)
                cur.execute(
                    """
                    insert into unit_webhook_events
                        (provider_event_id, event_type, provider_payment_id, payload_sha256)
                    values (%s, %s, %s, %s)
                    on conflict (provider_event_id) do nothing
                    returning provider_event_id
                    """,
                    (event_id, event_type, payment_id, payload_digest),
                )
                inserted = cur.fetchone()
                if inserted is None:
                    continue

                accepted += 1
                provider_status = _EVENT_TO_STATUS.get(event_type)
                if payment_id and provider_status:
                    cur.execute(
                        """
                        update unit_money_movements
                           set status = %s,
                               last_provider_event_at = now(),
                               updated_at = now()
                         where provider_payment_id = %s
                        """,
                        (provider_status, payment_id),
                    )
        conn.commit()

    return {"received": True, "new_events": accepted}
