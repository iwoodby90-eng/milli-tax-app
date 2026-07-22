import { motion } from "framer-motion";
import { useMemo, useId } from "react";

/**
 * WEEBO v2 — cinematic build.
 * Chrome dome, CRT face-screen, volumetric thruster cones, rim lighting,
 * ground shadow, ambient particle field. Fully self-contained SVG.
 *
 *   size    px width  (height ~ 1.55x)
 *   state   "idle" | "thinking" | "speaking"
 *   glow    optional halo intensity override
 *   onClick optional press handler
 */
export default function WeeboAvatar({ size = 128, state = "idle", glow, onClick, className = "" }) {
  const w = size;
  const h = Math.round(size * 1.55);
  const cx = w / 2;
  const uid = useId().replace(/:/g, "");            // unique gradient ids
  const _glow = glow ?? (state === "speaking" ? 1 : state === "thinking" ? 0.75 : 0.55);
  const eyeY = h * 0.42;
  const eyeGap = w * 0.16;

  // Layout — body sits in upper 62%, thrusters + shadow occupy lower 38%
  const bodyCy = h * 0.42;
  const bodyRx = w * 0.42;
  const bodyRy = h * 0.30;
  const baseY  = h * 0.78;

  // Bobbing motion
  const bob = state === "speaking" ? { y: [0, -5, 2, -3, 0], rotate: [0, -1.4, 1.4, -0.6, 0] }
             : state === "thinking" ? { y: [0, -7, 0], rotate: [0, 1.1, -1.1, 0] }
             :                        { y: [0, -3, 0], rotate: [0, 0.6, -0.6, 0] };
  const bobDur = state === "speaking" ? 0.95 : state === "thinking" ? 2.5 : 3.8;

  // Deterministic particle positions
  const particles = useMemo(() => {
    const rand = (s) => { const x = Math.sin(s) * 10000; return x - Math.floor(x); };
    return Array.from({ length: 14 }, (_, i) => ({
      id: i,
      x: rand(i + 1) * w * 1.4 - w * 0.2,
      y: rand(i + 11) * h * 0.9,
      s: 0.8 + rand(i + 21) * 2.2,
      d: 2 + rand(i + 31) * 4,
      delay: rand(i + 41) * 2,
    }));
  }, [w, h]);

  return (
    <div
      className={`relative inline-block select-none ${onClick ? "cursor-pointer" : ""} ${className}`}
      style={{ width: w, height: h }}
      onClick={onClick}
      data-testid="weebo-avatar"
      data-state={state}
    >
      {/* ────────── Ambient halo behind Weebo ────────── */}
      <motion.div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{ filter: "blur(22px)" }}
        animate={{ opacity: [_glow * 0.55, _glow, _glow * 0.55] }}
        transition={{ duration: 1.9, repeat: Infinity, ease: "easeInOut" }}
      >
        <div
          className="absolute rounded-full"
          style={{
            left: cx - w * 0.65,
            top: h * 0.10,
            width: w * 1.3,
            height: h * 0.68,
            background:
              "radial-gradient(ellipse at 50% 40%, rgba(0,229,255,0.55), rgba(0,229,255,0.08) 55%, rgba(0,0,0,0) 78%)",
          }}
        />
      </motion.div>

      {/* Ambient chrome/data particles */}
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
            background: "rgba(0, 229, 255, 0.85)",
            boxShadow: "0 0 6px rgba(0,229,255,0.9), 0 0 12px rgba(0,229,255,0.5)",
          }}
          animate={{ y: [0, -22, 0], opacity: [0, 0.95, 0] }}
          transition={{ duration: p.d, repeat: Infinity, delay: p.delay, ease: "easeInOut" }}
        />
      ))}

      {/* ────────── Weebo body ────────── */}
      <motion.svg
        viewBox={`0 0 ${w} ${h}`}
        width={w}
        height={h}
        className="relative"
        animate={bob}
        transition={{ duration: bobDur, repeat: Infinity, ease: "easeInOut" }}
      >
        <defs>
          {/* Cinematic chrome body — multi-stop reflection */}
          <linearGradient id={`body-${uid}`} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%"   stopColor="#F4FCFF" />
            <stop offset="18%"  stopColor="#CCECF4" />
            <stop offset="42%"  stopColor="#7BC9DA" />
            <stop offset="60%"  stopColor="#3A9BB3" />
            <stop offset="82%"  stopColor="#0B5568" />
            <stop offset="100%" stopColor="#03222C" />
          </linearGradient>
          {/* Rim light — bright cyan crescent along top-right */}
          <radialGradient id={`rim-${uid}`} cx="0.7" cy="0.15" r="0.75">
            <stop offset="0%"  stopColor="rgba(180,245,255,0.95)" />
            <stop offset="35%" stopColor="rgba(80,220,240,0.35)" />
            <stop offset="70%" stopColor="rgba(0,0,0,0)" />
          </radialGradient>
          {/* Sub-body ambient occlusion (shadow at bottom) */}
          <radialGradient id={`ao-${uid}`} cx="0.5" cy="0.9" r="0.6">
            <stop offset="0%"  stopColor="rgba(0,0,0,0.5)" />
            <stop offset="100%" stopColor="rgba(0,0,0,0)" />
          </radialGradient>
          {/* Face-plate CRT — dark curved screen with cyan phosphor bloom */}
          <radialGradient id={`face-${uid}`} cx="0.5" cy="0.45" r="0.75">
            <stop offset="0%"  stopColor="#06222B" />
            <stop offset="55%" stopColor="#020A0E" />
            <stop offset="100%" stopColor="#000000" />
          </radialGradient>
          <linearGradient id={`face-sheen-${uid}`} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%"  stopColor="rgba(120,240,255,0.3)" />
            <stop offset="35%" stopColor="rgba(0,0,0,0)" />
            <stop offset="100%" stopColor="rgba(0,229,255,0.10)" />
          </linearGradient>
          {/* Chrome equator band */}
          <linearGradient id={`chrome-${uid}`} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%"   stopColor="#F5FCFF" />
            <stop offset="45%"  stopColor="#B9DAE3" />
            <stop offset="55%"  stopColor="#3A6E7A" />
            <stop offset="100%" stopColor="#123540" />
          </linearGradient>
          {/* Thruster beam */}
          <linearGradient id={`beam-${uid}`} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%"  stopColor="rgba(255,255,255,0.95)" />
            <stop offset="35%" stopColor="rgba(0,229,255,0.85)" />
            <stop offset="100%" stopColor="rgba(0,80,120,0)" />
          </linearGradient>
          <radialGradient id={`hot-${uid}`} cx="0.5" cy="0.5" r="0.5">
            <stop offset="0%"  stopColor="#EAFEFF" />
            <stop offset="55%" stopColor="#00E5FF" />
            <stop offset="100%" stopColor="rgba(0,80,120,0)" />
          </radialGradient>
          {/* Eye glow filter */}
          <filter id={`eye-glow-${uid}`} x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="1.6" result="b" />
            <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
          <filter id={`face-inner-${uid}`}>
            <feGaussianBlur stdDeviation="0.9" />
          </filter>
        </defs>

        {/* ── Ground shadow (soft ellipse under her) ── */}
        <motion.ellipse
          cx={cx} cy={h * 0.94}
          rx={w * 0.28} ry={h * 0.028}
          fill="rgba(0,0,0,0.55)"
          animate={{ rx: [w * 0.28, w * 0.24, w * 0.28], opacity: [0.55, 0.35, 0.55] }}
          transition={{ duration: bobDur, repeat: Infinity, ease: "easeInOut" }}
        />

        {/* ── Antenna: chrome shaft + glass bulb ── */}
        <line
          x1={cx} y1={h * 0.03}
          x2={cx} y2={h * 0.135}
          stroke={`url(#chrome-${uid})`}
          strokeWidth={Math.max(1.4, w * 0.015)}
          strokeLinecap="round"
        />
        <motion.g
          animate={{ opacity: [0.85, 1, 0.85] }}
          transition={{ duration: 1.4, repeat: Infinity, ease: "easeInOut" }}
        >
          <circle cx={cx} cy={h * 0.03} r={w * 0.06} fill="#0DE8FF" opacity="0.35" />
          <motion.circle
            cx={cx} cy={h * 0.03}
            r={w * 0.038}
            fill="#EAFEFF"
            animate={{ r: [w * 0.032, w * 0.048, w * 0.032] }}
            transition={{ duration: 1.4, repeat: Infinity, ease: "easeInOut" }}
            style={{ filter: `drop-shadow(0 0 ${w * 0.10}px rgba(0,229,255,1))` }}
          />
        </motion.g>

        {/* ── Body: chrome dome (base + rim light + AO) ── */}
        <ellipse
          cx={cx} cy={bodyCy}
          rx={bodyRx} ry={bodyRy}
          fill={`url(#body-${uid})`}
          stroke="rgba(255,255,255,0.10)"
          strokeWidth={Math.max(1, w * 0.005)}
        />
        {/* AO shadow at bottom of the body */}
        <ellipse
          cx={cx} cy={bodyCy + bodyRy * 0.55}
          rx={bodyRx * 0.92} ry={bodyRy * 0.55}
          fill={`url(#ao-${uid})`}
        />
        {/* Rim light crescent (top-right highlight) */}
        <ellipse
          cx={cx} cy={bodyCy}
          rx={bodyRx * 0.98} ry={bodyRy * 0.95}
          fill={`url(#rim-${uid})`}
          opacity="0.85"
        />
        {/* Reflection strips on dome */}
        <ellipse
          cx={cx - bodyRx * 0.35} cy={bodyCy - bodyRy * 0.55}
          rx={w * 0.14} ry={h * 0.028}
          fill="rgba(255,255,255,0.55)"
          transform={`rotate(-18, ${cx - bodyRx * 0.35}, ${bodyCy - bodyRy * 0.55})`}
        />
        <ellipse
          cx={cx + bodyRx * 0.42} cy={bodyCy - bodyRy * 0.30}
          rx={w * 0.055} ry={h * 0.012}
          fill="rgba(255,255,255,0.4)"
          transform={`rotate(-20, ${cx + bodyRx * 0.42}, ${bodyCy - bodyRy * 0.30})`}
        />

        {/* ── Chrome equator band ── */}
        <rect
          x={cx - bodyRx * 0.99} y={bodyCy + bodyRy * 0.02}
          width={bodyRx * 1.98} height={h * 0.048}
          fill={`url(#chrome-${uid})`}
        />
        {/* Rivet dots on the band */}
        {[-0.7, -0.35, 0, 0.35, 0.7].map((k, i) => (
          <circle
            key={i}
            cx={cx + bodyRx * k}
            cy={bodyCy + bodyRy * 0.02 + h * 0.024}
            r={w * 0.008}
            fill="rgba(15,25,30,0.9)"
          />
        ))}

        {/* ── Face plate (CRT screen) ── */}
        <g>
          <ellipse
            cx={cx} cy={eyeY}
            rx={w * 0.26} ry={h * 0.13}
            fill={`url(#face-${uid})`}
            stroke="rgba(0,229,255,0.55)"
            strokeWidth={Math.max(1, w * 0.008)}
          />
          {/* Glass sheen */}
          <ellipse
            cx={cx} cy={eyeY}
            rx={w * 0.245} ry={h * 0.118}
            fill={`url(#face-sheen-${uid})`}
          />
          {/* Fine scanlines */}
          <g opacity="0.35" clipPath={`inset(0 0 0 0 round ${h * 0.13}px / ${w * 0.26}px)`}>
            {Array.from({ length: 10 }, (_, i) => (
              <rect
                key={i}
                x={cx - w * 0.26} width={w * 0.52}
                y={eyeY - h * 0.13 + i * (h * 0.026)}
                height={Math.max(0.5, h * 0.004)}
                fill="rgba(0,229,255,0.35)"
              />
            ))}
          </g>
          {/* Sweep beam during active states */}
          {state !== "idle" && (
            <motion.rect
              x={cx - w * 0.25} width={w * 0.50}
              y={eyeY - h * 0.13} height={Math.max(1, h * 0.015)}
              fill="rgba(140,240,255,0.7)"
              animate={{ y: [eyeY - h * 0.13, eyeY + h * 0.10, eyeY - h * 0.13] }}
              transition={{ duration: 1.5, repeat: Infinity, ease: "linear" }}
              style={{ filter: `blur(${w * 0.006}px)` }}
            />
          )}
        </g>

        {/* ── Eyes (halo + core + inner highlight) ── */}
        {[-1, 1].map((side) => {
          const ex = cx + side * eyeGap;
          const ey = eyeY - h * 0.005;
          return (
            <motion.g
              key={side}
              filter={`url(#eye-glow-${uid})`}
              animate={
                state === "speaking"
                  ? { opacity: [1, 1, 1, 1, 1, 1] }
                  : state === "thinking"
                  ? { scale: [1, 1.05, 1] }
                  : { opacity: [1, 1, 1, 1, 1] }
              }
              transition={{
                duration: state === "speaking" ? 0.9 : state === "thinking" ? 1.4 : 4.5,
                repeat: Infinity,
                ease: "easeInOut",
              }}
              style={{ transformOrigin: `${ex}px ${ey}px` }}
            >
              {/* halo */}
              <ellipse cx={ex} cy={ey} rx={w * 0.06} ry={h * 0.045} fill="rgba(0,229,255,0.35)" />
              {/* core */}
              <motion.rect
                x={ex - w * 0.038} y={ey - h * 0.028}
                width={w * 0.076} height={h * 0.056}
                rx={w * 0.014}
                fill="#B7FFFB"
                animate={
                  state === "speaking"
                    ? { scaleY: [1, 0.18, 1, 1, 0.22, 1] }
                    : state === "thinking"
                    ? { scaleY: [1, 0.9, 1], scaleX: [1, 1.08, 1] }
                    : { scaleY: [1, 0.08, 1, 1, 1] }
                }
                transition={{
                  duration: state === "speaking" ? 0.9 : state === "thinking" ? 1.4 : 4.5,
                  repeat: Infinity,
                  times: state === "idle" ? [0, 0.48, 0.52, 0.9, 1] : undefined,
                  ease: "easeInOut",
                }}
                style={{ transformOrigin: `${ex}px ${ey}px` }}
              />
              {/* pupil highlight */}
              <circle cx={ex - w * 0.012} cy={ey - h * 0.008} r={w * 0.010} fill="#FFFFFF" opacity="0.85" />
            </motion.g>
          );
        })}

        {/* ── Mouth ── */}
        {state === "speaking" ? (
          <motion.path
            stroke="#8FF6FF" strokeWidth={Math.max(1, w * 0.020)} fill="none" strokeLinecap="round"
            filter={`url(#eye-glow-${uid})`}
            animate={{ d: [
              `M ${cx - w * 0.09} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.10} ${cx + w * 0.09} ${eyeY + h * 0.06}`,
              `M ${cx - w * 0.06} ${eyeY + h * 0.075} Q ${cx} ${eyeY + h * 0.045} ${cx + w * 0.06} ${eyeY + h * 0.075}`,
              `M ${cx - w * 0.09} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.115} ${cx + w * 0.09} ${eyeY + h * 0.06}`,
            ] }}
            transition={{ duration: 0.35, repeat: Infinity, ease: "easeInOut" }}
          />
        ) : (
          <path
            d={`M ${cx - w * 0.075} ${eyeY + h * 0.06} Q ${cx} ${eyeY + h * 0.095} ${cx + w * 0.075} ${eyeY + h * 0.06}`}
            stroke="#8FF6FF" strokeWidth={Math.max(1, w * 0.018)} fill="none" strokeLinecap="round"
            opacity="0.9"
            filter={`url(#eye-glow-${uid})`}
          />
        )}

        {/* ── Volumetric thruster beams under her three pods ── */}
        {[-1, 0, 1].map((i) => {
          const px = cx + i * w * 0.22;
          return (
            <g key={i}>
              {/* Beam cone */}
              <motion.path
                d={`M ${px - w * 0.05} ${baseY + h * 0.01} L ${px + w * 0.05} ${baseY + h * 0.01} L ${px + w * 0.11} ${baseY + h * 0.16} L ${px - w * 0.11} ${baseY + h * 0.16} Z`}
                fill={`url(#beam-${uid})`}
                animate={{ opacity: [0.35, 0.75, 0.35] }}
                transition={{ duration: 1.6, repeat: Infinity, delay: i * 0.2, ease: "easeInOut" }}
                style={{ filter: `blur(${w * 0.01}px)` }}
              />
              {/* Chrome pod bottom */}
              <ellipse
                cx={px} cy={baseY}
                rx={w * 0.06} ry={h * 0.024}
                fill={`url(#chrome-${uid})`}
                stroke="rgba(0,0,0,0.35)"
                strokeWidth={Math.max(1, w * 0.004)}
              />
              {/* Hot core inside the pod */}
              <motion.ellipse
                cx={px} cy={baseY + h * 0.006}
                rx={w * 0.032} ry={h * 0.013}
                fill={`url(#hot-${uid})`}
                animate={{ opacity: [0.6, 1, 0.6] }}
                transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.15, ease: "easeInOut" }}
                style={{ filter: `drop-shadow(0 0 ${w * 0.08}px rgba(0,229,255,0.95))` }}
              />
            </g>
          );
        })}
      </motion.svg>
    </div>
  );
}
