# Milli — iOS Native Build Guide

This wraps the existing React PWA into a real iOS binary using **Capacitor v7**.
The web app continues to work standalone; the native shell unlocks **background GPS** for
continuous mileage tracking while the phone is locked or in your pocket.

---

## Prerequisites

- **macOS** with Xcode 15+ (App Store)
- **Node 20+** (already used by this project)
- **CocoaPods**: `sudo gem install cocoapods` (or `brew install cocoapods`)
- An Apple Developer account ($99/yr) for device installs + App Store distribution

---

## 1. Clone & install

```bash
git clone <your-repo>
cd milli/frontend
yarn install
```

The iOS Xcode project lives at `frontend/ios/` and is checked in.

---

## 2. Build the web assets

Capacitor copies the contents of `build/` into the iOS bundle.

```bash
cd frontend
yarn build           # outputs to /app/frontend/build
npx cap copy ios     # copies build/ -> ios/App/App/public
npx cap sync ios     # also updates native plugins
```

Re-run `yarn build && npx cap copy ios` every time you change React code.

---

## 3. Install CocoaPods deps (first time only)

```bash
cd frontend/ios/App
pod install
```

This wires `@capacitor-community/background-geolocation`, `@capacitor/splash-screen`,
`@capacitor/status-bar`, `@capacitor/app`, `@capacitor/preferences` into the Xcode workspace.

---

## 4. Open in Xcode

```bash
cd frontend
npx cap open ios
```

This opens `ios/App/App.xcworkspace` in Xcode.

### Configure signing
1. Click the **App** target → **Signing & Capabilities**
2. Select your Apple Developer **Team**
3. Bundle identifier is preset to `app.milli.tax` — change if your team already owns it
4. Required capabilities (already in `Info.plist`):
   - Background Modes → **Location updates**, **Background fetch**, **Background processing**
   - Privacy keys for location (Always + WhenInUse), motion

### Run on a real device
GPS in the simulator is faked — to test background mileage you **must** run on a physical iPhone.

1. Plug in iPhone, trust the Mac
2. Pick your device in the Xcode toolbar
3. ⌘R to build and run

---

## 5. Pointing the native shell at the API

The web build already reads `REACT_APP_BACKEND_URL` from `frontend/.env` at build time, so the
compiled bundle ships with the production URL baked in. Just make sure that env var points to your
**deployed** FastAPI before `yarn build`.

---

## 6. App Store submission checklist

- [ ] Replace placeholder app icons in `ios/App/App/Assets.xcassets/AppIcon.appiconset`
- [ ] Replace launch screen in `ios/App/App/Assets.xcassets/Splash.imageset`
- [ ] Bump `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` in Xcode → General
- [ ] Add a **Privacy Policy URL** in App Store Connect (required for location)
- [ ] Justify background location use in the App Review notes — Milli needs it for
      automatic mileage logging while the driver is on a gig run
- [ ] Configure **Apple In-App Purchases** for the Basic / Pro / Elite plans
      (see `IAP_INTEGRATION.md` — coming next)

---

## Background GPS — how it works

`src/native/mileageTracker.js` wraps `@capacitor-community/background-geolocation`.

- `startTrip(onLocation, onError)` → registers a watcher with `distanceFilter: 10m`
  and a foreground service notification on Android / persistent indicator on iOS.
- iOS keeps the watcher alive even when the app is suspended; the OS wakes it on
  significant location changes.
- `stopTrip()` removes the watcher and clears the saved id from `localStorage`.

The web (browser) fallback continues to use `navigator.geolocation.watchPosition`,
which only works while the tab is open and foregrounded.
