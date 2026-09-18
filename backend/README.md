# MILLI Tax Vault API

FastAPI backend for the native Milli iOS app. The backend is the authority for
identity, bank connections, reserve-ledger truth, and provider-confirmed
financial state. The mobile app is an untrusted client and never chooses its own
user identity or financial settlement state.

## Security and data-truth rules

- **Server-verified identity:** Sign in with Apple begins with a one-time backend
  nonce challenge. The backend verifies the signed Apple identity token, issuer,
  audience, expiry, subject, and nonce before minting a Milli session.
- **Opaque rotating sessions:** short-lived access tokens and rotating refresh
  tokens are random opaque values. Only SHA-256 token digests are stored in
  Postgres; logout revokes the server session.
- **No embedded mobile shared secret:** legacy `X-Milli-Client-Key` and
  `X-Milli-User-Id` headers do not authorize user financial data.
- **Per-user row isolation:** user identity is derived from the authenticated
  server session and every user-scoped query is constrained by that server
  identity.
- **No invented financial truth:** unavailable database/provider state returns
  an explicit error or `UNAVAILABLE`; the API does not synthesize a plausible
  balance.
- **Provider secrets stay server-side:** Plaid access tokens are persisted only
  by the backend and are never returned to the iOS client.
- **Signed Plaid webhooks:** `Plaid-Verification` ES256 signatures, request-body
  hashes, and freshness are verified before a webhook is accepted.
- **Reserve movements fail safe:** new Tax Vault ledger entries are
  `requested`. The mobile client cannot mark them `settled`; settlement must
  come from authoritative backend/provider reconciliation.
- **Production API surface is reduced:** FastAPI docs/OpenAPI endpoints are
  disabled in production and responses are non-cacheable with security headers.

## Authentication flow

1. iOS requests `POST /auth/apple/challenge`.
2. The returned nonce is attached to the native Sign in with Apple request.
3. iOS sends the signed Apple identity token and challenge id to
   `POST /auth/apple/exchange`.
4. The backend validates Apple cryptography and the one-time nonce, creates or
   resolves the Milli user, consumes the challenge, and returns an opaque
   access/refresh session.
5. User-scoped requests use `Authorization: Bearer <access-token>`.
6. `POST /auth/refresh` rotates both session tokens. Reusing an old refresh
   token fails. `POST /auth/logout` revokes the session.

## Core endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness probe |
| GET | `/ready` | Dependency truth without leaking secrets |
| POST | `/auth/apple/challenge` | Create one-time Apple nonce challenge |
| POST | `/auth/apple/exchange` | Verify Apple identity and mint Milli session |
| POST | `/auth/refresh` | Rotate refresh/access tokens |
| POST | `/auth/logout` | Revoke the authenticated session |
| POST | `/plaid/link-token` | Create a Plaid Link token for authenticated user |
| POST | `/plaid/exchange-public-token` | Persist Plaid item server-side |
| GET | `/plaid/accounts` | Cached accounts/balances with provenance timestamp |
| POST | `/plaid/refresh-balances` | Refresh authenticated user's balances |
| GET | `/plaid/transactions` | User-scoped stored transactions |
| POST | `/plaid/sync-transactions` | Sync transactions for the authenticated user |
| POST | `/plaid/webhook` | Cryptographically verified Plaid webhook receiver |
| GET | `/tax-vault/balance` | Derived settled/pending reserve |
| POST | `/tax-vault/entries` | Record a requested reserve movement |
| GET | `/tax-vault/entries` | Auditable user-scoped ledger history |
| GET/PUT | `/tax-vault/settings` | Authenticated Autopilot reserve settings |

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
```

## Deploy (Render)

`render.yaml` defines the service. Real secret values belong only in Render
environment variables / secret storage, never in source control.

Required authenticated-finance configuration includes:

`DATABASE_URL`, `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`,
`PLAID_WEBHOOK_URL`, and `APPLE_SIGN_IN_AUDIENCE`.

Keep provider environments aligned (sandbox with sandbox, production with
production). Production readiness must remain false when required identity,
database, or provider configuration is missing.

## Tests

```bash
cd backend && python -m pytest tests -q
```

The PostgreSQL integration suite covers one-time auth challenges, server bearer
authorization, refresh-token rotation/replay rejection, logout revocation,
legacy-header rejection, and Tax Vault user isolation.
