import { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { Robot } from "@phosphor-icons/react";

/**
 * MilliFAB — floating Milli AI companion button.
 * 58px dark housing, teal robot icon, teal glow rim + bloom beneath.
 * Pressing reveals a "Milli AI" tooltip chip sliding from the left.
 */
export default function MilliFAB() {
  const nav = useNavigate();
  const loc = useLocation();
  const [showLabel, setShowLabel] = useState(false);

  if (loc.pathname.startsWith("/app/ai")) return null;

  function handleTap() {
    if (showLabel) {
      nav("/app/ai");
    } else {
      setShowLabel(true);
      setTimeout(() => setShowLabel(false), 2400);
    }
  }

  return (
    <div
      className="fixed z-50"
      style={{
        right: 18,
        bottom: "calc(var(--safe-bottom, 34px) + 88px)",
      }}
    >
      {/* Tooltip chip — slides out to left */}
      <div
        className="absolute right-[66px] top-1/2 -translate-y-1/2 whitespace-nowrap pointer-events-none"
        style={{
          opacity: showLabel ? 1 : 0,
          transform: showLabel ? "translateX(0)" : "translateX(12px)",
          transition: "opacity 0.25s ease, transform 0.25s ease",
        }}
      >
        <span
          className="px-3 py-1.5 rounded-full text-white text-[12px] font-semibold"
          style={{
            background: "linear-gradient(135deg, rgba(255,255,255,0.08), rgba(255,255,255,0.03))",
            border: "1px solid rgba(255,255,255,0.12)",
            backdropFilter: "blur(16px)",
            boxShadow: "0 4px 16px rgba(0,0,0,0.4)",
          }}
        >
          Milli AI
        </span>
      </div>

      {/* Bloom beneath */}
      <div
        aria-hidden
        className="absolute inset-0 rounded-full"
        style={{
          background: "radial-gradient(circle, rgba(0,229,255,0.35) 0%, transparent 70%)",
          filter: "blur(12px)",
          transform: "translateY(4px) scale(1.3)",
        }}
      />

      {/* Main button */}
      <button
        onClick={handleTap}
        data-testid="milli-fab"
        aria-label="Chat with Milli AI"
        className="relative w-[58px] h-[58px] rounded-full flex items-center justify-center active:scale-95 transition-transform"
        style={{
          background: "linear-gradient(145deg, #12161B, #080A0D)",
          border: "1.5px solid rgba(0,229,255,0.5)",
          boxShadow: "0 0 24px rgba(0,229,255,0.35), inset 0 1px 0 rgba(255,255,255,0.06), 0 8px 24px rgba(0,0,0,0.5)",
          animation: "milli-fab-glow 3s ease-in-out infinite",
        }}
      >
        <Robot size={26} weight="duotone" color="#00E5FF" style={{ filter: "drop-shadow(0 0 8px rgba(0,229,255,0.6))" }} />
      </button>
    </div>
  );
}
