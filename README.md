# Milli Tax Vault

A premium iOS finance app for freelancers and gig workers to automatically set aside taxes from their earnings.

## Architecture

Pure SwiftUI, iOS 17+, Swift Charts.

## Project Structure

```
MilliTaxVault/
├── MilliApp.swift                    # App entry point
├── ContentView.swift                 # Root view & custom navigation coordination
├── Info.plist                        # App configuration
├── MilliSubscriptions.storekit       # StoreKit subscription configuration
│
├── Components/                       # Reusable UI building blocks
│   ├── MilliNavBar.swift             # Canonical bottom nav + center M dial (Payouts, Mileage, Home, Wealth, More)
│   ├── MilliVaultHeader.swift        # Tax Vault screen header
│   ├── MilliLedger.swift             # Ledger rows & transaction state badges
│   ├── MilliDetailAndStates.swift    # Detail sheet & six ledger state views
│   ├── MilliDetailSheet.swift       # Detail sheet scaffold
│   ├── MilliHeroBalanceCard.swift   # Hero balance card
│   ├── MilliMetalCard.swift         # Frosted metal card
│   ├── MilliMetricCard.swift        # Metric card
│   ├── MilliInsightCard.swift       # Insight card
│   ├── MilliSparkline.swift         # Sparkline chart
│   ├── MilliProgressRing.swift      # Progress ring
│   ├── MilliSurface.swift           # Glass card surface
│   ├── MilliWordmark.swift          # Brand wordmark
│   ├── MilliCenterMButton.swift     # Center M button
│   ├── MilliProtectionInstruments.swift # Protection instruments UI
│   ├── BelAirNavBarShape.swift      # Nav bar custom shape
│   ├── ChromeEmblemView.swift       # Chrome emblem
│   ├── MilliAIOrb.swift             # AI orb
│   └── MilliAICompanion.swift        # AI companion character
│
├── DesignSystem/                     # MilliColors, MilliTypography, MilliSpacing, MilliBlueprint
├── Theme/
│   └── MilliTheme.swift              # Theme entry point
│
├── Features/
│   └── Home/                         # Home dashboard (HomeView, HomeViewModel, HomeModels)
│
├── Views/                            # Feature screens
│   ├── VaultView.swift               # Tax vault balance & transfers
│   ├── WealthView.swift              # Net worth & spending overview
│   ├── ActivityView.swift            # Income sources & payouts
│   ├── CockpitView.swift             # Settings & profile
│   ├── MilliTaxVaultScreen.swift     # Full Tax Vault screen assembly (Blueprint v2)
│   ├── MilliTaxVaultView.swift       # Tax reserve breakdown
│   ├── MilliAIView.swift             # MILLI AI view
│   ├── MilliAIChatView.swift         # MILLI AI chat view (design-token based, back action)
│   ├── PayoutsView.swift             # Payouts & receipts
│   ├── MileageView.swift             # Mileage tracking
│   ├── MileageTrackerView.swift      # Mileage tracker
│   ├── MoreView.swift                # More menu
│   ├── DashboardView.swift           # Dashboard
│   ├── ExpensesView.swift            # Expenses
│   ├── InvestingView.swift           # Investing
│   ├── LiveMarketChartView.swift     # Live market chart
│   ├── MarketDataViewModel.swift     # Market data view model
│   ├── LocationManager.swift        # Location manager
│   ├── ReportsView.swift             # Reports
│   ├── RetirementView.swift          # Retirement
│   ├── AddRetirementAccountSheet.swift # Add retirement account sheet
│   ├── AddLifeEventSheet.swift       # Add life event sheet
│   ├── TaxReadyScoreView.swift       # Tax ready score
│   ├── TaxVaultView.swift            # Tax vault
│   ├── TreeOfLifeView.swift          # Tree of Life
│   ├── WealthOverviewView.swift      # Wealth overview
│   ├── MilliCentsView.swift          # Milli Cents
│   ├── QuarterlyTaxesView.swift      # Quarterly taxes
│   ├── TreasuryAutopilotViews.swift  # Stripe Treasury Autopilot UI (connect, routing, payout rows, receipts)
│   ├── Components/                   # Screen-level components (MilliCard, MilliChart, CircularProgressView)
│   └── Onboarding/                   # Login, onboarding flow, plan selection, setup
│
├── Models/
│   ├── AppModels.swift               # Core financial and transaction models
│   ├── PayoutStateContract.swift     # Canonical payout state machine & provenance labels (Money-Movement State Contract v2.1)
│   ├── TaxProfile.swift              # Tax filing status and subscription tiers
│   └── VehicleProfile.swift          # Vehicle profile
│
├── Services/
│   ├── AppleAuthManager.swift        # Sign in with Apple
│   ├── BankConnectionService.swift   # Bank connection
│   ├── QuarterlyTaxEstimator.swift   # Quarterly tax estimator
│   ├── TreasuryAutopilotStore.swift  # Read-only backend projection for Autopilot (demo only via loadDemoData)
│   └── StoreKitService.swift         # StoreKit subscriptions
│
├── Resources/                        # Fonts
└── Assets.xcassets/                   # App icon, brand assets, template icons, hero images

MilliTaxVaultTests/                   # XCTest suites: QuarterlyTaxEstimator (21 tests) + TreasuryAutopilot (10 tests)
backend/migrations/                    # SQL migrations (mileage logs, brokerage tradings)
scripts/                              # Screen capture, Swift validation (incl. brand hex-literal lint), repo health checks
```

## Design System

- Background: `#07090B` (Obsidian) with subtle radial gradients over `#0E1114` (Carbon)
- Accents: `#00E5FF` (Electric Cyan) and `#00B4C2` (Deep Cyan)
- Neutrals: `#C0C0C0` (Silver)
- Semantic: `#22DB83` (Positive), `#F4B73B` (Warning), `#FF5661` (Negative)
- Cards: Frosted glass with subtle stroke glow and chrome finishes
- Typography: Sora for financial metrics, Inter for UI text
- Charts: Swift Charts with cyan gradient fill
- Navigation: Custom brush-chrome center `M` button with custom tab routing (`MilliNavBar.swift`)

## Validation & Quality Assurance

- **Native Build CI**: Automated Xcode build validation on macOS runners (`.github/workflows/validate.yml`)
- **Visual QA**: SwiftUI visual QA workflow (`.github/workflows/swiftui-visual-qa.yml`) plus comprehensive UI screen capture and integrity verification suite (`scripts/capture-milli-screens.sh`, `scripts/verify-milli-screen-captures.sh`)
- **Unit Tests**: QuarterlyTaxEstimator (21 tests) and TreasuryAutopilot (10 tests) XCTest suites (`MilliTaxVaultTests/`)
- **Brand Lint**: `scripts/validate_all_swift.py` enforces the MilliColors token rule (off-token `Color(hex:)` literals rejected outside DesignSystem and locked nav components)
- **Repository Health**: Architecture and reference verification script (`scripts/verify-repo-health.sh`)

## Requirements

- Xcode 15.4+
- iOS 17.0+
- Swift 5.9+
