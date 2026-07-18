# Milli — iOS Build & App Store Submission Guide

The Capacitor scaffold is complete. This guide takes the owner from a
fresh Mac to a signed, uploaded App Store build in about 45 minutes.

---

## 0 · Prerequisites

- **macOS Sonoma 14.5+** with **Xcode 15.4+**
- **Apple Developer account** ($99/yr) with a valid team
- **CocoaPods**: `sudo gem install cocoapods` or `brew install cocoapods`
- **Node 20+** (matches the pod build environment)
- A physical iPhone if you want to test background GPS (the simulator
  fakes GPS)

---

## 1 · Sync the latest web build

Every time the React code changes, re-copy it into the iOS project:

```bash
cd /app/frontend
yarn install                # first time only
yarn build                  # outputs to /app/frontend/build
npx cap copy ios            # copies build/ → ios/App/App/public
npx cap sync ios            # copies + syncs plugin native pods
```

Verify the sync log lists all 5 Capacitor plugins:
`background-geolocation`, `app`, `preferences`, `splash-screen`, `status-bar`.

## 2 · Open in Xcode

```bash
cd /app/frontend
npx cap open ios
```

This opens **`ios/App/App.xcworkspace`** (never open the `.xcodeproj`
directly — Capacitor uses the workspace so CocoaPods can inject).

## 3 · Apple Developer team (already wired)

The owner's Apple Developer credentials are **already injected** into
the Xcode project so you should see them pre-selected on first open:

| Setting | Value |
|---|---|
| **Apple Developer Team ID** | `5GV6Z3S674` |
| **Apple ID / App Store Connect** | `iwoodby90@gmail.com` |
| **Bundle Identifier (iPhone/iPad)** | `app.milli.tax` |
| **Bundle Identifier (Watch)** | `app.milli.tax.watchkitapp` |
| **Bundle Identifier (Watch Complication)** | `app.milli.tax.watchkitapp.complication` |
| **Signing style** | Automatic |

1. In Xcode's left sidebar, select the **App** project → the **App**
   target → the **Signing & Capabilities** tab.
2. Confirm **Team** shows the account belonging to Team ID
   `5GV6Z3S674`. If Xcode prompts you to sign in, use the Apple ID
   `iwoodby90@gmail.com`.
3. Xcode will auto-provision the signing certificate and profile.
4. If the team dropdown is blank, quit Xcode, run
   `sudo xcode-select --reset`, sign in via **Xcode → Settings →
   Accounts** with `iwoodby90@gmail.com`, reopen the workspace, and
   the team will populate.

The following capabilities are already declared in `Info.plist` and
just need to appear in the Capabilities list:
- **Background Modes** → Location updates, Background fetch, Background
  processing (auto-enabled by the plist keys)
- **Privacy — Location Always & When In Use** description
- **Privacy — Location When In Use** description
- **Privacy — Motion Usage** description

## 4 · Install CocoaPods dependencies (first time only)

```bash
cd /app/frontend/ios/App
pod install
```

This is what wires `@capacitor-community/background-geolocation` and
friends into the Xcode workspace. Re-run this any time you upgrade a
Capacitor plugin.

## 5 · Verify project settings

Confirm these values in Xcode → App target → General:

| Setting | Expected |
|---|---|
| **Display name** | Milli |
| **Bundle identifier** | app.milli.tax |
| **Version** | 1.0.0 |
| **Build** | 1 |
| **Minimum deployments** | iOS 16.0 |
| **iPhone orientations** | Portrait, Landscape L/R |
| **Interface style** | Dark |

## 6 · Run on your iPhone (recommended before archiving)

1. Plug in the iPhone, trust the Mac when prompted.
2. Pick the device in the Xcode toolbar (top center).
3. **⌘R** to build and run.
4. On first launch, iOS will prompt for location + motion permissions —
   grant them so you can exercise the mileage engine.
5. Start a trip from the Mileage screen, put the phone in your pocket,
   drive for a mile, then end the trip. You should see distance +
   deduction populated with no interaction while backgrounded.

Any Swift/Info.plist issues here surface immediately in Xcode's
Report Navigator.

## 7 · Archive & upload to App Store Connect

1. In Xcode's toolbar, set the destination to **Any iOS Device
   (arm64)** (do NOT pick a simulator).
2. **Product → Archive**. When it finishes, the Organizer window
   opens.
3. In Organizer, select the new archive and click **Distribute App**.
4. Pick **App Store Connect → Upload**.
5. Automatic signing → Next → Upload.
6. Wait 5–10 minutes for App Store Connect to finish processing the
   build (you'll get an email).

### Optional: command-line export using `ExportOptions.plist`

The repo ships `/app/frontend/ios/App/ExportOptions.plist` pre-filled
with Team ID `5GV6Z3S674` and the three Milli bundle identifiers, so
you can drive the upload from a script:

```bash
cd /app/frontend/ios/App

# 1. Archive
xcodebuild -workspace App.xcworkspace \
           -scheme App \
           -configuration Release \
           -destination "generic/platform=iOS" \
           -archivePath ./build/Milli.xcarchive \
           archive

# 2. Export a signed .ipa using the pre-baked ExportOptions.plist
xcodebuild -exportArchive \
           -archivePath ./build/Milli.xcarchive \
           -exportPath ./build/ipa \
           -exportOptionsPlist ./ExportOptions.plist

# 3. Upload to App Store Connect using an app-specific password.
#    Generate one at https://appleid.apple.com → Sign-in & Security →
#    App-Specific Passwords, then export it as APP_STORE_PASSWORD.
xcrun altool --upload-app \
             --type ios \
             --file ./build/ipa/App.ipa \
             --username iwoodby90@gmail.com \
             --password "$APP_STORE_PASSWORD"
```

## 8 · App Store Connect submission

Everything you need to paste is in **`/app/APP_STORE_METADATA.md`**:
- App name, subtitle, description, keywords, promo text
- Category, age rating, encryption disclosure
- Reviewer notes (why background location is required)
- Suggested screenshots
- Data collection matrix for the App Privacy section

Set the processed build as the **1.0.0** release, upload 3–10
screenshots per required device size, then hit **Submit for Review**.

Typical review turnaround: 24–72 hours.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Xcode: "Provisioning profile doesn't include app.milli.tax" | Your team doesn't own that Bundle ID. Change it to `com.<yourteam>.milli` in Signing & Capabilities. |
| CocoaPods: "Unable to find spec" | `cd ios/App && pod repo update && pod install` |
| Background GPS not firing | Make sure the user granted **Always** (not just When In Use) — walk them into Settings → Milli → Location → Always. |
| Archive shows an old version | Bump `CURRENT_PROJECT_VERSION` in the App target's build settings (must be greater than any previously uploaded build). |
| "Missing Purpose String" from App Review | All 4 usage strings are already in Info.plist. If Apple flags one, edit the string and resubmit — no rebuild needed for description-only changes. |

---

## What lives where

```
/app/frontend/
├── build/                          # yarn build output (copied into iOS bundle)
├── capacitor.config.json           # appId, appName, plugin config
├── ios/App/
│   ├── App.xcworkspace             # open THIS in Xcode
│   ├── App.xcodeproj/              # do not open directly
│   ├── App/
│   │   ├── Info.plist              # permission strings + background modes
│   │   ├── Base.lproj/
│   │   │   └── LaunchScreen.storyboard   # dark noir + centered M
│   │   ├── Assets.xcassets/
│   │   │   └── AppIcon.appiconset/       # 16 icon sizes + 1024 master
│   │   └── public/                       # copied React build (do not edit)
│   └── Podfile                     # Capacitor + community plugins
└── src/                            # React source (edit here)
```

---

## Summary — what the owner needs to do on the Mac

1. Clone the repo, `cd frontend`, `yarn install`
2. `yarn build && npx cap sync ios`
3. `npx cap open ios` → set your Apple Developer team → ⌘R on device
4. Product → Archive → Distribute App → Upload to App Store Connect
5. Paste `/app/APP_STORE_METADATA.md` into App Store Connect, add
   screenshots, submit for review

**Everything below the water line is done: icons (16 sizes + 1024
master), launch screen (dark + centered M), Info.plist (bundle name,
version 1.0.0 build 1, iOS 16 minimum, dark UI, all 4 permission
strings, Background Modes: location + fetch + processing, encryption
exemption declared), Capacitor sync (5 plugins wired), and full
copy-paste metadata for App Store Connect.**
