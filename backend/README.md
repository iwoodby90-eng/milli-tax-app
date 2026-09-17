# MILLI Tax Vault API

FastAPI backend for the MILLITaxVault iOS app. Six modules:

1. **Bank connections via Plaid** — Link token creation, public-token exchange, account/balance snapshots, transaction sync, webhooks.
2. **Milli Tax Vault reserve ledger** — An append-only, auditable ledger. The vault balance is always *derived* by summing settled entries; no column stores a convenience balance that could drift.
3. **Column BaaS** — Account creation, card issuing, ACH transfers. Transfer state machine: `pending → processing → settled | failed | reversed`. The `settled` state is only reachable via Column webhook, never from a direct client POST (same pattern as the tax_vault fix, issue #103).
4. **Apple IAP** — Server-side StoreKit 2 transaction verification. The iOS app sends the signed JWS; the server decodes and verifies it. Apple Server Notification V2 webhook handles subscription lifecycle (renewal, expiration, refund, revoke).
5. **Apple Identity** — Wallet API identity verification + Column KYC fallback. Apple Wallet is available in ~16 US states; Column KYC covers the rest.
6. **Audit logging** — Every financial operation writes an append-only audit row with a unique `audit_id` that surfaces in the user's Financial Receipt.

## Data-truth rules baked into the API

- No endpoint ever invents a balance. Missing database or missing Plaid credentials returns **503** with a plain reason, not a plausible number.
- Balances pulled from Plaid are returned with `balance_as_of` and a `data_state` of `CACHED_LIVE` or `UNAVAILABLE`, so the app can label them.
- A new ledger entry defaults to `requested`. It is **not** counted as settled money. Only `POST /tax-vault/entries/{id}/status` can mark it `settled`.
- A new Column transfer defaults to `pending`. Only `POST /column/transfers/status` (webhook-driven) can mark it `settled`.
- No full account numbers or card PANs are stored. Only last-four and Column object IDs.
- All money is in signed cents (bigint). No floating-point.

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Liveness probe (Render health check) |
| GET | `/ready` | Dependency truth: database + Plaid config |
| POST | `/plaid/link-token` | Create a Plaid Link token |
| POST | `/plaid/exchange-public-token` | Store the item, sync accounts |
| GET | `/plaid/accounts` | Cached accounts + balances with `balance_as_of` |
| POST | `/plaid/refresh-balances` | Force a live balance pull |
| GET | `/plaid/transactions` | Stored transactions |
| POST | `/plaid/sync-transactions` | Pull via `/transactions/sync` |
| POST | `/plaid/webhook` | Plaid webhook receiver |
| GET | `/tax-vault/balance` | Derived settled + pending reserve |
| POST | `/tax-vault/entries` | Record a reserve movement |
| GET | `/tax-vault/entries` | Auditable ledger history |
| POST | `/tax-vault/entries/{id}/status` | Authoritative state transition |
| GET/PUT | `/tax-vault/settings` | Autopilot reserve rate |
| POST | `/column/accounts` | Create a Column deposit account |
| GET | `/column/accounts/{user_id}` | List user's Column accounts |
| POST | `/column/cards` | Issue a debit card |
| POST | `/column/cards/{card_id}/freeze` | Freeze a card |
| POST | `/column/transfers` | Create an ACH transfer (starts `pending`) |
| POST | `/column/transfers/status` | Webhook-driven status update (only path to `settled`) |
| GET | `/column/transfers/{user_id}` | List user's transfers |
| POST | `/iap/verify` | Verify a StoreKit 2 transaction |
| GET | `/iap/transactions/{user_id}` | List verified IAP transactions |
| POST | `/iap/webhook` | Apple Server Notification V2 webhook |
| POST | `/identity/apple-wallet` | Verify Apple Wallet identity payload |
| POST | `/identity/column-kyc` | Record Column KYC completion |
| GET | `/identity/{user_id}` | List identity verifications |

## Auth

The iOS client sends:

- `X-Milli-Client-Key` — shared key, matched against `CLIENT_API_KEY`.
- `X-Milli-User-Id` — the authenticated user's UUID.

Every query is scoped to that user id server-side. The client cannot read or write another user's rows.

## Local run

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in values
uvicorn app.main:app --reload
```

## Migrations

Apply in order against your Postgres instance:

```bash
psql "$DATABASE_URL" -f migrations/001_create_mileage_ledger_logs.sql
psql "$DATABASE_URL" -f migrations/002_create_brokerage_trading.sql
psql "$DATABASE_URL" -f migrations/003_create_plaid_and_tax_vault.sql
psql "$DATABASE_URL" -f migrations/004_create_column_iap_identity_audit.sql
```

## Deploy (Render)

`render.yaml` at the repository root defines the service: root dir `backend`, health check `/health`. Set these as environment variables in the Render dashboard (never in the repo):

`DATABASE_URL`, `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`, `PLAID_WEBHOOK_URL`, `PLAID_REDIRECT_URI`, `CLIENT_API_KEY`, `COLUMN_API_KEY`, `COLUMN_BASE_URL`, `COLUMN_WEBHOOK_SECRET`, `APPLE_IAP_BUNDLE_ID`, `APPLE_IAP_ENVIRONMENT`, `APPLE_IAP_ISSUER_ID`, `APPLE_IAP_KEY_ID`, `APPLE_IAP_PRIVATE_KEY`, `APPLE_IDENTITY_MERCHANT_ID`, `APPLE_IDENTITY_PRIVATE_KEY`, `RATE_LIMIT_PER_MINUTE`, `AUDIT_RETENTION_DAYS`.

Start with `PLAID_ENV=sandbox` and the sandbox key pair, verify the Link flow end to end, then switch to the production pair.

## Tests

```bash
cd backend && python -m pytest tests -q
```

61 tests covering: tax vault state machine, Column BaaS state machine and validation, Apple IAP JWS decode and verification, Apple Identity claim extraction, configuration guards (503 when deps missing), and API health/readiness.