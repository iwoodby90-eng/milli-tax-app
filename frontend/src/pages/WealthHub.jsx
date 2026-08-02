import { NavLink } from "react-router-dom";
import { ChartLineUp, PiggyBank } from "@phosphor-icons/react";

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
              background: "rgba(0,229,255,0.08)",
              border: "1px solid rgba(0,229,255,0.2)",
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

export default function WealthHub() {
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
        Wealth
      </h1>
      <p
        style={{
          fontFamily: "'SF Pro Text', -apple-system, system-ui, sans-serif",
          fontSize: "14px",
          color: "#71717a",
          marginBottom: 28,
        }}
      >
        Your portfolio and retirement at a glance.
      </p>
      <div className="space-y-4">
        <HubTile
          to="/app/investing"
          icon={ChartLineUp}
          title="Investing"
          subtitle="Brokerage portfolio & market positions"
        />
        <HubTile
          to="/app/retirement"
          icon={PiggyBank}
          title="401(k)"
          subtitle="Retirement savings & contributions"
          accentColor="#A78BFA"
        />
      </div>
    </div>
  );
}
