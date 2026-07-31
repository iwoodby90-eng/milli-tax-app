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

// -----------------------------------------------------------------------
// ChromeDialM — The rebuilt center nav button.
// A 3D hardware component: chrome specular highlights, obsidian milled edge,
// recessed dial shadow, and a neon cyan-aura M monogram.
// Designed to feel like a physical gauge knob milled from billet aluminum.
// -----------------------------------------------------------------------
function ChromeDialM({ isActive }) {
  return (
    <div
      className="relative flex items-center justify-center"
      style={{
        width: 62,
        height: 62,
      }}
    >
      {/* Outer recessed shadow — makes it look set INTO the chrome bar */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          boxShadow:
            "0px 4px 12px rgba(0,0,0,0.8), 0px 1px 3px rgba(0,0,0,0.6), inset 0px 2px 4px rgba(0,0,0,0.5)",
        }}
      />

      {/* Chrome body — specular gradient simulating light hitting polished metal */}
      <div
        className="absolute inset-[1px] rounded-full"
        style={{
          background:
            "conic-gradient(from 135deg, #3A3D42 0deg, #E8ECEF 45deg, #FAFBFC 90deg, #B8BEC4 135deg, #5B6068 180deg, #2A2D32 225deg, #7B8085 270deg, #D8DCE1 315deg, #3A3D42 360deg)",
          border: "1px solid #1A1D21",
        }}
      />

      {/* Inner ring bevel — secondary specular highlight (inner shadow) */}
      <div
        className="absolute rounded-full"
        style={{
          inset: 5,
          background:
            "radial-gradient(ellipse 80% 60% at 35% 25%, rgba(255,255,255,0.45) 0%, transparent 50%), radial-gradient(ellipse 60% 40% at 65% 75%, rgba(0,0,0,0.35) 0%, transparent 50%), linear-gradient(165deg, #4A4E54 0%, #1A1D21 40%, #0D0F12 70%, #2A2E33 100%)",
          border: "1px solid #1A1D21",
          boxShadow:
            "inset 0 2px 6px rgba(255,255,255,0.12), inset 0 -2px 8px rgba(0,0,0,0.7)",
        }}
      />

      {/* Neon cyan aura glow (subtle, breathes life into the dial) */}
      <div
        className="absolute rounded-full"
        style={{
          inset: 8,
          boxShadow: isActive
            ? "0 0 16px rgba(0,229,255,0.55), 0 0 32px rgba(0,229,255,0.2), inset 0 0 12px rgba(0,229,255,0.15)"
            : "0 0 10px rgba(0,229,255,0.3), 0 0 20px rgba(0,229,255,0.1)",
          border: "1px solid rgba(0,229,255,0.25)",
          background: "transparent",
          transition: "box-shadow 0.3s ease",
        }}
      />

      {/* The M monogram — rendered as SVG with cyan glow aura */}
      <div
        className="relative z-10 flex items-center justify-center"
        style={{
          filter: isActive
            ? "drop-shadow(0 0 6px rgba(0,229,255,0.7)) drop-shadow(0 0 14px rgba(0,229,255,0.35))"
            : "drop-shadow(0 0 4px rgba(0,229,255,0.5)) drop-shadow(0 0 10px rgba(0,229,255,0.2))",
          transition: "filter 0.3s ease",
        }}
      >
        <svg
          width={26}
          height={26}
          viewBox="0 0 64 64"
          aria-hidden="true"
        >
          <defs>
            <linearGradient id="nav-m-chrome" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#FFFFFF" />
              <stop offset="30%" stopColor="#E8ECEF" />
              <stop offset="60%" stopColor="#B0B5BB" />
              <stop offset="100%" stopColor="#7B8085" />
            </linearGradient>
            <linearGradient id="nav-m-road" x1="0" y1="1" x2="0" y2="0">
              <stop offset="0%" stopColor="#00E5FF" stopOpacity="1" />
              <stop offset="70%" stopColor="#00E5FF" stopOpacity="0.6" />
              <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.1" />
            </linearGradient>
          </defs>
          {/* M body */}
          <path
            d="M 6 58 L 6 10 L 16 6 L 27 30 L 32 20 L 37 30 L 48 6 L 58 10 L 58 58 L 48 58 L 48 24 L 38 42 L 32 34 L 26 42 L 16 24 L 16 58 Z"
            fill="url(#nav-m-chrome)"
            stroke="rgba(0,229,255,0.3)"
            strokeWidth="0.5"
            strokeLinejoin="round"
          />
          {/* Cyan road */}
          <path
            d="M 25 60 L 30 34 L 32 26 L 34 34 L 39 60 Z"
            fill="url(#nav-m-road)"
          />
          <path
            d="M 28 60 L 31 36 L 32 30 L 33 36 L 36 60 Z"
            fill="#7CF6FF"
            opacity="0.5"
          />
        </svg>
      </div>

      {/* Top specular highlight — final "wet" chrome reflection */}
      <div
        className="absolute rounded-full pointer-events-none"
        style={{
          top: 3,
          left: "20%",
          right: "20%",
          height: "30%",
          background:
            "linear-gradient(180deg, rgba(255,255,255,0.28) 0%, rgba(255,255,255,0.05) 60%, transparent 100%)",
          borderRadius: "50% 50% 40% 40%",
        }}
      />
    </div>
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

        {/* Floating Weebo FAB — only on Home */}
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

      {/* ============ Bottom tab bar — 1954 Bel Air dashboard chrome ============ */}
      <nav
        className="sticky bottom-0 z-40"
        style={{
          background: "linear-gradient(180deg, rgba(26,29,33,0.95) 0%, rgba(13,15,18,0.98) 100%)",
          borderTop: "1px solid rgba(192,192,192,0.12)",
          boxShadow: "0 -2px 20px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.05)",
          backdropFilter: "blur(20px) saturate(1.3)",
          WebkitBackdropFilter: "blur(20px) saturate(1.3)",
          paddingBottom: "var(--safe-bottom)",
        }}
        data-testid="bottom-tab-bar"
      >
        <div className="relative flex items-stretch justify-around h-[64px] px-1">
          {leftTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Center pocket for the raised M dial */}
          <div className="w-[68px] flex-shrink-0" aria-hidden />

          {rightTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Raised Chrome Dial M — the centerpiece hardware button */}
          <NavLink
            to="/app"
            end
            data-testid="tab-home-center"
            className="absolute left-1/2 -translate-x-1/2 -top-[18px] active:scale-95 transition-transform"
            aria-label="Home"
          >
            {({ isActive }) => <ChromeDialM isActive={isActive} />}
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
