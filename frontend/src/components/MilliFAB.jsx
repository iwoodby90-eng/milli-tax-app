import { useNavigate, useLocation } from "react-router-dom";
import { motion } from "framer-motion";

/**
 * MilliFAB — persistent small Milli AI avatar in the bottom-right corner.
 * Uses the transparent cutout PNG. Tapping it takes you to /app/ai.
 * Hidden on /app/ai itself (she's already the hero there).
 */
const CHAR_SRC = "/weebo/milli-ai-cutout-512.png";

export default function MilliFAB() {
  const nav = useNavigate();
  const loc = useLocation();
  if (loc.pathname.startsWith("/app/ai")) return null;

  return (
    <motion.button
      onClick={() => nav("/app/ai")}
      data-testid="milli-fab"
      aria-label="Chat with Milli AI"
      className="fixed z-40 flex flex-col items-center gap-0.5 active:scale-95 transition-transform"
      style={{
        right: 14,
        bottom: "calc(var(--safe-bottom) + 80px)",   // above the sticky tab bar
      }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, ease: "easeOut" }}
    >
      <div
        className="relative w-14 h-14"
        style={{
          filter:
            "drop-shadow(0 4px 12px rgba(0,0,0,0.55)) drop-shadow(0 0 14px rgba(0,229,255,0.55))",
        }}
      >
        {/* halo */}
        <div
          className="absolute inset-0 rounded-full pointer-events-none"
          style={{
            background:
              "radial-gradient(circle at 50% 45%, rgba(0,229,255,0.55) 0%, rgba(0,229,255,0.10) 45%, rgba(0,0,0,0) 72%)",
            filter: "blur(8px)",
          }}
        />
        <motion.img
          src={CHAR_SRC}
          alt="Milli AI"
          draggable={false}
          className="relative w-full h-full object-contain"
          animate={{ y: [0, -2, 0], rotate: [0, 0.8, -0.8, 0] }}
          transition={{ duration: 3.4, repeat: Infinity, ease: "easeInOut" }}
        />
      </div>
      <div
        className="px-2 py-0.5 rounded-full border border-volt/40 text-volt text-[9px] font-semibold tracking-widest uppercase"
        style={{ background: "rgba(5,7,10,0.85)", backdropFilter: "blur(12px)" }}
      >
        Milli AI
      </div>
    </motion.button>
  );
}
