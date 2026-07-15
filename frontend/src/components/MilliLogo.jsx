/**
 * MilliLogo — the Milli monogram.
 *
 * Two modes:
 *   • variant="mark" (default) — inline SVG version, sharp at any size, no HTTP.
 *     Use everywhere in the app UI where perf matters (headers, nav, buttons).
 *   • variant="hero" — high-detail PNG extracted from the approved artwork.
 *     Use ONLY for landing hero + splash + marketing surfaces.
 *
 * Prop ``withWordmark`` renders the "MILLI" wordmark below the mark.
 */
export default function MilliLogo({
  size = 64,
  withRoad = true,
  withWordmark = false,
  variant = "mark",
  className = "",
  "data-testid": testId,
}) {
  if (variant === "hero") {
    const src = withWordmark
      ? `${process.env.PUBLIC_URL || ""}/brand/milli-wordmark.png`
      : `${process.env.PUBLIC_URL || ""}/brand/milli-mark.png`;
    return (
      <img
        src={src}
        alt="Milli"
        width={size}
        height={Math.round(size * (withWordmark ? 0.83 : 0.67))}
        style={{ objectFit: "contain" }}
        className={className}
        data-testid={testId}
      />
    );
  }

  const id = `milli-${Math.random().toString(36).slice(2, 8)}`;
  return (
    <div className={`inline-flex flex-col items-center ${className}`} data-testid={testId}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 64 64"
        aria-label="Milli"
        role="img"
      >
        <defs>
          <linearGradient id={`${id}-chrome`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#FFFFFF" />
            <stop offset="35%" stopColor="#C0C0C0" />
            <stop offset="55%" stopColor="#5B6068" />
            <stop offset="75%" stopColor="#B0B4BA" />
            <stop offset="100%" stopColor="#EEF1F5" />
          </linearGradient>
          <linearGradient id={`${id}-cyan`} x1="0" y1="1" x2="0" y2="0">
            <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.15" />
            <stop offset="60%" stopColor="#00E5FF" stopOpacity="0.75" />
            <stop offset="100%" stopColor="#00E5FF" stopOpacity="1" />
          </linearGradient>
          <radialGradient id={`${id}-glow`} cx="50%" cy="100%" r="60%">
            <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.55" />
            <stop offset="100%" stopColor="#00E5FF" stopOpacity="0" />
          </radialGradient>
        </defs>

        {/* Neon glow behind the mark */}
        {withRoad && (
          <ellipse cx="32" cy="60" rx="26" ry="8" fill={`url(#${id}-glow)`} />
        )}

        {/* M — angular chrome */}
        <path
          d="M 6 58 L 6 10 L 16 6 L 27 30 L 32 20 L 37 30 L 48 6 L 58 10 L 58 58 L 48 58 L 48 24 L 38 42 L 32 34 L 26 42 L 16 24 L 16 58 Z"
          fill={`url(#${id}-chrome)`}
          stroke="#0A0D10"
          strokeWidth="0.5"
          strokeLinejoin="round"
        />

        {/* Turquoise runway rising into the M valley */}
        {withRoad && (
          <>
            <path
              d="M 26 60 L 30 40 L 32 28 L 34 40 L 38 60 Z"
              fill={`url(#${id}-cyan)`}
            />
            {/* runway dashes */}
            <rect x="31.5" y="52" width="1" height="4" fill="#FFFFFF" opacity="0.95" />
            <rect x="31.5" y="45" width="1" height="3" fill="#FFFFFF" opacity="0.7" />
            <rect x="31.5" y="39" width="1" height="2" fill="#FFFFFF" opacity="0.45" />
            <circle cx="32" cy="30" r="1" fill="#00E5FF" />
          </>
        )}
      </svg>

      {withWordmark && (
        <div
          className="chrome-text font-display font-black tracking-[0.18em]"
          style={{ fontSize: size * 0.28, marginTop: size * 0.06 }}
        >
          MILLI
        </div>
      )}
    </div>
  );
}
