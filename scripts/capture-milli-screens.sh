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
SCREEN_SETTLE_SECONDS="${SCREEN_SETTLE_SECONDS:-4}"

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

show_recent_app_logs() {
  echo "Recent MilliTaxVault simulator logs:" >&2
  xcrun simctl spawn "$SIMULATOR_UDID" log show \
    --style compact \
    --last 20s \
    --predicate 'process == "MilliTaxVault"' 2>/dev/null | tail -n 160 >&2 || true
}

capture_screen() {
  local screen="$1"
  local output="$OUTPUT_DIR/${screen}.png"
  local launch_output
  local pid

  xcrun simctl terminate "$SIMULATOR_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

  launch_output="$(xcrun simctl launch \
    "$SIMULATOR_UDID" \
    "$BUNDLE_ID" \
    -milliScreenshotMode \
    -milliScreen "$screen")"

  echo "$launch_output"
  pid="$(printf '%s\n' "$launch_output" | awk -F': ' 'NF > 1 {print $NF}' | tail -n 1)"

  # A 1.5-second fixed delay proved too short for a few cold SwiftUI launches on
  # hosted Xcode 26 simulators and captured the white launch screen. Give every
  # screen a deterministic render window, then verify the launched process is
  # still alive before accepting the screenshot.
  sleep "$SCREEN_SETTLE_SECONDS"

  if [[ "$pid" =~ ^[0-9]+$ ]] && ! ps -p "$pid" >/dev/null 2>&1; then
    echo "MilliTaxVault exited before '$screen' was ready (pid $pid)." >&2
    show_recent_app_logs
    exit 1
  fi

  xcrun simctl io "$SIMULATOR_UDID" screenshot "$output" >/dev/null
  test -s "$output"
  echo "Captured $screen -> $output"
}

for screen in "${SCREENS[@]}"; do
  capture_screen "$screen"
done

echo
echo "Milli screen capture complete."
echo "Output directory: $OUTPUT_DIR"
