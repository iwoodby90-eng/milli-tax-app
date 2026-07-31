import { useRef, useEffect, useState, useMemo } from "react";

/**
 * MilliLogo v2 — Zero-artifact hardware component.
 *
 * The M is rendered as pure SVG strokes with NO container, NO background,
 * NO box-shadow, NO rectangular divs. It exists as geometry only.
 *
 * - Left/center strokes: 5-stop chrome metallic gradient
 * - Right vertical stroke: separate element, neon cyan (#00E5FF) with SVG glow
 * - Edge highlights: thin bright strokes simulate light catching metal edges
 * - Specular sweep: animated gradient masked to the M path (no rectangle)
 * - Container: display:contents-like, zero visual footprint
 */
export default function MilliLogo({ size = 80, glow = true, motion = true }) {
  const ref = useRef(null);
  const [tilt, setTilt] = useState({ x: 0, y: 0 });

  useEffect(() => {
    if (!motion) return;
    let raf;
    const handler = (e) => {
      if (e.gamma != null) {
        // Device orientation (mobile)
        const x = Math.max(-20, Math.min(20, e.gamma * 0.6));
        const y = Math.max(-20, Math.min(20, (e.beta - 45) * 0.4));
        raf = requestAnimationFrame(() => setTilt({ x, y }));
      }
    };
    const mouseHandler = (e) => {
      if (!ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      const x = ((e.clientX - cx) / (window.innerWidth / 2)) * 20;
      const y = ((e.clientY - cy) / (window.innerHeight / 2)) * 20;
      raf = requestAnimationFrame(() => setTilt({ x, y }));
    };

    if ("ontouchstart" in window) {
      window.addEventListener("deviceorientation", handler, { passive: true });
    } else {
      window.addEventListener("mousemove", mouseHandler, { passive: true });
    }
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("deviceorientation", handler);
      window.removeEventListener("mousemove", mouseHandler);
    };
  }, [motion]);

  // M geometry (all values in 0-100 viewBox)
  const sw = 9; // stroke width as % of viewBox
  const mPath = "M 12 85 L 12 15 L 50 45 L 88 15 L 88 85"; // full M
  const leftPath = "M 12 85 L 12 15 L 50 45 L 88 15"; // left portion (chrome)
  const rightStroke = { x: 88, y1: 15, y2: 85 }; // right vertical (cyan)

  // Specular angle from tilt
  const specAngle = useMemo(() => 135 + (tilt.x || 0) * 0.8, [tilt.x]);

  return (
    <div
      ref={ref}
      style={{
        /* ZERO visual footprint: no bg, no border, no shadow, no outline */
        width: size,
        height: size,
        position: "relative",
        display: "inline-block",
        background: "transparent",
        border: "none",
        outline: "none",
        boxShadow: "none",
        padding: 0,
        margin: 0,
        lineHeight: 0,
        overflow: "visible",
      }}
    >
      <svg
        viewBox="0 0 100 100"
        width={size}
        height={size}
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ display: "block", overflow: "visible" }}
      >
        <defs>
          {/* 5-stop chrome metallic gradient */}
          <linearGradient id={`ml-chrome-${size}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#7A7F87" />
            <stop offset="22%" stopColor="#E8ECF0" />
            <stop offset="45%" stopColor="#B8BCC2" />
            <stop offset="70%" stopColor="#F4F6F8" />
            <stop offset="100%" stopColor="#8A8F96" />
          </linearGradient>

          {/* Darker chrome for shadow depth */}
          <linearGradient id={`ml-chrome-dark-${size}`} x1="0%" y1="100%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#4A4E54" />
            <stop offset="50%" stopColor="#6A6E74" />
            <stop offset="100%" stopColor="#4A4E54" />
          </linearGradient>

          {/* Cyan vertical gradient for right stroke */}
          <linearGradient id={`ml-cyan-${size}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#00FFEA" />
            <stop offset="40%" stopColor="#00E5FF" />
            <stop offset="100%" stopColor="#0097A7" />
          </linearGradient>

          {/* Specular highlight gradient (moves with tilt) */}
          <linearGradient id={`ml-spec-${size}`} x1="0%" y1="0%" x2="100%" y2="100%"
            gradientTransform={`rotate(${specAngle} 0.5 0.5)`}>
            <stop offset="0%" stopColor="rgba(255,255,255,0)" />
            <stop offset="35%" stopColor="rgba(255,255,255,0)" />
            <stop offset="50%" stopColor="rgba(255,255,255,0.4)" />
            <stop offset="65%" stopColor="rgba(255,255,255,0)" />
            <stop offset="100%" stopColor="rgba(255,255,255,0)" />
          </linearGradient>

          {/* Cyan glow filter */}
          <filter id={`ml-glow-${size}`} x="-40%" y="-40%" width="180%" height="180%">
            <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur1" />
            <feGaussianBlur in="SourceGraphic" stdDeviation="1" result="blur2" />
            <feMerge>
              <feMergeNode in="blur1" />
              <feMergeNode in="blur2" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Soft shadow filter */}
          <filter id={`ml-shadow-${size}`} x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="1.5" dy="2" stdDeviation="2" floodColor="rgba(0,0,0,0.6)" />
          </filter>
        </defs>

        {/* Layer 1: Drop shadow (subtle depth) */}
        <path
          d={mPath}
          stroke="rgba(0,0,0,0.5)"
          strokeWidth={sw + 1.5}
          strokeLinecap="round"
          strokeLinejoin="round"
          transform="translate(0.8, 1.2)"
        />

        {/* Layer 2: Dark chrome base (gives depth to metallic) */}
        <path
          d={leftPath}
          stroke={`url(#ml-chrome-dark-${size})`}
          strokeWidth={sw + 0.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Layer 3: Main chrome M (left 3 strokes) */}
        <path
          d={leftPath}
          stroke={`url(#ml-chrome-${size})`}
          strokeWidth={sw}
          strokeLinecap="round"
          strokeLinejoin="round"
          filter={`url(#ml-shadow-${size})`}
        />

        {/* Layer 4: Edge highlight (top edge of chrome, simulates light) */}
        <path
          d={leftPath}
          stroke="rgba(255,255,255,0.15)"
          strokeWidth={1.2}
          strokeLinecap="round"
          strokeLinejoin="round"
          transform="translate(-0.5, -0.8)"
        />

        {/* Layer 5: Right vertical stroke — NEON CYAN (separate, glowing) */}
        <line
          x1={rightStroke.x}
          y1={rightStroke.y1}
          x2={rightStroke.x}
          y2={rightStroke.y2}
          stroke={`url(#ml-cyan-${size})`}
          strokeWidth={sw}
          strokeLinecap="round"
          filter={glow ? `url(#ml-glow-${size})` : undefined}
        />

        {/* Layer 6: Cyan edge highlight (bright top edge) */}
        <line
          x1={rightStroke.x - 0.5}
          y1={rightStroke.y1}
          x2={rightStroke.x - 0.5}
          y2={rightStroke.y2}
          stroke="rgba(0,255,234,0.3)"
          strokeWidth={1}
          strokeLinecap="round"
        />

        {/* Layer 7: Specular sweep (masked to full M path) */}
        {motion && (
          <path
            d={mPath}
            stroke={`url(#ml-spec-${size})`}
            strokeWidth={sw - 1}
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{ transition: "stroke 0.15s ease-out" }}
          />
        )}
      </svg>
    </div>
  );
}
