# MILLI Tax Vault API

FastAPI backend for the MilliTaxVault iOS app. Two responsibilities:

1. **Bank connections via Plaid** — Link token creation, public-token exchange,
   account/balance snapshots, transaction sync, webhooks.
2. **Milli Tax Vault reserve ledger** — an append-only, auditable ledger. The
   vault balance is always *derived* by summing settled entries; no column
   stores a convenience balance that could drift.

## Data-truth rules baked into the API

- No endpoint ever invents a balance. Missing database or missing Plaid
  credentials returns **503** with a plain reason, not a plausible number.
- Balances pulled from Plaid are returned with `balance_as_of` and a
  `data_state` of `CACHED_LIVE` or `UNAVAILABLE`, so the app can label them.
- A new ledger entry defaults to `requested`. It is **not** counted as settled
  money. Only `POST /tax-vault/entries/{id}/status` can mark it `settled`.
- Plaid access tokens live only in the backend database. They are never
  returned to the iOS client.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
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

## Auth

The iOS client sends:

- `X-Milli-Client-Key` — shared key, matched against `CLIENT_API_KEY`.
- `X-Milli-User-Id` — the authenticated user's UUID.

Every query is scoped to that user id server-side. The client cannot read or
write another user's rows.

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
psql "$DATABASE_URL" -f migrations/001_create_mileage_logs.sql
psql "$DATABASE_URL" -f migrations/002_create_brokerage_trading.sql
psql "$DATABASE_URL" -f migrations/003_create_plaid_and_tax_vault.sql
```

## Deploy (Render)

`render.yaml` at the repository root defines the service: root dir `backend`,
health check `/health`. Set these as environment variables in the Render
dashboard (never in the repo):

`DATABASE_URL`, `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`,
`PLAID_WEBHOOK_URL`, `CLIENT_API_KEY`.

Start with `PLAID_ENV=sandbox` and the sandbox key pair, verify the Link flow
end to end, then switch to the production pair.

## Tests

```bash
cd backend && python -m pytest tests -q
```
