# Native Plaid onboarding smoke test

Branch: `fix/native-plaid-onboarding`

## Expected path

1. Sign in / create an account and reach setup step **BANK + PAYOUT DETECTION**.
2. Tap **Connect Bank Securely**.
3. Milli asks the Render backend for `POST /plaid/link-token`.
4. Native Plaid LinkKit opens.
5. Complete a Plaid Sandbox institution flow.
6. LinkKit returns the one-time `public_token` to Milli.
7. Milli sends it to Render at `POST /plaid/exchange-public-token`.
8. Milli fetches `GET /plaid/accounts` and marks the account **CONNECTED** only after Render confirms a cached Plaid account.
9. Enable the two Autopilot permissions and continue setup.

## Runtime configuration

The client prefers the Xcode scheme environment variable `MILLI_API_BASE_URL`. If omitted during migration testing it probes the two Render hostnames represented by Milli's repo history and accepts the first `/health` endpoint returning 2xx.

If Render has `CLIENT_API_KEY` configured, set the same value locally as the Xcode scheme environment variable `MILLI_CLIENT_API_KEY`. Do not commit the key.

Plaid `client_id`, `secret`, Item access tokens, and transaction credentials remain server-side on Render.

## Known release-auth follow-up

The current backend scopes Plaid data using a UUID request header plus an optional client key. The iOS repair deterministically namespaces the signed-in Apple subject into that UUID so sandbox data is stable. Before production financial data is enabled, replace this with a backend-issued session after server-side verification of the Sign in with Apple identity token. A client-supplied UUID is an identifier, not proof of identity.
