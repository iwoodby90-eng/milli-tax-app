import { useEffect, useState } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  Bank, MapTrifold, CalendarCheck, ShieldCheck, CheckCircle, CaretRight,
  Star, Coins, Robot, ArrowUpRight, FileText, Shield, Car, ChartLineUp,
  Vault as VaultIcon,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import {
  TaxReadyGauge, FinancialTimeline, TaxVaultCard,
  InsightRow, EliteBadge,
} from "@/components/MilliPrimitives";

export default function Dashboard() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const [deposits, setDeposits] = useState([]);
  const [trips, setTrips] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [syncing, setSyncing] = useState(false);

  async function load() {
    try {
      const [s, d, t, e] = await Promise.all([
        api.get("/tax/summary"),
        api.get("/deposits"),
        api.get("/trips"),
        api.get("/expenses"),
      ]);
      setSummary(s.data); setDeposits(d.data); setTrips(t.data); setExpenses(e.data);
    } catch (err) { toast.error(formatApiError(err)); }
  }

  useEffect(() => { load(); }, []);

  async function syncPlaid() {
    setSyncing(true);
    try {
      const { data } = await api.post("/plaid/sync");
      toast.success(`Synced ${data.synced} new deposits`);
      await load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setSyncing(false); }
  }

  if (!summary) {
    return <div className="p-12 font-mono text-volt animate-pulse">[ LOADING MILLI... ]</div>;
  }

  // Tax-ready score: 4 boxes — Income, Mileage, Expenses, Quarterly est available
  const checks = {
    income: deposits.length > 0,
    mileage: trips.length > 0,
    expenses: expenses.length > 0,
    quarterly: summary.estimated_tax > 0,
  };
  const filled = Object.values(checks).filter(Boolean).length;
  const score = Math.round((filled / 4) * 100);
  const isElite = user?.plan === "elite";

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-5xl mx-auto">
      {/* Tab widget grid — one card per bottom-nav tab */}
      <div className="grid grid-cols-2 gap-3 mb-6">
        <Link to="/app/vault" data-testid="widget-vault"
              className="milli-card p-4 flex flex-col justify-between min-h-[112px] active:scale-[0.98] transition"
              style={{ background: "radial-gradient(120% 80% at 0% 0%, rgba(0,229,255,0.10), rgba(0,0,0,0) 60%), #06080B" }}>
          <div className="flex items-center gap-1.5 text-volt font-mono text-[10px] uppercase tracking-[0.24em]"><VaultIcon size={12} weight="fill" /> Vault</div>
          <div>
            <div className="font-chrome text-3xl chrome-text tabular-nums leading-none">{money(summary.year_taxes_reserved || 0)}</div>
            <div className="text-[11px] text-zinc-500 uppercase tracking-widest mt-1">Reserved YTD</div>
          </div>
        </Link>
        <Link to="/app/wealth" data-testid="widget-wealth"
              className="milli-card p-4 flex flex-col justify-between min-h-[112px] active:scale-[0.98] transition"
              style={{ background: "radial-gradient(120% 80% at 100% 0%, rgba(0,229,255,0.10), rgba(0,0,0,0) 60%), #06080B" }}>
          <div className="flex items-center gap-1.5 text-volt font-mono text-[10px] uppercase tracking-[0.24em]"><ChartLineUp size={12} weight="fill" /> Wealth</div>
          <div>
            <div className="font-chrome text-3xl chrome-text tabular-nums leading-none">{money((summary.retirement_balance || 0) + (summary.invest_balance || 0))}</div>
            <div className="text-[11px] text-zinc-500 uppercase tracking-widest mt-1">401k + Invest</div>
          </div>
        </Link>
        <Link to="/app/mileage" data-testid="widget-mileage"
              className="milli-card p-4 flex flex-col justify-between min-h-[112px] active:scale-[0.98] transition"
              style={{ background: "radial-gradient(120% 80% at 0% 100%, rgba(0,229,255,0.10), rgba(0,0,0,0) 60%), #06080B" }}>
          <div className="flex items-center gap-1.5 text-volt font-mono text-[10px] uppercase tracking-[0.24em]"><MapTrifold size={12} weight="fill" /> Mileage</div>
          <div>
            <div className="font-chrome text-3xl chrome-text tabular-nums leading-none">{money(summary.mileage_deduction || 0)}</div>
            <div className="text-[11px] text-zinc-500 uppercase tracking-widest mt-1">Deduction YTD</div>
          </div>
        </Link>
        <Link to="/app/milli-cents" data-testid="widget-cents"
              className="milli-card p-4 flex flex-col justify-between min-h-[112px] active:scale-[0.98] transition border-volt/40"
              style={{ background: "radial-gradient(120% 80% at 100% 100%, rgba(0,229,255,0.16), rgba(0,0,0,0) 60%), #06080B",
                       boxShadow: "0 0 24px rgba(0,229,255,0.15)" }}>
          <div className="flex items-center gap-1.5 text-volt font-mono text-[10px] uppercase tracking-[0.24em]"><Coins size={12} weight="fill" /> Milli Cents</div>
          <div>
            <div className="font-chrome text-lg text-white tabular-nums leading-none">Live Offer</div>
            <div className="text-[11px] text-volt uppercase tracking-widest mt-1">Analyze now →</div>
          </div>
        </Link>
      </div>

      {/* Desktop header */}
      <div className="hidden lg:flex items-end justify-between flex-wrap gap-4 mb-8">
        <div className="flex items-center gap-4">
          <MilliLogo size={48} />
          <div>
            <div className="font-display chrome-text text-3xl tracking-[0.2em]">MILLI</div>
            <div className="text-zinc-500 text-xs font-mono uppercase tracking-widest mt-1">// tax year {summary.year}</div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <Link
            to="/app/pricing"
            data-testid="dashboard-plan-badge"
            className="btn-outline-cyan px-4 py-2 text-xs font-semibold inline-flex items-center gap-1.5"
          >
            <Star size={14} weight="fill" /> {(user?.plan || "trial").toUpperCase()}
          </Link>
          <button
            onClick={syncPlaid}
            disabled={syncing}
            data-testid="dashboard-sync-deposits"
            className="btn-volt px-4 py-2 text-xs font-bold uppercase tracking-wider disabled:opacity-50"
          >{syncing ? "Syncing..." : "Sync"}</button>
        </div>
      </div>

      {/* Mobile/center title */}
      <div className="lg:hidden text-center mb-6 mt-2">
        <div className="text-xs text-zinc-500 font-mono uppercase tracking-[0.3em]">Welcome back, {user?.name?.split(" ")[0]}</div>
      </div>

      {/* Quarterly Payment Hero Card */}
      <div className="milli-card p-6 mb-4 relative overflow-hidden" data-testid="dashboard-quarterly-card">
        <div className="flex items-center gap-2 mb-3">
          <CalendarCheck size={18} weight="duotone" className="text-volt" />
          <span className="font-semibold text-sm uppercase tracking-[0.18em] text-volt">Next Quarterly Payment</span>
        </div>
        <div className="flex items-end gap-4 flex-wrap">
          <div className="flex-1 min-w-0">
            <div className="chrome-text font-chrome font-bold text-5xl sm:text-6xl tracking-tight" data-testid="dashboard-quarterly-amount">
              {money(summary.next_quarterly.amount).split(".")[0]}
              <span className="text-3xl text-zinc-400">.{money(summary.next_quarterly.amount).split(".")[1] || "00"}</span>
            </div>
            <div className="text-zinc-300 text-sm font-medium mt-2 font-mono">
              {summary.next_quarterly.label} {summary.year} · Due {new Date(summary.next_quarterly.due_date).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
            </div>
            <div className="text-zinc-500 text-sm mt-1">Estimated & ready to pay.</div>
          </div>
          {/* Decorative calendar mark */}
          <div className="relative w-24 h-24 rounded-2xl border border-volt/30 bg-obsidian/60 flex items-center justify-center flex-shrink-0">
            <CheckCircle size={48} weight="duotone" className="text-volt" />
            <div className="absolute -top-2 left-3 right-3 h-1.5 bg-zinc-700 rounded-full" />
            <div className="absolute -top-1 left-5 w-1.5 h-3 bg-zinc-600 rounded" />
            <div className="absolute -top-1 right-5 w-1.5 h-3 bg-zinc-600 rounded" />
          </div>
        </div>
      </div>

      {/* Tax Ready Score — new gauge primitive */}
      <div className="milli-card p-6 mb-4 flex flex-col lg:flex-row items-center gap-8"
            data-testid="dashboard-tax-score-card">
        <TaxReadyGauge score={score} />
        <div className="flex-1 min-w-0 text-center lg:text-left">
          <div className="text-volt text-sm font-semibold uppercase tracking-[0.24em] mb-3">
            // Tax Ready Score™
          </div>
          <div className="text-zinc-300 text-base leading-snug max-w-md mx-auto lg:mx-0">
            {score >= 75
              ? "You're in great shape. Milli has protected enough to cover the next quarterly estimate."
              : score >= 40
              ? "Halfway there — every payout brings you closer. Log a few more items to close the gap."
              : "Let's get rolling. Connect your bank and take a first trip to start the score."}
          </div>
          {isElite && (
            <div className="mt-4 flex justify-center lg:justify-start">
              <EliteBadge size={72} />
            </div>
          )}
        </div>
      </div>

      {/* Insight row */}
      <div className="mb-4">
        <InsightRow items={[
          {
            icon: Shield, title: "Tax Protection",
            metric: money(summary?.savings_balance || 0),
            sub: `${score}% ready for next quarter`,
          },
          {
            icon: Car, title: "Miles Tracked",
            metric: `${num(summary?.mileage?.business_miles || 0)} mi`,
            sub: `IRS $0.70/mi · ${money(summary?.mileage?.business_deduction || 0)}`,
          },
          {
            icon: ChartLineUp, title: "Projections",
            metric: money(summary?.federal_estimated_tax || 0),
            sub: "Annual estimated tax",
          },
        ]} />
      </div>

      {/* Financial Timeline */}
      <div className="milli-card p-4 mb-4" data-testid="dashboard-timeline-card">
        <div className="px-2 pt-2 pb-1 flex items-center justify-between">
          <div className="text-volt text-xs font-mono uppercase tracking-[0.24em]">
            // Payout Timeline
          </div>
          <Link to="/app/income" className="text-xs font-mono text-zinc-500 hover:text-volt uppercase tracking-widest inline-flex items-center gap-1">
            All payouts <CaretRight size={10} weight="bold" />
          </Link>
        </div>
        <FinancialTimeline payouts={deposits} />
      </div>

      {/* Tax Vault */}
      <div className="mb-4" data-testid="dashboard-vault-card">
        <TaxVaultCard
          balance={summary?.savings_balance || 0}
          period={"Q3"}
          locked={!isElite && (summary?.savings_balance || 0) === 0}
        />
      </div>

      {/* Quarterly checklist */}
      <div className="milli-card p-6 mb-4" data-testid="dashboard-checklist-card">
        <div className="text-volt text-sm font-semibold uppercase tracking-[0.18em] mb-4">Quarterly Checklist</div>
        <div className="divide-y divide-hairline/60">
          <CheckRow label="Income" done={checks.income} to="/app/income" testid="check-income" />
          <CheckRow label="Mileage" done={checks.mileage} to="/app/mileage" testid="check-mileage" />
          <CheckRow label="Expenses" done={checks.expenses} to="/app/expenses" testid="check-expenses" />
          <CheckRow label="1099s & Reports" done={checks.quarterly} to="/app/reports" testid="check-1099s" />
        </div>
      </div>

      {/* Federal + State Filing card */}
      <Link
        to="/app/reports"
        data-testid="dashboard-filing-card"
        className="milli-card p-6 mb-4 block hover:border-volt/50 transition-colors relative overflow-hidden"
      >
        <div className="flex items-center gap-5">
          <ShieldCheck size={32} weight="duotone" className="text-volt flex-shrink-0" />
          <div className="flex-1 min-w-0">
            <div className="text-volt text-xs font-bold uppercase tracking-[0.2em]">Federal + State Filing</div>
            <div className="font-chrome text-2xl chrome-text mt-1">
              {isElite ? "Ready for Review" : "Upgrade to Elite"}
            </div>
            <div className="text-zinc-400 text-sm mt-1 max-w-md">
              {isElite
                ? "Your return is prepared and ready for Elite review."
                : "Elite users get auto-filed federal + state returns end-to-end."}
            </div>
          </div>
          {/* Elite shield placeholder */}
          <div className="hidden sm:flex w-20 h-20 items-center justify-center rounded-2xl border border-volt/30 bg-gradient-to-b from-zinc-800 to-zinc-950 flex-shrink-0 relative">
            <div className="chrome-text font-chrome text-xs font-bold tracking-widest">ELITE</div>
            <Star size={14} weight="fill" className="absolute top-2 right-2 text-volt" />
          </div>
        </div>
      </Link>

      {/* KPI grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
        <Kpi label="YTD Gross" value={money(summary.gross_income)} icon={Coins} testid="kpi-gross" />
        <Kpi label="YTD Miles" value={num(summary.total_miles)} icon={MapTrifold} testid="kpi-miles" />
        <Kpi label="Tax Est." value={money(summary.estimated_tax)} icon={CalendarCheck} testid="kpi-est-tax" />
        <Kpi label="Savings" value={money(summary.savings_balance)} icon={ShieldCheck} accent testid="kpi-savings" />
      </div>

      {/* Quick links */}
      <div className="grid sm:grid-cols-2 gap-3">
        <Link
          to="/app/ai"
          data-testid="dashboard-ai-cta"
          className="milli-card p-5 flex items-center gap-4 hover:border-volt/50 transition-colors group"
        >
          <Robot size={28} weight="duotone" className="text-volt" />
          <div className="flex-1">
            <div className="font-semibold">Ask MILLI AI</div>
            <div className="text-xs text-zinc-500">Tax tips · deductions · quarterlies</div>
          </div>
          <ArrowUpRight size={18} className="text-zinc-600 group-hover:text-volt" />
        </Link>
        <Link
          to="/app/reports"
          data-testid="dashboard-reports-cta"
          className="milli-card p-5 flex items-center gap-4 hover:border-volt/50 transition-colors group"
        >
          <FileText size={28} weight="duotone" className="text-volt" />
          <div className="flex-1">
            <div className="font-semibold">Tax Vault</div>
            <div className="text-xs text-zinc-500">Schedule C · SE · mileage CSV</div>
          </div>
          <ArrowUpRight size={18} className="text-zinc-600 group-hover:text-volt" />
        </Link>
      </div>
    </div>
  );
}

function ScoreRing({ value }) {
  const r = 56;
  const c = 2 * Math.PI * r;
  const offset = c - (value / 100) * c;
  return (
    <div className="relative w-36 h-36 flex-shrink-0">
      <svg width="144" height="144" viewBox="0 0 144 144" className="-rotate-90">
        <defs>
          <linearGradient id="ring-grad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#00E5FF" />
            <stop offset="100%" stopColor="#0090A8" />
          </linearGradient>
          <filter id="ring-glow">
            <feGaussianBlur stdDeviation="3" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>
        <circle cx="72" cy="72" r={r} fill="none" stroke="rgba(0,229,255,0.12)" strokeWidth="8" />
        <circle
          cx="72"
          cy="72"
          r={r}
          fill="none"
          stroke="url(#ring-grad)"
          strokeWidth="8"
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={offset}
          filter="url(#ring-glow)"
          style={{ transition: "stroke-dashoffset 800ms cubic-bezier(0.4, 0, 0.2, 1)" }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="chrome-text font-chrome font-bold text-3xl leading-none">{value}%</div>
        <div className="text-volt text-[10px] font-mono uppercase tracking-[0.3em] mt-1">Ready</div>
      </div>
    </div>
  );
}

function CheckRow({ label, done, to, testid }) {
  return (
    <Link to={to} data-testid={testid} className="flex items-center justify-between py-3 hover:bg-white/[0.02] -mx-2 px-2 rounded-lg transition-colors">
      <div className="flex items-center gap-3">
        <CheckCircle size={20} weight={done ? "fill" : "regular"} className={done ? "text-volt" : "text-zinc-700"} />
        <span className={`font-medium ${done ? "text-white" : "text-zinc-400"}`}>{label}</span>
      </div>
      <div className="flex items-center gap-2">
        <span className={`text-sm font-mono ${done ? "text-volt" : "text-zinc-500"}`}>
          {done ? "Complete" : "Pending"}
        </span>
        <CaretRight size={16} className="text-zinc-600" />
      </div>
    </Link>
  );
}

function Kpi({ label, value, icon: Icon, accent, testid }) {
  return (
    <div className="milli-card p-4" data-testid={testid}>
      <div className="flex items-center justify-between mb-2">
        <div className="text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500">{label}</div>
        <Icon size={14} weight="duotone" className={accent ? "text-volt" : "text-zinc-500"} />
      </div>
      <div className={`font-chrome font-bold text-xl ${accent ? "text-volt" : "chrome-text"}`}>{value}</div>
    </div>
  );
}
