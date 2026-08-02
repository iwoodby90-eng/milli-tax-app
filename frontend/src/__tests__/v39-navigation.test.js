/**
 * v3.9 Navigation Restructure — Structural Tests
 * Verifies the new 4-tab + center M layout, hub pages, and routing.
 */
const fs = require("fs");
const path = require("path");

const SRC = path.join(__dirname, "..");

describe("v3.9: Bel Air Signature Navigation", () => {
  let appLayout, appJs, wealthHub, activityHub, cockpitHub;

  beforeAll(() => {
    appLayout = fs.readFileSync(path.join(SRC, "components/AppLayout.jsx"), "utf8");
    appJs = fs.readFileSync(path.join(SRC, "App.js"), "utf8");
    wealthHub = fs.readFileSync(path.join(SRC, "pages/WealthHub.jsx"), "utf8");
    activityHub = fs.readFileSync(path.join(SRC, "pages/ActivityHub.jsx"), "utf8");
    cockpitHub = fs.readFileSync(path.join(SRC, "pages/CockpitHub.jsx"), "utf8");
  });

  describe("AppLayout — Tab Structure", () => {
    test("has VAULT tab routing to /app/vault", () => {
      expect(appLayout).toContain('to: "/app/vault"');
      expect(appLayout).toContain('label: "VAULT"');
    });

    test("has WEALTH tab routing to /app/wealth", () => {
      expect(appLayout).toContain('to: "/app/wealth"');
      expect(appLayout).toContain('label: "WEALTH"');
    });

    test("has ACTIVITY tab routing to /app/activity", () => {
      expect(appLayout).toContain('to: "/app/activity"');
      expect(appLayout).toContain('label: "ACTIVITY"');
    });

    test("has COCKPIT tab routing to /app/cockpit", () => {
      expect(appLayout).toContain('to: "/app/cockpit"');
      expect(appLayout).toContain('label: "COCKPIT"');
    });

    test("has exactly 2 left tabs and 2 right tabs", () => {
      const leftMatch = appLayout.match(/const leftTabs = \[([\s\S]*?)\];/);
      const rightMatch = appLayout.match(/const rightTabs = \[([\s\S]*?)\];/);
      expect(leftMatch).toBeTruthy();
      expect(rightMatch).toBeTruthy();
      // Count objects in array
      const leftCount = (leftMatch[1].match(/\{ to:/g) || []).length;
      const rightCount = (rightMatch[1].match(/\{ to:/g) || []).length;
      expect(leftCount).toBe(2);
      expect(rightCount).toBe(2);
    });

    test("removed old tabs (Income, Mileage from tab bar, Settings, etc.)", () => {
      const leftMatch = appLayout.match(/const leftTabs = \[([\s\S]*?)\];/)[1];
      const rightMatch = appLayout.match(/const rightTabs = \[([\s\S]*?)\];/)[1];
      const tabContent = leftMatch + rightMatch;
      expect(tabContent).not.toContain("/app/retirement");
      expect(tabContent).not.toContain("/app/investing");
      expect(tabContent).not.toContain("/app/mileage");
      expect(tabContent).not.toContain("/app/quarterly");
      expect(tabContent).not.toContain("/app/settings");
    });
  });

  describe("AppLayout — Chrome Dial M uses brand logo path", () => {
    test("uses exact brand logo M path data", () => {
      expect(appLayout).toContain("M 12 116 L 12 20 L 32 12 L 54 60 L 64 40 L 74 60 L 96 12 L 116 20 L 116 116 L 96 116 L 96 48 L 76 84 L 64 68 L 52 84 L 32 48 L 32 116 Z");
    });

    test("uses viewBox 0 0 128 128 and width/height 28", () => {
      expect(appLayout).toContain('viewBox="0 0 128 128"');
      expect(appLayout).toMatch(/width=\{28\}/);
      expect(appLayout).toMatch(/height=\{28\}/);
    });

    test("uses mChrome gradient colors from brand logo", () => {
      expect(appLayout).toContain('#F0F0F0');
      expect(appLayout).toContain('#E8E8E8');
      expect(appLayout).toContain('#808080');
      expect(appLayout).toContain('#C0C0C0');
    });

    test("uses mRoad gradient (cyan runway)", () => {
      expect(appLayout).toContain("nav-mRoad");
      expect(appLayout).toContain("#00E5FF");
    });

    test("has cyan aura glow ring", () => {
      expect(appLayout).toContain("breatheAura");
      expect(appLayout).toContain("rgba(0,229,255,");
    });
  });

  describe("AppLayout — Top Wordmark", () => {
    test("renders brand logo SVG as img tag at 28px", () => {
      expect(appLayout).toContain('src="/brand/milli-logo.svg"');
      expect(appLayout).toContain("height: 28");
    });

    test("renders MILLI wordmark with chrome gradient", () => {
      expect(appLayout).toContain("linear-gradient(135deg, #E8E8E8 0%, #C0C0C0 50%, #808080 100%)");
      expect(appLayout).toContain("fontWeight: 700");
      expect(appLayout).toContain('letterSpacing: "0.25em"');
    });
  });

  describe("AppLayout — Floating Weebo FAB", () => {
    test("is positioned fixed bottom-[96px] right-4 z-30", () => {
      expect(appLayout).toContain("fixed bottom-[96px] right-4 z-30");
    });

    test("is always visible (not restricted to isHome)", () => {
      // The FAB div should NOT be inside an {isHome && ...} block
      const fabIndex = appLayout.indexOf("fixed bottom-[96px] right-4 z-30");
      // Check that isHome is not a condition for it
      const before50chars = appLayout.substring(Math.max(0, fabIndex - 80), fabIndex);
      expect(before50chars).not.toContain("isHome");
    });

    test("navigates to /app/ai", () => {
      expect(appLayout).toContain('to="/app/ai"');
      expect(appLayout).toContain('data-testid="weebo-fab"');
    });
  });

  describe("App.js — Routing", () => {
    test("imports WealthHub, ActivityHub, CockpitHub", () => {
      expect(appJs).toContain('import WealthHub from "@/pages/WealthHub"');
      expect(appJs).toContain('import ActivityHub from "@/pages/ActivityHub"');
      expect(appJs).toContain('import CockpitHub from "@/pages/CockpitHub"');
    });

    test("has route for /app/wealth pointing to WealthHub", () => {
      expect(appJs).toContain('path="/app/wealth"');
      expect(appJs).toContain("<WealthHub />");
    });

    test("has route for /app/activity pointing to ActivityHub", () => {
      expect(appJs).toContain('path="/app/activity"');
      expect(appJs).toContain("<ActivityHub />");
    });

    test("has route for /app/cockpit pointing to CockpitHub", () => {
      expect(appJs).toContain('path="/app/cockpit"');
      expect(appJs).toContain("<CockpitHub />");
    });

    test("retains existing sub-routes", () => {
      expect(appJs).toContain('path="/app/vault"');
      expect(appJs).toContain('path="/app/investing"');
      expect(appJs).toContain('path="/app/retirement"');
      expect(appJs).toContain('path="/app/mileage"');
      expect(appJs).toContain('path="/app/expenses"');
      expect(appJs).toContain('path="/app/settings"');
      expect(appJs).toContain('path="/app/ai"');
    });
  });

  describe("Hub Pages — Content", () => {
    test("WealthHub links to /app/investing and /app/retirement", () => {
      expect(wealthHub).toContain('to="/app/investing"');
      expect(wealthHub).toContain('to="/app/retirement"');
      expect(wealthHub).toContain("Investing");
      expect(wealthHub).toContain("401(k)");
    });

    test("ActivityHub links to /app/mileage and /app/expenses", () => {
      expect(activityHub).toContain('to="/app/mileage"');
      expect(activityHub).toContain('to="/app/expenses"');
      expect(activityHub).toContain("Mileage");
      expect(activityHub).toContain("Expenses");
    });

    test("CockpitHub links to /app/settings and /app/referral", () => {
      expect(cockpitHub).toContain('to="/app/settings"');
      expect(cockpitHub).toContain('to="/app/referral"');
      expect(cockpitHub).toContain("Settings");
      expect(cockpitHub).toContain("Referral");
    });
  });
});
