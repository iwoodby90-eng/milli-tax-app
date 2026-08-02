/**
 * v3.7 LUXURY TRANSPARENCY — Hardware Dial Refinement + Milli AI Body + Plaid Fix
 *
 * Verifies:
 * 1. ChromeDialM has NO solid #0D0F12 background fill on the bevel ring inner div
 * 2. ChromeDialM bevel ring uses CSS mask (ring via radial-gradient) instead of filled div
 * 3. Deep recess div has NO heavy outer box-shadows (0px 6px 16px / 0px 2px 4px that bleed)
 * 4. Milli AI cutout PNG exists and is non-zero
 * 5. Plaid link_token endpoint has NO phone_number or email in LinkTokenCreateRequestUser
 */
const fs = require("fs");
const path = require("path");

const FRONTEND_SRC = path.resolve(__dirname, "..");
const REPO_ROOT    = path.resolve(__dirname, "../../..");

function readFrontend(relPath) {
  return fs.readFileSync(path.join(FRONTEND_SRC, relPath), "utf8");
}
function readBackend(relPath) {
  return fs.readFileSync(path.join(REPO_ROOT, "backend", relPath), "utf8");
}

// ─── 1. ChromeDialM — bevel ring must NOT have #0D0F12 fill ─────────────────

describe("v3.7 — ChromeDialM bevel ring transparency", () => {
  const layout = readFrontend("components/AppLayout.jsx");

  test("No solid #0D0F12 background on any inset-0 div in ChromeDialM", () => {
    // Find the ChromeDialM function block
    const dialStart = layout.indexOf("function ChromeDialM");
    expect(dialStart).toBeGreaterThan(-1);
    const dialBlock = layout.slice(dialStart, dialStart + 4000);
    expect(dialBlock).not.toContain('"#0D0F12"');
    expect(dialBlock).not.toContain("'#0D0F12'");
    expect(dialBlock).not.toContain("#0D0F12");
  });

  test("Chrome bevel ring uses CSS mask to form a ring shape", () => {
    const dialStart = layout.indexOf("function ChromeDialM");
    const dialBlock = layout.slice(dialStart, dialStart + 4000);
    // Must contain both mask and WebkitMask
    expect(dialBlock).toContain("WebkitMask");
    // Must use radial-gradient for ring shape
    expect(dialBlock).toContain("radial-gradient");
  });

  test("No padded inner-fill div replacing chrome bevel ring", () => {
    const dialStart = layout.indexOf("function ChromeDialM");
    const dialBlock = layout.slice(dialStart, dialStart + 4000);
    // The old pattern was: padding: "1px" + inner <div> with background: "#0D0F12"
    // New pattern is a single self-closing div with mask
    // Confirm no div has both padding:"1px" AND a child with solid background
    const hasBevelFill = dialBlock.includes('padding: "1px"') && dialBlock.includes('"#0D0F12"');
    expect(hasBevelFill).toBe(false);
  });
});

// ─── 2. Deep recess — NO heavy outer box-shadows ────────────────────────────

describe("v3.7 — Deep recess div — no heavy outer shadows", () => {
  const layout = readFrontend("components/AppLayout.jsx");

  test("Recess div does not have 0px 6px 16px rgba(0,0,0,0.85) outer shadow", () => {
    const dialStart = layout.indexOf("function ChromeDialM");
    const dialBlock = layout.slice(dialStart, dialStart + 4000);
    expect(dialBlock).not.toContain("0px 6px 16px rgba(0,0,0,0.85)");
  });

  test("Recess div does not have 0px 2px 4px rgba(0,0,0,0.6) outer shadow", () => {
    const dialStart = layout.indexOf("function ChromeDialM");
    const dialBlock = layout.slice(dialStart, dialStart + 4000);
    expect(dialBlock).not.toContain("0px 2px 4px rgba(0,0,0,0.6)");
  });

  test("Recess div still has inset shadows for depth effect", () => {
    const dialStart = layout.indexOf("function ChromeDialM");
    const dialBlock = layout.slice(dialStart, dialStart + 4000);
    expect(dialBlock).toContain("inset 0px 4px 10px rgba(0,0,0,0.9)");
  });
});

// ─── 3. Milli AI cutout PNG exists ──────────────────────────────────────────

describe("v3.7 — Milli AI cutout asset", () => {
  const assetPath = path.join(REPO_ROOT, "frontend/public/weebo/milli-ai-cutout-512.png");

  test("milli-ai-cutout-512.png exists at the correct path", () => {
    expect(fs.existsSync(assetPath)).toBe(true);
  });

  test("milli-ai-cutout-512.png is a non-zero PNG file", () => {
    const stat = fs.statSync(assetPath);
    expect(stat.size).toBeGreaterThan(10000); // must be at least 10KB
  });

  test("milli-ai-cutout-512.png begins with PNG signature bytes", () => {
    const buf = Buffer.alloc(8);
    const fd = fs.openSync(assetPath, "r");
    fs.readSync(fd, buf, 0, 8, 0);
    fs.closeSync(fd);
    // PNG magic: 89 50 4E 47 0D 0A 1A 0A
    expect(buf[0]).toBe(0x89);
    expect(buf[1]).toBe(0x50); // 'P'
    expect(buf[2]).toBe(0x4E); // 'N'
    expect(buf[3]).toBe(0x47); // 'G'
  });
});

// ─── 4. Plaid — no phone_number or email in LinkTokenCreateRequestUser ───────

describe("v3.7 — Plaid link token — no pre-fill fields", () => {
  const server = readBackend("server.py");

  // Extract the plaid_link_token function block
  function extractPlaidBlock(src) {
    const start = src.indexOf("async def plaid_link_token");
    if (start === -1) return "";
    // Find next route decorator after this function
    const searchFrom = start + 30;
    const nextRoute = src.indexOf("\n@api.", searchFrom);
    return nextRoute > -1 ? src.slice(start, nextRoute) : src.slice(start, start + 600);
  }

  test("plaid_link_token function exists", () => {
    expect(server).toContain("async def plaid_link_token");
  });

  test("LinkTokenCreateRequestUser does NOT contain phone_number field", () => {
    const block = extractPlaidBlock(server);
    expect(block).not.toContain("phone_number");
  });

  test("LinkTokenCreateRequestUser does NOT contain email field inside it", () => {
    const block = extractPlaidBlock(server);
    // Only client_user_id should be in LinkTokenCreateRequestUser
    expect(block).not.toContain('"email"');
    expect(block).not.toContain("email=");
  });

  test("LinkTokenCreateRequestUser has client_user_id only", () => {
    const block = extractPlaidBlock(server);
    expect(block).toContain("client_user_id");
  });
});
