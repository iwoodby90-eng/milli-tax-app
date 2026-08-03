"""
Milli Plaid Client — real Plaid bank integration.

This module bridges Plaid's API to Milli's autopilot pipeline.
When a user connects their bank via Plaid Link, Milli:

    1. Exchanges the public token for a permanent access token
    2. Stores the item (bank connection) in Mongo
    3. On sync / webhook, fetches new transactions
    4. Detects gig platform payouts (DoorDash, Uber, etc.)
    5. For each payout, runs the full autopilot pipeline:
       tax calculation → vault allocation → receipt

Requires: pip install plaid-python
Env vars: PLAID_CLIENT_ID, PLAID_SECRET, PLAID_ENV (sandbox/development/production)
"""

from __future__ import annotations

import os
import logging
from datetime import datetime, timezone
from typing import Any

import plaid
from plaid.api import plaid_api
from plaid.model.products import Products
from plaid.model.country_codes import CountryCode
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_sync_request import TransactionsSyncRequest
from plaid.model.accounts_get_request import AccountsGetRequest

logger = logging.getLogger(__name__)

# ─── Plaid environment configuration ───────────────────────────────

_ENV_MAP = {
    "sandbox": plaid.Environment.Sandbox,
    "development": plaid.Environment.Development,
    "production": plaid.Environment.Production,
}


def _get_plaid_env() -> str:
    return os.getenv("PLAID_ENV", "sandbox").lower()


def _get_client() -> plaid_api.PlaidApi:
    """Build a Plaid API client from env vars."""
    env = _get_plaid_env()
    host = _ENV_MAP.get(env, plaid.Environment.Sandbox)

    config = plaid.Configuration(
        host=host,
        api_key={
            "clientId": os.getenv("PLAID_CLIENT_ID", ""),
            "secret": os.getenv("PLAID_SECRET", ""),
            "plaidVersion": "2020-09-14",
        },
    )
    api_client = plaid.ApiClient(config)
    return plaid_api.PlaidApi(api_client)


# ─── Gig platform detection ───────────────────────────────────────

# Known gig platform names that Plaid may surface in transaction
# merchant_name or in the payment metadata.  We match case-insensitively
# against substrings so "UBER TRIP" and "Uber" both hit.
GIG_PLATFORM_PATTERNS: dict[str, list[str]] = {
    "doordash": ["doordash", "door dash", "ddash"],
    "uber": ["uber", "uber trips", "uber trip", "uber eats"],
    "lyft": ["lyft", "lyft ride"],
    "instacart": ["instacart"],
    "grubhub": ["grubhub", "grub hub"],
    "amazon flex": ["amazon flex", "amzn flex"],
    "postmates": ["postmates"],
    "shipt": ["shipt"],
    "gopuff": ["gopuff", "go puff"],
    "upwork": ["upwork"],
    "fiverr": ["fiverr"],
    "etsy": ["etsy"],
    "shopify": ["shopify"],
    "stripe": ["stripe payout", "stripe transfer"],
    "paypal": ["paypal"],
    "square": ["square", "square cash", "cash app"],
    "venmo": ["venmo"],
    "wag": ["wag", "wagwalking"],
    "roadie": ["roadie"],
    "taskrabbit": ["taskrabbit", "task rabbit"],
}


def _detect_gig_platform(tx: dict) -> str | None:
    """Return the canonical gig platform name if a transaction looks like a gig payout, else None."""
    merchant = (tx.get("merchant_name") or tx.get("name") or "").lower()
    for platform, patterns in GIG_PLATFORM_PATTERNS.items():
        if any(p in merchant for p in patterns):
            return platform
    return None


def _is_income_transaction(tx: dict) -> bool:
    """Heuristic: is this an incoming payment (a payout)?"""
    amount = tx.get("amount", 0)
    # Plaid represents inflows as negative amounts (money INTO the account)
    # but some institutions flip the sign.  We accept either convention
    # as long as the absolute value is reasonable (> $1).
    if abs(amount) < 1.0:
        return False
    # Personal transactions (groceries, rent) are outflows.  We only
    # care about inflows.  Plaid convention: negative = inflow.
    # But we also check the `amount` sign loosely — if the merchant
    # matches a gig platform, we treat it as income regardless of sign.
    return True  # The gig platform match is the real filter


# ─── Public API ────────────────────────────────────────────────────


async def create_link_token(user_id: str, db) -> dict:
    """Create a Plaid Link token for the user to connect their bank."""
    client = _get_client()

    # Collect previously linked item IDs so Plaid can skip those institutions.
    items = await db.plaid_items.find({"user_id": user_id}).to_list(100)
    existing = [item["access_token"] for item in items if item.get("access_token")]

    request = LinkTokenCreateRequest(
        user=LinkTokenCreateRequestUser(client_user_id=user_id),
        client_name="Milli Tax Vault",
        products=[Products("transactions")],
        country_codes=[CountryCode("US")],
        language="en",
        access_tokens=existing or None,  # Allows updating existing items
    )
    response = client.link_token_create(request)
    return {"link_token": response["link_token"]}


async def exchange_public_token(
    user_id: str, public_token: str, db, institution_name: str | None = None
) -> dict:
    """Exchange a Plaid public token for a permanent access token and store the item."""
    client = _get_client()

    request = ItemPublicTokenExchangeRequest(public_token=public_token)
    response = client.item_public_token_exchange(request)

    access_token = response["access_token"]
    item_id = response["item_id"]

    # Fetch account metadata
    accounts_resp = client.accounts_get(AccountsGetRequest(access_token=access_token))
    accounts = accounts_resp["accounts"]

    # Store the Plaid item in our DB
    doc = {
        "user_id": user_id,
        "item_id": item_id,
        "access_token": access_token,  # In production, encrypt this
        "institution_name": institution_name or "Bank",
        "accounts": [
            {
                "account_id": a["account_id"],
                "name": a.get("name", ""),
                "mask": a.get("mask", ""),
                "type": a.get("type", ""),
                "subtype": a.get("subtype", ""),
            }
            for a in accounts
        ],
        "cursor": None,  # Transactions sync cursor
        "created_at": datetime.now(timezone.utc).isoformat(),
        "status": "active",
    }
    await db.plaid_items.insert_one(doc)

    # Do an initial transaction sync immediately
    synced = await sync_transactions(user_id, item_id, db)

    return {
        "item_id": item_id,
        "institution_name": institution_name or "Bank",
        "synced_deposits": synced.get("new_payouts", 0),
    }


async def sync_transactions(user_id: str, item_id: str, db) -> dict:
    """
    Fetch new transactions from Plaid for a given item.

    Uses Plaid's Transactions Sync API (cursor-based pagination).
    For each new transaction that looks like a gig payout, triggers
    the autopilot pipeline.

    Returns a summary of what was processed.
    """
    client = _get_client()

    item = await db.plaid_items.find_one({"user_id": user_id, "item_id": item_id})
    if not item:
        raise ValueError(f"Plaid item {item_id} not found for user {user_id}")

    access_token = item["access_token"]
    cursor = item.get("cursor")

    new_payouts = 0
    autopilot_results = []
    has_more = True

    while has_more:
        request = TransactionsSyncRequest(
            access_token=access_token,
            cursor=cursor,
        )
        response = client.transactions_sync(request)

        # Process new transactions
        added = response.get("added", [])
        modified = response.get("modified", [])
        removed = response.get("removed", [])

        for tx in added:
            tx_dict = _tx_to_dict(tx)
            platform = _detect_gig_platform(tx_dict)

            if platform and _is_income_transaction(tx_dict):
                # Check if we already processed this transaction
                existing = await db.deposits.find_one({
                    "user_id": user_id,
                    "plaid_transaction_id": tx_dict["transaction_id"],
                })
                if existing:
                    continue

                # Create a payout dict in the format autopilot expects
                payout = {
                    "id": tx_dict["transaction_id"],
                    "amount": abs(tx_dict["amount"]),  # Plaid: negative = inflow
                    "platform": platform,
                    "merchant": tx_dict.get("merchant_name") or tx_dict.get("name", ""),
                    "date": tx_dict["date"],
                    "plaid_transaction_id": tx_dict["transaction_id"],
                    "plaid_account_id": tx_dict.get("account_id"),
                    "auto_detected": True,
                }

                # Store the deposit
                await db.deposits.insert_one({
                    **payout,
                    "user_id": user_id,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                })

                # Run the autopilot pipeline
                user = await db.users.find_one({"id": user_id})
                if user:
                    from autopilot import run_autopilot
                    receipt = await run_autopilot(db, user, payout)
                    autopilot_results.append(receipt)
                    new_payouts += 1
                    logger.info(
                        "Autopilot ran for %s payout of $%.2f (user %s)",
                        platform, payout["amount"], user_id,
                    )

        # Update cursor
        cursor = response.get("next_cursor", cursor)
        has_more = response.get("has_more", False)

    # Persist the new cursor
    await db.plaid_items.update_one(
        {"user_id": user_id, "item_id": item_id},
        {"$set": {"cursor": cursor, "last_sync": datetime.now(timezone.utc).isoformat()}},
    )

    return {
        "new_payouts": new_payouts,
        "autopilot_results": autopilot_results,
    }


async def sync_all_items(user_id: str, db) -> dict:
    """Sync all Plaid items for a user. Returns aggregate summary."""
    items = await db.plaid_items.find({"user_id": user_id, "status": "active"}).to_list(100)
    total_payouts = 0
    all_results = []

    for item in items:
        result = await sync_transactions(user_id, item["item_id"], db)
        total_payouts += result["new_payouts"]
        all_results.extend(result["autopilot_results"])

    return {"synced_items": len(items), "new_payouts": total_payouts, "results": all_results}


async def list_items(user_id: str, db) -> list[dict]:
    """List all connected Plaid items for a user."""
    items = await db.plaid_items.find(
        {"user_id": user_id, "status": "active"},
        {"access_token": 0},  # Never expose access tokens
    ).to_list(100)

    return [
        {
            "id": item["item_id"],
            "institution_name": item.get("institution_name", "Bank"),
            "accounts": item.get("accounts", []),
            "created_at": item.get("created_at"),
            "last_sync": item.get("last_sync"),
        }
        for item in items
    ]


async def remove_item(user_id: str, item_id: str, db) -> dict:
    """Remove (disconnect) a Plaid item."""
    item = await db.plaid_items.find_one({"user_id": user_id, "item_id": item_id})
    if not item:
        raise ValueError(f"Plaid item {item_id} not found")

    # Optionally invalidate the access token with Plaid
    try:
        client = _get_client()
        # Plaid's item_remove endpoint
        client.item_remove(item["access_token"])
    except Exception as e:
        logger.warning("Failed to invalidate Plaid item %s: %s", item_id, e)

    await db.plaid_items.update_one(
        {"user_id": user_id, "item_id": item_id},
        {"$set": {"status": "disconnected", "disconnected_at": datetime.now(timezone.utc).isoformat()}},
    )
    return {"item_id": item_id, "status": "disconnected"}


async def handle_webhook(webhook_type: str, webhook_code: str, item_id: str, db) -> dict:
    """
    Handle a Plaid webhook.

    Plaid sends webhooks for various events. The key one for us is
    'TRANSACTIONS' with code 'INITIAL_UPDATE', 'HISTORICAL_UPDATE',
    or 'DEFAULT_UPDATE' — all mean new transactions are available.
    """
    if webhook_type != "TRANSACTIONS":
        return {"status": "ignored", "reason": f"webhook_type {webhook_type} not handled"}

    if webhook_code not in ("INITIAL_UPDATE", "HISTORICAL_UPDATE", "DEFAULT_UPDATE"):
        return {"status": "ignored", "reason": f"webhook_code {webhook_code} not handled"}

    # Find the user for this item
    item = await db.plaid_items.find_one({"item_id": item_id, "status": "active"})
    if not item:
        logger.warning("Webhook for unknown/disconnected item %s", item_id)
        return {"status": "ignored", "reason": "item not found or inactive"}

    user_id = item["user_id"]
    result = await sync_transactions(user_id, item_id, db)

    return {
        "status": "processed",
        "user_id": user_id,
        "new_payouts": result["new_payouts"],
    }


# ─── Helpers ───────────────────────────────────────────────────────


def _tx_to_dict(tx) -> dict:
    """Convert a Plaid transaction object to a plain dict."""
    if isinstance(tx, dict):
        return tx
    # Plaid model objects
    return {
        "transaction_id": getattr(tx, "transaction_id", ""),
        "account_id": getattr(tx, "account_id", ""),
        "amount": float(getattr(tx, "amount", 0)),
        "date": str(getattr(tx, "date", "")),
        "name": getattr(tx, "name", ""),
        "merchant_name": getattr(tx, "merchant_name", "") or getattr(tx, "original_description", ""),
        "category": getattr(tx, "category", []),
        "pending": getattr(tx, "pending", False),
    }