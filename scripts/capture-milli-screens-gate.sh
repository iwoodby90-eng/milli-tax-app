#!/usr/bin/env bash
set -euo pipefail

# QA-only wrapper (PR #66 runtime visual gate).
# Selects a simulator by device-class preference instead of the default
# "first available iPhone", then runs the existing capture + verify flow.
#
# Usage:
#   SIMULATOR_DEVICE="iPhone 17" OUTPUT_DIR=/tmp/milli-screen-qa bash scripts/capture-milli-screens-gate.sh
#
# Device-class preference (first match wins):
#   compact : smallest iPhone (16e/17e-class, then SE, then Mini)
#   standard: iPhone 17/17 Pro-class, then any non-Max iPhone
#   promax  : iPhone Pro Max-class
# If SIMULATOR_DEVICE is set explicitly, it must resolve to the EXACT
# simulator name (e.g. "iPhone 17", never a substring match like
# "iPhone 17 Pro").

PROJECT="${PROJECT:-MilliTaxVault.xcodeproj}"
SCHEME="${SCHEME:-MilliTaxVault}"
BUNDLE_ID="${BUNDLE_ID:-com.milli.taxvault}"
OUTPUT_DIR="${OUTPUT_DIR:-$RUNNER_TEMP/milli-screen-qa}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/MilliVisualQADerivedData}"
SCREEN_SETTLE_SECONDS="${SCREEN_SETTLE_SECONDS:-4}"
MAP_SETTLE_SECONDS="${MAP_SETTLE_SECONDS:-7}"

DEVICE_CLASS="${DEVICE_CLASS:-standard}"

# PR #66 gate evidence set: five nav states + full MILLI AI screen.
# Output filenames use the display names (payouts/mileage/more) for stable
# evidence naming; capture-milli-screens.sh maps them to the raw
# ActiveScreen values accepted by the app's -milliScreen launch-argument
# router (ContentView). The production routes are:
#   Payouts -> vault, Mileage -> activity, Home -> home,
#   Wealth -> wealthOverview, More -> cockpit, MILLI AI -> milliAI.
# The floating MILLI AI companion appears in the normal app shell, so it is
# captured as part of each nav-state screenshot.
GATE_SCREENS=(
  home
  payouts
  mileage
  wealthOverview
  more
  milliAI
)

select_simulator_for_class() {
  local class="$1"
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

def pick_exact(candidates, names):
    for d in candidates:
        if d["name"] in names:
            return d
    return None

def pick_sub(candidates, must_any, must_none):
    for d in candidates:
        n = d["name"]
        if any(m in n for m in must_any) and not any(m in n for m in must_none):
            return d
    return None

cls = sys.argv[1]
if cls == "compact":
    d = (pick_sub(candidates, ["16e", "17e"], [])
         or pick_sub(candidates, ["SE"], [])
         or pick_sub(candidates, ["mini", "Mini"], []))
elif cls == "promax":
    d = pick_sub(candidates, ["Pro Max"], [])
else:
    # standard: prefer the EXACT "iPhone 17" (never "iPhone 17 Pro"),
    # then any non-Max iPhone 17/16, then any non-Max iPhone.
    d = (pick_exact(candidates, ["iPhone 17"])
         or pick_sub(candidates, ["iPhone 17", "iPhone 16"], ["Max"])
         or pick_sub(candidates, ["iPhone"], ["Max"]))
if d is None:
    d = candidates[0]
print(d["udid"])
' "$class"
}

if [[ -n "${SIMULATOR_DEVICE:-}" ]]; then
  # Resolve by EXACT simulator name only — a substring grep would let
  # "iPhone 17" silently match "iPhone 17 Pro".
  SIMULATOR_UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
payload = json.load(sys.stdin)
wanted = sys.argv[1]
for runtime, devices in payload.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        if device.get("isAvailable") and device.get("name") == wanted:
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit(1)
' "$SIMULATOR_DEVICE" || true)"
  if [[ -z "$SIMULATOR_UDID" ]]; then
    echo "Requested simulator '$SIMULATOR_DEVICE' not found by exact name; falling back to class selection ($DEVICE_CLASS)." >&2
    SIMULATOR_UDID="$(select_simulator_for_class "$DEVICE_CLASS")"
  fi
else
  SIMULATOR_UDID="$(select_simulator_for_class "$DEVICE_CLASS")"
fi
export SIMULATOR_UDID

echo "Using simulator: $SIMULATOR_UDID (class: $DEVICE_CLASS, requested: ${SIMULATOR_DEVICE:-auto})"

# Delegate the actual build/capture to the existing, proven script.
# It honors SIMULATOR_UDID, OUTPUT_DIR, PROJECT, SCHEME, BUNDLE_ID,
# DERIVED_DATA and the settle-time variables.
export OUTPUT_DIR PROJECT SCHEME BUNDLE_ID DERIVED_DATA
export SCREEN_SETTLE_SECONDS MAP_SETTLE_SECONDS

bash scripts/capture-milli-screens.sh

# Restrict the uploaded evidence to the PR #66 gate set: keep the five nav
# states + full MILLI AI screen (companion visible in the shell captures).
GATE_DIR="$OUTPUT_DIR-gate"
mkdir -p "$GATE_DIR"
for screen in "${GATE_SCREENS[@]}"; do
  if [[ -s "$OUTPUT_DIR/$screen.png" ]]; then
    cp "$OUTPUT_DIR/$screen.png" "$GATE_DIR/$screen.png"
  else
    echo "Missing gate screenshot: $OUTPUT_DIR/$screen.png" >&2
    exit 1
  fi
done

echo "PR #66 gate capture complete for class '$DEVICE_CLASS'."
echo "Gate output directory: $GATE_DIR"
