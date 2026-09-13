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
SWIFT_CHECK="$(mktemp -t milli-screen-sanity).swift"
trap 'rm -f "$HASH_FILE" "$SWIFT_CHECK"' EXIT

cat > "$SWIFT_CHECK" <<'SWIFT'
import AppKit
import Foundation

var failed = false

for path in CommandLine.arguments.dropFirst() {
    guard let image = NSImage(contentsOfFile: path),
          let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else {
        fputs("Unable to decode screenshot: \(path)\n", stderr)
        failed = true
        continue
    }

    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh
    let stepX = max(width / 48, 1)
    let stepY = max(height / 80, 1)

    var samples = 0
    var nearWhite = 0
    var luminanceSum = 0.0
    var luminanceSquaredSum = 0.0

    for y in stride(from: 0, to: height, by: stepY) {
        for x in stride(from: 0, to: width, by: stepX) {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            let r = Double(color.redComponent)
            let g = Double(color.greenComponent)
            let b = Double(color.blueComponent)
            let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b

            samples += 1
            luminanceSum += luma
            luminanceSquaredSum += luma * luma
            if r > 0.94 && g > 0.94 && b > 0.94 { nearWhite += 1 }
        }
    }

    guard samples > 0 else {
        fputs("No pixels sampled from screenshot: \(path)\n", stderr)
        failed = true
        continue
    }

    let whiteRatio = Double(nearWhite) / Double(samples)
    let mean = luminanceSum / Double(samples)
    let variance = max(0.0, luminanceSquaredSum / Double(samples) - mean * mean)

    // Milli is a dark interface. A capture that is overwhelmingly white with
    // almost no tonal variance is the simulator launch screen/SpringBoard, not
    // a valid product surface.
    if whiteRatio > 0.88 && variance < 0.025 {
        fputs(String(format: "Screenshot is effectively blank white (%.1f%% white): %@\n", whiteRatio * 100, path), stderr)
        failed = true
    }
}

if failed { exit(1) }
SWIFT

FILES=()
for name in "${EXPECTED[@]}"; do
  file="$CAPTURE_DIR/$name.png"
  if [[ ! -s "$file" ]]; then
    echo "Missing screenshot: $file" >&2
    exit 1
  fi

  # A full iPhone simulator PNG with the Milli UI is normally far larger than
  # this. Very small PNGs are commonly blank/solid launch-screen captures.
  size="$(stat -f%z "$file")"
  if (( size < 30000 )); then
    echo "Screenshot looks suspiciously small ($size bytes): $file" >&2
    exit 1
  fi

  FILES+=("$file")
  shasum -a 256 "$file" >> "$HASH_FILE"
done

# Pixel-level sanity check catches cases where the status bar makes a blank white
# launch screen large enough to evade the simple PNG byte-size threshold.
swift "$SWIFT_CHECK" "${FILES[@]}"

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
