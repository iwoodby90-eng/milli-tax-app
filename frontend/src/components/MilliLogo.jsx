/**
 * MilliLogo — official Milli Tax Vault app logo.
 * Renders the chrome-M-with-cyan-stripe icon (PNG, retina) at any pixel size.
 * If the image fails to load, falls back to a plain "M" chip so the UI never breaks.
 */
import { useState } from "react";

const LOGO_SRC = "/brand/milli-logo-256.png";

export default function MilliLogo({ size = 32, className = "", style, ...rest }) {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return (
      <div
        className={`inline-flex items-center justify-center rounded-lg font-black chrome-text ${className}`}
        style={{
          width: size,
          height: size,
          fontSize: size * 0.55,
          background: "linear-gradient(135deg, #0f1216 0%, #05070A 100%)",
          border: "1px solid rgba(0,229,255,0.35)",
          boxShadow: "0 0 12px rgba(0,229,255,0.35)",
          ...style,
        }}
        {...rest}
      >
        M
      </div>
    );
  }
  return (
    <img
      src={LOGO_SRC}
      alt="Milli Tax Vault"
      draggable={false}
      onError={() => setFailed(true)}
      className={`inline-block ${className}`}
      style={{
        width: size,
        height: size,
        objectFit: "contain",
        ...style,
      }}
      {...rest}
    />
  );
}
