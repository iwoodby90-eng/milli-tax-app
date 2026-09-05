# MilliScreens v3.1 — Simulator Pixel-QA Harness

Goal: produce REFERENCE | RUNTIME | SIDE-BY-SIDE evidence for the 25 v3.1 screens
against the Aug 31 approved reference set, per the MILLI Visual Brand Guidelines
Section 13 (Screen Implementation Gate).

## Devices (3)
- Compact: iPhone SE (3rd gen) — 667pt
- Standard: iPhone 16 — 393pt
- Pro Max: iPhone 16 Pro Max — 440pt

## Method
1. Set `MilliScreensNavWiring.install()` in App init (canonical nav seam active).
2. For each screen below, capture in the simulator (light off, dark default):
   - RUNTIME capture at each device size (Cmd+R screenshots, 1x scale)
   - place REFERENCE (approved image) | RUNTIME | SIDE-BY-SIDE in one canvas
3. Classify deviations P0 / P1 / P2 per Guidelines §10.
   - P0/P1 block approval (nav mismatch, wrong M geometry, fake data as fact,
     clipped content, wrong colors/tokens, missing truth labels)
   - P2 logged for review
4. Record results in the QA tracker table (one row per screen × device).

## Screen checklist (25)
| # | Screen | Reference |
|---|--------|-----------|
| 01 | Splash / Launch | Screen 01 |
| 02 | Welcome / Sign In | Screens 02–03 |
| 03 | Create Account | Screen 04 |
| 04 | Tax Profile onboarding | Screen 05 |
| 05 | Gig Platforms connect | Screen 06 |
| 06 | Autopilot Setup | Screen 07 |
| 07 | Home Dashboard | Screen 08 |
| 08 | Payouts | Screen 09 |
| 09 | Milli Tax Vault | Screen 10 |
| 10 | Mileage Dashboard | Screen 11 |
| 11 | Active Trip Tracking | Screen 12 |
| 12 | Trip Detail | Screen 13 |
| 13 | Offer Analyzer (GO/MAYBE/NO) | Screen 14 |
| 14 | Expenses | Screen 15 |
| 15 | Accounts & Connections | Screen 16 |
| 16 | Wealth Overview | Screen 17 |
| 17 | Investing | Screen 18 |
| 18 | Retirement | Screen 19 |
| 19 | Tree of Life Planner | Screen 20 |
| 20 | Life Events / Planning Adjustments | Screens 21–22 |
| 21 | Financial Timeline | Screen 23 |
| 22 | Milli AI chat | Screen 24 |
| 23 | AI Action Confirmation | Screen 25 |
| 24 | Reports & Exports | Screen 26 |
| 25 | Settings & Security / More Hub | Screens 29–30 |

## Hard gates (auto-fail)
- Any screen rendering the quarantined `MilliNavReferencePreview` instead of the
  canonical `MilliNavBar` (via the seam) — P0.
- Any fabricated financial state shown as authoritative (must carry
  DEMO/PREVIEW/ESTIMATED labels) — P0.
- Tap targets < 44pt, missing truth labels on projections — P1.

## After the 25 pass
Continue the same visual system toward the full 70–90 screen/state library
(receipt variants, Tax Vault ledger/transfer, Quarterly Taxes, Tax Ready Score,
Mileage History, Add Expense, bank connection, card controls, notifications,
subscription, Security & Privacy, support/legal, annual filing substates,
AI action processing/failure/success).