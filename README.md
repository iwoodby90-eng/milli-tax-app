# Milli Tax Vault

A premium iOS fintech app for freelancers and gig workers to automatically set aside taxes from their earnings.

## Architecture

Pure SwiftUI, iOS 17+, Swift Charts.

## Project Structure

```
MilliTaxVault/
├── MilliApp.swift                  # App entry point
├── ContentView.swift               # Root view & custom navigation coordinator
├── Views/
│   ├── VaultView.swift             # Tax vault balance & transfers
│   ├── WealthView.swift            # Net worth & spending overview
│   ├── ActivityView.swift          # Income sources & payouts
│   ├── CockpitView.swift           # Settings & profile
│   ├── TaxVaultView.swift          # Tax reserve and breakdown
│   ├── OnboardingFlowView.swift    # Multi-step setup flow
│   ├── TreeOfLifeView.swift        # Financial health visualizer
│   └── Components/
│       ├── MilliCard.swift         # Reusable card component
│       ├── CircularProgressView.swift # Animated progress ring
│       ├── MilliChart.swift        # Area chart & sparklines
│       └── MilliNavBar.swift       # Canonical custom bottom navigation bar
├── Models/
│   ├── AppModels.swift             # Core financial and transaction models
│   ├── TaxProfile.swift            # Tax filing status and subscription tiers
│   └── VehicleProfile.swift        # Vehicle mileage deduction tracking
├── Theme/
│   ├── MilliTheme.swift            # Colors, typography, spacing tokens
│   └── DesignSystem/               # MilliColors, MilliTypography, MilliSpacing
└── Assets.xcassets/                # App icon, accent colors, and design tokens
```

## Design System

- Background: `#080B12` with subtle radial gradients
- Accent: `#00B4FF` (Electric Cyan) & Emerald Green (`#00E599`)
- Cards: Frosted glass with subtle stroke glow and chrome finishes
- Typography: SF Pro Rounded for financial metrics, SF Pro / Inter for UI text
- Charts: Swift Charts with cyan/emerald gradient fill
- Navigation: Custom brushed-chrome center `M` button with custom tab routing (`MilliNavBar.swift`)

## Validation & Quality Assurance

- **Native Build CI**: Automated Xcode build validation on macOS runners (`.github/workflows/validate.yml`)
- **Visual QA**: Comprehensive UI screen capture and integrity verification suite (`scripts/verify-milli-screen-captures.sh`)
- **Repository Health**: Architecture and reference verification script (`scripts/verify-repo-health.sh`)

## Requirements

- Xcode 15.4+
- iOS 17.0+
- Swift 5.9+
