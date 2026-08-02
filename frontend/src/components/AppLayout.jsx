import { NavLink, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Vault as VaultIcon, PiggyBank, MapTrifold, ChartLineUp, Receipt, GearSix,
  List, Star, Sparkle, Wallet, Robot, FileText, DotsThree, SignOut, House, Gift,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import WeeboAvatar from "@/components/WeeboAvatar";
import { useState, useCallback } from "react";

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

const CYAN = "#00E5FF";

// -----------------------------------------------------------------------
// TabButton — Cinematic tab with active glow + SF Pro Display label
// -----------------------------------------------------------------------
function TabButton({ to, icon: Icon, label, testid, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      data-testid={testid}
      className={({ isActive }) =>
        `flex-1 flex flex-col items-center justify-center gap-1 min-w-0 active:opacity-60 transition-all duration-200 ${
          isActive ? "" : ""
        }`
      }
    >
      {({ isActive }) => (
        <>
          <div
            style={{
              color: isActive ? CYAN : "#71717a",
              filter: isActive ? `drop-shadow(0 0 6px rgba(0,229,255,0.6)) drop-shadow(0 0 12px rgba(0,229,255,0.25))` : "none",
              transition: "color 0.2s ease, filter 0.2s ease",
            }}
          >
            <Icon size={20} weight="duotone" />
          </div>
          <span
            style={{
              fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif",
              fontSize: "10px",
              fontWeight: isActive ? 600 : 500,
              letterSpacing: "0.1em",
              color: isActive ? CYAN : "#71717a",
              textShadow: isActive ? `0 0 8px rgba(0,229,255,0.4)` : "none",
              transition: "color 0.2s ease, text-shadow 0.2s ease",
            }}
            className="truncate max-w-full"
          >
            {label}
          </span>
        </>
      )}
    </NavLink>
  );
}

// -----------------------------------------------------------------------
// Haptics utility — triggers Capacitor Haptics if available, graceful no-op otherwise
// -----------------------------------------------------------------------
async function triggerHeavyHaptic() {
  try {
    if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.Haptics) {
      await window.Capacitor.Plugins.Haptics.impact({ style: "HEAVY" });
    } else if (navigator.vibrate) {
      navigator.vibrate(25);
    }
  } catch (_) { /* graceful no-op in browser */ }
}

// -----------------------------------------------------------------------
// ChromeDialM — The masterpiece center nav button.
// A 3D hardware dial milled from billet aluminum.
// Features:
//   • Outer chrome bevel ring (1px #C0C0C0 catching light)
//   • Deep recess shadow (inset 0 4px 10px rgba(0,0,0,0.9))
//   • Conic-gradient milled metal body
//   • Breathing neon aura pulse animation
//   • High-fidelity 3D Chrome M with cyan road
// -----------------------------------------------------------------------
function ChromeDialM({ isActive }) {
  return (
    <div
      className="relative flex items-center justify-center"
      style={{ width: 66, height: 66 }}
    >
      {/* Deep recess — makes it look physically SET INTO the dashboard */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          boxShadow:
            "inset 0px 4px 10px rgba(0,0,0,0.9), inset 0px 1px 3px rgba(0,0,0,0.7), 0px 6px 16px rgba(0,0,0,0.85), 0px 2px 4px rgba(0,0,0,0.6)",
        }}
      />

      {/* Outer chrome bevel ring — 1px specular catch */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          background: "conic-gradient(from 0deg, #808080 0deg, #C0C0C0 30deg, #FFFFFF 60deg, #C0C0C0 90deg, #606060 135deg, #404040 180deg, #808080 225deg, #D0D0D0 270deg, #FFFFFF 300deg, #A0A0A0 330deg, #808080 360deg)",
          padding: "1px",
        }}
      >
        <div className="w-full h-full rounded-full" style={{ background: "#0D0F12" }} />
      </div>

      {/* Milled metal body — conic gradient simulating machined aluminum under studio lighting */}
      <div
        className="absolute rounded-full"
        style={{
          inset: 3,
          background:
            "conic-gradient(from 135deg, #2A2D32 0deg, #4A4E54 30deg, #E8ECEF 55deg, #FAFBFC 75deg, #B8BEC4 105deg, #5B6068 140deg, #1A1D21 180deg, #3A3D42 210deg, #7B8085 240deg, #D8DCE1 270deg, #F4F6F8 290deg, #8A9099 320deg, #2A2D32 360deg)",
          border: "1px solid #1A1D21",
        }}
      />

      {/* Inner face — obsidian with radial specular highlights (concave dish effect) */}
      <div
        className="absolute rounded-full"
        style={{
          inset: 7,
          background:
            "radial-gradient(ellipse 80% 55% at 35% 22%, rgba(255,255,255,0.4) 0%, transparent 45%), radial-gradient(ellipse 50% 35% at 70% 80%, rgba(0,0,0,0.4) 0%, transparent 40%), linear-gradient(168deg, #3A3E44 0%, #1A1D21 35%, #0A0C0E 60%, #1E2226 100%)",
          border: "1px solid rgba(30,34,38,0.8)",
          boxShadow:
            "inset 0 3px 8px rgba(255,255,255,0.08), inset 0 -3px 10px rgba(0,0,0,0.8)",
        }}
      />

      {/* Breathing neon aura — pulsing ring of light */}
      <div
        className="absolute rounded-full"
        style={{
          inset: 10,
          border: `1.5px solid rgba(0,229,255,${isActive ? "0.5" : "0.25"})`,
          boxShadow: isActive
            ? `0 0 18px rgba(0,229,255,0.6), 0 0 36px rgba(0,229,255,0.25), inset 0 0 14px rgba(0,229,255,0.2)`
            : `0 0 10px rgba(0,229,255,0.35), 0 0 22px rgba(0,229,255,0.12)`,
          background: "transparent",
          animation: "breatheAura 2.4s ease-in-out infinite",
        }}
      />

      {/* The M monogram — 3D Chrome with cyan road */}
      <div
        className="relative z-10 flex items-center justify-center"
        style={{
          filter: isActive
            ? `drop-shadow(0 0 8px rgba(0,229,255,0.75)) drop-shadow(0 0 18px rgba(0,229,255,0.35))`
            : `drop-shadow(0 0 5px rgba(0,229,255,0.5)) drop-shadow(0 0 12px rgba(0,229,255,0.2))`,
          transition: "filter 0.3s ease",
        }}
      >
        <svg
          width={28}
          height={28}
          viewBox="0 0 64 64"
          aria-hidden="true"
        >
          <defs>
            <linearGradient id="nav-m-chrome" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#FFFFFF" />
              <stop offset="20%" stopColor="#F0F2F4" />
              <stop offset="45%" stopColor="#C8CDD2" />
              <stop offset="70%" stopColor="#8A9099" />
              <stop offset="100%" stopColor="#5B6068" />
            </linearGradient>
            <linearGradient id="nav-m-edge" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.85" />
              <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0" />
            </linearGradient>
            <linearGradient id="nav-m-road" x1="0" y1="1" x2="0" y2="0">
              <stop offset="0%" stopColor={CYAN} stopOpacity="1" />
              <stop offset="60%" stopColor={CYAN} stopOpacity="0.7" />
              <stop offset="100%" stopColor={CYAN} stopOpacity="0.1" />
            </linearGradient>
          </defs>
          {/* M body — chrome */}
          <path
            d="M 6 58 L 6 10 L 16 6 L 27 30 L 32 20 L 37 30 L 48 6 L 58 10 L 58 58 L 48 58 L 48 24 L 38 42 L 32 34 L 26 42 L 16 24 L 16 58 Z"
            fill="url(#nav-m-chrome)"
            stroke="rgba(0,0,0,0.3)"
            strokeWidth="0.6"
            strokeLinejoin="round"
          />
          {/* Top bevel highlight */}
          <path
            d="M 6 10 L 16 6 L 27 30 L 32 20 L 37 30 L 48 6 L 58 10 L 48 8 L 37 32 L 32 24 L 27 32 L 16 8 Z"
            fill="url(#nav-m-edge)"
            opacity="0.5"
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
          {/* Lane markers */}
          <rect x="31.5" y="50" width="1" height="5" fill="#FFF" opacity="0.8" rx="0.5" />
          <rect x="31.6" y="42" width="0.8" height="4" fill="#FFF" opacity="0.6" rx="0.4" />
          <rect x="31.7" y="36" width="0.6" height="3" fill="#FFF" opacity="0.4" rx="0.3" />
        </svg>
      </div>

      {/* Top specular crescent — wet chrome reflection on the dial's crown */}
      <div
        className="absolute rounded-full pointer-events-none"
        style={{
          top: 4,
          left: "22%",
          right: "22%",
          height: "28%",
          background:
            "linear-gradient(180deg, rgba(255,255,255,0.32) 0%, rgba(255,255,255,0.08) 50%, transparent 100%)",
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

  const handleMTap = useCallback(() => {
    triggerHeavyHaptic();
  }, []);

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

      {/* ============ Bottom tab bar — Cinematic Luxury Cockpit ============ */}
      <nav
        className="sticky bottom-0 z-40"
        style={{ paddingBottom: "var(--safe-bottom)" }}
        data-testid="bottom-tab-bar"
      >
        {/* Specular edge — 0.5px white highlight at the very top of the bar */}
        <div
          className="absolute top-0 left-0 right-0 pointer-events-none"
          style={{
            height: "1px",
            background: "linear-gradient(90deg, transparent 5%, rgba(255,255,255,0.3) 30%, rgba(255,255,255,0.45) 50%, rgba(255,255,255,0.3) 70%, transparent 95%)",
          }}
          aria-hidden="true"
        />

        {/* Multi-layer brushed titanium background */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: `
              linear-gradient(180deg, 
                rgba(42,45,50,0.92) 0%, 
                rgba(22,24,28,0.96) 25%,
                rgba(13,15,18,0.98) 50%,
                rgba(10,12,15,0.99) 75%,
                rgba(5,6,7,1) 100%
              )
            `,
            backdropFilter: "blur(32px) saturate(1.4)",
            WebkitBackdropFilter: "blur(32px) saturate(1.4)",
          }}
          aria-hidden="true"
        />

        {/* Brushed titanium texture overlay */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            backgroundImage: "repeating-linear-gradient(90deg, transparent, transparent 1px, rgba(255,255,255,0.008) 1px, rgba(255,255,255,0.008) 2px)",
            mixBlendMode: "overlay",
          }}
          aria-hidden="true"
        />

        {/* Inner top highlight — subtle light catching the bevel */}
        <div
          className="absolute top-[1px] left-[10%] right-[10%] pointer-events-none"
          style={{
            height: "1px",
            background: "linear-gradient(90deg, transparent, rgba(200,210,220,0.12) 30%, rgba(200,210,220,0.18) 50%, rgba(200,210,220,0.12) 70%, transparent)",
          }}
          aria-hidden="true"
        />

        <div className="relative flex items-stretch justify-around h-[68px] px-1">
          {leftTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Center pocket for the raised M dial */}
          <div className="w-[72px] flex-shrink-0" aria-hidden />

          {rightTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Raised Chrome Dial M — the masterpiece hardware button */}
          <NavLink
            to="/app"
            end
            data-testid="tab-home-center"
            className="absolute left-1/2 -translate-x-1/2 -top-[20px] active:scale-[0.93] transition-transform duration-100"
            aria-label="Home"
            onClick={handleMTap}
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

      {/* Breathing aura keyframe — injected once */}
      <style>{`
        @keyframes breatheAura {
          0%, 100% { opacity: 1; box-shadow: 0 0 14px rgba(0,229,255,0.4), 0 0 28px rgba(0,229,255,0.15), inset 0 0 10px rgba(0,229,255,0.12); }
          50% { opacity: 0.7; box-shadow: 0 0 22px rgba(0,229,255,0.6), 0 0 44px rgba(0,229,255,0.25), inset 0 0 16px rgba(0,229,255,0.2); }
        }
      `}</style>
    </div>
  );
}
