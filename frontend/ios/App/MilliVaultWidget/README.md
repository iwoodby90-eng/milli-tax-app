# Milli Vault Widget — Xcode Integration Guide

The Swift source lives at `MilliVaultWidget/MilliVaultWidget.swift`. Follow these steps in Xcode after opening `App.xcworkspace`:

## 1. Add the Widget Extension target

1. `File → New → Target…`
2. Choose **Widget Extension** → Next
3. Fill in:
   - Product Name: **MilliVaultWidget**
   - Bundle Identifier: **app.milli.tax.MilliVaultWidget**
   - ☐ Include Configuration Intent (leave unchecked)
   - Team: **W5Q42XNM9V**
4. Click **Finish** → activate the scheme when prompted.

## 2. Replace the auto-generated file

- Xcode created a `MilliVaultWidget.swift` inside `MilliVaultWidget/`.
- Delete the file's contents and paste ALL of `MilliVaultWidget/MilliVaultWidget.swift` (from this repo).
- Also delete any auto-generated `MilliVaultWidgetBundle.swift` if present — this single file uses `@main`.

## 3. Enable App Group on BOTH targets

App Groups is what lets the widget read the vault balance the main app writes.

1. Select the **App** target → **Signing & Capabilities** → `+ Capability` → **App Groups**.
2. Add group: `group.app.milli.tax` (check the box).
3. Select the **MilliVaultWidget** target → same steps → same group.

## 4. Write vault data from the main app

Add this to the main iOS app once (e.g. inside `AppDelegate.swift`'s `application(_:didFinishLaunchingWithOptions:)`):

```swift
// One-time bridge: web JS writes into Preferences, we mirror to App Group.
NotificationCenter.default.addObserver(forName: Notification.Name("MilliVaultUpdated"),
                                       object: nil, queue: .main) { note in
    if let payload = note.userInfo as? [String: Any] {
        let d = UserDefaults(suiteName: "group.app.milli.tax")
        d?.set(payload["balance"] as? Double ?? 0, forKey: "vault_balance")
        d?.set(payload["goal"]    as? Double ?? 20000, forKey: "vault_goal")
        d?.set(payload["month"]   as? Double ?? 0, forKey: "vault_month")
        d?.set(Date().timeIntervalSince1970, forKey: "vault_updated")
        WidgetCenter.shared.reloadTimelines(ofKind: "MilliVaultWidget")
    }
}
```

Then in the React frontend, after every `/api/tax/summary` fetch (only when running native), post the update through a tiny bridge — or simpler, save via `@capacitor/preferences` and add a small custom Capacitor plugin that mirrors the values into the shared UserDefaults suite.

Fastest ship: **hard-code the group write directly from the WKWebView plugin bridge** by adding a `MilliVaultBridge` Capacitor plugin (10 lines of Swift). Ping me if you want that code — I'll drop it in.

## 5. Long-press your home screen → +Widget → search "Milli"

You should see two sizes:
- **Small** — "MILLI VAULT" pill, big balance, +this month, cyan progress bar, "X% of $20K"
- **Medium** — same info + polished chrome M glyph on the right

## Preview data

If the App Group values are empty, the widget shows the placeholder (`$1,480.42` / `+$7.38 this month` / 7% progress).

## Refresh cadence

`getTimeline` returns `.after(now + 30 min)` so the widget reloads automatically. Force a reload anytime with `WidgetCenter.shared.reloadTimelines(ofKind: "MilliVaultWidget")`.
