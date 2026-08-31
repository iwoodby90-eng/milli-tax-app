# MilliScreens v3.1 — Screen / Component Split for Integration

**Status:** integration prep · **Base:** main @ db94a253 · **Branch:** feature/milliscreens-v3.1-canonical-nav-seam
**Owner:** Alexa (visual implementation layer) → **Integrator:** Julian

## 1. Nav status (blocking)

- `MilliTaxVault/Components/MilliNavBar.swift` on main is the **rejected floating-pill implementation** (capsule chassis, elevated center M, ambient underglow). Ian verified this directly. It is NOT canonical.
- The only allowed final nav is the approved sculpted chrome chassis reference: **Payouts | Mileage | center M/Home | Wealth | More**. No screenshot-derived substitute, no alternate design.
- `MilliScreensNavBar.canonicalRenderer` seam is kept; `MilliScreensNavWiring.install()` is now a **deliberate no-op** until the canonical nav reconstruction passes its own runtime gate. Julian binds the reconstructed nav there — and only there.
- `MilliNavReferencePreview` (screenshot-derived dock) stays quarantined: design-preview builds only, DO NOT SHIP.

## 2. Layer contract

| Layer | File(s) | Responsibility |
|---|---|---|
| Visual implementation | `MilliTaxVault/DesignSystem/MilliScreens-v3.1.swift` | 25 high-fidelity screens + shared visual components. Renders nav ONLY via the seam. |
| Nav seam | `MilliScreensNavBar.canonicalRenderer` (in v3.1 file) | Single injection point for the canonical nav. |
| Nav wiring | `MilliTaxVault/DesignSystem/MilliScreensNavWiring.swift` | Tab-model bridge (`MilliScreensTab` ↔ canonical tab). Currently unbound by design. |
| Canonical nav | TBD (reconstruction, separate gate) | Sculpted chrome chassis per approved reference. |

## 3. Shared components in v3.1 (extractable for production)

`MilliTheme` (tokens), `MilliLogoHeader`, `ScreenTitleBar`, `MilliMark`, `MilliAICallout`, `MilliAICharacterView`, `MilliCard`, `SectionLabel`, `PrimaryButton`, `OutlineButton`, `MilliToggle`, `ProgressRing`, `Sparkline`, `DonutChart`, `MilliCardVisual`, `RouteMapPanel`.

These are screen-agnostic and can be promoted into `MilliTaxVault/Components/` one by one as Julian integrates, keeping v3.1 as the reference implementation.

## 4. The 25 screens (grouped for staged integration)

- **Entry/Onboarding (5):** Splash, Welcome, CreateAccount, TaxProfileOnboarding, GigPlatforms
- **Autopilot (1):** AutopilotSetup
- **Core (3):** HomeDashboard, Payouts, TaxVault
- **Mileage (4):** ActiveTrip, TripDetail, OfferAnalyzer, (Mileage Dashboard lives in HomeDashboard module set)
- **Operations (2):** Expenses, Accounts
- **Wealth (4):** WealthOverview, Investing, Retirement, TreeOfLife
- **Planning (2):** PlanningAdjustments, FinancialTimeline
- **Intelligence (2):** MilliAIChat, AIActionConfirmation
- **Records/Control (4):** Reports, Settings, MoreHub, (AuthField/FormFieldRow support views)

## 5. Integration steps for Julian

1. Wait for the canonical nav reconstruction to pass its runtime gate (separate workstream).
2. Bind it in `MilliScreensNavWiring.install()` — the only allowed binding point.
3. Add `MilliScreens-v3.1.swift` + `MilliScreensNavWiring.swift` to the Xcode project (they are not yet in project.pbxproj).
4. Integrate screens in the staged order above; promote shared components as needed.
5. Run the QA harness: `docs/QA-HARNESS-MilliScreens-v3.1.md` (25 screens × 3 devices, REFERENCE | RUNTIME | SIDE-BY-SIDE, P0/P1/P2 gates).

## 6. Data truth

All figures in v3.1 screens are DEMO/PREVIEW placeholders per the Money-Movement State Contract. No screen asserts authoritative balances; state labels (LIVE/ESTIMATED/DEMO) are preserved.
