import { useMemo } from "react";

/**
 * GigConnections — "Automated Payout Slicing" panel.
 *
 * Shows connected gig platforms detected via Plaid bank transactions.
 * If a bank is linked, platforms are shown as "Active via [Bank Name]".
 * Industrial-Noir aesthetic: glassmorphic card, neon cyan accents.
 *
 * Props:
 *   bankConnected - boolean (is Plaid linked?)
 *   bankName      - string (e.g., "Chase", "Capital One")
 *   platforms     - array of detected platform names (optional override)
 */

const PLATFORMS = [
  {
    id: "uber",
    name: "Uber",
    color: "#000000",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#000" />
        <text x="12" y="16" textAnchor="middle" fontSize="10" fontWeight="700" fill="#FFF">U</text>
      </svg>
    ),
  },
  {
    id: "lyft",
    name: "Lyft",
    color: "#FF00BF",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#FF00BF" />
        <text x="12" y="16" textAnchor="middle" fontSize="10" fontWeight="700" fill="#FFF">L</text>
      </svg>
    ),
  },
  {
    id: "doordash",
    name: "DoorDash",
    color: "#FF3008",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#FF3008" />
        <text x="12" y="16" textAnchor="middle" fontSize="9" fontWeight="700" fill="#FFF">DD</text>
      </svg>
    ),
  },
  {
    id: "spark",
    name: "Spark",
    color: "#0071CE",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#0071CE" />
        <text x="12" y="16" textAnchor="middle" fontSize="10" fontWeight="700" fill="#FFF">S</text>
      </svg>
    ),
  },
];

export default function GigConnections({ bankConnected = false, bankName = "Bank" }) {
  const statusText = useMemo(() => {
    if (bankConnected) return `Active via ${bankName}`;
    return "Connect bank to activate";
  }, [bankConnected, bankName]);

  return (
    <div
      style={{
        background: "rgba(13, 15, 18, 0.7)",
        backdropFilter: "blur(20px)",
        WebkitBackdropFilter: "blur(20px)",
        border: "1px solid rgba(192, 192, 192, 0.08)",
        borderRadius: 20,
        padding: "24px 20px",
        marginBottom: 16,
      }}
    >
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
        <div>
          <h3 style={{
            fontSize: 15,
            fontWeight: 600,
            color: "#FFFFFF",
            margin: 0,
            letterSpacing: "0.01em",
          }}>
            Automated Payout Slicing
          </h3>
          <p style={{
            fontSize: 12,
            color: "#8B9DAF",
            margin: "4px 0 0",
          }}>
            Deposits detected and auto-taxed
          </p>
        </div>
        {/* Status indicator */}
        <div style={{
          display: "flex",
          alignItems: "center",
          gap: 6,
          padding: "4px 10px",
          borderRadius: 20,
          background: bankConnected ? "rgba(0,229,255,0.08)" : "rgba(139,157,175,0.08)",
          border: `1px solid ${bankConnected ? "rgba(0,229,255,0.2)" : "rgba(139,157,175,0.15)"}`,
        }}>
          <div style={{
            width: 6, height: 6, borderRadius: "50%",
            background: bankConnected ? "#00E5FF" : "#8B9DAF",
            boxShadow: bankConnected ? "0 0 6px rgba(0,229,255,0.5)" : "none",
          }} />
          <span style={{
            fontSize: 11,
            color: bankConnected ? "#00E5FF" : "#8B9DAF",
            fontWeight: 500,
          }}>
            {bankConnected ? "LIVE" : "INACTIVE"}
          </span>
        </div>
      </div>

      {/* Platform grid */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: 10,
      }}>
        {PLATFORMS.map((p) => (
          <div
            key={p.id}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "12px 14px",
              borderRadius: 14,
              background: "rgba(5, 6, 7, 0.6)",
              border: `1px solid ${bankConnected ? "rgba(0,229,255,0.1)" : "rgba(255,255,255,0.04)"}`,
              transition: "border-color 0.2s",
            }}
          >
            {/* Platform icon */}
            <div style={{
              width: 28, height: 28, borderRadius: 6, overflow: "hidden",
              flexShrink: 0,
              opacity: bankConnected ? 1 : 0.4,
              transition: "opacity 0.2s",
            }}>
              {p.icon}
            </div>
            {/* Platform info */}
            <div style={{ minWidth: 0 }}>
              <div style={{
                fontSize: 13,
                fontWeight: 600,
                color: bankConnected ? "#FFFFFF" : "#8B9DAF",
              }}>
                {p.name}
              </div>
              <div style={{
                fontSize: 10,
                color: bankConnected ? "rgba(0,229,255,0.7)" : "#5A6573",
                marginTop: 1,
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              }}>
                {statusText}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Bottom note */}
      {bankConnected && (
        <p style={{
          fontSize: 11,
          color: "#5A6573",
          margin: "14px 0 0",
          textAlign: "center",
          lineHeight: 1.4,
        }}>
          Milli automatically identifies gig payouts and applies your tax slicing rules.
        </p>
      )}
    </div>
  );
}
