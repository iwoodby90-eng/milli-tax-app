import { motion } from "framer-motion";
import { useMemo, useEffect, useState } from "react";

/**
 * WEEBO v5.0 — SENIOR FINISH: Full-body 3D character with arms.
 *
 * Uses the high-fidelity 3D character asset (head + body + arms).
 * CSS mask uses the image's own alpha channel → zero sticker/background artifacts.
 * object-fit: contain enforced. Background: transparent !important everywhere.
 *
 * Props:
 *   size     px width/height of the character (defaults 180)
 *   state    "idle" | "thinking" | "speaking"
 *   stageW   px width of her roaming area (defaults 2x size)
 *   stageH   px height of her roaming area (defaults 1.5x size)
 *   onClick  optional press handler
 */
const CHAR_SRC = "https://static.prod-images.emergentagent.com/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/images/6b5e562c203f0d0bbde4f39e0124c310de74c4661385956aef646a69b9d2dabf.jpeg";

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
  const H = stageH || Math.round(s * 1.5);
  const active = state !== "idle";

  const dx = state === "speaking" ? s * 0.08
           : state === "thinking" ? s * 0.22
           :                        s * 0.16;
  const dy = state === "speaking" ? s * 0.04
           : state === "thinking" ? s * 0.10
           :                        s * 0.08;

  const dur = state === "speaking" ? 3.2 : state === "thinking" ? 4.8 : 6.6;

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

  const [loaded, setLoaded] = useState(false);
  useEffect(() => {
    const img = new window.Image();
    img.onload = () => setLoaded(true);
    img.onerror = () => setLoaded(true); // show anyway
    img.src = CHAR_SRC;
  }, []);

  const cx = W / 2, cy = H / 2;

  return (
    <div
      className={`relative select-none ${onClick ? "cursor-pointer" : ""} ${className}`}
      style={{
        width: W,
        height: H,
        perspective: 900,
        background: "transparent !important",
        backgroundColor: "transparent",
      }}
      onClick={onClick}
      data-testid="weebo-avatar"
      data-state={state}
    >
      {/* Portal levitation ring on the floor */}
      <motion.div
        aria-hidden
        className="absolute pointer-events-none"
        style={{
          left: cx - s * 0.38,
          top: cy + s * 0.52,
          width: s * 0.76,
          height: s * 0.12,
          background:
            "radial-gradient(ellipse at 50% 50%, rgba(0,229,255,0.90) 0%, rgba(0,229,255,0.30) 45%, rgba(0,229,255,0) 78%)",
          filter: "blur(4px)",
        }}
        animate={{
          x: [-dx * 0.5, dx * 0.5, -dx * 0.5],
          opacity: active ? [0.65, 1, 0.65] : [0.45, 0.8, 0.45],
          scaleX: active ? [0.85, 1.08, 0.85] : [0.9, 1.02, 0.9],
        }}
        transition={{ duration: dur * 0.9, repeat: Infinity, ease: "easeInOut" }}
      />

      {/* Ambient halo behind the character */}
      <motion.div
        aria-hidden
        className="absolute pointer-events-none rounded-full"
        style={{
          left: cx - s * 0.55,
          top:  cy - s * 0.5,
          width: s * 1.1,
          height: s * 1.1,
          background:
            "radial-gradient(circle at 50% 40%, rgba(0,229,255,0.45) 0%, rgba(0,229,255,0.08) 45%, rgba(0,0,0,0) 72%)",
          filter: "blur(20px)",
        }}
        animate={{
          x: [-dx, dx, -dx],
          y: [-dy, dy * 0.4, -dy],
          opacity: active ? [0.55, 0.9, 0.55] : [0.4, 0.7, 0.4],
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

      {/* THE CHARACTER — full-body 3D with arms, masked via alpha */}
      <motion.div
        className="absolute"
        style={{
          left: cx - s * 0.55,
          top:  cy - s * 0.55,
          width: s * 1.1,
          height: s * 1.1,
          transformStyle: "preserve-3d",
          background: "transparent",
          backgroundColor: "transparent",
        }}
        animate={{
          x: [-dx * 0.7, dx * 0.7, -dx * 0.4, dx * 0.3, -dx * 0.7],
          y: [-dy, dy * 0.4, -dy * 0.3, dy * 0.7, -dy],
          rotate: [0, -2, 1.5, -0.8, 0],
          rotateY: [-5, 5, -3, 2, -5],
          scale: [1, 1.02, 0.99, 1.01, 1],
        }}
        transition={{ duration: dur, repeat: Infinity, ease: "easeInOut" }}
      >
        {loaded && (
          <motion.img
            src={CHAR_SRC}
            alt="Milli AI"
            draggable={false}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "contain",
              background: "transparent",
              backgroundColor: "transparent",
              border: "none",
              boxShadow: "none",
              /* Alpha-channel mask — eliminates any background artifacts */
              maskImage: `url(${CHAR_SRC})`,
              maskSize: "contain",
              maskRepeat: "no-repeat",
              maskPosition: "center",
              maskMode: "alpha",
              WebkitMaskImage: `url(${CHAR_SRC})`,
              WebkitMaskSize: "contain",
              WebkitMaskRepeat: "no-repeat",
              WebkitMaskPosition: "center",
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

      {/* Speaking pulse ring */}
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
