import fs from "fs";
import path from "path";

const ROOT = path.resolve(__dirname, "../..");

describe("Quality pass fixes", () => {
  const indexCSS = fs.readFileSync(path.join(ROOT, "src/index.css"), "utf8");
  const appLayout = fs.readFileSync(path.join(ROOT, "src/components/AppLayout.jsx"), "utf8");
  const login = fs.readFileSync(path.join(ROOT, "src/pages/Login.jsx"), "utf8");
  const register = fs.readFileSync(path.join(ROOT, "src/pages/Register.jsx"), "utf8");
  const landing = fs.readFileSync(path.join(ROOT, "src/pages/Landing.jsx"), "utf8");

  test("FIX 1: safe area CSS vars defined at top of index.css", () => {
    const first200 = indexCSS.slice(0, 200);
    expect(first200).toContain("--safe-top: env(safe-area-inset-top, 44px)");
    expect(first200).toContain("--safe-bottom: env(safe-area-inset-bottom, 34px)");
    expect(first200).toContain("--safe-left: env(safe-area-inset-left, 0px)");
    expect(first200).toContain("--safe-right: env(safe-area-inset-right, 0px)");
  });

  test("FIX 2: native-scroll has height 100%", () => {
    expect(indexCSS).toMatch(/\.native-scroll\s*\{[^}]*height:\s*100%/);
  });

  test("FIX 2: html, body, #root overflow hidden", () => {
    expect(indexCSS).toMatch(/html,\s*body,\s*#root\s*\{[^}]*overflow:\s*hidden/);
  });

  test("FIX 2: main tag has WebkitOverflowScrolling style", () => {
    expect(appLayout).toContain('WebkitOverflowScrolling: "touch"');
  });

  test("FIX 3: CHANGE link goes to /welcome", () => {
    expect(register).toContain('to="/welcome"');
  });

  test("FIX 4: Landing header has safe area padding", () => {
    expect(landing).toContain('paddingTop: "var(--safe-top)"');
  });

  test("FIX 5: Login has cinematic redesign elements", () => {
    expect(login).toContain("Welcome back.");
    expect(login).toContain("Your money is waiting.");
    expect(login).toContain("radial-gradient(ellipse 80% 60% at 50% 110%");
  });

  test("FIX 6: Register has cinematic redesign elements", () => {
    expect(register).toContain("Create your account.");
    expect(register).toContain("Tax season starts now.");
    expect(register).toContain("radial-gradient(ellipse 80% 60% at 50% 110%");
  });

  test("FIX 7: ChromeDialM uses new glass-encased version", () => {
    expect(appLayout).toContain("Outer cyan bloom glow");
    expect(appLayout).toContain("Main dial housing");
    expect(appLayout).toContain("Glass dome overlay");
    expect(appLayout).toContain('src="/brand/milli-mark-192.png"');
  });

  test("FIX 8: Global polish rules present", () => {
    expect(indexCSS).toContain(".carbon-bg");
    expect(indexCSS).toContain("text-rendering: optimizeLegibility");
  });
});
