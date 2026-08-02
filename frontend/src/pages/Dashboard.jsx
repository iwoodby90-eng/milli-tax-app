import { useEffect, useState } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  Bank, MapTrifold, CalendarCheck, ShieldCheck, CheckCircle, CaretRight,
  Star, Coins, Robot, ArrowUpRight, FileText, Shield, Car, ChartLineUp,
  PiggyBank, Receipt, TrendUp,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import {
  TaxReadyGauge, FinancialTimeline, TaxVaultCard,
  InsightRow, EliteBadge,
} from "@/components/MilliPrimitives";
import MilliCentsWidget from "@/components/MilliCentsWidget";


export default function Dashboard() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const [deposits, setDeposits] = useState([]);
  const [trips, setTrips] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [syncing, setSyncing] = useState(false);
  const [vault, setVault] = useState(null);
  const [retirementAcct, setRetirementAcct] = useState(null);
  const [investingAcct, setInvestingAcct] = useState(null);
  const [mileageSummary, setMileageSummary] = useState(null);

  async function load() {
    try {
      const [s, d, t, e, v, ret, inv, mil] = await Promise.all([
        api.get("/tax/summary"),
        api.get("/deposits"),
        api.get("/trips"),
        api.get("/expenses"),
        api.get("/vault").catch(() => ({ data: null })),
        api.get("/smart/retirement").catch(() => ({ data: null })),
        api.get("/smart/investing").catch(() => ({ data: null })),
        api.get("/mileage/summary").catch(() => ({ data: null })),
      ]);
      setSummary(s.data);
      setDeposits(d.data);
      setTrips(t.data);
      setExpenses(e.data);
      setVault(v.data);
      setRetirementAcct(ret.data);
      setInvestingAcct(inv.data);
      setMileageSummary(mil.data);
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
    return (
      <div
        className="p-12 font-mono animate-pulse"
        style={{ backgroundColor: "#050607", color: "#00E5FF", minHeight: "100vh" }}
      >
        [ LOADING MILLI... ]
      </div>
    );
  }

  // Tax-ready score
  const checks = {
    income: deposits.length > 0,
    mileage: trips.length > 0,
    expenses: expenses.length > 0,
    quarterly: summary.estimated_tax > 0,
  };
  const filled = Object.values(checks).filter(Boolean).length;
  const score = Math.round((filled / 4) * 100);
  const isElite = user?.plan === "elite";

  // Wealth: retirement + investing balances
  const retBalance = retirementAcct?.balance ?? user?.retirement_balance ?? 0;
  const invBalance = investingAcct?.balance ?? user?.investing_balance ?? 0;
  const wealthTotal = retBalance + invBalance;

  // Vault balance
  const vaultBalance = vault?.balance ?? summary?.savings_balance ?? 0;

  // Mileage & expenses
  const totalMiles = mileageSummary?.total_miles ?? summary?.total_miles ?? 0;
  const businessMiles = mileageSummary?.business_miles ?? totalMiles;
  const mileageDeduction = mileageSummary?.business_deduction ?? summary?.mileage_deduction ?? 0;
  const expenseTotal = summary?.expense_total ?? 0;

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-5xl mx-auto">

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
        <div className="text-xs text-zinc-500 font-mono uppercase tracking-[0.3em]">
          Welcome back, {user?.name?.split(" ")[0]}
        </div>
      </div>

      {/* ══════════════════════════════════════════════════════
          1 · MILLI-CENTS PROFITABILITY ENGINE  ← HERO TOP
          ══════════════════════════════════════════════════════ */}
      <div className="mb-4" data-testid="dashboard-milli-cents-inline">
        <MilliCentsWidget inline />
      </div>

      {/* ══════════════════════════════════════════════════════
          2 · WEALTH SUMMARY  (Investing + Retirement)
          ══════════════════════════════════════════════════════ */}
      <div
        className="milli-card p-6 mb-4 relative overflow-hidden"
        data-testid="dashboard-wealth-summary"
      >
        {/* Subtle ambient gradient */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "radial-gradient(ellipse 60% 50% at 85% 50%, rgba(0,229,255,0.04) 0%, transparent 70%)",
          }}
        />
        <div className="flex items-center gap-2 mb-4">
          <TrendUp size={18} weight="duotone" className="text-volt" />
          <span className="font-semibold text-sm uppercase tracking-[0.18em] text-volt">Wealth Summary</span>
        </div>

        <div className="flex items-end gap-4 flex-wrap">
          <div className="flex-1 min-w-0">
            <div className="text-zinc-500 text-[10px] font-mono uppercase tracking-[0.25em] mb-1">Combined Balance</div>
            <div className="chrome-text font-chrome font-bold text-4xl sm:text-5xl tracking-tight" data-testid="wealth-total">
              {money(wealthTotal).split(".")[0]}
              <span className="text-2xl text-zinc-400">.{money(wealthTotal).split(".")[1] || "00"}</span>
            </div>
            <div className="text-zinc-400 text-xs font-mono mt-2">
              Investing + Retirement
            </div>
          </div>

          {/* Breakdown mini-cards */}
          <div className="flex gap-3 flex-shrink-0">
            <Link
              to="/app/investing"
              className="flex flex-col items-center justify-center px-4 py-3 rounded-2xl"
              style={{
                background: "rgba(0,229,255,0.04)",
                border: "1px solid rgba(0,229,255,0.12)",
                minWidth: 90,
              }}
            >
              <ChartLineUp size={18} weight="duotone" className="text-volt mb-1" />
              <div className="font-chrome font-bold text-lg chrome-text" data-testid="wealth-investing">
                {money(invBalance)}
              </div>
              <div className="text-[9px] font-mono uppercase tracking-[0.2em] text-zinc-500 mt-0.5">Investing</div>
            </Link>
            <Link
              to="/app/retirement"
              className="flex flex-col items-center justify-center px-4 py-3 rounded-2xl"
              style={{
                background: "rgba(0,229,255,0.04)",
                border: "1px solid rgba(0,229,255,0.12)",
                minWidth: 90,
              }}
            >
              <PiggyBank size={18} weight="duotone" className="text-volt mb-1" />
              <div className="font-chrome font-bold text-lg chrome-text" data-testid="wealth-retirement">
                {money(retBalance)}
              </div>
              <div className="text-[9px] font-mono uppercase tracking-[0.2em] text-zinc-500 mt-0.5">Retirement</div>
            </Link>
          </div>
        </div>

        {(retBalance === 0 && invBalance === 0) && (
          <Link
            to="/app/wealth"
            className="mt-4 flex items-center gap-2 text-xs font-mono uppercase tracking-widest"
            style={{ color: "rgba(0,229,255,0.6)" }}
          >
            <span>Set up smart accounts</span>
            <CaretRight size={10} weight="bold" />
          </Link>
        )}
      </div>

      {/* ══════════════════════════════════════════════════════
          3 · TAX VAULT
          ══════════════════════════════════════════════════════ */}
      <div className="mb-4" data-testid="dashboard-vault-card">
        <TaxVaultCard
          balance={vaultBalance}
          period={summary.next_quarterly?.label || "Q3"}
          locked={!isElite && vaultBalance === 0}
        />
      </div>

      {/* ══════════════════════════════════════════════════════
          4 · QUARTERLY READINESS / TAX SCORE GAUGE
          ══════════════════════════════════════════════════════ */}
      <div
        className="milli-card p-6 mb-4 flex flex-col lg:flex-row items-center gap-8"
        data-testid="dashboard-tax-score-card"
      >
        <TaxReadyGauge score={score} />
        <div className="flex-1 min-w-0 text-center lg:text-left">
          <div className="text-volt text-sm font-semibold uppercase tracking-[0.24em] mb-3">
            // Quarterly Readiness
          </div>
          <div className="text-zinc-300 text-base leading-snug max-w-md mx-auto lg:mx-0">
            {score >= 75
              ? "You're in great shape. Milli has protected enough to cover the next quarterly estimate."
              : score >= 40
              ? "Halfway there — every payout brings you closer. Log a few more items to close the gap."
              : "Let's get rolling. Connect your bank and take a first trip to start the score."}
          </div>

          {/* Next quarterly due */}
          <div className="mt-4 flex flex-col sm:flex-row gap-3 justify-center lg:justify-start">
            <div
              className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm"
              style={{ background: "rgba(0,229,255,0.05)", border: "1px solid rgba(0,229,255,0.12)" }}
            >
              <CalendarCheck size={14} weight="duotone" className="text-volt" />
              <span className="text-zinc-300 font-mono">
                {summary.next_quarterly.label} · {money(summary.next_quarterly.amount)} due
              </span>
            </div>
            <div
              className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm"
              style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}
            >
              <span className="text-zinc-500 font-mono text-xs">
                {summary.next_quarterly.days_until}d until deadline
              </span>
            </div>
          </div>

          {isElite && (
            <div className="mt-4 flex justify-center lg:justify-start">
              <EliteBadge size={72} />
            </div>
          )}
        </div>
      </div>

      {/* ══════════════════════════════════════════════════════
          5 · MILEAGE & EXPENSES SUMMARY
          ══════════════════════════════════════════════════════ */}
      <div
        className="milli-card p-6 mb-4 relative overflow-hidden"
        data-testid="dashboard-mileage-expenses-card"
      >
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "radial-gradient(ellipse 50% 60% at 15% 50%, rgba(0,229,255,0.03) 0%, transparent 70%)",
          }}
        />
        <div className="flex items-center gap-2 mb-5">
          <Car size={18} weight="duotone" className="text-volt" />
          <span className="font-semibold text-sm uppercase tracking-[0.18em] text-volt">Mileage &amp; Expenses</span>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <MiniStat
            label="Business Miles"
            value={`${num(businessMiles)} mi`}
            sub={`${num(totalMiles)} total`}
            accent
            testid="me-business-miles"
          />
          <MiniStat
            label="Mileage Deduction"
            value={money(mileageDeduction)}
            sub="IRS $0.70/mi"
            testid="me-deduction"
          />
          <MiniStat
            label="YTD Expenses"
            value={money(expenseTotal)}
            sub={`${expenses.length} receipts`}
            testid="me-expenses"
          />
          <MiniStat
            label="Total Saved"
            value={money(mileageDeduction + expenseTotal)}
            sub="deductible total"
            accent
            testid="me-total-saved"
          />
        </div>

        <div className="mt-5 flex gap-3">
          <Link
            to="/app/mileage"
            className="flex-1 flex items-center justify-between px-4 py-3 rounded-xl transition-colors hover:border-volt/40"
            style={{ background: "rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.06)" }}
          >
            <div className="flex items-center gap-2">
              <MapTrifold size={16} weight="duotone" className="text-volt" />
              <span className="text-sm font-medium text-zinc-200">Track Mileage</span>
            </div>
            <CaretRight size={14} className="text-zinc-600" />
          </Link>
          <Link
            to="/app/expenses"
            className="flex-1 flex items-center justify-between px-4 py-3 rounded-xl transition-colors hover:border-volt/40"
            style={{ background: "rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.06)" }}
          >
            <div className="flex items-center gap-2">
              <Receipt size={16} weight="duotone" className="text-volt" />
              <span className="text-sm font-medium text-zinc-200">Log Expense</span>
            </div>
            <CaretRight size={14} className="text-zinc-600" />
          </Link>
        </div>
      </div>

      {/* ─── Payout Timeline ─── */}
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

      {/* ─── Quarterly Checklist ─── */}
      <div className="milli-card p-6 mb-4" data-testid="dashboard-checklist-card">
        <div className="text-volt text-sm font-semibold uppercase tracking-[0.18em] mb-4">Quarterly Checklist</div>
        <div className="divide-y divide-hairline/60">
          <CheckRow label="Income" done={checks.income} to="/app/income" testid="check-income" />
          <CheckRow label="Mileage" done={checks.mileage} to="/app/mileage" testid="check-mileage" />
          <CheckRow label="Expenses" done={checks.expenses} to="/app/expenses" testid="check-expenses" />
          <CheckRow label="1099s &amp; Reports" done={checks.quarterly} to="/app/reports" testid="check-1099s" />
        </div>
      </div>

      {/* ─── Federal + State Filing ─── */}
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
          <div className="hidden sm:flex w-20 h-20 items-center justify-center rounded-2xl border border-volt/30 bg-gradient-to-b from-zinc-800 to-zinc-950 flex-shrink-0 relative">
            <div className="chrome-text font-chrome text-xs font-bold tracking-widest">ELITE</div>
            <Star size={14} weight="fill" className="absolute top-2 right-2 text-volt" />
          </div>
        </div>
      </Link>

      {/* ─── KPI grid ─── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
        <Kpi label="YTD Gross" value={money(summary.gross_income)} icon={Coins} testid="kpi-gross" />
        <Kpi label="YTD Miles" value={num(summary.total_miles)} icon={MapTrifold} testid="kpi-miles" />
        <Kpi label="Tax Est." value={money(summary.estimated_tax)} icon={CalendarCheck} testid="kpi-est-tax" />
        <Kpi label="Savings" value={money(summary.savings_balance)} icon={ShieldCheck} accent testid="kpi-savings" />
      </div>

      {/* ─── Quick links ─── */}
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
            <div className="font-semibold">Tax Reports</div>
            <div className="text-xs text-zinc-500">Schedule C · SE · mileage CSV</div>
          </div>
          <ArrowUpRight size={18} className="text-zinc-600 group-hover:text-volt" />
        </Link>
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

function MiniStat({ label, value, sub, accent, testid }) {
  return (
    <div className="flex flex-col" data-testid={testid}>
      <div className="text-[9px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</div>
      <div className={`font-chrome font-bold text-lg leading-tight ${accent ? "text-volt" : "chrome-text"}`}>{value}</div>
      {sub && <div className="text-[10px] text-zinc-600 font-mono mt-0.5">{sub}</div>}
    </div>
  );
}
