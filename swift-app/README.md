# Milli Tax Vault — Native SwiftUI App

## Xcode Setup (60 seconds)
1. Open Xcode → File > New > Project → iOS App
2. Set: Interface = SwiftUI, Language = Swift, Minimum iOS = 17.0
3. Delete the default ContentView.swift from the project
4. Drag ALL .swift files from this MilliTaxVault/ folder into your Xcode project
5. In the dialog: check "Copy items if needed", target = your app target
6. Add the Charts framework: Project > Target > Frameworks > + > Charts
7. Build and run (Cmd+R)

## Screens
- Home / Dashboard
- Payouts
- Tax Vault
- Milli AI (floating assistant)
- Mileage Tracker (MapKit)
- Milli Cents (Savings)
- Expenses
- Reports
- Investing (Swift Charts candlestick)
- Retirement Projection
- Wealth Overview
- Tree of Life
- Life Events Timeline
- Planning Adjustments
- Your Future

## Notes
- Map uses Apple MapKit natively — no API key required
- Charts use Apple Swift Charts — included in iOS 16+ SDK
- Live market data: replace LIVE_API_PLACEHOLDER comments with TwelveData API
- All mock data clearly marked for easy replacement
