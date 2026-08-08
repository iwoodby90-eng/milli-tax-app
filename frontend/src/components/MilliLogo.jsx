/**
 * MilliLogo — animated, transparent-background Milli mark.
 * Breathes with a teal glow pulse at sizes >= 40px.
 */
import { useState } from "react";

const LOGO_SRC = "/brand/milli-logo-transparent.png";

export default function MilliLogo({ size = 32, animate = true, className = "", style, ...rest }) {
  const [failed, setFailed] = useState(false);
  const shouldAnimate = animate && size >= 40;

  if (failed) {
    return (
      <span
        className={`inline-flex items-center justify-center font-black ${className}`}
        style={{
          width: size, height: size,
          fontSize: size * 0.6,
          color: "#00E5FF",
          textShadow: "0 0 14px rgba(0,229,255,0.75)",
          background: "transparent",
          ...style,
        }}
      >M</span>
    );
  }

  return (
    <span
      className={`relative inline-flex items-center justify-center flex-shrink-0 ${className}`}
      style={{ width: size, height: size, ...style }}
    >
      <img
        src={LOGO_SRC}
        alt="Milli"
        draggable={false}
        onError={() => setFailed(true)}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "contain",
          display: "block",
          animation: shouldAnimate ? "milli-breathe 3.5s ease-in-out infinite" : undefined,
        }}
        {...rest}
      />
      {shouldAnimate && (
        <span
          aria-hidden
          style={{
            position: "absolute",
            inset: 0,
            background: "linear-gradient(110deg, transparent 25%, rgba(255,255,255,0.28) 50%, transparent 75%)",
            animation: "milli-shimmer 6s ease-in-out infinite",
            pointerEvents: "none",
            borderRadius: "50%",
          }}
        />
      )}
    </span>
  );
}
