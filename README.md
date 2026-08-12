# Milli Tax Vault

A premium iOS fintech app for freelancers and gig workers to automatically set aside taxes from their earnings.

## Architecture

Pure SwiftUI, iOS 17+, Swift Charts.

## Project Structure

```
MilliTaxVault/
├── MilliTaxVaultApp.swift          # App entry point
├── ContentView.swift               # Tab bar + floating AI button
├── Views/
│   ├── VaultView.swift             # Tax vault balance & transfers
│   ├── WealthView.swift            # Net worth & spending overview
│   ├── ActivityView.swift          # Income sources & payouts
│   ├── CockpitView.swift           # Settings & profile
│   └── Components/
│       ├── MilliCard.swift         # Reusable card component
│       ├── CircularProgressView.swift  # Animated progress ring
│       ├── MilliChart.swift        # Area chart & sparkline
│       └── NavBar.swift            # Custom bottom navigation
├── Models/
│   └── AppModels.swift             # All data models
├── Theme/
│   └── MilliTheme.swift            # Colors, fonts, gradients
└── Assets.xcassets/                # App icon & accent color
```

## Design System

- Background: #080B12 with radial gradient
- Accent: #00B4FF (cyan)
- Cards: frosted glass with cyan stroke glow
- Typography: SF Pro Rounded for numbers, SF Pro for text
- Charts: Swift Charts with cyan gradient fill
- Nav: Custom brushed-chrome center M button, 4 icon tabs

## Requirements

- Xcode 15.4+
- iOS 17.0+
- Swift 5.9+
