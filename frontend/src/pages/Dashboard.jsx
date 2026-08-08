import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  Eye, CaretRight, Bank, Gauge, Plant, ChartLineUp,
  Receipt, FileText, ShieldCheck,
} from "@phosphor-icons/react";
import { EliteBadge } from "@/components/MilliPrimitives";
import { MilliCardHero, MilliCardMini, cardMetaFor } from "@/components/MilliCard";
import MilliVaultBridge from "@/plugins/MilliVaultBridge";
import MilliLogo from "@/components/MilliLogo";

/**
 * Milli Tax Vault — Dashboard.
 * WWDC-quality cinematic hero screen. Bloomberg Terminal meets Apple Wallet meets Bentley cockpit.
 */
export default function Dashboard() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const [deposits, setDeposits] = useState([]);
  const [trips, setTrips] = useState([]);

  async function load() {
    try {
      const [s, d, t] = await Promise.all([
        api.get("/tax/summary"),
        api.get("/deposits"),
        api.get("/trips"),
      ]);
      setSummary(s.data); setDeposits(d.data); setTrips(t.data);
    } catch (err) { toast.error(formatApiError(err)); }
  }
  useEffect(() => { load(); }, []);

  const streak = (() => {
    if (!trips || !trips.length) return 0;
    const daySet = new Set(
      trips.map(t => {
        const d = new Date(t.date || t.created_at || 0);
        return d.toDateString();
      })
    );
    let count = 0;
    for (let i = 0; i < 60; i++) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      if (daySet.has(d.toDateString())) count++;
      else if (i > 0) break;
    }
    return count;
  })();

  useEffect(() => {
    if (!summary) return;
    const firstName = user?.name?.split(" ")[0] || "";
    MilliVaultBridge.update({
      balance:   Number(summary?.savings_balance || 0),
      goal:      Number(summary?.tax_goal || 20000),
      thisMonth: Number(summary?.vault_this_month || 0),
      streak,
      firstName,
    }).catch((e) => { console.debug("[Dashboard] widget bridge:", e); });
  }, [summary, streak, user?.name]);

  if (!summary) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
        <MilliLogo size={48} animate={true} />
        <p style={{ color: "#6B7280", fontSize: 14, letterSpacing: "-0.01em" }}>Loading your vault...</p>
      </div>
    );
  }

  const firstName = user?.name?.split(" ")[0] || "there";
  const now = new Date();
  const hour = now.getHours();
  const greeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";

  const availableToSpend =
    Number(summary?.available_to_spend) ||
    Math.max(
      0,
      Number(summary?.gross_income || 0) -
      Number(summary?.year_taxes_reserved || summary?.savings_balance || 0)
    );

  const latestPayout = deposits?.[0] || null;
  const latestGross = Number(latestPayout?.amount || 0);
  const latestTaxes = Math.round(latestGross * 0.15 * 100) / 100;
  const latestVault = Math.round(latestGross * 0.066 * 100) / 100;
  const latestNet = Math.round((latestGross - latestTaxes - latestVault) * 100) / 100;
  const latestDate = latestPayout
    ? new Date(latestPayout.date || latestPayout.created_at)
        .toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" })
    : "—";

  const vaultBalance = Number(summary?.savings_balance || 0);
  const vaultThisMonth = Number(summary?.vault_this_month || latestVault || 0);
  const taxGoal = Number(summary?.tax_goal || 20000);
  const vaultPct = Math.min(100, Math.round((vaultBalance / Math.max(1, taxGoal)) * 100));

  const readyScore = summary?.tax_ready_score
    ? Math.round(Math.min(100, (vaultBalance / Math.max(1, taxGoal * 0.25)) * 100))
    : 0;
  const readyLabel = readyScore >= 85 ? "Excellent"
      : readyScore >= 70 ? "On Track"
      : readyScore >= 40 ? "Building"
      : "Start";

  const milesThisMonth = summary?.mileage?.business_miles || trips.reduce((a, t) => a + Number(t.miles || 0), 0);
  const mileageDeduction = summary?.mileage?.business_deduction || Math.round(milesThisMonth * 0.70 * 100) / 100;

  const retirement = Number(summary?.retirement_balance || 0);
  const invest = Number(summary?.invest_balance || 0);

  return (
    <div
      style={{
        padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px",
        fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif',
        maxWidth: 640,
        margin: "0 auto",
      }}
    >
      {/*=== Greeting ===*/}
      <header style={{ paddingTop: 8, paddingBottom: 4, display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12 }}>
        <div style={{ minWidth: 0 }}>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", lineHeight: 1.15, margin: 0 }} data-testid="dashboard-greeting">
            {greeting}, {firstName}
          </h1>
          <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }} data-testid="dashboard-subgreeting">
            {streak > 1
              ? `You're on a ${streak}-day earning streak.`
              : (deposits?.length ?? 0) > 0
                ? `Here's your money, ${firstName}.`
                : `Welcome to Milli, ${firstName}.`}
          </p>
        </div>
        {streak > 0 && (
          <div
            data-testid="dashboard-streak-pill"
            style={{
              flexShrink: 0, display: "flex", alignItems: "center", gap: 6,
              padding: "6px 12px", borderRadius: 999, marginTop: 4,
              background: "rgba(0,229,255,0.08)",
              border: "1px solid rgba(0,229,255,0.5)",
              boxShadow: "0 0 14px rgba(0,229,255,0.35)",
            }}
          >
            <FlameIcon />
            <span style={{ fontWeight: 700, fontSize: 15, color: "#00E5FF", fontVariantNumeric: "tabular-nums", textShadow: "0 0 6px rgba(0,229,255,0.55)" }}>
              {streak}
            </span>
            <span style={{ color: "#6B7280", fontSize: 10, textTransform: "uppercase", letterSpacing: "0.14em" }}>
              day{streak === 1 ? "" : "s"}
            </span>
          </div>
        )}
      </header>

      <div style={{ height: 20 }} />

      {/*=== 1. Available to Spend — HERO TEAL CARD ===*/}
      <section
        data-testid="dashboard-available-card"
        style={{
          position: "relative", overflow: "hidden", borderRadius: 24, padding: "24px 24px 20px",
          background: "linear-gradient(135deg, rgba(0,180,200,0.22), rgba(0,229,255,0.07) 45%, rgba(5,6,7,0.9))",
          border: "1px solid rgba(0,229,255,0.45)",
          boxShadow: "0 0 32px rgba(0,229,255,0.2), inset 0 1px 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.4)",
        }}
      >
        <div style={{ position: "absolute", top: 20, right: 20, pointerEvents: "none" }}>
          <MilliCardMini user={user} />
        </div>
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.14em", textTransform: "uppercase", marginBottom: 8 }}>
            AVAILABLE TO SPEND
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <Eye size={16} weight="regular" color="rgba(255,255,255,0.5)" />
          </div>
          <div
            data-testid="dashboard-available-amount"
            style={{
              fontSize: 44, fontWeight: 800, color: "#FFFFFF", letterSpacing: "-0.04em",
              fontVariantNumeric: "tabular-nums", lineHeight: 1, marginTop: 8,
              fontFamily: '"Outfit", system-ui, sans-serif',
            }}
          >
            {availableToSpend.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <Link
            to="/app/vault"
            data-testid="dashboard-checking-link"
            style={{ display: "inline-flex", alignItems: "center", gap: 6, color: "rgba(255,255,255,0.6)", fontSize: 13, marginTop: 12, textDecoration: "none" }}
          >
            <span>Milli Checking</span>
            <span style={{ letterSpacing: "0.12em", color: "rgba(255,255,255,0.4)" }} data-testid="dashboard-checking-last4">⌗⌗⌗⌗ {cardMetaFor(user).last4}</span>
            <CaretRight size={12} weight="bold" color="rgba(255,255,255,0.5)" />
          </Link>
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/*=== 1.5 Your Milli Card ===*/}
      <section
        data-testid="dashboard-milli-card-section"
        style={{
          borderRadius: 24, padding: "20px 24px",
          display: "flex", flexDirection: "column", alignItems: "center", gap: 12,
          background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
          border: "1px solid rgba(255,255,255,0.07)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
        }}
      >
        <div style={{ width: "100%", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ color: "rgba(255,255,255,0.85)", fontSize: 15, fontWeight: 600 }}>Your Milli Card</div>
            <div style={{ color: "#4B5563", fontSize: 12, marginTop: 2 }}>
              Tap-to-pay ready · {user?.plan === "elite" ? "Elite metal edition" : user?.plan === "pro" ? "Pro edition" : "Virtual card"}
            </div>
          </div>
          <Link to="/app/more" data-testid="dashboard-card-manage" style={{ color: "#00E5FF", fontSize: 13, fontWeight: 600, textDecoration: "none", textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            Manage
          </Link>
        </div>
        <MilliCardHero user={user} testid="dashboard-milli-card" />
      </section>

      <div style={{ height: 16 }} />

      {/*=== 2. Latest Payout ===*/}
      <Link
        to="/app/income"
        data-testid="dashboard-latest-payout-card"
        style={{
          display: "block", borderRadius: 20, padding: 20, textDecoration: "none",
          background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
          border: "1px solid rgba(255,255,255,0.07)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Latest Payout</h2>
          <CaretRight size={16} weight="bold" color="#4B5563" />
        </div>
        <div style={{ display: "flex", gap: 20 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ color: "#9CA3AF", fontSize: 12 }}>Gross Payout</div>
            <div style={{ fontSize: 26, fontWeight: 700, color: "#fff", fontVariantNumeric: "tabular-nums", marginTop: 4 }}>
              {latestGross.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <div style={{ color: "#4B5563", fontSize: 12, marginTop: 8 }}>{latestDate}</div>
          </div>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
            <BreakdownRow label="Net Payout" value={`$${latestNet.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} />
            <BreakdownRow label="Taxes" value={`−$${latestTaxes.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} />
            <BreakdownRow label="Milli Tax Vault" value={`−$${latestVault.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} cyan />
            <div style={{ borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: 6, marginTop: 2 }}>
              <BreakdownRow label="Total" value={`$${latestGross.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} bold />
            </div>
          </div>
        </div>
      </Link>

      <div style={{ height: 16 }} />

      {/*=== 2.5 Milli Cents ===*/}
      <Link
        to="/app/milli-cents"
        data-testid="dashboard-milli-cents-link"
        style={{
          display: "flex", alignItems: "center", gap: 12, padding: 16, borderRadius: 20, textDecoration: "none",
          background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
          border: "1px solid rgba(0,229,255,0.38)",
          boxShadow: "0 0 24px rgba(0,229,255,0.10), inset 0 1px 0 rgba(255,255,255,0.06)",
        }}
      >
        <div style={{
          width: 44, height: 44, borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center",
          background: "rgba(0,229,255,0.10)", border: "1px solid rgba(0,229,255,0.25)", boxShadow: "0 0 17px rgba(0,229,255,0.11)",
        }}>
          <Gauge size={24} weight="duotone" color="#00E5FF" />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ color: "#00E5FF", fontSize: 11, fontWeight: 600, letterSpacing: "0.12em", textTransform: "uppercase" }}>Milli Cents</div>
          <div style={{ color: "rgba(255,255,255,0.85)", fontSize: 13, fontWeight: 500, marginTop: 2 }}>Analyze live offers before you accept.</div>
        </div>
        <CaretRight size={18} weight="bold" color="#00E5FF" />
      </Link>

      <div style={{ height: 16 }} />

      {/*=== 3. Tax Vault + Ready Score (2-up) ===*/}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        <Link
          to="/app/vault"
          data-testid="dashboard-vault-card"
          style={{
            borderRadius: 20, padding: 16, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "space-between", textDecoration: "none",
            background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
            border: "1px solid rgba(255,255,255,0.07)", boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
            <Bank size={20} weight="regular" color="#00E5FF" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.6))" }} />
            <span style={{ color: "#fff", fontSize: 13, fontWeight: 600 }}>Milli Tax Vault</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: "#fff", fontVariantNumeric: "tabular-nums" }}>
            {vaultBalance.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div style={{ color: "#00E5FF", fontSize: 12, marginTop: 6, textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            +{vaultThisMonth.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} this month
          </div>
          <div style={{ marginTop: 12, display: "flex", alignItems: "center", gap: 8, width: "100%" }}>
            <div style={{ flex: 1, height: 6, borderRadius: 999, background: "rgba(255,255,255,0.06)", overflow: "hidden" }}>
              <div style={{ height: "100%", borderRadius: 999, width: `${vaultPct}%`, background: "linear-gradient(90deg, #00E5FF 0%, #4DE0FF 100%)", boxShadow: "0 0 12px rgba(0,229,255,0.7)", transition: "width 1s ease" }} />
            </div>
            <span style={{ color: "#9CA3AF", fontSize: 11, fontVariantNumeric: "tabular-nums" }}>{vaultPct}%</span>
          </div>
          <div style={{ color: "#4B5563", fontSize: 11, marginTop: 8 }}>
            {now.getFullYear()} Tax Goal: ${taxGoal.toLocaleString("en-US")}
          </div>
        </Link>

        <Link
          to="/app/quarterly"
          data-testid="dashboard-ready-score-card"
          style={{
            borderRadius: 20, padding: 16, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "space-between", textDecoration: "none",
            background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
            border: "1px solid rgba(255,255,255,0.07)", boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
          }}
        >
          <div style={{ width: "100%", color: "#fff", fontSize: 13, fontWeight: 600 }}>Tax Ready Score</div>
          <ReadyRing value={readyScore} label={readyLabel} />
          <div style={{ color: "#4B5563", fontSize: 11 }}>Updated today</div>
        </Link>
      </div>

      <div style={{ height: 16 }} />

      {/*=== 4. Financial Timeline ===*/}
      <section
        data-testid="dashboard-timeline-card"
        style={{
          borderRadius: 20, padding: 20,
          background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
          border: "1px solid rgba(255,255,255,0.07)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Financial Timeline</h2>
          <Link to="/app/income" data-testid="dashboard-timeline-viewall" style={{ color: "#00E5FF", fontSize: 13, fontWeight: 600, textDecoration: "none", textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            View all
          </Link>
        </div>
        <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
          <TimelineRow month="JUN" day="15" icon={Receipt} label="Estimated Tax Payment" amount="$1,240.00" />
          <TimelineRow month="SEP" day="15" icon={FileText} label="Q3 Estimated Tax" amount="$1,310.00" last />
        </ul>
      </section>

      <div style={{ height: 16 }} />

      {/*=== 5. Filing Card ===*/}
      <FilingCard isElite={user?.plan === "elite"} year={now.getFullYear()} />

      <div style={{ height: 16 }} />

      {/*=== 6. Mileage / Retirement / Investing (3-up) ===*/}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
        <MetricTile to="/app/mileage" icon={Gauge} label="Mileage" value={`${Math.round(milesThisMonth).toLocaleString("en-US")} mi`} sub="This month" delta={`+$${mileageDeduction.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} testid="tile-mileage" />
        <MetricTile to="/app/retirement" icon={Plant} label="Retirement" value={`$${Math.round(retirement).toLocaleString("en-US")}`} sub="Total Balance" delta="+7.2%" testid="tile-retirement" />
        <MetricTile to="/app/investing" icon={ChartLineUp} label="Investing" value={`$${Math.round(invest).toLocaleString("en-US")}`} sub="Total Balance" delta="+5.6%" testid="tile-investing" />
      </div>
    </div>
  );
}

/* ============================================================ Sub-components ============================================================ */

function BreakdownRow({ label, value, cyan, bold }) {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <span style={{ color: bold ? "#fff" : "#9CA3AF", fontSize: 13, fontWeight: bold ? 600 : 400 }}>{label}</span>
      <span style={{ fontVariantNumeric: "tabular-nums", fontSize: 13, fontWeight: bold ? 700 : 500, color: cyan ? "#00E5FF" : "#fff", textShadow: cyan ? "0 0 6px rgba(0,229,255,0.4)" : "none" }}>
        {value}
      </span>
    </div>
  );
}

function ReadyRing({ value = 0, label = "Excellent" }) {
  const size = 100;
  const stroke = 7;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const offset = c - (Math.max(0, Math.min(100, value)) / 100) * c;
  return (
    <div style={{ position: "relative", width: size, height: size, filter: "drop-shadow(0 0 16px rgba(0,229,255,0.35))" }}>
      <svg width={size} height={size} style={{ transform: "rotate(-90deg)" }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(0,229,255,0.12)" strokeWidth={stroke} />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#00E5FF" strokeWidth={stroke} strokeLinecap="round" strokeDasharray={c} strokeDashoffset={offset} style={{ transition: "stroke-dashoffset 900ms cubic-bezier(0.16, 1, 0.3, 1)" }} />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: 26, fontWeight: 700, color: "#fff", fontVariantNumeric: "tabular-nums" }}>{Math.round(value)}</div>
        <div style={{ color: "#00E5FF", fontSize: 10, fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.14em", marginTop: 2, textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>{label}</div>
      </div>
    </div>
  );
}

function TimelineRow({ month, day, icon: Icon, label, amount, last }) {
  return (
    <li style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 0", borderBottom: last ? "none" : "1px solid rgba(255,255,255,0.05)" }}>
      <div style={{ width: 44, height: 44, borderRadius: 999, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", flexShrink: 0, border: "1.5px solid rgba(0,229,255,0.55)", background: "rgba(0,229,255,0.05)", boxShadow: "0 0 12px rgba(0,229,255,0.25)" }}>
        <span style={{ color: "#00E5FF", fontSize: 9, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase" }}>{month}</span>
        <span style={{ color: "#fff", fontSize: 13, fontWeight: 700, marginTop: 1 }}>{day}</span>
      </div>
      <div style={{ width: 32, height: 32, borderRadius: 10, background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.08)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
        <Icon size={16} weight="regular" color="rgba(255,255,255,0.6)" />
      </div>
      <div style={{ flex: 1, minWidth: 0, color: "#fff", fontSize: 14, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{label}</div>
      <div style={{ color: "#fff", fontWeight: 600, fontSize: 15, fontVariantNumeric: "tabular-nums", whiteSpace: "nowrap" }}>{amount}</div>
      <CaretRight size={14} weight="bold" color="#4B5563" style={{ flexShrink: 0 }} />
    </li>
  );
}

function MetricTile({ to, icon: Icon, label, value, sub, delta, testid }) {
  return (
    <Link
      to={to}
      data-testid={testid}
      style={{
        borderRadius: 20, padding: 12, display: "flex", flexDirection: "column", justifyContent: "space-between", minHeight: 130, textDecoration: "none",
        background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
        border: "1px solid rgba(255,255,255,0.07)",
        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <Icon size={16} weight="regular" color="#00E5FF" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.5))" }} />
        <span style={{ color: "#9CA3AF", fontSize: 11, fontWeight: 600 }}>{label}</span>
      </div>
      <div>
        <div style={{ fontSize: 17, fontWeight: 700, color: "#fff", fontVariantNumeric: "tabular-nums", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{value}</div>
        <div style={{ color: "#4B5563", fontSize: 10, marginTop: 2 }}>{sub}</div>
      </div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <span style={{ color: "#00E5FF", fontSize: 12, fontWeight: 600, textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>{delta}</span>
        <CaretRight size={12} weight="bold" color="#4B5563" />
      </div>
    </Link>
  );
}

function FlameIcon() {
  return (
    <svg width="12" height="14" viewBox="0 0 12 14" fill="none" style={{ filter: "drop-shadow(0 0 4px rgba(0,229,255,0.7))" }}>
      <path d="M6 1 C4 3 3 5 3 7 C3 9.5 4.5 12 6 12 C7.5 12 9 9.5 9 7 C9 5.5 8 4 7 3 C7 4 6.5 4.5 6 4.5 C5.5 4.5 5 4 6 1 Z" fill="#00E5FF" stroke="#7BF3FF" strokeWidth="0.4" />
    </svg>
  );
}

function FilingCard({ isElite, year }) {
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);

  async function openPreview() {
    if (!isElite) return;
    setLoading(true);
    try {
      const token = localStorage.getItem("milli_token");
      const base = process.env.REACT_APP_BACKEND_URL || "";
      const res = await fetch(`${base}/api/reports/schedule-c-pdf`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error(`Server returned ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      setPreview({ url, blob });
    } catch (e) {
      toast.error(`Could not build PDF: ${e.message}`);
    } finally { setLoading(false); }
  }

  function downloadFromPreview() {
    if (!preview) return;
    const a = document.createElement("a");
    a.href = preview.url;
    a.download = `milli-schedule-c-${year}.pdf`;
    document.body.appendChild(a); a.click(); a.remove();
    toast.success("Downloaded — check your Downloads");
  }

  function closePreview() {
    if (preview?.url) URL.revokeObjectURL(preview.url);
    setPreview(null);
  }

  if (!isElite) {
    return (
      <Link
        to="/app/pricing"
        data-testid="dashboard-filing-card"
        style={{
          display: "block", borderRadius: 20, padding: 20, textDecoration: "none",
          background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
          border: "1px solid rgba(255,255,255,0.07)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ width: 44, height: 44, borderRadius: 16, border: "1px solid rgba(0,229,255,0.5)", background: "rgba(0,229,255,0.06)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 14px rgba(0,229,255,0.3)", flexShrink: 0 }}>
            <ShieldCheck size={22} weight="duotone" color="#00E5FF" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ color: "#00E5FF", fontSize: 10, fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase", textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>Federal + State Filing</div>
            <div style={{ color: "#fff", fontSize: 18, fontWeight: 700, marginTop: 4 }}>Upgrade to Elite</div>
            <div style={{ color: "#9CA3AF", fontSize: 12, marginTop: 2 }}>Elite unlocks the IRS-Ready Schedule C + SE PDF.</div>
          </div>
          <EliteBadge size={54} />
        </div>
      </Link>
    );
  }

  return (
    <>
      <button
        onClick={openPreview}
        disabled={loading}
        data-testid="dashboard-filing-card"
        style={{
          width: "100%", textAlign: "left", borderRadius: 20, padding: 20, cursor: "pointer",
          background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))",
          border: "1px solid rgba(0,229,255,0.35)",
          boxShadow: "0 0 18px rgba(0,229,255,0.22), inset 0 1px 0 rgba(255,255,255,0.06)",
          opacity: loading ? 0.7 : 1,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ width: 44, height: 44, borderRadius: 16, border: "1px solid rgba(0,229,255,0.5)", background: "rgba(0,229,255,0.06)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 14px rgba(0,229,255,0.35)", flexShrink: 0 }}>
            <ShieldCheck size={22} weight="duotone" color="#00E5FF" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ color: "#00E5FF", fontSize: 10, fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase", textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>IRS-Ready · Schedule C + SE</div>
            <div style={{ color: "#fff", fontSize: 18, fontWeight: 700, marginTop: 4 }}>{loading ? "Building your PDF…" : "Preview Filing PDF"}</div>
            <div style={{ color: "#9CA3AF", fontSize: 12, marginTop: 2 }}>Review before downloading.</div>
          </div>
          <EliteBadge size={54} />
        </div>
      </button>

      {preview && (
        <div onClick={closePreview} data-testid="pdf-preview-modal" style={{ position: "fixed", inset: 0, zIndex: 50, background: "rgba(0,0,0,0.85)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", padding: 12 }}>
          <div onClick={(e) => e.stopPropagation()} style={{ position: "relative", width: "100%", maxWidth: 720, borderRadius: 24, overflow: "hidden", display: "flex", flexDirection: "column", background: "linear-gradient(180deg, rgba(15,18,22,0.98), rgba(5,7,10,0.98))", border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 40px rgba(0,229,255,0.25), 0 30px 80px rgba(0,0,0,0.7)", maxHeight: "92vh" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 16px", borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <ShieldCheck size={18} weight="duotone" color="#00E5FF" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.6))" }} />
                <div style={{ color: "#fff", fontWeight: 600, fontSize: 14 }}>Schedule C + SE · {year}</div>
              </div>
              <button onClick={closePreview} data-testid="pdf-preview-close" style={{ width: 36, height: 36, borderRadius: 999, background: "rgba(255,255,255,0.06)", display: "flex", alignItems: "center", justifyContent: "center", border: "none", cursor: "pointer" }}>
                <span style={{ color: "#fff", fontSize: 18 }}>✕</span>
              </button>
            </div>
            <div style={{ flex: 1, minHeight: 0, background: "#f1f1f1" }}>
              <iframe title="Schedule C Preview" src={preview.url} style={{ width: "100%", height: "100%", minHeight: "60vh", border: 0 }} data-testid="pdf-preview-iframe" />
            </div>
            <div style={{ display: "flex", gap: 8, padding: "12px 16px", borderTop: "1px solid rgba(255,255,255,0.06)" }}>
              <button onClick={closePreview} style={{ flex: 1, borderRadius: 16, padding: "12px 0", color: "rgba(255,255,255,0.7)", fontSize: 13, fontWeight: 600, border: "1px solid rgba(255,255,255,0.1)", background: "transparent", cursor: "pointer" }}>Close</button>
              <button onClick={downloadFromPreview} data-testid="pdf-preview-download" style={{ flex: 1, borderRadius: 16, padding: "12px 0", fontWeight: 700, fontSize: 13, color: "#000", background: "linear-gradient(180deg, #00E5FF, #00B4D0)", boxShadow: "0 0 20px rgba(0,229,255,0.5), inset 0 1px 0 rgba(255,255,255,0.5)", border: "none", cursor: "pointer" }}>Download PDF</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
