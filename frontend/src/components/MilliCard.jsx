/**
 * MilliCard — pixel-perfect Milli card visual that matches the user's luxury reference:
 *   ▸ brushed-steel top diagonal half
 *   ▸ matte-obsidian bottom diagonal half
 *   ▸ neon-cyan glowing diagonal seam
 *   ▸ embossed 3-D chrome "M" logo
 *   ▸ EMV chip + "MILLI" label
 *   ▸ VISA + plan tier wordmark (ELITE / PRO / BASIC)
 *   ▸ cardholder name, card number, expiry — all personalised to the signed-in user
 *
 * Two exports:
 *   <MilliCardHero user={user} />   large hero variant (used on Dashboard, More)
 *   <MilliCardMini user={user} />   compact badge (used inside "Available to Spend")
 */

/* -------- deterministic mock account number from the user id/email -------- */
function digitsFrom(seed, len) {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i);
    h = (h * 16777619) >>> 0;
  }
  let out = "";
  while (out.length < len) {
    h = (h * 1103515245 + 12345) >>> 0;
    out += String(h % 10);
  }
  return out.slice(0, len);
}

export function cardMetaFor(user) {
  const name = (user?.name || user?.email?.split("@")[0] || "Milli Member").toUpperCase();
  const seed = (user?.id || user?.email || user?.name || "milli").toString();
  // Fixed "4218 5632" BIN prefix (visa-style demo range) + 8 deterministic digits
  const tail = digitsFrom(seed, 8);
  const number = `4218 5632 ${tail.slice(0, 4)} ${tail.slice(4, 8)}`;
  const last4 = tail.slice(4, 8);
  // expiry = created_at year + 5, month derived from seed
  let year = new Date().getFullYear() + 5;
  if (user?.created_at) {
    const y = new Date(user.created_at).getFullYear();
    if (!Number.isNaN(y)) year = y + 5;
  }
  const month = ((parseInt(tail.slice(0, 2), 10) % 12) + 1).toString().padStart(2, "0");
  const expiry = `${month}/${String(year).slice(2)}`;
  const plan = (user?.plan || "elite").toString();
  const tierLabel = plan === "elite" ? "ELITE" : plan === "pro" ? "PRO" : plan === "trial" ? "MEMBER" : "BASIC";
  return { name, number, last4, expiry, tierLabel };
}

/* ------------------------------- HERO CARD ------------------------------- */
export function MilliCardHero({ user, className = "", testid = "milli-card-hero" }) {
  const { name, number, expiry, tierLabel } = cardMetaFor(user);
  return (
    <div
      data-testid={testid}
      className={`relative w-full max-w-[380px] mx-auto ${className}`}
      style={{ aspectRatio: "1.586 / 1", perspective: "1200px" }}
    >
      <div
        className="absolute inset-0 rounded-[22px] overflow-hidden"
        style={{
          transform: "rotateX(6deg) rotateY(-8deg)",
          transformStyle: "preserve-3d",
          boxShadow:
            "0 30px 60px rgba(0,0,0,0.72), 0 12px 28px rgba(0,0,0,0.55), 0 0 60px rgba(0,229,255,0.12)",
        }}
      >
        {/* base: brushed steel */}
        <div
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(135deg, #F5F6F8 0%, #D8DBE0 18%, #B8BCC2 38%, #8F9399 58%, #5C6066 78%, #2E3136 100%)",
          }}
        />
        {/* brushed-metal grain */}
        <div
          className="absolute inset-0 mix-blend-overlay opacity-70"
          style={{
            background:
              "repeating-linear-gradient(135deg, rgba(255,255,255,0.09) 0 1px, rgba(0,0,0,0.05) 1px 2px)",
          }}
        />
        {/* diagonal matte-obsidian half (bottom-right) — clipped */}
        <div
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(135deg, #14161B 0%, #0B0D11 60%, #05070A 100%)",
            clipPath: "polygon(100% 22%, 100% 100%, 12% 100%)",
          }}
        />
        {/* diagonal neon seam */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              "linear-gradient(135deg, transparent calc(50% - 1.2px), #7BF3FF calc(50% - 0.6px), #00E5FF 50%, #00A2C0 calc(50% + 0.6px), transparent calc(50% + 1.2px))",
            filter: "drop-shadow(0 0 6px rgba(0,229,255,0.9)) drop-shadow(0 0 18px rgba(0,229,255,0.55))",
          }}
        />
        {/* subtle top gloss */}
        <div
          className="absolute inset-x-0 top-0 h-1/2 pointer-events-none"
          style={{
            background:
              "linear-gradient(180deg, rgba(255,255,255,0.35) 0%, rgba(255,255,255,0) 60%)",
            mixBlendMode: "screen",
          }}
        />
        {/* specular highlight streak */}
        <div
          className="absolute inset-0 pointer-events-none opacity-70"
          style={{
            background:
              "linear-gradient(115deg, transparent 30%, rgba(255,255,255,0.35) 44%, transparent 58%)",
            mixBlendMode: "screen",
          }}
        />

        {/* ============ FOREGROUND CONTENT ============ */}
        {/* Embossed chrome M (top-left) */}
        <div
          className="absolute"
          style={{ top: "9%", left: "7%", width: "22%", aspectRatio: "1 / 1" }}
        >
          <EmbossedM />
        </div>

        {/* EMV chip + MILLI label */}
        <div
          className="absolute flex items-center gap-2"
          style={{ top: "44%", left: "8%" }}
        >
          <Chip />
          <span
            style={{
              fontFamily: "'Sora','Inter',sans-serif",
              fontWeight: 800,
              fontSize: "clamp(10px, 2.6vw, 13px)",
              letterSpacing: "0.28em",
              color: "#2A2D32",
              textShadow: "0 1px 0 rgba(255,255,255,0.6)",
            }}
          >
            MILLI
          </span>
        </div>

        {/* Cardholder */}
        <div
          className="absolute"
          style={{ left: "8%", bottom: "20%", right: "8%" }}
        >
          <div
            className="text-white/60"
            style={{
              fontFamily: "'JetBrains Mono', ui-monospace, monospace",
              fontSize: "clamp(8px, 1.8vw, 9.5px)",
              letterSpacing: "0.22em",
              textTransform: "uppercase",
            }}
          >
            Cardholder
          </div>
          <div
            className="text-white truncate"
            style={{
              fontFamily: "'Sora','Inter',sans-serif",
              fontWeight: 700,
              fontSize: "clamp(11px, 2.8vw, 14px)",
              letterSpacing: "0.14em",
              textShadow: "0 1px 0 rgba(0,0,0,0.6)",
            }}
          >
            {name}
          </div>
        </div>

        {/* Card number */}
        <div
          className="absolute text-white tabular-nums"
          style={{
            left: "8%",
            bottom: "9%",
            fontFamily: "'JetBrains Mono', ui-monospace, monospace",
            fontWeight: 700,
            fontSize: "clamp(11px, 2.9vw, 15px)",
            letterSpacing: "0.16em",
            textShadow: "0 1px 0 rgba(0,0,0,0.65)",
          }}
        >
          {number}
        </div>

        {/* Expiry */}
        <div
          className="absolute text-white/85 tabular-nums"
          style={{
            right: "8%",
            bottom: "9%",
            fontFamily: "'JetBrains Mono', ui-monospace, monospace",
            fontWeight: 700,
            fontSize: "clamp(10px, 2.4vw, 13px)",
            letterSpacing: "0.14em",
          }}
        >
          {expiry}
        </div>

        {/* VISA + Tier — bottom right, above expiry */}
        <div
          className="absolute flex flex-col items-end leading-none"
          style={{ right: "8%", top: "12%" }}
        >
          <span
            className="text-white"
            style={{
              fontFamily: "'Sora','Inter',sans-serif",
              fontWeight: 900,
              fontStyle: "italic",
              fontSize: "clamp(16px, 4.8vw, 26px)",
              letterSpacing: "0.02em",
              textShadow: "0 2px 0 rgba(0,0,0,0.55), 0 0 12px rgba(255,255,255,0.15)",
            }}
          >
            VISA
          </span>
          <span
            className="text-volt mt-1"
            style={{
              fontFamily: "'Sora','Inter',sans-serif",
              fontWeight: 800,
              fontSize: "clamp(9px, 2.2vw, 11px)",
              letterSpacing: "0.34em",
              textShadow: "0 0 8px rgba(0,229,255,0.6)",
            }}
          >
            {tierLabel}
          </span>
        </div>
      </div>
    </div>
  );
}

/* -------------------------- Mini badge variant -------------------------- */
export function MilliCardMini({ user, className = "" }) {
  const { tierLabel } = cardMetaFor(user);
  return (
    <div
      aria-hidden
      className={`relative w-[92px] h-[58px] sm:w-[112px] sm:h-[70px] flex-shrink-0 rounded-[10px] overflow-hidden ${className}`}
      style={{
        transform: "rotate(-8deg)",
        boxShadow:
          "0 8px 18px rgba(0,0,0,0.6), 0 0 22px rgba(0,229,255,0.18)",
      }}
    >
      {/* brushed steel */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(135deg, #F1F3F5 0%, #C8CCD1 25%, #8E9299 55%, #4A4E54 85%, #1E2126 100%)",
        }}
      />
      {/* grain */}
      <div
        className="absolute inset-0 mix-blend-overlay opacity-60"
        style={{
          background:
            "repeating-linear-gradient(135deg, rgba(255,255,255,0.09) 0 1px, rgba(0,0,0,0.05) 1px 2px)",
        }}
      />
      {/* matte black half */}
      <div
        className="absolute inset-0"
        style={{
          background: "linear-gradient(135deg, #14161B 0%, #06080B 100%)",
          clipPath: "polygon(100% 25%, 100% 100%, 12% 100%)",
        }}
      />
      {/* neon seam */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            "linear-gradient(135deg, transparent 49%, #7BF3FF 49.6%, #00E5FF 50%, #00A2C0 50.4%, transparent 51%)",
          filter: "drop-shadow(0 0 4px rgba(0,229,255,0.9))",
        }}
      />
      {/* chip */}
      <div
        className="absolute top-1.5 left-1.5 w-3.5 h-2.5 rounded-[2px]"
        style={{
          background: "linear-gradient(180deg, #E6D07A 0%, #8A7A3E 100%)",
          boxShadow: "inset 0 0 2px rgba(0,0,0,0.6)",
        }}
      />
      {/* Big embossed M */}
      <div
        className="absolute inset-0 flex items-center justify-start pl-1.5"
        style={{
          fontFamily: "'Sora','Inter',sans-serif",
          fontWeight: 900,
          fontSize: 22,
          letterSpacing: "-0.02em",
          background: "linear-gradient(180deg, #FFFFFF 0%, #D5D8DC 40%, #6E7379 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          filter: "drop-shadow(0 1px 0 rgba(0,0,0,0.55))",
          paddingTop: 6,
        }}
      >
        M
      </div>
      {/* Tier wordmark bottom right */}
      <div
        className="absolute bottom-1 right-1.5 text-volt"
        style={{
          fontFamily: "'Sora','Inter',sans-serif",
          fontWeight: 800,
          fontSize: 7,
          letterSpacing: "0.24em",
          textShadow: "0 0 4px rgba(0,229,255,0.7)",
        }}
      >
        {tierLabel}
      </div>
    </div>
  );
}

/* ------------------------- 3-D embossed M glyph ------------------------- */
function EmbossedM() {
  return (
    <svg viewBox="0 0 100 100" style={{ width: "100%", height: "100%" }}>
      <defs>
        <linearGradient id="mFace" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FDFEFF" />
          <stop offset="45%" stopColor="#D9DCE1" />
          <stop offset="100%" stopColor="#6A6E74" />
        </linearGradient>
        <linearGradient id="mEdge" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#8C9096" />
          <stop offset="100%" stopColor="#2A2D32" />
        </linearGradient>
      </defs>
      {/* drop shadow / bevel */}
      <path
        d="M14 82 L14 22 L30 22 L50 55 L70 22 L86 22 L86 82 L74 82 L74 44 L54 76 L46 76 L26 44 L26 82 Z"
        fill="url(#mEdge)"
        transform="translate(2,3)"
        opacity="0.85"
      />
      {/* face */}
      <path
        d="M14 82 L14 22 L30 22 L50 55 L70 22 L86 22 L86 82 L74 82 L74 44 L54 76 L46 76 L26 44 L26 82 Z"
        fill="url(#mFace)"
        stroke="rgba(255,255,255,0.55)"
        strokeWidth="0.6"
      />
      {/* top highlight */}
      <path
        d="M14 22 L30 22 L50 55 L70 22 L86 22 L86 30 L70 30 L50 62 L30 30 L14 30 Z"
        fill="rgba(255,255,255,0.35)"
      />
    </svg>
  );
}

/* -------------------------------- Chip -------------------------------- */
function Chip() {
  return (
    <svg width="34" height="26" viewBox="0 0 34 26" style={{ filter: "drop-shadow(0 1px 0 rgba(0,0,0,0.4))" }}>
      <defs>
        <linearGradient id="chipBase" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#F0DC94" />
          <stop offset="55%" stopColor="#C4A64A" />
          <stop offset="100%" stopColor="#7A6428" />
        </linearGradient>
      </defs>
      <rect x="0.5" y="0.5" width="33" height="25" rx="4" fill="url(#chipBase)" stroke="#5A4B1E" strokeWidth="0.6" />
      <g stroke="#5A4B1E" strokeWidth="0.7" opacity="0.7">
        <line x1="11" y1="0" x2="11" y2="26" />
        <line x1="23" y1="0" x2="23" y2="26" />
        <line x1="0" y1="8" x2="34" y2="8" />
        <line x1="0" y1="18" x2="34" y2="18" />
      </g>
      <rect x="12" y="9" width="10" height="8" rx="1.2" fill="none" stroke="#5A4B1E" strokeWidth="0.8" />
    </svg>
  );
}

export default MilliCardHero;
