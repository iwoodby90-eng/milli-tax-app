"""Authenticated Plaid -> Column money-rail routes.

Trust boundaries:
- Sign in with Apple -> Milli bearer session establishes the user.
- Plaid Auth establishes the external bank account/routing details.
- Column KYC profile establishes the user's Column entity.
- Column is the only BaaS / ACH movement provider.
- The mobile client never supplies user IDs, Column entity IDs, raw bank
  credentials, provider status, or ACH SEC classification.
"""

from __future__ import annotations

from datetime import datetime
import secrets
import uuid
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field

from .. import db
from ..column_client import ColumnClient, ColumnRequestFailed, ColumnUnavailable
from ..config import get_settings
from ..plaid_client import get_client as get_plaid_client
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


def _normalize_enum(value) -> str:
    return str(value or "").split(".")[-1].lower()


def _local_transfer_status(provider_status: str) -> str:
    normalized = provider_status.upper()
    if normalized in {"SETTLED", "COMPLETED"}:
        return "settled"
    if normalized in {"RETURNED", "PENDING_RETURN"}:
        return "returned"
    if normalized == "CANCELED":
        return "canceled"
    # Unknown/new provider states never become settled by inference.
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
) -> str:
    audit_id = "FA-" + secrets.token_hex(16)
    cur.execute(
        """
        insert into financial_audit_log
            (audit_id, user_id, action, resource_type, resource_id,
             amount_cents, provider_reference)
        values (%s, %s, %s, %s, %s, %s, %s)
        """,
        (
            audit_id,
            user_id,
            action,
            resource_type,
            resource_id,
            amount_cents,
            provider_reference,
        ),
    )
    return audit_id


def _plaid_ach_details(user_id: uuid.UUID, plaid_account_id: uuid.UUID) -> dict:
    """Resolve ACH details directly from Plaid Auth for an owned account.

    Account and routing numbers are returned only to server-side code and are
    never included in an API response or persisted by Milli.
    """
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select a.account_id, a.name, a.subtype, i.access_token
                  from plaid_accounts a
                  join plaid_items i on i.id = a.plaid_item_id
                 where a.id = %s
                   and a.user_id = %s
                   and i.user_id = %s
                   and i.status = 'active'
                """,
                (plaid_account_id, user_id, user_id),
            )
            row = cur.fetchone()

    if row is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Active Plaid account not found")

    provider_account_id, cached_name, cached_subtype, access_token = row
    plaid_client = get_plaid_client()
    if plaid_client is None:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Plaid Auth is not configured",
        )

    from plaid.model.auth_get_request import AuthGetRequest

    try:
        auth_payload = plaid_client.auth_get(
            AuthGetRequest(access_token=access_token)
        ).to_dict()
    except Exception as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Plaid Auth could not verify the linked bank account",
        ) from exc

    account = next(
        (
            item for item in auth_payload.get("accounts", [])
            if item.get("account_id") == provider_account_id
        ),
        None,
    )
    ach = next(
        (
            item for item in (auth_payload.get("numbers") or {}).get("ach", [])
            if item.get("account_id") == provider_account_id
        ),
        None,
    )
    if account is None or ach is None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "The linked Plaid account is not ACH-ready",
        )

    verification = _normalize_enum(account.get("verification_status"))
    blocked_verification = {
        "pending_automatic_verification",
        "pending_manual_verification",
        "unsent",
        "verification_expired",
        "verification_failed",
        "database_insights_fail",
    }
    if verification in blocked_verification:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "The linked bank account has not completed ACH verification",
        )

    account_number = str(ach.get("account") or "")
    routing_number = str(ach.get("routing") or "")
    if not account_number or len(routing_number) != 9 or not routing_number.isdigit():
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Plaid did not return usable ACH account details",
        )

    subtype = _normalize_enum(account.get("subtype") or cached_subtype)
    if subtype not in {"checking", "savings"}:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Only checking or savings accounts can be used for Milli ACH transfers",
        )

    return {
        "plaid_account_id": plaid_account_id,
        "provider_account_id": provider_account_id,
        "name": account.get("name") or cached_name,
        "account_type": subtype,
        "account_number": account_number,
        "routing_number": routing_number,
    }


class StrictFinancialModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class AccountCreateIn(StrictFinancialModel):
    request_id: uuid.UUID
    account_type: Literal["checking", "tax_vault"] = "checking"


class AccountOut(BaseModel):
    id: uuid.UUID
    account_type: str
    provider_status: str
    available_balance_cents: int | None
    pending_balance_cents: int | None
    currency_code: str


class PlaidCounterpartyCreateIn(StrictFinancialModel):
    request_id: uuid.UUID
    plaid_account_id: uuid.UUID


class CounterpartyOut(BaseModel):
    id: uuid.UUID
    plaid_account_id: uuid.UUID
    name: str | None
    account_type: str
    account_last_four: str
    routing_last_four: str


class TransferCreateIn(StrictFinancialModel):
    request_id: uuid.UUID
    bank_account_id: uuid.UUID
    counterparty_id: uuid.UUID
    transfer_type: Literal["CREDIT", "DEBIT"]
    amount_cents: int = Field(gt=0)
    description: str = Field(default="MILLI transfer", min_length=1, max_length=255)


class TransferOut(BaseModel):
    id: uuid.UUID
    bank_account_id: uuid.UUID
    counterparty_id: uuid.UUID
    transfer_type: str
    entry_class_code: str
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
        plaid_account_id=row[1],
        name=row[2],
        account_type=row[3],
        account_last_four=row[4],
        routing_last_four=row[5],
    )


def _transfer_row(row) -> TransferOut:
    return TransferOut(
        id=row[0],
        bank_account_id=row[1],
        counterparty_id=row[2],
        transfer_type=row[3],
        entry_class_code=row[4],
        amount_cents=row[5],
        currency_code=row[6],
        provider_status=row[7],
        status=row[8],
        audit_id=row[9],
        settled_at=row[10],
        returned_at=row[11],
        completed_at=row[12],
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

            # Column entity ownership is server-maintained after KYC. Never
            # accept a provider entity ID from the phone.
            cur.execute(
                """
                select column_entity_id
                  from column_customer_profiles
                 where user_id = %s and kyc_status = 'verified'
                """,
                (user_id,),
            )
            profile = cur.fetchone()

    if profile is None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Column identity verification is incomplete",
        )

    client = _provider_client()
    description = "MILLI Tax Vault" if body.account_type == "tax_vault" else "MILLI Checking"
    try:
        provider = client.create_bank_account(
            entity_id=profile[0],
            description=description,
            idempotency_key=_idempotency_key("account", user_id, body.request_id),
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column account creation failed") from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column returned an invalid account")

    balances = provider.get("balances") if isinstance(provider.get("balances"), dict) else {}
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
                    profile[0],
                    body.account_type,
                    str(provider.get("status") or "open"),
                    balances.get("available_amount"),
                    balances.get("pending_amount"),
                    str(provider.get("currency_code") or "USD"),
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

    if str(provider.get("id") or "") != owned[0]:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column account identity mismatch")

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


@router.post("/counterparties/from-plaid", response_model=CounterpartyOut, status_code=201)
def create_counterparty_from_plaid(
    body: PlaidCounterpartyCreateIn,
    user_id: uuid.UUID = Depends(require_user),
) -> CounterpartyOut:
    details = _plaid_ach_details(user_id, body.plaid_account_id)
    provider_client = _provider_client()

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, plaid_account_id, column_counterparty_id, display_name,
                       account_type, account_last_four, routing_last_four
                  from column_counterparties
                 where user_id = %s and client_request_id = %s
                """,
                (user_id, body.request_id),
            )
            by_request = cur.fetchone()
            if by_request and by_request[1] != body.plaid_account_id:
                raise HTTPException(
                    status.HTTP_409_CONFLICT,
                    "Request ID is already bound to another Plaid account",
                )

            cur.execute(
                """
                select id, plaid_account_id, column_counterparty_id, display_name,
                       account_type, account_last_four, routing_last_four
                  from column_counterparties
                 where user_id = %s and plaid_account_id = %s
                """,
                (user_id, body.plaid_account_id),
            )
            by_account = cur.fetchone()

    existing = by_request or by_account
    if existing:
        try:
            provider_existing = provider_client.get_counterparty(existing[2])
        except ColumnRequestFailed:
            provider_existing = {}

        if (
            str(provider_existing.get("account_number") or "") == details["account_number"]
            and str(provider_existing.get("routing_number") or "") == details["routing_number"]
        ):
            return CounterpartyOut(
                id=existing[0],
                plaid_account_id=existing[1],
                name=existing[3],
                account_type=existing[4],
                account_last_four=existing[5],
                routing_last_four=existing[6],
            )

    try:
        provider = provider_client.create_counterparty(
            account_number=details["account_number"],
            routing_number=details["routing_number"],
            account_type=details["account_type"],
            name=details["name"],
            description="MILLI Plaid-verified ACH account",
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column counterparty creation failed",
        ) from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Column returned an invalid counterparty")

    with db.connection() as conn:
        with conn.cursor() as cur:
            if existing:
                local_id = existing[0]
                cur.execute(
                    """
                    update column_counterparties
                       set column_counterparty_id = %s,
                           display_name = %s,
                           account_type = %s,
                           account_last_four = %s,
                           routing_last_four = %s,
                           updated_at = now()
                     where id = %s and user_id = %s
                    returning id, plaid_account_id, display_name, account_type,
                              account_last_four, routing_last_four
                    """,
                    (
                        provider_id,
                        details["name"],
                        details["account_type"],
                        details["account_number"][-4:],
                        details["routing_number"][-4:],
                        local_id,
                        user_id,
                    ),
                )
                action = "column.counterparty.refreshed"
            else:
                local_id = uuid.uuid4()
                cur.execute(
                    """
                    insert into column_counterparties
                        (id, user_id, client_request_id, plaid_account_id,
                         column_counterparty_id, display_name, account_type,
                         account_last_four, routing_last_four)
                    values (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    returning id, plaid_account_id, display_name, account_type,
                              account_last_four, routing_last_four
                    """,
                    (
                        local_id,
                        user_id,
                        body.request_id,
                        body.plaid_account_id,
                        provider_id,
                        details["name"],
                        details["account_type"],
                        details["account_number"][-4:],
                        details["routing_number"][-4:],
                    ),
                )
                action = "column.counterparty.created"

            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action=action,
                resource_type="column_counterparty",
                resource_id=row[0],
                provider_reference=provider_id,
            )
        conn.commit()
    return _counterparty_row(row)


def _verify_counterparty_is_current(
    *,
    user_id: uuid.UUID,
    provider_counterparty_id: str,
    plaid_account_id: uuid.UUID,
) -> None:
    """Fail closed if Plaid Auth and the Column counterparty no longer match."""
    details = _plaid_ach_details(user_id, plaid_account_id)
    try:
        provider = _provider_client().get_counterparty(provider_counterparty_id)
    except ColumnRequestFailed as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column counterparty verification failed",
        ) from exc

    if (
        str(provider.get("account_number") or "") != details["account_number"]
        or str(provider.get("routing_number") or "") != details["routing_number"]
    ):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Linked bank details changed; refresh the Plaid-backed counterparty before transferring",
        )


@router.post("/transfers", response_model=TransferOut, status_code=201)
def create_transfer(
    body: TransferCreateIn,
    user_id: uuid.UUID = Depends(require_user),
) -> TransferOut:
    settings = get_settings()
    if not settings.column_ach_configured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Column ACH compliance configuration is incomplete",
        )

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, column_bank_account_id, column_counterparty_id,
                       transfer_type, entry_class_code, amount_cents, currency_code,
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
                select column_counterparty_id, plaid_account_id
                  from column_counterparties
                 where id = %s and user_id = %s
                """,
                (body.counterparty_id, user_id),
            )
            counterparty = cur.fetchone()
            if not counterparty:
                raise HTTPException(status.HTTP_404_NOT_FOUND, "Column counterparty not found")

    _verify_counterparty_is_current(
        user_id=user_id,
        local_counterparty_id=body.counterparty_id,
        provider_counterparty_id=counterparty[0],
        plaid_account_id=counterparty[1],
    )

    entry_class_code = (
        settings.column_ach_credit_sec_code
        if body.transfer_type == "CREDIT"
        else settings.column_ach_debit_sec_code
    )
    if entry_class_code is None:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "ACH SEC classification is not configured",
        )

    request_key = _idempotency_key("ach", user_id, body.request_id)
    try:
        provider = _provider_client().create_ach_transfer(
            bank_account_id=account[0],
            counterparty_id=counterparty[0],
            transfer_type=body.transfer_type,
            amount_cents=body.amount_cents,
            description=body.description,
            entry_class_code=entry_class_code,
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
                     idempotency_key, transfer_type, entry_class_code,
                     amount_cents, currency_code, provider_status, local_status,
                     audit_id, settled_at, returned_at, completed_at)
                values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'USD',
                        %s, %s, %s, %s, %s, %s)
                returning id, column_bank_account_id, column_counterparty_id,
                          transfer_type, entry_class_code, amount_cents,
                          currency_code, provider_status, local_status, audit_id,
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
                    entry_class_code,
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
                          transfer_type, entry_class_code, amount_cents,
                          currency_code, provider_status, local_status, audit_id,
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
                amount_cents=row[5],
                provider_reference=owned[0],
            )
        conn.commit()
    return _transfer_row(row)
