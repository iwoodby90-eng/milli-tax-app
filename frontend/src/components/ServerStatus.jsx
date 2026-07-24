import { useState, useEffect, useRef } from "react";

/**
 * ConnectionIndicator — a thin, non-blocking top banner.
 *
 * Replaces the old full-screen ServerStatus overlay.
 * Does NOT run a health check on mount.
 * Shows only when the API interceptor dispatches "milli:network-error",
 * auto-hides when "milli:network-ok" is received or after a short timer.
 */
export default function ServerStatus() {
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState("Unable to reach Milli servers.");
  const hideTimer = useRef(null);

  useEffect(() => {
    const onError = (e) => {
      if (hideTimer.current) clearTimeout(hideTimer.current);
      setMessage(e.detail?.message ?? "Unable to reach Milli servers.");
      setVisible(true);
    };

    const onOk = () => {
      if (hideTimer.current) clearTimeout(hideTimer.current);
      // Brief delay so the user sees the recovery before the bar disappears
      hideTimer.current = setTimeout(() => setVisible(false), 1800);
      setMessage("Connection restored.");
    };

    window.addEventListener("milli:network-error", onError);
    window.addEventListener("milli:network-ok", onOk);
    return () => {
      window.removeEventListener("milli:network-error", onError);
      window.removeEventListener("milli:network-ok", onOk);
      if (hideTimer.current) clearTimeout(hideTimer.current);
    };
  }, []);

  if (!visible) return null;

  const isRecovered = message === "Connection restored.";

  return (
    <div
      role="status"
      aria-live="polite"
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        zIndex: 99999,
        background: isRecovered
          ? "rgba(0, 229, 100, 0.10)"
          : "rgba(0, 229, 255, 0.08)",
        backdropFilter: "blur(12px)",
        WebkitBackdropFilter: "blur(12px)",
        borderBottom: isRecovered
          ? "1px solid rgba(0, 229, 100, 0.30)"
          : "1px solid rgba(0, 229, 255, 0.25)",
        padding: "6px 16px",
        paddingTop: "calc(6px + var(--safe-top, 0px))",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
      }}
    >
      <div
        style={{
          width: 6,
          height: 6,
          borderRadius: "50%",
          background: isRecovered ? "#00E564" : "#00E5FF",
          animation: isRecovered ? "none" : "milli-ci-pulse 1.2s ease-in-out infinite",
          flexShrink: 0,
        }}
      />
      <span
        style={{
          fontSize: 11,
          color: isRecovered ? "#00E564" : "#00E5FF",
          fontWeight: 500,
          letterSpacing: "0.05em",
        }}
      >
        {message}
      </span>
      <style>{`
        @keyframes milli-ci-pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.25; }
        }
      `}</style>
    </div>
  );
}
