import MilliLogo from "./MilliLogo";

/**
 * NavDialButton — Physical 3D hardware center button for the nav bar.
 *
 * Three layers simulate a milled metal volume knob recessed into titanium:
 *   Layer 1 (Base): Concave chrome dial with radial gradient (milled metal)
 *   Layer 2 (Logo): 3-blade architectural M monogram — centered with neon cyan glow
 *   Layer 3 (Specular): 45° white-to-transparent gloss layer (top reflection)
 *
 * v2.1 — Re-injects the 3-blade architectural monogram with subtle neon cyan outline.
 */
export default function NavDialButton({ size = 56, onClick }) {
  const outerRing = size + 4; // outer bezel
  const logoSize = size * 0.48;

  return (
    <button
      onClick={onClick}
      data-testid="nav-dial-button"
      aria-label="Home"
      style={{
        all: "unset",
        cursor: "pointer",
        WebkitTapHighlightColor: "transparent",
        position: "relative",
        width: outerRing,
        height: outerRing,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        marginTop: -14,
        zIndex: 10,
      }}
    >
      {/* === OUTER BEZEL: Brushed titanium ring === */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "50%",
          background: `conic-gradient(
            from 0deg,
            #3A3F47 0deg,
            #5A5F67 45deg,
            #2A2F37 90deg,
            #6A6F77 135deg,
            #3A3F47 180deg,
            #5A5F67 225deg,
            #2A2F37 270deg,
            #4A4F57 315deg,
            #3A3F47 360deg
          )`,
          boxShadow: `
            0 2px 8px rgba(0, 0, 0, 0.6),
            inset 0 1px 0 rgba(255, 255, 255, 0.08),
            inset 0 -1px 0 rgba(0, 0, 0, 0.3)
          `,
          border: "none",
        }}
      />

      {/* === LAYER 1: Concave chrome dial (milled metal) === */}
      <div
        style={{
          position: "absolute",
          inset: 3,
          borderRadius: "50%",
          background: `radial-gradient(
            ellipse at 40% 35%,
            #4A4F57 0%,
            #2A2E34 30%,
            #1A1E22 60%,
            #0D0F12 100%
          )`,
          boxShadow: `
            inset 0 3px 6px rgba(0, 0, 0, 0.5),
            inset 0 -1px 3px rgba(255, 255, 255, 0.04),
            0 1px 3px rgba(0, 0, 0, 0.4)
          `,
        }}
      />

      {/* === LAYER 2: 3-Blade Architectural M Monogram with Neon Cyan Glow === */}
      <div
        style={{
          position: "relative",
          zIndex: 2,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          filter: "drop-shadow(0 0 4px rgba(0, 229, 255, 0.6)) drop-shadow(0 0 8px rgba(0, 229, 255, 0.3))",
        }}
      >
        <MilliLogo size={logoSize} glowOutline />
      </div>

      {/* === LAYER 3: Specular gloss (45° highlight) === */}
      <div
        style={{
          position: "absolute",
          inset: 3,
          borderRadius: "50%",
          background: `linear-gradient(
            135deg,
            rgba(255, 255, 255, 0.12) 0%,
            rgba(255, 255, 255, 0.04) 30%,
            transparent 55%,
            transparent 100%
          )`,
          pointerEvents: "none",
          zIndex: 3,
        }}
      />

      {/* === Subtle cyan ring glow (indicates active/home) === */}
      <div
        style={{
          position: "absolute",
          inset: -2,
          borderRadius: "50%",
          border: "1px solid rgba(0, 229, 255, 0.25)",
          boxShadow: "0 0 10px rgba(0, 229, 255, 0.15), 0 0 20px rgba(0, 229, 255, 0.05)",
          pointerEvents: "none",
        }}
      />
    </button>
  );
}
