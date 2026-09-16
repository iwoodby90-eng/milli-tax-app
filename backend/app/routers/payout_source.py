"""Authoritative selection of the linked account where gig payouts land.

Plaid can return multiple accounts for one institution. Milli must not guess
which balance is the user's spendable/payout account. The user selects one,
and the backend stores that choice in plaid_accounts.is_payout_source.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from .. import db
from ..config import get_settings
from ..security import require_user

router = APIRouter(prefix="/plaid", tags=["plaid"])


class PayoutSourceRequest(BaseModel):
    account_id: str


def _require_database() -> None:
    if not get_settings().db_configured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "DATABASE_URL is not configured",
        )


@router.put("/payout-source")
def set_payout_source(
    body: PayoutSourceRequest,
    user_id: uuid.UUID = Depends(require_user),
) -> dict:
    """Select exactly one linked Plaid account as the payout account."""
    _require_database()

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select account_id, name, mask, type, subtype
                  from plaid_accounts
                 where user_id = %s and account_id = %s
                """,
                (user_id, body.account_id),
            )
            account = cur.fetchone()
            if account is None:
                raise HTTPException(status.HTTP_404_NOT_FOUND, "linked account not found")

            cur.execute(
                "update plaid_accounts set is_payout_source = false, updated_at = now() where user_id = %s",
                (user_id,),
            )
            cur.execute(
                """
                update plaid_accounts
                   set is_payout_source = true, updated_at = now()
                 where user_id = %s and account_id = %s
                """,
                (user_id, body.account_id),
            )
        conn.commit()

    return {
        "account_id": account[0],
        "name": account[1],
        "mask": account[2],
        "type": account[3],
        "subtype": account[4],
        "is_payout_source": True,
        "data_state": "USER_ENTERED",
    }


@router.get("/payout-source")
def get_payout_source(user_id: uuid.UUID = Depends(require_user)) -> dict:
    """Return the user-selected payout account; never infer one."""
    _require_database()

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select a.account_id, a.name, a.mask, a.type, a.subtype,
                       a.available_balance, a.current_balance, a.iso_currency_code,
                       a.balance_as_of, i.institution_name, i.status
                  from plaid_accounts a
                  join plaid_items i on i.id = a.plaid_item_id
                 where a.user_id = %s and a.is_payout_source = true
                 limit 1
                """,
                (user_id,),
            )
            row = cur.fetchone()

    if row is None:
        return {
            "account": None,
            "data_state": "UNAVAILABLE",
            "reason": "payout source has not been selected",
        }

    return {
        "account": {
            "account_id": row[0],
            "name": row[1],
            "mask": row[2],
            "type": row[3],
            "subtype": row[4],
            "available_balance": float(row[5]) if row[5] is not None else None,
            "current_balance": float(row[6]) if row[6] is not None else None,
            "iso_currency_code": row[7],
            "balance_as_of": row[8].isoformat() if row[8] else None,
            "institution_name": row[9],
            "item_status": row[10],
            "is_payout_source": True,
        },
        "data_state": "CACHED_LIVE" if row[5] is not None or row[6] is not None else "UNAVAILABLE",
    }
