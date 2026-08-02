/**
 * v4.0 FINAL COCKPIT — Dashboard Overhaul & Trial Feature Activation
 *
 * Structural (file-based) tests verifying:
 * 1. MilliCentsWidget — inline prop support, no overlay in inline mode
 * 2. Dashboard — layout order: MilliCents → Wealth → Vault → Score → Mileage
 * 3. Dashboard — Wealth Summary shows retBalance + invBalance
 * 4. Dashboard — Tax Vault card present via TaxVaultCard
 * 5. Dashboard — Quarterly Readiness / TaxReadyGauge present
 * 6. Dashboard — Mileage & Expenses summary with business miles + deduction
 */

const fs = require("fs");
const path = require("path");

const SRC = path.resolve(__dirname, "..");

function readFile(relPath) {
  return fs.readFileSync(path.join(SRC, relPath), "utf8");
}

// ─── MilliCentsWidget ──────────────────────────────────────────────────────
describe("v4.0 — MilliCentsWidget: inline prop support", () => {
  const code = readFile("components/MilliCentsWidget.jsx");

  test("accepts inline prop (defaults to false)", () => {
    expect(code).toContain("inline = false");
  });

  test("renders content without fixed overlay in inline mode", () => {
    expect(code).toContain("if (inline)");
    expect(code).toContain("return content");
  });

  test("modal mode still has fixed overlay", () => {
    expect(code).toContain("fixed inset-0");
  });

  test("BelAirGauge still present in widget", () => {
    expect(code).toContain("BelAirGauge");
  });

  test("gig connect UI present", () => {
    expect(code).toContain("Connect Gig Account");
  });
});

// ─── Dashboard layout order ─────────────────────────────────────────────────
describe("v4.0 — Dashboard: card layout order", () => {
  const code = readFile("pages/Dashboard.jsx");

  const positions = {
    millicents: code.indexOf("dashboard-milli-cents-inline"),
    wealth: code.indexOf("dashboard-wealth-summary"),
    vault: code.indexOf("dashboard-vault-card"),
    score: code.indexOf("dashboard-tax-score-card"),
    mileage: code.indexOf("dashboard-mileage-expenses-card"),
  };

  test("MilliCentsWidget inline at very top", () => {
    expect(positions.millicents).toBeGreaterThan(-1);
    expect(positions.millicents).toBeLessThan(positions.wealth);
  });

  test("Wealth Summary card below MilliCents", () => {
    expect(positions.wealth).toBeGreaterThan(positions.millicents);
  });

  test("Tax Vault card below Wealth Summary", () => {
    expect(positions.vault).toBeGreaterThan(positions.wealth);
  });

  test("Quarterly Readiness / Tax Score below Vault", () => {
    expect(positions.score).toBeGreaterThan(positions.vault);
  });

  test("Mileage & Expenses below Tax Score", () => {
    expect(positions.mileage).toBeGreaterThan(positions.score);
  });
});

// ─── Dashboard wealth summary ─────────────────────────────────────────────────
describe("v4.0 — Dashboard: Wealth Summary card content", () => {
  const code = readFile("pages/Dashboard.jsx");

  test("fetches smart retirement account", () => {
    expect(code).toContain("/smart/retirement");
  });

  test("fetches smart investing account", () => {
    expect(code).toContain("/smart/investing");
  });

  test("calculates combined balance (retBalance + invBalance)", () => {
    expect(code).toContain("retBalance + invBalance");
  });

  test("displays wealthTotal", () => {
    expect(code).toContain("wealthTotal");
  });

  test("has testid for investing breakdown", () => {
    expect(code).toContain("wealth-investing");
  });

  test("has testid for retirement breakdown", () => {
    expect(code).toContain("wealth-retirement");
  });
});

// ─── Dashboard Tax Vault ─────────────────────────────────────────────────────
describe("v4.0 — Dashboard: Tax Vault card", () => {
  const code = readFile("pages/Dashboard.jsx");

  test("renders TaxVaultCard component", () => {
    expect(code).toContain("TaxVaultCard");
  });

  test("passes vaultBalance to TaxVaultCard", () => {
    expect(code).toContain("vaultBalance");
  });

  test("fetches vault from /vault endpoint", () => {
    expect(code).toContain('"/vault"');
  });
});

// ─── Dashboard Quarterly Readiness ──────────────────────────────────────────
describe("v4.0 — Dashboard: Quarterly Readiness / Tax Score", () => {
  const code = readFile("pages/Dashboard.jsx");

  test("renders TaxReadyGauge", () => {
    expect(code).toContain("TaxReadyGauge");
  });

  test("passes score to gauge", () => {
    expect(code).toContain("score={score}");
  });

  test("shows Quarterly Readiness heading", () => {
    expect(code).toContain("Quarterly Readiness");
  });

  test("shows next quarterly due details", () => {
    expect(code).toContain("next_quarterly");
  });
});

// ─── Dashboard Mileage & Expenses ────────────────────────────────────────────
describe("v4.0 — Dashboard: Mileage & Expenses Summary", () => {
  const code = readFile("pages/Dashboard.jsx");

  test("shows business miles stat", () => {
    expect(code).toContain("me-business-miles");
  });

  test("shows mileage deduction stat", () => {
    expect(code).toContain("me-deduction");
  });

  test("shows YTD expenses stat", () => {
    expect(code).toContain("me-expenses");
  });

  test("shows total saved stat", () => {
    expect(code).toContain("me-total-saved");
  });

  test("fetches mileage/summary endpoint", () => {
    expect(code).toContain("/mileage/summary");
  });

  test("links to /app/mileage", () => {
    expect(code).toContain("/app/mileage");
  });

  test("links to /app/expenses", () => {
    expect(code).toContain("/app/expenses");
  });
});
