# Current Render Plaid routes

The native iOS client targets the current FastAPI contract with no legacy `/api` prefix:

- `POST /plaid/link-token`
- `POST /plaid/exchange-public-token`
- `GET /plaid/accounts`
- `POST /plaid/refresh-balances`

The historical Swift client used an `/api/...` prefix and is not reused by this repair.
