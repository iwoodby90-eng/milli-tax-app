# Milli Secure Storage Policy

## Keychain-only data

The following values must never be written to Local Storage, Session Storage, Capacitor Preferences, logs, analytics, or crash metadata:

- access and refresh tokens
- passwords and password-reset secrets
- bank-link credentials or processor tokens
- StoreKit receipts and signed transaction payloads
- personally identifying tax documents
- API secrets or private keys

Use an iOS Keychain-backed storage implementation with an accessibility level appropriate for the feature. Authentication tokens should normally be unavailable before first device unlock and should be removed on explicit logout.

## Preferences-only data

Capacitor Preferences may store non-secret user experience settings such as:

- whether the intro has been seen
- selected appearance and accessibility preferences
- non-authoritative draft plan choice
- dismissed education cards

Preferences must never determine billing entitlement, authentication, tax balances, or account authorization.

## Server authority

The backend is authoritative for:

- identity and session validity
- subscription entitlement
- transaction verification
- financial balances and ledger entries
- tax calculations and filed/payment status

Client state may improve responsiveness but must be reconciled against the server before protected functionality is unlocked.
