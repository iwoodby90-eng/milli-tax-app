# MilliScreens v3.1 — Screen / Component Split for Julian's Integration

**Branch:** `feature/milliscreens-v3.1-canonical-nav-seam` (this commit)
**Base:** main @ `db94a25`
**Status:** visual implementation layer ready; nav seam UNBOUND (see below)

## 1. Nav status — critical

- `MilliTaxVault/Components/MilliNavBar.swift` on main is the **rejected floating-pill
  implementation** (capsule chassis, elevated center M, glow pulse). Ian verified this
  directly. **Do not bind it.**
- `MilliScreensNavWiring.install()` is now a **no-op**: the seam
  (`MilliScreensNavBar.canonicalRenderer`) stays nil until the canonical nav
  reconstruction (sculpted chrome chassis, Image 40: Payouts | Mileage | center M/Home |
  Wealth | More) passes its own runtime gate.
- When the approved nav lands, bind it in `MilliScreensNavWiring.install()` — the
  `Binding<MilliScreensTab>.canonical` bridge is kept for that purpose.
- The screenshot-derived dock (`MilliNavReferencePreview`) remains quarantined
  DO-NOT-SHIP; it renders only when the seam is nil (design previews only).

## 2. Screen inventory (25 screens, `MilliScreens-v3.1.swift`)

| # | Screen struct | Area |
|---|---------------|------|
| 1 | SplashScreen | Entry |
| 2 | WelcomeScreen | Entry |
| 3 | CreateAccountScreen | Onboarding |
| 4 | TaxProfileOnboardingScreen | Onboarding |
| 5 | GigPlatformsScreen | Onboarding |
| 6 | AutopilotSetupScreen | Autopilot |
| 7 | HomeDashboardScreen | Core |
| 8 | PayoutsScreen | Core |
| 9 | TaxVaultScreen | Core |
| 10 | MileageDashboardScreen* | Mileage |
| 11 | ActiveTripScreen | Mileage |
| 12 | TripDetailScreen | Mileage |
| 13 | OfferAnalyzerScreen | Mileage |
| 14 | ExpensesScreen | Operations |
| 15 | AccountsScreen | Operations |
| 16 | WealthOverviewScreen | Wealth |
| 17 | InvestingScreen | Wealth |
| 18 | RetirementScreen | Wealth |
| 19 | TreeOfLifeScreen | Wealth |
| 20 | PlanningAdjustmentsScreen | Planning |
| 21 | FinancialTimelineScreen | Planning |
| 22 | MilliAIChatScreen | Intelligence |
| 23 | AIActionConfirmationScreen | Intelligence |
| 24 | ReportsScreen | Records |
| 25 | SettingsScreen / MoreHubScreen | Control |

*MileageDashboardScreen is composed inside the mileage section; see file for exact name.

## 3. Shared production components (extractable, reused across screens)

- `MilliCard` — layered material card (obsidian/carbon, fine silver border)
- `MilliCardVisual` — premium card object treatment
- `MilliToggle` — engineered control
- `PrimaryButton` / `OutlineButton` — cyan-lit primary / black-glass secondary actions
- `ProgressRing`, `Sparkline`, `DonutChart` — data viz (cyan primary series)
- `RouteMapPanel` — trip route visualization
- `ScreenTitleBar`, `SectionLabel`, `FormFieldRow`, `AuthField`, `FlowChips`
- `MilliLogoHeader`, `MilliMark`, `MilliWordmark` (wordmark in Components/)
- `MilliAICharacterView`, `MilliAICallout` — MILLI AI supporting layer (subtle, per Ian)

## 4. Integration contract for Julian

1. App root calls `MilliScreensNavWiring.install()` (currently no-op — safe).
2. Every applicable screen renders nav only via `MilliScreensNavBar` (the seam).
3. Once the canonical nav reconstruction passes its runtime gate, inject the approved
   renderer in `install()` — nothing else changes.
4. Screens are self-contained SwiftUI views taking plain state; no nav coupling beyond
   the seam binding.
5. QA gate: `docs/QA-HARNESS-MilliScreens-v3.1.md` (25 screens × 3 devices,
   REFERENCE | RUNTIME | SIDE-BY-SIDE, P0/P1/P2).
