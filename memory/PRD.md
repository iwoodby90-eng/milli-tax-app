# MILLI — Tax Autopilot for Gig Workers

## Positioning
**Tax Autopilot for Gig Workers** — _Earn freely. Milli handles the tax side._

## Target Users
Uber, Lyft, DoorDash, Instacart, Spark, Grubhub, Amazon Flex drivers · freelancers · independent contractors · creators · consultants · home-service pros · anyone with 1099 income.

## Brand
- Glossy Black `#050607`, Milli Turquoise `#13D8D1`, Deep Teal `#087F82`, Polished Silver `#D9E0E4`, Alpine White `#F7F9FA`, Supporting Gray `#8B949B`. Status: success `#39D98A`, warning `#FFB547`, critical `#FF5C67`.
- Typography: Manrope / Inter (no display fonts), tabular numerals.
- Chrome M monogram logo with turquoise road accent.
- Premium glass cards `rounded-2xl` on carbon-fibre obsidian background.

## Implemented (2026-02)
### Backend (FastAPI, MongoDB)
- Auth: email + password JWT, configurable state on signup
- Plaid: link-token, exchange, sync, items list/remove
- Income: auto-detected gig deposits + manual entry with auto-reserve to Vault
- Mileage: live GPS tracking (Haversine), manual entry, list, delete
- Expenses: CRUD + AI receipt OCR (Gemini 3 Flash)
- AI tax assistant chat (SSE streaming)
- Tax summary: SE 15.3% + federal + state + quarterly estimate
- **Tax Vault** (`/api/vault/...`): setup, balance, rules (mode/strategy/percentage/min-balance/max-daily/pause), in/out transfers, transfer history
- **Quarterly Tax Center** (`/api/quarterly/...`): 4-quarter overview with reserved + readiness, record outside payment
- Reports: Schedule C + SE worksheet PDF, mileage CSV
- Stripe checkout (3 tiers via emergentintegrations) + webhook + polling
- **Demo Mode** (`POST /api/demo/seed`): one-click Jordan Taylor demo user with 40 deposits, 28 trips, 18 expenses, vault balance, Q1 paid payment record

### Frontend (React, Tailwind, Phosphor icons)
- Landing page (rebranded, demo CTA, turquoise theme)
- Login, Register, Billing success polling
- Dashboard with Quarterly Payment hero, Tax Ready Score circular ring, Quarterly Checklist, Federal+State Filing Elite card, KPI grid
- Income (Plaid Link, manual deposits, ledger)
- Mileage (live GPS tracker, manual trip, history)
- Expenses (manual + AI receipt OCR)
- AI Assistant (streaming chat)
- Reports (PDF/CSV download)
- Pricing (3 tiers + 3-day trial)
- Settings (profile, state, filing status)
- **Tax Vault** (new): balance card, account details, auto-reserve rules dialog, transfer history
- **Quarterly Tax Center** (new): 4-quarter timeline with status rings + record payment dialog
- **More** menu (new): Quarterly · Reports · AI · Plans · Settings + "coming soon" placeholders
- 5-tab mobile bottom nav: **Home · Income · Mileage · Vault · More**

## MOCKED / Important Notes
- **Tax Vault** is a mocked banking account (no real partner). Account/routing numbers are randomly generated; balance is tracked in MongoDB. Real production requires a Banking-as-a-Service partner (Stripe Treasury, Unit, Synapse, Treasury Prime).
- **Stripe** uses emergentintegrations one-time checkout (grants 30 days of access). Native recurring subscriptions + customer portal not yet supported.
- **Schedule C PDF** is a worksheet, not an official fillable IRS form. Tax filing requires a licensed e-file partner (TurboTax/TaxAct API).
- **State tax** uses flat top-bracket estimates for informational purposes only.
- **Plaid Transfer** for real bank-to-Vault movement requires production approval.

## Deferred to Backlog
- **Multi-step onboarding flow** (8 screens — currently using single-step register)
- **Recurring categorization rules** UI
- **Tax Documents center** (1099-NEC/K/MISC, W-2 upload)
- **Accountant Collaboration** (invite with permissions)
- **Referral Program** (give $20 / get $20)
- **Security Center** (MFA, sessions, device management, login history)
- **Admin Dashboard** (user mgmt, fraud alerts, content, audit logs)
- **Push/email/SMS notifications system**
- **Multi-vehicle management**
- **Receipt scanning** with line-item extraction
- **Safe to Spend** calculator on dashboard
- **Monthly Cash Flow chart** on dashboard
- **App icon & splash screen** assets (currently SVG logo only)

## Test Accounts
- **Demo Mode**: `POST /api/demo/seed` returns Jordan Taylor (email `demo@milli.app`, plan Elite) with full seeded data. Landing page "Try the demo" button auto-logs in.
- **Trial test user**: `driver@taxhaul.app` / `Driver123!` (state CA, trial plan)
- Plaid sandbox: `user_good` / `pass_good`
- Stripe test card: `4242 4242 4242 4242`
