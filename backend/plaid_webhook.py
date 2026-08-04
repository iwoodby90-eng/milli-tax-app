"""
Plaid webhook receiver for Milli Tax Vault.

When Plaid detects new transactions on a connected bank account,
it sends a webhook to this endpoint. The server then syncs
transactions, detects gig payouts, and runs the autopilot
pipeline to move the correct tax amount to the Milli Tax Vault.

Register this URL in the Plaid dashboard:
    https://api.millionvault.com/api/plaid/webhook

Or set PLAID_WEBHOOK_URL env var when creating link tokens.
"""
from __future__ import annotations

import logging

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/api/plaid/webhook")
async def plaid_webhook(request: Request):
    """
    Receive Plaid webhook notifications.

    Plaid sends webhooks for various events. The key ones for auto
    tax pulling are TRANSACTIONS events:
    - INITIAL_UPDATE: first batch of transactions (30 days)
    - HISTORICAL_UPDATE: full transaction history
    - DEFAULT_UPDATE: new transactions since last sync

    For each, we sync the item and the autopilot pipeline runs
    automatically on any detected gig payouts.
    """
    try:
        body = await request.json()
    except Exception:
        return JSONResponse({"error": "invalid body"}, status_code=400)

    webhook_type = body.get("webhook_type", "")
    webhook_code = body.get("webhook_code", "")
    item_id = body.get("item_id", "")

    logger.info("Plaid webhook: type=%s code=%s item=%s", webhook_type, webhook_code, item_id)

    if webhook_type != "TRANSACTIONS":
        return JSONResponse({"status": "ignored", "reason": f"type {webhook_type} not handled"})

    if webhook_code not in ("INITIAL_UPDATE", "HISTORICAL_UPDATE", "DEFAULT_UPDATE"):
        return JSONResponse({"status": "ignored", "reason": f"code {webhook_code} not handled"})

    # Find the Plaid item and its user
    from server import db, _sync_item
    item = await db.plaid_items.find_one({"item_id": item_id, "status": "active"})
    if not item:
        logger.warning("Webhook for unknown/disconnected item %s", item_id)
        return JSONResponse({"status": "ignored", "reason": "item not found or inactive"})

    user = await db.users.find_one({"id": item["user_id"]})
    if not user:
        logger.warning("Webhook: user %s not found for item %s", item["user_id"], item_id)
        return JSONResponse({"status": "ignored", "reason": "user not found"})

    # Sync transactions — this will detect gig payouts and run autopilot
    try:
        new_deposits = await _sync_item(item, user)
        logger.info("Webhook processed: %d new deposits for user %s", new_deposits, user["id"])
        return JSONResponse({
            "status": "processed",
            "user_id": user["id"],
            "new_deposits": new_deposits,
        })
    except Exception as e:
        logger.error("Webhook sync failed for item %s: %s", item_id, e)
        return JSONResponse({"status": "error", "error": str(e)}, status_code=500)