/**
 * MilliLogo — chrome "M" monogram with cyan road accent.
 * Renders as inline SVG with a brushed-metal gradient + neon glow.
 */
export default function MilliLogo({ size = 64, withRoad = true, className = "" }) {
  const id = `milli-${Math.random().toString(36).slice(2, 8)}`;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      className={`m-glow ${className}`}
      aria-label="MILLI"
      role="img"
    >
      <defs>
        <linearGradient id={`${id}-chrome`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#F4F8FA" />
          <stop offset="35%" stopColor="#B8C2CC" />
          <stop offset="55%" stopColor="#3A4450" />
          <stop offset="75%" stopColor="#A8B3BA" />
          <stop offset="100%" stopColor="#E8EEF2" />
        </linearGradient>
        <linearGradient id={`${id}-cyan`} x1="0" y1="1" x2="0" y2="0">
          <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.2" />
          <stop offset="100%" stopColor="#00E5FF" stopOpacity="1" />
        </linearGradient>
      </defs>

      {/* M Shape — angular, sharp diagonals */}
      <path
        d="M 8 56 L 8 12 L 16 8 L 26 32 L 32 22 L 38 32 L 48 8 L 56 12 L 56 56 L 48 56 L 48 26 L 38 44 L 32 36 L 26 44 L 16 26 L 16 56 Z"
        fill={`url(#${id}-chrome)`}
        stroke="#0A1218"
        strokeWidth="0.6"
        strokeLinejoin="round"
      />

      {/* Cyan road in the centre valley */}
      {withRoad && (
        <>
          <path
            d="M 28 56 L 30 40 L 32 30 L 34 40 L 36 56 Z"
            fill={`url(#${id}-cyan)`}
            opacity="0.85"
          />
          {/* lane dashes */}
          <rect x="31.5" y="50" width="1" height="3" fill="#fff" opacity="0.9" />
          <rect x="31.5" y="44" width="1" height="2.5" fill="#fff" opacity="0.75" />
          <rect x="31.5" y="39" width="1" height="2" fill="#fff" opacity="0.55" />
          <rect x="31.5" y="35" width="1" height="1.5" fill="#fff" opacity="0.35" />
        </>
      )}
    </svg>
  );
}
