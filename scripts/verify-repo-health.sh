#!/usr/bin/env bash
set -euo pipefail

echo "=== Milli Tax Vault Repository Health Check ==="

# Verify essential files exist
REQUIRED_FILES=(
  "MilliTaxVault.xcodeproj/project.pbxproj"
  "MilliTaxVault/MilliApp.swift"
  "MilliTaxVault/ContentView.swift"
  "MilliTaxVault/Components/MilliNavBar.swift"
  "MilliTaxVault/Models/AppModels.swift"
  "MilliTaxVault/Models/TaxProfile.swift"
  "MilliTaxVault/Models/VehicleProfile.swift"
  "MilliTaxVault/Theme/MilliTheme.swift"
  "README.md"
  ".github/workflows/validate.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "❌ Missing required file: $file" >&2
    exit 1
  fi
  echo "✅ Found: $file"
done

# Ensure deprecated BottomNavBar is not referenced in active source code
if grep -rn "BottomNavBar" MilliTaxVault/ >/dev/null 2>&1; then
  echo "❌ Found obsolete BottomNavBar reference in MilliTaxVault sources" >&2
  exit 1
fi
echo "✅ No obsolete BottomNavBar references in source code"

echo "=== All repository health checks passed ==="
