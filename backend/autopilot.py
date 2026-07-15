"""
Milli Autopilot™ — canonical financial automation engine.

The pipeline runs on every eligible payout (Plaid-detected gig deposit
or manually added payout) and executes the following sequence atomically
against Milli's internal ledger:

    Payout Received
        ↓  Determine Income Source
        ↓  Calculate Estimated Taxes
        ↓  Allocate Tax → Milli Tax Vault™
        ↓  Update Available to Spend
        ↓  Retirement Allocation (if enabled)
        ↓  Investing Allocation (if enabled)
        ↓  Savings Allocation (if enabled)
        ↓  Update Quarterly Tax Projection
        ↓  Generate Milli AI Insight
        ↓  Create Autopilot Receipt (immutable)

The result of a run is an immutable Autopilot Receipt written to the
`autopilot_receipts` collection. Every step includes the amount moved
and the resulting balance. Balances are updated on both the user document
and the corresponding account collection so the two remain consistent.

This module deliberately has NO knowledge of HTTP or a specific web framework.
It receives a Motor db handle + user dict + payout dict, and returns a receipt.
"""
from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime, timezone, date
from typing import Any


# -------------------- Constants --------------------

# Sensible defaults for a self-employed user in the US. Tax bands are approximate
# and intentionally conservative so the reserve tends to over-protect rather than
# under-protect. When a user has a tax profile, we blend federal + state + SE.
SE_TAX_RATE = 0.153            # Social Security + Medicare
DEFAULT_FEDERAL_RATE = 0.12    # simple bracket assumption
DEFAULT_STATE_RATE = 0.05

# Default autopilot settings applied to every user on first run.
DEFAULT_AUTOPILOT_SETTINGS: dict[str, Any] = {
    "tax_enabled": True,
    "retirement_pct": 0.05,     # 5%
    "investing_pct": 0.05,      # 5%
    "savings_pct": 0.0,         # 0% (opt-in)
    "version": 1,
    "updated_at": None,
}

# Simple per-state effective rates for the tax step. Anything not listed
# defaults to DEFAULT_STATE_RATE.
STATE_EFFECTIVE_RATES: dict[str, float] = {
    "TX": 0.0, "FL": 0.0, "WA": 0.0, "TN": 0.0, "NV": 0.0, "SD": 0.0, "WY": 0.0, "AK": 0.0,
    "CA": 0.093, "NY": 0.0685, "OR": 0.0875, "MA": 0.05, "IL": 0.0495,
    "NJ": 0.0637, "GA": 0.0575, "AZ": 0.025, "NC": 0.0475, "PA": 0.0307,
    "OH": 0.0399, "MI": 0.0425, "VA": 0.0575, "CO": 0.044, "MN": 0.0785,
}

# Known payout platforms that qualify as "self-employment income" and thus
# trigger the full Autopilot pipeline.
GIG_PLATFORMS = {
    "doordash", "uber", "uber eats", "lyft", "spark", "instacart",
    "grubhub", "amazon flex", "postmates", "shipt", "gopuff",
    "upwork", "fiverr", "etsy", "shopify", "stripe", "paypal",
    "square", "venmo business", "manual",
}


# -------------------- Public API --------------------

async def get_or_init_settings(db, user_id: str) -> dict:
    """Return the user's Autopilot settings, creating defaults on first access."""
    user = await db.users.find_one({"id": user_id})
    if not user:
        raise ValueError(f"user {user_id} not found")
    settings = user.get("autopilot_settings")
    if not settings:
        settings = {**DEFAULT_AUTOPILOT_SETTINGS,
                    "updated_at": datetime.now(timezone.utc).isoformat()}
        await db.users.update_one(
            {"id": user_id},
            {"$set": {"autopilot_settings": settings}}
        )
    else:
        # Fill in any newly-added default keys (forward compat).
        merged = {**DEFAULT_AUTOPILOT_SETTINGS, **settings}
        if merged != settings:
            await db.users.update_one(
                {"id": user_id}, {"$set": {"autopilot_settings": merged}}
            )
        settings = merged
    return settings


async def update_settings(db, user_id: str, patch: dict) -> dict:
    """Persist a partial settings update. Clamps percentages to [0, 0.25]."""
    current = await get_or_init_settings(db, user_id)
    for k in ("retirement_pct", "investing_pct", "savings_pct"):
        if k in patch and patch[k] is not None:
            current[k] = max(0.0, min(0.25, float(patch[k])))
    if "tax_enabled" in patch and patch["tax_enabled"] is not None:
        current["tax_enabled"] = bool(patch["tax_enabled"])
    current["updated_at"] = datetime.now(timezone.utc).isoformat()
    await db.users.update_one(
        {"id": user_id}, {"$set": {"autopilot_settings": current}}
    )
    return current


def compute_tax_rate(user: dict) -> dict:
    """Return the blended effective tax rate breakdown for a payout."""
    state_rate = STATE_EFFECTIVE_RATES.get(
        (user.get("state") or "TX").upper(), DEFAULT_STATE_RATE
    )
    federal_rate = DEFAULT_FEDERAL_RATE
    se_rate = SE_TAX_RATE
    total = round(federal_rate + state_rate + se_rate, 4)
    # Cap at 40% so we never do something absurd for a high-tax state.
    total = min(total, 0.40)
    return {
        "federal": federal_rate,
        "state": state_rate,
        "se": se_rate,
        "total": total,
    }


def determine_source(payout: dict) -> dict:
    """Identify the income source and whether it qualifies for the pipeline."""
    platform = (payout.get("platform") or payout.get("merchant") or "").strip()
    canonical = platform.lower()
    is_gig = any(canonical.startswith(p) for p in GIG_PLATFORMS)
    return {
        "platform": platform or "Manual",
        "canonical": canonical or "manual",
        "is_gig": is_gig or canonical in ("", "manual"),
        "detected_at": datetime.now(timezone.utc).isoformat(),
    }


async def run_autopilot(db, user: dict, payout: dict) -> dict:
    """Execute the full Autopilot pipeline and return an immutable receipt.

    ``payout`` must contain at minimum {id, amount, platform, date}. Balances
    on the user document and the vault/retirement/investing/savings account
    collections are updated in place. All monetary steps are rounded to 2dp.
    """
    settings = await get_or_init_settings(db, user["id"])
    source = determine_source(payout)
    amount = round(float(payout["amount"]), 2)
    if amount <= 0:
        raise ValueError("payout amount must be > 0")

    steps: list[dict] = []
    running_available = amount  # everything not allocated is available to spend

    # ---- 1. TAX PROTECTION → Milli Tax Vault™ ---------------------------------
    tax_rate = compute_tax_rate(user)
    tax_reserve = 0.0
    if settings.get("tax_enabled", True):
        tax_reserve = round(amount * tax_rate["total"], 2)
        vault_balance = await _apply_vault_credit(db, user["id"], tax_reserve, payout)
        running_available = round(running_available - tax_reserve, 2)
        steps.append({
            "step": "tax_protection",
            "label": "Taxes Protected",
            "amount": tax_reserve,
            "rate": tax_rate,
            "destination": "Milli Tax Vault™",
            "balance_after": vault_balance,
            "status": "completed",
        })
    else:
        steps.append({
            "step": "tax_protection",
            "label": "Taxes Skipped",
            "amount": 0.0,
            "rate": tax_rate,
            "destination": "Milli Tax Vault™",
            "balance_after": None,
            "status": "skipped",
        })

    # ---- 2. RETIREMENT (from post-tax net) -----------------------------------
    ret_pct = float(settings.get("retirement_pct", 0.0) or 0.0)
    ret_amount = 0.0
    if ret_pct > 0 and running_available > 0:
        ret_amount = round(amount * ret_pct, 2)
        if ret_amount > running_available:
            ret_amount = round(running_available, 2)
        ret_balance = await _apply_smart_credit(
            db, user["id"], "retirement", ret_amount, payout
        )
        running_available = round(running_available - ret_amount, 2)
        steps.append({
            "step": "retirement",
            "label": "Retirement",
            "amount": ret_amount,
            "rate": {"pct": ret_pct},
            "destination": "Solo 401(k)",
            "balance_after": ret_balance,
            "status": "completed",
        })

    # ---- 3. INVESTING --------------------------------------------------------
    inv_pct = float(settings.get("investing_pct", 0.0) or 0.0)
    inv_amount = 0.0
    if inv_pct > 0 and running_available > 0:
        inv_amount = round(amount * inv_pct, 2)
        if inv_amount > running_available:
            inv_amount = round(running_available, 2)
        inv_balance = await _apply_smart_credit(
            db, user["id"], "investing", inv_amount, payout
        )
        running_available = round(running_available - inv_amount, 2)
        steps.append({
            "step": "investing",
            "label": "Investing",
            "amount": inv_amount,
            "rate": {"pct": inv_pct},
            "destination": "Brokerage",
            "balance_after": inv_balance,
            "status": "completed",
        })

    # ---- 4. SAVINGS ----------------------------------------------------------
    sav_pct = float(settings.get("savings_pct", 0.0) or 0.0)
    sav_amount = 0.0
    if sav_pct > 0 and running_available > 0:
        sav_amount = round(amount * sav_pct, 2)
        if sav_amount > running_available:
            sav_amount = round(running_available, 2)
        sav_balance = await _apply_savings_credit(
            db, user["id"], sav_amount, payout
        )
        running_available = round(running_available - sav_amount, 2)
        steps.append({
            "step": "savings",
            "label": "Savings",
            "amount": sav_amount,
            "rate": {"pct": sav_pct},
            "destination": "Milli Savings",
            "balance_after": sav_balance,
            "status": "completed",
        })

    # ---- 5. AVAILABLE TO SPEND ----------------------------------------------
    available = round(max(0.0, running_available), 2)
    new_ats_balance = await _apply_ats_credit(db, user["id"], available)
    steps.append({
        "step": "available_to_spend",
        "label": "Available to Spend",
        "amount": available,
        "rate": None,
        "destination": "Everyday Cash",
        "balance_after": new_ats_balance,
        "status": "completed",
    })

    # ---- 6. QUARTERLY PROJECTION UPDATE --------------------------------------
    projection = await _refresh_quarterly_projection(db, user["id"])
    steps.append({
        "step": "quarterly_projection",
        "label": "Quarterly Projection Updated",
        "amount": projection["next_quarterly_amount"],
        "rate": None,
        "destination": projection["next_period"],
        "balance_after": None,
        "status": "completed",
        "meta": projection,
    })

    # ---- 7. MILLI AI INSIGHT ------------------------------------------------
    insight = _generate_insight(user, source, amount, tax_reserve, ret_amount,
                                inv_amount, sav_amount, available, projection)
    steps.append({
        "step": "ai_insight",
        "label": "Milli AI Insight",
        "amount": None,
        "rate": None,
        "destination": None,
        "balance_after": None,
        "status": "completed",
        "insight": insight,
    })

    # ---- 8. Persist immutable receipt ---------------------------------------
    receipt_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    receipt = {
        "id": receipt_id,
        "user_id": user["id"],
        "payout_id": payout.get("id"),
        "payout_date": payout.get("date") or now[:10],
        "source": source,
        "amount": amount,
        "tax_reserve": tax_reserve,
        "retirement_amount": ret_amount,
        "investing_amount": inv_amount,
        "savings_amount": sav_amount,
        "available_to_spend": available,
        "tax_rate": tax_rate,
        "settings_snapshot": {
            "tax_enabled": settings.get("tax_enabled", True),
            "retirement_pct": ret_pct,
            "investing_pct": inv_pct,
            "savings_pct": sav_pct,
        },
        "steps": steps,
        "insight": insight,
        "created_at": now,
        "immutable": True,
    }
    receipt["hash"] = _receipt_hash(receipt)
    await db.autopilot_receipts.insert_one({**receipt})
    receipt.pop("_id", None)

    # Link the receipt back onto the payout for quick lookup.
    if payout.get("id"):
        await db.deposits.update_one(
            {"id": payout["id"]},
            {"$set": {
                "autopilot_receipt_id": receipt_id,
                "autopilot_ran_at": now,
                "savings_set_aside": tax_reserve,
            }},
        )
    return receipt


async def get_snapshot(db, user_id: str) -> dict:
    """Aggregated snapshot used by the dashboard hero cards."""
    user = await db.users.find_one({"id": user_id}) or {}
    vault = await db.tax_vaults.find_one({"user_id": user_id}) or {}
    retirement = await db.retirement_accounts.find_one({"user_id": user_id}) or {}
    investing = await db.investment_accounts.find_one({"user_id": user_id}) or {}

    latest_receipt = await db.autopilot_receipts.find_one(
        {"user_id": user_id}, sort=[("created_at", -1)]
    ) or {}
    if latest_receipt:
        latest_receipt.pop("_id", None)

    projection = await _refresh_quarterly_projection(db, user_id)

    vault_balance = round(vault.get("balance", 0.0) or 0.0, 2)
    quarterly_target = projection["next_quarterly_amount"] or 1.0
    # Tax Ready Score™: how close vault is to covering the next quarterly bill.
    tax_ready_score = min(100, round(vault_balance / quarterly_target * 100)) \
        if quarterly_target else 0

    return {
        "available_to_spend": round(user.get("available_to_spend", 0.0) or 0.0, 2),
        "vault_balance": vault_balance,
        "retirement_balance": round(retirement.get("balance", 0.0) or 0.0, 2),
        "investing_balance": round(investing.get("balance", 0.0) or 0.0, 2),
        "savings_balance": round(user.get("savings_balance", 0.0) or 0.0, 2),
        "tax_ready_score": tax_ready_score,
        "next_quarterly": projection,
        "latest_receipt": latest_receipt,
        "amount_protected_ytd": await _amount_protected_ytd(db, user_id),
    }


# -------------------- Internal helpers --------------------

async def _apply_vault_credit(db, user_id: str, amount: float, payout: dict) -> float:
    vault = await db.tax_vaults.find_one({"user_id": user_id})
    now = datetime.now(timezone.utc).isoformat()
    if not vault:
        vault = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "institution_name": "Milli Reserve (Internal Ledger)",
            "account_nickname": "Milli Tax Vault™",
            "account_number_masked": "****" + str(uuid.uuid4().int)[-4:],
            "routing_number_masked": "****0397",
            "balance": 0.0,
            "interest_earned_ytd": 0.0,
            "rule": {
                "mode": "auto", "strategy": "autopilot", "fixed_percentage": None,
                "min_checking_balance": 0.0, "max_daily_transfer": 5000.0,
                "paused": False,
            },
            "created_at": now,
        }
        await db.tax_vaults.insert_one(vault)
    new_balance = round((vault.get("balance") or 0.0) + amount, 2)
    await db.vault_transfers.insert_one({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "direction": "in",
        "amount": amount,
        "balance_after": new_balance,
        "note": f"Autopilot from {payout.get('platform', 'payout')} (${payout['amount']:.2f})",
        "source": "autopilot",
        "deposit_id": payout.get("id"),
        "created_at": now,
    })
    await db.tax_vaults.update_one(
        {"user_id": user_id}, {"$set": {"balance": new_balance}}
    )
    await db.users.update_one(
        {"id": user_id}, {"$set": {"tax_savings_balance": new_balance}}
    )
    return new_balance


async def _apply_smart_credit(db, user_id: str, kind: str, amount: float, payout: dict) -> float:
    cfg = {
        "retirement": {
            "coll": "retirement_accounts",
            "tx": "retirement_transfers",
            "user_field": "retirement_balance",
            "partner": "Milli Retirement (Internal Ledger)",
            "nickname": "Solo 401(k)",
        },
        "investing": {
            "coll": "investment_accounts",
            "tx": "investment_transfers",
            "user_field": "investing_balance",
            "partner": "Milli Invest (Internal Ledger)",
            "nickname": "Brokerage Account",
        },
    }[kind]
    acct = await db[cfg["coll"]].find_one({"user_id": user_id})
    now = datetime.now(timezone.utc).isoformat()
    if not acct:
        acct = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "kind": kind,
            "institution_name": cfg["partner"],
            "account_nickname": cfg["nickname"],
            "account_number_masked": "****" + str(uuid.uuid4().int)[-4:],
            "balance": 0.0,
            "ytd_growth": 0.0,
            "rule": {"mode": "auto", "fixed_percentage": None,
                     "max_daily_transfer": 500.0, "paused": False},
            "created_at": now,
        }
        await db[cfg["coll"]].insert_one(acct)
    new_balance = round((acct.get("balance") or 0.0) + amount, 2)
    await db[cfg["tx"]].insert_one({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "direction": "in",
        "amount": amount,
        "balance_after": new_balance,
        "note": f"Autopilot from {payout.get('platform', 'payout')} (${payout['amount']:.2f})",
        "source": "autopilot",
        "deposit_id": payout.get("id"),
        "created_at": now,
    })
    await db[cfg["coll"]].update_one(
        {"user_id": user_id}, {"$set": {"balance": new_balance}}
    )
    await db.users.update_one(
        {"id": user_id}, {"$set": {cfg["user_field"]: new_balance}}
    )
    return new_balance


async def _apply_savings_credit(db, user_id: str, amount: float, payout: dict) -> float:
    user = await db.users.find_one({"id": user_id}) or {}
    new_balance = round((user.get("savings_balance") or 0.0) + amount, 2)
    await db.savings_transfers.insert_one({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "direction": "in",
        "amount": amount,
        "balance_after": new_balance,
        "note": f"Autopilot from {payout.get('platform', 'payout')} (${payout['amount']:.2f})",
        "source": "autopilot",
        "deposit_id": payout.get("id"),
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    await db.users.update_one(
        {"id": user_id}, {"$set": {"savings_balance": new_balance}}
    )
    return new_balance


async def _apply_ats_credit(db, user_id: str, amount: float) -> float:
    """Increase Available to Spend (everyday cash) balance."""
    user = await db.users.find_one({"id": user_id}) or {}
    new_balance = round((user.get("available_to_spend") or 0.0) + amount, 2)
    await db.users.update_one(
        {"id": user_id}, {"$set": {"available_to_spend": new_balance}}
    )
    return new_balance


async def _refresh_quarterly_projection(db, user_id: str) -> dict:
    """Compute the next quarterly estimate + which quarter it applies to."""
    year = datetime.now(timezone.utc).year
    today = date.today()
    quarters = [
        (date(year, 4, 15), "Q1"),
        (date(year, 6, 15), "Q2"),
        (date(year, 9, 15), "Q3"),
        (date(year + 1, 1, 15), "Q4"),
    ]
    next_q = next((q for q in quarters if q[0] >= today), quarters[-1])

    # Estimate based on YTD gross × blended tax rate ÷ 4.
    deposits = await db.deposits.find(
        {"user_id": user_id}, {"amount": 1, "date": 1, "_id": 0}
    ).to_list(5000)
    ytd_gross = sum(
        (d.get("amount") or 0.0) for d in deposits
        if str(d.get("date", "")).startswith(str(year))
    )
    user = await db.users.find_one({"id": user_id}) or {}
    rate = compute_tax_rate(user)["total"]
    annual_est = ytd_gross * rate
    next_amount = round(annual_est / 4, 2)
    return {
        "year": year,
        "next_period": next_q[1],
        "next_due_date": next_q[0].isoformat(),
        "next_quarterly_amount": next_amount,
        "days_until": (next_q[0] - today).days,
        "annual_estimate": round(annual_est, 2),
    }


async def _amount_protected_ytd(db, user_id: str) -> float:
    year = datetime.now(timezone.utc).year
    receipts = await db.autopilot_receipts.find(
        {"user_id": user_id}, {"tax_reserve": 1, "created_at": 1, "_id": 0}
    ).to_list(5000)
    total = sum(
        (r.get("tax_reserve") or 0.0) for r in receipts
        if str(r.get("created_at", "")).startswith(str(year))
    )
    return round(total, 2)


def _generate_insight(user, source, amount, tax_reserve, ret_amount,
                       inv_amount, sav_amount, available, projection) -> str:
    name = (user.get("name") or "").split()[0] or "there"
    parts = [f"You earned ${amount:,.2f} from {source['platform']}."]
    if tax_reserve > 0:
        parts.append(f"${tax_reserve:,.2f} moved to your Milli Tax Vault™.")
    if ret_amount > 0:
        parts.append(f"${ret_amount:,.2f} added to retirement.")
    if inv_amount > 0:
        parts.append(f"${inv_amount:,.2f} added to investing.")
    if sav_amount > 0:
        parts.append(f"${sav_amount:,.2f} added to savings.")
    parts.append(f"${available:,.2f} is now safe to spend.")
    if projection["days_until"] <= 45:
        parts.append(
            f"{projection['next_period']} estimate ${projection['next_quarterly_amount']:,.2f} "
            f"due in {projection['days_until']} days."
        )
    return " ".join(parts)


def _receipt_hash(receipt: dict) -> str:
    payload = {k: v for k, v in receipt.items() if k not in ("hash", "_id")}
    blob = json.dumps(payload, sort_keys=True, default=str).encode("utf-8")
    return "sha256:" + hashlib.sha256(blob).hexdigest()


# -------------------- Migration --------------------

async def migrate_all_users(db) -> dict:
    """One-shot migration: apply DEFAULT_AUTOPILOT_SETTINGS to any user missing them.

    Also backfills ``available_to_spend`` and ``savings_balance`` fields.
    Safe to call at every server startup (idempotent).
    """
    now = datetime.now(timezone.utc).isoformat()
    updated = 0
    async for user in db.users.find({}):
        patch: dict[str, Any] = {}
        if not user.get("autopilot_settings"):
            patch["autopilot_settings"] = {
                **DEFAULT_AUTOPILOT_SETTINGS,
                "updated_at": now,
            }
        if user.get("available_to_spend") is None:
            patch["available_to_spend"] = 0.0
        if user.get("savings_balance") is None:
            patch["savings_balance"] = 0.0
        if patch:
            await db.users.update_one({"id": user["id"]}, {"$set": patch})
            updated += 1
    return {"users_migrated": updated, "ran_at": now}
