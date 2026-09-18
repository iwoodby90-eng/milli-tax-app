#!/usr/bin/env bash
set -euo pipefail

# Fails visual QA when the capture set is incomplete, blank-looking, or clearly
# routed to the same screen repeatedly. This protects against the historical
# failure mode where the workflow itself passed while many PNGs were Home/white.

CAPTURE_DIR="${1:-${OUTPUT_DIR:-artifacts/milli-screen-qa}}"

EXPECTED=(
  home payouts mileage milliCents autopilot expenses taxVault taxReadyScore
  quarterlyTaxes investing retirement wealthOverview treeOfLife milliAI reports
  accounts savings documents plans more auth-login auth-onboarding auth-setup
)

if [[ ! -d "$CAPTURE_DIR" ]]; then
  echo "Capture directory does not exist: $CAPTURE_DIR" >&2
  exit 1
fi

HASH_FILE="$(mktemp)"
trap 'rm -f "$HASH_FILE"' EXIT

for name in "${EXPECTED[@]}"; do
  file="$CAPTURE_DIR/$name.png"
  if [[ ! -s "$file" ]]; then
    echo "Missing screenshot: $file" >&2
    exit 1
  fi

  # Full-screen Milli references in this suite are materially larger than
  # launch/blank frames. The previous 30 KB threshold allowed an 87 KB white
  # Pro Max launch frame to pass, so keep this gate intentionally conservative.
  size="$(stat -f%z "$file")"
  if (( size < 250000 )); then
    echo "Screenshot looks suspiciously small ($size bytes): $file" >&2
    exit 1
  fi

  shasum -a 256 "$file" >> "$HASH_FILE"
done

unique_hashes="$(awk '{print $1}' "$HASH_FILE" | sort -u | wc -l | tr -d ' ')"

if (( unique_hashes < 20 )); then
  echo "Only $unique_hashes unique screenshots were captured for ${#EXPECTED[@]} routes." >&2
  echo "This usually means debug routing collapsed multiple destinations onto one screen." >&2
  cat "$HASH_FILE" >&2
  exit 1
fi

home_hash="$(shasum -a 256 "$CAPTURE_DIR/home.png" | awk '{print $1}')"
for name in "${EXPECTED[@]}"; do
  [[ "$name" == "home" ]] && continue
  hash="$(shasum -a 256 "$CAPTURE_DIR/$name.png" | awk '{print $1}')"
  if [[ "$hash" == "$home_hash" ]]; then
    echo "Route '$name' captured an exact duplicate of Home." >&2
    exit 1
  fi
done

echo "Visual QA capture sanity check passed: ${#EXPECTED[@]} files, $unique_hashes unique screenshots."
