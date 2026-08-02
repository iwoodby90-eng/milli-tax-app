import { NavLink } from "react-router-dom";
import { GearSix, Gift } from "@phosphor-icons/react";

const CYAN = "#00E5FF";

function HubTile({ to, icon: Icon, title, subtitle, accentColor = CYAN }) {
  return (
    <NavLink
      to={to}
      className="block active:scale-[0.97] transition-transform duration-150"
    >
      <div
        style={{
          background: "linear-gradient(135deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0.02) 100%)",
          backdropFilter: "blur(24px)",
          WebkitBackdropFilter: "blur(24px)",
          border: "1px solid rgba(255,255,255,0.08)",
          borderRadius: "20px",
          padding: "28px 24px",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {/* Accent glow */}
        <div
          style={{
            position: "absolute",
            top: -20,
            right: -20,
            width: 100,
            height: 100,
            background: `radial-gradient(circle, ${accentColor}22 0%, transparent 70%)`,
            borderRadius: "50%",
          }}
          aria-hidden
        />
        <div className="flex items-center gap-4 mb-4">
          <div
            style={{
              width: 48,
              height: 48,
              borderRadius: 14,
              background: `${accentColor}14`,
              border: `1px solid ${accentColor}33`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Icon size={24} weight="duotone" color={accentColor} />
          </div>
          <div>
            <h3
              style={{
                fontFamily: "'SF Pro Display', -apple-system, system-ui, sans-serif",
                fontSize: "18px",
                fontWeight: 700,
                letterSpacing: "0.04em",
                color: "#FFFFFF",
                margin: 0,
              }}
            >
              {title}
            </h3>
            <p
              style={{
                fontFamily: "'SF Pro Text', -apple-system, system-ui, sans-serif",
                fontSize: "13px",
                color: "#71717a",
                margin: "4px 0 0",
              }}
            >
              {subtitle}
            </p>
          </div>
        </div>
        {/* Bottom accent line */}
        <div
          style={{
            height: 2,
            background: `linear-gradient(90deg, ${accentColor}00, ${accentColor}66, ${accentColor}00)`,
            borderRadius: 1,
            marginTop: 8,
          }}
          aria-hidden
        />
      </div>
    </NavLink>
  );
}

export default function CockpitHub() {
  return (
    <div style={{ padding: "24px 20px 40px" }}>
      <h1
        style={{
          fontFamily: "'SF Pro Display', -apple-system, system-ui, sans-serif",
          fontSize: "28px",
          fontWeight: 800,
          letterSpacing: "0.02em",
          color: "#FFFFFF",
          marginBottom: 8,
        }}
      >
        Cockpit
      </h1>
      <p
        style={{
          fontFamily: "'SF Pro Text', -apple-system, system-ui, sans-serif",
          fontSize: "14px",
          color: "#71717a",
          marginBottom: 28,
        }}
      >
        Your controls and preferences.
      </p>
      <div className="space-y-4">
        <HubTile
          to="/app/settings"
          icon={GearSix}
          title="Settings"
          subtitle="Account, notifications & preferences"
          accentColor="#94A3B8"
        />
        <HubTile
          to="/app/referral"
          icon={Gift}
          title="Referral"
          subtitle="Invite friends & earn rewards"
          accentColor="#34D399"
        />
      </div>
    </div>
  );
}
