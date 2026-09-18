# MILLI Tax Vault API

FastAPI backend for the native Milli iOS app. The backend is the authority for
identity, bank connections, reserve-ledger truth, and provider-confirmed money
movement. The mobile app is an untrusted client and never chooses its own user
identity or provider settlement state.

## Security and data-truth rules

- **Server-verified identity:** Sign in with Apple begins with a one-time backend
  nonce challenge. The backend verifies the signed Apple token before minting a
  Milli session.
- **Opaque rotating sessions:** short-lived access tokens and rotating refresh
  tokens are random opaque values. Only SHA-256 token digests are stored.
- **No embedded financial secret:** Unit organization API credentials and Plaid
  secrets remain server-side; legacy mobile shared-key headers do not establish
  user identity.
- **Signed provider webhooks:** Plaid uses its signed JWT webhook verification;
  Unit uses the configured `X-Unit-Signature` HMAC over the raw request body.
  Bodies are authenticated before JSON parsing.
- **Provider event deduplication:** Unit webhook event ids are persisted once,
  preventing duplicate delivery from applying a financial transition twice.
- **Idempotent Unit payment primitive:** server-side Unit payment creation
  requires a stable UUID idempotency key. The app does not yet expose a public
  transfer endpoint; the security rail is established first.
- **ACH debit authorization records:** debit movements require a recorded
  authorization reference and the schema enforces retention of authorization
  records for at least two years.
- **Provider-owned lifecycle truth:** Unit webhook events can update provider
  payment status. The mobile client cannot mark a payment sent/settled.
- **No invented balances:** unavailable database/provider state is reported as
  unavailable instead of replaced by plausible demo numbers.

## Authentication flow

1. iOS requests `POST /auth/apple/challenge`.
2. The returned nonce is attached to the native Sign in with Apple request.
3. iOS sends the signed Apple identity token and challenge id to
   `POST /auth/apple/exchange`.
4. The backend validates Apple cryptography and the one-time nonce, resolves the
   user, consumes the challenge, and returns an opaque access/refresh session.
5. User-scoped requests use `Authorization: Bearer <access-token>`.
6. `POST /auth/refresh` rotates both session tokens and
   `POST /auth/logout` revokes the session.

## Core endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness probe |
| GET | `/ready` | Database + Apple + Plaid + Unit configuration truth |
| POST | `/auth/apple/challenge` | Create one-time Apple nonce challenge |
| POST | `/auth/apple/exchange` | Verify Apple identity and mint Milli session |
| POST | `/auth/refresh` | Rotate refresh/access tokens |
| POST | `/auth/logout` | Revoke authenticated session |
| POST | `/plaid/link-token` | Create Plaid Link token |
| POST | `/plaid/exchange-public-token` | Persist Plaid item server-side |
| GET | `/plaid/accounts` | User-scoped cached accounts/balances |
| POST | `/plaid/refresh-balances` | Refresh authenticated user balances |
| GET | `/plaid/transactions` | User-scoped stored transactions |
| POST | `/plaid/sync-transactions` | Sync authenticated user transactions |
| POST | `/plaid/webhook` | Cryptographically verified Plaid webhook |
| POST | `/unit/webhook` | HMAC-verified, deduplicated Unit provider events |
| GET | `/tax-vault/balance` | Derived settled/pending reserve |
| POST | `/tax-vault/entries` | Record a requested reserve movement |
| GET | `/tax-vault/entries` | Auditable user-scoped ledger |
| GET/PUT | `/tax-vault/settings` | Authenticated Autopilot reserve settings |

There is intentionally **no public Unit transfer endpoint yet**. Money movement
will only be exposed after user-to-Unit account ownership, consent, limits,
step-up authentication, and provider reconciliation are wired and tested.

## Local run

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
```

## Migrations

Apply in order against Postgres:

```bash
psql "$DATABASE_URL" -f migrations/001_create_mileage_logs.sql
psql "$DATABASE_URL" -f migrations/002_create_brokerage_trading.sql
psql "$DATABASE_URL" -f migrations/003_create_plaid_and_tax_vault.sql
psql "$DATABASE_URL" -f migrations/004_create_server_auth.sql
psql "$DATABASE_URL" -f migrations/005_create_unit_money_movement.sql
```

## Deploy (Render)

Real secret values belong only in Render environment variables / secret storage,
never source control. Required authenticated-finance configuration includes:

`DATABASE_URL`, `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`,
`PLAID_WEBHOOK_URL`, `APPLE_SIGN_IN_AUDIENCE`, `UNIT_API_TOKEN`,
`UNIT_BASE_URL`, and `UNIT_WEBHOOK_SECRET`.

Keep all provider environments aligned. Sandbox must use sandbox credentials and
sandbox provider URLs; production must use production credentials and URLs.
Readiness remains false when a required financial dependency is absent.

## Unit production security posture

The Unit organization API token is never embedded in iOS. Use the narrowest Unit
scopes required for each server capability. Customer-sensitive fund-movement
flows should use Unit customer tokens / step-up verification where applicable,
and linked-account/counterparty-specific payment scopes instead of broad payment
write authority. Every sensitive operation must carry a stable idempotency key.

ACH debits require authenticated external-account ownership plus explicit user
authorization. Authorization records must be retained according to network and
provider requirements. Provider webhook events—not UI callbacks—advance
financial lifecycle truth.

## Tests

```bash
cd backend && python -m pytest tests -q
```

The PostgreSQL integration suite covers one-time auth challenges, bearer-session
authorization, refresh-token rotation/replay rejection, logout revocation,
legacy-header rejection, Tax Vault row isolation, Unit webhook authenticity,
Unit webhook deduplication, and Unit provider-owned state transitions.
