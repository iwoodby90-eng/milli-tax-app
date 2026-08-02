# Milli — Product Requirements Document

## Vision
Milli is a premium, AI-powered financial operating system and tax collection
app for gig workers and the self-employed. The flagship feature is
**Milli Autopilot™**: every payout is automatically sliced into tax reserve,
retirement, investing, and available-to-spend before the user ever sees it.

## Core Pillars
1. **Milli Autopilot™** — automatic allocation on every deposit
2. **Milli Tax Vault™** — dedicated tax reserve with immutable receipts
3. **Automatic Background Mileage** — GPS-based, Waze-style
4. **Big City Futuristic UI** — pure black + neon cyan + polished chrome

## Platforms
- Web (React) — production-ready
- iOS + iPad (Capacitor v7) — App-Store-submission-ready
- Apple Watch (SwiftUI companion, `MilliWatch`)

## Apple Developer Account (locked in)
| Field | Value |
|---|---|
| Team ID | `W5Q42XNM9V` |
| Apple ID | `iwoodby90@gmail.com` |
| Main Bundle ID | `app.milli.tax` |
| Watch Bundle ID | `app.milli.tax.watchkitapp` |
| Watch Complication Bundle ID | `app.milli.tax.watchkitapp.complication` |

## What's Implemented
- FastAPI backend: autopilot.py, tax_engine.py, integrations abstraction
- MongoDB models: User, Transaction/Deposit, Trip, AutopilotReceipt
- React frontend: full Big City Futuristic design system
- Marketing site + Sora 2 videos hosted on gofile.io
- iOS Capacitor scaffold: icons, launch screen, Info.plist, plugins wired
- Apple Watch SwiftUI target files (ContentView, WatchSession, Complication)
- **App Store registration finalized (Feb 2026)**: Team ID, ExportOptions.plist,
  metadata + build guide updated with real Apple credentials

## What's Mocked / Pending Real Keys
- Plaid — LIVE wired (multi-bank connections)
- Stripe — LIVE keys wired (Billing + portal)
- Apple IAP (StoreKit 2) — implemented via `@capgo/native-purchases` + receipt verification

## Changelog
- **Aug 2, 2026 (night)** — **Streak Counter, Push infra, TaxBandits auth, Vault Widget code.**
  * **Streak Counter** — Dashboard header now shows a cyan flame pill "N day(s)" that counts consecutive days with logged trips (60-day look-back). Rendered next to the greeting via `data-testid="dashboard-streak-pill"`.
  * **Push Notifications infrastructure** — installed `@capacitor/push-notifications`, added `usePushNotifications` hook (permissions → register → POST /api/push/register), and backend endpoints `POST /api/push/register` + `DELETE /api/push/register` that persist device token in `users.push`. Wired at AppLayout mount so every native launch registers. **Actual APNs delivery still needs an Apple Push key (.p8) + Key ID.**
  * **TaxBandits sandbox** — creds stored in `backend/.env` (`TAXBANDITS_CLIENT_ID/SECRET/USER_TOKEN`, `TAXBANDITS_ENV=sandbox`). New `backend/taxbandits.py` implements the JWS-signed GET auth flow (verified live — returns a real access token). Two new endpoints: `GET /api/taxbandits/health` (auth diagnostic) and `POST /api/taxbandits/tin-match` (Elite-only). NOTE: TaxBandits does **not** publish a Form 1040 / Schedule C endpoint, so Elite Schedule C e-file will route to Column Tax later; TaxBandits stays for TIN matching + 1099-NEC receipt.
  * **Vault Widget** — `/app/frontend/ios/App/MilliVaultWidget/MilliVaultWidget.swift` + `README.md` shipped. SwiftUI TimelineProvider + Small/Medium views (MILLI VAULT pill, big balance, +this month, cyan progress bar, polished chrome M on medium). Integration guide covers Xcode Widget Extension target creation, App Group setup (`group.app.milli.tax`), and data bridge from React → shared UserDefaults.
  * Rebuilt Capacitor iOS bundle. Fresh `milli-source.tar.gz` (~1.2 GB) at `/app/frontend/public/`.
- **Aug 2, 2026 (late-late)** — **All 4 remaining tabs matched + Notification Center + Vault Progress Story.**
  * **NotificationSheet** (`/app/frontend/src/components/NotificationSheet.jsx`) — bottom sheet with grabber, "3 NEW" pill, and rows for Quarterly / Payout / Vault / Milestone kinds. Unread rows carry a cyan tint + right-side dot; each row has a color-tinted icon square + kind label + timestamp + title + body. Wired to the bell icon in `AppLayout.jsx` (was previously navigating to Settings).
  * **Vault** rewritten as `Milli Tax Vault™` with the **Progress Story hero**: "You're X% to your 2026 goal" copy, big protected balance, milestone-dotted cyan progress bar (25/50/75/100), "$X to next milestone" hint, VaultShield SVG. Auto-fires a **CSS confetti burst** the moment the user crosses a milestone. Below: Milli Autopilot ON pill, Recent Transfers (in/out directional icons, cyan `+$` and rose `−$` amounts), and **Elite Perks** card that unlocks tiers with the progress bar (Priority AI @25%, Auto Quarterly Filing @50%, 1099 auto-import @75%, Federal + State e-file @100%) plus a full-bright card for existing Elite users.
  * **More** rewritten to Milli aesthetic: chrome-initials profile card with cyan ELITE badge, grouped nav (Money / Tools / Account) using milli-card rows with cyan icon squares and chevrons, big sign-out button, version footer.
  * **Wealth** rewritten as a segmented Retirement / Investing hub — reuses the new Retirement + Investing pages under a cyan-outlined segment control.
  * Rebuilt Capacitor iOS bundle and refreshed `/app/frontend/public/milli-source.tar.gz` (~590 MB).
- **Aug 2, 2026 (late)** — **Full mockup match: 4 pages + polished chrome home button.**
  * **Chrome M home button** rewritten as a single polished-chrome disc (radial silver gradient, no more dark inner ring) with a big embossed chrome-gradient M and a proper cyan under-bloom. Now matches the reference exactly.
  * **Mileage** rewritten to match "Mileage Tracker" mockup: `Auto-Tracking ON` pill (top-right, horizontal), LIVE Tracking Trip card (cyan pulse ring + Miles/Time/Est.Deduction + cyan-gradient Stop Tracking button), **real Google Maps** with Milli-branded dark-noir style + cyan double-stroke route + start/end pins + "Today's Miles" glass overlay, Trip History rows with platform badges, and monthly Summary. Google Maps key wired via `REACT_APP_GOOGLE_MAPS_KEY`.
  * **Retirement** rewritten to match the "Retirement" mockup: Projected Balance $2.65M hero with glowing tree on chrome M pedestal + delta cyan line, Projection Range selector + Future Value/Income segmented control, animated line-chart with $2.65M callout, 3-up Contribution ring / Employer Match / Goal Progress bar, Est. Monthly Income + 5-bar Confidence Level, Scenario Comparison (Current/Increase/Delay) with mini spark lines.
  * **Investing** rewritten to match the "Investing" mockup: Total Portfolio Value $124,560 hero with metallic M card + delta, Market Overview (SPX candlestick chart with cyan/rose candles + Live pill + 1D/1W/1M/1Y/All tabs), Today's Gain/Loss + Buying Power (with Milli coin stack graphic), Watchlist AAPL/TSLA/NVDA + Asset Allocation donut, Milli AI Insight card.
  * **Milli Cents** rewritten to match "Milli Cents" mockup: LIVE Offer Analysis (Uber logo + payout + half-arc profit-score gauge with verdict color coding: GO/OKAY/SKIP), breakdown table with icons per row + Projected Net Profit highlighted, big verdict CTA card, Compare Live Offers 4-up ranked tiles (rank badge, platform logo, payout, miles, net, mini score ring).
  * **Activity** (Income) rewritten to match Milli aesthetic: fixed text-bleed by dropping the old table for a card-list grouped by month with platform badges, +amount, and "−$X.XX to Vault" cyan sub-lines. Sync + Add pill icon buttons in the header. Manual-payout modal restyled with cyan-border sheet.
- **Aug 2, 2026 (evening)** — **Dashboard v3 — 1:1 with reference mockup.**
  * Rewrote `AppLayout.jsx` header: cyan lowercase `milli` wordmark left, bell icon w/ cyan notification dot right. Removed Elite pill from header.
  * New 5-tab bottom bar: **Dashboard · Activity · [raised chrome M home] · Transfers · More**. Center home button is a metallic radial-gradient chrome ring with pure text-M inside (no more sticker-look) plus cyan underglow bloom.
  * Rewrote `Dashboard.jsx` from scratch to match the "Good morning, Alex" mockup exactly:
    - Greeting hero (time-aware Good morning / afternoon / evening)
    - **Available to Spend** cyan-glow-border card with metallic M debit-card graphic floated in top-right
    - **Latest Payout** 2-column card (Gross | Net/Taxes/Vault/Total breakdown)
    - **Milli Tax Vault™** + **Tax Ready Score™** 2-up (bank icon + progress bar + goal · circular ring + status)
    - **Financial Timeline** with cyan-outlined date circles + icon + label + amount + chevron rows
    - **Mileage · Retirement · Investing** 3-up tiles with delta chips
  * New CSS primitives in `index.css`: `.milli-card-lux` (cyan halo glass card w/ gradient border), `.app-aurora` + `.aurora-streak` (ambient cyan side-glow / neon streak animations layered over carbon-fibre bg — matches the mockup's signature aurora).
  * Rebuilt Capacitor iOS bundle (`yarn build && npx cap sync ios`) and refreshed `/app/frontend/public/milli-source.tar.gz` (~121 MB) so user can pull latest into Xcode.
- **Aug 2, 2026** — **App Store submission rebuild.**
  * App officially renamed to **Milli Tax Vault** (short form: MILLI) in `capacitor.config.json`, `Info.plist` (CFBundleDisplayName + CFBundleName), `index.html` title/meta, `manifest`.
  * New **official logo** shipped: chrome-M with cyan stripe. Saved as `/app/frontend/public/brand/milli-logo-{60,120,180,256,512,1024}.png`. 25 iOS app icons regenerated in `Assets.xcassets/AppIcon.appiconset/`. `MilliLogo.jsx` rewritten to render the PNG with SVG fallback.
  * **New 5-tab bar**: `[Vault | Wealth | 🅜 raised chrome M | Mileage | Settings]`. Old 7-slot bar removed.
  * **MilliFAB** — persistent floating Milli AI avatar in bottom-right on every protected `/app/*` route (hidden on `/app/ai` where she's already the hero).
  * **Wealth page** (`/app/wealth`) — combined Retirement + Investing hub with segment control.
  * **Milli Cents** (`/app/milli-cents`) — new Offer Profitability Engine. Backend: `POST /api/milli-cents/score` and `/api/milli-cents/compare` with real scoring math (gas cost + wear + tax + per-mile + per-hour blended score). Frontend: Live Offer Analysis card with animated score gauge, breakdown table, GO/MARGINAL/SKIP verdict badge, and full offer input form.
  * **Dashboard widget grid** — 4 tab-shortcut cards (Vault, Wealth, Mileage, Milli Cents) at the top of the dashboard.
  * Tested by testing_agent (iteration_9): backend 10/10 pytest passing, frontend all acceptance criteria green after adding missing App.js imports.
- **Feb 22, 2026** (late-late) — **Weebo v4: 3D-feel, transparent, roaming.**
  Removed the background from the reference PNG using `rembg` (U²-Net model),
  saved as `milli-ai-cutout.png` + `milli-ai-cutout-512.png`. Rewrote
  `WeeboAvatar.jsx` v4 to render the transparent cutout inside a stage that
  she wanders across (drift + tilt + rotateY perspective + scale for 3D feel).
  Portal ring stays on the floor and drifts with her. Rebuilt + copied assets
  into iOS bundle. New 31 MB source tarball. Full Xcode-open recipe delivered.
- **Feb 22, 2026** (late) — Real Milli AI mascot replaces the SVG.
- **Feb 22, 2026** (evening) — Voice + Referral + iOS refresh:
  * **Weebo now talks.** `/api/ai/voice` (OpenAI TTS via emergentintegrations, `tts-1` / voice=shimmer) generates MP3 audio from her final answer. React hook `useWeeboVoice` fetches the MP3 and plays via `<audio>`, drives `weeboState="speaking"` so her mouth animates in sync. Mute toggle persisted in localStorage.
  * **Referral system** — 3 backend endpoints (`GET /api/referral/me`, `POST /api/referral/apply`) + new `/app/referral` page. $10 vault credit both sides, unique `MILLI-XXXXXX` code per user, share/copy/redeem UI, live stats (invited count, credit earned).
  * **Fixed WelcomePaywall tier badge overlap** (same bug pattern as `Paywall.jsx` from earlier).
  * **iPhone 404 hardening**: added public `GET /api/health` for smoke tests; rebuilt frontend (`DISABLE_ESLINT_PLUGIN=true yarn build`) + refreshed iOS bundle at `/app/frontend/ios/App/App/public/`; verified compiled JS points at correct preview URL; new source tarball published at `/app/frontend/public/milli-source.tar.gz` (24 MB).
- **Feb 22, 2026** — Big design push (7-slot tab bar, Weebo avatar, landing polish, private reels).
- **Feb 2026** — Fixed AppLayout scroll clipping (position:fixed → position:sticky).
  * New 7-slot bottom nav: `[Vault][401(k)][Invest] [🅜 raised center] [Mileage][Taxes][Settings]`. All other pages moved into the side drawer.
  * Added `WeeboAvatar.jsx` — animated SVG mascot (Flubber-inspired droid): antenna pulse, chrome equator, glowing pixel eyes, blinking + speaking mouth animations, levitation halo + particles. States: `idle | thinking | speaking`.
  * Floating Weebo FAB on Home routes to `/app/ai`.
  * Milli AI page: large animated Weebo hero at top with grid backdrop + scan-line sweep; state reacts to streaming ("thinking" → "speaking" → "idle"). Message rows now show Weebo as the assistant avatar.
  * Landing page: hero CTA copy shrunk to one-line ("Start 3-day trial"), footer tagline shrunk, tier cards stacked vertically with breathing room, hero closing copy rewritten to "Taxes are inevitable. Losing to them isn't.".
  * Pricing page: tiers stacked as full-width, generous cards with badges & CTAs.
  * Regenerated all 5 Sora 2 marketing reels — now **PRIVATE**: `/api/marketing/videos` + `/api/marketing/videos/{file}` require auth; public gofile mirror disabled (`upload_marketing_to_public_host.py` renamed to `.bak`).
- **Feb 2026** — Fixed AppLayout scroll clipping (position:fixed → position:sticky).

## Prioritized Roadmap
### P0 — DONE
- Apple IAP (StoreKit 2) via `@capgo/native-purchases` + `/api/subscriptions/verify-receipt` ✅
- AppLayout scroll/clipping fix (sticky header + tab bar) ✅ (Feb 2026)

### P1
- Wire real banking via Stripe Treasury when Treasury access is approved

### P2
- Auto quarterly estimated tax payments (Elite tier)
- Guided tax prep + e-filing via approved partner (Elite tier)

### P3
- Cash-flow forecasting + advanced goal planning
