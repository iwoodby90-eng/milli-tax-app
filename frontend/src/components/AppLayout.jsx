import { NavLink, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Vault as VaultIcon, ChartLineUp, MapTrifold, Gauge,
  List, Star, SignOut, House, Gift, PiggyBank, Receipt,
  FileText, Wallet, Robot, GearSix, DotsThree,
} from "@phosphor-icons/react";
import WeeboAvatar from "@/components/WeeboAvatar";
import { useState, useCallback } from "react";

// 4-tab + center M layout: VAULT | WEALTH | [M] | ACTIVITY | COCKPIT
const leftTabs = [
  { to: "/app/vault",     icon: VaultIcon,   label: "VAULT",     testid: "tab-vault"     },
  { to: "/app/wealth",    icon: ChartLineUp, label: "WEALTH",    testid: "tab-wealth"    },
];
const rightTabs = [
  { to: "/app/activity",  icon: MapTrifold,  label: "ACTIVITY",  testid: "tab-activity"  },
  { to: "/app/cockpit",   icon: Gauge,       label: "COCKPIT",   testid: "tab-cockpit"   },
];

// Full navigation lives in the side drawer
const drawerNav = [
  { to: "/app",            icon: House,       label: "Home", end: true },
  { to: "/app/vault",      icon: VaultIcon,   label: "Tax Vault" },
  { to: "/app/wealth",     icon: ChartLineUp, label: "Wealth" },
  { to: "/app/activity",   icon: MapTrifold,  label: "Activity" },
  { to: "/app/cockpit",    icon: Gauge,       label: "Cockpit" },
  { to: "/app/income",     icon: Wallet,      label: "Income" },
  { to: "/app/mileage",    icon: MapTrifold,  label: "Mileage" },
  { to: "/app/expenses",   icon: FileText,    label: "Expenses" },
  { to: "/app/investing",  icon: ChartLineUp, label: "Investing" },
  { to: "/app/retirement", icon: PiggyBank,   label: "401(k)" },
  { to: "/app/quarterly",  icon: Receipt,     label: "Taxes / Quarterly" },
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
              fontSize: "9px",
              fontWeight: isActive ? 600 : 500,
              letterSpacing: "0.15em",
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
// Haptics utility
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
// Uses the EXACT brand logo M path from public/brand/milli-logo.svg
// -----------------------------------------------------------------------
function ChromeDialM({ isActive }) {
  return (
    <div
      className="relative flex items-center justify-center"
      style={{ width: 66, height: 66 }}
    >
      {/* Deep recess */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          boxShadow: "inset 0px 4px 10px rgba(0,0,0,0.9), inset 0px 1px 3px rgba(0,0,0,0.7), 0px 1px 3px rgba(0,0,0,0.25)",
          mask: "radial-gradient(circle at center, white 32px, black 33px)",
          WebkitMask: "radial-gradient(circle at center, white 32px, black 33px)",
        }}
      />

      {/* Outer chrome bevel ring */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          background: "conic-gradient(from 0deg, #808080 0deg, #C0C0C0 30deg, #FFFFFF 60deg, #C0C0C0 90deg, #606060 135deg, #404040 180deg, #808080 225deg, #D0D0D0 270deg, #FFFFFF 300deg, #A0A0A0 330deg, #808080 360deg)",
          mask: "radial-gradient(circle at center, black 30px, white 30px, white 33px, black 33px)",
          WebkitMask: "radial-gradient(circle at center, black 30px, white 30px, white 33px, black 33px)",
        }}
      />

      {/* Milled metal body */}
      <div
        className="absolute rounded-full"
        style={{
          inset: 3,
          background:
            "conic-gradient(from 135deg, #2A2D32 0deg, #4A4E54 30deg, #E8ECEF 55deg, #FAFBFC 75deg, #B8BEC4 105deg, #5B6068 140deg, #1A1D21 180deg, #3A3D42 210deg, #7B8085 240deg, #D8DCE1 270deg, #F4F6F8 290deg, #8A9099 320deg, #2A2D32 360deg)",
          border: "1px solid #1A1D21",
        }}
      />

      {/* Inner face — obsidian */}
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

      {/* Breathing neon aura */}
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

      {/* The M monogram — EXACT brand logo SVG paths */}
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
          viewBox="0 0 128 128"
          aria-hidden="true"
        >
          <defs>
            <linearGradient id="nav-mChrome" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#F0F0F0" />
              <stop offset="35%" stopColor="#E8E8E8" />
              <stop offset="55%" stopColor="#808080" />
              <stop offset="80%" stopColor="#C0C0C0" />
              <stop offset="100%" stopColor="#F0F0F0" />
            </linearGradient>
            <linearGradient id="nav-mRoad" x1="0" y1="1" x2="0" y2="0">
              <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.15" />
              <stop offset="55%" stopColor="#00E5FF" stopOpacity="0.85" />
              <stop offset="100%" stopColor="#00E5FF" stopOpacity="1" />
            </linearGradient>
          </defs>
          {/* Chrome M — exact brand logo path */}
          <path
            d="M 12 116 L 12 20 L 32 12 L 54 60 L 64 40 L 74 60 L 96 12 L 116 20 L 116 116 L 96 116 L 96 48 L 76 84 L 64 68 L 52 84 L 32 48 L 32 116 Z"
            fill="url(#nav-mChrome)"
            stroke="#0A0D10"
            strokeWidth="1"
            strokeLinejoin="round"
          />
          {/* Turquoise perspective runway */}
          <path
            d="M 52 118 L 60 82 L 63 56 L 65 56 L 68 82 L 76 118 Z"
            fill="url(#nav-mRoad)"
          />
          {/* Lane markers */}
          <rect x="63.4" y="102" width="1.2" height="8" fill="#FFFFFF" opacity="0.95" />
          <rect x="63.4" y="90" width="1.2" height="6" fill="#FFFFFF" opacity="0.75" />
          <rect x="63.4" y="80" width="1.2" height="4" fill="#FFFFFF" opacity="0.5" />
          <rect x="63.4" y="72" width="1.2" height="3" fill="#FFFFFF" opacity="0.3" />
          <circle cx="64" cy="58" r="1.4" fill="#00E5FF" />
        </svg>
      </div>

      {/* Top specular crescent */}
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
            <img src="/brand/milli-logo.svg" alt="Milli" style={{ height: 28, width: 28 }} />
            <span
              style={{
                fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif",
                fontWeight: 700,
                fontSize: "13px",
                letterSpacing: "0.25em",
                background: "linear-gradient(135deg, #E8E8E8 0%, #C0C0C0 50%, #808080 100%)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                backgroundClip: "text",
              }}
            >
              MILLI
            </span>
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
      </main>

      {/* ============ Floating Weebo FAB — on EVERY page, above tab bar ============ */}
      <div
        className="fixed bottom-[96px] right-4 z-30"
        style={{
          filter: "drop-shadow(0 8px 16px rgba(0,0,0,0.55)) drop-shadow(0 0 18px rgba(0,229,255,0.35))",
        }}
      >
        <NavLink
          to="/app/ai"
          data-testid="weebo-fab"
          aria-label="Ask Milli AI"
          className="block active:scale-95 transition-transform"
        >
          <WeeboAvatar size={58} state="idle" />
        </NavLink>
      </div>

      {/* ============ Bottom tab bar — Cinematic Luxury Cockpit ============ */}
      <nav
        className="sticky bottom-0 z-40"
        style={{ paddingBottom: "var(--safe-bottom)" }}
        data-testid="bottom-tab-bar"
      >
        {/* Specular edge */}
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

        {/* Inner top highlight */}
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
              <img src="/brand/milli-logo.svg" alt="Milli" style={{ height: 30, width: 30 }} />
              <span
                style={{
                  fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif",
                  fontWeight: 700,
                  letterSpacing: "0.25em",
                  background: "linear-gradient(135deg, #E8E8E8 0%, #C0C0C0 50%, #808080 100%)",
                  WebkitBackgroundClip: "text",
                  WebkitTextFillColor: "transparent",
                  backgroundClip: "text",
                }}
              >
                MILLI
              </span>
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

      {/* Breathing aura keyframe */}
      <style>{`
        @keyframes breatheAura {
          0%, 100% { opacity: 1; box-shadow: 0 0 14px rgba(0,229,255,0.4), 0 0 28px rgba(0,229,255,0.15), inset 0 0 10px rgba(0,229,255,0.12); }
          50% { opacity: 0.7; box-shadow: 0 0 22px rgba(0,229,255,0.6), 0 0 44px rgba(0,229,255,0.25), inset 0 0 16px rgba(0,229,255,0.2); }
        }
      `}</style>
    </div>
  );
}
