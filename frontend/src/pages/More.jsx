import { Link } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Gear, ShieldCheck, Gift, Sparkle, FileText, ChartLineUp, PiggyBank,
  Receipt, Robot, CaretRight, SignOut, Star, Coins,
} from "@phosphor-icons/react";

/**
 * More — extra destinations, styled in Milli aesthetic (card list).
 */
const GROUPS = [
  {
    title: "Money",
    items: [
      { to: "/app/quarterly",   icon: Receipt,     label: "Quarterly Tax Center",  sub: "Deadlines, payments, readiness" },
      { to: "/app/retirement",  icon: PiggyBank,   label: "Retirement · 401(k)",   sub: "Auto-contribute per payout" },
      { to: "/app/investing",   icon: ChartLineUp, label: "Investing",             sub: "Auto-invest a % of every payout" },
      { to: "/app/milli-cents", icon: Coins,       label: "Milli Cents",           sub: "Offer Profitability Engine" },
    ],
  },
  {
    title: "Tools",
    items: [
      { to: "/app/reports",     icon: FileText,    label: "Tax Vault Reports",     sub: "Schedule C · SE · Mileage CSV" },
      { to: "/app/expenses",    icon: FileText,    label: "Expenses",              sub: "Receipts & deductions" },
      { to: "/app/ai",          icon: Robot,       label: "Milli AI",              sub: "Ask anything about your numbers" },
    ],
  },
  {
    title: "Account",
    items: [
      { to: "/app/pricing",     icon: Star,        label: "Plans & Billing",       sub: "Basic · Pro · Elite" },
      { to: "/app/referral",    icon: Gift,        label: "Invite & Earn $10",     sub: "Both sides get $10 to your Vault" },
      { to: "/app/settings",    icon: Gear,        label: "Settings",              sub: "Profile · state · notifications" },
    ],
  },
];

export default function More() {
  const { user, logout } = useAuth();
  const initials = (user?.name || user?.email || "M").split(" ").map(s => s[0]).slice(0, 2).join("").toUpperCase();
  const plan = (user?.plan || "trial").toUpperCase();

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">
      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          More
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Everything else, in one place.</p>
      </header>

      {/* Profile card */}
      <Link
        to="/app/settings"
        data-testid="more-profile-card"
        className="milli-card block rounded-2xl p-4 active:scale-[0.995] transition-transform"
      >
        <div className="flex items-center gap-3">
          <div
            className="w-12 h-12 rounded-2xl flex items-center justify-center font-chrome font-bold text-white text-[17px]"
            style={{
              background: "radial-gradient(circle at 30% 25%, #E8ECEF 0%, #808388 50%, #2A2E33 100%)",
              boxShadow: "inset 0 1px 0 rgba(255,255,255,0.5), 0 0 14px rgba(0,229,255,0.35)",
              color: "#0A0C10",
            }}
          >
            {initials}
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-white font-semibold text-[15.5px] truncate">{user?.name || "Milli User"}</div>
            <div className="text-zinc-500 text-[12px] truncate">{user?.email || "you@milli.app"}</div>
          </div>
          <span
            className="text-volt text-[10.5px] font-bold px-2 py-1 rounded-full tracking-wider"
            style={{
              background: "rgba(0,229,255,0.10)",
              border: "1px solid rgba(0,229,255,0.4)",
              textShadow: "0 0 6px rgba(0,229,255,0.5)",
            }}
          >
            <Star size={10} weight="fill" className="inline mr-1" /> {plan}
          </span>
        </div>
      </Link>

      {/* Grouped nav */}
      {GROUPS.map((g) => (
        <section key={g.title}>
          <div className="px-1 mb-2 font-mono text-[10.5px] uppercase tracking-[0.28em] text-zinc-500">
            {g.title}
          </div>
          <div className="milli-card rounded-2xl overflow-hidden">
            <ul>
              {g.items.map((it, i, arr) => (
                <li key={it.to}>
                  <Link
                    to={it.to}
                    data-testid={`more-${it.label.toLowerCase().replace(/[^a-z]/g, "-")}`}
                    className={`flex items-center gap-3 py-3.5 px-4 active:bg-white/[0.03] ${
                      i === arr.length - 1 ? "" : "border-b border-white/[0.05]"
                    }`}
                  >
                    <div
                      className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{
                        background: "rgba(0,229,255,0.08)",
                        border: "1px solid rgba(0,229,255,0.28)",
                        boxShadow: "0 0 8px rgba(0,229,255,0.18)",
                      }}
                    >
                      <it.icon size={17} weight="regular" className="text-volt" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-white text-[14.5px] font-medium truncate">{it.label}</div>
                      <div className="text-zinc-500 text-[11.5px] truncate">{it.sub}</div>
                    </div>
                    <CaretRight size={14} weight="bold" className="text-zinc-600 flex-shrink-0" />
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </section>
      ))}

      <button
        onClick={logout}
        data-testid="more-signout"
        className="w-full milli-card rounded-2xl py-3.5 text-zinc-300 text-[14px] font-semibold inline-flex items-center justify-center gap-2 active:opacity-70"
      >
        <SignOut size={15} weight="bold" /> Sign Out
      </button>

      <div className="text-center text-zinc-600 text-[10.5px] pt-2">
        Milli Tax Vault™ · v2.6.0
      </div>
    </div>
  );
}
