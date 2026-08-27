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
# If SIMULATOR_DEVICE is set explicitly, it is used verbatim.

PROJECT="${PROJECT:-MilliTaxVault.xcodeproj}"
SCHEME="${SCHEME:-MilliTaxVault}"
BUNDLE_ID="${BUNDLE_ID:-com.milli.taxvault}"
OUTPUT_DIR="${OUTPUT_DIR:-$RUNNER_TEMP/milli-screen-qa}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/MilliVisualQADerivedData}"
SCREEN_SETTLE_SECONDS="${SCREEN_SETTLE_SECONDS:-4}"
MAP_SETTLE_SECONDS="${MAP_SETTLE_SECONDS:-7}"

DEVICE_CLASS="${DEVICE_CLASS:-standard}"

# PR #66 gate screens: five nav states + full MILLI AI screen.
# IMPORTANT: these must be raw ActiveScreen values accepted by the app's
# -milliScreen launch-argument router (ContentView). The production routes are:
#   Payouts -> vault, Mileage -> activity, Home -> home,
#   Wealth -> wealthOverview, More -> cockpit, MILLI AI -> milliAI.
# The previous list (payouts/mileage/more) used display names that are NOT
# valid raw values, so those launches silently fell back to Home.
# The floating MILLI AI companion appears in the normal app shell, so it is
# captured as part of each nav-state screenshot.
GATE_SCREENS=(
  home
  vault
  activity
  wealthOverview
  cockpit
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

def pick(cands, must_any, must_none):
    for d in cands:
        n = d["name"]
        if any(m in n for m in must_any) and not any(m in n for m in must_none):
            return d
    return None

cls = sys.argv[1]
if cls == "compact":
    d = pick(candidates, ["16e", "17e"], []) or pick(candidates, ["SE"], []) or pick(candidates, ["mini", "Mini"], [])
elif cls == "promax":
    d = pick(candidates, ["Pro Max"], [])
else:
    d = pick(candidates, ["iPhone 17"], ["Max"]) or pick(candidates, ["iPhone 16"], ["Max"]) or pick(candidates, ["iPhone 15"], ["Max"])
if d is None:
    d = candidates[0]
print(d["uid"])
' "$class"
}

if [[ -n "${SIMULATOR_DEVICE:-}" ]]; then
  SIMULATOR_UID="$(xcrun simctl list devices available | grep -F "$SIMULATOR_DEVICE" | head -1 | grep -oE '[0-9A-Fa-f-]{36}' | head -1 || true)"
  if [[ -z "$SIMULATOR_UID" ]]; then
    echo "Requested simulator '$SIMULATOR_DEVICE' not found; falling back to class selection ($DEVICE_CLASS)." >&2
    SIMULATOR_UID="$(select_simulator_for_class "$DEVICE_CLASS")"
  fi
else
  SIMULATOR_UID="$(select_simulator_for_class "$DEVICE_CLASS")"
fi
export SIMULATOR_UID

echo "Using simulator: $SIMULATOR_UID (class: $DEVICE_CLASS, requested: ${SIMULATOR_DEVICE:-auto})"

# Delegate the actual build/capture to the existing, proven script.
# It honors SIMULATOR_UID, OUTPUT_DIR, PROJECT, SCHEME, BUNDLE_ID,
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
