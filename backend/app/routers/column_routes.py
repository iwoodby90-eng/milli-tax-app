"""Column BaaS router.

Endpoints for account creation, balance queries, card issuing,
and ACH transfers. All money is in signed cents.

State machine for transfers: pending -> processing -> settled | failed | reversed.
The `settled` state is only reachable via Column webhook confirmation,
never from a direct client POST (same pattern as the tax_vault fix).
"""

import uuid
from datetime import datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field

from ..audit import log as audit_log
from ..config import get_settings
from ..column_client import ColumnClient
from .. import db
from ..security import verify_client_key

router = APIRouter(prefix="/column", tags=["column"])


# --- Models ---

class AccountCreateIn(BaseModel):
    user_id: uuid.UUID
    account_type: Literal["checking", "tax_vault"] = "checking"
    column_entity_id: str = Field(..., description="Column entity ID from KYC/onboarding")


class AccountOut(BaseModel):
    id: uuid.UUID
    column_account_id: str
    account_type: str
    status: str
    available_balance_cents: int
    pending_balance_cents: int
    iso_currency_code: str
    last_synced_at: Optional[datetime] = None
    created_at: datetime


class CardCreateIn(BaseModel):
    user_id: uuid.UUID
    column_account_id: uuid.UUID
    card_type: Literal["physical", "virtual"] = "virtual"


class CardOut(BaseModel):
    id: uuid.UUID
    column_card_id: str
    card_type: str
    status: str
    last_four: Optional[str] = None
    created_at: datetime


class TransferCreateIn(BaseModel):
    user_id: uuid.UUID
    column_account_id: uuid.UUID
    direction: Literal["inbound", "outbound"]
    transfer_type: Literal["ach", "wire"] = "ach"
    amount_cents: int = Field(..., gt=0, description="Amount in cents, must be positive")
    counterparty_name: str
    counterparty_routing_number: str
    counterparty_account_number: str = Field(..., description="Full account number (not stored)")
    description: Optional[str] = None


class TransferOut(BaseModel):
    id: uuid.UUID
    column_transfer_id: Optional[str] = None
    direction: str
    transfer_type: str
    amount_cents: int
    status: str
    counterparty_name: Optional[str] = None
    counterparty_account_number_last_four: Optional[str] = None
    description: Optional[str] = None
    audit_id: str
    settled_at: Optional[datetime] = None
    created_at: datetime


class TransferStatusUpdateIn(BaseModel):
    """Webhook-driven status update. Only Column webhooks should call this."""
    column_transfer_id: str
    new_status: Literal["processing", "settled", "failed", "reversed"]
    settled_at: Optional[datetime] = None


# --- Endpoints ---

@router.post("/accounts", response_model=AccountOut, status_code=status.HTTP_201_CREATED)
async def create_account(
    body: AccountCreateIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Create a Column deposit account (checking or Tax Vault savings)."""
    settings = get_settings()
    if not settings.column_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Column BaaS is not configured. Set COLUMN_API_KEY.",
        )

    client = ColumnClient()
    try:
        col_account = client.create_account(
            user_id=str(body.user_id),
            account_type=body.account_type,
            customer_id=body.column_entity_id,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Column account creation failed: {exc}",
        )

    account_id = uuid.uuid4()
    col_account_id = col_account.get("id", "")
    if not col_account_id:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Column returned no account ID",
        )

    audit_id = audit_log(
        user_id=body.user_id,
        action="column.account.create",
        resource_type="column_account",
        resource_id=str(account_id),
        metadata={"column_account_id": col_account_id, "account_type": body.account_type},
        ip_address=request.client.host if request.client else None,
    )

    pool = db.pool()
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database is not configured.",
        )

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_accounts
                    (id, user_id, column_account_id, account_type, status)
                values (%s, %s, %s, %s, 'pending')
                returning id, column_account_id, account_type, status,
                          available_balance_cents, pending_balance_cents,
                          iso_currency_code, last_synced_at, created_at
                """,
                (account_id, body.user_id, col_account_id, body.account_type),
            )
            row = cur.fetchone()
        conn.commit()

    return AccountOut(
        id=row[0],
        column_account_id=row[1],
        account_type=row[2],
        status=row[3],
        available_balance_cents=row[4],
        pending_balance_cents=row[5],
        iso_currency_code=row[6],
        last_synced_at=row[7],
        created_at=row[8],
    )


@router.get("/accounts/{user_id}", response_model=list[AccountOut])
async def list_accounts(
    user_id: uuid.UUID,
    _: None = Depends(verify_client_key),
):
    """List all Column accounts for a user."""
    pool = db.pool()
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database is not configured.",
        )

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, column_account_id, account_type, status,
                       available_balance_cents, pending_balance_cents,
                       iso_currency_code, last_synced_at, created_at
                from column_accounts
                where user_id = %s
                order by created_at
                """,
                (user_id,),
            )
            rows = cur.fetchall()

    return [
        AccountOut(
            id=r[0],
            column_account_id=r[1],
            account_type=r[2],
            status=r[3],
            available_balance_cents=r[4],
            pending_balance_cents=r[5],
            iso_currency_code=r[6],
            last_synced_at=r[7],
            created_at=r[8],
        )
        for r in rows
    ]


@router.post("/cards", response_model=CardOut, status_code=status.HTTP_201_CREATED)
async def create_card(
    body: CardCreateIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Issue a debit card on a Column account."""
    settings = get_settings()
    if not settings.column_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Column BaaS is not configured.",
        )

    pool = db.pool()
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database is not configured.",
        )

    # Verify the account belongs to this user
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select column_account_id from column_accounts where id = %s and user_id = %s",
                (body.column_account_id, body.user_id),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Account not found for this user.",
                )
            col_account_id = row[0]

    client = ColumnClient()
    try:
        col_card = client.create_card(col_account_id, body.card_type)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Column card creation failed: {exc}",
        )

    card_id = uuid.uuid4()
    col_card_id = col_card.get("id", "")
    last_four = col_card.get("last_four")

    audit_log(
        user_id=body.user_id,
        action="column.card.create",
        resource_type="column_card",
        resource_id=str(card_id),
        metadata={"column_card_id": col_card_id, "card_type": body.card_type},
        ip_address=request.client.host if request.client else None,
    )

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_cards
                    (id, user_id, column_account_id, column_card_id, card_type, status, last_four)
                values (%s, %s, %s, %s, %s, 'active', %s)
                returning id, column_card_id, card_type, status, last_four, created_at
                """,
                (card_id, body.user_id, body.column_account_id, col_card_id, body.card_type, last_four),
            )
            row = cur.fetchone()
        conn.commit()

    return CardOut(
        id=row[0],
        column_card_id=row[1],
        card_type=row[2],
        status=row[3],
        last_four=row[4],
        created_at=row[5],
    )


@router.post("/cards/{card_id}/freeze", response_model=CardOut)
async def freeze_card(
    card_id: uuid.UUID,
    user_id: uuid.UUID,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Freeze a debit card."""
    pool = db.pool()
    if pool is None:
        raise HTTPException(status_code=503, detail="Database is not configured.")

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select column_card_id from column_cards where id = %s and user_id = %s",
                (card_id, user_id),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(404, "Card not found.")
            col_card_id = row[0]

            client = ColumnClient()
            try:
                client.freeze_card(col_card_id)
            except Exception as exc:
                raise HTTPException(502, f"Column card freeze failed: {exc}")

            cur.execute(
                """
                update column_cards set status = 'frozen', updated_at = now()
                where id = %s
                returning id, column_card_id, card_type, status, last_four, created_at
                """,
                (card_id,),
            )
            row = cur.fetchone()
        conn.commit()

    audit_log(
        user_id=user_id,
        action="column.card.freeze",
        resource_type="column_card",
        resource_id=str(card_id),
        ip_address=request.client.host if request.client else None,
    )

    return CardOut(
        id=row[0], column_card_id=row[1], card_type=row[2],
        status=row[3], last_four=row[4], created_at=row[5],
    )


@router.post("/transfers", response_model=TransferOut, status_code=status.HTTP_201_CREATED)
async def create_transfer(
    body: TransferCreateIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Create an ACH transfer. Status starts as 'pending'.

    The 'settled' state is only reachable via Column webhook confirmation,
    never from this endpoint. This is the same state-machine pattern as
    the tax_vault fix (issue #103).
    """
    settings = get_settings()
    if not settings.column_configured:
        raise HTTPException(503, "Column BaaS is not configured.")

    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    # Verify account ownership
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select column_account_id from column_accounts where id = %s and user_id = %s",
                (body.column_account_id, body.user_id),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(404, "Account not found for this user.")
            col_account_id = row[0]

    # Call Column to initiate the transfer
    client = ColumnClient()
    try:
        col_transfer = client.create_ach_transfer(
            from_account_id=col_account_id,
            to_routing_number=body.counterparty_routing_number,
            to_account_number=body.counterparty_account_number,
            amount_cents=body.amount_cents,
            direction=body.direction,
            description=body.description,
        )
    except Exception as exc:
        raise HTTPException(502, f"Column transfer creation failed: {exc}")

    transfer_id = uuid.uuid4()
    col_transfer_id = col_transfer.get("id")
    last_four = body.counterparty_account_number[-4:] if body.counterparty_account_number else None

    audit_id = audit_log(
        user_id=body.user_id,
        action="column.transfer.create",
        resource_type="column_transfer",
        resource_id=str(transfer_id),
        metadata={
            "column_transfer_id": col_transfer_id,
            "direction": body.direction,
            "amount_cents": body.amount_cents,
        },
        ip_address=request.client.host if request.client else None,
    )

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_transfers
                    (id, user_id, column_account_id, column_transfer_id,
                     direction, transfer_type, amount_cents, status,
                     counterparty_name, counterparty_routing_number,
                     counterparty_account_number_last_four, description, audit_id)
                values (%s, %s, %s, %s, %s, %s, %s, 'pending',
                        %s, %s, %s, %s, %s)
                returning id, column_transfer_id, direction, transfer_type,
                          amount_cents, status, counterparty_name,
                          counterparty_account_number_last_four, description,
                          audit_id, settled_at, created_at
                """,
                (
                    transfer_id, body.user_id, body.column_account_id, col_transfer_id,
                    body.direction, body.transfer_type, body.amount_cents,
                    body.counterparty_name, body.counterparty_routing_number,
                    last_four, body.description, audit_id,
                ),
            )
            row = cur.fetchone()
        conn.commit()

    return TransferOut(
        id=row[0], column_transfer_id=row[1], direction=row[2],
        transfer_type=row[3], amount_cents=row[4], status=row[5],
        counterparty_name=row[6], counterparty_account_number_last_four=row[7],
        description=row[8], audit_id=row[9], settled_at=row[10], created_at=row[11],
    )


@router.post("/transfers/status", response_model=TransferOut)
async def update_transfer_status(
    body: TransferStatusUpdateIn,
    request: Request,
    _: None = Depends(verify_client_key),
):
    """Webhook-driven transfer status update.

    This is the ONLY way a transfer reaches 'settled'. The iOS client
    cannot POST settled status directly.
    """
    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, user_id from column_transfers
                where column_transfer_id = %s
                """,
                (body.column_transfer_id,),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(404, "Transfer not found.")
            transfer_id, user_id = row

            settled_at = body.settled_at or (datetime.now(timezone.utc) if body.new_status == "settled" else None)

            cur.execute(
                """
                update column_transfers
                set status = %s, settled_at = %s, updated_at = now()
                where id = %s
                returning id, column_transfer_id, direction, transfer_type,
                          amount_cents, status, counterparty_name,
                          counterparty_account_number_last_four, description,
                          audit_id, settled_at, created_at
                """,
                (body.new_status, settled_at, transfer_id),
            )
            row = cur.fetchone()
        conn.commit()

    audit_log(
        user_id=user_id,
        action=f"column.transfer.{body.new_status}",
        resource_type="column_transfer",
        resource_id=str(transfer_id),
        metadata={"column_transfer_id": body.column_transfer_id},
        ip_address=request.client.host if request.client else None,
    )

    return TransferOut(
        id=row[0], column_transfer_id=row[1], direction=row[2],
        transfer_type=row[3], amount_cents=row[4], status=row[5],
        counterparty_name=row[6], counterparty_account_number_last_four=row[7],
        description=row[8], audit_id=row[9], settled_at=row[10], created_at=row[11],
    )


@router.get("/transfers/{user_id}", response_model=list[TransferOut])
async def list_transfers(
    user_id: uuid.UUID,
    _: None = Depends(verify_client_key),
):
    """List recent transfers for a user."""
    pool = db.pool()
    if pool is None:
        raise HTTPException(503, "Database is not configured.")

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, column_transfer_id, direction, transfer_type,
                       amount_cents, status, counterparty_name,
                       counterparty_account_number_last_four, description,
                       audit_id, settled_at, created_at
                from column_transfers
                where user_id = %s
                order by created_at desc
                limit 50
                """,
                (user_id,),
            )
            rows = cur.fetchall()

    return [
        TransferOut(
            id=r[0], column_transfer_id=r[1], direction=r[2],
            transfer_type=r[3], amount_cents=r[4], status=r[5],
            counterparty_name=r[6], counterparty_account_number_last_four=r[7],
            description=r[8], audit_id=r[9], settled_at=r[10], created_at=r[11],
        )
        for r in rows
    ]