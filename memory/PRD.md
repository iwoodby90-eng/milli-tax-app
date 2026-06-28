# MILLI — PRD

## Problem Statement (original)
"Build me a comprehensive tax collection and mileage tracker app that can connect with apps like spark or uber and door dash. Allowing those who deliver to remove and collect tax and track miles for end of year tax's"

## Target User
US-based 1099 gig delivery drivers (Uber, DoorDash, Spark, Lyft, Instacart, Amazon Flex, Grubhub, Shipt). Typically not tax-savvy; need a tool that auto-saves tax, tracks miles, and produces year-end forms.

## User Decisions Captured
- Bank → Plaid (sandbox keys provided, production secret available for switch)
- Auth: Email + password (JWT, Bearer token, localStorage)
- Mileage: device geolocation (browser GPS)
- Tax: Federal SE 15.3% + quarterly + state (configurable on signup)
- AI: Gemini 3 Flash (cheapest) via Emergent Universal Key — tax tips chat + receipt OCR
- Pricing: 3-day trial → Basic $19.99 / Pro $29.99 / Elite $49.99 (Stripe via emergentintegrations)
- "Elite" feature: auto-allocate tax savings per deposit + auto-generate Schedule C + SE PDFs

## Core Requirements
1. Marketing landing + sign-up + login
2. Plaid Link → bank connect → auto-detect gig deposits → suggest tax savings %
3. Live GPS trip tracker + manual trip entry + trip history
4. Expense ledger with AI receipt OCR (Pro+)
5. AI tax assistant chat (streaming)
6. Schedule C + SE worksheet PDF (Pro+), mileage CSV (all)
7. Stripe checkout for tier upgrade (Basic / Pro / Elite)
8. Quarterly estimated tax tracker

## Implemented (2026-02)
- Backend (FastAPI, MongoDB) — full auth, Plaid (link/exchange/sync), trips (start/end/active/manual/list/delete), expenses (CRUD + OCR via Gemini 3 Flash), AI streaming chat, tax summary (SE+fed+state+quarterly), reports (Schedule C PDF, mileage CSV), Stripe checkout (3 tiers) + polling status + webhook
- Frontend (React, Tailwind, Phosphor icons, shadcn baseline) — Landing, Login, Register, Dashboard, Income (Plaid Link), Mileage (live GPS + manual), Expenses (+ OCR upload), AI Assistant (SSE streaming), Reports (PDF/CSV downloads), Pricing, Billing success polling, Settings
- Design — Volt Yellow / Obsidian / Neo-Brutalist tactical theme per design agent
- Test credentials saved to `/app/memory/test_credentials.md`

## Known / MOCKED items
- Stripe is **one-time payment that grants 30 days of access**, not native recurring subscriptions (emergentintegrations doesn't support native Stripe subscription billing). Webhook + polling both update plan.
- Schedule C PDF is a worksheet — not an officially-fillable IRS PDF.
- State tax uses simplified flat top-bracket estimates.

## Backlog (P1/P2)
- Recurring Stripe subscriptions + customer portal
- Schedule SE separate PDF (currently rolled into Schedule C PDF)
- Auto-savings → real bank transfer via Plaid Transfer (requires production approval)
- Push notifications for quarterly reminders + auto-end-trip detection
- Drive detection (start trip automatically when speed > threshold)
- Multi-year reports / 1099 import flow
