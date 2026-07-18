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
 * Non-negotiable brand elements enforced here:
 *   • Right-hand vertical stroke of the M is cyan (#00E5FF)
 *   • "FOR YOU." is cyan (#00E5FF)
 *   • Solid #0A0A0A background — no gradients that dilute the black
 */
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Shield, Lock, MapPin, PieChart, FileCheck } from "lucide-react";

const CYAN = "#00E5FF";
const HOLD_MS = 2400;  // minimum time the splash stays on screen
const FADE_MS = 600;

// -----------------------------------------------------------------------
// Chrome M — inline SVG so we get pixel-perfect gradients + cyan right bar
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
          "drop-shadow(0 0 24px rgba(0, 229, 255, 0.35)) drop-shadow(0 6px 14px rgba(0,0,0,0.6))",
      }}
    >
      <defs>
        {/* Metallic chrome for the M body */}
        <linearGradient id="chrome" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#F4F5F7" />
          <stop offset="35%" stopColor="#C7CDD3" />
          <stop offset="55%" stopColor="#8A9096" />
          <stop offset="75%" stopColor="#D8DCE1" />
          <stop offset="100%" stopColor="#6F7479" />
        </linearGradient>
        {/* Bevel highlight along the top edge */}
        <linearGradient id="chromeHi" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.85" />
          <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0" />
        </linearGradient>
        {/* Turquoise right stroke — the key brand element */}
        <linearGradient id="cyanBar" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#7CF6FF" />
          <stop offset="45%" stopColor="#00E5FF" />
          <stop offset="100%" stopColor="#0097A7" />
        </linearGradient>
      </defs>

      {/* Left leg */}
      <path
        d="M28 172 L28 40 L58 40 L100 118 L96 132 L74 130 L58 96 L58 172 Z"
        fill="url(#chrome)"
      />
      {/* Center V pointing down */}
      <path
        d="M58 40 L100 118 L142 40 L124 40 L100 84 L76 40 Z"
        fill="url(#chrome)"
      />
      {/* Bevel highlight on the V */}
      <path
        d="M58 40 L100 118 L142 40 L134 40 L100 100 L66 40 Z"
        fill="url(#chromeHi)"
        opacity="0.35"
      />
      {/* Cyan right vertical (accent bar) */}
      <path
        d="M118 74 L136 40 L152 40 L134 74 Z"
        fill="url(#cyanBar)"
      />
      <rect
        x="122"
        y="74"
        width="18"
        height="98"
        rx="1.5"
        fill="url(#cyanBar)"
      />
      {/* Right chrome column — mirror of left leg */}
      <path
        d="M172 172 L172 40 L152 40 L152 172 Z"
        fill="url(#chrome)"
      />
      {/* Thin cyan glow line along the inner edge of the right column */}
      <rect
        x="146"
        y="46"
        width="2"
        height="120"
        fill={CYAN}
        opacity="0.55"
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
// SplashScreen
// -----------------------------------------------------------------------
export default function SplashScreen({ onDone, minDurationMs = HOLD_MS }) {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    const t = setTimeout(() => setVisible(false), minDurationMs);
    const t2 = setTimeout(
      () => onDone && onDone(),
      minDurationMs + FADE_MS + 50
    );
    return () => {
      clearTimeout(t);
      clearTimeout(t2);
    };
  }, [minDurationMs, onDone]);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key="milli-splash"
          data-testid="splash-screen"
          className="fixed inset-0 z-[200] overflow-hidden"
          initial={{ opacity: 1 }}
          exit={{
            opacity: 0,
            transition: { duration: FADE_MS / 1000, ease: "easeInOut" },
          }}
          style={{
            backgroundColor: "#0A0A0A",
            fontFamily: "Inter, system-ui, sans-serif",
          }}
        >
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
                transition={{ delay: 0.15 + i * 0.15, duration: 1.6, ease: "easeOut" }}
              />
            ))}
          </svg>

          {/* -- main stacked content -- */}
          <div className="relative z-10 flex flex-col items-center justify-between h-full py-[9vh] px-6">
            {/* logo + wordmark */}
            <motion.div
              className="flex flex-col items-center gap-4"
              initial={{ opacity: 0, y: -18, scale: 0.92 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            >
              <ChromeM size={132} />
              <div
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
                data-testid="splash-wordmark"
              >
                MILLI
              </div>
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

            {/* status */}
            <motion.div
              className="flex flex-col items-center gap-2 mt-2"
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
              <div
                className="text-[11px] text-white/70 tracking-[0.05em]"
                style={{ fontFamily: "Inter, system-ui, sans-serif" }}
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
              </div>
            </motion.div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
