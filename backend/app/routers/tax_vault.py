"""Milli Tax Vault reserve ledger.

Data-truth contract:
  * The vault balance is ALWAYS derived by summing settled ledger entries.
  * Requested / processing entries are reported separately and never folded
    into the authoritative balance.
  * No endpoint invents a balance. With no database configured the API answers
    503 UNAVAILABLE rather than returning a plausible number.
"""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..config import get_settings
from ..security import require_user
from .. import db

router = APIRouter(prefix="/tax-vault", tags=["tax-vault"])


def _require_db() -> None:
    if not get_settings().db_configured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "tax vault unavailable: DATABASE_URL is not configured",
        )


class BalanceResponse(BaseModel):
    settled_cents: int
    pending_cents: int
    iso_currency_code: str = "USD"
    data_state: str = "LIVE"
    as_of: str
    entry_count: int


@router.get("/balance", response_model=BalanceResponse)
def balance(user_id: uuid.UUID = Depends(require_user)) -> BalanceResponse:
    _require_db()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select
                  coalesce(sum(amount_cents) filter (where status = 'settled'), 0),
                  coalesce(sum(amount_cents) filter (where status in ('requested','processing')), 0),
                  count(*)
                from tax_vault_ledger
                where user_id = %s
                """,
                (user_id,),
            )
            settled, pending, count = cur.fetchone()
    return BalanceResponse(
        settled_cents=int(settled),
        pending_cents=int(pending),
        as_of=datetime.now(timezone.utc).isoformat(),
        entry_count=int(count),
    )


class LedgerEntryIn(BaseModel):
    entry_type: str = Field(pattern="^(reserve|withdrawal|adjustment|interest)$")
    amount_cents: int
    reserve_rate: float | None = None
    tax_year: int | None = None
    quarter: int | None = Field(default=None, ge=1, le=4)
    memo: str | None = None
    status: str = Field(default="requested", pattern="^(requested|processing|settled)$")


class LedgerEntryOut(BaseModel):
    id: uuid.UUID
    audit_id: str
    status: str
    amount_cents: int


@router.post("/entries", response_model=LedgerEntryOut, status_code=201)
def create_entry(
    body: LedgerEntryIn,
    user_id: uuid.UUID = Depends(require_user),
) -> LedgerEntryOut:
    """Record a reserve movement.

    A new entry defaults to `requested`: it is NOT counted as settled money and
    the client must not show it as completed until it settles.
    """
    _require_db()
    if body.entry_type in {"reserve", "interest"} and body.amount_cents <= 0:
        raise HTTPException(400, "reserve and interest entries must be positive")
    if body.entry_type == "withdrawal" and body.amount_cents >= 0:
        raise HTTPException(400, "withdrawal entries must be negative")

    entry_id = uuid.uuid4()
    audit_id = f"TV-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{entry_id.hex[:10].upper()}"
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into tax_vault_ledger
                    (id, user_id, entry_type, amount_cents, status, reserve_rate,
                     tax_year, quarter, memo, audit_id, settled_at)
                values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    entry_id,
                    user_id,
                    body.entry_type,
                    body.amount_cents,
                    body.status,
                    body.reserve_rate,
                    body.tax_year,
                    body.quarter,
                    body.memo,
                    audit_id,
                    datetime.now(timezone.utc) if body.status == "settled" else None,
                ),
            )
        conn.commit()
    return LedgerEntryOut(
        id=entry_id, audit_id=audit_id, status=body.status, amount_cents=body.amount_cents
    )


@router.get("/entries")
def list_entries(
    user_id: uuid.UUID = Depends(require_user),
    limit: int = 100,
) -> dict:
    _require_db()
    limit = max(1, min(limit, 500))
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, entry_type, amount_cents, status, tax_year, quarter,
                       memo, audit_id, settled_at, created_at
                  from tax_vault_ledger
                 where user_id = %s
                 order by created_at desc
                 limit %s
                """,
                (user_id, limit),
            )
            rows = cur.fetchall()
    return {
        "entries": [
            {
                "id": str(r[0]),
                "entry_type": r[1],
                "amount_cents": int(r[2]),
                "status": r[3],
                "tax_year": r[4],
                "quarter": r[5],
                "memo": r[6],
                "audit_id": r[7],
                "settled_at": r[8].isoformat() if r[8] else None,
                "created_at": r[9].isoformat(),
            }
            for r in rows
        ],
        "count": len(rows),
    }


class SettleRequest(BaseModel):
    status: str = Field(pattern="^(processing|settled|failed|reversed)$")


@router.post("/entries/{entry_id}/status")
def update_status(
    entry_id: uuid.UUID,
    body: SettleRequest,
    user_id: uuid.UUID = Depends(require_user),
) -> dict:
    """Authoritative state transition. Only this call can make money 'settled'."""
    _require_db()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update tax_vault_ledger
                   set status = %s,
                       settled_at = case when %s = 'settled' then now() else settled_at end,
                       updated_at = now()
                 where id = %s and user_id = %s
                returning status
                """,
                (body.status, body.status, entry_id, user_id),
            )
            row = cur.fetchone()
        conn.commit()
    if row is None:
        raise HTTPException(404, "ledger entry not found")
    return {"id": str(entry_id), "status": row[0]}


class SettingsIn(BaseModel):
    reserve_rate: float = Field(ge=0, le=1)
    autopilot_enabled: bool


@router.get("/settings")
def get_vault_settings(user_id: uuid.UUID = Depends(require_user)) -> dict:
    _require_db()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select reserve_rate, autopilot_enabled, updated_at from tax_vault_settings where user_id = %s",
                (user_id,),
            )
            row = cur.fetchone()
    if row is None:
        return {"configured": False, "data_state": "UNAVAILABLE"}
    return {
        "configured": True,
        "reserve_rate": float(row[0]),
        "autopilot_enabled": row[1],
        "updated_at": row[2].isoformat(),
        "data_state": "USER_ENTERED",
    }


@router.put("/settings")
def put_vault_settings(
    body: SettingsIn,
    user_id: uuid.UUID = Depends(require_user),
) -> dict:
    _require_db()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into tax_vault_settings (user_id, reserve_rate, autopilot_enabled)
                values (%s, %s, %s)
                on conflict (user_id) do update
                    set reserve_rate = excluded.reserve_rate,
                        autopilot_enabled = excluded.autopilot_enabled,
                        updated_at = now()
                """,
                (user_id, body.reserve_rate, body.autopilot_enabled),
            )
        conn.commit()
    return {"reserve_rate": body.reserve_rate, "autopilot_enabled": body.autopilot_enabled}
