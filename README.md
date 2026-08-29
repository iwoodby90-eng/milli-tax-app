# Milli Tax Vault

A premium iOS finance app for freelancers and gig workers to automatically set aside taxes from their earnings.

## Architecture

Pure SwiftUI, iOS 17+, Swift Charts.

## Project Structure

```
MilliTaxVault/
├── MilliApp.swift                    # App entry point
├── ContentView.swift                 # Root view & custom navigation coordination
├── DesignSystem/                     # MilliColors, MilliTypography, MilliSpacing, MilliBlueprint
├── Features/
│   ├── Home/                         # Home dashboard (HomeView, HomeViewModel, HomeModels)
│   └── Components/                   # Blueprint v2 visual layer
│       ├── MilliNavBar.swift         # Canonical bottom nav + center M dial (tab labels: Payouts, Mileage, Wealth, More, Home)
│       ├── MilliVaultHeader.swift    # Tax Vault screen header
│       ├── MilliLedger.swift         # Ledger rows & transaction state badges
│       ├── MilliDetailAndStates.swift# Detail sheet & six ledger state views
│       ├── MilliHeroBalanceCard.swift# Hero balance card
│       └── ...                       # Cards, rings, sparklines, surfaces, wordmark
├── Views/
│   ├── VaultView.swift               # Tax vault balance & transfers
│   ├── WealthView.swift              # Net worth & spending overview
│   ├── ActivityView.swift            # Income sources & payouts
│   ├── CockpitView.swift             # Settings & profile
│   ├── TaxVaultView.swift            # Tax reserve and breakdown
│   ├── MilliTaxVaultScreen.swift     # Full Tax Vault screen assembly (Blueprint v2)
│   ├── MilliAIChatView.swift         # MILLI AI chat view (design-token based, back action)
│   ├── PayoutsView.swift             # Payouts & receipts
│   ├── MileageView.swift             # Mileage tracking
│   └── Onboarding/                   # Login, onboarding flow, plan selection, setup
│       └── ...
├── Models/
│   ├── AppModels.swift               # Core financial and transaction models
│   └── TaxProfile.swift              # Tax filing status and subscription tiers
├── Services/                         # AppleAuthManager, BankConnectionService, QuarterlyTaxEstimator, StoneKitService
├── Theme/MilliTheme.swift            # Colors, typography, spacing tokens
├── Assets.xcassets/                  # App icon, brand assets, platform icons, hero images

MilliTaxVaultTests/                  # QuarterlyTaxEstimator XCTest suite (21 tests)
backend/migrations/                   # SQL migrations (mileage logs, brokerage trading)
scripts/                             # Screen capture, Swift validation, repo health checks
```

## Design System

- Background: `#080B12` with subtle radial gradients
- Accent: `#00B4FF` (Electric Cyan) & Emerald Green (`#00E599`)
- Cards: Frosted glass with subtle stroke glow and chrome finishes
- Typography: Sora for financial metrics, Inter for UI text
- Charts: Swift Charts with cyan/emerald gradient fill
- Navigation: Custom brush-chrome center `M` button with custom tab routing (`MilliNavBar.swift`)

## Validation & Quality Assurance

- **Native Build CI**: Automated Xcode build validation on macOS runners (`.github/workflows/validate.yml`)
- **Visual QA**: SwiftUI visual QA workflow (`.github/workflows/swiftui-visual-qa.yml`) plus comprehensive UI screen capture and integrity verification suite (`scripts/verify-milli-screen-captures.sh`)
- **Unit Tests**: QuarterlyTaxEstimator XCTest suite (`MilliTaxVaultTests/`)
- **Repository Health**: Architecture and reference verification script (`scripts/verify-repo-health.sh`)

## Requirements

- Xcode 15.4+
- iOS 17.0+
- Swift 5.9+
