# Milli iOS Release Readiness

This checklist is the release gate for App Store builds. A build is not release-ready until every required item is verified on a physical device and in an Xcode Archive.

## Xcode target

- Add `PrivacyInfo.xcprivacy` to the App target's Copy Bundle Resources phase.
- Set **Code Signing Entitlements** to `App/App.entitlements` for Debug and Release.
- Enable **In-App Purchase** in Signing & Capabilities.
- Keep only the **Location updates** background mode unless another mode has a tested implementation and documented review justification.
- Confirm the deployment target and supported devices match the App Store listing.
- Run Product > Analyze and resolve all actionable warnings.
- Archive with the Release configuration and validate the archive before upload.

## StoreKit

- Product identifiers must be exactly:
  - `milli.basic.monthly`
  - `milli.pro.monthly`
  - `milli.elite.monthly`
- Product availability and localized prices must come from StoreKit on iOS.
- The server must verify transactions and remain the entitlement authority.
- Implement Restore Purchases and test it using a separate sandbox Apple ID.
- Test purchased, pending, cancelled, refunded, expired, billing-retry, grace-period, and family-device scenarios.
- Do not unlock digital functionality from client-controlled plan data.

## Privacy and security

- Reconcile `PrivacyInfo.xcprivacy` with the final App Store privacy questionnaire and every third-party SDK manifest.
- Store authentication tokens and other secrets in Keychain-backed secure storage, never Local Storage or Preferences.
- Use a permanent production API hostname, not a preview environment.
- Verify account deletion, data export, privacy policy, and support URLs in the production build.
- Confirm logs, crash reports, screenshots, and analytics do not contain financial or authentication data.

## Mileage

- Test foreground, background, terminated-app, low-power, denied-permission, approximate-location, and permission-upgrade flows.
- Show a clear in-app indicator whenever automatic mileage tracking is active.
- Provide an obvious control to stop automatic tracking.
- Verify battery impact on a physical device over a representative workday.

## Accessibility

- Test VoiceOver in every primary flow.
- Verify Dynamic Type without clipping or inaccessible controls.
- Verify Reduce Motion, Increase Contrast, Bold Text, and Button Shapes.
- Ensure all interactive targets are at least 44 by 44 points.
- Ensure status is never communicated by color alone.

## Final validation

- Test clean install, upgrade, logout/login, password reset, offline launch, interrupted purchase, restored purchase, background mileage, and account deletion.
- Capture App Store screenshots from the release candidate, not mock data that misrepresents functionality.
- Complete TestFlight internal testing before external review.
