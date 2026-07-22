import { motion } from "framer-motion";
import { useMemo } from "react";

/**
 * WEEBO — the MILLI AI mascot, inspired by the levitating droid from Flubber (1997).
 * A cyan chrome dome with a face-screen (pixel eyes + curve smile).
 *
 * Props:
 *   size    — pixel width (also drives height ~1.4x).
 *   state   — "idle" | "thinking" | "speaking".
 *   glow    — optional cyan halo intensity 0..1 (default varies by state).
 *   onClick — optional press handler (makes container tappable).
 */
export default function WeeboAvatar({ size = 96, state = "idle", glow, onClick, className = "" }) {
  const w = size;
  const h = Math.round(size * 1.4);
  const cx = w / 2;
  const eyeY = h * 0.44;
  const eyeGap = w * 0.18;
  const _glow = glow ?? (state === "speaking" ? 1 : state === "thinking" ? 0.7 : 0.45);

  // Bobbing motion — subtle idle, larger and faster while thinking, chirpy while speaking
  const bob = state === "speaking" ? { y: [0, -6, 2, -4, 0], rotate: [0, -2, 2, -1, 0] }
             : state === "thinking" ? { y: [0, -8, 0], rotate: [0, 1.5, -1.5, 0] }
             :                        { y: [0, -3, 0], rotate: [0, 0.8, -0.8, 0] };
  const bobDur = state === "speaking" ? 0.9 : state === "thinking" ? 2.4 : 3.6;

  // Deterministic particle field around Weebo (memoized so it doesn't reshuffle on every render)
  const particles = useMemo(() => {
    const rand = (seed) => {
      const x = Math.sin(seed) * 10000;
      return x - Math.floor(x);
    };
    return Array.from({ length: 10 }, (_, i) => ({
      id: i,
      x: rand(i + 1) * w * 1.6 - w * 0.3,
      y: rand(i + 11) * h * 1.2,
      s: 1 + rand(i + 21) * 2,
      d: 2 + rand(i + 31) * 3,
    }));
  }, [w, h]);

  return (
    <div
      className={`relative inline-block select-none ${className} ${onClick ? "cursor-pointer" : ""}`}
      style={{ width: w, height: h }}
      onClick={onClick}
      data-testid="weebo-avatar"
      data-state={state}
    >
      {/* Levitation halo */}
      <motion.div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{ filter: "blur(14px)" }}
        animate={{ opacity: [_glow * 0.6, _glow, _glow * 0.6] }}
        transition={{ duration: 1.6, repeat: Infinity, ease: "easeInOut" }}
      >
        <div
          className="absolute rounded-full"
          style={{
            left: cx - w * 0.55,
            top: h * 0.15,
            width: w * 1.1,
            height: h * 0.7,
            background: "radial-gradient(ellipse at center, rgba(0,229,255,0.55), rgba(0,229,255,0) 70%)",
          }}
        />
      </motion.div>

      {/* Floating chrome particles around her */}
      {(state !== "idle") && particles.map((p) => (
        <motion.div
          key={p.id}
          aria-hidden
          className="absolute rounded-full"
          style={{
            left: p.x,
            top: p.y,
            width: p.s,
            height: p.s,
            background: "rgba(0, 229, 255, 0.7)",
            boxShadow: "0 0 6px rgba(0,229,255,0.9)",
          }}
          animate={{ y: [0, -14, 0], opacity: [0, 0.9, 0] }}
          transition={{ duration: p.d, repeat: Infinity, delay: p.id * 0.15, ease: "easeInOut" }}
        />
      ))}

      {/* Weebo body — bobs and sways */}
      <motion.svg
        viewBox={`0 0 ${w} ${h}`}
        width={w}
        height={h}
        className="relative"
        animate={bob}
        transition={{ duration: bobDur, repeat: Infinity, ease: "easeInOut" }}
      >
        <defs>
          <linearGradient id={`weebo-body-${size}`} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%"  stopColor="#DFF7FF" />
            <stop offset="45%" stopColor="#8CE6F5" />
            <stop offset="80%" stopColor="#3AB5CE" />
            <stop offset="100%" stopColor="#0F5A70" />
          </linearGradient>
          <linearGradient id={`weebo-hi-${size}`} x1="0" x2="1" y1="0" y2="1">
            <stop offset="0%"  stopColor="rgba(255,255,255,0.85)" />
            <stop offset="60%" stopColor="rgba(255,255,255,0)" />
          </linearGradient>
          <radialGradient id={`weebo-face-${size}`} cx="0.5" cy="0.45" r="0.7">
            <stop offset="0%"  stopColor="#031015" />
            <stop offset="70%" stopColor="#000508" />
            <stop offset="100%" stopColor="#000000" />
          </radialGradient>
          <filter id={`weebo-eye-glow-${size}`}>
            <feGaussianBlur stdDeviation="1.4" result="b" />
            <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
        </defs>

        {/* Antenna wire */}
        <line x1={cx} y1={h * 0.05} x2={cx} y2={h * 0.14}
              stroke="#8CE6F5" strokeWidth={Math.max(1, w * 0.012)} strokeLinecap="round" />
        {/* Antenna bulb — pulses */}
        <motion.circle
          cx={cx} cy={h * 0.05} r={w * 0.045}
          fill="#00E5FF"
          animate={{ opacity: [0.6, 1, 0.6], r: [w * 0.04, w * 0.055, w * 0.04] }}
          transition={{ duration: 1.2, repeat: Infinity, ease: "easeInOut" }}
          style={{ filter: `drop-shadow(0 0 ${w * 0.08}px rgba(0,229,255,0.9))` }}
        />

        {/* Dome / body */}
        <ellipse
          cx={cx} cy={h * 0.5}
          rx={w * 0.42} ry={h * 0.34}
          fill={`url(#weebo-body-${size})`}
          stroke="rgba(255,255,255,0.15)"
          strokeWidth={Math.max(1, w * 0.006)}
        />
        {/* Chrome equator band */}
        <rect
          x={cx - w * 0.42} y={h * 0.5 - h * 0.02}
          width={w * 0.84} height={h * 0.045}
          fill="rgba(255,255,255,0.25)"
        />
        <rect
          x={cx - w * 0.42} y={h * 0.5 + h * 0.02}
          width={w * 0.84} height={h * 0.008}
          fill="rgba(0,0,0,0.4)"
        />
        {/* Body highlight */}
        <ellipse
          cx={cx - w * 0.14} cy={h * 0.35}
          rx={w * 0.15} ry={h * 0.1}
          fill={`url(#weebo-hi-${size})`}
        />

        {/* Face plate — the "TV screen" */}
        <ellipse
          cx={cx} cy={eyeY}
          rx={w * 0.25} ry={h * 0.14}
          fill={`url(#weebo-face-${size})`}
          stroke="rgba(0,229,255,0.4)"
          strokeWidth={Math.max(1, w * 0.008)}
        />
        {/* Scan-line sweep on the face — active states only */}
        {state !== "idle" && (
          <motion.rect
            x={cx - w * 0.24} width={w * 0.48} y={eyeY - h * 0.13} height={Math.max(1, h * 0.012)}
            fill="rgba(0,229,255,0.35)"
            animate={{ y: [eyeY - h * 0.13, eyeY + h * 0.11, eyeY - h * 0.13] }}
            transition={{ duration: 1.6, repeat: Infinity, ease: "linear" }}
          />
        )}

        {/* Eyes — square pixel style, blink and pulse per state */}
        {[-1, 1].map((side) => (
          <motion.rect
            key={side}
            x={cx + side * eyeGap - w * 0.045}
            y={eyeY - h * 0.03}
            width={w * 0.09}
            height={h * 0.06}
            rx={w * 0.02}
            fill="#66FFEA"
            filter={`url(#weebo-eye-glow-${size})`}
            animate={
              state === "speaking"
                ? { scaleY: [1, 0.15, 1, 1, 0.2, 1], opacity: [1, 1, 1, 1, 1, 1] }
                : state === "thinking"
                ? { scaleY: [1, 0.85, 1], scaleX: [1, 1.05, 1] }
                : { scaleY: [1, 0.08, 1, 1, 1] }
            }
            transition={{
              duration: state === "speaking" ? 0.9 : state === "thinking" ? 1.4 : 4.5,
              repeat: Infinity,
              times: state === "idle" ? [0, 0.5, 0.55, 0.9, 1] : undefined,
              ease: "easeInOut",
            }}
            style={{ transformOrigin: `${cx + side * eyeGap}px ${eyeY}px` }}
          />
        ))}

        {/* Mouth — curve smile, animates while speaking */}
        {state === "speaking" ? (
          <motion.path
            d={`M ${cx - w * 0.09} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.10} ${cx + w * 0.09} ${eyeY + h * 0.06}`}
            stroke="#66FFEA" strokeWidth={Math.max(1, w * 0.02)} fill="none" strokeLinecap="round"
            animate={{ d: [
              `M ${cx - w * 0.09} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.10} ${cx + w * 0.09} ${eyeY + h * 0.06}`,
              `M ${cx - w * 0.06} ${eyeY + h * 0.07} Q ${cx} ${eyeY + h * 0.05} ${cx + w * 0.06} ${eyeY + h * 0.07}`,
              `M ${cx - w * 0.09} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.11} ${cx + w * 0.09} ${eyeY + h * 0.06}`,
            ] }}
            transition={{ duration: 0.4, repeat: Infinity, ease: "easeInOut" }}
          />
        ) : (
          <path
            d={`M ${cx - w * 0.07} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.09} ${cx + w * 0.07} ${eyeY + h * 0.06}`}
            stroke="#66FFEA" strokeWidth={Math.max(1, w * 0.017)} fill="none" strokeLinecap="round"
            opacity={0.9}
          />
        )}

        {/* Base — three chrome pods */}
        {[-1, 0, 1].map((i) => (
          <g key={i}>
            <ellipse
              cx={cx + i * w * 0.20}
              cy={h * 0.88}
              rx={w * 0.055}
              ry={h * 0.03}
              fill="#B7D5DD"
              stroke="rgba(0,0,0,0.35)"
              strokeWidth={Math.max(1, w * 0.004)}
            />
            <motion.circle
              cx={cx + i * w * 0.20}
              cy={h * 0.905}
              r={w * 0.025}
              fill="#00E5FF"
              animate={{ opacity: [0.4, 1, 0.4] }}
              transition={{ duration: 1.4, repeat: Infinity, delay: i * 0.2, ease: "easeInOut" }}
              style={{ filter: `drop-shadow(0 0 ${w * 0.06}px rgba(0,229,255,0.8))` }}
            />
          </g>
        ))}
      </motion.svg>
    </div>
  );
}
