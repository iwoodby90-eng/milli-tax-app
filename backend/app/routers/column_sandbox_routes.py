"""Sandbox-only Column end-to-end provisioning proof.

Creates a synthetic Milli customer entirely server-side, then provisions:
Column person entity -> Column bank account -> debit card account -> virtual card.

No real customer KYC data is accepted by this route. Production issuance remains
disabled until server-side Elite entitlement and approved card-program controls
are in place.
"""

from __future__ import annotations

import uuid
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict

from .. import db
from ..column_client import ColumnClient, ColumnRequestFailed, ColumnUnavailable
from ..config import get_settings
from ..security import require_user
from .column_routes import AccountCreateIn, AccountOut, create_account


router = APIRouter(prefix="/column/sandbox", tags=["column-sandbox"])


class StrictSandboxModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class SandboxProvisionIn(StrictSandboxModel):
    request_id: uuid.UUID
    card_type: Literal["virtual", "physical"] = "virtual"


class SandboxCustomerOut(BaseModel):
    verification_status: str
    ready_for_financial_products: bool


class SandboxCardAccountOut(BaseModel):
    id: uuid.UUID
    provider_status: str
    bank_account_id: uuid.UUID


class SandboxCardOut(BaseModel):
    id: uuid.UUID
    card_type: str
    provider_status: str
    last_four: str | None
    expiration_month: int | None
    expiration_year: int | None
    design: str = "milli-approved"


class SandboxProvisionOut(BaseModel):
    customer: SandboxCustomerOut
    bank_account: AccountOut
    card_account: SandboxCardAccountOut
    card: SandboxCardOut


def _provider() -> ColumnClient:
    settings = get_settings()
    if settings.column_env != "sandbox":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    try:
        return ColumnClient.configured()
    except ColumnUnavailable as exc:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Column sandbox is not configured",
        ) from exc


def _idempotency_key(kind: str, user_id: uuid.UUID, request_id: uuid.UUID) -> str:
    return f"milli.sandbox.{kind}.{user_id}.{request_id}"


def _local_kyc_status(provider_status: str) -> str:
    value = provider_status.upper()
    if value == "VERIFIED":
        return "verified"
    if value == "DENIED":
        return "rejected"
    return "pending"


def _audit(
    cur,
    *,
    user_id: uuid.UUID,
    action: str,
    resource_type: str,
    resource_id: uuid.UUID | None,
    provider_reference: str | None,
) -> None:
    cur.execute(
        """
        insert into financial_audit_log
            (audit_id, user_id, action, resource_type, resource_id,
             provider_reference)
        values (%s, %s, %s, %s, %s, %s)
        """,
        (
            "FA-" + uuid.uuid4().hex,
            user_id,
            action,
            resource_type,
            resource_id,
            provider_reference,
        ),
    )


def _customer(user_id: uuid.UUID, request_id: uuid.UUID) -> tuple[str, str]:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select column_entity_id, kyc_status
                  from column_customer_profiles
                 where user_id = %s
                """,
                (user_id,),
            )
            existing = cur.fetchone()
    if existing:
        return existing[0], existing[1]

    # Synthetic data only. These values exist solely to prove Column Sandbox
    # integration and must never be reused for a production identity.
    suffix = user_id.hex[:12]
    try:
        provider = _provider().create_person_entity(
            first_name="Milli",
            last_name="Sandbox",
            ssn="123456789",
            date_of_birth="1987-03-15",
            email=f"sandbox+{suffix}@drivemilli.com",
            address={
                "line_1": "123 Federal Reserve Way",
                "city": "San Francisco",
                "state": "CA",
                "postal_code": "94123",
                "country_code": "US",
            },
            phone_number=None,
            idempotency_key=_idempotency_key("entity", user_id, request_id),
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column sandbox customer creation failed",
        ) from exc

    provider_id = str(provider.get("id") or "")
    provider_status = str(
        provider.get("verification_status") or "UNVERIFIED"
    ).upper()
    if not provider_id:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column returned an invalid customer",
        )

    local_status = _local_kyc_status(provider_status)
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_customer_profiles
                    (user_id, column_entity_id, kyc_status, provider_status,
                     verified_at, last_reconciled_at)
                values (%s, %s, %s, %s,
                        case when %s = 'verified' then now() else null end,
                        now())
                returning column_entity_id, kyc_status
                """,
                (
                    user_id,
                    provider_id,
                    local_status,
                    provider_status,
                    local_status,
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.sandbox_customer.created",
                resource_type="column_customer_profile",
                resource_id=user_id,
                provider_reference=provider_id,
            )
        conn.commit()
    return row[0], row[1]


def _card_program(user_id: uuid.UUID) -> str:
    settings = get_settings()
    if settings.column_card_program_id:
        return settings.column_card_program_id

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select column_card_program_id
                  from column_card_programs
                 where environment = 'sandbox'
                   and card_program_type = 'debit'
                 order by created_at asc
                 limit 1
                """
            )
            row = cur.fetchone()
    if row:
        return row[0]

    try:
        provider = _provider().create_sandbox_debit_card_program(
            description="MILLI Elite Sandbox Debit"
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column sandbox card program creation failed",
        ) from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column returned an invalid card program",
        )

    scheme = str(provider.get("primary_card_scheme") or "visa").lower()
    if scheme not in {"visa", "mastercard"}:
        scheme = "visa"

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_card_programs
                    (id, environment, column_card_program_id, card_program_type,
                     scheme, description, provider_status)
                values (%s, 'sandbox', %s, 'debit', %s, %s, %s)
                on conflict (environment, card_program_type) do update
                    set updated_at = now()
                returning column_card_program_id
                """,
                (
                    uuid.uuid4(),
                    provider_id,
                    scheme,
                    "MILLI Elite Sandbox Debit",
                    str(provider.get("status") or "active"),
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.sandbox_card_program.ready",
                resource_type="column_card_program",
                resource_id=None,
                provider_reference=row[0],
            )
        conn.commit()
    return row[0]


def _card_account(
    *,
    user_id: uuid.UUID,
    bank_account: AccountOut,
    card_program_id: str,
) -> tuple[SandboxCardAccountOut, str]:
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, provider_status, column_bank_account_local_id,
                       column_card_account_id
                  from column_card_accounts
                 where user_id = %s
                   and column_bank_account_local_id = %s
                """,
                (user_id, bank_account.id),
            )
            existing = cur.fetchone()
            if existing:
                return (
                    SandboxCardAccountOut(
                        id=existing[0],
                        provider_status=existing[1],
                        bank_account_id=existing[2],
                    ),
                    existing[3],
                )

            cur.execute(
                """
                select column_bank_account_id
                  from column_bank_accounts
                 where id = %s and user_id = %s
                """,
                (bank_account.id, user_id),
            )
            bank_provider = cur.fetchone()

    if not bank_provider:
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "Column bank account persistence failed",
        )

    try:
        provider = _provider().create_card_account(
            card_program_id=card_program_id,
            bank_account_id=bank_provider[0],
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column card account creation failed",
        ) from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column returned an invalid card account",
        )

    local_id = uuid.uuid4()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_card_accounts
                    (id, user_id, column_bank_account_local_id,
                     column_card_program_id, column_card_account_id,
                     provider_status)
                values (%s, %s, %s, %s, %s, %s)
                returning id, provider_status, column_bank_account_local_id
                """,
                (
                    local_id,
                    user_id,
                    bank_account.id,
                    card_program_id,
                    provider_id,
                    str(provider.get("status") or "open"),
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.card_account.created",
                resource_type="column_card_account",
                resource_id=local_id,
                provider_reference=provider_id,
            )
        conn.commit()

    return (
        SandboxCardAccountOut(
            id=row[0],
            provider_status=row[1],
            bank_account_id=row[2],
        ),
        provider_id,
    )


def _card(
    *,
    user_id: uuid.UUID,
    entity_id: str,
    card_account_local_id: uuid.UUID,
    card_account_provider_id: str,
    card_type: str,
) -> SandboxCardOut:
    settings = get_settings()
    if card_type == "physical" and not settings.column_card_template_id:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Approved MILLI physical card template is not configured",
        )

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select id, card_type, provider_status, last_four,
                       expiration_month, expiration_year
                  from column_cards
                 where user_id = %s
                   and column_card_account_local_id = %s
                   and card_type = %s
                """,
                (user_id, card_account_local_id, card_type),
            )
            existing = cur.fetchone()
    if existing:
        return SandboxCardOut(
            id=existing[0],
            card_type=existing[1],
            provider_status=existing[2],
            last_four=existing[3],
            expiration_month=existing[4],
            expiration_year=existing[5],
        )

    # Virtual-first keeps the sandbox proof immediate. Physical issuance is
    # allowed only when the approved MILLI template is configured.
    shipping = None
    if card_type == "physical":
        shipping = {
            "name": "Milli Sandbox",
            "address": {
                "line_1": "123 Federal Reserve Way",
                "city": "San Francisco",
                "state": "CA",
                "postal_code": "94123",
                "country_code": "US",
            },
        }

    try:
        provider = _provider().create_card(
            card_account_id=card_account_provider_id,
            authorized_user_entity_id=entity_id,
            card_type=card_type,
            card_template_id=(
                settings.column_card_template_id
                if card_type == "physical"
                else None
            ),
            shipping_details=shipping,
        )
    except ColumnRequestFailed as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column card creation failed",
        ) from exc

    provider_id = str(provider.get("id") or "")
    if not provider_id:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "Column returned an invalid card",
        )

    local_id = uuid.uuid4()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into column_cards
                    (id, user_id, column_card_account_local_id,
                     column_card_id, card_type, provider_status, last_four,
                     expiration_month, expiration_year, card_template_id)
                values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                returning id, card_type, provider_status, last_four,
                          expiration_month, expiration_year
                """,
                (
                    local_id,
                    user_id,
                    card_account_local_id,
                    provider_id,
                    card_type,
                    str(provider.get("status") or "paused"),
                    provider.get("last_four_digits"),
                    provider.get("expiration_month"),
                    provider.get("expiration_year"),
                    (
                        settings.column_card_template_id
                        if card_type == "physical"
                        else None
                    ),
                ),
            )
            row = cur.fetchone()
            _audit(
                cur,
                user_id=user_id,
                action="column.card.created",
                resource_type="column_card",
                resource_id=local_id,
                provider_reference=provider_id,
            )
        conn.commit()

    return SandboxCardOut(
        id=row[0],
        card_type=row[1],
        provider_status=row[2],
        last_four=row[3],
        expiration_month=row[4],
        expiration_year=row[5],
    )


@router.post("/provision-demo", response_model=SandboxProvisionOut, status_code=201)
def provision_demo(
    body: SandboxProvisionIn,
    user_id: uuid.UUID = Depends(require_user),
) -> SandboxProvisionOut:
    """Create and persist the complete synthetic Column sandbox customer."""
    settings = get_settings()
    if body.card_type == "physical" and not settings.column_card_template_id:
        # Fail before creating any provider resources: physical cards are never
        # allowed to fall back to a generic/unapproved design.
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Approved MILLI physical card template is not configured",
        )

    entity_id, kyc_status = _customer(user_id, body.request_id)
    if kyc_status != "verified":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Column sandbox identity verification is not complete",
        )

    bank_account = create_account(
        AccountCreateIn(request_id=body.request_id, account_type="checking"),
        user_id,
    )
    program_id = _card_program(user_id)
    card_account, card_account_provider_id = _card_account(
        user_id=user_id,
        bank_account=bank_account,
        card_program_id=program_id,
    )
    card = _card(
        user_id=user_id,
        entity_id=entity_id,
        card_account_local_id=card_account.id,
        card_account_provider_id=card_account_provider_id,
        card_type=body.card_type,
    )

    return SandboxProvisionOut(
        customer=SandboxCustomerOut(
            verification_status=kyc_status,
            ready_for_financial_products=True,
        ),
        bank_account=bank_account,
        card_account=card_account,
        card=card,
    )


@router.get("/provision-demo", response_model=SandboxProvisionOut)
def read_demo(
    user_id: uuid.UUID = Depends(require_user),
) -> SandboxProvisionOut:
    """Read persisted proof for the authenticated user without exposing PAN."""
    _provider()  # Enforce sandbox-only access.

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select kyc_status
                  from column_customer_profiles
                 where user_id = %s
                """,
                (user_id,),
            )
            customer = cur.fetchone()
            cur.execute(
                """
                select id, account_type, provider_status, available_balance_cents,
                       pending_balance_cents, currency_code
                  from column_bank_accounts
                 where user_id = %s
                 order by created_at asc
                 limit 1
                """,
                (user_id,),
            )
            bank = cur.fetchone()
            cur.execute(
                """
                select id, provider_status, column_bank_account_local_id
                  from column_card_accounts
                 where user_id = %s
                 order by created_at asc
                 limit 1
                """,
                (user_id,),
            )
            card_account = cur.fetchone()
            cur.execute(
                """
                select id, card_type, provider_status, last_four,
                       expiration_month, expiration_year
                  from column_cards
                 where user_id = %s
                 order by created_at asc
                 limit 1
                """,
                (user_id,),
            )
            card = cur.fetchone()

    if not all((customer, bank, card_account, card)):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Column sandbox demo has not been provisioned",
        )

    return SandboxProvisionOut(
        customer=SandboxCustomerOut(
            verification_status=customer[0],
            ready_for_financial_products=(customer[0] == "verified"),
        ),
        bank_account=AccountOut(
            id=bank[0],
            account_type=bank[1],
            provider_status=bank[2],
            available_balance_cents=bank[3],
            pending_balance_cents=bank[4],
            currency_code=bank[5],
        ),
        card_account=SandboxCardAccountOut(
            id=card_account[0],
            provider_status=card_account[1],
            bank_account_id=card_account[2],
        ),
        card=SandboxCardOut(
            id=card[0],
            card_type=card[1],
            provider_status=card[2],
            last_four=card[3],
            expiration_month=card[4],
            expiration_year=card[5],
        ),
    )
