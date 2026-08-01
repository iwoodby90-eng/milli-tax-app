import { useMemo, useState } from "react";
import { Plus, X } from "@phosphor-icons/react";

/**
 * GigConnections — "Automated Payout Slicing" panel.
 *
 * v2.2 SENIOR FINISH — Modal z-index: 9999. Backdrop blur. Viewport centered.
 * Text contrast hardened (no dark-on-dark).
 */

const ALL_PLATFORMS = [
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
  {
    id: "grubhub",
    name: "Grubhub",
    color: "#F63440",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#F63440" />
        <text x="12" y="16" textAnchor="middle" fontSize="9" fontWeight="700" fill="#FFF">GH</text>
      </svg>
    ),
  },
  {
    id: "instacart",
    name: "Instacart",
    color: "#43B02A",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#43B02A" />
        <text x="12" y="16" textAnchor="middle" fontSize="9" fontWeight="700" fill="#FFF">IC</text>
      </svg>
    ),
  },
  {
    id: "amazon_flex",
    name: "Amazon Flex",
    color: "#FF9900",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#FF9900" />
        <text x="12" y="16" textAnchor="middle" fontSize="9" fontWeight="700" fill="#FFF">AF</text>
      </svg>
    ),
  },
  {
    id: "shipt",
    name: "Shipt",
    color: "#00A650",
    icon: (
      <svg viewBox="0 0 24 24" width="28" height="28" fill="none">
        <rect width="24" height="24" rx="6" fill="#00A650" />
        <text x="12" y="16" textAnchor="middle" fontSize="10" fontWeight="700" fill="#FFF">Sh</text>
      </svg>
    ),
  },
];

export default function GigConnections({
  bankConnected = false,
  bankName = "Bank",
  connectedPlatforms = [],
}) {
  const [modalOpen, setModalOpen] = useState(false);

  const statusText = useMemo(() => {
    if (bankConnected) return `Active via ${bankName}`;
    return "Connect bank to activate";
  }, [bankConnected, bankName]);

  const connected = useMemo(
    () => ALL_PLATFORMS.filter((p) => connectedPlatforms.includes(p.id)),
    [connectedPlatforms]
  );

  const unconnected = useMemo(
    () => ALL_PLATFORMS.filter((p) => !connectedPlatforms.includes(p.id)),
    [connectedPlatforms]
  );

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
          <h3 style={{ fontSize: 15, fontWeight: 600, color: "#FFFFFF", margin: 0, letterSpacing: "0.01em" }}>
            Automated Payout Slicing
          </h3>
          <p style={{ fontSize: 12, color: "#8B9DAF", margin: "4px 0 0" }}>
            Deposits detected and auto-taxed
          </p>
        </div>
        <div style={{
          display: "flex", alignItems: "center", gap: 6, padding: "4px 10px", borderRadius: 20,
          background: bankConnected ? "rgba(0,229,255,0.08)" : "rgba(139,157,175,0.08)",
          border: `1px solid ${bankConnected ? "rgba(0,229,255,0.2)" : "rgba(139,157,175,0.15)"}`,
        }}>
          <div style={{
            width: 6, height: 6, borderRadius: "50%",
            background: bankConnected ? "#00E5FF" : "#8B9DAF",
            boxShadow: bankConnected ? "0 0 6px rgba(0,229,255,0.5)" : "none",
          }} />
          <span style={{ fontSize: 11, color: bankConnected ? "#00E5FF" : "#8B9DAF", fontWeight: 500 }}>
            {bankConnected ? "LIVE" : "INACTIVE"}
          </span>
        </div>
      </div>

      {/* Connected platform grid */}
      {connected.length > 0 ? (
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          {connected.map((p) => (
            <div key={p.id} data-testid={`gig-platform-${p.id}`} style={{
              display: "flex", alignItems: "center", gap: 10, padding: "12px 14px", borderRadius: 14,
              background: "rgba(5, 6, 7, 0.6)",
              border: `1px solid ${bankConnected ? "rgba(0,229,255,0.1)" : "rgba(255,255,255,0.04)"}`,
            }}>
              <div style={{ width: 28, height: 28, borderRadius: 6, overflow: "hidden", flexShrink: 0, opacity: bankConnected ? 1 : 0.4 }}>
                {p.icon}
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: bankConnected ? "#FFFFFF" : "#8B9DAF" }}>{p.name}</div>
                <div style={{ fontSize: 10, color: bankConnected ? "rgba(0,229,255,0.7)" : "#8B9DAF", marginTop: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{statusText}</div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div style={{ textAlign: "center", padding: "20px 16px", color: "#8B9DAF", fontSize: 13 }}>
          No platforms connected yet. Link a bank account and connect your gig platforms below.
        </div>
      )}

      {/* Connect New Platform button */}
      <button
        data-testid="connect-new-platform-btn"
        onClick={() => setModalOpen(true)}
        style={{
          all: "unset", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          gap: 8, width: "100%", marginTop: 14, padding: "12px 0", borderRadius: 12,
          background: "rgba(0, 229, 255, 0.06)", border: "1px solid rgba(0, 229, 255, 0.2)",
          color: "#00E5FF", fontSize: 13, fontWeight: 600, letterSpacing: "0.02em",
        }}
      >
        <Plus size={14} weight="bold" />
        Connect New Platform
      </button>

      {/* Bottom note */}
      {bankConnected && connected.length > 0 && (
        <p style={{ fontSize: 11, color: "#8B9DAF", margin: "14px 0 0", textAlign: "center", lineHeight: 1.4 }}>
          Milli automatically identifies gig payouts and applies your tax slicing rules.
        </p>
      )}

      {/* === MODAL: z-index 9999, viewport-centered, backdrop blur === */}
      {modalOpen && (
        <div
          data-testid="connect-platform-modal"
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 9999,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            backgroundColor: "rgba(0,0,0,0.82)",
            backdropFilter: "blur(12px)",
            WebkitBackdropFilter: "blur(12px)",
          }}
          onClick={() => setModalOpen(false)}
        >
          <div
            style={{
              position: "relative",
              zIndex: 10000,
              background: "#0D0F12",
              borderRadius: 22,
              border: "1px solid rgba(0,229,255,0.15)",
              padding: "28px 24px",
              width: "90%",
              maxWidth: 380,
              maxHeight: "70vh",
              overflowY: "auto",
              boxShadow: "0 24px 64px rgba(0,0,0,0.6), 0 0 32px rgba(0,229,255,0.08)",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
              <h3 style={{ fontSize: 16, fontWeight: 700, color: "#FFFFFF", margin: 0 }}>Connect a Platform</h3>
              <button onClick={() => setModalOpen(false)} style={{ all: "unset", cursor: "pointer", padding: 4, color: "#8B9DAF" }} aria-label="Close">
                <X size={18} weight="bold" />
              </button>
            </div>

            {unconnected.length > 0 ? (
              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                {unconnected.map((p) => (
                  <button key={p.id} data-testid={`connect-platform-${p.id}`} style={{
                    all: "unset", cursor: "pointer", display: "flex", alignItems: "center", gap: 12,
                    padding: "14px 16px", borderRadius: 14, background: "rgba(5, 6, 7, 0.8)",
                    border: "1px solid rgba(255,255,255,0.06)",
                  }}>
                    <div style={{ width: 28, height: 28, borderRadius: 6, overflow: "hidden", flexShrink: 0 }}>{p.icon}</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 14, fontWeight: 600, color: "#FFFFFF" }}>{p.name}</div>
                      <div style={{ fontSize: 11, color: "#8B9DAF", marginTop: 2 }}>Tap to connect</div>
                    </div>
                    <Plus size={14} weight="bold" style={{ color: "#00E5FF" }} />
                  </button>
                ))}
              </div>
            ) : (
              <div style={{ textAlign: "center", padding: 20, color: "#8B9DAF", fontSize: 13 }}>
                All available platforms are connected.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
