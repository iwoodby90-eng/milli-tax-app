import { NavLink, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Bell,
  ChartLineUp,
  DotsThree,
  FileText,
  GearSix,
  Gift,
  Gauge,
  House,
  List,
  MapTrifold,
  PiggyBank,
  Receipt,
  Robot,
  SignOut,
  Vault as VaultIcon,
  Wallet,
} from "@phosphor-icons/react";
import WeeboAvatar from "@/components/WeeboAvatar";
import { useCallback, useState } from "react";

const CYAN = "#00E5FF";

const bottomLeft = [
  { to: "/app", icon: House, label: "Dashboard", end: true, testid: "tab-dashboard" },
  { to: "/app/activity", icon: MapTrifold, label: "Activity", testid: "tab-activity" },
];

const bottomRight = [
  { to: "/app/vault", icon: VaultIcon, label: "Transfers", testid: "tab-transfers" },
  { to: "/app/more", icon: DotsThree, label: "More", testid: "tab-more" },
];

const drawerNav = [
  { to: "/app", icon: House, label: "Dashboard", end: true },
  { to: "/app/milli-cents", icon: Gauge, label: "Milli Cents" },
  { to: "/app/income", icon: Wallet, label: "Payouts" },
  { to: "/app/vault", icon: VaultIcon, label: "Milli Tax Vault™" },
  { to: "/app/mileage", icon: MapTrifold, label: "Mileage Tracker" },
  { to: "/app/investing", icon: ChartLineUp, label: "Investing" },
  { to: "/app/retirement", icon: PiggyBank, label: "Retirement" },
  { to: "/app/quarterly", icon: Receipt, label: "Quarterly Taxes" },
  { to: "/app/expenses", icon: FileText, label: "Expenses" },
  { to: "/app/ai", icon: Robot, label: "Milli AI" },
  { to: "/app/reports", icon: FileText, label: "Reports" },
  { to: "/app/referral", icon: Gift, label: "Invite & Earn" },
  { to: "/app/settings", icon: GearSix, label: "Settings" },
];

function TabButton({ to, icon: Icon, label, end, testid }) {
  return (
    <NavLink
      to={to}
      end={end}
      data-testid={testid}
      aria-label={label}
      style={{
        flex: 1,
        minWidth: 0,
        minHeight: 72,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        textDecoration: "none",
      }}
    >
      {({ isActive }) => (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
          <Icon
            size={22}
            weight={isActive ? "fill" : "regular"}
            color={isActive ? CYAN : "#8B929C"}
            style={{ filter: isActive ? "drop-shadow(0 0 9px rgba(0,229,255,.7))" : "none" }}
          />
          <span style={{
            color: isActive ? CYAN : "#A2A8B0",
            fontSize: 10,
            fontWeight: isActive ? 700 : 550,
            textShadow: isActive ? "0 0 10px rgba(0,229,255,.45)" : "none",
            whiteSpace: "nowrap",
          }}>
            {label}
          </span>
        </div>
      )}
    </NavLink>
  );
}

async function triggerHeavyHaptic() {
  try {
    if (window.Capacitor?.Plugins?.Haptics) {
      await window.Capacitor.Plugins.Haptics.impact({ style: "HEAVY" });
    } else if (navigator.vibrate) {
      navigator.vibrate(25);
    }
  } catch (_) {
    // Enhancement only.
  }
}

function ChromeHomeButton({ active }) {
  return (
    <div style={{
      width: 72,
      height: 72,
      borderRadius: "50%",
      padding: 4,
      background: "conic-gradient(from 20deg,#4A4F56,#F8FAFC,#7C838C,#EEF2F6,#3D4249,#C7CDD4,#FFFFFF,#555B63)",
      boxShadow: active
        ? "0 0 0 2px rgba(0,229,255,.55),0 0 26px rgba(0,229,255,.55),0 13px 28px rgba(0,0,0,.7)"
        : "0 0 0 1px rgba(255,255,255,.22),0 0 18px rgba(0,229,255,.3),0 13px 28px rgba(0,0,0,.7)",
      position: "relative",
    }}>
      <div style={{
        width: "100%",
        height: "100%",
        borderRadius: "50%",
        background: "radial-gradient(circle at 32% 24%,rgba(255,255,255,.23),transparent 28%),linear-gradient(155deg,#343940 0%,#0A0D10 52%,#23282E 100%)",
        border: "1px solid rgba(0,0,0,.8)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        overflow: "hidden",
        boxShadow: "inset 0 2px 4px rgba(255,255,255,.18),inset 0 -6px 12px rgba(0,0,0,.65)",
      }}>
        <img
          src="/brand/milli-logo.svg"
          alt=""
          style={{ width: 43, height: 43, objectFit: "contain", filter: "drop-shadow(0 0 8px rgba(0,229,255,.5))" }}
        />
      </div>
      <div style={{
        position: "absolute",
        left: "22%",
        right: "22%",
        bottom: -7,
        height: 3,
        borderRadius: 999,
        background: CYAN,
        filter: "blur(1px)",
        boxShadow: "0 0 14px rgba(0,229,255,.95)",
        opacity: active ? 1 : .65,
      }} />
    </div>
  );
}

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const isHome = location.pathname === "/app" || location.pathname === "/app/";

  const onCenterHome = useCallback(() => {
    triggerHeavyHaptic();
  }, []);

  const onLogout = async () => {
    await logout();
    navigate("/login", { replace: true });
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: "radial-gradient(circle at 50% -12%,rgba(0,229,255,.09),transparent 31%),linear-gradient(180deg,#071016 0%,#050607 36%,#030405 100%)",
      color: "#FFFFFF",
      fontFamily: "-apple-system,BlinkMacSystemFont,'SF Pro Display','Sora',system-ui,sans-serif",
      WebkitFontSmoothing: "antialiased",
    }}>
      <header style={{
        position: "sticky",
        top: 0,
        zIndex: 40,
        paddingTop: "var(--safe-top)",
        background: "linear-gradient(180deg,rgba(5,6,7,.96),rgba(5,6,7,.74))",
        backdropFilter: "blur(28px) saturate(1.3)",
        WebkitBackdropFilter: "blur(28px) saturate(1.3)",
        borderBottom: "1px solid rgba(0,229,255,.1)",
      }}>
        <div style={{ height: 54, padding: "0 18px", display: "grid", gridTemplateColumns: "44px 1fr 44px", alignItems: "center" }}>
          <button
            type="button"
            onClick={() => setDrawerOpen(true)}
            aria-label="Open navigation"
            data-testid="mobile-menu-btn"
            style={{ all: "unset", width: 40, height: 40, display: "grid", placeItems: "center", cursor: "pointer", color: "#E7EBEF" }}
          >
            <List size={23} weight="bold" />
          </button>

          <NavLink to="/app" style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 9, textDecoration: "none" }}>
            <img src="/brand/milli-logo.svg" alt="Milli" style={{ width: 28, height: 28 }} />
            <span style={{ color: CYAN, fontSize: 21, fontWeight: 800, letterSpacing: ".04em", textShadow: "0 0 14px rgba(0,229,255,.35)" }}>
              milli
            </span>
          </NavLink>

          <NavLink
            to="/app/more"
            aria-label="Notifications"
            style={{ width: 40, height: 40, display: "grid", placeItems: "center", justifySelf: "end", color: "#E7EBEF", position: "relative" }}
          >
            <Bell size={22} weight="regular" />
            <span style={{ position: "absolute", top: 8, right: 7, width: 7, height: 7, borderRadius: "50%", background: CYAN, boxShadow: "0 0 9px rgba(0,229,255,.9)" }} />
          </NavLink>
        </div>
      </header>

      <main style={{ minHeight: "calc(100vh - 54px)", paddingBottom: "calc(112px + var(--safe-bottom))" }} data-testid="app-main-scroll">
        {children}
      </main>

      <NavLink
        to="/app/ai"
        aria-label="Open Milli AI"
        data-testid="weebo-fab"
        style={{
          position: "fixed",
          right: 17,
          bottom: "calc(92px + var(--safe-bottom))",
          zIndex: 45,
          textDecoration: "none",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          filter: "drop-shadow(0 8px 20px rgba(0,0,0,.65)) drop-shadow(0 0 18px rgba(0,229,255,.42))",
        }}
      >
        <div style={{
          borderRadius: "50%",
          padding: 2,
          background: "linear-gradient(145deg,#F4F7F9,#767D85 44%,#00E5FF 72%,#F4F7F9)",
          boxShadow: "0 0 0 1px rgba(0,229,255,.32),0 0 24px rgba(0,229,255,.25)",
        }}>
          <WeeboAvatar size={58} state="idle" />
        </div>
        <span style={{
          marginTop: -2,
          padding: "5px 13px",
          borderRadius: 999,
          color: "#EAFDFF",
          background: "linear-gradient(180deg,rgba(29,43,52,.96),rgba(9,15,19,.98))",
          border: "1px solid rgba(0,229,255,.35)",
          boxShadow: "0 0 14px rgba(0,229,255,.18)",
          fontSize: 11,
          fontWeight: 650,
        }}>
          Milli AI
        </span>
      </NavLink>

      <nav style={{
        position: "fixed",
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 42,
        paddingBottom: "var(--safe-bottom)",
        background: "linear-gradient(180deg,rgba(26,31,36,.96),rgba(6,8,10,.99) 48%,#020304 100%)",
        borderTop: "1px solid rgba(201,214,225,.24)",
        boxShadow: "0 -18px 40px rgba(0,0,0,.48),0 -1px 18px rgba(0,229,255,.08)",
        backdropFilter: "blur(28px)",
        WebkitBackdropFilter: "blur(28px)",
      }} data-testid="bottom-tab-bar">
        <div style={{ height: 76, display: "flex", alignItems: "stretch", padding: "0 4px", maxWidth: 760, margin: "0 auto", position: "relative" }}>
          {bottomLeft.map((tab) => <TabButton key={tab.to} {...tab} />)}
          <div style={{ width: 80, flexShrink: 0 }} aria-hidden="true" />
          {bottomRight.map((tab) => <TabButton key={tab.to} {...tab} />)}

          <NavLink
            to="/app"
            end
            aria-label="Milli home"
            data-testid="tab-home-center"
            onClick={onCenterHome}
            style={{ position: "absolute", left: "50%", top: -24, transform: "translateX(-50%)", textDecoration: "none" }}
          >
            <ChromeHomeButton active={isHome} />
          </NavLink>
        </div>
      </nav>

      {drawerOpen && (
        <div
          role="presentation"
          onClick={() => setDrawerOpen(false)}
          style={{ position: "fixed", inset: 0, zIndex: 60, background: "rgba(0,0,0,.72)", backdropFilter: "blur(8px)" }}
          data-testid="drawer-overlay"
        >
          <aside
            onClick={(event) => event.stopPropagation()}
            style={{
              width: "min(84vw,320px)",
              height: "100%",
              overflowY: "auto",
              padding: "calc(var(--safe-top) + 24px) 18px calc(var(--safe-bottom) + 24px)",
              background: "radial-gradient(circle at 18% 0%,rgba(0,229,255,.12),transparent 30%),linear-gradient(180deg,#10161B,#050607 62%)",
              borderRight: "1px solid rgba(0,229,255,.2)",
              boxShadow: "24px 0 70px rgba(0,0,0,.7)",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "0 8px 22px", borderBottom: "1px solid rgba(255,255,255,.07)" }}>
              <img src="/brand/milli-logo.svg" alt="Milli" style={{ width: 44, height: 44 }} />
              <div>
                <div style={{ color: CYAN, fontSize: 21, fontWeight: 800 }}>milli</div>
                <div style={{ color: "#8B929C", fontSize: 11 }}>{user?.name || user?.email || "Financial command center"}</div>
              </div>
            </div>

            <div style={{ display: "grid", gap: 5, paddingTop: 18 }}>
              {drawerNav.map(({ to, icon: Icon, label, end }) => (
                <NavLink
                  key={to}
                  to={to}
                  end={end}
                  onClick={() => setDrawerOpen(false)}
                  style={({ isActive }) => ({
                    display: "flex",
                    alignItems: "center",
                    gap: 13,
                    minHeight: 48,
                    padding: "0 14px",
                    borderRadius: 14,
                    textDecoration: "none",
                    color: isActive ? "#EAFEFF" : "#B1B7BE",
                    background: isActive ? "linear-gradient(90deg,rgba(0,229,255,.16),rgba(0,229,255,.035))" : "transparent",
                    border: isActive ? "1px solid rgba(0,229,255,.26)" : "1px solid transparent",
                    boxShadow: isActive ? "inset 3px 0 0 #00E5FF,0 0 18px rgba(0,229,255,.08)" : "none",
                    fontSize: 13,
                    fontWeight: isActive ? 700 : 550,
                  })}
                >
                  {({ isActive }) => <><Icon size={20} weight="duotone" color={isActive ? CYAN : "#8B929C"} /><span>{label}</span></>}
                </NavLink>
              ))}
            </div>

            <button
              type="button"
              onClick={onLogout}
              data-testid="drawer-logout"
              style={{
                width: "100%",
                minHeight: 48,
                marginTop: 20,
                borderRadius: 14,
                border: "1px solid rgba(255,82,107,.2)",
                background: "rgba(255,82,107,.05)",
                color: "#FF7488",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 9,
                cursor: "pointer",
                fontWeight: 650,
              }}
            >
              <SignOut size={19} weight="duotone" /> Sign out
            </button>
          </aside>
        </div>
      )}
    </div>
  );
}
