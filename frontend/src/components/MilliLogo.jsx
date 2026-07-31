/**
 * MilliLogo v3 — Definitive 1.0 build.
 *
 * 3-segment architectural M, matching the segmented blueprint exactly:
 *   Segment 1 (Left):   Thick brushed silver vertical blade
 *   Segment 2 (Middle): V-shaped brushed silver blade (two diagonals meeting at bottom)
 *   Segment 3 (Right):  DETACHED glowing neon cyan vertical bar
 *
 * Rules:
 *   - Three SEPARATE SVG shapes, NOT a connected M path
 *   - Visible gap between middle-V and right cyan bar
 *   - Cyan bar has CSS filter drop-shadow glow; silver segments do NOT
 *   - Zero rectangular background, zero container artifacts
 *   - Pure transparent SVG
 */
export default function MilliLogo({ size = 80 }) {
  // All coordinates in a 100x100 viewBox
  // Blade width (thickness of each segment)
  const bw = 12;

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
          {/* Brushed silver gradient (5-stop metallic) */}
          <linearGradient id="milli-silver" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#6B7280" />
            <stop offset="20%" stopColor="#D1D5DB" />
            <stop offset="45%" stopColor="#9CA3AF" />
            <stop offset="70%" stopColor="#F3F4F6" />
            <stop offset="100%" stopColor="#6B7280" />
          </linearGradient>

          {/* Silver edge highlight */}
          <linearGradient id="milli-silver-edge" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#F9FAFB" />
            <stop offset="50%" stopColor="#E5E7EB" />
            <stop offset="100%" stopColor="#9CA3AF" />
          </linearGradient>

          {/* Cyan gradient for right bar */}
          <linearGradient id="milli-cyan-bar" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#00FFEA" />
            <stop offset="40%" stopColor="#00E5FF" />
            <stop offset="100%" stopColor="#00ACC1" />
          </linearGradient>
        </defs>

        {/* ===== SEGMENT 1: Left vertical blade ===== */}
        {/* A thick vertical rectangle, slightly tapered at top */}
        <path
          d={`
            M 10 12
            L ${10 + bw} 12
            L ${10 + bw} 88
            L 10 88
            Z
          `}
          fill="url(#milli-silver)"
        />
        {/* Left edge highlight */}
        <line
          x1="10" y1="12" x2="10" y2="88"
          stroke="rgba(255,255,255,0.2)"
          strokeWidth="0.8"
        />

        {/* ===== SEGMENT 2: V-shaped middle blade ===== */}
        {/* Two diagonals meeting at bottom center, forming a V/chevron */}
        <path
          d={`
            M ${10 + bw + 2} 12
            L ${10 + bw + 2 + (bw * 0.7)} 12
            L 50 72
            L ${50 - (bw * 0.35)} 72
            Z
          `}
          fill="url(#milli-silver)"
        />
        <path
          d={`
            M ${90 - bw - 6} 12
            L ${90 - 6} 12
            L ${50 + (bw * 0.35)} 72
            L 50 72
            Z
          `}
          fill="url(#milli-silver)"
        />
        {/* V inner edge highlights */}
        <line
          x1={10 + bw + 2} y1="12" x2={50 - (bw * 0.35)} y2="72"
          stroke="rgba(255,255,255,0.12)"
          strokeWidth="0.6"
        />
        <line
          x1={90 - 6} y1="12" x2={50 + (bw * 0.35)} y2="72"
          stroke="rgba(255,255,255,0.12)"
          strokeWidth="0.6"
        />

        {/* ===== SEGMENT 3: Right vertical cyan bar (DETACHED) ===== */}
        {/* Visible gap from the V. This is the glowing element. */}
        <g style={{ filter: "drop-shadow(0 0 10px rgba(0, 229, 255, 0.4)) drop-shadow(0 0 4px rgba(0, 229, 255, 0.6))" }}>
          <rect
            x={90 - bw}
            y="12"
            width={bw}
            height="76"
            rx="1.5"
            ry="1.5"
            fill="url(#milli-cyan-bar)"
          />
          {/* Cyan inner highlight */}
          <line
            x1={90 - bw + 1.5}
            y1="14"
            x2={90 - bw + 1.5}
            y2="86"
            stroke="rgba(255,255,255,0.25)"
            strokeWidth="1"
            strokeLinecap="round"
          />
        </g>
      </svg>
    </div>
  );
}
