/**
 * SignInTransition — the "you're in" moment.
 *
 * Full-screen overlay shown for ~1.6s after a successful login or
 * register. Chrome M zooms in from far, a cyan ring detonates,
 * a personalized welcome resolves, then the whole thing fades to
 * reveal the dashboard underneath.
 *
 * Reused by both /login and /register submit flows.
 */
import { useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useNavigate } from "react-router-dom";

const CYAN = "#00E5FF";
const HOLD_MS = 1600;
const FADE_MS = 550;

// ---------------------------------------------------------------
// Chrome M mark — same design as the splash for continuity.
// ---------------------------------------------------------------
function ChromeM({ size = 148 }) {
  return (
    <svg
      viewBox="0 0 200 200"
      width={size}
      height={size}
      xmlns="http://www.w3.org/2000/svg"
      style={{
        filter:
          "drop-shadow(0 0 40px rgba(0, 229, 255, 0.55)) drop-shadow(0 6px 20px rgba(0,0,0,0.7))",
      }}
    >
      <defs>
        <linearGradient id="tChrome" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%"  stopColor="#F4F6F8" />
          <stop offset="25%" stopColor="#D8DCE1" />
          <stop offset="50%" stopColor="#7B8085" />
          <stop offset="75%" stopColor="#C7CDD3" />
          <stop offset="100%" stopColor="#5B6068" />
        </linearGradient>
        <linearGradient id="tRoad" x1="0" y1="1" x2="0" y2="0">
          <stop offset="0%"  stopColor="#00E5FF" stopOpacity="1"    />
          <stop offset="50%" stopColor="#00E5FF" stopOpacity="0.75" />
          <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.15" />
        </linearGradient>
        <radialGradient id="tOrb" cx="50%" cy="50%" r="50%">
          <stop offset="0%"  stopColor="#FFFFFF" stopOpacity="1"   />
          <stop offset="45%" stopColor="#7CF6FF" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#00E5FF" stopOpacity="0"   />
        </radialGradient>
      </defs>
      <path
        d="M 20 180 L 20 24 L 44 20 L 88 106 L 100 88 L 112 106 L 156 20 L 180 24 L 180 180 L 156 180 L 156 60 L 120 128 L 100 104 L 80 128 L 44 60 L 44 180 Z"
        fill="url(#tChrome)" stroke="#050607" strokeWidth="0.8" strokeLinejoin="round"
      />
      <path d="M 78 184 L 92 108 L 100 96 L 108 108 L 122 184 Z" fill="url(#tRoad)" />
      <path d="M 88 184 L 96 110 L 100 100 L 104 110 L 112 184 Z" fill="#7CF6FF" opacity="0.55" />
      <rect x="99"   y="164" width="2"   height="10" fill="#FFFFFF" opacity="0.95" />
      <rect x="99"   y="148" width="2"   height="8"  fill="#FFFFFF" opacity="0.8" />
      <rect x="99"   y="134" width="1.6" height="6"  fill="#FFFFFF" opacity="0.65" />
      <rect x="99.2" y="122" width="1.4" height="5"  fill="#FFFFFF" opacity="0.5" />
      <rect x="99.4" y="112" width="1.2" height="4"  fill="#FFFFFF" opacity="0.4" />
      <circle cx="100" cy="172" r="16" fill="url(#tOrb)" />
      <circle cx="100" cy="172" r="5"  fill="#FFFFFF" />
      <circle cx="100" cy="172" r="3"  fill="#EAF9FD" />
      <path d="M 100 92 L 95 102 L 100 99 L 105 102 Z" fill="#7CF6FF" />
    </svg>
  );
}

/**
 * @param {object}   props
 * @param {boolean}  props.show      — controls whether the overlay is mounted
 * @param {string=}  props.name      — "Ian" → "Welcome back, Ian." (login)
 * @param {"back"|"welcome"} props.mode
 * @param {string=}  props.to        — route to navigate to when the overlay clears
 * @param {()=>void=} props.onDone    — optional callback fired after nav
 */
export default function SignInTransition({ show, name, mode = "back", to = "/app", onDone }) {
  const nav = useNavigate();

  useEffect(() => {
    if (!show) return;
    const t = setTimeout(() => {
      nav(to, { replace: true });
      onDone && onDone();
    }, HOLD_MS + FADE_MS);
    return () => clearTimeout(t);
  }, [show, to, nav, onDone]);

  const firstName = (name || "").trim().split(/\s+/)[0] || "";
  const line = mode === "welcome"
    ? (firstName ? `Welcome to Milli, ${firstName}.` : "Welcome to Milli.")
    : (firstName ? `Welcome back, ${firstName}.` : "Welcome back.");

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          key="signin-transition"
          data-testid="signin-transition"
          className="fixed inset-0 z-[400] flex flex-col items-center justify-center overflow-hidden"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: FADE_MS / 1000 } }}
          transition={{ duration: 0.2 }}
          style={{
            backgroundColor: "#050607",
            fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", "IBM Plex Sans", system-ui, sans-serif',
            paddingTop: "var(--safe-top)",
            paddingBottom: "var(--safe-bottom)",
          }}
        >
          {/* Ambient backdrop */}
          <div
            className="absolute inset-0 pointer-events-none"
            style={{
              background:
                "radial-gradient(ellipse 60% 40% at 50% 50%, rgba(0,229,255,0.18), transparent 65%)," +
                "repeating-linear-gradient(45deg, rgba(255,255,255,0.014) 0 2px, transparent 2px 6px)," +
                "repeating-linear-gradient(-45deg, rgba(255,255,255,0.010) 0 2px, transparent 2px 6px)",
            }}
          />

          {/* Expanding cyan detonation ring */}
          <motion.div
            aria-hidden="true"
            className="absolute rounded-full pointer-events-none"
            style={{
              width: 260, height: 260,
              border: "1px solid rgba(0,229,255,0.65)",
              boxShadow: "0 0 50px rgba(0,229,255,0.5)",
            }}
            initial={{ scale: 0.35, opacity: 0 }}
            animate={{ scale: [0.35, 1.5, 2.2], opacity: [0, 0.7, 0] }}
            transition={{ delay: 0.15, duration: 1.4, ease: "easeOut" }}
          />

          {/* Chrome M — zoom-in with blur resolve + subtle rotate */}
          <motion.div
            className="relative"
            initial={{ opacity: 0, scale: 4.0, filter: "blur(28px)", rotate: -6, y: -60 }}
            animate={{ opacity: 1, scale: 1,   filter: "blur(0px)",  rotate: 0, y: 0 }}
            transition={{ duration: 1.0, ease: [0.16, 1, 0.3, 1] }}
          >
            <ChromeM size={148} />

            {/* Diagonal chrome light-sweep across the M face */}
            <motion.div
              aria-hidden="true"
              className="absolute inset-0 pointer-events-none"
              style={{
                background:
                  "linear-gradient(115deg, transparent 30%, rgba(255,255,255,0.55) 48%, transparent 62%)",
                mixBlendMode: "screen",
                WebkitMaskImage: "radial-gradient(circle at 50% 50%, #000 60%, transparent 65%)",
                            maskImage: "radial-gradient(circle at 50% 50%, #000 60%, transparent 65%)",
              }}
              initial={{ x: -180, opacity: 0 }}
              animate={{ x: 180,  opacity: [0, 0.95, 0] }}
              transition={{ delay: 0.75, duration: 1.0, ease: "easeOut" }}
            />
          </motion.div>

          {/* Welcome line */}
          <motion.div
            className="mt-6 text-center px-6"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7, duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
          >
            <div
              className="font-display text-[26px] leading-tight font-bold"
              style={{
                background: "linear-gradient(180deg, #F4F6F8 0%, #C7CDD3 50%, #7B8085 100%)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                textShadow: "0 0 20px rgba(0,229,255,0.25)",
              }}
              data-testid="signin-transition-line"
            >
              {line}
            </div>
            <motion.div
              className="mt-2 text-[11.5px] uppercase tracking-[0.32em] font-semibold"
              style={{ color: CYAN, textShadow: "0 0 12px rgba(0,229,255,0.5)" }}
              initial={{ opacity: 0, letterSpacing: "0.5em" }}
              animate={{ opacity: 1, letterSpacing: "0.32em" }}
              transition={{ delay: 0.9, duration: 0.7 }}
            >
              Autopilot Engaged
            </motion.div>
          </motion.div>

          {/* Bottom pulse — signals "loading" without a spinner */}
          <div className="absolute bottom-14 left-0 right-0 flex justify-center pointer-events-none">
            <div className="relative w-40 h-px bg-white/10">
              <motion.div
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full"
                style={{ width: 6, height: 6, background: CYAN, boxShadow: `0 0 10px ${CYAN}` }}
                animate={{ opacity: [1, 0.3, 1] }}
                transition={{ duration: 1.3, repeat: Infinity }}
              />
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}