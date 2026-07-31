import { useRef, useEffect, useState } from "react";

/**
 * MilliLogo — Senior Staff hardware-grade component.
 *
 * Renders the Milli "M" as a seamless, transparent-background mark with:
 * - Multi-stage chrome gradient (5 stops, metallic sheen)
 * - Cyan right-stroke accent with inner glow
 * - 3D specular highlight layer with subtle parallax on device motion
 * - CSS mask-image compositing (no rectangular container, no block artifacts)
 * - Blends perfectly into any dark background
 *
 * Props:
 *   size   - height in px (default 80)
 *   glow   - enable ambient cyan glow (default true)
 *   motion - enable parallax specular highlight (default true)
 */
export default function MilliLogo({ size = 80, glow = true, motion = true }) {
  const containerRef = useRef(null);
  const [tilt, setTilt] = useState({ x: 0, y: 0 });

  // Parallax: device orientation or mouse move
  useEffect(() => {
    if (!motion) return;
    let raf;

    const handleOrientation = (e) => {
      const x = Math.max(-15, Math.min(15, (e.gamma || 0) * 0.5));
      const y = Math.max(-15, Math.min(15, (e.beta || 0) * 0.3 - 10));
      raf = requestAnimationFrame(() => setTilt({ x, y }));
    };

    const handleMouse = (e) => {
      const rect = containerRef.current?.getBoundingClientRect();
      if (!rect) return;
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      const x = ((e.clientX - cx) / rect.width) * 12;
      const y = ((e.clientY - cy) / rect.height) * 12;
      raf = requestAnimationFrame(() => setTilt({ x, y }));
    };

    if (window.DeviceOrientationEvent && "ontouchstart" in window) {
      window.addEventListener("deviceorientation", handleOrientation, { passive: true });
    } else {
      window.addEventListener("mousemove", handleMouse, { passive: true });
    }

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("deviceorientation", handleOrientation);
      window.removeEventListener("mousemove", handleMouse);
    };
  }, [motion]);

  const w = size;
  const h = size;
  const strokeW = Math.max(2, size * 0.09);

  // M path (angular, architectural)
  const buildMPath = () => {
    const pad = strokeW;
    const left = pad;
    const right = w - pad;
    const top = pad + h * 0.1;
    const bottom = h - pad - h * 0.1;
    const midX = w / 2;
    const peakY = top + (bottom - top) * 0.35;
    return `M ${left} ${bottom} L ${left} ${top} L ${midX} ${peakY} L ${right} ${top} L ${right} ${bottom}`;
  };

  const mPath = buildMPath();

  return (
    <div
      ref={containerRef}
      style={{
        position: "relative",
        width: w,
        height: h,
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        /* NO background, NO border, NO rectangular container */
        background: "transparent",
        border: "none",
        borderRadius: 0,
        overflow: "visible",
      }}
    >
      {/* Ambient glow (behind everything) */}
      {glow && (
        <div
          style={{
            position: "absolute",
            inset: "-20%",
            background: "radial-gradient(ellipse at center, rgba(0,229,255,0.12) 0%, transparent 70%)",
            filter: "blur(8px)",
            pointerEvents: "none",
          }}
        />
      )}

      {/* Main M SVG */}
      <svg
        viewBox={`0 0 ${w} ${h}`}
        width={w}
        height={h}
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ position: "relative", zIndex: 2 }}
      >
        <defs>
          {/* Chrome gradient — 5-stop metallic */}
          <linearGradient id="milli-chrome" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#9CA3AF" />
            <stop offset="25%" stopColor="#E5E7EB" />
            <stop offset="50%" stopColor="#D1D5DB" />
            <stop offset="75%" stopColor="#F9FAFB" />
            <stop offset="100%" stopColor="#9CA3AF" />
          </linearGradient>

          {/* Cyan accent gradient */}
          <linearGradient id="milli-cyan-grad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#00FFEA" />
            <stop offset="50%" stopColor="#00E5FF" />
            <stop offset="100%" stopColor="#00BCD4" />
          </linearGradient>

          {/* Specular highlight gradient */}
          <linearGradient id="milli-specular" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="rgba(255,255,255,0)" />
            <stop offset="40%" stopColor="rgba(255,255,255,0.35)" />
            <stop offset="60%" stopColor="rgba(255,255,255,0.1)" />
            <stop offset="100%" stopColor="rgba(255,255,255,0)" />
          </linearGradient>

          {/* Glow filter for cyan stroke */}
          <filter id="milli-glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceGraphic" stdDeviation="2" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Shadow layer */}
        <path
          d={mPath}
          stroke="rgba(0,0,0,0.4)"
          strokeWidth={strokeW + 2}
          strokeLinecap="round"
          strokeLinejoin="round"
          transform="translate(1.5, 2)"
        />

        {/* Main chrome M (left 3 strokes) */}
        <path
          d={mPath}
          stroke="url(#milli-chrome)"
          strokeWidth={strokeW}
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Cyan right-stroke overlay (only the rightmost vertical) */}
        <line
          x1={w - strokeW}
          y1={strokeW + h * 0.1}
          x2={w - strokeW}
          y2={h - strokeW - h * 0.1}
          stroke="url(#milli-cyan-grad)"
          strokeWidth={strokeW}
          strokeLinecap="round"
          filter="url(#milli-glow)"
        />
      </svg>

      {/* Specular highlight layer with parallax */}
      {motion && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            zIndex: 3,
            pointerEvents: "none",
            background: `linear-gradient(${135 + tilt.x}deg, transparent 30%, rgba(255,255,255,0.15) 50%, transparent 70%)`,
            transform: `translate(${tilt.x * 0.3}px, ${tilt.y * 0.3}px)`,
            transition: "transform 0.1s ease-out, background 0.1s ease-out",
            maskImage: `url("data:image/svg+xml,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ${w} ${h}'><path d='${mPath}' stroke='white' stroke-width='${strokeW}' fill='none' stroke-linecap='round' stroke-linejoin='round'/></svg>`)}")`,
            WebkitMaskImage: `url("data:image/svg+xml,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ${w} ${h}'><path d='${mPath}' stroke='white' stroke-width='${strokeW}' fill='none' stroke-linecap='round' stroke-linejoin='round'/></svg>`)}")`,
            maskSize: "contain",
            WebkitMaskSize: "contain",
            maskRepeat: "no-repeat",
            WebkitMaskRepeat: "no-repeat",
            maskPosition: "center",
            WebkitMaskPosition: "center",
          }}
        />
      )}
    </div>
  );
}
