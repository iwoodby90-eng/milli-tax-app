import { motion } from "framer-motion";
import { useMemo, useId } from "react";

/**
 * WEEBO v3 — real illustrated mascot.
 * Uses the "milli-ai" hero portrait (cropped to a 1:1 square) and adds
 * layered atmospheric FX around it: portal ring, halo pulse, scan-line
 * sweep, cyan particle field, and levitation shadow.
 *
 *   size    px width  (height == size)
 *   state   "idle" | "thinking" | "speaking"
 *   onClick optional press handler
 */
const CHAR_SRC = "/weebo/milli-ai-square.png";

export default function WeeboAvatar({ size = 160, state = "idle", onClick, className = "" }) {
  const s = size;
  const uid = useId().replace(/:/g, "");
  const active = state !== "idle";

  // Bob + tiny sway per state
  const bob = state === "speaking" ? { y: [0, -6, 2, -4, 0], rotate: [0, -1.5, 1.5, -0.6, 0] }
             : state === "thinking" ? { y: [0, -9, 0], rotate: [0, 1.2, -1.2, 0] }
             :                        { y: [0, -4, 0], rotate: [0, 0.6, -0.6, 0] };
  const bobDur = state === "speaking" ? 1.0 : state === "thinking" ? 2.6 : 3.8;

  // Deterministic particle field
  const particles = useMemo(() => {
    const rand = (n) => { const x = Math.sin(n) * 10000; return x - Math.floor(x); };
    return Array.from({ length: 14 }, (_, i) => ({
      id: i,
      x: rand(i + 1) * s * 1.25 - s * 0.125,
      y: rand(i + 11) * s * 1.05,
      r: 0.9 + rand(i + 21) * 2.4,
      d: 2.4 + rand(i + 31) * 3.6,
      delay: rand(i + 41) * 2.4,
    }));
  }, [s]);

  return (
    <div
      className={`relative inline-block select-none ${onClick ? "cursor-pointer" : ""} ${className}`}
      style={{ width: s, height: s }}
      onClick={onClick}
      data-testid="weebo-avatar"
      data-state={state}
    >
      {/* Portal / floor ring — pulses harder while active */}
      <motion.div
        aria-hidden
        className="absolute pointer-events-none"
        style={{
          left: s * 0.12,
          bottom: -s * 0.02,
          width: s * 0.76,
          height: s * 0.15,
          background:
            "radial-gradient(ellipse at 50% 50%, rgba(0,229,255,0.9) 0%, rgba(0,229,255,0.35) 40%, rgba(0,229,255,0) 75%)",
          filter: "blur(3px)",
        }}
        animate={{
          opacity: active ? [0.55, 1, 0.55] : [0.35, 0.7, 0.35],
          scaleX: active ? [0.9, 1.05, 0.9] : [0.9, 1.0, 0.9],
        }}
        transition={{ duration: active ? 1.4 : 2.6, repeat: Infinity, ease: "easeInOut" }}
      />

      {/* Ambient halo behind the character */}
      <motion.div
        aria-hidden
        className="absolute inset-0 pointer-events-none rounded-full"
        style={{
          background:
            "radial-gradient(circle at 50% 42%, rgba(0,229,255,0.55) 0%, rgba(0,229,255,0.10) 45%, rgba(0,0,0,0) 70%)",
          filter: "blur(18px)",
        }}
        animate={{ opacity: active ? [0.6, 1, 0.6] : [0.45, 0.75, 0.45] }}
        transition={{ duration: 1.9, repeat: Infinity, ease: "easeInOut" }}
      />

      {/* The illustrated character */}
      <motion.img
        src={CHAR_SRC}
        alt="Milli AI"
        draggable={false}
        className="relative w-full h-full object-contain"
        style={{
          filter: active
            ? "drop-shadow(0 8px 24px rgba(0,0,0,0.55)) drop-shadow(0 0 22px rgba(0,229,255,0.45))"
            : "drop-shadow(0 6px 18px rgba(0,0,0,0.55)) drop-shadow(0 0 14px rgba(0,229,255,0.25))",
        }}
        animate={bob}
        transition={{ duration: bobDur, repeat: Infinity, ease: "easeInOut" }}
        onError={(e) => { e.currentTarget.style.display = "none"; }}
      />

      {/* Scan-line sweep across the character face during active states */}
      {active && (
        <div
          aria-hidden
          className="absolute inset-0 pointer-events-none overflow-hidden"
          style={{ mixBlendMode: "screen" }}
        >
          <motion.div
            className="absolute inset-x-0"
            style={{
              height: Math.max(2, s * 0.02),
              background:
                "linear-gradient(90deg, transparent, rgba(140,240,255,0.55) 50%, transparent)",
              filter: `blur(${s * 0.006}px)`,
            }}
            animate={{ y: [s * 0.08, s * 0.7, s * 0.08], opacity: [0, 0.75, 0] }}
            transition={{
              duration: state === "speaking" ? 1.4 : 2.2,
              repeat: Infinity,
              ease: "linear",
            }}
          />
        </div>
      )}

      {/* Ambient particles — only during active states */}
      {active && particles.map((p) => (
        <motion.div
          key={p.id}
          aria-hidden
          className="absolute rounded-full pointer-events-none"
          style={{
            left: p.x,
            top: p.y,
            width: p.r,
            height: p.r,
            background: "rgba(0, 229, 255, 0.9)",
            boxShadow: "0 0 6px rgba(0,229,255,1), 0 0 14px rgba(0,229,255,0.55)",
          }}
          animate={{ y: [0, -22, 0], opacity: [0, 0.95, 0] }}
          transition={{ duration: p.d, repeat: Infinity, delay: p.delay, ease: "easeInOut" }}
        />
      ))}

      {/* Speaking pulse ring — synchronizes with her mouth animation */}
      {state === "speaking" && (
        <motion.div
          aria-hidden
          className="absolute rounded-full pointer-events-none"
          style={{
            left: s * 0.16,
            top: s * 0.16,
            width: s * 0.68,
            height: s * 0.68,
            border: "1px solid rgba(0,229,255,0.55)",
          }}
          animate={{ scale: [1, 1.25, 1], opacity: [0.75, 0, 0.75] }}
          transition={{ duration: 1.1, repeat: Infinity, ease: "easeOut" }}
        />
      )}

      {/* SR-only status */}
      <span className="sr-only" aria-live="polite">
        {state === "thinking" ? "Milli AI is thinking"
          : state === "speaking" ? "Milli AI is responding"
          : "Milli AI is idle"}
      </span>
      {/* uid kept to avoid unused-var lint */}
      <span data-uid={uid} className="hidden" />
    </div>
  );
}
