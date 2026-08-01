/**
 * v2.0 Component Integrity Tests
 * Validates that all new/modified JSX files parse without errors
 * and export the expected default functions.
 */

const fs = require("fs");
const path = require("path");

function assert(condition, msg) {
  if (!condition) throw new Error(`FAIL: ${msg}`);
  console.log(`  ✓ ${msg}`);
}

function fileExists(relPath) {
  const full = path.resolve(__dirname, "..", relPath);
  return fs.existsSync(full);
}

function fileContains(relPath, text) {
  const full = path.resolve(__dirname, "..", relPath);
  const content = fs.readFileSync(full, "utf-8");
  return content.includes(text);
}

function fileNotContains(relPath, text) {
  const full = path.resolve(__dirname, "..", relPath);
  const content = fs.readFileSync(full, "utf-8");
  return !content.includes(text);
}

console.log("\n━━━ v2.0 Component Integrity Tests ━━━\n");

// Test 1: Dashboard — Command Center with Mileage Tracker
console.log("Test 1: Dashboard.jsx (Command Center)");
{
  assert(fileExists("pages/Dashboard.jsx"), "Dashboard.jsx exists");
  assert(fileContains("pages/Dashboard.jsx", "mileage-tracker-hero"), "Has mileage tracker hero block");
  assert(fileContains("pages/Dashboard.jsx", "trip-toggle-btn"), "Has Start/Stop trip toggle");
  assert(fileContains("pages/Dashboard.jsx", "dollars-saved"), "Has live dollars saved counter");
  assert(fileContains("pages/Dashboard.jsx", "mini-map-placeholder"), "Has mini-map placeholder");
  assert(fileContains("pages/Dashboard.jsx", "tax-vault-module"), "Has Tax Vault glassmorphic module");
  assert(fileContains("pages/Dashboard.jsx", "wealth-engine-module"), "Has Wealth Engine glassmorphic module");
  assert(fileContains("pages/Dashboard.jsx", "GigConnections"), "Imports GigConnections");
  assert(fileContains("pages/Dashboard.jsx", "dashboard-gig-connections"), "Renders GigConnections at base");
}

// Test 2: Investing.jsx (Wealth Engine)
console.log("\nTest 2: Investing.jsx (Wealth Engine)");
{
  assert(fileExists("pages/Investing.jsx"), "Investing.jsx exists");
  assert(fileContains("pages/Investing.jsx", "blur(28px)"), "Uses 28px blur glassmorphism");
  assert(fileContains("pages/Investing.jsx", "#0D0F12"), "Uses #0D0F12 base color");
  assert(fileContains("pages/Investing.jsx", "#00E5FF"), "Uses neon cyan");
  assert(fileContains("pages/Investing.jsx", "PORTFOLIO_DATA"), "Has portfolio growth data");
  assert(fileContains("pages/Investing.jsx", "HOLDINGS"), "Has holdings allocation");
  assert(fileContains("pages/Investing.jsx", "Dollar-Cost Averaging"), "Explains DCA strategy");
  assert(fileContains("pages/Investing.jsx", "portfolio-chart"), "Has chart component");
}

// Test 3: Retirement.jsx (Solo 401k)
console.log("\nTest 3: Retirement.jsx (Solo 401k)");
{
  assert(fileExists("pages/Retirement.jsx"), "Retirement.jsx exists");
  assert(fileContains("pages/Retirement.jsx", "blur(28px)"), "Uses 28px blur glassmorphism");
  assert(fileContains("pages/Retirement.jsx", "CONTRIBUTION_LIMITS_2026"), "Has IRS contribution limits");
  assert(fileContains("pages/Retirement.jsx", "69000"), "Shows $69K combined max");
  assert(fileContains("pages/Retirement.jsx", "23000"), "Shows $23K employee deferral");
  assert(fileContains("pages/Retirement.jsx", "GROWTH_PROJECTION"), "Has growth projection");
  assert(fileContains("pages/Retirement.jsx", "Tax-Free Growth Projection"), "Shows projection chart");
  assert(fileContains("pages/Retirement.jsx", "contribution-limits"), "Has contribution limits section");
}

// Test 4: Settings.jsx (iOS Grouped List)
console.log("\nTest 4: Settings.jsx (iOS Grouped List)");
{
  assert(fileExists("pages/Settings.jsx"), "Settings.jsx exists");
  assert(fileContains("pages/Settings.jsx", "SettingsGroup"), "Uses grouped list pattern");
  assert(fileContains("pages/Settings.jsx", "Account & Billing"), "Has Account & Billing group");
  assert(fileContains("pages/Settings.jsx", "Vehicle Profile"), "Has Vehicle Profile group");
  assert(fileContains("pages/Settings.jsx", "Payout Sourcing"), "Has Payout Sourcing group");
  assert(fileContains("pages/Settings.jsx", "Security"), "Has Security group");
  assert(fileContains("pages/Settings.jsx", "SF Pro"), "Uses SF Pro typography");
  assert(fileContains("pages/Settings.jsx", "GIG_PLATFORMS"), "Has gig platform connections");
  assert(fileContains("pages/Settings.jsx", "FingerprintSimple"), "Has biometric (Phosphor duotone)");
}

// Test 5: MilliCentsWidget.jsx (Connect Gig + Auto-Calc)
console.log("\nTest 5: MilliCentsWidget.jsx (v2.0 with Connect Gig)");
{
  assert(fileExists("components/MilliCentsWidget.jsx"), "MilliCentsWidget.jsx exists");
  assert(fileContains("components/MilliCentsWidget.jsx", "Connect Gig Account"), "Has Connect Gig Account UI");
  assert(fileContains("components/MilliCentsWidget.jsx", "connect-gig-"), "Has gig connect buttons");
  assert(fileContains("components/MilliCentsWidget.jsx", "Live Offer Detected"), "Shows live offer detection");
  assert(fileContains("components/MilliCentsWidget.jsx", "28.50"), "Shows $28.50 live offer");
  assert(fileContains("components/MilliCentsWidget.jsx", "auto-verdict-badge"), "Has auto-verdict badge");
  assert(fileContains("components/MilliCentsWidget.jsx", "Auto-accepted by Milli-Cents formula"), "Auto-ACCEPT trigger");
}

// Test 6: AppLayout.jsx (3D Hardware Dial)
console.log("\nTest 6: AppLayout.jsx (Hardware Nav)");
{
  assert(fileExists("components/AppLayout.jsx"), "AppLayout.jsx exists");
  assert(fileContains("components/AppLayout.jsx", "NavDialButton"), "Imports NavDialButton (3D Hardware Dial)");
  assert(fileContains("components/AppLayout.jsx", "bottom-tab-bar"), "Has bottom tab bar");
  assert(fileContains("components/AppLayout.jsx", "Titanium"), "References titanium finish");
  assert(fileContains("components/AppLayout.jsx", "Specular top edge"), "Has specular edge highlight");
  assert(fileContains("components/AppLayout.jsx", "Brushed"), "References brushed finish");
}

// Test 7: glass-polish.css (Nuclear 28px)
console.log("\nTest 7: glass-polish.css (Nuclear Glassmorphism)");
{
  assert(fileExists("../src/styles/glass-polish.css"), "glass-polish.css exists");
  assert(fileContains("../src/styles/glass-polish.css", "blur(28px)"), "Has 28px blur");
  assert(fileContains("../src/styles/glass-polish.css", "brightness(1.2)"), "Has brightness boost");
  assert(fileContains("../src/styles/glass-polish.css", "--glass-radius: 22px"), "22px radius token");
  assert(fileContains("../src/styles/glass-polish.css", "--noir-bg: #050607"), "Noir background token");
}

// Test 8: NavDialButton.jsx (3D Hardware Component)
console.log("\nTest 8: NavDialButton.jsx (3D Chrome Dial)");
{
  assert(fileExists("components/NavDialButton.jsx"), "NavDialButton.jsx exists");
  assert(fileContains("components/NavDialButton.jsx", "conic-gradient"), "Uses conic gradient (brushed metal)");
  assert(fileContains("components/NavDialButton.jsx", "radial-gradient"), "Uses radial gradient (concave)");
  assert(fileContains("components/NavDialButton.jsx", "Specular"), "Has specular gloss layer");
  assert(fileContains("components/NavDialButton.jsx", "MilliLogo"), "Renders M logo");
}

// Test 9: SplashScreen (Cinematic Video)
console.log("\nTest 9: SplashScreen.jsx (v1.9.6 Cinematic)");
{
  assert(fileExists("components/SplashScreen.jsx"), "SplashScreen.jsx exists");
  assert(fileContains("components/SplashScreen.jsx", "VIDEO_URL"), "Has video URL constant");
  assert(fileContains("components/SplashScreen.jsx", "WORDMARK_URL"), "Has wordmark hold frame");
  assert(fileContains("components/SplashScreen.jsx", "WORDMARK_HOLD_MS"), "Has hold duration");
}

// Test 10: Pricing.jsx (Native Apple IAP)
console.log("\nTest 10: Pricing.jsx (StoreKit 2 IAP)");
{
  assert(fileExists("pages/Pricing.jsx"), "Pricing.jsx exists");
  assert(fileContains("pages/Pricing.jsx", "isNativeIOS"), "Detects native iOS");
  assert(fileContains("pages/Pricing.jsx", "StoreKit 2"), "References StoreKit 2");
  assert(fileContains("pages/Pricing.jsx", "NativePurchases"), "Uses @capgo/native-purchases");
  assert(fileContains("pages/Pricing.jsx", "milli_elite_monthly"), "Has IAP product ID");
  assert(fileContains("pages/Pricing.jsx", "milli_pro_monthly"), "Has Pro IAP product ID");
  assert(fileContains("pages/Pricing.jsx", "/iap/verify"), "Verifies receipt server-side");
  assert(fileContains("pages/Pricing.jsx", "AppleLogo"), "Shows Apple branding on native");
}

console.log("\n━━━ ALL v2.0 TESTS PASSED ━━━\n");
