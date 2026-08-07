import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  SquaresFour, ListBullets, ArrowsLeftRight, DotsThreeOutline,
  Bell, List, SignOut, House, Vault as VaultIcon, ChartLineUp,
  MapTrifold, Coins, Receipt, Wallet, FileText, Gift, GearSix,
  PiggyBank, Bank, Car,
  FolderOpen, Calendar, CreditCard,
  ShieldCheck, ChartBar, Gauge,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import MilliFAB from "@/components/MilliFAB";
import NotificationSheet from "@/components/NotificationSheet";
import { usePushNotifications } from "@/hooks/usePushNotifications";
import { useState } from "react";

/**
 * Milli Tax Vault — App shell (v4.9 Bel Air Cockpit).
 * Top bar:  28px logo + SF Pro Display "MILLI" wordmark left  |  bell right.
 * Bottom nav: VAULT ⟶ WEALTH ⟶ [raised chrome M dial] ⟶ ACTIVITY ⟶ COCKPIT.
 * Milli AI floats as a persistent sphere at bottom-right (no tab).
 */

const leftTabs = [
  { to: "/app/vault",    icon: VaultIcon,   label: "VAULT",    testid: "tab-vault" },
  { to: "/app/wealth",   icon: ChartLineUp, label: "WEALTH",   testid: "tab-wealth" },
];
const rightTabs = [
  { to: "/app/activity", icon: ListBullets,  label: "ACTIVITY", testid: "tab-activity" },
  { to: "/app/cockpit",  icon: Gauge,        label: "COCKPIT",  testid: "tab-cockpit" },
];

const drawerNav = [
  { to: "/app",              icon: House,          label: "Dashboard" },
  { to: "/app/income",       icon: Wallet,         label: "Activity / Payouts" },
  { to: "/app/vault",        icon: VaultIcon,       label: "Milli Tax Vault™" },
  { to: "/app/wealth",       icon: ChartLineUp,     label: "Wealth (401k + Investing)" },
  { to: "/app/mileage",      icon: MapTrifold,      label: "Mileage" },
  { to: "/app/milli-cents",  icon: Coins,          label: "Milli Cents" },
  { to: "/app/savings",      icon: PiggyBank,      label: "Savings" },
  { to: "/app/accounts",     icon: Bank,           label: "Accounts" },
  { to: "/app/vehicles",     icon: Car,            label: "Vehicles" },
  { to: "/app/annual-taxes", icon: FileText,       label: "Annual Taxes" },
  { to: "/app/documents",    icon: FolderOpen,      label: "Documents" },
  { to: "/app/quarterly",    icon: Receipt,        label: "Quarterly Taxes" },
  { to: "/app/expenses",     icon: FileText,       label: "Expenses" },
  { to: "/app/subscription", icon: CreditCard,     label: "Subscription" },
  { to: "/app/security",     icon: ShieldCheck,    label: "Security & Auth" },
  { to: "/app/referral",     icon: Gift,           label: "Invite & Earn $10" },
  { to: "/app/reports",      icon: FileText,       label: "Reports" },
  { to: "/app/admin",       icon: ChartBar,       label: "Admin Dashboard" },
  { to: "/app/settings",    icon: GearSix,        label: "Settings" },
];

function TabButton({ to, icon: Icon, label, end, testid }) {
  return (
    <NavLink
      to={to}
      end={end}
      data-testid={testid}
      className={({ isActive }) =>
        `flex-1 flex flex-col items-center justify-center gap-1 min-w-0 active:opacity-60 transition-colors ${
          isActive ? "text-volt" : "text-zinc-500"
        }`
      }
      style={({ isActive }) =>
        isActive ? { textShadow: "0 0 10px rgba(0,229,255,0.55)" } : undefined
      }
    >
      {({ isActive }) => (
        <>
          <Icon size={22} weight={isActive ? "fill" : "regular"} />
          <span className="text-[10px] font-semibold tracking-[0.08em] truncate max-w-full uppercase">
            {label}
          </span>
        </>
      )}
    </NavLink>
  );
}

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);

  // Register APNs / FCM device token on native iOS/Android launch
  usePushNotifications(true);

  return (
    <div className="carbon-bg app-aura text-white min-h-full flex flex-col relative">
      <div className="aura-streak" aria-hidden />

      {/* === Top bar — 28px logo + SF Pro Display "MILLI" wordmark left, bell right === */}
      <header
        className="sticky top-0 z-40 backdrop-blur-2xl"
        style={{
          background: "linear-gradient(180deg, rgba(5,6,7,0.9) 0%, rgba(5,6,7,0.6) 100%)",
          paddingTop: "var(--safe-top)",
        }}
      >
        <div className="flex items-center justify-between px-5 h-12">
          <button
            data-testid="mobile-menu-btn"
            onClick={() => setDrawerOpen(true)}
            className="active:opacity-60 flex items-center gap-2"
          >
            <List size={20} weight="bold" className="text-zinc-400 sm:hidden" />
            <MilliLogo size={28} />
            <span
              className="font-display text-[22px] leading-none select-none"
              style={{
                fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
                fontWeight: 700,
                letterSpacing: "0.06em",
                background: "linear-gradient(180deg, #FFFFFF 0%, #E0E4E8 40%, #A0A8B0 70%, #6E7379 100%)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                filter: "drop-shadow(0 0 8px rgba(0,229,255,0.35))",
              }}
              data-testid="topbar-brand"
            >
              MILLI
            </span>
          </button>
          <button
            data-testid="topbar-bell"
            onClick={() => setNotifOpen(true)}
            aria-label="Notifications"
            className="relative w-9 h-9 flex items-center justify-center rounded-full active:opacity-60"
          >
            <Bell size={22} weight="regular" className="text-white/80" />
            <span
              className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-volt"
              style={{ boxShadow: "0 0 8px rgba(0,229,255,0.9)" }}
            />
          </button>
        </div>
      </header>

      {/* === Main content === */}
      <main className="flex-1 native-scroll relative z-10" data-testid="app-main-scroll">
        {children}
        <div aria-hidden className="h-28" />
      </main>

      {/* === Bottom tab bar — 4-tab Bel Air Cockpit + raised chrome M dial === */}
      <nav
        className="sticky bottom-0 z-40 backdrop-blur-2xl border-t border-white/[0.06]"
        style={{
          background: "linear-gradient(180deg, rgba(5,6,7,0.75) 0%, rgba(5,6,7,0.95) 100%)",
          paddingBottom: "var(--safe-bottom)",
        }}
        data-testid="bottom-tab-bar"
      >
        <div className="relative flex items-stretch justify-around h-[68px] px-1">
          {leftTabs.map((t) => <TabButton key={t.to} {...t} />)}
          <div className="w-[76px] flex-shrink-0" aria-hidden />
          {rightTabs.map((t) => <TabButton key={t.to} {...t} />)}

          {/* Raised chrome M dial — center home button */}
          <NavLink
            to="/app"
            end
            data-testid="tab-home-center"
            aria-label="Home"
            className="absolute left-1/2 -translate-x-1/2 -top-7 active:scale-95 transition-transform"
          >
            <ChromeDialM />
          </NavLink>
        </div>
      </nav>

      {/* Persistent Milli AI floating sphere — bottom-right, NOT a tab */}
      <MilliFAB />

      {/* Notification sheet */}
      <NotificationSheet open={notifOpen} onClose={() => setNotifOpen(false)} />

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
                <span
                  className="font-display text-[20px] leading-none select-none"
                  style={{
                    fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
                    fontWeight: 700,
                    letterSpacing: "0.06em",
                    background: "linear-gradient(180deg, #FFFFFF 0%, #E0E4E8 40%, #A0A8B0 70%, #6E7379 100%)",
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                  }}
                >
                  MILLI
                </span>
                <div className="text-[10px] text-zinc-600 uppercase tracking-widest mt-1">Tax Vault</div>
              </div>
            </div>
            <nav className="space-y-1 px-3">
              {drawerNav.map((item) => (
                <NavLink
                  key={item.label}
                  to={item.to}
                  end={item.end}
                  onClick={() => setDrawerOpen(false)}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-3 py-3 text-[15px] font-medium rounded-xl active:opacity-60 ${
                      isActive ? "bg-volt/10 text-volt" : "text-zinc-300"
                    }`
                  }
                >
                  <item.icon size={18} weight="duotone" />
                  {item.label}
                </NavLink>
              ))}
            </nav>
            <div className="px-6 pt-6 text-[11px] text-zinc-600 uppercase tracking-widest">
              Signed in as {(user?.plan || "trial").toUpperCase()}
            </div>
            <div className="px-6 pt-3">
              <button
                onClick={() => { logout(); nav("/"); }}
                data-testid="drawer-logout"
                className="w-full flex items-center justify-center gap-2 px-3 py-3 text-sm text-zinc-400 border border-white/10 rounded-xl active:bg-white/[0.04]"
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

/* === Chrome M Dial — Raised home button matching the Bel Air Cockpit spec === */
function ChromeDialM() {
  return (
    <div
      className="w-[68px] h-[68px] rounded-full flex items-center justify-center relative"
      style={{
        background:
          "radial-gradient(circle at 32% 24%, #FDFDFE 0%, #E8ECEF 22%, #B2B7BD 48%, #7A8087 72%, #3F454B 92%, #22272C 100%)",
        boxShadow:
          "inset 0 3px 3px rgba(255,255,255,0.75), inset 0 -4px 8px rgba(0,0,0,0.55), 0 8px 22px rgba(0,0,0,0.6), 0 0 32px rgba(0,229,255,0.55), 0 14px 24px rgba(0,229,255,0.35)",
      }}
    >
      {/* underworld cyan light bloom */}
      <span
        className="absolute -bottom-3 left-1/2 -translate-x-1/2 w-10 h-2.5 rounded-full pointer-events-none"
        style={{
          background: "rgba(0,229,255,0.95)",
          filter: "blur(7px)",
          opacity: 0.95,
        }}
      />
      {/* soft top-light shield */}
      <span
        className="absolute top-1 left-2 right-2 h-3 rounded-full pointer-events-none"
        style={{
          background: "linear-gradient(180deg, rgba(255,255,255,0.6) 0%, rgba(255,255,255,0) 100%)",
          filter: "blur(2px)",
        }}
      />
      {/* Big polished chrome M — logo-aligned angular style */}
      <span
        style={{
          fontFamily: "'Sora','Inter',sans-serif",
          fontWeight: 900,
          fontSize: 38,
          lineHeight: 1,
          background: "linear-gradient(180deg, #FFFFFF 0%, #E8ECEF 30%, #6E7379 62%, #24272C 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          letterSpacing: "-0.05em",
          filter:
            "drop-shadow(0 2px 0 rgba(0,0,0,0.55)) drop-shadow(0 -1px 0 rgba(255,255,255,0.35))",
          position: "relative",
          zIndex: 2,
        }}
      >
        M
      </span>
    </div>
  );
}
