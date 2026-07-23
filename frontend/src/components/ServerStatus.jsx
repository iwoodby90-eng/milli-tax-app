import { useState, useEffect } from "react";
import { checkBackendHealth } from "@/lib/api";

/**
 * ServerStatus — overlay that shows when backend is unreachable.
 * Polls every 5s until connection is restored, then auto-dismisses.
 */
export default function ServerStatus() {
  const [offline, setOffline] = useState(false);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    let mounted = true;
    const check = async () => {
      const result = await checkBackendHealth();
      if (!mounted) return;
      setOffline(!result.ok);
      setChecking(false);
    };
    check();
    const interval = setInterval(check, 5000);
    return () => { mounted = false; clearInterval(interval); };
  }, []);

  if (checking || !offline) return null;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 99999,
        background: "#050607",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
        padding: 32,
        textAlign: "center",
      }}
    >
      <div
        style={{
          width: 72, height: 72, borderRadius: "50%",
          border: "2px solid rgba(0, 229, 255, 0.3)",
          display: "flex", alignItems: "center", justifyContent: "center",
          marginBottom: 28,
          animation: "milli-spin 2s linear infinite",
        }}
      >
        <span style={{ fontSize: 32, fontWeight: 700, color: "#00E5FF" }}>M</span>
      </div>
      <h2 style={{ fontSize: 18, fontWeight: 600, color: "#FFFFFF", marginBottom: 8 }}>
        Connecting to Milli...
      </h2>
      <p style={{ fontSize: 14, color: "#8B9DAF", maxWidth: 280, lineHeight: 1.5 }}>
        The server is waking up. This usually takes a few seconds.
        <br />If this persists, check your connection.
      </p>
      <div
        style={{
          marginTop: 32,
          width: 40, height: 4, borderRadius: 2,
          background: "rgba(0, 229, 255, 0.2)",
          overflow: "hidden",
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute", left: "-40px", width: 40, height: 4,
            borderRadius: 2, background: "#00E5FF",
            animation: "slide 1.2s ease-in-out infinite",
          }}
        />
      </div>
      <style>{`
        @keyframes slide {
          0% { transform: translateX(0); }
          50% { transform: translateX(80px); }
          100% { transform: translateX(0); }
        }
      `}</style>
    </div>
  );
}
