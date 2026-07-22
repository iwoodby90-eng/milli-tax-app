import { motion } from "framer-motion";
import { useMemo, useEffect, useState } from "react";

/**
 * WEEBO v4 — 3D-feel, transparent, roaming.
 *
 * Uses the background-removed PNG cutout (rembg) and animates it as if it were
 * a living companion floating in the hero area:
 *   - continuous horizontal / vertical drift path (not just bob)
 *   - 3D-feel via subtle scale + rotateY perspective + tilt
 *   - state-based intensity (idle vs thinking vs speaking)
 *   - atmospheric FX around her (halo, particles, scan sweep, portal ring)
 *
 * Props:
 *   size     px width/height of the character (defaults 180)
 *   state    "idle" | "thinking" | "speaking"
 *   stageW   px width of her roaming area (defaults 2x size)
 *   stageH   px height of her roaming area (defaults 1.5x size)
 *   onClick  optional press handler
 */
const CHAR_SRC = "/weebo/milli-ai-cutout-512.png";

export default function WeeboAvatar({
  size = 180,
  state = "idle",
  stageW,
  stageH,
  onClick,
  className = "",
}) {
  const s = size;
  const W = stageW || Math.round(s * 1.8);
  const H = stageH || Math.round(s * 1.35);
  const active = state !== "idle";

  // Drift range — how far she wanders from center
  const dx = state === "speaking" ? s * 0.10
           : state === "thinking" ? s * 0.28
           :                        s * 0.22;
  const dy = state === "speaking" ? s * 0.06
           : state === "thinking" ? s * 0.14
           :                        s * 0.10;

  // Speed
  const dur = state === "speaking" ? 3.2 : state === "thinking" ? 4.8 : 6.6;

  // Particles
  const particles = useMemo(() => {
    const rand = (n) => { const x = Math.sin(n) * 10000; return x - Math.floor(x); };
    return Array.from({ length: 16 }, (_, i) => ({
      id: i,
      x: rand(i + 1) * W,
      y: rand(i + 11) * H * 0.9,
      r: 0.8 + rand(i + 21) * 2.4,
      d: 2.4 + rand(i + 31) * 4,
      delay: rand(i + 41) * 3,
    }));
  }, [W, H]);

  // Preload check so the halo/portal don't sit alone during first paint
  const [loaded, setLoaded] = useState(false);
  useEffect(() => {
    const img = new window.Image();
    img.onload = () => setLoaded(true);
    img.src = CHAR_SRC;
  }, []);

  const cx = W / 2, cy = H / 2 + s * 0.04;

  return (
    <div
      className={`relative select-none ${onClick ? "cursor-pointer" : ""} ${className}`}
      style={{ width: W, height: H, perspective: 900 }}
      onClick={onClick}
      data-testid="weebo-avatar"
      data-state={state}
    >
      {/* Portal levitation ring on the floor — follows her drift */}
      <motion.div
        aria-hidden
        className="absolute pointer-events-none"
        style={{
          left: cx - s * 0.42,
          top: cy + s * 0.38,
          width: s * 0.84,
          height: s * 0.14,
          background:
            "radial-gradient(ellipse at 50% 50%, rgba(0,229,255,0.95) 0%, rgba(0,229,255,0.35) 45%, rgba(0,229,255,0) 78%)",
          filter: "blur(4px)",
        }}
        animate={{
          x: [-dx * 0.6, dx * 0.6, -dx * 0.6],
          opacity: active ? [0.65, 1, 0.65] : [0.45, 0.8, 0.45],
          scaleX: active ? [0.85, 1.08, 0.85] : [0.9, 1.02, 0.9],
        }}
        transition={{ duration: dur * 0.9, repeat: Infinity, ease: "easeInOut" }}
      />

      {/* Ambient halo behind the character — travels with her */}
      <motion.div
        aria-hidden
        className="absolute pointer-events-none rounded-full"
        style={{
          left: cx - s * 0.65,
          top:  cy - s * 0.6,
          width: s * 1.3,
          height: s * 1.15,
          background:
            "radial-gradient(circle at 50% 42%, rgba(0,229,255,0.55) 0%, rgba(0,229,255,0.10) 45%, rgba(0,0,0,0) 72%)",
          filter: "blur(20px)",
        }}
        animate={{
          x: [-dx, dx, -dx],
          y: [-dy, dy * 0.4, -dy],
          opacity: active ? [0.65, 1, 0.65] : [0.5, 0.8, 0.5],
        }}
        transition={{ duration: dur, repeat: Infinity, ease: "easeInOut" }}
      />

      {/* Ambient particles */}
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

      {/* THE CHARACTER — transparent PNG, wanders + tilts + subtle 3D scale */}
      <motion.div
        className="absolute"
        style={{
          left: cx - s / 2,
          top:  cy - s / 2,
          width: s,
          height: s,
          transformStyle: "preserve-3d",
        }}
        animate={{
          x: [-dx, dx, -dx * 0.6, dx * 0.4, -dx],
          y: [-dy, dy * 0.5, -dy * 0.4, dy, -dy],
          rotate: [0, -3, 2, -1, 0],
          rotateY: [-8, 8, -6, 4, -8],
          scale: [1, 1.03, 0.98, 1.02, 1],
        }}
        transition={{ duration: dur, repeat: Infinity, ease: "easeInOut" }}
      >
        {loaded && (
          <motion.img
            src={CHAR_SRC}
            alt="Milli AI"
            draggable={false}
            className="w-full h-full object-contain"
            style={{
              filter: active
                ? "drop-shadow(0 12px 22px rgba(0,0,0,0.65)) drop-shadow(0 0 24px rgba(0,229,255,0.55))"
                : "drop-shadow(0 10px 18px rgba(0,0,0,0.6)) drop-shadow(0 0 16px rgba(0,229,255,0.35))",
              WebkitFilter: active
                ? "drop-shadow(0 12px 22px rgba(0,0,0,0.65)) drop-shadow(0 0 24px rgba(0,229,255,0.55))"
                : "drop-shadow(0 10px 18px rgba(0,0,0,0.6)) drop-shadow(0 0 16px rgba(0,229,255,0.35))",
            }}
            animate={
              state === "speaking"
                ? { scale: [1, 1.02, 1] }
                : state === "thinking"
                ? { rotate: [0, 1, -1, 0] }
                : { scale: [1, 1.005, 1] }
            }
            transition={{
              duration: state === "speaking" ? 0.6 : 3.5,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          />
        )}
      </motion.div>

      {/* Speaking pulse ring — expanding wave from her */}
      {state === "speaking" && (
        <>
          <motion.div
            aria-hidden
            className="absolute pointer-events-none rounded-full"
            style={{
              left: cx - s * 0.34,
              top:  cy - s * 0.34,
              width: s * 0.68,
              height: s * 0.68,
              border: "1px solid rgba(0,229,255,0.55)",
            }}
            animate={{ scale: [1, 1.4, 1], opacity: [0.75, 0, 0.75] }}
            transition={{ duration: 1.1, repeat: Infinity, ease: "easeOut" }}
          />
          <motion.div
            aria-hidden
            className="absolute pointer-events-none rounded-full"
            style={{
              left: cx - s * 0.34,
              top:  cy - s * 0.34,
              width: s * 0.68,
              height: s * 0.68,
              border: "1px solid rgba(0,229,255,0.35)",
            }}
            animate={{ scale: [1, 1.65, 1], opacity: [0.55, 0, 0.55] }}
            transition={{ duration: 1.6, repeat: Infinity, ease: "easeOut", delay: 0.3 }}
          />
        </>
      )}

      {/* SR-only status */}
      <span className="sr-only" aria-live="polite">
        {state === "thinking" ? "Milli AI is thinking"
          : state === "speaking" ? "Milli AI is responding"
          : "Milli AI is idle"}
      </span>
    </div>
  );
}
