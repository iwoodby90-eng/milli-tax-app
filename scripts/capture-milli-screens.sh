#!/usr/bin/env bash
set -euo pipefail

# Captures deterministic native SwiftUI screenshots for Milli's primary screens.
# Usage:
#   bash scripts/capture-milli-screens.sh
#   SIMULATOR_UDID=<udid> bash scripts/capture-milli-screens.sh
#   OUTPUT_DIR=/tmp/milli-visual-qa bash scripts/capture-milli-screens.sh
#
# The app supports -milliScreenshotMode to skip onboarding/login and
# -milliScreen <screen> to launch a specific native screen in DEBUG builds.

PROJECT="${PROJECT:-MilliTaxVault.xcodeproj}"
SCHEME="${SCHEME:-MilliTaxVault}"
BUNDLE_ID="${BUNDLE_ID:-com.milli.taxvault}"
OUTPUT_DIR="${OUTPUT_DIR:-artifacts/milli-screen-qa}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/MilliVisualQADerivedData}"

SCREENS=(
  home
  payouts
  mileage
  milliCents
  autopilot
  expenses
  taxVault
  taxReadyScore
  quarterlyTaxes
  investing
  retirement
  wealthOverview
  treeOfLife
  milliAI
  reports
  accounts
  savings
  documents
  plans
  more
)

mkdir -p "$OUTPUT_DIR"

select_simulator() {
  if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    printf '%s\n' "$SIMULATOR_UDID"
    return
  fi

  xcrun simctl list devices available -j | python3 -c '
import json, sys
payload = json.load(sys.stdin)
candidates = []
for runtime, devices in payload.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            candidates.append(device)
if not candidates:
    raise SystemExit("No available iPhone simulator found")
preferred = next((d for d in candidates if "Pro" in d["name"] and "Max" not in d["name"]), candidates[0])
print(preferred["udid"])
'
}

SIMULATOR_UDID="$(select_simulator)"
export SIMULATOR_UDID

echo "Using simulator: $SIMULATOR_UDID"

xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR_UDID" -b

rm -rf "$DERIVED_DATA"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/MilliTaxVault.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle not found: $APP_PATH" >&2
  exit 1
fi

xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"

capture_screen() {
  local screen="$1"
  local output="$OUTPUT_DIR/${screen}.png"

  xcrun simctl terminate "$SIMULATOR_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

  xcrun simctl launch \
    "$SIMULATOR_UDID" \
    "$BUNDLE_ID" \
    -milliScreenshotMode \
    -milliScreen "$screen" >/dev/null

  sleep 1.5
  xcrun simctl io "$SIMULATOR_UDID" screenshot "$output" >/dev/null
  echo "Captured $screen -> $output"
}

for screen in "${SCREENS[@]}"; do
  capture_screen "$screen"
done

echo
echo "Milli screen capture complete."
echo "Output directory: $OUTPUT_DIR"
