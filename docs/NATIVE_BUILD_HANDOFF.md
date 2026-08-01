# Native Build Handoff

After merging this branch, run the following from `frontend` on the development Mac:

```bash
yarn install --frozen-lockfile
yarn build
npx cap sync ios
open ios/App/App.xcworkspace
```

In Xcode:

1. Select the App target.
2. Set Code Signing Entitlements to `App/App.entitlements` for Debug and Release.
3. Confirm `PrivacyInfo.xcprivacy` has App target membership and appears in Copy Bundle Resources.
4. Enable In-App Purchase and Location updates capabilities.
5. Confirm the correct Apple Developer team, bundle identifier, marketing version, and build number.
6. Build on a physical iPhone, then run Product > Analyze.
7. Archive using Release and run Validate App.

The connected GitHub environment can harden source and project assets, but it cannot truthfully certify signing, provisioning, StoreKit sandbox configuration, physical-device background behavior, or a successful Xcode archive. Those are release gates, not optional polish.
