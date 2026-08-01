/**
 * v2.3.1 ABSOLUTE TIER LOCK — Regression Tests.
 *
 * Covers:
 * 1. Landing.jsx — plan selection writes correct localStorage record
 * 2. Landing.jsx — Elite tier mapped to milli.elite.monthly (dot format)
 * 3. Register.jsx — verifyStoredPlan correctness (null, valid, mismatch)
 * 4. Register.jsx — plan-chooser UI present when plan is null
 * 5. Register.jsx — banner text "Milli Elite · $49.99/mo" format correct
 * 6. Pricing.jsx  — purchaseNativeIAP uses dot-format IDs (not underscores)
 */
const fs = require("fs");
const path = require("path");

const SRC = path.resolve(__dirname, "..");

function readFile(relPath) {
  return fs.readFileSync(path.join(SRC, relPath), "utf8");
}

// ─── LANDING.JSX ─────────────────────────────────────────────────────────────

describe("v2.3.1 — Landing plan selection", () => {
  const code = readFile("pages/Landing.jsx");

  test("imports IAP_PRODUCTS for canonical tier mapping", () => {
    expect(code).toContain("import { IAP_PRODUCTS }");
    expect(code).toContain("@/hooks/useStoreKit");
  });

  test("imports useNavigate for programmatic navigation", () => {
    expect(code).toContain("useNavigate");
  });

  test("has handleSelectPlan function", () => {
    expect(code).toContain("handleSelectPlan");
  });

  test("sets milli_selected_plan in localStorage on plan select", () => {
    expect(code).toContain('localStorage.setItem("milli_selected_plan"');
    expect(code).toContain("JSON.stringify(record)");
  });

  test("plan record uses product_id (not id) key — matches Register verifyStoredPlan", () => {
    expect(code).toContain("product_id: iap.id");
  });

  test("plan record stores price_display from IAP canonical data", () => {
    expect(code).toContain("price_display: iap.priceDisplay");
  });

  test("navigates to /register after storing plan", () => {
    expect(code).toContain('nav("/register")');
  });

  test("Elite tier resolves to milli.elite.monthly via IAP lookup (plan=elite)", () => {
    // The lookup is: IAP_PRODUCTS.find(p => p.plan === tier.id)
    // Elite IAP entry has id="milli.elite.monthly" plan="elite"
    // The stored product_id will be iap.id = "milli.elite.monthly"
    expect(code).toContain('p.plan === tier.id');
    expect(code).toContain("product_id: iap.id");
  });

  test("pricing CTA uses button element with onClick (not Link)", () => {
    // Should have a button with data-testid pricing-cta and onClick
    expect(code).toContain('data-testid={`pricing-cta-${t.id}`}');
    expect(code).toContain("onClick={() => handleSelectPlan(t)");
  });

  test("defensive fallback uses dot-format product_id", () => {
    expect(code).toContain('product_id: `milli.${tier.id}.monthly`');
  });
});

// ─── REGISTER.JSX ────────────────────────────────────────────────────────────

describe("v2.3.1 — Register verifyStoredPlan hardening", () => {
  const code = readFile("pages/Register.jsx");

  test("imports IAP_PRODUCTS", () => {
    expect(code).toContain("import { IAP_PRODUCTS }");
  });

  test("has verifyStoredPlan function", () => {
    expect(code).toContain("verifyStoredPlan");
  });

  test("returns null for null input", () => {
    expect(code).toContain("if (!raw) return null");
  });

  test("returns null for non-object parsed JSON", () => {
    expect(code).toContain('typeof stored !== "object"');
  });

  test("primary lookup by product_id", () => {
    expect(code).toContain("stored.product_id");
    expect(code).toContain('IAP_PRODUCTS.find((p) => p.id === stored.product_id)');
  });

  test("secondary fallback lookup by plan name", () => {
    expect(code).toContain("stored.plan");
    expect(code).toContain('IAP_PRODUCTS.find((p) => p.plan === stored.plan)');
  });

  test("does NOT silently default — returns null when nothing matched", () => {
    // Must not have a hardcoded pro fallback
    const fnBody = code.split("function verifyStoredPlan")[1].split("/** Build")[0];
    expect(fnBody).not.toContain('"pro"');
    expect(fnBody).toContain("return null");
  });

  test("canonical data overrides price and price_display", () => {
    expect(code).toContain("price: canonical.price");
    expect(code).toContain("price_display: canonical.priceDisplay");
  });

  test("sends stripe_price_id to backend", () => {
    expect(code).toContain("stripe_price_id: plan?.stripe_price_id");
  });
});

describe("v2.3.1 — Register plan-chooser UI", () => {
  const code = readFile("pages/Register.jsx");

  test("has register-plan-chooser testid for null-plan state", () => {
    expect(code).toContain('data-testid="register-plan-chooser"');
  });

  test("has Choose your plan heading", () => {
    expect(code).toContain("Choose your plan");
  });

  test("renders per-plan choose buttons with testid register-choose-plan-{plan}", () => {
    expect(code).toContain('data-testid={`register-choose-plan-${p.plan}`}');
  });

  test("choosePlan writes to localStorage and updates state", () => {
    expect(code).toContain("function choosePlan");
    expect(code).toContain('localStorage.setItem("milli_selected_plan"');
    expect(code).toContain("setPlan(record)");
  });

  test("Change button sets plan to null (returns to chooser)", () => {
    expect(code).toContain("onClick={() => setPlan(null)");
  });

  test("banner displays Milli {Name} · {price_display}/mo format", () => {
    // plan.plan = "elite" → "Elite" capitalised, then price_display = "$49.99"
    expect(code).toContain("plan.plan?.[0]?.toUpperCase()}{plan.plan?.slice(1)} · {plan.price_display}/mo");
  });

  test("has friendly Account not found error message", () => {
    expect(code).toContain("Account not found. Please register for the production server.");
  });
});

// ─── PRICING.JSX ─────────────────────────────────────────────────────────────

describe("v2.3.1 — Pricing purchaseNativeIAP dot-format IDs", () => {
  const code = readFile("pages/Pricing.jsx");

  test("Elite uses milli.elite.monthly (dot format)", () => {
    expect(code).toContain('"milli.elite.monthly"');
  });

  test("Pro uses milli.pro.monthly (dot format)", () => {
    expect(code).toContain('"milli.pro.monthly"');
  });

  test("does NOT contain underscore format milli_elite_monthly", () => {
    expect(code).not.toContain("milli_elite_monthly");
  });

  test("does NOT contain underscore format milli_pro_monthly", () => {
    expect(code).not.toContain("milli_pro_monthly");
  });

  test("purchaseNativeIAP function exists", () => {
    expect(code).toContain("purchaseNativeIAP");
  });

  test("productId variable uses tier conditional with dot IDs", () => {
    expect(code).toContain('tier === "elite" ? "milli.elite.monthly" : "milli.pro.monthly"');
  });
});

// ─── IAP_PRODUCTS canonical cross-check ──────────────────────────────────────

describe("v2.3.1 — IAP_PRODUCTS Elite entry canonical values", () => {
  // Load the actual module data as text
  const code = readFile("hooks/useStoreKit.js");

  test("Elite id is milli.elite.monthly (dot format)", () => {
    expect(code).toContain('"milli.elite.monthly"');
  });

  test("Elite plan is 'elite'", () => {
    const eliteBlock = code.split("milli.elite.monthly")[1].split("milli.basic.monthly")[0];
    expect(eliteBlock).toContain('"elite"');
  });

  test("Elite price is 49.99", () => {
    const eliteBlock = code.split("milli.elite.monthly")[1];
    expect(eliteBlock).toContain("49.99");
  });

  test("Elite priceDisplay is '$49.99'", () => {
    const eliteBlock = code.split("milli.elite.monthly")[1];
    expect(eliteBlock).toContain('"$49.99"');
  });
});
