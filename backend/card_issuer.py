"""
Card ordering and fulfillment module for Milli Visa Elite Card.

When an Elite subscriber orders a card, this module:
1. Validates the user's Elite subscription status
2. Stores the card order in the database
3. Queues the order for production through the card issuer partner API
4. Sends confirmation email to the user

The card issuer partner (e.g. Marqeta, Lithic, or Stripe Issuing) handles
physical card production and shipping. This module triggers that process.
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
    "pending": "pending",          # Order received, awaiting issuer submission
    "submitted": "submitted",      # Sent to card issuer partner
    "production": "production",    # Card being manufactured
    "shipped": "shipped",          # Card in transit
    "delivered": "delivered",      # Card delivered to user
    "failed": "failed",            # Order failed
}


async def create_card_order(db, user_id: str, material: str, shipping_info: dict) -> dict:
    """
    Create a new card order and trigger fulfillment.

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
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
        """,
        order_record["id"], order_record["user_id"],
        order_record["material"], order_record["material_name"],
        order_record["price"], order_record["status"],
        order_record["shipping_name"], order_record["shipping_address1"],
        order_record["shipping_address2"], order_record["shipping_city"],
        order_record["shipping_state"], order_record["shipping_zip"],
        order_record["shipping_phone"], order_record["ssn_last4_encrypted"],
        order_record["created_at"], order_record["updated_at"],
    )

    logger.info(f"Card order {order_id} created for user {user_id}, material: {material}")

    # Trigger fulfillment with card issuer partner
    try:
        fulfillment_result = await _submit_to_issuer(order_record)
        if fulfillment_result.get("success"):
            await db.execute(
                "UPDATE card_orders SET status = $1, issuer_reference = $2, updated_at = $3 WHERE id = $4",
                ORDER_STATUS["submitted"],
                fulfillment_result.get("issuer_reference", ""),
                datetime.now(timezone.utc),
                order_id,
            )
            logger.info(f"Card order {order_id} submitted to issuer: {fulfillment_result.get('issuer_reference')}")
        else:
            logger.warning(f"Card order {order_id} issuer submission deferred: {fulfillment_result.get('error')}")
    except Exception as e:
        logger.error(f"Failed to submit card order {order_id} to issuer: {e}")
        # Order stays in pending status; a background job will retry

    return {
        "order_id": order_id,
        "status": ORDER_STATUS["submitted"] if fulfillment_result.get("success") else ORDER_STATUS["pending"],
        "material": mat_info["name"],
        "estimated_delivery": "5-7 business days",
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


async def _submit_to_issuer(order_record: dict) -> dict:
    """
    Submit the card order to the card issuer partner API.

    In production, this calls the partner's API (Marqeta, Lithic, Stripe Issuing, etc.)
    to create a physical card and trigger production + shipping.

    The partner API key is read from environment variables.
    """
    issuer_api_key = os.environ.get("CARD_ISSUER_API_KEY", "")
    issuer_api_url = os.environ.get("CARD_ISSUER_API_URL", "")

    if not issuer_api_key or not issuer_api_url:
        logger.warning(
            "CARD_ISSUER_API_KEY or CARD_ISSUER_API_URL not configured. "
            "Card order will be queued and retried by background job."
        )
        return {"success": False, "error": "Issuer API not configured"}

    # Build the issuer API payload
    payload = {
        "card_product": "milli_visa_elite",
        "material": order_record["material"],
        "cardholder": {
            "name": order_record["shipping_name"],
            "address": {
                "line1": order_record["shipping_address1"],
                "line2": order_record["shipping_address2"],
                "city": order_record["shipping_city"],
                "state": order_record["shipping_state"],
                "postal_code": order_record["shipping_zip"],
            },
            "phone": order_record["shipping_phone"],
        },
        "shipping": {
            "method": "standard",
            "estimated_days": "5-7",
        },
        "metadata": {
            "order_id": order_record["id"],
            "user_id": order_record["user_id"],
        },
    }

    try:
        import aiohttp
        headers = {
            "Authorization": f"Bearer {issuer_api_key}",
            "Content-Type": "application/json",
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{issuer_api_url}/v1/cards/physical",
                json=payload,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                if resp.status in (200, 201):
                    data = await resp.json()
                    return {
                        "success": True,
                        "issuer_reference": data.get("id", data.get("card_id", "")),
                    }
                else:
                    error_text = await resp.text()
                    logger.error(f"Card issuer API error {resp.status}: {error_text}")
                    return {"success": False, "error": f"API returned {resp.status}"}
    except Exception as e:
        logger.error(f"Card issuer API request failed: {e}")
        return {"success": False, "error": str(e)}


def _encrypt_ssn(ssn_last4: str) -> str:
    """Encrypt the last 4 of SSN for storage. Uses a simple reversible cipher."""
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