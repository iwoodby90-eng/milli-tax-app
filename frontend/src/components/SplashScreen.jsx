/**
 * SplashScreen — the "power-on" screen for Milli.
 *
 * Recreates the production reference at `/brand/milli-splash-reference.jpg`
 * pixel-honestly using CSS + SVG so every element is crisp on any
 * screen size (including the 2732px iPad and 490px Watch mirror mode).
 *
 * Layout, top-to-bottom:
 *   1. Faint concentric arcs behind the logo (command-center vibe)
 *   2. Chrome M with cyan right-stroke  +  wordmark  "MILLI"
 *   3. Tagline:  "EVERY PAYOUT."
 *                "PROTECTED. AUTOMATED. FOR YOU."   ← "FOR YOU." in cyan
 *   4. Dotted cyan wave (SVG)
 *   5. Four outline feature icons: PROTECT · TRACK · GROW · PREPARE
 *   6. "Initializing your financial command center…"
 *
 * v1.9.2 — Final Design Hardening:
 *   • Initial scale 10 (more dramatic fly-in)
 *   • Background #050607 (Pure Noir)
 *   • Hardware Texture overlay (subtle scanlines + noise)
 *   • Faster, punchier M logo reveal (1.2s duration)
 */
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Shield, Lock, MapPin, PieChart, FileCheck } from "lucide-react";

const CYAN = "#00E5FF";
const HOLD_MS = 4000;  // 4s — cinematic reveal per Ian
const FADE_MS = 700;

// -----------------------------------------------------------------------
// Chrome M with cyan road running up through the center V.
// Signature Milli brand mark — mirrors /public/brand/milli-icon-1024.png
// and the reference marketing shots.
// -----------------------------------------------------------------------
function ChromeM({ size = 132 }) {
  return (
    <svg
      viewBox="0 0 200 200"
      width={size}
      height={size}
      xmlns="http://www.w3.org/2000/svg"
      aria-label="Milli"
      role="img"
      style={{
        filter:
          "drop-shadow(0 0 32px rgba(0, 229, 255, 0.42)) drop-shadow(0 6px 14px rgba(0,0,0,0.6))",
      }}
    >
      <defs>
        {/* Metallic chrome — polished, deep bevel */}
        <linearGradient id="mChrome" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%"  stopColor="#F4F6F8" />
          <stop offset="25%" stopColor="#D8DCE1" />
          <stop offset="50%" stopColor="#7B8085" />
          <stop offset="75%" stopColor="#C7CDD3" />
          <stop offset="100%" stopColor="#5B6068" />
        </linearGradient>
        {/* Edge highlight */}
        <linearGradient id="mHi" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0" />
        </linearGradient>
        {/* Cyan road — bright at the base, fades toward the horizon */}
        <linearGradient id="mRoad" x1="0" y1="1" x2="0" y2="0">
          <stop offset="0%"  stopColor="#00E5FF" stopOpacity="1"    />
          <stop offset="50%" stopColor="#00E5FF" stopOpacity="0.75" />
          <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.15" />
        </linearGradient>
        {/* Road glow */}
        <radialGradient id="mOrb" cx="50%" cy="50%" r="50%">
          <stop offset="0%"  stopColor="#FFFFFF" stopOpacity="1"   />
          <stop offset="45%" stopColor="#7CF6FF" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#00E5FF" stopOpacity="0"   />
        </radialGradient>
      </defs>

      {/* --- 1. Left leg + inner V (chrome M silhouette) --- */}
      <path
        d="M 20 180 L 20 24 L 44 20 L 88 106 L 100 88 L 112 106 L 156 20 L 180 24 L 180 180 L 156 180 L 156 60 L 120 128 L 100 104 L 80 128 L 44 60 L 44 180 Z"
        fill="url(#mChrome)"
        stroke="#050607"
        strokeWidth="0.8"
        strokeLinejoin="round"
      />
      {/* Bevel highlight along the top of the M */}
      <path
        d="M 20 24 L 44 20 L 88 106 L 100 88 L 112 106 L 156 20 L 180 24 L 156 26 L 112 112 L 100 96 L 88 112 L 44 26 Z"
        fill="url(#mHi)"
        opacity="0.55"
      />

      {/* --- 2. Cyan road rising into the M valley --- */}
      {/* Base flare (wide at bottom, narrows to the horizon point) */}
      <path
        d="M 78 184 L 92 108 L 100 96 L 108 108 L 122 184 Z"
        fill="url(#mRoad)"
      />
      {/* Inner bright edge of the road */}
      <path
        d="M 88 184 L 96 110 L 100 100 L 104 110 L 112 184 Z"
        fill="#7CF6FF"
        opacity="0.55"
      />

      {/* --- 3. Dashed lane markers (perspective: bigger near, smaller far) --- */}
      <rect x="99" y="164" width="2"   height="10" fill="#FFFFFF" opacity="0.95" />
      <rect x="99" y="148" width="2"   height="8"  fill="#FFFFFF" opacity="0.8"  />
      <rect x="99" y="134" width="1.6" height="6"  fill="#FFFFFF" opacity="0.65" />
      <rect x="99.2" y="122" width="1.4" height="5" fill="#FFFFFF" opacity="0.5" />
      <rect x="99.4" y="112" width="1.2" height="4" fill="#FFFFFF" opacity="0.4" />

      {/* --- 4. Glowing orb at the base of the road --- */}
      <circle cx="100" cy="172" r="16" fill="url(#mOrb)" />
      <circle cx="100" cy="172" r="5"  fill="#FFFFFF" />
      <circle cx="100" cy="172" r="3"  fill="#EAF9FD" />

      {/* --- 5. Arrow head at the top of the road (into the horizon) --- */}
      <path
        d="M 100 92 L 95 102 L 100 99 L 105 102 Z"
        fill="#7CF6FF"
      />
    </svg>
  );
}

// -----------------------------------------------------------------------
// Digital wave — dotted grid displaced by two sine waves
// -----------------------------------------------------------------------
function DigitalWave() {
  const cols = 60;
  const rows = 10;
  const width = 720;
  const height = 180;
  const dx = width / cols;
  const dots = [];
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const x = c * dx;
      const t = c / cols;
      // two overlaid sines give an organic ribbon
      const wave =
        Math.sin(t * Math.PI * 2.3) * 22 +
        Math.sin(t * Math.PI * 4.7 + 1.2) * 8;
      const y = height / 2 + wave + r * 9;
      const dist = Math.abs(r - rows / 2) / rows;
      const opacity = Math.max(0.08, 0.9 - dist * 1.8);
      const size = 1.4 + (1 - dist) * 1.4;
      dots.push({ x, y, opacity, size, key: `${r}-${c}` });
    }
  }
  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      className="w-full h-auto"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
    >
      <defs>
        <radialGradient id="waveFade" cx="50%" cy="50%" r="60%">
          <stop offset="0%" stopColor={CYAN} stopOpacity="1" />
          <stop offset="100%" stopColor={CYAN} stopOpacity="0.15" />
        </radialGradient>
      </defs>
      {dots.map((d) => (
        <circle
          key={d.key}
          cx={d.x}
          cy={d.y}
          r={d.size}
          fill="url(#waveFade)"
          opacity={d.opacity}
        />
      ))}
    </svg>
  );
}

// -----------------------------------------------------------------------
// Shield-with-padlock icon (Lucide's Shield doesn't ship with a lock inside)
// -----------------------------------------------------------------------
function ShieldLockIcon({ size = 30, color = CYAN }) {
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <Shield size={size} color={color} strokeWidth={1.6} />
      <Lock
        size={size * 0.45}
        color={color}
        strokeWidth={1.8}
        className="absolute"
        style={{
          top: "45%",
          left: "50%",
          transform: "translate(-50%, -55%)",
        }}
      />
    </div>
  );
}

function FeatureIcon({ label, children, delay }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.5, ease: "easeOut" }}
      className="flex flex-col items-center gap-2"
      data-testid={`splash-feature-${label.toLowerCase()}`}
    >
      <div
        className="p-2 rounded-lg"
        style={{
          background:
            "linear-gradient(180deg, rgba(0,229,255,0.06), rgba(0,229,255,0.01))",
          border: "1px solid rgba(0,229,255,0.18)",
          boxShadow: "0 0 12px rgba(0,229,255,0.12) inset",
        }}
      >
        {children}
      </div>
      <span
        className="text-[10px] tracking-[0.22em] text-white font-medium"
        style={{ fontFamily: "Inter, system-ui, sans-serif" }}
      >
        {label}
      </span>
    </motion.div>
  );
}

// -----------------------------------------------------------------------
// Hardware Texture Overlay — subtle scanlines + noise for cinematic depth
// -----------------------------------------------------------------------
function HardwareTexture() {
  return (
    <div
      className="absolute inset-0 pointer-events-none z-[1]"
      aria-hidden="true"
      style={{ mixBlendMode: "overlay" }}
    >
      {/* Scanlines */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage:
            "repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(255,255,255,0.015) 2px, rgba(255,255,255,0.015) 4px)",
        }}
      />
      {/* Noise texture via inline SVG data URI */}
      <div
        className="absolute inset-0 opacity-[0.035]"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='200'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/%3E%3C/svg%3E")`,
          backgroundRepeat: "repeat",
        }}
      />
    </div>
  );
}

// -----------------------------------------------------------------------
// SplashScreen — animates in, then either waits for a tap (returning
// users) OR auto-fades into the next flow (first launch).
// -----------------------------------------------------------------------
export default function SplashScreen({ onDone, minDurationMs = HOLD_MS, autoFade = false }) {
  const [visible, setVisible] = useState(true);
  const [readyToDismiss, setReadyToDismiss] = useState(false);

  // After the intro animation lands, either auto-fade or surface the tap prompt.
  useEffect(() => {
    const t = setTimeout(() => {
      setReadyToDismiss(true);
      if (autoFade) {
        // Give the wordmark a beat to breathe, then dissolve into the next flow
        setTimeout(() => {
          setVisible(false);
          setTimeout(() => onDone && onDone(), FADE_MS + 50);
        }, 900);
      }
    }, minDurationMs);
    return () => clearTimeout(t);
  }, [minDurationMs, autoFade, onDone]);

  const dismiss = () => {
    if (!readyToDismiss || autoFade) return;
    setVisible(false);
    setTimeout(() => onDone && onDone(), FADE_MS + 50);
  };

  // Any pointer or Enter/Space dismisses once the tap prompt is live.
  useEffect(() => {
    if (!readyToDismiss || !visible || autoFade) return;
    const onKey = (e) => {
      if (e.key === "Enter" || e.key === " " || e.key === "Escape") dismiss();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [readyToDismiss, visible, autoFade]);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key="milli-splash"
          data-testid="splash-screen"
          role="button"
          tabIndex={0}
          onClick={dismiss}
          onTouchEnd={dismiss}
          className={`absolute inset-0 z-[200] overflow-hidden ${readyToDismiss ? "cursor-pointer" : "cursor-default"}`}
          initial={{ opacity: 1 }}
          exit={{
            opacity: 0,
            transition: { duration: FADE_MS / 1000, ease: "easeInOut" },
          }}
          style={{
            backgroundColor: "#050607",
            fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
            paddingTop:    "var(--safe-top)",
            paddingBottom: "var(--safe-bottom)",
          }}
        >
          {/* Hardware Texture overlay — scanlines + noise */}
          <HardwareTexture />

          {/* -- concentric arcs behind the logo -- */}
          <svg
            className="absolute inset-x-0 top-0 mx-auto pointer-events-none"
            width="120%"
            height="90%"
            viewBox="0 0 800 700"
            preserveAspectRatio="xMidYMid slice"
            style={{ left: "-10%", opacity: 0.85 }}
            aria-hidden="true"
          >
            <defs>
              <linearGradient id="arcGrad" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor={CYAN} stopOpacity="0" />
                <stop offset="50%" stopColor={CYAN} stopOpacity="0.9" />
                <stop offset="100%" stopColor={CYAN} stopOpacity="0" />
              </linearGradient>
              <filter id="arcGlow">
                <feGaussianBlur stdDeviation="3" />
              </filter>
            </defs>
            {[ 260, 300, 340, 380 ].map((r, i) => (
              <motion.circle
                key={r}
                cx="400"
                cy="440"
                r={r}
                fill="none"
                stroke="url(#arcGrad)"
                strokeWidth={i === 0 ? 2.2 : 0.9}
                opacity={i === 0 ? 0.9 : 0.35 - i * 0.06}
                filter={i === 0 ? "url(#arcGlow)" : undefined}
                initial={{ pathLength: 0 }}
                animate={{ pathLength: 1 }}
                transition={{ delay: 0.1 + i * 0.1, duration: 1.0, ease: "easeOut" }}
              />
            ))}
          </svg>

          {/* -- main stacked content -- */}
          <div className="relative z-10 flex flex-col items-center justify-between h-full py-[9vh] px-6">
            {/* logo + wordmark — cinematic fly-in (v1.9.2: scale 10, 1.2s punch) */}
            <motion.div
              className="flex flex-col items-center gap-4 relative"
              initial={{ opacity: 0, scale: 10, filter: "blur(32px)", y: -100 }}
              animate={{ opacity: 1, scale: 1,   filter: "blur(0px)",  y: 0 }}
              transition={{ duration: 1.2, ease: [0.16, 1, 0.3, 1] }}
            >
              {/* Chrome light-sweep across the M */}
              <motion.div
                aria-hidden="true"
                className="absolute pointer-events-none"
                style={{
                  width: 132, height: 132,
                  background:
                    "linear-gradient(115deg, transparent 30%, rgba(255,255,255,0.55) 48%, transparent 62%)",
                  mixBlendMode: "screen",
                  WebkitMaskImage:
                    "radial-gradient(circle at 50% 50%, #000 60%, transparent 65%)",
                          maskImage:
                    "radial-gradient(circle at 50% 50%, #000 60%, transparent 65%)",
                }}
                initial={{ x: -160, opacity: 0 }}
                animate={{ x: 160,  opacity: [0, 0.9, 0] }}
                transition={{ delay: 0.7, duration: 0.8, ease: "easeOut" }}
              />
              {/* Ambient cyan pulse ring behind the M */}
              <motion.div
                aria-hidden="true"
                className="absolute rounded-full pointer-events-none"
                style={{
                  width: 220, height: 220,
                  border: "1px solid rgba(0, 229, 255, 0.6)",
                  boxShadow: "0 0 40px rgba(0, 229, 255, 0.4)",
                }}
                initial={{ scale: 0.4, opacity: 0 }}
                animate={{ scale: [0.4, 1.4, 1.9], opacity: [0, 0.6, 0] }}
                transition={{ delay: 0.5, duration: 1.2, ease: "easeOut" }}
              />
              <ChromeM size={132} />
              <motion.div
                className="text-[38px] leading-none"
                style={{
                  fontWeight: 700,
                  letterSpacing: "0.15em",
                  background:
                    "linear-gradient(180deg, #EEF1F4 0%, #B7BCC1 45%, #7B8085 100%)",
                  WebkitBackgroundClip: "text",
                  WebkitTextFillColor: "transparent",
                  textShadow: "0 0 22px rgba(0,229,255,0.18)",
                }}
                initial={{ opacity: 0, letterSpacing: "0.5em" }}
                animate={{ opacity: 1, letterSpacing: "0.15em" }}
                transition={{ delay: 0.6, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
                data-testid="splash-wordmark"
              >
                MILLI
              </motion.div>
            </motion.div>

            {/* tagline */}
            <motion.div
              className="flex flex-col items-center gap-1 mt-6 text-center"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.35, duration: 0.6 }}
            >
              <div
                className="text-[15px] uppercase text-white"
                style={{ letterSpacing: "0.32em", fontWeight: 500 }}
              >
                Every Payout.
              </div>
              <div
                className="text-[15px] uppercase flex flex-wrap items-center justify-center gap-2"
                style={{ letterSpacing: "0.32em", fontWeight: 500 }}
              >
                <span className="text-white">Protected.</span>
                <span className="text-white">Automated.</span>
                <span
                  data-testid="splash-tagline-cyan"
                  style={{
                    color: CYAN,
                    fontWeight: 700,
                    textShadow: "0 0 12px rgba(0,229,255,0.55)",
                  }}
                >
                  For You.
                </span>
              </div>
            </motion.div>

            {/* digital wave */}
            <motion.div
              className="w-full max-w-[720px]"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.6, duration: 0.8 }}
            >
              <DigitalWave />
            </motion.div>

            {/* feature icons */}
            <div
              className="grid grid-cols-4 gap-6 sm:gap-10 mt-4"
              data-testid="splash-features"
            >
              <FeatureIcon label="PROTECT" delay={0.85}>
                <ShieldLockIcon />
              </FeatureIcon>
              <FeatureIcon label="TRACK" delay={0.95}>
                <MapPin size={30} color={CYAN} strokeWidth={1.6} />
              </FeatureIcon>
              <FeatureIcon label="GROW" delay={1.05}>
                <PieChart size={30} color={CYAN} strokeWidth={1.6} />
              </FeatureIcon>
              <FeatureIcon label="PREPARE" delay={1.15}>
                <FileCheck size={30} color={CYAN} strokeWidth={1.6} />
              </FeatureIcon>
            </div>

            {/* status + tap prompt */}
            <motion.div
              className="flex flex-col items-center gap-3 mt-2"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.35, duration: 0.6 }}
            >
              {/* horizon line with pulsing dot */}
              <div className="relative w-56 h-px bg-white/10">
                <motion.div
                  className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full"
                  style={{
                    width: 6,
                    height: 6,
                    background: CYAN,
                    boxShadow: `0 0 10px ${CYAN}`,
                  }}
                  animate={{ opacity: [1, 0.3, 1] }}
                  transition={{ duration: 1.4, repeat: Infinity }}
                />
              </div>

              {/* status text — hides once the tap prompt is live (or stays if auto-fading) */}
              <AnimatePresence mode="wait">
                {(!readyToDismiss || autoFade) ? (
                  <motion.div
                    key="status"
                    className="text-[11px] text-white/70 tracking-[0.05em]"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    data-testid="splash-status"
                  >
                    Initializing your financial command center
                    <motion.span
                      className="inline-block ml-1"
                      animate={{ opacity: [1, 0.2, 1] }}
                      transition={{ duration: 1.1, repeat: Infinity }}
                    >
                      …
                    </motion.span>
                  </motion.div>
                ) : (
                  <motion.div
                    key="tap"
                    className="flex items-center gap-2 text-white uppercase"
                    style={{
                      fontWeight: 500,
                      fontSize: 12,
                      letterSpacing: "0.15em",
                    }}
                    initial={{ opacity: 0, y: 6 }}
                    animate={{ opacity: [0, 1, 0.55, 1], y: 0 }}
                    transition={{
                      opacity: { duration: 1.6, repeat: Infinity, ease: "easeInOut" },
                      y: { duration: 0.4 },
                    }}
                    data-testid="splash-tap-prompt"
                  >
                    <span>Tap to continue</span>
                    <motion.span
                      aria-hidden="true"
                      animate={{ x: [0, 4, 0] }}
                      transition={{ duration: 1.4, repeat: Infinity }}
                      style={{ color: CYAN, textShadow: `0 0 8px ${CYAN}` }}
                    >
                      ›
                    </motion.span>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
