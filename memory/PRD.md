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

## Implemented (2026-07 · Multi-Platform + Legal Site)
### Marketing site — LIVE
- `/app/marketing_site/` — 3 pages (index / privacy / terms) + style.css + vercel.json + README
- Big City Futuristic aesthetic — charcoal checker, neon cyan, glassmorphism
- 3 core value props: **Automatic Tax Slicing · Real-time Mileage Tracking · Wealth Builder** with SVG illustrations
- Full 3-step "How it works" (Connect → Drive → Relax)
- Pricing tiers (Basic $19.99 / Pro $29.99 / Elite $49.99) with "Most Popular" flag on Pro
- **Privacy Policy** — CCPA/CPRA + GDPR/UK GDPR sections, third-party disclosure table (Plaid, Apple, Stripe, OpenAI/Gemini, MongoDB), 30-day deletion
- **Terms** — Michigan governing law, subscription/auto-renewal disclosures, "not a bank/CPA" disclaimer, $100 liability cap
- **Live via pod FastAPI static mount** — served at:
  - `https://<preview>/api/site/index.html`
  - `https://<preview>/api/site/privacy.html`
  - `https://<preview>/api/site/terms.html`
  - Clean redirects `/api/privacy` and `/api/terms`
- Ready to deploy verbatim to milli.tax via `npx vercel --prod` (config included)

### iPad support
- `TARGETED_DEVICE_FAMILY = "1,2"` in project.pbxproj (iPhone + iPad both)
- Big City Futuristic CSS is already responsive; grid layouts scale automatically

### Apple Watch (MilliWatch)
- `/app/frontend/ios/MilliWatch/` — SwiftUI watchOS 10+ companion app
- Files: `MilliWatchApp.swift`, `ContentView.swift` (3-tab UI: Live Trip / Tax Ready / Autopilot), `WatchSession.swift` (WatchConnectivity), `TripState.swift`, `TaxReadyComplication.swift` (circular/inline/corner WidgetKit families)
- Bundle ID: `app.milli.tax.watchkitapp`, companion of `app.milli.tax`
- Info.plist configured for `WKApplication=true`, `WKCompanionAppBundleIdentifier=app.milli.tax`
- 15 watch icon sizes + 1024×1024 marketing master generated with cyan floor glow
- `README_XCODE_SETUP.md` walks the owner through the 5-min Xcode target wizard (Xcode owns target creation via UUIDs in pbxproj)

## Implemented (2026-07 · iOS Build Prep for App Store)
- **Capacitor v7 synced**: `yarn build && npx cap sync ios` — 5 plugins wired (background-geolocation, app, preferences, splash-screen, status-bar). 5.8 MB web bundle copied into iOS.
- **Full AppIcon set**: 16 icon sizes + 1024×1024 master, generated from Milli mark artwork with cyan floor glow. Contents.json manifest validated.
- **LaunchScreen.storyboard**: dark noir + centered AppIcon image (`#050607`), matches Big City Futuristic aesthetic
- **Info.plist**: `CFBundleDisplayName=Milli`, `UIUserInterfaceStyle=Dark`, `ITSAppUsesNonExemptEncryption=false`, all 4 location/motion strings, `UIBackgroundModes: location, fetch, processing`
- **project.pbxproj**: iOS 16.0 minimum, v1.0.0 build 1, auto-signing, bundle `app.milli.tax`
- **`/app/APP_STORE_METADATA.md`**: 7.5 KB — copy-paste ready description (≤4000 char), keywords, subtitle, promo text, review notes, data-collection matrix, demo credentials
- **`/app/IOS_BUILD_GUIDE.md`**: 6.8 KB — step-by-step from clone → Xcode signing → Archive → App Store Connect upload
- **All artifacts validated**: plist parses, storyboard parses, all 16 icon files present, Podfile references all plugins, web build present in `/app/frontend/ios/App/App/public`

## Implemented (2026-07 · Phase 2 — Financial Engine)
### Tax Engine (`/app/backend/tax_engine.py`)
- Pure-math module — swap-in ready behind the `TaxCalculator` integration interface
- 2025 IRS reference: federal marginal brackets × 5 filing statuses, SE tax with SS wage-base cap ($168,600), additional Medicare tax with per-status thresholds, QBI §199A 20% deduction, standard deduction, all US state effective rates (9 no-tax states supported)
- Public helpers: `calc_total_tax()`, `quarterly_plan()`, `mileage_deduction()` (2025 rates: $0.70 biz / $0.21 medical / $0.14 charity), `per_payout_reserve_rate()` (cold-start + projected-annual modes), `profile_from_user()`, `TaxProfile` dataclass

### Autopilot upgrades (`/app/backend/autopilot.py`)
- Now delegates all tax math to Tax Engine (projected-annual per-payout rate w/ YTD hint)
- Feature-gates retirement + investing steps to Pro/Elite plans (Basic gets tax+savings only)
- Writes an in-app notification for every receipt (kind=`autopilot_receipt`)
- Quarterly projection uses full Tax Engine plan (not flat rate)

### Integration Interfaces (`/app/backend/integrations.py`)
- Protocol abstractions: `AccountAggregator`, `MoneyMover`, `TaxCalculator`, `TaxPaymentSubmitter`, `TaxFiler`, `Brokerage`, `RetirementCustodian`, `GpsProvider`, `OcrProvider`, `Notifier`
- Concrete impls (all internal ledger): `InternalLedgerBank`, `InternalTaxCalculator`, `NullTaxPayer` (returns pending_partner), `NullTaxFiler`, `InAppNotifier` — real ACH/e-file partners drop in later without app rewrite
- `IntegrationRegistry` bundles providers for server.py

### New endpoints
- `GET/PUT /api/tax/profile` — filing status, business type, states, dependents, additional income/withholding, QBI opt-in
- `PUT /api/trips/{id}/classify` — one of business|personal|medical|charitable|commuting|needs_review, recomputes deduction with proper 2025 rate
- `GET /api/trips/needs-review` — surfaces unclassified trips for review-queue UI
- `GET /api/mileage/summary` — Tax-Engine-backed deduction totals + per-category breakdown
- `GET|POST|DELETE /api/vehicles` — vehicle management for mileage logs
- `GET /api/plan/features` — surfaces the current plan's feature matrix (core / pro / elite)
- `GET /api/notifications` + `POST /api/notifications/{id}/read`
- `GET /api/ai/insights` — deterministic proactive insights (autopilot recap, unclassified-trips action, quarterly readiness good/warn, profile-incomplete info)

### Subscription gating
- `FEATURE_MATRIX` + `PLAN_INCLUDES` + `require_feature()` FastAPI dependency
- Retirement + Investing setup endpoints reject `basic` plans with HTTP 402 `plan_upgrade_required`
- Trial users get everything for 3 days (per user spec)

### Tests
- `/app/backend/tests/test_phase2_engine.py` — 28 unit tests (Tax Engine + Autopilot)
- `/app/backend/tests/test_phase2_api.py` — 20 API integration tests (added by testing agent)
- **48/48 passing** — verified by external testing agent (see `/app/test_reports/iteration_3.json`)

## Implemented (2026-07)
### Milli Autopilot™ Engine (backend)
- New `/app/backend/autopilot.py` — pure-logic pipeline module (no HTTP coupling), fully immutable receipts
- 9-step pipeline runs on every eligible payout: `Payout → Source → Tax Rate → Vault credit → Retirement → Investing → Savings → Available-to-Spend → Quarterly Projection → AI Insight → SHA-256 hashed Autopilot Receipt`
- Wired into Plaid sync AND `/api/deposits/manual-v2` — every new payout triggers the pipeline
- New endpoints: `GET/PUT /api/autopilot/settings`, `GET /api/autopilot/receipts[/{id}]`, `GET /api/dashboard/snapshot`
- Idempotent startup migration: applies Autopilot defaults (Tax ON, Retirement 5%, Investing 5%, Savings 0%) to every existing user
- New collections: `autopilot_receipts` (immutable, hashed), `savings_transfers`; existing `tax_vaults` / `retirement_accounts` / `investment_accounts` are auto-created on first payout
- Demo seed rewritten to run Autopilot on all 40 seeded payouts (produces real receipts + coherent balances)
- Verified: Tax Vault $2,312.59 · Retirement $505.51 · Investing $315.94 · Savings $126.37 · Available-to-Spend $3,058.13 · Tax Ready Score 100 for demo user

### Brand Refresh (frontend)
- Extracted M-runway logo + wordmark from user's approved artwork to `/app/frontend/public/brand/` (mark, wordmark, app-icon, hero-m, hero-scene)
- Tailwind palette locked to design-system exact hex: Obsidian `#07090B` · Charcoal `#0E1114` · Surface `#161A1F` · Electric Cyan `#00E5FF` · Deep Teal `#00B4C2` · Polished Silver `#C0C0C0` · Alpine White `#FFFFFF`
- Typography swapped Manrope → **Sora** for headings, Inter for body
- Global CSS variables + carbon/rays/card/button classes updated to new palette
- Title tag + favicon + description updated ("Milli — Money, Made Intelligent.")
- `MilliLogo` component supports variant="mark" (inline SVG) and variant="hero" (approved PNG)

### Login + Register split-screen redesign (frontend)
- New `<AuthHero />` component: cinematic right pane with hero M+MILLI mark, "Money, Made Intelligent." tagline, "Every payout, on Autopilot." subtitle, and 4-icon feature grid (Automate Taxes / Track Mileage / Build Wealth / Tax Season Ready)
- Register page rebuilt to match approved reference exactly: icon-prefixed inputs, cyan gradient START TRIAL button, trust badges (Bank-level security · PCI compliant · No commitment), silver/cyan two-tone hero headline
- Login page rebuilt with same visual system, "Back to Autopilot." headline, matching field styling and trust badges

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
- **Marketing Studio** (`/api/marketing/videos`, `/api/marketing/videos/{file}.mp4`): lists + streams Sora 2 generated brand films

## Implemented (2026-06)
### Native iOS Shell (Capacitor 7)
- Capacitor v7 wired into `/app/frontend` (cli + core + ios + community plugins)
- `ios/` Xcode project scaffolded with app id `app.milli.tax`, name `Milli`
- `Info.plist` configured with `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSMotionUsageDescription` and `UIBackgroundModes: location, fetch, processing`
- `@capacitor-community/background-geolocation` integrated via `src/native/mileageTracker.js`; falls back to web `watchPosition` when not native
- `Mileage.jsx` auto-detects platform and runs background-capable GPS on iOS/Android, web continues unchanged
- Build guide checked in at `/app/IOS_BUILD_GUIDE.md` (Xcode signing, pod install, App Store checklist)

### Marketing Studio (Sora 2)
- 5 cinematic 8-second brand films generated and stored at `/app/marketing_videos/`:
  - 01 Cinematic Luxury — Skyline (9:16, 720x1280) — Reels / TikTok
  - 02 Driver POV — Night HUD (16:9, 1280x720) — YouTube / web hero
  - 03 Lifestyle — Gig Worker Smile (9:16, 720x1280)
  - 04 Product — Kinetic Typography (16:9, 1280x720)
  - 05 Hero Brand Montage (9:16, 720x1280)
- `/marketing` React page with auto-preview hover cards, modal player, per-clip MP4 download, polls backend for in-progress clips
- Generator script at `/app/scripts/generate_marketing_videos.py` (resumable, status logged to `generation_log.json`)
- Added `Reel` link in Landing page nav

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
- **Apple In-App Purchase + Google Play Billing** for native Basic/Pro/Elite (web still uses Stripe)
- **Real partner integrations** (Stripe Treasury / Unit for Vault, Carry / Altruist for Investing) when production keys arrive
- **Plaid Sandbox → Production** swap
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
