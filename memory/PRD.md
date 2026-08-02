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
