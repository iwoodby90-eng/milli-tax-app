"""
Milli Integration Interfaces
============================

Every external provider is accessed through one of these abstract Protocol
classes so we can swap providers without touching the rest of the app.

Current concrete implementations:
    banking        ─┬─ InternalLedgerBank (Milli's own DB-backed ledger, default)
                    └─ PlaidBank (real Plaid API, used when PLAID_CLIENT_ID is set)
    tax_calc       ─ InternalTaxCalculator (uses tax_engine.py)
    tax_payments   ─ NullTaxPayer (returns "activation pending")
    tax_filing     ─ NullTaxFiler (returns "activation pending")
    brokerage      ─ InternalBrokerage (DB ledger stand-in)
    retirement     ─ InternalRetirementCustodian (DB ledger stand-in)
    gps            ─ NativeCapacitorGps (client-side, this just persists trips)
    ocr            ─ GeminiOcrProvider (via emergentintegrations)
    notifications  ─ InAppNotifier (persists to db.notifications)

When a real provider (Unit/Stripe Treasury, Avalara, Carry, Plaid,
IRS Direct Pay, TaxAct, etc.) is wired in, only the concrete class changes.
"""
from __future__ import annotations

import os
from typing import Protocol, Optional, Any

from datetime import datetime, timezone


# ──────────────────────────────────────────────────────────────────
# Base Protocols
# ──────────────────────────────────────────────────────────────────

class AccountAggregator(Protocol):
    """Fetch balances + income across all connected external accounts."""
    async def link_token(self, user_id: str) -> str: ...
    async def exchange(self, user_id: str, public_token: str) -> dict: ...
    async def sync_transactions(self, user_id: str, item_id: str) -> int: ...
    async def list_items(self, user_id: str) -> list[dict]: ...


class MoneyMover(Protocol):
    """Move money between accounts. Internal ledger for now; ACH later."""
    async def credit(self, user_id: str, bucket: str, amount: float,
                     note: str, source_ref: Optional[str] = None) -> float: ...
    async def debit(self, user_id: str, bucket: str, amount: float,
                    note: str, source_ref: Optional[str] = None) -> float: ...
    async def balance(self, user_id: str, bucket: str) -> float: ...


class TaxCalculator(Protocol):
    """Federal + state + SE tax math."""
    def per_payout_rate(self, user: dict) -> dict: ...
    def annual_projection(self, user: dict, ytd_gross: float,
                          ytd_deductions: float) -> dict: ...
    def quarterly_plan(self, user: dict, ytd_gross: float,
                       ytd_deductions: float, payments: list) -> dict: ...


class TaxPaymentSubmitter(Protocol):
    """Send an estimated tax payment to the IRS / state."""
    async def submit_federal(self, user_id: str, amount: float,
                            period: str) -> dict: ...
    async def submit_state(self, user_id: str, amount: float,
                           period: str, state: str) -> dict: ...


class TaxFiler(Protocol):
    """Electronic tax filing through an approved provider (Elite only)."""
    async def prepare_return(self, user_id: str, year: int) -> dict: ...
    async def submit_return(self, user_id: str, year: int,
                            signed_return_id: str) -> dict: ...
    async def status(self, user_id: str, filing_id: str) -> dict: ...


class Brokerage(Protocol):
    async def deposit(self, user_id: str, amount: float, note: str) -> float: ...
    async def balance(self, user_id: str) -> float: ...
    async def positions(self, user_id: str) -> list[dict]: ...


class RetirementCustodian(Protocol):
    async def contribute(self, user_id: str, amount: float,
                         account_type: str, note: str) -> float: ...
    async def balance(self, user_id: str) -> float: ...


class GpsProvider(Protocol):
    """The mobile client is the actual GPS source; this interface persists
    the trips it reports and computes deductions."""
    async def start_trip(self, user_id: str, lat: float, lng: float,
                         purpose: str) -> dict: ...
    async def append_point(self, trip_id: str, lat: float, lng: float,
                           timestamp: str) -> dict: ...
    async def end_trip(self, trip_id: str, lat: float, lng: float) -> dict: ...

class OcrProvider(Protocol):
    async def extract_receipt(self, image_bytes: bytes,
                               mime_type: str) -> dict: ...


class Notifier(Protocol):
    async def send(self, user_id: str, kind: str, title: str,
                   body: str, meta: Optional[dict] = None) -> dict: ...


# ──────────────────────────────────────────────────────────────────
# Concrete implementations
# ──────────────────────────────────────────────────────────────────

class InternalLedgerBank:
    """MoneyMover using Milli's own DB — every transfer is auditable."""
    def __init__(self, db):
        self.db = db

    def _coll(self, bucket: str) -> str:
        # Map logical buckets to physical collections + user fields.
        return {
            "tax_vault": ("tax_vaults", "tax_savings_balance", "vault_transfers"),
            "retirement": ("retirement_accounts", "retirement_balance", "retirement_transfers"),
            "investing": ("investment_accounts", "investing_balance", "investment_transfers"),
            "savings": (None, "savings_balance", "savings_transfers"),
            "spend": (None, "available_to_spend", "spend_transfers"),
        }[bucket]

    async def credit(self, user_id: str, bucket: str, amount: float,
                     note: str, source_ref: Optional[str] = None) -> float:
        coll, user_field, tx_coll = self._coll(bucket)
        now = datetime.now(timezone.utc).isoformat()
        if coll:
            acct = await self.db[coll].find_one({"user_id": user_id}) or {}
            new_bal = round((acct.get("balance") or 0.0) + amount, 2)
            await self.db[coll].update_one(
                {"user_id": user_id}, {"$set": {"balance": new_bal}}, upsert=True,
            )
        else:
            u = await self.db.users.find_one({"id": user_id}) or {}
            new_bal = round((u.get(user_field) or 0.0) + amount, 2)
            await self.db.users.update_one({"id": user_id}, {"$set": {user_field: new_bal}})
        if tx_coll:
            await self.db[tx_coll].insert_one({
                "user_id": user_id, "direction": "in", "amount": amount,
                "balance_after": new_bal, "note": note, "source": "autopilot",
                "source_ref": source_ref, "created_at": now,
            })
        return new_bal

    async def debit(self, user_id: str, bucket: str, amount: float,
                    note: str, source_ref: Optional[str] = None) -> float:
        return await self.credit(user_id, bucket, -abs(amount), note, source_ref)

    async def balance(self, user_id: str, bucket: str) -> float:
        _, user_field, _ = self._coll(bucket)
        u = await self.db.users.find_one({"id": user_id}) or {}
        return round(float(u.get(user_field) or 0.0), 2)


class PlaidBank:
    """AccountAggregator backed by the real Plaid API.

    Delegates to plaid_client.py for all Plaid API calls.
    The autopilot pipeline is triggered automatically when gig
    payouts are detected during transaction sync.
    """
    def __init__(self, db):
        self.db = db

    async def link_token(self, user_id: str) -> str:
        from plaid_client import create_link_token
        result = await create_link_token(user_id, self.db)
        return result["link_token"]

    async def exchange(self, user_id: str, public_token: str,
                       institution_name: str | None = None) -> dict:
        from plaid_client import exchange_public_token
        return await exchange_public_token(user_id, public_token, self.db, institution_name)

    async def sync_transactions(self, user_id: str, item_id: str) -> dict:
        from plaid_client import sync_transactions
        return await sync_transactions(user_id, item_id, self.db)

    async def sync_all(self, user_id: str) -> dict:
        from plaid_client import sync_all_items
        return await sync_all_items(user_id, self.db)

    async def list_items(self, user_id: str) -> list[dict]:
        from plaid_client import list_items
        return await list_items(user_id, self.db)

    async def remove_item(self, user_id: str, item_id: str) -> dict:
        from plaid_client import remove_item
        return await remove_item(user_id, item_id, self.db)

    async def handle_webhook(self, webhook_type: str, webhook_code: str,
                             item_id: str) -> dict:
        from plaid_client import handle_webhook
        return await handle_webhook(webhook_type, webhook_code, item_id, self.db)


class InternalTaxCalculator:
    """TaxCalculator implementation backed by tax_engine.py."""
    def per_payout_rate(self, user: dict) -> dict:
        from tax_engine import profile_from_user, per_payout_reserve_rate
        return per_payout_reserve_rate(profile_from_user(user))

    def annual_projection(self, user: dict, ytd_gross: float,
                          ytd_deductions: float) -> dict:
        from tax_engine import profile_from_user, calc_total_tax
        p = profile_from_user(user)
        br = calc_total_tax(ytd_gross, ytd_deductions, p)
        return br.__dict__

    def quarterly_plan(self, user: dict, ytd_gross: float,
                       ytd_deductions: float, payments: list) -> dict:
        from tax_engine import profile_from_user, quarterly_plan
        from datetime import date
        year = date.today().year
        p = profile_from_user(user)
        plan = quarterly_plan(year, p, ytd_gross, ytd_deductions, payments)
        return plan.__dict__


class NullTaxPayer:
    """Placeholder — real ACH-to-IRS integration lives in a future partner."""
    async def submit_federal(self, user_id, amount, period):
        return {"status": "pending_partner", "amount": amount, "period": period}
    async def submit_state(self, user_id, amount, period, state):
        return {"status": "pending_partner", "amount": amount, "period": period, "state": state}


class NullTaxFiler:
    """Placeholder — Elite filing wired to a real e-file partner later."""
    async def prepare_return(self, user_id, year):
        return {"status": "prepared", "year": year, "partner": "placeholder"}
    async def submit_return(self, user_id, year, signed_return_id):
        return {"status": "pending_partner", "year": year}
    async def status(self, user_id, filing_id):
        return {"status": "pending_partner", "filing_id": filing_id}


class InAppNotifier:
    """Persist notifications to db.notifications; UI polls or subs later."""
    def __init__(self, db):
        self.db = db

    async def send(self, user_id, kind, title, body, meta=None):
        import uuid
        doc = {
            "id": str(uuid.uuid44()),
            "user_id": user_id, "kind": kind, "title": title, "body": body,
            "meta": meta or {}, "read": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        await self.db.notifications.insert_one(doc)
        doc.pop("_id", None)
        return doc


# ──────────────────────────────────────────────────────────────────
# Registry — the one place server.py wires providers
# ──────────────────────────────────────────────────────────────────

class IntegrationRegistry:
    def __init__(self, db):
        self.db = db
        self.bank = InternalLedgerBank(db)
        self.tax = InternalTaxCalculator()
        self.tax_pay = NullTaxPayer()
        self.tax_file = NullTaxFiler()
        self.notifier = InAppNotifier(db)

        # Use real Plaid bank integration when credentials are available
        if os.getenv("PLAID_CLIENT_ID") and os.getenv("PLAID_SECRET"):
            self.plaid = PlaidBank(db)
        else:
            self.plaid = None