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
            <stop offset="0%" stopColor="#F4F6F8" />
            <stop offset="25%" stopColor="#D8DCE1" />
            <stop offset="50%" stopColor="#7B8085" />
            <stop offset="75%" stopColor="#C7CDD3" />
            <stop offset="100%" stopColor="#5B6068" />
          </linearGradient>
          <linearGradient id={`${id}-cyan`} x1="0" y1="1" x2="0" y2="0">
            <stop offset="0%" stopColor="#00E5FF" stopOpacity="1" />
            <stop offset="50%" stopColor="#00E5FF" stopOpacity="0.75" />
            <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.15" />
          </linearGradient>
          <radialGradient id={`${id}-orb`} cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#FFFFFF" stopOpacity="1" />
            <stop offset="45%" stopColor="#7CF6FF" stopOpacity="0.9" />
            <stop offset="100%" stopColor="#00E5FF" stopOpacity="0" />
          </radialGradient>
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

        {/* Cyan runway rising into the M valley */}
        {withRoad && (
          <>
            <path
              d="M 25 60 L 30 34 L 32 26 L 34 34 L 39 60 Z"
              fill={`url(#${id}-cyan)`}
            />
            {/* Inner bright edge */}
            <path
              d="M 28 60 L 31 36 L 32 30 L 33 36 L 36 60 Z"
              fill="#7CF6FF"
              opacity="0.55"
            />
            {/* Perspective lane dashes */}
            <rect x="31.6" y="52" width="0.8" height="4"   fill="#FFFFFF" opacity="0.95" />
            <rect x="31.6" y="45" width="0.8" height="3"   fill="#FFFFFF" opacity="0.75" />
            <rect x="31.7" y="39" width="0.6" height="2.2" fill="#FFFFFF" opacity="0.55" />
            <rect x="31.8" y="34" width="0.5" height="1.6" fill="#FFFFFF" opacity="0.4"  />
            {/* Glowing orb at the base of the road */}
            <circle cx="32" cy="55" r="5"   fill={`url(#${id}-orb)`} />
            <circle cx="32" cy="55" r="1.5" fill="#FFFFFF" />
            {/* Arrow at the horizon */}
            <path d="M 32 24 L 30 28 L 32 27 L 34 28 Z" fill="#7CF6FF" />
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
