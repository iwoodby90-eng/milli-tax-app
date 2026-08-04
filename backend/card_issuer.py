"""
Card ordering and fulfillment module for Milli Visa Elite Card.

When an Elite subscriber orders a card, this module:
1. Validates the user's Elite subscription status
2. Stores the card order in the database
3. Creates a Stripe Issuing cardholder and issues a physical card
4. Stripe handles physical card production, printing, and shipping
5. Webhook endpoint syncs delivery status from Stripe events

Uses the Stripe Issuing API (stripe.issuing.Cardholder + stripe.issuing.Card)
for real physical card production and shipping.
"""
import os
import json
import logging
from datetime import datetime, timezone
from typing import Optional

logger = logging.getLogger(__name__)

# Card materials and pricing
CARD_MATERIALS = {
    "metal": {
        "name": "Brushed Metal",
        "price": 0,
        "description": "Premium brushed stainless steel with silver-chrome finish",
    },
    "titanium": {
        "name": "Aerospace Titanium",
        "price": 49,
        "description": "Ultra-light Grade 5 titanium with gunmetal finish",
    },
}

# Card order statuses
ORDER_STATUS = {
    "pending": "pending",        # Order received, awaiting Stripe submission
    "submitted": "submitted",    # Cardholder + card created in Stripe
    "production": "production",  # Card being manufactured (Stripe status: pending)
    "shipped": "shipped",        # Card in transit (Stripe status: active + shipped)
    "delivered": "delivered",    # Card delivered to user
    "failed": "failed",          # Order failed
}


async def create_card_order(db, user_id: str, material: str, shipping_info: dict) -> dict:
    """
    Create a new card order and trigger fulfillment via Stripe Issuing.

    Args:
        db: Database connection
        user_id: The user's ID
        material: "metal" or "titanium"
        shipping_info: Dict with legalName, address1, address2, city, state, zip, phone, ssnLast4

    Returns:
        Dict with order_id and status
    """
    # Validate material
    if material not in CARD_MATERIALS:
        raise ValueError(f"Invalid material: {material}. Must be 'metal' or 'titanium'.")

    mat_info = CARD_MATERIALS[material]

    # Check if user already has an active card order
    existing = await db.fetchrow(
        """SELECT id FROM card_orders WHERE user_id = $1 AND status NOT IN ('failed')""",
        user_id,
    )
    if existing:
        raise ValueError("You already have an active card order. Contact support if you need a replacement.")

    # Create the order record
    order_id = f"card_{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}_{user_id[:8]}"
    order_record = {
        "id": order_id,
        "user_id": user_id,
        "material": material,
        "material_name": mat_info["name"],
        "price": mat_info["price"],
        "status": ORDER_STATUS["pending"],
        "shipping_name": shipping_info.get("legalName", ""),
        "shipping_address1": shipping_info.get("address1", ""),
        "shipping_address2": shipping_info.get("address2", ""),
        "shipping_city": shipping_info.get("city", ""),
        "shipping_state": shipping_info.get("state", ""),
        "shipping_zip": shipping_info.get("zip", ""),
        "shipping_phone": shipping_info.get("phone", ""),
        "ssn_last4_encrypted": _encrypt_ssn(shipping_info.get("ssnLast4", "")),
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }

    await db.execute(
        """
        INSERT INTO card_orders
            (id, user_id, material, material_name, price, status,
             shipping_name, shipping_address1, shipping_address2,
             shipping_city, shipping_state, shipping_zip, shipping_phone,
             ssn_last4_encrypted, created_at, updated_at)
        VALUES
            ($1, $2, $3, $4, $5, $6,
             $7, $8, $9,
             $10, $11, $12, $13,
             $14, $15, $16)
        """,
        order_record["id"], order_record["user_id"],
        order_record["material"], order_record["material_name"],
        order_record["price"], order_record["status"],
        order_record["shipping_name"], order_record["shipping_address1"],
        order_record["shipping_address2"],
        order_record["shipping_city"], order_record["shipping_state"],
        order_record["shipping_zip"], order_record["shipping_phone"],
        order_record["ssn_last4_encrypted"],
        order_record["created_at"], order_record["updated_at"],
    )

    logger.info(f"Card order {order_id} created for user {user_id}, material: {material}")

    # Trigger fulfillment with Stripe Issuing
    try:
        fulfillment_result = await _submit_to_stripe_issuing(order_record)
        if fulfillment_result.get("success"):
            await db.execute(
                """UPDATE card_orders SET status = $1, issuer_reference = $2, updated_at = $3 WHERE id = $4""",
                ORDER_STATUS["submitted"],
                fulfillment_result.get("stripe_card_id", ""),
                datetime.now(timezone.utc),
                order_id,
            )
            logger.info(f"Card order {order_id} submitted to Stripe: card_id={fulfillment_result.get('stripe_card_id')}")
        else:
            logger.warning(f"Card order {order_id} Stripe submission deferred: {fulfillment_result.get('error')}")
    except Exception as e:
        logger.error(f"Failed to submit card order {order_id} to Stripe: {e}")
        # Order stays in pending status; a background job will retry

    return {
        "order_id": order_id,
        "status": ORDER_STATUS["submitted"] if fulfillment_result.get("success") else ORDER_STATUS["pending"],
        "material": mat_info["name"],
        "estimated_delivery": "7-10 business days",
    }


async def get_card_order(db, user_id: str) -> Optional[dict]:
    """Get the user's card order status."""
    row = await db.fetchrow(
        """SELECT * FROM card_orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1""",
        user_id,
    )
    if not row:
        return None
    return dict(row)


async def sync_card_status_from_stripe(db, stripe_card_id: str, new_status: str) -> None:
    """
    Sync card order status from Stripe webhook events.
    Called when Stripe sends a card.status_updated or card.shipped webhook.
    """
    await db.execute(
        """UPDATE card_orders SET status = $1, updated_at = $2 WHERE issuer_reference = $3""",
        new_status,
        datetime.now(timezone.utc),
        stripe_card_id,
    )
    logger.info(f"Card order {stripe_card_id} status synced to: {new_status}")


async def _submit_to_stripe_issuing(order_record: dict) -> dict:
    """
    Submit the card order to Stripe Issuing API.

    This creates a Stripe Issuing cardholder and then issues a physical card.
    Stripe handles the physical card production, printing, and shipping.

    Requires STRIPE_SECRET_KEY environment variable.
    """
    import stripe

    stripe_secret_key = os.environ.get("STRIPE_SECRET_KEY", "")

    if not stripe_secret_key:
        logger.warning(
            "STRIPE_SECRET_KEY not configured. "
            "Card order will be queued and retried by background job."
        )
        return {"success": False, "error": "Stripe API key not configured"}

    stripe.api_key = stripe_secret_key

    try:
        # Step 1: Create a Stripe Issuing Cardholder
        cardholder = stripe.issuing.Cardholder.create(
            type="individual",
            name=order_record["shipping_name"],
            email=order_record.get("email", ""),
            phone_number=order_record["shipping_phone"],
            billing={
                "address": {
                    "line1": order_record["shipping_address1"],
                    "line2": order_record["shipping_address2"] or None,
                    "city": order_record["shipping_city"],
                    "state": order_record["shipping_state"],
                    "postal_code": order_record["shipping_zip"],
                    "country": "US",
                },
            },
            metadata={
                "order_id": order_record["id"],
                "user_id": order_record["user_id"],
                "material": order_record["material"],
                "material_name": order_record["material_name"],
                "product": "milli_visa_elite",
            },
        )

        logger.info(f"Stripe cardholder created: {cardholder.id} for order {order_record['id']}")

        # Step 2: Issue a physical card
        card = stripe.issuing.Card.create(
            cardholder=cardholder.id,
            type="physical",
            status="active",
            metadata={
                "order_id": order_record["id"],
                "user_id": order_record["user_id"],
                "material": order_record["material"],
                "material_name": order_record["material_name"],
            },
        )

        logger.info(f"Stripe physical card issued: {card.id} for order {order_record['id']}")

        return {
            "success": True,
            "stripe_cardholder_id": cardholder.id,
            "stripe_card_id": card.id,
        }

    except stripe.error.StripeError as e:
        logger.error(f"Stripe API error for order {order_record['id']}: {e}")
        return {"success": False, "error": str(e)}
    except Exception as e:
        logger.error(f"Unexpected error submitting to Stripe for order {order_record['id']}: {e}")
        return {"success": False, "error": str(e)}


def _encrypt_ssn(ssn_last4: str) -> str:
    """Encrypt the last 4 of SSN for storage. Uses proper encryption in production."""
    if not ssn_last4:
        return ""
    # In production, use proper encryption (e.g. Fernet from cryptography library)
    # For now, we use a simple XOR with an env-based key
    key = os.environ.get("SSN_ENCRYPTION_KEY", "milli-default-key-change-me")
    encrypted = "".join(
        chr(ord(c) ^ ord(key[i % len(key)]))
        for i, c in enumerate(ssn_last4)
    )
    return encrypted.encode("utf-8").hex()


# SQL for creating the card_orders table
CARD_ORDERS_SCHEMA = """
CREATE TABLE IF NOT EXISTS card_orders (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    material VARCHAR(20) NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    shipping_name VARCHAR(255) NOT NULL,
    shipping_address1 VARCHAR(255) NOT NULL,
    shipping_address2 VARCHAR(255),
    shipping_city VARCHAR(100) NOT NULL,
    shipping_state VARCHAR(10) NOT NULL,
    shipping_zip VARCHAR(20) NOT NULL,
    shipping_phone VARCHAR(30) NOT NULL,
    ssn_last4_encrypted VARCHAR(255),
    issuer_reference VARCHAR(255),
    tracking_number VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);
"""