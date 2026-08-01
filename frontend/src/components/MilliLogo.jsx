/**
 * MilliLogo v4.0 — ARCHITECTURAL LOCK (v2.3)
 *
 * Definitive high-fidelity rebuild: sharper blade-like segments with
 * multi-layered metallic gradients simulating "Senior Staff" 3D lighting.
 *
 * Geometric guide: the 4K architectural wordmark asset.
 *   Segment 1 (Left):   Brushed silver vertical blade — razor-thin, precise.
 *   Segment 2 (Middle): V-shaped brushed silver blade (two symmetrical diagonals).
 *   Segment 3 (Right):  DETACHED glowing neon cyan bar.
 *
 * Props:
 *   size        px (default 80)
 *   glowOutline boolean — when true, adds subtle neon cyan outline to all segments
 */
export default function MilliLogo({ size = 80, glowOutline = false }) {
  const uid = `milli-arch-${Math.random().toString(36).slice(2, 8)}`;

  return (
    <div
      style={{
        width: size,
        height: size,
        display: "inline-block",
        background: "transparent",
        border: "none",
        boxShadow: "none",
        outline: "none",
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
          {/* PRIMARY: Multi-layered brushed silver — simulates Senior Staff 3D studio lighting */}
          <linearGradient id={`${uid}-silver-main`} x1="0%" y1="0%" x2="30%" y2="100%">
            <stop offset="0%" stopColor="#E8EAED" />
            <stop offset="12%" stopColor="#F8F9FA" />
            <stop offset="28%" stopColor="#B0B5BC" />
            <stop offset="42%" stopColor="#D4D8DD" />
            <stop offset="55%" stopColor="#6B7280" />
            <stop offset="68%" stopColor="#9CA3AF" />
            <stop offset="82%" stopColor="#E5E7EB" />
            <stop offset="92%" stopColor="#6B7280" />
            <stop offset="100%" stopColor="#4B5563" />
          </linearGradient>

          {/* SECONDARY: Edge-lit specular highlight — left face */}
          <linearGradient id={`${uid}-silver-spec`} x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.9" />
            <stop offset="30%" stopColor="#F3F4F6" stopOpacity="0.6" />
            <stop offset="60%" stopColor="#9CA3AF" stopOpacity="0.3" />
            <stop offset="100%" stopColor="#4B5563" stopOpacity="0.1" />
          </linearGradient>

          {/* TERTIARY: Vertical ambient occlusion */}
          <linearGradient id={`${uid}-silver-ao`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#F9FAFB" stopOpacity="0.7" />
            <stop offset="15%" stopColor="#E5E7EB" stopOpacity="0.4" />
            <stop offset="50%" stopColor="#6B7280" stopOpacity="0.2" />
            <stop offset="85%" stopColor="#374151" stopOpacity="0.5" />
            <stop offset="100%" stopColor="#1F2937" stopOpacity="0.8" />
          </linearGradient>

          {/* Neon cyan gradient for right bar */}
          <linearGradient id={`${uid}-cyan`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#00FFEA" />
            <stop offset="25%" stopColor="#00F5FF" />
            <stop offset="50%" stopColor="#00E5FF" />
            <stop offset="75%" stopColor="#00D4E8" />
            <stop offset="100%" stopColor="#00ACC1" />
          </linearGradient>

          {/* Cyan inner glow */}
          <linearGradient id={`${uid}-cyan-inner`} x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.5" />
            <stop offset="50%" stopColor="#00FFEA" stopOpacity="0.3" />
            <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0" />
          </linearGradient>

          {/* Glow filter for cyan bar */}
          <filter id={`${uid}-cyan-glow`} x="-50%" y="-20%" width="200%" height="140%">
            <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur1" />
            <feGaussianBlur in="SourceGraphic" stdDeviation="5" result="blur2" />
            <feMerge>
              <feMergeNode in="blur2" />
              <feMergeNode in="blur1" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Subtle metallic noise texture */}
          <filter id={`${uid}-brushed`} x="0%" y="0%" width="100%" height="100%">
            <feTurbulence type="fractalNoise" baseFrequency="0.9 0.02" numOctaves="3" result="noise" />
            <feColorMatrix type="saturate" values="0" in="noise" result="gray" />
            <feBlend in="SourceGraphic" in2="gray" mode="overlay" result="brushed" />
            <feComposite in="brushed" in2="SourceGraphic" operator="in" />
          </filter>
        </defs>

        {/* ===== SEGMENT 1: Left vertical blade — razor-sharp ===== */}
        <g>
          {/* Base metallic fill */}
          <path
            d="M 12 10 L 22 10 L 22 90 L 12 90 Z"
            fill={`url(#${uid}-silver-main)`}
            filter={`url(#${uid}-brushed)`}
          />
          {/* Specular left edge */}
          <path
            d="M 12 10 L 14.5 10 L 14.5 90 L 12 90 Z"
            fill={`url(#${uid}-silver-spec)`}
          />
          {/* Ambient occlusion overlay */}
          <path
            d="M 12 10 L 22 10 L 22 90 L 12 90 Z"
            fill={`url(#${uid}-silver-ao)`}
            opacity="0.3"
          />
          {/* Top edge highlight (blade tip) */}
          <line x1="12" y1="10" x2="22" y2="10" stroke="rgba(255,255,255,0.6)" strokeWidth="0.5" />
          {/* Left edge razor line */}
          <line x1="12" y1="10" x2="12" y2="90" stroke="rgba(255,255,255,0.35)" strokeWidth="0.4" />
          {/* Glow outline when active */}
          {glowOutline && (
            <path
              d="M 12 10 L 22 10 L 22 90 L 12 90 Z"
              fill="none"
              stroke="rgba(0, 229, 255, 0.6)"
              strokeWidth="1.2"
            />
          )}
        </g>

        {/* ===== SEGMENT 2: V-shaped middle blade — dual diagonal blades ===== */}
        {/* Left diagonal of V */}
        <g>
          <path
            d="M 25 10 L 33 10 L 51 78 L 46 78 Z"
            fill={`url(#${uid}-silver-main)`}
            filter={`url(#${uid}-brushed)`}
          />
          <path
            d="M 25 10 L 27.5 10 L 48 78 L 46 78 Z"
            fill={`url(#${uid}-silver-spec)`}
            opacity="0.7"
          />
          <path
            d="M 25 10 L 33 10 L 51 78 L 46 78 Z"
            fill={`url(#${uid}-silver-ao)`}
            opacity="0.25"
          />
          {/* Top blade edge */}
          <line x1="25" y1="10" x2="33" y2="10" stroke="rgba(255,255,255,0.5)" strokeWidth="0.4" />
          {/* Outer edge highlight */}
          <line x1="25" y1="10" x2="46" y2="78" stroke="rgba(255,255,255,0.2)" strokeWidth="0.3" />
          {glowOutline && (
            <path d="M 25 10 L 33 10 L 51 78 L 46 78 Z" fill="none" stroke="rgba(0, 229, 255, 0.6)" strokeWidth="1.2" />
          )}
        </g>

        {/* Right diagonal of V */}
        <g>
          <path
            d="M 67 10 L 75 10 L 54 78 L 49 78 Z"
            fill={`url(#${uid}-silver-main)`}
            filter={`url(#${uid}-brushed)`}
          />
          <path
            d="M 73 10 L 75 10 L 54 78 L 52 78 Z"
            fill={`url(#${uid}-silver-spec)`}
            opacity="0.7"
          />
          <path
            d="M 67 10 L 75 10 L 54 78 L 49 78 Z"
            fill={`url(#${uid}-silver-ao)`}
            opacity="0.25"
          />
          {/* Top blade edge */}
          <line x1="67" y1="10" x2="75" y2="10" stroke="rgba(255,255,255,0.5)" strokeWidth="0.4" />
          {/* Outer edge highlight */}
          <line x1="75" y1="10" x2="54" y2="78" stroke="rgba(255,255,255,0.2)" strokeWidth="0.3" />
          {glowOutline && (
            <path d="M 67 10 L 75 10 L 54 78 L 49 78 Z" fill="none" stroke="rgba(0, 229, 255, 0.6)" strokeWidth="1.2" />
          )}
        </g>

        {/* ===== SEGMENT 3: Right vertical cyan bar (DETACHED, glowing) ===== */}
        <g filter={`url(#${uid}-cyan-glow)`}>
          <rect
            x="80"
            y="10"
            width="10"
            height="80"
            rx="1.5"
            ry="1.5"
            fill={`url(#${uid}-cyan)`}
          />
          {/* Inner specular highlight */}
          <rect
            x="80.8"
            y="12"
            width="2.5"
            height="76"
            rx="1"
            fill={`url(#${uid}-cyan-inner)`}
          />
          {/* Top cap highlight */}
          <line x1="80" y1="10" x2="90" y2="10" stroke="rgba(255,255,255,0.5)" strokeWidth="0.5" />
          {glowOutline && (
            <rect
              x="80" y="10" width="10" height="80" rx="1.5" ry="1.5"
              fill="none" stroke="rgba(0, 229, 255, 0.85)" strokeWidth="1.5"
            />
          )}
        </g>
      </svg>
    </div>
  );
}
