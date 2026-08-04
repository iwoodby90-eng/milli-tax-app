"""
Card order API routes for the Milli backend.

Add these routes to the FastAPI app in server.py by calling:
    from card_routes import register_card_routes
    register_card_routes(app, db_pool)
"""
import logging
import json
import os
from fastapi import APIRouter, HTTPException, Depends, Request, Header

from card_issuer import (
    create_card_order,
    get_card_order,
    sync_card_status_from_stripe,
    CARD_ORDERS_SCHEMA,
)

logger = logging.getLogger(__name__)


def register_card_routes(app, db_pool):
    """Register card order routes on the FastAPI app."""

    @app.post("/api/card/order")
    async def place_card_order(request: Request):
        """Place a new card order. User must be on Elite plan."""
        user = request.state.user
        if not user:
            raise HTTPException(status_code=401, detail="Not authenticated")

        body = await request.json()
        material = body.get("material", "metal")

        # Validate Elite subscription
        if user.get("plan") != "elite":
            raise HTTPException(
                status_code=403,
                detail="Milli Visa Elite Card is only available for Elite members."
            )

        shipping_info = {
            "legalName": body.get("legalName", ""),
            "address1": body.get("address1", ""),
            "address2": body.get("address2", ""),
            "city": body.get("city", ""),
            "state": body.get("state", ""),
            "zip": body.get("zip", ""),
            "phone": body.get("phone", ""),
            "ssnLast4": body.get("ssnLast4", ""),
        }

        # Validate required fields
        required = ["legalName", "address1", "city", "state", "zip", "phone", "ssnLast4"]
        for field in required:
            if not shipping_info.get(field):
                raise HTTPException(status_code=422, detail=f"Missing required field: {field}")

        async with db_pool.acquire() as db:
            try:
                result = await create_card_order(db, user["id"], material, shipping_info)
                return {"success": True, **result}
            except ValueError as e:
                raise HTTPException(status_code=400, detail=str(e))
            except Exception as e:
                logger.error(f"Card order failed: {e}")
                raise HTTPException(status_code=500, detail="Failed to place card order")

    @app.get("/api/card/order")
    async def get_user_card_order(request: Request):
        """Get the user's card order status."""
        user = request.state.user
        if not user:
            raise HTTPException(status_code=401, detail="Not authenticated")

        async with db_pool.acquire() as db:
            order = await get_card_order(db, user["id"])
            if not order:
                return {"has_order": False}
            return {"has_order": True, "order": order}

    @app.get("/api/card/order/{order_id}")
    async def get_card_order_by_id(order_id: str, request: Request):
        """Get a specific card order by ID (admin or owner only)."""
        user = request.state.user
        if not user:
            raise HTTPException(status_code=401, detail="Not authenticated")

        async with db_pool.acquire() as db:
            row = await db.fetchrow(
                """SELECT * FROM card_orders WHERE id = $1 AND user_id = $2""",
                order_id, user["id"],
            )
            if not row:
                raise HTTPException(status_code=404, detail="Order not found")
            return dict(row)

    @app.post("/api/card/webhook")
    async def stripe_card_webhook(request: Request, stripe_signature: str = Header(None)):
        """
        Stripe webhook endpoint for card status updates.
        Stripe sends events when a physical card is manufactured, shipped, or delivered.
        Configure this URL in Stripe Dashboard > Developers > Webhooks.
        """
        payload = await request.body()

        # Verify Stripe webhook signature
        stripe_secret_key = os.environ.get("STRIPE_SECRET_KEY", "")
        webhook_secret = os.environ.get("STRIPE_CARD_WEBHOOK_SECRET", "")

        if not stripe_secret_key or not webhook_secret:
            logger.warning("Stripe webhook secret not configured")
            raise HTTPException(status_code=503, detail="Webhook not configured")

        import stripe
        stripe.api_key = stripe_secret_key

        try:
            event = stripe.Webhook.construct_event(
                payload, stripe_signature, webhook_secret
            )
        except stripe.error.SignatureVerificationError:
            raise HTTPException(status_code=400, detail="Invalid signature")
        except Exception as e:
            logger.error(f"Webhook construction failed: {e}")
            raise HTTPException(status_code=400, detail="Invalid payload")

        # Handle card-related events
        if event["type"] == "issuing_card.created":
            logger.info(f"Stripe card created event: {event['data']['object']['id']}")
        elif event["type"] == "issuing_card.updated":
            card_obj = event["data"]["object"]
            stripe_card_id = card_obj["id"]
            # Map Stripe card status to our order status
            stripe_status = card_obj.get("status", "")
            status_map = {
                "pending": "production",   # Card being manufactured
                "active": "shipped",       # Card shipped and active
                "inactive": "submitted",   # Card created but not yet active
            }
            new_status = status_map.get(stripe_status)
            if new_status:
                async with db_pool.acquire() as db:
                    await sync_card_status_from_stripe(db, stripe_card_id, new_status)

        elif event["type"] == "issuing_cardholder.created":
            logger.info(f"Stripe cardholder created: {event['data']['object']['id']}")

        return {"received": True}

    logger.info("Card order routes registered (with Stripe webhook)")