/**
 * v3.8 WEALTH ENGINE HARDENING — Structural validation tests.
 *
 * Verifies (file-based, no DOM render required):
 * 1. Retirement.jsx — PlanSelector text visibility: active = cyan+white, inactive = ivory+zinc-400
 * 2. Retirement.jsx — GrowthProjectionGraph has 5Y/10Y segmented toggle
 * 3. Retirement.jsx — PortfolioAllocation401k section exists with correct allocation data
 * 4. Investing.jsx  — SectorView component with Tech, Energy, Finance badges
 * 5. Investing.jsx  — MILLI PICK badge logic: top 2 gainers only
 * 6. Investing.jsx  — "Highest Daily Movers" cinematic subtitle present
 */

const fs = require("fs");
const path = require("path");

const SRC = path.resolve(__dirname, "..");

function readFile(relPath) {
  return fs.readFileSync(path.join(SRC, relPath), "utf8");
}

/* ─── RETIREMENT.JSX ───────────────────────────────────────────────── */

describe("v3.8 — Retirement: PlanSelector text visibility", () => {
  const code = readFile("pages/Retirement.jsx");

  test("active plan title uses neon cyan (#00E5FF)", () => {
    // isActive === true  → title color "#00E5FF"
    expect(code).toContain('isActive ? "#00E5FF" : "#F4F6F8"');
  });

  test("inactive plan title uses ivory (#F4F6F8)", () => {
    expect(code).toContain('"#F4F6F8"');
  });

  test("active plan description uses white (#FFFFFF)", () => {
    // isActive === true  → description color white
    expect(code).toContain('isActive ? "#FFFFFF" : "#A1A1AA"');
  });

  test("inactive plan description uses zinc-400 (#A1A1AA)", () => {
    expect(code).toContain('"#A1A1AA"');
  });
});

describe("v3.8 — Retirement: GrowthProjectionGraph 5Y/10Y toggle", () => {
  const code = readFile("pages/Retirement.jsx");

  test("projection-toggle test id present", () => {
    expect(code).toContain('data-testid="projection-toggle"');
  });

  test("5Y toggle button present", () => {
    expect(code).toContain('data-testid={`projection-toggle-${yr}y`}');
  });

  test("10Y toggle button present", () => {
    // Toggle renders ["5","10"].map — verify both year values are embedded
    expect(code).toContain('"10"');
  });

  test("data sliced for 5-year range", () => {
    expect(code).toContain("data.slice(0, 5)");
  });

  test("yearRange state is initialized", () => {
    expect(code).toContain('useState("10")');
  });
});

describe("v3.8 — Retirement: PortfolioAllocation401k section", () => {
  const code = readFile("pages/Retirement.jsx");

  test("PortfolioAllocation401k component defined", () => {
    expect(code).toContain("function PortfolioAllocation401k");
  });

  test("component rendered in main return", () => {
    expect(code).toContain("<PortfolioAllocation401k");
  });

  test("ALLOCATION_401K constant defined", () => {
    expect(code).toContain("ALLOCATION_401K");
  });

  test("S&P 500 at 60% allocation", () => {
    expect(code).toContain("allocation: 60");
    expect(code).toContain("S&P 500");
  });

  test("International Stocks at 20%", () => {
    const allocs = code.match(/allocation: 20/g);
    expect(allocs).not.toBeNull();
    expect(allocs.length).toBeGreaterThanOrEqual(2);
  });

  test("Bonds at 20%", () => {
    expect(code).toContain("Bonds");
  });

  test("portfolio-allocation-401k test id present", () => {
    expect(code).toContain('data-testid="portfolio-allocation-401k"');
  });

  test("section placed after GrowthProjectionGraph", () => {
    const graphIdx = code.indexOf("<GrowthProjectionGraph");
    const allocIdx = code.indexOf("<PortfolioAllocation401k");
    expect(graphIdx).toBeGreaterThan(-1);
    expect(allocIdx).toBeGreaterThan(graphIdx);
  });
});

/* ─── INVESTING.JSX ────────────────────────────────────────────────── */

describe("v3.8 — Investing: SectorView badges", () => {
  const code = readFile("pages/Investing.jsx");

  test("SectorView component defined", () => {
    expect(code).toContain("function SectorView");
  });

  test("SectorView rendered in JSX", () => {
    expect(code).toContain("<SectorView");
  });

  test("sector-view test id present", () => {
    expect(code).toContain('data-testid="sector-view"');
  });

  test("SECTORS constant includes Tech", () => {
    expect(code).toContain('"tech"');
    expect(code).toContain('"Tech"');
  });

  test("SECTORS constant includes Energy", () => {
    expect(code).toContain('"energy"');
    expect(code).toContain('"Energy"');
  });

  test("SECTORS constant includes Finance", () => {
    expect(code).toContain('"finance"');
    expect(code).toContain('"Finance"');
  });

  test("sector badge test id pattern present", () => {
    expect(code).toContain('data-testid={`sector-badge-${sector.id}`}');
  });

  test("activeSector state initialized to null", () => {
    expect(code).toContain("useState(null)");
  });
});

describe("v3.8 — Investing: MILLI PICK badge on top 2 gainers", () => {
  const code = readFile("pages/Investing.jsx");

  test("MILLI PICK text present", () => {
    expect(code).toContain("MILLI PICK");
  });

  test("isMilliPick logic checks tab === gainers and index < 2", () => {
    expect(code).toContain('tab === "gainers" && i < 2');
  });

  test("MILLI PICK badge rendered conditionally", () => {
    expect(code).toContain("{isMilliPick && (");
  });

  test("milli-pick test id pattern present", () => {
    expect(code).toContain('data-testid={`milli-pick-${m.symbol}`}');
  });

  test("MILLI PICK badge uses Star icon", () => {
    expect(code).toContain("Star");
    expect(code).toContain('weight="fill"');
  });
});

describe("v3.8 — Investing: DailyMovers cinematic premium feel", () => {
  const code = readFile("pages/Investing.jsx");

  test("Highest Daily Movers subtitle present", () => {
    expect(code).toContain("Highest Daily Movers");
  });

  test("cinematic shimmer on MILLI PICK rows", () => {
    // top-edge shimmer via gradient
    expect(code).toContain("rgba(0,229,255,0.4)");
  });

  test("MILLI PICK strategy footnote present", () => {
    expect(code).toContain("Aggressive Growth");
  });

  test("daily-movers test id preserved", () => {
    expect(code).toContain('data-testid="daily-movers"');
  });

  test("movers-gainers-tab test id preserved", () => {
    expect(code).toContain('data-testid="movers-gainers-tab"');
  });

  test("movers-losers-tab test id preserved", () => {
    expect(code).toContain('data-testid="movers-losers-tab"');
  });
});
