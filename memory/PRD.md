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
| Team ID | `5GV6Z3S674` |
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
- Plaid — sandbox
- Stripe — test mode
- Apple In-App Purchase (StoreKit 2) — not yet implemented

## Prioritized Roadmap
### P0
- **Apple IAP (StoreKit 2)** — Capacitor IAP plugin, Paywall UI
  (Basic $19.99 / Pro $29.99 / Elite $49.99 monthly),
  backend `/api/subscriptions/verify-receipt` endpoint,
  `Products.storekit` local test config

### P1
- Wire real banking APIs (Unit or Stripe Treasury) when production keys arrive

### P2
- Auto quarterly estimated tax payments (Elite tier)
- Guided tax prep + e-filing via approved partner (Elite tier)

### P3
- Cash-flow forecasting + advanced goal planning
