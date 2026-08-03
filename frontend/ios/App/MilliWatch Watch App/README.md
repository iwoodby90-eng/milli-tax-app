# Milli Watch — Apple Watch Companion Setup

The Watch app lives at `ios/App/MilliWatch Watch App/` and mirrors the iPhone
app's Milli Tax Vault™ balance + earning streak on the wrist via WatchKit
+ WidgetKit complications.

## What's included

| File | Purpose |
|------|---------|
| `MilliWatchApp.swift`            | SwiftUI `@main` entry point for the paired watch app |
| `WatchContentView.swift`         | Main watch screen — Vault balance, this-month delta, streak flame, cyan progress ring |
| `MilliWatchComplication.swift`   | WidgetKit complications for `accessoryCircular`, `accessoryInline`, `accessoryRectangular`, `accessoryCorner` |

## Data flow

```
 React (Vault.jsx / Dashboard.jsx)
        │  MilliVaultBridge.update({ balance, goal, thisMonth, streak, firstName })
        ▼
 iOS Capacitor plugin (MilliVaultBridgePlugin.swift)
        │  writes → UserDefaults(suiteName: "group.app.milli.tax")
        ▼
 Watch app + complication (WatchSnapshot.read(from:))
        │  WidgetCenter.reloadAllTimelines() refreshes complications
        ▼
        Apple Watch face + full-screen app
```

## One-time Xcode setup

1. Open `ios/App/App.xcworkspace` in Xcode 15+.
2. **Add the Watch target**:
   `File → New → Target → watchOS → App`
   - Product Name: **MilliWatch**
   - Interface: SwiftUI · Language: Swift · Include Notification Scene: OFF
3. **Add the Complication target** (second target):
   `File → New → Target → watchOS → Widget Extension`
   - Product Name: **MilliWatchComplication**
   - Include Configuration Intent: OFF · Include Live Activity: OFF
4. **Wire the App Group** on all three targets — `App`, `MilliWatch`, `MilliWatchComplication`:
   Signing & Capabilities → `+ Capability → App Groups → group.app.milli.tax`.
5. **Replace the auto-generated files** in `MilliWatch Watch App/` with the three files already committed in this folder.
6. **Signing**: pick your Team on both new targets. Suggested bundle IDs:
   - `app.milli.tax.watchkitapp`
   - `app.milli.tax.watchkitapp.MilliWatchComplication`
7. Product → Run → select a paired Watch simulator or device.

## First run

- Launch the iPhone app once — the Vault snapshot is written to the shared App
  Group on the very first `/api/tax/summary` fetch (see `Dashboard.jsx` line ~44).
- Long-press the watch face → **Edit** → add the **Milli Vault** complication
  in any of the four supported slots.
- Raise your wrist — you'll see `$X,XXX.XX · 🔥N-day streak · YY% of goal` live.

## Refresh cadence

- App-driven push: every mutation to `MilliVaultBridge.update(...)` calls
  `WidgetCenter.shared.reloadTimelines(ofKind: "MilliWatchComplication")`.
- WatchKit poll: `getTimeline` returns `.after(15min)` as a safety net.
