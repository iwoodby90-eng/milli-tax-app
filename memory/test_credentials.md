# Test Credentials — MILLI

## Demo Account (preferred for QA)
- **Endpoint**: `POST /api/demo/seed` → returns `{token, user}` with seeded Jordan Taylor data
- **Email**: `demo@milli.app`
- **Password**: `milli-demo-2026`
- **Plan**: Elite
- **State**: CA
- **Seeded data**: 40 gig deposits, 28 trips, 18 expenses, $1,364.80 Vault balance, Q1 paid

## Trial Test User
- Email: `driver@taxhaul.app`
- Password: `Driver123!`
- State: CA, Plan: trial

## Auth Endpoints
- POST `/api/auth/register` (body: email, password, name, state)
- POST `/api/auth/login` (body: email, password)
- GET `/api/auth/me` (Authorization: Bearer <token>)
- POST `/api/demo/seed` (no body, returns token)

## Tax Vault Endpoints
- POST `/api/vault/setup`, GET `/api/vault`, PUT `/api/vault/rule`, POST `/api/vault/transfer`

## Quarterly Endpoints
- GET `/api/quarterly`, POST `/api/quarterly/payment`

## Stripe Test
- Test card: 4242 4242 4242 4242, any future expiry, any CVC, any ZIP

## Plaid Sandbox
- Username: `user_good`, Password: `pass_good`
