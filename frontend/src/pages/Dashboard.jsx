import { useEffect, useState, useCallback } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  Bank, MapTrifold, CalendarCheck, ShieldCheck, CheckCircle, CaretRight,
  Star, Coins, Robot, ArrowUpRight, FileText, Shield, Car, ChartLineUp,
  Play, Stop, NavigationArrow, Vault as VaultIcon, Lightning, Gauge,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import {
  TaxReadyGauge, FinancialTimeline, TaxVaultCard,
  InsightRow, EliteBadge,
} from "@/components/MilliPrimitives";
import MilliCentsWidget from "@/components/MilliCentsWidget";
import GigConnections from "@/components/GigConnections";


export default function Dashboard() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const [deposits, setDeposits] = useState([]);
  const [trips, setTrips] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [syncing, setSyncing] = useState(false);
  const [showMilliCents, setShowMilliCents] = useState(false);

  // Mileage tracker state
  const [tripActive, setTripActive] = useState(false);
  const [tripStartTime, setTripStartTime] = useState(null);
  const [liveMiles, setLiveMiles] = useState(0);
  const [dollarsSaved, setDollarsSaved] = useState(0);

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

  // Live trip simulator
  useEffect(() => {
    if (!tripActive) return;
    const interval = setInterval(() => {
      setLiveMiles(m => {
        const next = m + 0.02 + Math.random() * 0.03;
        setDollarsSaved(next * 0.70); // IRS rate
        return next;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [tripActive]);

  const toggleTrip = useCallback(() => {
    if (tripActive) {
      setTripActive(false);
      toast.success(`Trip ended: ${liveMiles.toFixed(1)} miles · $${dollarsSaved.toFixed(2)} saved`);
    } else {
      setTripActive(true);
      setTripStartTime(Date.now());
      setLiveMiles(0);
      setDollarsSaved(0);
    }
  }, [tripActive, liveMiles, dollarsSaved]);

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
    return <div className="p-12 font-mono text-volt animate-pulse" style={{ backgroundColor: "#050607", color: "#00E5FF", minHeight: "100vh" }}>[ LOADING MILLI... ]</div>;
  }

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
      {/* Desktop header */}
      <div className="hidden lg:flex items-end justify-between flex-wrap gap-4 mb-8">
        <div className="flex items-center gap-4">
          <MilliLogo size={48} />
          <div>
            <div className="font-display chrome-text text-3xl tracking-[0.2em]">MILLI</div>
            <div className="text-zinc-500 text-xs font-mono uppercase tracking-widest mt-1">// command center · {summary.year}</div>
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
        <div className="text-xs text-zinc-500 font-mono uppercase tracking-[0.3em]">Command Center</div>
      </div>

      {/* ═══════════════════════════════════════════════════════
          P0 — REAL-TIME MILEAGE TRACKER (Top Block)
         ═══════════════════════════════════════════════════════ */}
      <div
        className="milli-card relative overflow-hidden mb-4"
        data-testid="mileage-tracker-hero"
        style={{
          background: tripActive
            ? "linear-gradient(135deg, rgba(0,229,255,0.08) 0%, rgba(13,15,18,0.85) 60%)"
            : "rgba(13,15,18,0.6)",
          backdropFilter: "blur(28px)",
          border: tripActive ? "1px solid rgba(0,229,255,0.25)" : "1px solid rgba(40,44,52,0.8)",
        }}
      >
        {/* Animated pulse ring when active */}
        {tripActive && (
          <div className="absolute top-4 right-4 w-3 h-3">
            <div className="absolute inset-0 rounded-full bg-volt animate-ping opacity-40" />
            <div className="absolute inset-0 rounded-full bg-volt" />
          </div>
        )}

        <div className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <NavigationArrow size={18} weight="duotone" className="text-volt" />
            <span className="font-semibold text-xs uppercase tracking-[0.2em] text-volt">Real-Time Mileage</span>
          </div>

          <div className="flex items-center gap-6 flex-wrap">
            {/* Start/Stop Toggle */}
            <button
              onClick={toggleTrip}
              data-testid="trip-toggle-btn"
              className="relative flex-shrink-0"
              style={{
                all: "unset",
                cursor: "pointer",
                width: 72,
                height: 72,
                borderRadius: "50%",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: tripActive
                  ? "radial-gradient(circle at 40% 35%, #FF3B5C 0%, #CC0033 100%)"
                  : "radial-gradient(circle at 40% 35%, #4CDCF5 0%, #00E5FF 40%, #0B7A94 100%)",
                boxShadow: tripActive
                  ? "0 0 24px rgba(255,59,92,0.5), inset 0 2px 0 rgba(255,255,255,0.2)"
                  : "0 0 24px rgba(0,229,255,0.5), inset 0 2px 0 rgba(255,255,255,0.2)",
                border: "2px solid rgba(255,255,255,0.15)",
                transition: "all 0.3s ease",
              }}
            >
              {tripActive ? <Stop size={28} weight="fill" color="#fff" /> : <Play size={28} weight="fill" color="#fff" />}
            </button>

            {/* Live Counters */}
            <div className="flex-1 min-w-0">
              <div className="text-zinc-400 text-xs font-mono uppercase tracking-wider mb-1">
                {tripActive ? "TRACKING LIVE" : "TAP TO START"}
              </div>
              <div className="flex items-baseline gap-4 flex-wrap">
                <div>
                  <span className="chrome-text font-chrome font-bold text-4xl tabular-nums" data-testid="live-miles">
                    {liveMiles.toFixed(1)}
                  </span>
                  <span className="text-zinc-400 text-sm ml-1">mi</span>
                </div>
                <div className="h-8 w-px bg-zinc-700/50" />
                <div>
                  <span className="text-volt font-chrome font-bold text-3xl tabular-nums" data-testid="dollars-saved">
                    ${dollarsSaved.toFixed(2)}
                  </span>
                  <span className="text-zinc-500 text-xs ml-1 font-mono">SAVED</span>
                </div>
              </div>
              {tripActive && tripStartTime && (
                <div className="text-zinc-500 text-xs font-mono mt-2">
                  IRS Rate: $0.70/mi · Started {new Date(tripStartTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </div>
              )}
            </div>

            {/* Mini-map placeholder */}
            <div
              className="hidden sm:flex w-24 h-24 rounded-2xl items-center justify-center flex-shrink-0"
              style={{
                background: "rgba(5,6,7,0.8)",
                border: "1px solid rgba(0,229,255,0.1)",
              }}
              data-testid="mini-map-placeholder"
            >
              <MapTrifold size={32} weight="duotone" className={tripActive ? "text-volt" : "text-zinc-600"} />
            </div>
          </div>
        </div>
      </div>

      {/* ═══════════════════════════════════════════════════════
          CARD FLOW — Tax Vault Module
         ═══════════════════════════════════════════════════════ */}
      <div
        className="milli-card p-6 mb-4 relative overflow-hidden"
        data-testid="tax-vault-module"
        style={{
          background: "rgba(13,15,18,0.5)",
          backdropFilter: "blur(28px) brightness(1.1)",
          border: "1px solid rgba(0,229,255,0.08)",
        }}
      >
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-volt/40 to-transparent" />
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.2)" }}>
            <VaultIcon size={20} weight="duotone" className="text-volt" />
          </div>
          <div>
            <div className="font-semibold text-white text-sm">Tax Vault</div>
            <div className="text-[10px] text-zinc-500 font-mono uppercase tracking-wider">Auto-protected reserves</div>
          </div>
          <Link to="/app/vault" className="ml-auto text-xs text-zinc-500 hover:text-volt font-mono uppercase tracking-wider inline-flex items-center gap-1">
            Open <CaretRight size={10} weight="bold" />
          </Link>
        </div>
        <div className="flex items-end gap-4">
          <div className="chrome-text font-chrome font-bold text-4xl" data-testid="vault-balance-hero">
            {money(summary?.savings_balance || 0)}
          </div>
          <div className="text-zinc-400 text-sm mb-1">
            {score}% tax-ready · Q{Math.ceil((new Date().getMonth() + 1) / 3)}
          </div>
        </div>
      </div>

      {/* ═══════════════════════════════════════════════════════
          CARD FLOW — Wealth Engine Module
         ═══════════════════════════════════════════════════════ */}
      <div
        className="milli-card p-6 mb-4 relative overflow-hidden"
        data-testid="wealth-engine-module"
        style={{
          background: "rgba(13,15,18,0.5)",
          backdropFilter: "blur(28px) brightness(1.1)",
          border: "1px solid rgba(0,229,255,0.06)",
        }}
      >
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-emerald-400/30 to-transparent" />
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: "rgba(52,211,153,0.08)", border: "1px solid rgba(52,211,153,0.2)" }}>
            <ChartLineUp size={20} weight="duotone" style={{ color: "#34D399" }} />
          </div>
          <div>
            <div className="font-semibold text-white text-sm">Wealth Engine</div>
            <div className="text-[10px] text-zinc-500 font-mono uppercase tracking-wider">Invest + Retire on autopilot</div>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Link to="/app/investing" className="p-4 rounded-xl hover:bg-white/[0.02] transition-colors" style={{ background: "rgba(5,6,7,0.5)", border: "1px solid rgba(255,255,255,0.04)" }}>
            <div className="text-[10px] text-zinc-500 font-mono uppercase tracking-wider mb-1">Brokerage</div>
            <div className="font-chrome font-bold text-xl chrome-text">Auto-Invest</div>
            <div className="text-xs text-zinc-400 mt-1">DCA every payout</div>
          </Link>
          <Link to="/app/retirement" className="p-4 rounded-xl hover:bg-white/[0.02] transition-colors" style={{ background: "rgba(5,6,7,0.5)", border: "1px solid rgba(255,255,255,0.04)" }}>
            <div className="text-[10px] text-zinc-500 font-mono uppercase tracking-wider mb-1">Solo 401(k)</div>
            <div className="font-chrome font-bold text-xl chrome-text">Tax-Free</div>
            <div className="text-xs text-zinc-400 mt-1">$69K limit 2026</div>
          </Link>
        </div>
      </div>

      {/* Quarterly Payment Card */}
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
          </div>
          <div className="relative w-24 h-24 rounded-2xl border border-volt/30 bg-obsidian/60 flex items-center justify-center flex-shrink-0">
            <CheckCircle size={48} weight="duotone" className="text-volt" />
            <div className="absolute -top-2 left-3 right-3 h-1.5 bg-zinc-700 rounded-full" />
          </div>
        </div>
      </div>

      {/* Tax Ready Score */}
      <div className="milli-card p-6 mb-4 flex flex-col lg:flex-row items-center gap-8" data-testid="dashboard-tax-score-card">
        <TaxReadyGauge score={score} />
        <div className="flex-1 min-w-0 text-center lg:text-left">
          <div className="text-volt text-sm font-semibold uppercase tracking-[0.24em] mb-3">// Tax Ready Score</div>
          <div className="text-zinc-300 text-base leading-snug max-w-md mx-auto lg:mx-0">
            {score >= 75
              ? "You're in great shape. Milli has protected enough to cover the next quarterly estimate."
              : score >= 40
              ? "Halfway there — every payout brings you closer."
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
          { icon: Shield, title: "Tax Protection", metric: money(summary?.savings_balance || 0), sub: `${score}% ready` },
          { icon: Car, title: "Miles Tracked", metric: `${num(summary?.mileage?.business_miles || 0)} mi`, sub: `$0.70/mi · ${money(summary?.mileage?.business_deduction || 0)}` },
          { icon: ChartLineUp, title: "Projections", metric: money(summary?.federal_estimated_tax || 0), sub: "Annual estimated tax" },
        ]} />
      </div>

      {/* Payout Timeline */}
      <div className="milli-card p-4 mb-4" data-testid="dashboard-timeline-card">
        <div className="px-2 pt-2 pb-1 flex items-center justify-between">
          <div className="text-volt text-xs font-mono uppercase tracking-[0.24em]">// Payout Timeline</div>
          <Link to="/app/income" className="text-xs font-mono text-zinc-500 hover:text-volt uppercase tracking-widest inline-flex items-center gap-1">
            All <CaretRight size={10} weight="bold" />
          </Link>
        </div>
        <FinancialTimeline payouts={deposits} />
      </div>

      {/* KPI grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
        <Kpi label="YTD Gross" value={money(summary.gross_income)} icon={Coins} testid="kpi-gross" />
        <Kpi label="YTD Miles" value={num(summary.total_miles)} icon={MapTrifold} testid="kpi-miles" />
        <Kpi label="Tax Est." value={money(summary.estimated_tax)} icon={CalendarCheck} testid="kpi-est-tax" />
        <Kpi label="Savings" value={money(summary.savings_balance)} icon={ShieldCheck} accent testid="kpi-savings" />
      </div>

      {/* Milli-Cents Engine */}
      {(user?.plan === "pro" || user?.plan === "elite") && (
        <>
          <button
            onClick={() => setShowMilliCents(true)}
            data-testid="dashboard-milli-cents-cta"
            className="milli-card p-5 mb-4 w-full flex items-center gap-4 hover:border-volt/50 transition-colors group text-left"
          >
            <div className="w-12 h-12 rounded-2xl border border-volt/30 bg-zinc-900 flex items-center justify-center flex-shrink-0">
              <Gauge size={24} weight="duotone" className="text-volt" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="font-semibold text-white">Milli-Cents Calculator</div>
              <div className="text-xs text-zinc-500 font-mono">Instant offer profitability · fuel + tax</div>
            </div>
            <ArrowUpRight size={18} className="text-zinc-600 group-hover:text-volt transition-colors" />
          </button>
          {showMilliCents && <MilliCentsWidget onClose={() => setShowMilliCents(false)} />}
        </>
      )}

      {/* ═══════════════════════════════════════════════════════
          GIG CONNECTIONS — Base of Dashboard
         ═══════════════════════════════════════════════════════ */}
      <div className="mb-4" data-testid="dashboard-gig-connections">
        <GigConnections
          bankConnected={deposits.length > 0}
          bankName="Connected Bank"
          connectedPlatforms={[...new Set(deposits.map(d => (d.platform || '').toLowerCase().replace(/\s+/g, '_')).filter(Boolean))]}
        />
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
            <div className="font-semibold">Tax Reports</div>
            <div className="text-xs text-zinc-500">Schedule C · SE · mileage CSV</div>
          </div>
          <ArrowUpRight size={18} className="text-zinc-600 group-hover:text-volt" />
        </Link>
      </div>
    </div>
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
