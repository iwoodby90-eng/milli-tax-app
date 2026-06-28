import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Gauge, Wallet, Vault, ChartLineUp, Gear, SignOut, List, Star,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import { useState } from "react";

// Sidebar (desktop) — full menu
const sideNav = [
  { to: "/app", icon: Gauge, label: "Dashboard", end: true, testid: "nav-dashboard" },
  { to: "/app/income", icon: Wallet, label: "Payouts", testid: "nav-income" },
  { to: "/app/mileage", icon: ChartLineUp, label: "Mileage", testid: "nav-mileage" },
  { to: "/app/expenses", icon: Vault, label: "Expenses", testid: "nav-expenses" },
  { to: "/app/ai", icon: Star, label: "AI Assistant", testid: "nav-ai" },
  { to: "/app/reports", icon: Vault, label: "Tax Vault", testid: "nav-reports" },
  { to: "/app/pricing", icon: Star, label: "Plans", testid: "nav-pricing" },
  { to: "/app/settings", icon: Gear, label: "Settings", testid: "nav-settings" },
];

// Bottom tab bar (mobile) — 5 anchors: Dashboard / Payouts / [M logo center] / Tax Vault / Insights
const bottomTabs = [
  { to: "/app", icon: Gauge, label: "Dashboard", end: true },
  { to: "/app/income", icon: Wallet, label: "Payouts" },
  { center: true, to: "/app", label: "M" },
  { to: "/app/reports", icon: Vault, label: "Tax Vault" },
  { to: "/app/mileage", icon: ChartLineUp, label: "Insights" },
];

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="min-h-screen carbon-bg text-white flex">
      {/* Desktop sidebar */}
      <aside className="w-64 hidden lg:flex flex-col border-r border-hairline bg-obsidian/80 sticky top-0 h-screen">
        <div className="px-6 py-6 border-b border-hairline">
          <NavLink to="/app" className="flex items-center gap-3" data-testid="sidebar-logo">
            <MilliLogo size={32} />
            <div className="font-display tracking-[0.25em] text-lg chrome-text">MILLI</div>
          </NavLink>
        </div>
        <nav className="flex-1 px-3 py-4 space-y-1">
          {sideNav.map((it) => (
            <NavLink
              key={it.label}
              to={it.to}
              end={it.end}
              data-testid={it.testid}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all ${
                  isActive
                    ? "bg-cyan-400/10 text-volt border border-volt/40"
                    : "text-zinc-400 hover:text-white hover:bg-white/[0.03] border border-transparent"
                }`
              }
            >
              <it.icon size={18} weight="duotone" />
              {it.label}
            </NavLink>
          ))}
        </nav>
        <div className="px-3 py-4 border-t border-hairline">
          <div className="px-3 py-2 mb-2 milli-card !rounded-xl !py-3 flex items-center gap-2">
            <Star size={14} weight="fill" className="text-volt" />
            <div className="flex-1">
              <div className="text-[10px] text-zinc-500 font-mono uppercase tracking-wider">Plan</div>
              <div className="font-chrome font-bold text-sm uppercase tracking-wider text-volt" data-testid="sidebar-plan">
                {user?.plan || "trial"}
              </div>
            </div>
          </div>
          <button
            data-testid="sidebar-logout"
            onClick={() => { logout(); nav("/"); }}
            className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-zinc-400 hover:text-danger border border-hairline rounded-xl hover:border-danger/60 transition-colors"
          >
            <SignOut size={16} weight="bold" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Mobile top bar */}
      <div className="lg:hidden fixed top-0 inset-x-0 z-40 carbon-bg/95 backdrop-blur-xl border-b border-hairline">
        <div className="flex items-center justify-between px-5 py-3">
          <button
            data-testid="mobile-menu-btn"
            onClick={() => setDrawerOpen(true)}
            className="text-zinc-300 p-2 -ml-2"
          >
            <List size={22} weight="bold" />
          </button>
          <NavLink to="/app" className="flex items-center gap-2">
            <MilliLogo size={26} />
            <span className="font-display tracking-[0.3em] chrome-text">MILLI</span>
          </NavLink>
          <NavLink
            to="/app/pricing"
            data-testid="mobile-plan-badge"
            className="btn-outline-cyan px-3 py-1.5 text-xs font-semibold inline-flex items-center gap-1.5"
          >
            <Star size={12} weight="fill" /> {user?.plan === "trial" ? "Trial" : (user?.plan || "trial").toUpperCase()}
          </NavLink>
        </div>
      </div>

      {/* Mobile bottom tab nav */}
      <div className="lg:hidden fixed bottom-0 inset-x-0 z-40 carbon-bg/95 backdrop-blur-xl border-t border-hairline">
        <div className="flex items-end justify-around py-2 pb-3 relative">
          {bottomTabs.map((t, i) => (
            t.center ? (
              <NavLink
                key={i}
                to={t.to}
                data-testid="mobile-center-logo"
                className="-mt-6 flex flex-col items-center"
              >
                <div className="w-14 h-14 rounded-full bg-obsidian border-2 border-volt/70 flex items-center justify-center shadow-[0_0_18px_rgba(0,229,255,0.4)]">
                  <MilliLogo size={28} />
                </div>
              </NavLink>
            ) : (
              <NavLink
                key={i}
                to={t.to}
                end={t.end}
                data-testid={`mobile-tab-${t.label.toLowerCase()}`}
                className={({ isActive }) =>
                  `flex flex-col items-center gap-1 px-2 py-1 min-w-[64px] ${isActive ? "text-volt" : "text-zinc-500"}`
                }
              >
                <t.icon size={20} weight="duotone" />
                <span className="text-[10px] font-medium tracking-wide">{t.label}</span>
              </NavLink>
            )
          ))}
        </div>
      </div>

      {/* Mobile drawer */}
      {drawerOpen && (
        <div className="lg:hidden fixed inset-0 z-50 bg-black/70 backdrop-blur-sm" onClick={() => setDrawerOpen(false)}>
          <div
            className="absolute top-0 left-0 bottom-0 w-72 carbon-bg border-r border-hairline p-6 overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 mb-8">
              <MilliLogo size={28} />
              <div className="font-display tracking-[0.25em] chrome-text">MILLI</div>
            </div>
            <nav className="space-y-1">
              {sideNav.map((it) => (
                <NavLink
                  key={it.label}
                  to={it.to}
                  end={it.end}
                  onClick={() => setDrawerOpen(false)}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-3 py-3 text-sm font-medium rounded-xl ${
                      isActive ? "bg-cyan-400/10 text-volt" : "text-zinc-400 hover:text-white"
                    }`
                  }
                >
                  <it.icon size={18} weight="duotone" /> {it.label}
                </NavLink>
              ))}
            </nav>
            <button
              onClick={() => { logout(); nav("/"); }}
              className="mt-6 w-full flex items-center gap-2 px-3 py-3 text-sm text-zinc-400 hover:text-danger border border-hairline rounded-xl"
            >
              <SignOut size={16} weight="bold" /> Sign Out
            </button>
          </div>
        </div>
      )}

      <main className="flex-1 min-w-0 pt-16 pb-24 lg:pt-0 lg:pb-0">{children}</main>
    </div>
  );
}
