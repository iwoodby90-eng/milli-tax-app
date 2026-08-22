#!/usr/bin/env bash
set -euo pipefail

echo "=== Milli Tax Vault Repository Health & Domain Check ==="

# Verify essential files exist
REQUIRED_FILES=(
  "MilliTaxVault.xcodeproj/project.pbxproj"
  "MilliTaxVault/MilliTaxVaultApp.swift"
  "MilliTaxVault/ContentView.swift"
  "MilliTaxVault/Domain/Money.swift"
  "MilliTaxVault/Domain/RoundingPolicy.swift"
  "MilliTaxVault/Domain/TaxEngine.swift"
  "MilliTaxVault/Domain/AutopilotEngine.swift"
  "MilliTaxVault/Domain/FinancialInvariant.swift"
  "MilliTaxVaultTests/DomainTests/MoneyTests.swift"
  "MilliTaxVaultTests/DomainTests/RoundingPolicyTests.swift"
  "MilliTaxVaultTests/DomainTests/TaxEngineTests.swift"
  "MilliTaxVaultTests/DomainTests/AutopilotEngineTests.swift"
  "MilliTaxVaultTests/DomainTests/FinancialInvariantTests.swift"
  "scripts/test_financial_engine.py"
  "scripts/validate_all_swift.py"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing required file: $file"
    exit 1
  fi
done

# Verify legacy files were completely removed
REMOVED_FILES=(
  "MilliTaxVault/Views/MilliAIChatView.swift"
  "MilliTaxVault/Views/MilliTaxVaultScreen.swift"
  "MilliTaxVault/Views/MilliTaxVaultView.swift"
  "MilliTaxVault/Views/MileageTrackerView.swift"
  "MilliTaxVault/Views/Components/CircularProgressView.swift"
  "MilliTaxVault/Views/Components/NavBar.swift"
  "MilliTaxVault/Components/MilliBottomBar.swift"
)

for file in "${REMOVED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "❌ Legacy file still exists: $file"
    exit 1
  fi
done

# Verify project.pbxproj is valid and has no shell substitution artifacts
if grep -q '\$(cat /' MilliTaxVault.xcodeproj/project.pbxproj; then
  echo "❌ project.pbxproj contains corrupted shell-substitution string!"
  exit 1
fi

echo "✅ All required files present and legacy files cleanly removed."

# Run Swift lexical syntax validation
echo "--- Running Swift Syntax Validation ---"
python3 scripts/validate_all_swift.py

# Run deterministic financial engine test suite
echo "--- Running Deterministic Financial Engine Reference Tests ---"
python3 scripts/test_financial_engine.py

echo "=== Repository Health Verification PASSED (100%) ==="
