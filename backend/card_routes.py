"""
Card order API routes for the Milli backend.

Add these routes to the FastAPI app in server.py by calling:
    from card_routes import register_card_routes
    register_card_routes(app, db_pool)
"""
import logging
from fastapi import APIRouter, HTTPException, Depends

from card_issuer import create_card_order, get_card_order, CARD_ORDERS_SCHEMA

logger = logging.getLogger(__name__)


def register_card_routes(app, db_pool):
    """Register card order routes on the FastAPI app."""

    @app.post("/api/card/order")
    async def place_card_order(request: Request):
        """Place a new card order. User must be on Elite plan."""
        # Get user from auth context
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
                "SELECT * FROM card_orders WHERE id = $1 AND user_id = $2",
                order_id, user["id"],
            )
            if not row:
                raise HTTPException(status_code=404, detail="Order not found")
            return dict(row)

    logger.info("Card order routes registered")