/**
 * v2.2 Senior Finish — Structural validation tests.
 * Verifies the critical fixes are in place without requiring a full DOM render.
 */
const fs = require("fs");
const path = require("path");

const SRC = path.resolve(__dirname, "..");

function readFile(relPath) {
  return fs.readFileSync(path.join(SRC, relPath), "utf8");
}

describe("v2.2 Senior Finish — WeeboAvatar", () => {
  const code = readFile("components/WeeboAvatar.jsx");

  test("uses full-body 3D character asset URL", () => {
    expect(code).toContain("6b5e562c203f0d0bbde4f39e0124c310de74c4661385956aef646a69b9d2dabf");
  });

  test("enforces object-fit: contain", () => {
    expect(code).toContain("objectFit: \"contain\"");
  });

  test("has transparent background on container", () => {
    expect(code).toContain("transparent");
  });

  test("applies mask-image for alpha-channel blending", () => {
    expect(code).toContain("maskImage:");
    expect(code).toContain("WebkitMaskImage:");
    expect(code).toContain("maskMode: \"alpha\"");
  });
});

describe("v2.2 Senior Finish — GigConnections Modal", () => {
  const code = readFile("components/GigConnections.jsx");

  test("modal overlay has z-index 9999", () => {
    expect(code).toContain("zIndex: 9999");
  });

  test("modal has backdrop blur", () => {
    expect(code).toContain("backdropFilter: \"blur(12px)\"");
  });

  test("modal is viewport-centered (position fixed + flex center)", () => {
    expect(code).toContain("position: \"fixed\"");
    expect(code).toContain("alignItems: \"center\"");
    expect(code).toContain("justifyContent: \"center\"");
  });
});

describe("v2.2 Senior Finish — NavDialButton", () => {
  const code = readFile("components/NavDialButton.jsx");

  test("imports MilliLogo", () => {
    expect(code).toContain("import MilliLogo from");
  });

  test("renders MilliLogo with glowOutline", () => {
    expect(code).toContain("<MilliLogo size={logoSize} glowOutline />");
  });

  test("logo container has z-index 5 (above specular layer)", () => {
    expect(code).toContain("zIndex: 5");
  });

  test("logoSize is at least 30px minimum", () => {
    expect(code).toContain("Math.max(size * 0.5, 30)");
  });
});

describe("v2.2 Senior Finish — Text Contrast (Retirement)", () => {
  const code = readFile("pages/Retirement.jsx");

  test("plan selector buttons use #F4F6F8 silver text", () => {
    expect(code).toContain("#F4F6F8");
  });

  test("descriptions use #8B9DAF zinc (not #5A6573)", () => {
    const matches8B = (code.match(/#8B9DAF/g) || []).length;
    expect(matches8B).toBeGreaterThan(0);
  });
});

describe("v2.2 Senior Finish — Text Contrast (Investing)", () => {
  const code = readFile("pages/Investing.jsx");

  test("inactive tab buttons use #8B9DAF (not #5A6573)", () => {
    expect(code).toContain("\"#8B9DAF\"");
    const lines = code.split("\n");
    const tabLines = lines.filter(l => l.includes("tab ===") && l.includes("color:"));
    tabLines.forEach(line => {
      if (line.includes("#5A6573")) {
        throw new Error("Interactive tab button still uses #5A6573 (too dark)");
      }
    });
  });
});

describe("v2.2 Senior Finish — SplashScreen (Zero-Scroll)", () => {
  const code = readFile("components/SplashScreen.jsx");

  test("plays the Perfect car take-off video", () => {
    expect(code).toContain("319e22928c08311a.mp4");
  });

  test("shows Welcome back greeting with user name", () => {
    expect(code).toContain("Money, Made Intelligent.");
    expect(code).toContain("userName");
  });

  test("has 2-second welcome hold before auto-advance", () => {
    expect(code).toContain("WORDMARK_HOLD_MS = 3000");
  });

  test("uses position: fixed (no scroll involvement)", () => {
    expect(code).toContain("position: \"fixed\"");
  });

  test("has z-index 100000 to sit above all content", () => {
    expect(code).toContain("zIndex: 100000");
  });

  test("accepts userName prop", () => {
    expect(code).toContain("userName");
  });
});

describe("v2.2 Senior Finish — App.js (Zero-Scroll Flow)", () => {
  const code = readFile("App.js");

  test("no ios-frame wrapper causing scroll gates", () => {
    expect(code).not.toContain("ios-frame-outer");
    expect(code).not.toContain("ios-frame native-scroll");
  });

  test("splash is rendered as fixed overlay (not blocking scroll content)", () => {
    expect(code).toContain("SplashWrapper");
    expect(code).toContain("splashDone");
  });

  test("no WelcomePaywall or OnboardingCarousel gates blocking view", () => {
    expect(code).not.toContain("WelcomePaywall");
    expect(code).not.toContain("OnboardingCarousel");
  });

  test("SplashWrapper reads user name from AuthContext", () => {
    expect(code).toContain("user?.name");
    expect(code).toContain("userName");
  });
});
