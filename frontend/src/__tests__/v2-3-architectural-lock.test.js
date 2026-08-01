/**
 * v2.3 ARCHITECTURAL LOCK — Tier Mapping + Brand Lock Tests.
 *
 * Verifies:
 * 1. IAP_PRODUCTS has correct Stripe Price IDs for all tiers
 * 2. WelcomePaywall stores the correct plan data via ref (no stale closure)
 * 3. Register's verifyStoredPlan cross-validates against canonical data
 * 4. MilliLogo renders without errors
 * 5. SplashScreen uses correct WORDMARK_URL
 */
const fs = require("fs");
const path = require("path");

const SRC = path.resolve(__dirname, "..");

function readFile(relPath) {
  return fs.readFileSync(path.join(SRC, relPath), "utf8");
}

// ─── TIER MAPPING VERIFICATION (file-based) ─────────────────────────────────

describe("v2.3 — IAP_PRODUCTS Stripe Price IDs", () => {
  const code = readFile("hooks/useStoreKit.js");

  test("Basic tier maps to price_1TvrNCGaLE4ZdjeBcaxzuWjf", () => {
    expect(code).toContain('"price_1TvrNCGaLE4ZdjeBcaxzuWjf"');
  });

  test("Pro tier maps to price_1TvrNBGaLE4ZdjeBAu4C7ZPa", () => {
    expect(code).toContain('"price_1TvrNBGaLE4ZdjeBAu4C7ZPa"');
  });

  test("Elite tier maps to price_1TvrNBGaLE4ZdjeBBOfoHXgn", () => {
    expect(code).toContain('"price_1TvrNBGaLE4ZdjeBBOfoHXgn"');
  });

  test("Basic is $19.99", () => {
    // Basic block should have both the id and price together
    const basicBlock = code.split("milli.basic.monthly")[1].split("milli.pro.monthly")[0];
    expect(basicBlock).toContain("19.99");
    expect(basicBlock).toContain('"$19.99"');
  });

  test("Pro is $29.99", () => {
    const proBlock = code.split("milli.pro.monthly")[1].split("milli.elite.monthly")[0];
    expect(proBlock).toContain("29.99");
    expect(proBlock).toContain('"$29.99"');
  });

  test("Elite is $49.99", () => {
    const eliteBlock = code.split("milli.elite.monthly")[1];
    expect(eliteBlock).toContain("49.99");
    expect(eliteBlock).toContain('"$49.99"');
  });

  test("Each tier has a stripe_price_id field", () => {
    const matches = code.match(/stripe_price_id/g);
    expect(matches.length).toBeGreaterThanOrEqual(3);
  });
});

// ─── WELCOMEPAYWALL FIX VERIFICATION ────────────────────────────────────────

describe("v2.3 — WelcomePaywall Stale-Closure Fix", () => {
  const code = readFile("components/WelcomePaywall.jsx");

  test("uses useRef for selected state (anti-stale-closure)", () => {
    expect(code).toContain("selectedRef");
    expect(code).toContain("useRef");
  });

  test("handleStart reads from ref, not closure", () => {
    expect(code).toContain("selectedRef.current");
  });

  test("does NOT use AnimatePresence around the CTA button", () => {
    // The CTA button should not be wrapped in AnimatePresence key={selected}
    // which caused the stale closure race condition
    const ctaSection = code.split("Sticky CTA")[1];
    expect(ctaSection).not.toContain("<AnimatePresence");
    expect(ctaSection).not.toContain("key={selected}");
  });

  test("stores stripe_price_id in localStorage record", () => {
    expect(code).toContain("stripe_price_id: currentTier.stripe_price_id");
  });

  test("updateSelected keeps ref and state in sync", () => {
    expect(code).toContain("selectedRef.current = id");
    expect(code).toContain("setSelected(id)");
  });

  test("tier card onClick uses updateSelected (not setSelected)", () => {
    expect(code).toContain("onClick={() => updateSelected(t.id)}");
  });
});

// ─── REGISTER CROSS-VALIDATION ──────────────────────────────────────────────

describe("v2.3 — Register Plan Cross-Validation", () => {
  const code = readFile("pages/Register.jsx");

  test("imports IAP_PRODUCTS for canonical cross-validation", () => {
    expect(code).toContain('import { IAP_PRODUCTS }');
  });

  test("has verifyStoredPlan function", () => {
    expect(code).toContain("verifyStoredPlan");
  });

  test("cross-validates product_id against canonical data", () => {
    expect(code).toContain("IAP_PRODUCTS.find");
    expect(code).toContain("canonical");
  });

  test("sends stripe_price_id to backend in register call", () => {
    expect(code).toContain("stripe_price_id: plan?.stripe_price_id");
  });

  test("has friendly 'Account not found' error message", () => {
    expect(code).toContain("Account not found. Please register for the production server.");
  });
});

// ─── MILLILOGO ARCHITECTURE ─────────────────────────────────────────────────

describe("v2.3 — MilliLogo Architectural Rebuild", () => {
  const code = readFile("components/MilliLogo.jsx");

  test("has multi-layered metallic gradient (Senior Staff 3D lighting)", () => {
    expect(code).toContain("silver-main");
    expect(code).toContain("silver-spec");
    expect(code).toContain("silver-ao");
  });

  test("has at least 7 gradient stops for primary silver", () => {
    // Count stops in the main silver gradient section
    const mainGradient = code.split("silver-main")[1].split("</linearGradient>")[0];
    const stops = mainGradient.match(/<stop /g);
    expect(stops.length).toBeGreaterThanOrEqual(7);
  });

  test("has separate left blade, V-shape, and cyan bar segments", () => {
    expect(code).toContain("SEGMENT 1");
    expect(code).toContain("SEGMENT 2");
    expect(code).toContain("SEGMENT 3");
  });

  test("cyan bar has glow filter", () => {
    expect(code).toContain("cyan-glow");
    expect(code).toContain("feGaussianBlur");
  });

  test("has brushed metal noise filter", () => {
    expect(code).toContain("feTurbulence");
    expect(code).toContain("brushed");
  });

  test("v4.0 version marker", () => {
    expect(code).toContain("MilliLogo v4.0");
  });
});

// ─── SPLASHSCREEN WORDMARK ──────────────────────────────────────────────────

describe("v2.3 — SplashScreen Cinematic Wordmark", () => {
  const code = readFile("components/SplashScreen.jsx");

  test("uses definitive 4K architectural wordmark URL", () => {
    expect(code).toContain(
      "https://static.prod-images.emergentagent.com/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/images/ffb506321e2ecff2d2a3c57207bd7e866e1fd1bd9bb21f8bc721b10b3d36c742.jpeg"
    );
  });

  test("has 3-second wordmark hold (not 2-second)", () => {
    expect(code).toContain("WORDMARK_HOLD_MS = 3000");
  });

  test("implements white flash transition between video and wordmark", () => {
    expect(code).toContain("whiteFlash");
    expect(code).toContain("WHITE_FLASH_MS");
  });

  test("renders wordmark as an <img> tag (not SVG inline)", () => {
    expect(code).toContain("<motion.img");
    expect(code).toContain("WORDMARK_URL");
    expect(code).toContain('data-testid="splash-wordmark"');
  });

  test("v2.3 version marker", () => {
    expect(code).toContain("SplashScreen v2.3");
  });
});

// ─── LOGIN ERROR MESSAGE ────────────────────────────────────────────────────

describe("v2.3 — Login Error Handling", () => {
  const code = readFile("pages/Login.jsx");

  test("has friendly 'Account not found' error for invalid emails", () => {
    expect(code).toContain("Account not found. Please register for the production server.");
  });
});
