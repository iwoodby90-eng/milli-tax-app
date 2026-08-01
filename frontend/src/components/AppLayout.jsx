import { NavLink, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Vault as VaultIcon, PiggyBank, MapTrifold, ChartLineUp, Receipt, GearSix,
  List, Star, Sparkle, Wallet, Robot, FileText, DotsThree, SignOut, House, Gift,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import NavDialButton from "@/components/NavDialButton";
import WeeboAvatar from "@/components/WeeboAvatar";
import { useState } from "react";

// 6 side buttons + center raised M — symmetric 3 / M / 3
const leftTabs = [
  { to: "/app/vault",      icon: VaultIcon,   label: "Vault",     testid: "tab-vault"   },
  { to: "/app/retirement", icon: PiggyBank,   label: "401(k)",    testid: "tab-retire"  },
  { to: "/app/investing",  icon: ChartLineUp, label: "Invest",    testid: "tab-invest"  },
];
const rightTabs = [
  { to: "/app/mileage",    icon: MapTrifold,  label: "Mileage",   testid: "tab-mileage" },
  { to: "/app/quarterly",  icon: Receipt,     label: "Taxes",     testid: "tab-taxes"   },
  { to: "/app/settings",   icon: GearSix,     label: "Settings",  testid: "tab-settings"},
];

// Full navigation lives in the side drawer
const drawerNav = [
  { to: "/app",            icon: House,       label: "Home", end: true },
  { to: "/app/income",     icon: Wallet,      label: "Income" },
  { to: "/app/mileage",    icon: MapTrifold,  label: "Mileage" },
  { to: "/app/vault",      icon: VaultIcon,   label: "Tax Vault" },
  { to: "/app/retirement", icon: PiggyBank,   label: "401(k)" },
  { to: "/app/investing",  icon: ChartLineUp, label: "Investing" },
  { to: "/app/quarterly",  icon: Receipt,     label: "Taxes / Quarterly" },
  { to: "/app/expenses",   icon: FileText,    label: "Expenses" },
  { to: "/app/ai",         icon: Robot,       label: "Milli AI" },
  { to: "/app/referral",   icon: Gift,        label: "Invite & Earn $10" },
  { to: "/app/reports",    icon: FileText,    label: "Reports" },
  { to: "/app/settings",   icon: GearSix,     label: "Settings" },
  { to: "/app/more",       icon: DotsThree,   label: "More" },
];

function TabButton({ to, icon: Icon, label, testid, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      data-testid={testid}
      className={({ isActive }) =>
        `flex-1 flex flex-col items-center justify-center gap-0.5 min-w-0 active:opacity-60 ${
          isActive ? "text-volt" : "text-zinc-500"
        }`
      }
      style={{ all: "unset", cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", flex: 1, gap: 2, minWidth: 0 }}
    >
      {({ isActive }) => (
        <>
          <Icon size={20} weight="duotone" style={{ color: isActive ? "#00E5FF" : "#71717a" }} />
          <span style={{ fontSize: 9, fontWeight: 500, letterSpacing: "0.03em", color: isActive ? "#00E5FF" : "#71717a", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", maxWidth: "100%" }}>{label}</span>
        </>
      )}
    </NavLink>
  );
}

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const isHome = loc.pathname === "/app" || loc.pathname === "/app/";

  return (
    <div className="carbon-bg text-white min-h-full flex flex-col" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100vh", WebkitFontSmoothing: "antialiased" }}>
      {/* ============ iOS-style top bar (sticky) ============ */}
      <header
        className="sticky top-0 z-40"
        style={{ background: "rgba(5, 6, 7, 0.72)", backdropFilter: "blur(24px) saturate(1.3)", WebkitBackdropFilter: "blur(24px) saturate(1.3)", borderBottom: "1px solid rgba(255,255,255,0.06)", paddingTop: "var(--safe-top)" }}
      >
        <div className="flex items-center justify-between px-5 h-11">
          <button
            data-testid="mobile-menu-btn"
            onClick={() => setDrawerOpen(true)}
            style={{ all: "unset", cursor: "pointer", padding: 8, marginLeft: -8, color: "#e4e4e7" }}
            aria-label="Open menu"
          >
            <List size={22} weight="bold" />
          </button>
          <NavLink to="/app" className="flex items-center gap-2 active:opacity-70" data-testid="topbar-brand" style={{ textDecoration: "none" }}>
            <MilliLogo size={22} />
            <span style={{ fontFamily: "'Sora', sans-serif", letterSpacing: "0.3em", fontSize: 13, background: "linear-gradient(135deg, #E8E8E8, #808080)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>MILLI</span>
          </NavLink>
          <NavLink
            to="/app/pricing"
            data-testid="mobile-plan-badge"
            style={{ all: "unset", cursor: "pointer", padding: "4px 10px", fontSize: 11, fontWeight: 600, borderRadius: 8, border: "1px solid rgba(0,229,255,0.3)", color: "#00E5FF", display: "inline-flex", alignItems: "center", gap: 4 }}
          >
            <Star size={11} weight="fill" />
            {(user?.plan === "trial" || !user?.plan) ? "Trial" : String(user.plan).toUpperCase()}
          </NavLink>
        </div>
      </header>

      {/* ============ Main content ============ */}
      <main className="flex-1 native-scroll" data-testid="app-main-scroll">
        {children}
        <div aria-hidden className="h-6" />

        {/* Floating Weebo FAB */}
        {isHome && (
          <div className="sticky bottom-[18px] pointer-events-none flex justify-end pr-4 z-30" style={{ height: 0 }}>
            <NavLink
              to="/app/ai"
              data-testid="weebo-fab"
              aria-label="Ask Milli AI"
              className="pointer-events-auto -translate-y-[92px] block active:scale-95 transition-transform"
              style={{ filter: "drop-shadow(0 8px 16px rgba(0,0,0,0.55)) drop-shadow(0 0 18px rgba(0,229,255,0.35))" }}
            >
              <WeeboAvatar size={58} state="idle" />
            </NavLink>
          </div>
        )}
      </main>

      {/* ============ Bottom Tab Bar — Brushed Titanium + 3D Hardware Dial ============ */}
      <nav
        className="sticky bottom-0 z-40"
        style={{
          background: "linear-gradient(180deg, rgba(22,24,28,0.97) 0%, rgba(12,14,16,0.99) 100%)",
          backdropFilter: "blur(24px) saturate(1.3)",
          WebkitBackdropFilter: "blur(24px) saturate(1.3)",
          borderTop: "1px solid rgba(255,255,255,0.04)",
          boxShadow: "0 -4px 24px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.03)",
          paddingBottom: "var(--safe-bottom)",
        }}
        data-testid="bottom-tab-bar"
      >
        {/* Specular top edge — hardware feel */}
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 1, background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.08), transparent)" }} />

        <div className="relative flex items-stretch justify-around h-[64px] px-1">
          {leftTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Center pocket for the 3D Hardware Dial */}
          <div style={{ width: 68, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center" }} aria-hidden>
            <NavDialButton size={56} onClick={() => nav("/app")} />
          </div>

          {rightTabs.map((t) => <TabButton key={t.to} {...t} />)}
        </div>
      </nav>

      {/* ============ Slide-in drawer ============ */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-50"
          style={{ backgroundColor: "rgba(0,0,0,0.7)", backdropFilter: "blur(4px)" }}
          onClick={() => setDrawerOpen(false)}
          data-testid="drawer-overlay"
        >
          <div
            className="fixed top-0 left-0 bottom-0 w-72 overflow-y-auto native-scroll"
            style={{
              backgroundColor: "#050607",
              borderRight: "1px solid rgba(255,255,255,0.06)",
              paddingTop: "calc(var(--safe-top) + 20px)",
              paddingBottom: "calc(var(--safe-bottom) + 20px)",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 px-6 mb-8">
              <MilliLogo size={30} />
              <div style={{ fontFamily: "'Sora', sans-serif", letterSpacing: "0.25em", background: "linear-gradient(135deg, #E8E8E8, #808080)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>MILLI</div>
            </div>
            <nav className="space-y-1 px-3">
              {drawerNav.map((it) => (
                <NavLink
                  key={it.label}
                  to={it.to}
                  end={it.end}
                  onClick={() => setDrawerOpen(false)}
                  style={{ textDecoration: "none" }}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-3 py-3 text-[15px] font-medium rounded-xl active:opacity-60 ${
                      isActive ? "bg-volt/10 text-volt" : "text-zinc-300"
                    }`
                  }
                >
                  <it.icon size={18} weight="duotone" />
                  {it.label}
                </NavLink>
              ))}
            </nav>
            <div className="px-6 pt-6">
              <button
                onClick={() => { logout(); nav("/"); }}
                style={{ all: "unset", cursor: "pointer", width: "100%", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, padding: "12px 0", fontSize: 14, color: "#a1a1aa", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 12 }}
                data-testid="drawer-logout"
              >
                <SignOut size={16} weight="bold" /> Sign Out
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
