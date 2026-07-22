import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Gauge, Wallet, MapTrifold, Vault as VaultIcon, DotsThree, SignOut, List, Star,
  Sparkle, FileText, Robot, PiggyBank, ChartLineUp,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import { useState } from "react";

// Bottom tab bar — 5 slots, exactly like an iOS app
const bottomTabs = [
  { to: "/app",         icon: Gauge,      label: "Home",    end: true, testid: "tab-home"    },
  { to: "/app/income",  icon: Wallet,     label: "Income",             testid: "tab-income"  },
  { to: "/app/mileage", icon: MapTrifold, label: "Mileage",            testid: "tab-mileage" },
  { to: "/app/vault",   icon: VaultIcon,  label: "Vault",              testid: "tab-vault"   },
  { to: "/app/more",    icon: DotsThree,  label: "More",               testid: "tab-more"    },
];

// Slide-in drawer — full nav tree
const drawerNav = [
  { to: "/app",            icon: Gauge,       label: "Home", end: true },
  { to: "/app/income",     icon: Wallet,      label: "Income" },
  { to: "/app/mileage",    icon: MapTrifold,  label: "Mileage" },
  { to: "/app/vault",      icon: VaultIcon,   label: "Tax Vault" },
  { to: "/app/retirement", icon: PiggyBank,   label: "401(k)" },
  { to: "/app/investing",  icon: ChartLineUp, label: "Investing" },
  { to: "/app/quarterly",  icon: Sparkle,     label: "Quarterly" },
  { to: "/app/expenses",   icon: FileText,    label: "Expenses" },
  { to: "/app/ai",         icon: Robot,       label: "Assistant" },
  { to: "/app/reports",    icon: FileText,    label: "Reports" },
  { to: "/app/more",       icon: DotsThree,   label: "More" },
];

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="carbon-bg text-white min-h-full flex flex-col">
      {/* ============ iOS-style top bar (sticky within scroll container) ============ */}
      <header
        className="sticky top-0 z-40 backdrop-blur-2xl border-b border-white/[0.06]"
        style={{
          background: "rgba(5, 6, 7, 0.72)",
          paddingTop: "var(--safe-top)",
        }}
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
            <MilliLogo size={26} />
            <span className="font-display tracking-[0.3em] chrome-text text-[15px]">MILLI</span>
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

      {/* ============ Main content — flows naturally, sticky header/nav reserve their own space ============ */}
      <main className="flex-1 native-scroll" data-testid="app-main-scroll">
        {children}
        {/* Small spacer so last card never kisses the sticky tab bar */}
        <div aria-hidden className="h-4" />
      </main>

      {/* ============ iOS-style bottom tab bar (sticky within scroll container) ============ */}
      <nav
        className="sticky bottom-0 z-40 backdrop-blur-2xl border-t border-white/[0.06]"
        style={{
          background: "rgba(5, 6, 7, 0.78)",
          paddingBottom: "var(--safe-bottom)",
        }}
        data-testid="bottom-tab-bar"
      >
        <div className="flex items-stretch justify-around h-[54px]">
          {bottomTabs.map((t) => (
            <NavLink
              key={t.to}
              to={t.to}
              end={t.end}
              data-testid={t.testid}
              className={({ isActive }) =>
                `flex-1 flex flex-col items-center justify-center gap-0.5 active:opacity-60 ${
                  isActive ? "text-volt" : "text-zinc-500"
                }`
              }
            >
              <t.icon size={22} weight="duotone" />
              <span className="text-[10px] font-medium tracking-wide">{t.label}</span>
            </NavLink>
          ))}
        </div>
      </nav>

      {/* ============ Slide-in drawer (iOS half-sheet feel) ============ */}
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
                      isActive
                        ? "bg-volt/10 text-volt"
                        : "text-zinc-300"
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
