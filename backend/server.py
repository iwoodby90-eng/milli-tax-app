#!/usr/bin/env python3
"""
Milli backend — bank link + payout sync + Tax Vault reserve.

Holds provider credentials server-side. Current implementation is suitable for
integration/QA only; production must replace process-memory state with the
Postgres schema and authenticated user scoping before money movement is enabled.
"""

import os
import re
import time
import uuid
from decimal import Decimal, ROUND_HALF_UP

from flask import Flask, request, jsonify
import stripe

stripe.api_key = os.environ.get("STRIPE_SECRET_KEY", "")
if not stripe.api_key:
    print("WARNING: STRIPE_SECRET_KEY not set — bank link will fail until it is provided.")

app = Flask(__name__)

LINK_SESSIONS = {}
# Integration-only process memory. State is isolated per connected account so
# one account can never receive another account's reserve/payout history.
ACCOUNT_RESERVE_LEDGER = {}
AUTHORIZED_ACCOUNTS = set()

GIG_PATTERNS = [
    ("DoorDash", re.compile(r"doordash", re.I)),
    ("Uber", re.compile(r"uber", re.I)),
    ("Lyft", re.compile(r"lyft", re.I)),
    ("Instacart", re.compile(r"instacart|shipt", re.I)),
    ("Grubhub", re.compile(r"grubhub|seamless", re.I)),
    ("Amazon Flex", re.compile(r"amazon\s*flex|amzn\s*flex", re.I)),
    ("Spark Driver", re.compile(r"spark\s*driver|walmart\s*spark", re.I)),
]

DEFAULT_TAX_RATE_BPS = 3000


def money(value) -> float:
    return float(Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


@app.post("/api/bank-link/session")
def create_link_session():
    session_id = f"fc_{uuid.uuid4().hex}"
    try:
        session = stripe.financial_connections.Session.create(
            account_holder={"type": "customer"},
            components={"account_linking": {
                "enabled": True,
                "permissions": ["balances", "ownership", "transactions"],
            }},
            return_url=f"https://app.drivemilli.com/bank-link/callback?session_id={session_id}",
        )
    except Exception as exc:  # noqa: BLE001
        return jsonify({"error": f"Stripe session creation failed: {exc}"}), 502

    LINK_SESSIONS[session_id] = {"stripe_session_id": session.id, "created": time.time()}
    return jsonify({
        "sessionId": session_id,
        "hostedUrl": session.url if hasattr(session, "url") else (
            f"https://connect.stripe.com/financial_connections/sessions/{session.id}"
        ),
        "returnUrl": f"https://app.drivemilli.com/bank-link/callback?session_id={session_id}",
    })


@app.post("/api/bank-link/complete")
def complete_link():
    payload = request.get_json(silent=True) or {}
    session_id = payload.get("sessionId", "")
    record = LINK_SESSIONS.pop(session_id, None)
    if not record:
        return jsonify({"error": "Unknown or expired link session."}), 404

    try:
        session = stripe.financial_connections.Session.retrieve(record["stripe_session_id"])
        accounts = []
        for acc in session.accounts or []:
            full = stripe.financial_connections.Account.retrieve(
                acc.id, expand=["balances", "display"]
            )
            AUTHORIZED_ACCOUNTS.add(full.id)
            ACCOUNT_RESERVE_LEDGER.setdefault(full.id, [])

            balance = 0.0
            for bal in (getattr(full, "balances", None) or []):
                if getattr(bal, "status", "") == "active" and getattr(bal, "type", "") == "cash":
                    balance = money(bal.current.amount / 100)
                    break
            display = getattr(full, "display", None)
            accounts.append({
                "id": full.id,
                "institutionName": getattr(display, "bank_name", "Connected Bank") if display else "Connected Bank",
                "accountName": getattr(display, "account_name", "Primary Checking") if display else "Primary Checking",
                "accountMask": getattr(display, "account_number_last4", "0000") if display else "0000",
                "accountType": "Checking",
                "balance": balance,
                "lastSyncedAt": int(time.time()),
            })
    except Exception as exc:  # noqa: BLE001
        return jsonify({"error": f"Stripe retrieval failed: {exc}"}), 502

    return jsonify({"accounts": accounts})


@app.post("/api/payouts/sync")
def sync_payouts():
    payload = request.get_json(silent=True) or {}
    account_id = payload.get("accountId")
    if not account_id:
        return jsonify({"error": "accountId required"}), 400
    if account_id not in AUTHORIZED_ACCOUNTS:
        return jsonify({"error": "Account is not linked in this backend session."}), 403

    ledger = ACCOUNT_RESERVE_LEDGER.setdefault(account_id, [])
    existing_ids = {entry["id"] for entry in ledger}

    try:
        txns = stripe.financial_connections.Transaction.list(
            account=account_id, limit=100
        )
    except Exception as exc:  # noqa: BLE001
        return jsonify({"error": f"Stripe transaction fetch failed: {exc}"}), 502

    for txn in getattr(txns, "data", []):
        amount = getattr(txn, "amount", 0)
        if amount <= 0:
            continue

        descriptor = " ".join(filter(None, [
            getattr(txn, "description", "") or "",
            getattr(txn, "merchant_name", "") or "",
            getattr(txn, "statement_descriptor", "") or "",
        ]))
        platform = next((name for name, rx in GIG_PATTERNS if rx.search(descriptor)), None)
        if not platform:
            continue

        entry_id = getattr(txn, "id", uuid.uuid4().hex)
        if entry_id in existing_ids:
            continue

        gross = money(amount / 100)
        tax_hold = money(gross * DEFAULT_TAX_RATE_BPS / 10000)
        detected_at = int(getattr(txn, "created", time.time()))

        record = {
            "id": entry_id,
            "platform": platform,
            "grossAmount": gross,
            "detectedAt": detected_at,
            "taxHoldAmount": tax_hold,
            "taxHoldState": "processing",
        }
        ledger.append(record)
        existing_ids.add(entry_id)

    reserve = sum((Decimal(str(e["taxHoldAmount"])) for e in ledger), Decimal("0"))

    # Return the authoritative persisted view, not only newly discovered deltas,
    # so repeat syncs never clear the client's payout history.
    return jsonify({
        "payouts": ledger,
        "taxVaultReserveBalance": money(reserve),
        "syncedAt": int(time.time()),
    })


if __name__ == "__main__":
    app.run(port=int(os.environ.get("PORT", "8080")))
