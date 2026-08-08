import { Link } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Gear, ShieldCheck, Gift, Sparkle, FileText, ChartLineUp,
  PiggyBank, Bank, Car,
  Receipt, Robot, CaretRight, SignOut, Star, Coins,
  FolderOpen, Calendar, CreditCard, ChartBar,
} from "@phosphor-icons/react";
import { MilliCardHero } from "@/components/MilliCard";

/**
 * More — WWDC cinematic navigation hub. Every extra destination, styled as a luxury cockpit panel.
 */

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };

const GROUPS = [
  {
    title: "Money",
    items: [
      { to: "/app/quarterly", icon: Receipt, label: "Quarterly Tax Center", sub: "Deadlines, payments, readings" },
      { to: "/app/retirement", icon: PiggyBank, label: "Retirement — 401(k)", sub: "Auto-contribute per payout" },
      { to: "/app/investing", icon: ChartLineUp, label: "Investing", sub: "Auto-invest a % of every payout" },
      { to: "/app/milli-cents", icon: Coins, label: "Milli Cents", sub: "Offer Profitability Engine" },
      { to: "/app/savings", icon: PiggyBank, label: "Savings", sub: "Goals: emergency, vehicle, vacation" },
      { to: "/app/accounts", icon: Bank, label: "Accounts", sub: "Checking, cards, connections" },
      { to: "/app/vehicles", icon: Car, label: "Vehicles", sub: "Mileage tracking & deductions" },
      { to: "/app/annual-taxes", icon: FileText, label: "Annual Taxes", sub: "Year-end summary, filing, quarterly" },
    ],
  },
  {
    title: "Tools",
    items: [
      { to: "/app/documents", icon: FolderOpen, label: "Documents", sub: "Tax docs, receipts, statements" },
      { to: "/app/reports", icon: FileText, label: "Tax Vault Reports", sub: "Schedule C · SE · Mileage CV" },
      { to: "/app/expenses", icon: Receipt, label: "Expenses", sub: "Receipts & deductions" },
      { to: "/app/ai", icon: Robot, label: "Milli AI", sub: "Ask anything about your numbers" },
    ],
  },
  {
    title: "Account",
    items: [
      { to: "/app/subscription", icon: CreditCard, label: "Subscription", sub: "Manage plan, billing, features" },
      { to: "/app/security", icon: ShieldCheck, label: "Security & Auth", sub: "Biometric, MFA, social login" },
      { to: "/app/pricing", icon: Star, label: "Plans & Pricing", sub: "Basic · Pro · Elite" },
      { to: "/app/referral", icon: Gift, label: "Invite & Earn $10", sub: "Both sides get $10 to your Vault™" },
      { to: "/app/admin", icon: ChartBar, label: "Admin Dashboard", sub: "Platform overview & user management" },
      { to: "/app/settings", icon: Gear, label: "Settings", sub: "Profile · state · notifications" },
    ],
  },
];

export default function More() {
  const { user, logout } = useAuth();
  const initials = (user?.name || user?.email || "M").split(" ").map(s => s[0]).slice(0, 2).join("").toUpperCase();
  const plan = (user?.plan || "trial").toUpperCase();

  return (
    <div style={PAGE_STYLE}>
      {/* Header */}
      <header style={{ marginBottom: 20 }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }} data-testid="more-header">
          {(user?.name?.split(" ")[0] || "Your")} account
        </h1>
        <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Everything else, in one place.</p>
      </header>

      {/* Milli Card showcase */}
      <section data-testid="more-milli-card-section" style={{ ...SURFACE, borderRadius: 24, padding: "20px", display: "flex", flexDirection: "column", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <MilliCardHero user={user} testid="more-milli-card" />
        <div style={{ color: "#6B7280", fontSize: 11.5, textAlign: "center" }}>Ships once your first $100 clears the Milli Tax Vault™</div>
      </section>

      {/* Profile card */}
      <Link to="/app/settings" data-testid="more-profile-card" style={{ ...SURFACE, display: "flex", alignItems: "center", gap: 12, padding: "14px 16px", textDecoration: "none", marginBottom: 20 }}>
        <div style={{ width: 48, height: 48, borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 17, color: "#0A0C10", background: "radial-gradient(circle at 30% 25%, #E8ECEF, #808388 50%, #2A2E33)", boxShadow: "inset 0 1px 0 rgba(255,255,255,0.5), 0 0 14px rgba(0,229,255,0.35)" }}>
          {initials}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ color: "#fff", fontWeight: 600, fontSize: 15, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{user?.name || "Milli User"}</div>
          <div style={{ color: "#6B7280", fontSize: 12, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{user?.email || "you@milli.app"}</div>
        </div>
        <span style={{ color: "#00E5FF", fontSize: 10.5, fontWeight: 700, padding: "4px 10px", borderRadius: 999, background: "rgba(0,229,255,0.1)", border: "1px solid rgba(0,229,255,0.4)", textShadow: "0 0 6px rgba(0,229,255,0.5)", display: "flex", alignItems: "center", gap: 4 }}>
          <Star size={10} weight="fill" color="#00E5FF" /> {plan}
        </span>
      </Link>

      {/* Grouped nav */}
      {GROUPS.map((g) => (
        <section key={g.title} style={{ marginBottom: 16 }}>
          <div style={{ paddingLeft: 4, marginBottom: 8, fontSize: 10.5, fontWeight: 600, letterSpacing: "0.22em", textTransform: "uppercase", color: "#6B7280" }}>{g.title}</div>
          <div style={SURFACE}>
            <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
              {g.items.map((it, i, arr) => (
                <li key={it.to}>
                  <Link to={it.to} data-testid={`more-${it.label.toLowerCase().replace(/[^a-z]/g, "-")}`} style={{ display: "flex", alignItems: "center", gap: 12, padding: "14px 16px", textDecoration: "none", borderBottom: i === arr.length - 1 ? "none" : "1px solid rgba(255,255,255,0.05)" }}>
                    <div style={{ width: 36, height: 36, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.2)", boxShadow: "0 0 8px rgba(0,229,255,0.18)" }}>
                      <it.icon size={17} weight="regular" color="#00E5FF" />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ color: "#fff", fontSize: 14.5, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{it.label}</div>
                      <div style={{ color: "#6B7280", fontSize: 11.5, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{it.sub}</div>
                    </div>
                    <CaretRight size={14} weight="bold" color="#4B5563" style={{ flexShrink: 0 }} />
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </section>
      ))}

      {/* Sign Out */}
      <button onClick={logout} data-testid="more-signout" style={{ width: "100%", ...SURFACE, padding: "14px 0", color: "#D1D5DB", fontSize: 14, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, cursor: "pointer", border: "1px solid rgba(255,255,255,0.07)", background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))" }}>
        <SignOut size={15} weight="bold" color="#D1D5DB" /> Sign Out
      </button>

      <div style={{ textAlign: "center", color: "#4B5563", fontSize: 10.5, marginTop: 16 }}>Milli Tax Vault™ · v2.7.0</div>
    </div>
  );
}
