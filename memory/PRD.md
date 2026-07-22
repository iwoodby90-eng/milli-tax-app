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
- **Feb 22, 2026** — Big design push:
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
