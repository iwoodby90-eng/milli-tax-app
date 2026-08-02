import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Vault as VaultIcon, ChartLineUp, MapTrifold, GearSix,
  List, Star, Wallet, Robot, FileText, DotsThree, SignOut, House, PiggyBank, Gift, Receipt, Coins,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import MilliFAB from "@/components/MilliFAB";
import { useState } from "react";

const leftTabs = [
  { to: "/app/vault",   icon: VaultIcon,    label: "Vault",    testid: "tab-vault"   },
  { to: "/app/wealth",  icon: ChartLineUp,  label: "Wealth",   testid: "tab-wealth"  },
];
const rightTabs = [
  { to: "/app/mileage",  icon: MapTrifold, label: "Mileage",  testid: "tab-mileage"  },
  { to: "/app/settings", icon: GearSix,    label: "Settings", testid: "tab-settings" },
];

const drawerNav = [
  { to: "/app",             icon: House,       label: "Dashboard", end: true },
  { to: "/app/vault",       icon: VaultIcon,   label: "Vault (Tax + Holding)" },
  { to: "/app/wealth",      icon: ChartLineUp, label: "Wealth (401k + Investing)" },
  { to: "/app/mileage",     icon: MapTrifold,  label: "Mileage" },
  { to: "/app/milli-cents", icon: Coins,       label: "Milli Cents" },
  { to: "/app/quarterly",   icon: Receipt,     label: "Taxes / Quarterly" },
  { to: "/app/income",      icon: Wallet,      label: "Income" },
  { to: "/app/expenses",    icon: FileText,    label: "Expenses" },
  { to: "/app/ai",          icon: Robot,       label: "Milli AI" },
  { to: "/app/referral",    icon: Gift,        label: "Invite & Earn $10" },
  { to: "/app/reports",     icon: FileText,    label: "Reports" },
  { to: "/app/settings",    icon: GearSix,     label: "Settings" },
];

function TabButton({ to, icon: Icon, label, testid }) {
  return (
    <NavLink
      to={to}
      data-testid={testid}
      className={({ isActive }) =>
        `flex-1 flex flex-col items-center justify-center gap-0.5 min-w-0 active:opacity-60 ${
          isActive ? "text-volt" : "text-zinc-500"
        }`
      }
    >
      <Icon size={20} weight="duotone" />
      <span className="text-[10px] font-medium tracking-wide truncate max-w-full">{label}</span>
    </NavLink>
  );
}

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="carbon-bg text-white min-h-full flex flex-col">
      {/* ============ Top bar ============ */}
      <header
        className="sticky top-0 z-40 backdrop-blur-2xl border-b border-white/[0.06]"
        style={{ background: "rgba(5, 6, 7, 0.72)", paddingTop: "var(--safe-top)" }}
      >
        <div className="flex items-center justify-between px-5 h-11">
          <button
            data-testid="mobile-menu-btn"
            onClick={() => setDrawerOpen(true)}
            className="p-2 -ml-2 text-zinc-200 active:opacity-60"
            aria-label="Open menu"
          >
            <List size={22} weight="bold" />
          </button>
          <NavLink to="/app" className="flex items-center gap-2 active:opacity-70" data-testid="topbar-brand">
            <MilliLogo size={22} />
            <span className="font-display tracking-[0.24em] chrome-text text-[13px]">MILLI</span>
          </NavLink>
          <NavLink
            to="/app/pricing"
            data-testid="mobile-plan-badge"
            className="btn-outline-cyan px-2.5 py-1 text-[11px] font-semibold inline-flex items-center gap-1.5 active:opacity-70"
          >
            <Star size={11} weight="fill" />
            {(user?.plan === "trial" || !user?.plan) ? "Trial" : String(user.plan).toUpperCase()}
          </NavLink>
        </div>
      </header>

      {/* ============ Main content ============ */}
      <main className="flex-1 native-scroll" data-testid="app-main-scroll">
        {children}
        <div aria-hidden className="h-24" />
      </main>

      {/* ============ Bottom tab bar — 5 slots symmetric ============ */}
      <nav
        className="sticky bottom-0 z-40 backdrop-blur-2xl border-t border-white/[0.06]"
        style={{ background: "rgba(5, 6, 7, 0.85)", paddingBottom: "var(--safe-bottom)" }}
        data-testid="bottom-tab-bar"
      >
        <div className="relative flex items-stretch justify-around h-[64px] px-1">
          {leftTabs.map((t) => <TabButton key={t.to} {...t} />)}
          <div className="w-[68px] flex-shrink-0" aria-hidden />
          {rightTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Raised chrome-M home button — floating glyph, no sticker frame */}
          <NavLink
            to="/app"
            end
            data-testid="tab-home-center"
            aria-label="Home"
            className="absolute left-1/2 -translate-x-1/2 -top-6 w-[60px] h-[60px] flex items-center justify-center active:scale-95 transition-transform"
            style={{
              filter:
                "drop-shadow(0 0 22px rgba(0,229,255,0.65)) drop-shadow(0 8px 14px rgba(0,0,0,0.65))",
            }}
          >
            <MilliLogo size={60} />
          </NavLink>
        </div>
      </nav>

      {/* Persistent Milli AI floating avatar (visible on every /app/* route except /app/ai) */}
      <MilliFAB />

      {/* Slide-in drawer */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm"
          onClick={() => setDrawerOpen(false)}
          data-testid="drawer-overlay"
        >
          <div
            className="fixed top-0 left-0 bottom-0 w-72 carbon-bg border-r border-white/10 overflow-y-auto native-scroll"
            style={{
              paddingTop: "calc(var(--safe-top) + 20px)",
              paddingBottom: "calc(var(--safe-bottom) + 20px)",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 px-6 mb-6">
              <MilliLogo size={32} />
              <div>
                <div className="font-display tracking-[0.22em] chrome-text text-sm">MILLI</div>
                <div className="text-[10px] text-zinc-500 tracking-widest uppercase">Tax Vault</div>
              </div>
            </div>
            <nav className="space-y-1 px-3">
              {drawerNav.map((it) => (
                <NavLink
                  key={it.label}
                  to={it.to}
                  end={it.end}
                  onClick={() => setDrawerOpen(false)}
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
                className="w-full flex items-center justify-center gap-2 px-3 py-3 text-sm text-zinc-400 border border-white/10 rounded-xl active:bg-white/[0.04]"
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
