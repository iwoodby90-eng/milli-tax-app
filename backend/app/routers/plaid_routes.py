"""Plaid bank-connect endpoints.

Flow:
  1. iOS calls POST /plaid/link-token  -> link_token for Plaid Link.
  2. Link returns a public_token to iOS.
  3. iOS calls POST /plaid/exchange-public-token -> backend stores the access
     token (never returned to the client) and syncs accounts.
  4. Plaid calls POST /plaid/webhook on updates.
"""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel

from ..config import get_settings
from ..plaid_client import get_client
from ..security import require_user
from .. import db

router = APIRouter(prefix="/plaid", tags=["plaid"])


def _client():
    client = get_client()
    if client is None:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "bank connection unavailable: Plaid credentials are not configured",
        )
    return client


class LinkTokenResponse(BaseModel):
    link_token: str
    expiration: str | None = None


@router.post("/link-token", response_model=LinkTokenResponse)
def create_link_token(user_id: uuid.UUID = Depends(require_user)) -> LinkTokenResponse:
    from plaid.model.country_code import CountryCode
    from plaid.model.link_token_create_request import LinkTokenCreateRequest
    from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
    from plaid.model.products import Products

    settings = get_settings()
    payload = {
        "user": LinkTokenCreateRequestUser(client_user_id=str(user_id)),
        "client_name": "MILLI Tax Vault",
        "products": [Products("transactions")],
        "country_codes": [CountryCode("US")],
        "language": "en",
    }
    if settings.plaid_webhook_url:
        payload["webhook"] = settings.plaid_webhook_url
    if settings.plaid_redirect_uri:
        payload["redirect_uri"] = settings.plaid_redirect_uri

    response = _client().link_token_create(LinkTokenCreateRequest(**payload))
    data = response.to_dict()
    expiration = data.get("expiration")
    return LinkTokenResponse(
        link_token=data["link_token"],
        expiration=expiration.isoformat() if hasattr(expiration, "isoformat") else expiration,
    )


class ExchangeRequest(BaseModel):
    public_token: str
    institution_id: str | None = None
    institution_name: str | None = None


class ExchangeResponse(BaseModel):
    item_id: str
    accounts_linked: int


@router.post("/exchange-public-token", response_model=ExchangeResponse)
def exchange_public_token(
    body: ExchangeRequest,
    user_id: uuid.UUID = Depends(require_user),
) -> ExchangeResponse:
    from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest

    client = _client()
    exchange = client.item_public_token_exchange(
        ItemPublicTokenExchangeRequest(public_token=body.public_token)
    ).to_dict()
    access_token = exchange["access_token"]
    item_id = exchange["item_id"]

    settings = get_settings()
    if not settings.db_configured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "cannot persist bank connection: DATABASE_URL is not configured",
        )

    row_id = uuid.uuid4()
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into plaid_items
                    (id, user_id, item_id, access_token, institution_id, institution_name)
                values (%s, %s, %s, %s, %s, %s)
                on conflict (item_id) do update
                    set access_token = excluded.access_token,
                        status = 'active',
                        last_error = null,
                        updated_at = now()
                returning id
                """,
                (
                    row_id,
                    user_id,
                    item_id,
                    access_token,
                    body.institution_id,
                    body.institution_name,
                ),
            )
            plaid_item_uuid = cur.fetchone()[0]
        conn.commit()

    linked = _sync_accounts(client, plaid_item_uuid, user_id, access_token)
    return ExchangeResponse(item_id=item_id, accounts_linked=linked)


def _sync_accounts(client, plaid_item_uuid, user_id, access_token) -> int:
    """Pull accounts + balances from Plaid and cache them with a timestamp."""
    from plaid.model.accounts_balance_get_request import AccountsBalanceGetRequest

    response = client.accounts_balance_get(
        AccountsBalanceGetRequest(access_token=access_token)
    ).to_dict()
    accounts = response.get("accounts", [])
    now = datetime.now(timezone.utc)

    with db.connection() as conn:
        with conn.cursor() as cur:
            for account in accounts:
                balances = account.get("balances") or {}
                cur.execute(
                    """
                    insert into plaid_accounts
                        (id, user_id, plaid_item_id, account_id, name, official_name, mask,
                         type, subtype, available_balance, current_balance,
                         iso_currency_code, balance_as_of)
                    values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    on conflict (account_id) do update
                        set available_balance = excluded.available_balance,
                            current_balance = excluded.current_balance,
                            balance_as_of = excluded.balance_as_of,
                            updated_at = now()
                    """,
                    (
                        uuid.uuid4(),
                        user_id,
                        plaid_item_uuid,
                        account["account_id"],
                        account.get("name"),
                        account.get("official_name"),
                        account.get("mask"),
                        str(account.get("type")) if account.get("type") else None,
                        str(account.get("subtype")) if account.get("subtype") else None,
                        balances.get("available"),
                        balances.get("current"),
                        balances.get("iso_currency_code"),
                        now,
                    ),
                )
            cur.execute(
                "update plaid_items set last_synced_at = %s, updated_at = now() where id = %s",
                (now, plaid_item_uuid),
            )
        conn.commit()
    return len(accounts)


@router.get("/accounts")
def list_accounts(user_id: uuid.UUID = Depends(require_user)) -> dict:
    """Cached account snapshots. `balance_as_of` lets the client label state."""
    if not get_settings().db_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "DATABASE_URL is not configured")
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select a.account_id, a.name, a.mask, a.type, a.subtype,
                       a.available_balance, a.current_balance, a.iso_currency_code,
                       a.balance_as_of, i.institution_name, i.status
                  from plaid_accounts a
                  join plaid_items i on i.id = a.plaid_item_id
                 where a.user_id = %s
                 order by i.institution_name nulls last, a.name
                """,
                (user_id,),
            )
            rows = cur.fetchall()
    accounts = [
        {
            "account_id": r[0],
            "name": r[1],
            "mask": r[2],
            "type": r[3],
            "subtype": r[4],
            "available_balance": float(r[5]) if r[5] is not None else None,
            "current_balance": float(r[6]) if r[6] is not None else None,
            "iso_currency_code": r[7],
            "balance_as_of": r[8].isoformat() if r[8] else None,
            "data_state": "CACHED_LIVE" if r[5] is not None or r[6] is not None else "UNAVAILABLE",
            "institution_name": r[9],
            "item_status": r[10],
        }
        for r in rows
    ]
    return {"accounts": accounts, "count": len(accounts)}


@router.post("/refresh-balances")
def refresh_balances(user_id: uuid.UUID = Depends(require_user)) -> dict:
    """Force a live balance pull for every item owned by this user."""
    client = _client()
    if not get_settings().db_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "DATABASE_URL is not configured")
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select id, access_token from plaid_items where user_id = %s and status = 'active'",
                (user_id,),
            )
            items = cur.fetchall()
    refreshed = 0
    for item_uuid, access_token in items:
        refreshed += _sync_accounts(client, item_uuid, user_id, access_token)
    return {"accounts_refreshed": refreshed, "items": len(items)}


@router.get("/transactions")
def list_transactions(
    user_id: uuid.UUID = Depends(require_user),
    limit: int = 100,
) -> dict:
    if not get_settings().db_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "DATABASE_URL is not configured")
    limit = max(1, min(limit, 500))
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select transaction_id, date, name, merchant_name, amount,
                       iso_currency_code, pending, is_gig_payout, payout_platform
                  from plaid_transactions
                 where user_id = %s
                 order by date desc
                 limit %s
                """,
                (user_id, limit),
            )
            rows = cur.fetchall()
    return {
        "transactions": [
            {
                "transaction_id": r[0],
                "date": r[1].isoformat(),
                "name": r[2],
                "merchant_name": r[3],
                "amount": float(r[4]),
                "iso_currency_code": r[5],
                "pending": r[6],
                "is_gig_payout": r[7],
                "payout_platform": r[8],
            }
            for r in rows
        ],
        "count": len(rows),
    }


@router.post("/sync-transactions")
def sync_transactions(user_id: uuid.UUID = Depends(require_user)) -> dict:
    """Pull transactions with Plaid's /transactions/sync for every active item."""
    from plaid.model.transactions_sync_request import TransactionsSyncRequest

    client = _client()
    if not get_settings().db_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "DATABASE_URL is not configured")

    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "select id, access_token from plaid_items where user_id = %s and status = 'active'",
                (user_id,),
            )
            items = cur.fetchall()

    inserted = 0
    for _item_uuid, access_token in items:
        cursor_value = None
        has_more = True
        while has_more:
            payload = {"access_token": access_token}
            if cursor_value:
                payload["cursor"] = cursor_value
            response = client.transactions_sync(TransactionsSyncRequest(**payload)).to_dict()
            has_more = response.get("has_more", False)
            cursor_value = response.get("next_cursor")
            added = list(response.get("added", [])) + list(response.get("modified", []))
            inserted += _store_transactions(user_id, added)
    return {"transactions_upserted": inserted, "items": len(items)}


def _store_transactions(user_id, transactions) -> int:
    if not transactions:
        return 0
    stored = 0
    with db.connection() as conn:
        with conn.cursor() as cur:
            for txn in transactions:
                cur.execute(
                    "select id from plaid_accounts where account_id = %s and user_id = %s",
                    (txn["account_id"], user_id),
                )
                row = cur.fetchone()
                if row is None:
                    continue  # account not linked to this user: skip, never guess
                cur.execute(
                    """
                    insert into plaid_transactions
                        (id, user_id, plaid_account_id, transaction_id, pending, amount,
                         iso_currency_code, date, authorized_date, name, merchant_name, category)
                    values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    on conflict (transaction_id) do update
                        set pending = excluded.pending,
                            amount = excluded.amount,
                            name = excluded.name,
                            merchant_name = excluded.merchant_name,
                            updated_at = now()
                    """,
                    (
                        uuid.uuid4(),
                        user_id,
                        row[0],
                        txn["transaction_id"],
                        txn.get("pending", False),
                        txn.get("amount"),
                        txn.get("iso_currency_code"),
                        txn.get("date"),
                        txn.get("authorized_date"),
                        txn.get("name"),
                        txn.get("merchant_name"),
                        (txn.get("personal_finance_category") or {}).get("primary"),
                    ),
                )
                stored += 1
        conn.commit()
    return stored


@router.post("/webhook")
async def plaid_webhook(request: Request) -> dict:
    """Plaid webhook receiver.

    Acknowledged with 200 so Plaid does not retry, but nothing is treated as
    authoritative beyond recording the item state. Data is refreshed by the
    sync endpoints against Plaid itself.
    """
    body = await request.json()
    webhook_type = body.get("webhook_type")
    webhook_code = body.get("webhook_code")
    item_id = body.get("item_id")

    if item_id and get_settings().db_configured:
        new_status = None
        if webhook_code in {"PENDING_EXPIRATION", "USER_PERMISSION_REVOKED"}:
            new_status = "revoked" if webhook_code == "USER_PERMISSION_REVOKED" else "login_required"
        elif webhook_code == "ERROR":
            new_status = "error"
        if new_status:
            with db.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        update plaid_items
                           set status = %s,
                               last_error = %s,
                               updated_at = now()
                         where item_id = %s
                        """,
                        (new_status, str(body.get("error")) if body.get("error") else None, item_id),
                    )
                conn.commit()

    return {"received": True, "webhook_type": webhook_type, "webhook_code": webhook_code}
