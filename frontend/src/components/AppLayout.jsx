import { NavLink, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Vault as VaultIcon, PiggyBank, MapTrifold, ChartLineUp, Receipt, GearSix,
  List, Star, Wallet, Robot, FileText, DotsThree, SignOut, House, Gift,
  X, CaretRight,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import { useState } from "react";

const primaryTabs = [
  { to: "/app", icon: House, label: "Home", testid: "tab-home", end: true },
  { to: "/app/income", icon: Wallet, label: "Payouts", testid: "tab-payouts" },
  { to: "/app/vault", icon: VaultIcon, label: "Tax Vault", testid: "tab-vault" },
  { to: "/app/mileage", icon: MapTrifold, label: "Mileage", testid: "tab-mileage" },
  { to: "/app/ai", icon: Robot, label: "Milli AI", testid: "tab-ai" },
];

const drawerGroups = [
  {
    label: "Money",
    items: [
      { to: "/app/expenses", icon: FileText, label: "Expenses" },
      { to: "/app/quarterly", icon: Receipt, label: "Quarterly Taxes" },
      { to: "/app/reports", icon: FileText, label: "Reports & Documents" },
    ],
  },
  {
    label: "Build Wealth",
    items: [
      { to: "/app/retirement", icon: PiggyBank, label: "Retirement" },
      { to: "/app/investing", icon: ChartLineUp, label: "Investing" },
    ],
  },
  {
    label: "Account",
    items: [
      { to: "/app/referral", icon: Gift, label: "Invite & Earn" },
      { to: "/app/settings", icon: GearSix, label: "Settings" },
      { to: "/app/more", icon: DotsThree, label: "More" },
    ],
  },
];

function TabButton({ to, icon: Icon, label, testid, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      data-testid={testid}
      aria-label={label}
      className="milli-tab"
    >
      {({ isActive }) => (
        <>
          <span className={`milli-tab-icon ${isActive ? "is-active" : ""}`}>
            <Icon size={22} weight={isActive ? "fill" : "regular"} />
          </span>
          <span className={`milli-tab-label ${isActive ? "is-active" : ""}`}>{label}</span>
        </>
      )}
    </NavLink>
  );
}

export default function AppLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const location = useLocation();
  const [drawerOpen, setDrawerOpen] = useState(false);

  const pageTitle = primaryTabs.find((item) =>
    item.end ? location.pathname === "/app" || location.pathname === "/app/" : location.pathname.startsWith(item.to)
  )?.label || "Milli";

  return (
    <div className="milli-shell">
      <header className="milli-topbar">
        <div className="milli-topbar-inner">
          <button
            type="button"
            data-testid="mobile-menu-btn"
            onClick={() => setDrawerOpen(true)}
            className="milli-icon-button"
            aria-label="Open menu"
          >
            <List size={22} weight="bold" />
          </button>

          <NavLink to="/app" className="milli-brand" data-testid="topbar-brand" aria-label="Milli Home">
            <MilliLogo size={23} />
            <span>MILLI</span>
          </NavLink>

          <NavLink to="/app/pricing" data-testid="mobile-plan-badge" className="milli-plan-pill">
            <Star size={11} weight="fill" />
            {(user?.plan === "trial" || !user?.plan) ? "Trial" : String(user.plan)}
          </NavLink>
        </div>
        <div className="milli-page-context" aria-hidden="true">{pageTitle}</div>
      </header>

      <main className="milli-main native-scroll" data-testid="app-main-scroll">
        {children}
        <div aria-hidden className="h-5" />
      </main>

      <nav className="milli-bottom-bar" data-testid="bottom-tab-bar" aria-label="Primary navigation">
        <div className="milli-bottom-bar-inner">
          {primaryTabs.map((tab) => <TabButton key={tab.to} {...tab} />)}
        </div>
      </nav>

      {drawerOpen && (
        <div className="milli-drawer-overlay" onClick={() => setDrawerOpen(false)} data-testid="drawer-overlay">
          <aside className="milli-drawer" onClick={(event) => event.stopPropagation()} aria-label="More navigation">
            <div className="milli-drawer-header">
              <div className="milli-brand milli-brand-large">
                <MilliLogo size={32} />
                <span>MILLI</span>
              </div>
              <button type="button" onClick={() => setDrawerOpen(false)} className="milli-icon-button" aria-label="Close menu">
                <X size={20} weight="bold" />
              </button>
            </div>

            <div className="milli-account-summary">
              <div className="milli-account-avatar">{(user?.name || user?.email || "M").slice(0, 1).toUpperCase()}</div>
              <div className="min-w-0">
                <div className="milli-account-name">{user?.name || "Milli Member"}</div>
                <div className="milli-account-plan">{user?.plan ? `${String(user.plan).toUpperCase()} PLAN` : "TRIAL PLAN"}</div>
              </div>
              <NavLink to="/app/settings" onClick={() => setDrawerOpen(false)} className="milli-drawer-chevron" aria-label="Open account settings">
                <CaretRight size={17} weight="bold" />
              </NavLink>
            </div>

            <nav className="milli-drawer-nav">
              {drawerGroups.map((group) => (
                <section key={group.label} className="milli-drawer-group">
                  <div className="milli-drawer-group-title">{group.label}</div>
                  {group.items.map((item) => (
                    <NavLink
                      key={item.to}
                      to={item.to}
                      onClick={() => setDrawerOpen(false)}
                      className={({ isActive }) => `milli-drawer-link ${isActive ? "is-active" : ""}`}
                    >
                      <item.icon size={19} weight="duotone" />
                      <span>{item.label}</span>
                      <CaretRight size={14} className="ml-auto opacity-40" />
                    </NavLink>
                  ))}
                </section>
              ))}
            </nav>

            <button
              type="button"
              onClick={() => { logout(); nav("/"); }}
              className="milli-signout"
              data-testid="drawer-logout"
            >
              <SignOut size={17} weight="bold" /> Sign Out
            </button>
          </aside>
        </div>
      )}
    </div>
  );
}
