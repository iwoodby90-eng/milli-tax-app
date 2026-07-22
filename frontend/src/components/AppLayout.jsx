import { NavLink, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Vault as VaultIcon, PiggyBank, MapTrifold, ChartLineUp, Receipt, GearSix,
  List, Star, Sparkle, Wallet, Robot, FileText, DotsThree, SignOut, House, Gift,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
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
    >
      <Icon size={20} weight="duotone" />
      <span className="text-[9px] font-medium tracking-wide truncate max-w-full">{label}</span>
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
    <div className="carbon-bg text-white min-h-full flex flex-col">
      {/* ============ iOS-style top bar (sticky) ============ */}
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
            <span className="font-display tracking-[0.3em] chrome-text text-[13px]">MILLI</span>
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
        <div aria-hidden className="h-6" />

        {/* Floating Weebo FAB — only on Home. Sticky-zero-height trick keeps her
            pinned above the tab bar while the page scrolls. */}
        {isHome && (
          <div
            className="sticky bottom-[18px] pointer-events-none flex justify-end pr-4 z-30"
            style={{ height: 0 }}
          >
            <NavLink
              to="/app/ai"
              data-testid="weebo-fab"
              aria-label="Ask Milli AI"
              className="pointer-events-auto -translate-y-[92px] block active:scale-95 transition-transform"
              style={{
                filter: "drop-shadow(0 8px 16px rgba(0,0,0,0.55)) drop-shadow(0 0 18px rgba(0,229,255,0.35))",
              }}
            >
              <WeeboAvatar size={58} state="idle" />
            </NavLink>
          </div>
        )}
      </main>

      {/* ============ Bottom tab bar — 3 tabs · raised M · 3 tabs ============ */}
      <nav
        className="sticky bottom-0 z-40 backdrop-blur-2xl border-t border-white/[0.06]"
        style={{ background: "rgba(5, 6, 7, 0.85)", paddingBottom: "var(--safe-bottom)" }}
        data-testid="bottom-tab-bar"
      >
        <div className="relative flex items-stretch justify-around h-[64px] px-1">
          {leftTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Center pocket for the raised M */}
          <div className="w-[68px] flex-shrink-0" aria-hidden />

          {rightTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Raised MILLI-M home button */}
          <NavLink
            to="/app"
            end
            data-testid="tab-home-center"
            className={({ isActive }) =>
              `absolute left-1/2 -translate-x-1/2 -top-6 w-[60px] h-[60px] rounded-full flex items-center justify-center active:scale-95 transition-transform ${
                isActive ? "" : ""
              }`
            }
            style={{
              background: "radial-gradient(circle at 30% 30%, #4CDCF5 0%, #00E5FF 40%, #0B7A94 100%)",
              boxShadow:
                "0 0 24px rgba(0,229,255,0.65), 0 6px 16px rgba(0,0,0,0.6), inset 0 2px 0 rgba(255,255,255,0.35), inset 0 -3px 0 rgba(0,0,0,0.25)",
              border: "1px solid rgba(255,255,255,0.35)",
            }}
            aria-label="Home"
          >
            <MilliLogo size={30} />
          </NavLink>
        </div>
      </nav>

      {/* ============ Slide-in drawer ============ */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm"
          onClick={() => setDrawerOpen(false)}
          data-testid="drawer-overlay"
        >
          <div
            className="fixed top-0 left-0 bottom-0 w-72 carbon-bg border-r border-white/10 overflow-y-auto native-scroll"
            style={{
              paddingTop:    "calc(var(--safe-top) + 20px)",
              paddingBottom: "calc(var(--safe-bottom) + 20px)",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 px-6 mb-8">
              <MilliLogo size={30} />
              <div className="font-display tracking-[0.25em] chrome-text">MILLI</div>
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
