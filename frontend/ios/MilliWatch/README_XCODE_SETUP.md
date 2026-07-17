# Milli Watch — Xcode Setup (5 min)

The **Swift source files are ready** in `/app/frontend/ios/MilliWatch/`.
Because Xcode owns target creation (with all its interlinked build phases,
capabilities, and framework references), the owner has to add the watch
target through Xcode's Target wizard. This takes 5 minutes.

## Files already prepared (drop-in ready)

```
/app/frontend/ios/MilliWatch/
├── MilliWatchApp.swift          @main SwiftUI entry point
├── ContentView.swift            3-tab UI (Live Trip · Tax Ready · Autopilot)
├── WatchSession.swift           WatchConnectivity — talks to the phone
├── TripState.swift              Observable trip timer + distance
├── TaxReadyComplication.swift   WidgetKit complication (circular/inline/corner)
├── Info.plist                   watchOS bundle with companion bundle ID
└── Assets.xcassets/
    └── AppIcon.appiconset/      15 watch icon sizes + 1024 master
```

## Step-by-step in Xcode

1. Open **`ios/App/App.xcworkspace`** (already the workspace you use).
2. **File → New → Target**
3. Pick **watchOS → App** (SwiftUI, watchOS 10.0 minimum).
4. Fill in the wizard:
   - **Product Name:** `MilliWatch`
   - **Team:** your Apple Developer team
   - **Bundle Identifier:** `app.milli.tax.watchkitapp`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Include Notification Scene:** ✅
   - **Include Complication:** ✅ (this creates a WidgetKit extension)
5. Click **Finish**. Xcode creates a fresh `MilliWatch` folder inside the
   project.
6. **Delete the stub files** Xcode generated (`ContentView.swift`,
   `MilliWatchApp.swift`, `Assets.xcassets`, `Info.plist`).
7. **Right-click the MilliWatch group → Add Files to "App"**, and select
   every file in `/app/frontend/ios/MilliWatch/` (source files + Assets +
   Info.plist). Make sure **Target Membership → MilliWatch** is checked.
8. In the MilliWatch target's **General** tab, set the **Info.plist file**
   path to the one you just imported.
9. In **Build Phases → Copy Bundle Resources**, make sure
   `Assets.xcassets` is listed once.
10. Product → Run (⌘R) with the Watch simulator selected. The Milli
    watch UI should boot with the three tabs.

## Connectivity between phone and watch

Both apps use Apple's `WatchConnectivity` framework, no code changes
required on the phone side. When the Watch sends `start_trip` /
`stop_trip`, the phone app receives it via the standard `WCSession`
delegate and forwards it to the existing Capacitor plugin
(`@capacitor-community/background-geolocation`).

If you want the phone side to broadcast Tax Ready Score to the watch,
add a tiny hook in `frontend/src/App.js` that calls a native bridge
whenever the dashboard snapshot updates. This is optional — the watch
will also poll the backend directly through the same session token.

## Bundle IDs summary

| Target | Bundle ID |
|---|---|
| iPhone / iPad app | `app.milli.tax` |
| Watch app | `app.milli.tax.watchkitapp` |
| Watch complication extension | `app.milli.tax.watchkitapp.complication` |

## Submission

The watch app is submitted **as part of the same App Store Connect
version** as the iPhone app — no separate listing. Just archive the
main scheme (which includes the embedded watch target) and Xcode will
upload both.
