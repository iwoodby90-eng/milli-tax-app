# Milli API & Production Integration Checklist

This document separates credentials the current code can use today from providers that still require implementation, contracts, compliance review, or production approval.

## 1. Core production configuration

These are required before any public deployment.

| Configuration | Environment variable(s) | Status |
|---|---|---|
| MongoDB | `MONGO_URL`, `DB_NAME` | Implemented in `backend/server.py` |
| JWT signing | `JWT_SECRET` | Implemented; use at least 32 random bytes |
| Runtime mode | `APP_ENV=production` | Enables production-only security rules |
| Public API URL | `REACT_APP_API_URL` | Implemented in frontend services |
| Allowed origins | `CORS_ORIGINS` | Implemented; wildcard origins are rejected in production |
| Demo controls | `DEMO_MODE_ENABLED=false`, `DEMO_SEED_SECRET` | Demo seeding is disabled by default and forbidden in production |

## 2. Integrations already represented in the code

### Plaid — bank connections and payout transaction sync

Required:

- `PLAID_CLIENT_ID`
- `PLAID_SECRET`
- `PLAID_ENV` (`sandbox` first, then `production`)
- `PLAID_WEBHOOK_URL`

Current state: Link-token creation, public-token exchange, item storage, transaction sync, and gig-deposit classification exist in `backend/server.py`. Missing credentials now return a controlled “not configured” response instead of crashing startup. Production access, encrypted token storage, and a public HTTPS webhook remain required.

### Stripe — subscriptions and checkout

Required:

- `STRIPE_API_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

Current state: Subscription checkout and signed webhook handling use Stripe's public SDK through a repository-owned adapter. The two API-key variables currently refer to the same Stripe secret key because separate modules use different variable names; they should be consolidated later.

### Stripe Issuing — physical Milli card

Required after Stripe approves Issuing access:

- `STRIPE_SECRET_KEY`
- `STRIPE_CARD_WEBHOOK_SECRET`

Current state: Card-order modules exist, but they were written for the legacy PostgreSQL data layer and are **not production-ready with the current MongoDB backend**. Do not expose card-order routes until the storage layer is rewritten and KYC, issuing, and compliance requirements are approved.

### Milli AI and voice

Required:

- `GEMINI_API_KEY`
- `GEMINI_MODEL` (optional model override)
- `OPENAI_API_KEY` for speech generation

Current state: The private, non-installable Emergent package was replaced with repository-owned adapters that call Gemini streaming and OpenAI speech APIs directly. `EMERGENT_LLM_KEY=not-configured` remains only as a temporary legacy compatibility variable and is not the production provider credential.

### Apple Push Notification service

Required:

- `APNS_TEAM_ID`
- `APNS_KEY_ID`
- `APNS_KEY_P8`
- `APNS_BUNDLE_ID=app.milli.tax`
- `APNS_ENV=sandbox` during development

Current state: Token-based APNs delivery and device registration routes exist. The `.p8` key contents belong in the secret manager, never in GitHub.

### Apple StoreKit server verification

Required:

- `APPLE_ISSUER_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY`
- `APPLE_IAP_ENVIRONMENT=Sandbox` during development
- `ALLOW_UNVERIFIED_STOREKIT=false`

Current state: Individual transaction lookup against Apple's server API exists. Unverified purchase fallback is disabled unless explicitly enabled in a non-production environment. Production App Store Server Notifications are deliberately rejected until Apple's signed JWS certificate chain is fully verified; this prevents spoofed subscription upgrades.

### TaxBandits — TIN matching and 1099 workflows

Required:

- `TAXBANDITS_CLIENT_ID`
- `TAXBANDITS_CLIENT_SECRET`
- `TAXBANDITS_USER_TOKEN`

Current state: Sandbox authentication and TIN matching exist. TaxBandits is **not** the app's Form 1040 / Schedule C e-file provider.

## 3. Providers that still require a product decision and implementation

These cannot be completed by merely pasting an API key.

| Capability | Provider direction | Current reality |
|---|---|---|
| Tax Vault custody / real money movement | Unit, Increase, or Stripe Treasury through an eligible platform program | Current Tax Vault is an internal ledger; no custodial bank account is created yet |
| ACH tax payments | Modern Treasury or banking partner plus approved tax-payment workflow | Current production payment submitter is a placeholder |
| Form 1040 / Schedule C e-file | Column Tax or another approved individual-tax filing partner | Current code prepares reports/PDFs but does not provide approved full individual e-file |
| Brokerage investing | Alpaca or another regulated brokerage partner | UI and internal ledger concepts exist; real brokerage onboarding and compliance are not complete |
| Solo 401(k) / IRA custody | Carry, Vestwell, or another retirement custodian | Projections and internal contribution records exist; regulated custody is not complete |
| Identity verification | Persona or Stripe Identity | Credentials are documented, but the active Mongo backend still needs a complete production KYC flow |
| Receipt OCR | Gemini vision or Google Cloud Vision | Gemini image parsing is represented; production credential, retention, and secure storage rules must be finalized |
| Apple subscription webhooks | Apple JWS verification using the published certificate chain | Production webhook processing is safely blocked until verification is implemented |

## 4. Recommended credential order

1. MongoDB production connection, `APP_ENV=production`, restricted CORS, and a strong JWT secret.
2. Plaid Sandbox credentials.
3. Stripe test secret and signed webhook secret.
4. Apple APNs and StoreKit server credentials.
5. Gemini and OpenAI provider keys.
6. TaxBandits sandbox credentials.
7. Choose the banking, tax-payment, e-file, brokerage, retirement, and KYC partners before pursuing their production credentials.

## 5. Secret-handling rules

- Store production secrets in the deployment platform's encrypted secret manager.
- Never commit `.env`, `.p8`, service-account JSON, private keys, access tokens, or webhook secrets.
- Use separate sandbox/test and production credentials.
- Rotate any secret immediately if it appears in a commit, screenshot, support ticket, or chat log.
- Encrypt Plaid access tokens and other provider credentials at rest with a managed KMS before launch.
- Restrict CORS, webhook origins, provider permissions, and callback domains before launch.
