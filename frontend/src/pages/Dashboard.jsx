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

/**
 * Milli Tax Vault — Dashboard.
 * Matches the "Good morning, Alex" reference mockup exactly:
 *   1. Greeting
 *   2. Available to Spend hero (cyan glow + metallic M card graphic)
 *   3. Latest Payout (2-column breakdown)
 *   4. Milli Tax Vault™ | Tax Ready Score™ (side-by-side)
 *   5. Financial Timeline
 *   6. Mileage · Retirement · Investing (3-up tiles)
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

  if (!summary) {
    return (
      <div className="p-12 font-mono text-volt animate-pulse text-center">
        [ LOADING MILLI... ]
      </div>
    );
  }

  const firstName = user?.name?.split(" ")[0] || "there";
  const now = new Date();
  const hour = now.getHours();
  const greeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";

  // Compute a driving-day streak from `trips` — consecutive days working back from today.
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

  // Available to spend = gross - reserved (fallback logic if fields missing)
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

  // Tax Ready Score (Excellent ≥85, On Track ≥70, ...)
  const readyScore = summary?.tax_ready_score
    ?? Math.round(Math.min(100, (vaultBalance / Math.max(1, taxGoal * 0.25)) * 100));
  const readyLabel = readyScore >= 85 ? "Excellent"
                   : readyScore >= 70 ? "On Track"
                   : readyScore >= 40 ? "Building"
                   : "Start";

  // Mileage
  const milesThisMonth = summary?.mileage?.business_miles || trips.reduce((a, t) => a + Number(t.miles || 0), 0);
  const mileageDeduction = summary?.mileage?.business_deduction || Math.round(milesThisMonth * 0.70 * 100) / 100;

  // Wealth
  const retirement = Number(summary?.retirement_balance || 0);
  const invest = Number(summary?.invest_balance || 0);

  return (
    <div className="px-5 sm:px-6 lg:px-10 pt-4 pb-6 max-w-2xl mx-auto space-y-5">

      {/* ===== Greeting ===== */}
      <header className="pt-2 pb-1 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h1
            className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight"
            data-testid="dashboard-greeting"
          >
            {greeting}, {firstName}
          </h1>
          <p className="text-zinc-400 text-[15px] mt-1">Here&apos;s your financial overview</p>
        </div>
        {streak > 0 && (
          <div
            data-testid="dashboard-streak-pill"
            className="flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full mt-1"
            style={{
              background: "rgba(0,229,255,0.08)",
              border: "1px solid rgba(0,229,255,0.5)",
              boxShadow: "0 0 14px rgba(0,229,255,0.35)",
            }}
            title={`${streak}-day driving streak · earning Milli Cents boost`}
          >
            <FlameIcon />
            <span
              className="font-chrome font-bold text-[15px] tabular-nums text-volt leading-none"
              style={{ textShadow: "0 0 6px rgba(0,229,255,0.55)" }}
            >
              {streak}
            </span>
            <span className="text-zinc-400 text-[10px] uppercase tracking-widest leading-none">
              day{streak === 1 ? "" : "s"}
            </span>
          </div>
        )}
      </header>

      {/* ===== 1 · Available to Spend Hero ===== */}
      <section
        className="relative overflow-hidden rounded-3xl p-5 sm:p-6"
        data-testid="dashboard-available-card"
        style={{
          background:
            "linear-gradient(135deg, rgba(0,180,200,0.30) 0%, rgba(0,229,255,0.10) 35%, rgba(10,14,18,0.85) 70%, rgba(10,14,18,0.95) 100%)",
          border: "1px solid rgba(0,229,255,0.55)",
          boxShadow:
            "inset 0 1px 0 rgba(255,255,255,0.10), 0 0 28px rgba(0,229,255,0.35), 0 0 60px rgba(0,229,255,0.15), 0 18px 44px rgba(0,0,0,0.55)",
        }}
      >
        {/* Metallic M card floated in the top-right corner so the amount has full width */}
        <div className="absolute top-4 right-4 sm:top-5 sm:right-5 pointer-events-none">
          <MetallicMCard />
        </div>
        <div className="relative z-10 min-w-0">
          <div className="flex items-center gap-2 text-white/80 text-[14px] font-medium">
            <span>Available to Spend</span>
            <Eye size={16} weight="regular" className="text-white/60" />
          </div>
          <div
            className="font-chrome font-black text-white tabular-nums leading-[1] tracking-tight mt-3 text-[36px] sm:text-[44px]"
            data-testid="dashboard-available-amount"
          >
            ${availableToSpend.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <Link
            to="/app/vault"
            className="mt-3 inline-flex items-center gap-1.5 text-white/70 text-[13px] active:opacity-70"
            data-testid="dashboard-checking-link"
          >
            <span>Milli Checking</span>
            <span className="tracking-widest text-white/50">•••• 4587</span>
            <CaretRight size={12} weight="bold" className="text-white/60" />
          </Link>
        </div>
      </section>

      {/* ===== 2 · Latest Payout ===== */}
      <Link
        to="/app/income"
        className="milli-card block p-5 rounded-2xl active:scale-[0.995] transition-transform"
        data-testid="dashboard-latest-payout-card"
      >
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-white font-semibold text-[17px]">Latest Payout</h2>
          <CaretRight size={16} weight="bold" className="text-zinc-500" />
        </div>
        <div className="flex gap-5">
          {/* Left */}
          <div className="flex-1 min-w-0">
            <div className="text-zinc-400 text-[12.5px]">Gross Payout</div>
            <div className="chrome-text font-chrome font-bold text-[26px] leading-tight mt-1 tabular-nums">
              ${latestGross.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <div className="text-zinc-500 text-[12.5px] mt-2">{latestDate}</div>
          </div>
          {/* Right */}
          <div className="flex-1 min-w-0 text-[13.5px] space-y-1.5">
            <BreakdownRow label="Net Payout" value={`$${latestNet.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} />
            <BreakdownRow label="Taxes" value={`−$${latestTaxes.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} />
            <BreakdownRow label={<>Milli Tax Vault<sup>™</sup></>} value={`−$${latestVault.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} cyan />
            <div className="border-t border-white/10 pt-1.5 mt-1.5">
              <BreakdownRow label="Total" value={`$${latestGross.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} bold />
            </div>
          </div>
        </div>
      </Link>

      {/* ===== 3 · Tax Vault + Ready Score (2-up) ===== */}
      <div className="grid grid-cols-2 gap-3">
        {/* Tax Vault */}
        <Link
          to="/app/vault"
          data-testid="dashboard-vault-card"
          className="milli-card p-4 rounded-2xl flex flex-col active:scale-[0.995] transition-transform"
        >
          <div className="flex items-center gap-2 mb-2">
            <Bank size={20} weight="regular" className="text-volt" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.6))" }} />
            <span className="text-white text-[13.5px] font-semibold leading-none">Milli Tax Vault<sup>™</sup></span>
          </div>
          <div className="chrome-text font-chrome font-bold text-[24px] leading-none tabular-nums mt-1">
            ${vaultBalance.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="text-volt text-[12px] mt-1.5" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            +${vaultThisMonth.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} this month
          </div>
          {/* progress */}
          <div className="mt-3 flex items-center gap-2">
            <div className="flex-1 h-1.5 rounded-full bg-white/[0.08] overflow-hidden">
              <div
                className="h-full rounded-full"
                style={{
                  width: `${vaultPct}%`,
                  background: "linear-gradient(90deg, #00E5FF 0%, #4DE0FF 100%)",
                  boxShadow: "0 0 12px rgba(0,229,255,0.7)",
                }}
              />
            </div>
            <span className="text-zinc-400 text-[11px] tabular-nums">{vaultPct}%</span>
          </div>
          <div className="text-zinc-500 text-[11.5px] mt-2">
            {now.getFullYear()} Tax Goal: ${taxGoal.toLocaleString("en-US")}
          </div>
        </Link>

        {/* Tax Ready Score */}
        <Link
          to="/app/quarterly"
          data-testid="dashboard-ready-score-card"
          className="milli-card p-4 rounded-2xl flex flex-col items-center justify-between active:scale-[0.995] transition-transform"
        >
          <div className="w-full text-white text-[13.5px] font-semibold">Tax Ready Score<sup>™</sup></div>
          <ReadyRing value={readyScore} label={readyLabel} />
          <div className="text-zinc-500 text-[11.5px]">Updated today</div>
        </Link>
      </div>

      {/* ===== 4 · Financial Timeline ===== */}
      <section className="milli-card p-5 rounded-2xl" data-testid="dashboard-timeline-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[16px]">Financial Timeline</h2>
          <Link
            to="/app/income"
            className="text-volt text-[13.5px] font-semibold active:opacity-70"
            style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}
            data-testid="dashboard-timeline-viewall"
          >
            View all
          </Link>
        </div>
        <ul className="space-y-2">
          <TimelineRow
            month="JUN" day="15"
            icon={Receipt}
            label="Estimated Tax Payment"
            amount="$1,240.00"
          />
          <TimelineRow
            month="SEP" day="15"
            icon={FileText}
            label="Q3 Estimated Tax"
            amount="$1,310.00"
            last
          />
        </ul>
      </section>

      {/* ===== 5 · Federal + State Filing (Elite: download IRS-ready PDF) ===== */}
      <FilingCard isElite={user?.plan === "elite"} year={now.getFullYear()} />

      {/* ===== 6 · Mileage · Retirement · Investing (3-up) ===== */}
      <div className="grid grid-cols-3 gap-2.5">
        <MetricTile
          to="/app/mileage"
          icon={Gauge}
          label="Mileage"
          value={`${Math.round(milesThisMonth).toLocaleString("en-US")} mi`}
          sub="This month"
          delta={`+$${mileageDeduction.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
          testid="tile-mileage"
        />
        <MetricTile
          to="/app/retirement"
          icon={Plant}
          label="Retirement"
          value={`$${Math.round(retirement).toLocaleString("en-US")}`}
          sub="Total Balance"
          delta="+7.2%"
          testid="tile-retirement"
        />
        <MetricTile
          to="/app/investing"
          icon={ChartLineUp}
          label="Investing"
          value={`$${Math.round(invest).toLocaleString("en-US")}`}
          sub="Total Balance"
          delta="+5.6%"
          testid="tile-investing"
        />
      </div>
    </div>
  );
}

/* =================================================================
   Sub-components
   ================================================================= */

function BreakdownRow({ label, value, cyan, bold }) {
  return (
    <div className="flex items-center justify-between">
      <span className={`text-zinc-400 ${bold ? "font-semibold text-white" : ""}`}>{label}</span>
      <span
        className={`tabular-nums ${bold ? "font-bold text-white" : "text-white"} ${
          cyan ? "text-volt" : ""
        }`}
        style={cyan ? { color: "#00E5FF", textShadow: "0 0 6px rgba(0,229,255,0.4)" } : {}}
      >
        {value}
      </span>
    </div>
  );
}

/* Small circular Tax Ready Score ring (fits inside the 2-up card) */
function ReadyRing({ value = 0, label = "Excellent" }) {
  const size = 100;
  const stroke = 7;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const offset = c - (Math.max(0, Math.min(100, value)) / 100) * c;
  return (
    <div
      className="relative"
      style={{ width: size, height: size, filter: "drop-shadow(0 0 16px rgba(0,229,255,0.35))" }}
    >
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(0,229,255,0.15)" strokeWidth={stroke} />
        <circle
          cx={size/2} cy={size/2} r={r}
          fill="none" stroke="#00E5FF" strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={offset}
          style={{ transition: "stroke-dashoffset 900ms cubic-bezier(0.16, 1, 0.3, 1)" }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="chrome-text font-chrome font-bold text-[26px] leading-none tabular-nums">{Math.round(value)}</div>
        <div className="text-volt text-[10px] font-semibold uppercase tracking-widest mt-0.5"
             style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
          {label}
        </div>
      </div>
    </div>
  );
}

function TimelineRow({ month, day, icon: Icon, label, amount, last }) {
  return (
    <li>
      <div className={`flex items-center gap-3 py-2.5 ${last ? "" : "border-b border-white/[0.05]"}`}>
        {/* date circle */}
        <div
          className="w-11 h-11 rounded-full flex flex-col items-center justify-center flex-shrink-0"
          style={{
            border: "1.5px solid rgba(0,229,255,0.55)",
            background: "rgba(0,229,255,0.05)",
            boxShadow: "0 0 12px rgba(0,229,255,0.25)",
          }}
        >
          <span className="text-volt text-[9px] font-bold tracking-wider leading-none uppercase">{month}</span>
          <span className="text-white text-[13px] font-bold leading-none mt-0.5">{day}</span>
        </div>
        <div className="w-8 h-8 rounded-lg bg-white/[0.04] border border-white/10 flex items-center justify-center flex-shrink-0">
          <Icon size={16} weight="regular" className="text-white/70" />
        </div>
        <div className="flex-1 min-w-0 text-white text-[14.5px] truncate">{label}</div>
        <div className="text-white font-semibold text-[15px] tabular-nums whitespace-nowrap">{amount}</div>
        <CaretRight size={14} weight="bold" className="text-zinc-600 flex-shrink-0" />
      </div>
    </li>
  );
}

function MetricTile({ to, icon: Icon, label, value, sub, delta, testid }) {
  return (
    <Link
      to={to}
      data-testid={testid}
      className="milli-card p-3 rounded-2xl flex flex-col justify-between min-h-[130px] active:scale-[0.98] transition-transform"
    >
      <div className="flex items-center gap-1.5">
        <Icon size={16} weight="regular" className="text-volt" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.5))" }} />
        <span className="text-zinc-300 text-[11.5px] font-semibold">{label}</span>
      </div>
      <div>
        <div className="chrome-text font-chrome font-bold text-[17px] leading-tight tabular-nums truncate">
          {value}
        </div>
        <div className="text-zinc-500 text-[10.5px] mt-0.5">{sub}</div>
      </div>
      <div className="flex items-center justify-between">
        <span className="text-volt text-[12px] font-semibold" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
          {delta}
        </span>
        <CaretRight size={12} weight="bold" className="text-zinc-500" />
      </div>
    </Link>
  );
}

/* Small cyan flame for streak pill */
function FlameIcon() {
  return (
    <svg width="12" height="14" viewBox="0 0 12 14" fill="none"
         style={{ filter: "drop-shadow(0 0 4px rgba(0,229,255,0.7))" }}>
      <path d="M6 1 C4 3 3 5 3 7 C3 9.5 4.5 12 6 12 C7.5 12 9 9.5 9 7 C9 5.5 8 4 7 3 C7 4 6.5 4.5 6 4.5 C5.5 4.5 5 4 6 1 Z"
            fill="#00E5FF" stroke="#7BF3FF" strokeWidth="0.4" />
    </svg>
  );
}

/* Metallic M card graphic (right side of the "Available to Spend" hero) */
function MetallicMCard() {
  return (
    <div
      className="relative w-[88px] h-[56px] sm:w-[104px] sm:h-[64px] flex-shrink-0 rounded-lg overflow-hidden"
      aria-hidden
      style={{
        background:
          "linear-gradient(135deg, #E4E7EA 0%, #A8ADB4 20%, #4B4F55 50%, #1E2126 80%, #0A0C10 100%)",
        boxShadow:
          "inset 0 1px 0 rgba(255,255,255,0.55), inset 0 -6px 12px rgba(0,0,0,0.5), 0 6px 14px rgba(0,0,0,0.55)",
        transform: "rotate(-8deg)",
      }}
    >
      {/* diagonal highlight */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(120deg, transparent 30%, rgba(255,255,255,0.28) 45%, transparent 60%)",
        }}
      />
      {/* chip */}
      <div
        className="absolute top-2 left-2 w-5 h-3.5 rounded-sm"
        style={{
          background: "linear-gradient(180deg, #C8B970 0%, #8A7A3E 100%)",
          boxShadow: "inset 0 0 2px rgba(0,0,0,0.6)",
        }}
      />
      {/* Big M */}
      <div
        className="absolute inset-0 flex items-center justify-end pr-2.5"
        style={{
          fontFamily: "'Sora','Inter',sans-serif",
          fontWeight: 900,
          fontSize: 32,
          background: "linear-gradient(180deg, #FFFFFF 0%, #D0D3D8 40%, #6E7379 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          filter: "drop-shadow(0 1px 0 rgba(0,0,0,0.5))",
        }}
      >
        M
      </div>
    </div>
  );
}


/* ===================== Filing Card (Elite Schedule C download) ===================== */
function FilingCard({ isElite, year }) {
  const [preview, setPreview] = useState(null);   // { url, blob } while previewing
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
        className="milli-card rounded-2xl p-5 block active:scale-[0.995] transition-transform"
      >
        <div className="flex items-center gap-4">
          <div className="flex-shrink-0 w-11 h-11 rounded-2xl border border-volt/50 bg-volt/[0.06] flex items-center justify-center"
               style={{ boxShadow: "0 0 14px rgba(0,229,255,0.3)" }}>
            <ShieldCheck size={22} weight="duotone" className="text-volt" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="font-mono text-[10.5px] uppercase tracking-[0.28em] text-volt"
                 style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
              Federal + State Filing
            </div>
            <div className="chrome-text font-chrome font-bold text-[18px] leading-tight mt-1">
              Upgrade to Elite
            </div>
            <div className="text-zinc-400 text-[12px] mt-0.5">
              Elite unlocks the IRS-Ready Schedule C + SE PDF preview.
            </div>
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
        className="milli-card rounded-2xl p-5 w-full text-left active:scale-[0.995] transition-transform disabled:opacity-70"
        style={{ border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 18px rgba(0,229,255,0.22)" }}
      >
        <div className="flex items-center gap-4">
          <div className="flex-shrink-0 w-11 h-11 rounded-2xl border border-volt/50 bg-volt/[0.06] flex items-center justify-center"
               style={{ boxShadow: "0 0 14px rgba(0,229,255,0.35)" }}>
            <ShieldCheck size={22} weight="duotone" className="text-volt" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="font-mono text-[10.5px] uppercase tracking-[0.28em] text-volt"
                 style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
              IRS-Ready · Schedule C + SE
            </div>
            <div className="chrome-text font-chrome font-bold text-[18px] leading-tight mt-1">
              {loading ? "Building your PDF…" : "Preview Filing PDF"}
            </div>
            <div className="text-zinc-400 text-[12px] mt-0.5">
              Review before downloading. Attach in FreeTaxUSA / TurboTax or hand to your CPA.
            </div>
          </div>
          <EliteBadge size={54} />
        </div>
      </button>

      {preview && (
        <div
          className="fixed inset-0 z-50 bg-black/85 backdrop-blur-sm flex items-center justify-center p-3 sm:p-6"
          onClick={closePreview}
          data-testid="pdf-preview-modal"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="relative w-full max-w-3xl rounded-3xl overflow-hidden flex flex-col"
            style={{
              background: "linear-gradient(180deg, rgba(15,18,22,0.98) 0%, rgba(5,7,10,0.98) 100%)",
              border: "1px solid rgba(0,229,255,0.35)",
              boxShadow: "0 0 40px rgba(0,229,255,0.25), 0 30px 80px rgba(0,0,0,0.7)",
              maxHeight: "92vh",
            }}
          >
            <div className="flex items-center justify-between px-4 py-3 border-b border-white/[0.06]">
              <div className="flex items-center gap-2">
                <ShieldCheck size={18} weight="duotone" className="text-volt"
                             style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.6))" }} />
                <div className="text-white font-semibold text-[14.5px]">Schedule C + SE — {year}</div>
              </div>
              <button
                onClick={closePreview}
                data-testid="pdf-preview-close"
                className="w-9 h-9 rounded-full bg-white/[0.06] flex items-center justify-center active:opacity-60"
                aria-label="Close"
              >
                <span className="text-white text-[18px] leading-none">×</span>
              </button>
            </div>
            <div className="flex-1 min-h-0 bg-zinc-100">
              <iframe
                title="Schedule C Preview"
                src={preview.url}
                className="w-full h-full"
                style={{ minHeight: "60vh", border: "0" }}
                data-testid="pdf-preview-iframe"
              />
            </div>
            <div className="flex gap-2 px-4 py-3 border-t border-white/[0.06]">
              <button
                onClick={closePreview}
                className="flex-1 rounded-xl py-3 text-white/80 text-[13px] font-semibold border border-white/10 active:opacity-70"
              >
                Close
              </button>
              <button
                onClick={downloadFromPreview}
                data-testid="pdf-preview-download"
                className="flex-1 rounded-xl py-3 font-bold text-[13px] text-obsidian active:brightness-95"
                style={{
                  background: "linear-gradient(180deg, #00E5FF 0%, #00B4D0 100%)",
                  boxShadow: "0 0 20px rgba(0,229,255,0.5), inset 0 1px 0 rgba(255,255,255,0.5)",
                }}
              >
                Download PDF
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
