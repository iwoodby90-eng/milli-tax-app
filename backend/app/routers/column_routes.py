"""Authenticated Column money-rail routes.

Security invariants:
- user identity always comes from Milli's verified bearer session;
- the client cannot supply a user UUID or transfer status;
- Column credentials never leave the server;
- provider object IDs are ownership-checked before use;
- ACH creation always uses a provider idempotency key;
- local transfer state is reconciled only from Column's authoritative API;
- full counterparty account/routing numbers are transient and never persisted.
"""

from __future__ import annotations

from datetime import datetime
import secrets
import uuid
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from .. import db
from ..column_client import ColumnClient, ColumnRequestFailed, ColumnUnavailable
from ..security import require_user


router = APIRouter(prefix="/column", tags=["column"])


def _provider_client() -> ColumnClient:
    try:
        return ColumnClient.configured()
    except ColumnUnavailable as exc:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Column money movement is not configured",
        ) from exc


def _idempotency_key(kind: str, user_id: uuid.UUID, request_id: uuid.UUID) -> str:
    return f"milli.{kind}.{user_id}.{request_id}"


def _local_transfer_status(provider_status: str) -> str:
    normalized = provider_status.upper()
    if normalized in {"SETTLED", "COMPLETED"}:
        return "settled"
    if normalized in {"RETURNED", "PENDING_RETURN"}:
        return "returned"
    if normalized == "CANCELED":
        return "canceled"
    return "processing"


def _provider_datetime(payload: dict, key: str):
    value = payload.get(key)
    if not value:
        return None
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
    return None


def _audit(
    cur,
    *,
    user_id: uuid.UUID,
    action: str,
    resource_type: str,
    resource_id: uuid.UUID | None,
    amount_cents: int | None = None,
    provider_reference: str | None = None,
    metadata: str | None = None,
) -> str:
    audit_id = "FA-" + secrets.token_hex(16)
    cur.execute(
        """
        insert into financial_audit_log
            (audit_id, user_id, action, resource_type, resource_id,
             amount_cents, provider_reference, metadata)
        values (%s, %s, %s, %s, %s, %s, %s,
                case when %s is null then null else %s::jsonb end)
        """,
        (
            audit_id,
            user_id,
            action,
            resource_type,
            resource_id,
            amount_cents,
            provider_reference,
            metadata,
            metadata,
        ),
    )
    return audit_id


class AccountCreateIn(BaseModel):
    request_id: uuid.UUID
    column_entity_id: str = Field(min_length=8, max_length=128)
    account_type: Literal["checking", "tax_vault"] = "checking"


class AccountOut(BaseModel):
    id: uuid.UUID
    account_type: str
    provider_status: str
    available_balance_cents: int | None
    pending_balance_cents: int | None
    currency_code: str


class CounterpartyCreateIn(BaseModel):
    request_id: uuid.UUID
    name: str | None = Field(default=None, max_length=127)
    routing_number: str = Field(min_length=9, max_length=9, pattern=r"^[0-9]{9}$")
    account_number: str = Field(min_length=4, max_length=34)
    account_type: Literal["checking", "savings"] = "checking"


class CounterpartyOut(BaseModel):
    id: uuid.UUID
    name: str | None
    account_type: str
    account_last_four: str
    routing_last_four: str


class TransferCreateIn(BaseModel):
    request_id: uuid.UUID
    bank_account_id: uuid.UUID
    counterparty_id: uuid.UUID
    transfer_type: Literal["CREDIT", "DEBIT"]
    amount_cents: int = Field(gt=0)
    description: str = Field(default="MILLI transfer", min_length=1, max_length=127)


class TransferOut(BaseModel):
    id: uuid.UUID
    bank_account_id: uuid.UUID
    counterparty_id: uuid.UUID
    transfer_type: str
    amount_cents: int
    currency_code: str
    provider_status: str
    status: str
    audit_id: str
    settled_at: datetime | None = None
    returned_at: datetime | None = None
    completed_at: datetime | None = None


def _account_row(row) -> AccountOut:
    return AccountOut(
        id=row[0],
        account_type=row[1],
        provider_status=row[2],
        available_balance_cents=row[3],
        pending_balance_cents=row[4],
        currency_code=row[5],
    )


def _counterparty_row(row) -> CounterpartyOut:
    return CounterpartyOut(
        id=row[0],
        name=row[1],
        account_type=row[2],
        account_last_four=row[3],
        routing_last_four=row[4],
    )


def _transfer_row(row) -> TransferOut:
    return TransferOut(
        id=row[0],
        bank_account_id=row[1],
        counterparty_id=row[2],
        transfer_type=row[3],
        amount_cents=row[4],
        currency_code=row[5],
        provider_status=row[6],
        status=row[7],
        audit_id=row[8],
        settled_at=row[9],
        returned_at=row[10],
        completed_at=row[11],
    )


@router.post("/accounts", response_model=AccountOut, status_code=201)
def create_account(
    body: AccountCreateIn,
    user_id: uuid.UUID = Depends(require_user),
) -> AccountOut:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, account_type, provider_status, available_balance_cents,
                       pending_balance_cents, currency_code
                  from column_bank_accounts
                 where user_id = %s and client_request_id = %s
                """,
                (user_id, body.request_id),
            )
            existing = cur.fetchone()
            if existing:
                return _account_row(existing)

    client = _provider_client()
    request_key = _idempotency_key("account", user_id, body.request_id)
    description = "MILLI Tax Vault" if body.account_type == "tax_vault" else "MILLI Checking"

    try:
        provider = client.create_bank_account(
            entity_id=body.column_entity_id,
            description=description,
            idempotency_key=request_key,
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column account creation failed") from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column returned an invalid account")

    balances = provider.get("balances") if isinstance(provider.get("balances"), dict) else {}
    available = balances.get("available_amount")
    pending = balances.get("pending_amount")
    provider_status = str(provider.get("status") or "open")
    currency = str(provider.get("currency_code") or "USD")

    local_id = uuid.uuid4()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_bank_accounts
                    (id, user_id, client_request_id, column_bank_account_id,
                     column_entity_id, account_type, provider_status,
                     available_balance_cents, pending_balance_cents, currency_code)
                values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                on conflict (user_id, client_request_id) do update
                    set provider_status = excluded.provider_status,
                        available_balance_cents = excluded.available_balance_cents,
                        pending_balance_cents = excluded.pending_balance_cents,
                        updated_at = now()
                returning id, account_type, provider_status, available_balance_cents,
                          pending_balance_cents, currency_code
                """,
                (
                    local_id,
                    user_id,
                    body.request_id,
                    provider_id,
                    body.column_entity_id,
                    body.account_type,
                    provider_status,
                    available,
                    pending,
                    currency,
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.account.created",
                resource_type="column_bank_account",
                resource_id=row[0],
                provider_reference=provider_id,
            )
        conn.commit()
    return _account_row(row)


@router.post("/accounts/{account_id}/reconcile", response_model=AccountOut)
def reconcile_account(
    account_id: uuid.UUID,
    user_id: uuid.UUID = Depends(require_user),
) -> AccountOut:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select column_bank_account_id
                  from column_bank_accounts
                 where id = %s and user_id = %s
                """,
                (account_id, user_id),
            )
            owned = cur.fetchone()
    if not owned:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Column account not found")

    try:
        provider = _provider_client().get_bank_account(owned[0])
    except ColumnRequestFailed as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column account reconciliation failed") from exc

    balances = provider.get("balances") if isinstance(provider.get("balances"), dict) else {}
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update column_bank_accounts
                   set provider_status = %s,
                       available_balance_cents = %s,
                       pending_balance_cents = %s,
                       currency_code = %s,
                       updated_at = now()
                 where id = %s and user_id = %s
                returning id, account_type, provider_status, available_balance_cents,
                          pending_balance_cents, currency_code
                """,
                (
                    str(provider.get("status") or "unknown"),
                    balances.get("available_amount"),
                    balances.get("pending_amount"),
                    str(provider.get("currency_code") or "USD"),
                    account_id,
                    user_id,
                ),
            )
            row = cur.fetchone()
        conn.commit()
    return _account_row(row)


@router.post("/counterparties", response_model=CounterpartyOut, status_code=201)
def create_counterparty(
    body: CounterpartyCreateIn,
    user_id: uuid.UUID = Depends(require_user),
) -> CounterpartyOut:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, display_name, account_type, account_last_four, routing_last_four
                  from column_counterparties
                 where user_id = %s and client_request_id = %s
                """,
                (user_id, body.request_id),
            )
            existing = cur.fetchone()
            if existing:
                return _counterparty_row(existing)

    try:
        provider = _provider_client().create_counterparty(
            account_number=body.account_number,
            routing_number=body.routing_number,
            account_type=body.account_type,
            name=body.name,
            description="MILLI verified counterparty",
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column counterparty creation failed") from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column returned an invalid counterparty")

    local_id = uuid.uuid4()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_counterparties
                    (id, user_id, client_request_id, column_counterparty_id,
                     display_name, account_type, account_last_four, routing_last_four)
                values (%s, %s, %s, %s, %s, %s, %s, %s)
                on conflict (user_id, client_request_id) do update
                    set display_name = excluded.display_name,
                        updated_at = now()
                returning id, display_name, account_type, account_last_four, routing_last_four
                """,
                (
                    local_id,
                    user_id,
                    body.request_id,
                    provider_id,
                    body.name,
                    body.account_type,
                    body.account_number[-4:],
                    body.routing_number[-4:],
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.counterparty.created",
                resource_type="column_counterparty",
                resource_id=row[0],
                provider_reference=provider_id,
            )
        conn.commit()
    return _counterparty_row(row)


@router.post("/transfers", response_model=TransferOut, status_code=201)
def create_transfer(
    body: TransferCreateIn,
    user_id: uuid.UUID = Depends(require_user),
) -> TransferOut:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, column_bank_account_id, column_counterparty_id,
                       transfer_type, amount_cents, currency_code,
                       provider_status, local_status, audit_id,
                       settled_at, returned_at, completed_at
                  from column_ach_transfers
                 where user_id = %s and client_request_id = %s
                """,
                (user_id, body.request_id),
            )
            existing = cur.fetchone()
            if existing:
                return _transfer_row(existing)

            cur.execute(
                """
                select column_bank_account_id
                  from column_bank_accounts
                 where id = %s and user_id = %s and provider_status = 'open'
                """,
                (body.bank_account_id, user_id),
            )
            account = cur.fetchone()
            if not account:
                raise HTTPException(status.HTTP_404_NOT_FOUND, "Active Column account not found")

            cur.execute(
                """
                select column_counterparty_id
                  from column_counterparties
                 where id = %s and user_id = %s
                """,
                (body.counterparty_id, user_id),
            )
            counterparty = cur.fetchone()
            if not counterparty:
                raise HTTPException(status.HTTP_404_NOT_FOUND, "Column counterparty not found")

    request_key = _idempotency_key("ach", user_id, body.request_id)
    try:
        provider = _provider_client().create_ach_transfer(
            bank_account_id=account[0],
            counterparty_id=counterparty[0],
            transfer_type=body.transfer_type,
            amount_cents=body.amount_cents,
            description=body.description,
            idempotency_key=request_key,
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column ACH transfer creation failed") from exc

    provider_id = str(provider.get("id") or "")
    provider_status = str(provider.get("status") or "INITIATED").upper()
    if not provider_id:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column returned an invalid transfer")

    local_id = uuid.uuid4()
    local_status = _local_transfer_status(provider_status)

    with db.connection() as conn:
        with conn.cursor() as cur:
            audit_id = _audit(
                cur,
                user_id=user_id,
                action="column.ach.created",
                resource_type="column_ach_transfer",
                resource_id=local_id,
                amount_cents=body.amount_cents,
                provider_reference=provider_id,
            )
            cur.execute(
                """
                insert into column_ach_transfers
                    (id, user_id, client_request_id, column_bank_account_id,
                     column_counterparty_id, column_ach_transfer_id,
                     idempotency_key, transfer_type, amount_cents, currency_code,
                     provider_status, local_status, audit_id,
                     settled_at, returned_at, completed_at)
                values (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'USD',
                        %s, %s, %s, %s, %s, %s)
                on conflict (user_id, client_request_id) do update
                    set provider_status = excluded.provider_status,
                        local_status = excluded.local_status,
                        updated_at = now()
                returning id, column_bank_account_id, column_counterparty_id,
                          transfer_type, amount_cents, currency_code,
                          provider_status, local_status, audit_id,
                          settled_at, returned_at, completed_at
                """,
                (
                    local_id,
                    user_id,
                    body.request_id,
                    body.bank_account_id,
                    body.counterparty_id,
                    provider_id,
                    request_key,
                    body.transfer_type,
                    body.amount_cents,
                    provider_status,
                    local_status,
                    audit_id,
                    _provider_datetime(provider, "settled_at"),
                    _provider_datetime(provider, "returned_at"),
                    _provider_datetime(provider, "completed_at"),
                ),
            )
            row = cur.fetchone()
        conn.commit()
    return _transfer_row(row)


@router.post("/transfers/{transfer_id}/reconcile", response_model=TransferOut)
def reconcile_transfer(
    transfer_id: uuid.UUID,
    user_id: uuid.UUID = Depends(require_user),
) -> TransferOut:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select column_ach_transfer_id
                  from column_ach_transfers
                 where id = %s and user_id = %s
                """,
                (transfer_id, user_id),
            )
            owned = cur.fetchone()
    if not owned:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Column transfer not found")

    try:
        provider = _provider_client().get_ach_transfer(owned[0])
    except ColumnRequestFailed as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column transfer reconciliation failed") from exc

    if str(provider.get("id") or "") != owned[0]:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column transfer identity mismatch")

    provider_status = str(provider.get("status") or "UNKNOWN").upper()
    local_status = _local_transfer_status(provider_status)

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update column_ach_transfers
                   set provider_status = %s,
                       local_status = %s,
                       settled_at = coalesce(%s, settled_at),
                       returned_at = coalesce(%s, returned_at),
                       completed_at = coalesce(%s, completed_at),
                       updated_at = now()
                 where id = %s and user_id = %s
                returning id, column_bank_account_id, column_counterparty_id,
                          transfer_type, amount_cents, currency_code,
                          provider_status, local_status, audit_id,
                          settled_at, returned_at, completed_at
                """,
                (
                    provider_status,
                    local_status,
                    _provider_datetime(provider, "settled_at"),
                    _provider_datetime(provider, "returned_at"),
                    _provider_datetime(provider, "completed_at"),
                    transfer_id,
                    user_id,
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.ach.reconciled",
                resource_type="column_ach_transfer",
                resource_id=transfer_id,
                amount_cents=row[4],
                provider_reference=owned[0],
            )
        conn.commit()
    return _transfer_row(row)
