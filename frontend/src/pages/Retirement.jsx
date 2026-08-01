import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  PiggyBank, TrendUp, Info, Bank, ArrowDown, ArrowUp,
  Pause, Play, Sparkle, ShieldCheck, Lightning,
} from "@phosphor-icons/react";

/**
 * Retirement.jsx — Solo 401(k) Tax-Advantaged Growth
 * AESTHETIC: 28px blur glassmorphism, #0D0F12 base, neon cyan
 * CONTENT: Contribution limits, tax-free growth projections
 */

const CONTRIBUTION_LIMITS_2026 = {
  employee_deferral: 23000,
  employer_match: 46000,
  combined_max: 69000,
  catch_up_50_plus: 7500,
};

const GROWTH_PROJECTION = [
  { year: "2026", balance: 12000 },
  { year: "2027", balance: 28500 },
  { year: "2028", balance: 48200 },
  { year: "2029", balance: 71800 },
  { year: "2030", balance: 99500 },
];

export default function Retirement() {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);
  const [busy, setBusy] = useState(false);

  async function load() {
    try {
      const { data } = await api.get("/smart/retirement");
      setAcct(data);
    } catch (e) { /* silent */ }
  }
  useEffect(() => { load(); }, []);

  async function setup() {
    setBusy(true);
    try {
      await api.post("/smart/retirement/setup", {});
      toast.success("Solo 401(k) opened");
      await load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  const balance = acct?.balance || 0;
  const ytdGrowth = acct?.ytd_growth || 0;
  const rule = acct?.rule || {};
  const pct = Math.round((rule.fixed_percentage ?? 0.08) * 100);
  const ytdContributed = acct?.ytd_contributed || balance * 0.6;
  const remainingRoom = CONTRIBUTION_LIMITS_2026.combined_max - ytdContributed;
  const maxProj = Math.max(...GROWTH_PROJECTION.map(d => d.balance));

  if (acct === undefined) {
    return (
      <div className="p-12 font-mono animate-pulse" style={{ backgroundColor: "#0D0F12", color: "#00E5FF", minHeight: "100vh" }}>
        [ LOADING SOLO 401(k)... ]
      </div>
    );
  }

  if (!acct) {
    return (
      <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-3xl mx-auto" style={{ backgroundColor: "#0D0F12", color: "#FFFFFF", minHeight: "100%" }}>
        <PageHeader />
        <div
          className="p-8 text-center rounded-[22px]"
          style={{ background: "rgba(13,15,18,0.6)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.08)" }}
        >
          <div className="w-16 h-16 mx-auto mb-5 rounded-2xl flex items-center justify-center" style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.3)" }}>
            <PiggyBank size={32} weight="duotone" style={{ color: "#00E5FF" }} />
          </div>
          <div className="font-display text-2xl mb-2">Open your Solo 401(k).</div>
          <div className="text-zinc-400 text-sm mb-6 max-w-md mx-auto leading-relaxed">
            Stash up to $69,000/year tax-free. Milli auto-contributes from every payout. Your future self will thank you.
          </div>
          <button
            onClick={setup}
            disabled={busy}
            data-testid="retirement-setup-btn"
            className="btn-volt px-6 py-3 uppercase tracking-wider text-xs inline-flex items-center gap-2 disabled:opacity-50"
          >
            <Bank size={14} weight="bold" /> {busy ? "Opening..." : "Open my 401(k)"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-4xl mx-auto" style={{ backgroundColor: "#0D0F12", color: "#FFFFFF", minHeight: "100%" }}>
      <PageHeader />

      {/* Balance Hero */}
      <div
        className="p-7 mb-5 relative overflow-hidden rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px) brightness(1.15)", border: "1px solid rgba(0,229,255,0.1)" }}
        data-testid="retirement-balance-card"
      >
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-cyan-400/40 to-transparent" />
        <div className="flex items-start justify-between flex-wrap gap-4">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <PiggyBank size={14} weight="bold" style={{ color: "#00E5FF" }} />
              <span className="text-xs font-semibold uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>Solo 401(k) Balance</span>
            </div>
            <div className="font-chrome font-bold text-5xl sm:text-6xl tabular-nums" style={{ background: "linear-gradient(135deg, #E8E8E8, #808080)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              {money(balance)}
            </div>
            <div className="text-zinc-400 text-sm mt-2">
              {pct}% per payout · {rule.paused ? <span style={{ color: "#FFB800" }}>paused</span> : <span style={{ color: "#34D399" }}>active</span>}
            </div>
          </div>
          <div className="text-right">
            <div className="text-xs text-zinc-500 font-mono uppercase tracking-widest">Tax Savings</div>
            <div className="font-chrome font-bold text-2xl" style={{ color: "#34D399" }}>
              <ShieldCheck size={16} weight="bold" className="inline mr-1" />
              {money(ytdContributed * 0.25)}
            </div>
            <div className="text-[10px] text-zinc-500 mt-1">at 25% marginal rate</div>
          </div>
        </div>
      </div>

      {/* Contribution Limits */}
      <div
        className="p-5 mb-5 rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.08)" }}
        data-testid="contribution-limits"
      >
        <div className="text-xs font-semibold uppercase tracking-[0.2em] mb-4" style={{ color: "#00E5FF" }}>
          2026 IRS Contribution Limits
        </div>
        <div className="grid grid-cols-2 gap-4 mb-4">
          <LimitCard label="Employee Deferral" amount={CONTRIBUTION_LIMITS_2026.employee_deferral} />
          <LimitCard label="Employer Match" amount={CONTRIBUTION_LIMITS_2026.employer_match} />
          <LimitCard label="Combined Maximum" amount={CONTRIBUTION_LIMITS_2026.combined_max} highlight />
          <LimitCard label="Catch-Up (50+)" amount={CONTRIBUTION_LIMITS_2026.catch_up_50_plus} />
        </div>

        {/* Progress toward limit */}
        <div className="mt-4">
          <div className="flex justify-between text-xs mb-2">
            <span className="text-zinc-400">YTD Contributed</span>
            <span className="font-mono" style={{ color: "#00E5FF" }}>{money(ytdContributed)} / {money(CONTRIBUTION_LIMITS_2026.combined_max)}</span>
          </div>
          <div className="h-3 rounded-full overflow-hidden" style={{ background: "rgba(255,255,255,0.04)" }}>
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{
                width: `${Math.min((ytdContributed / CONTRIBUTION_LIMITS_2026.combined_max) * 100, 100)}%`,
                background: "linear-gradient(90deg, #00E5FF, #0B7A94)",
                boxShadow: "0 0 12px rgba(0,229,255,0.4)",
              }}
            />
          </div>
          <div className="text-right text-[10px] text-zinc-500 mt-1 font-mono">
            {money(remainingRoom > 0 ? remainingRoom : 0)} remaining
          </div>
        </div>
      </div>

      {/* Tax-Free Growth Projection Chart */}
      <div
        className="p-5 mb-5 rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
        data-testid="growth-projection"
      >
        <div className="flex items-center justify-between mb-4">
          <div className="text-xs font-mono uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>// Tax-Free Growth Projection</div>
          <div className="text-xs text-zinc-500 font-mono">5-year outlook</div>
        </div>
        <div className="flex items-end gap-3 h-36">
          {GROWTH_PROJECTION.map((d, i) => (
            <div key={i} className="flex-1 flex flex-col items-center gap-1">
              <div className="text-[9px] font-mono" style={{ color: "#00E5FF" }}>{money(d.balance)}</div>
              <div
                className="w-full rounded-t-lg transition-all"
                style={{
                  height: `${(d.balance / maxProj) * 100}%`,
                  background: `linear-gradient(180deg, #00E5FF 20%, rgba(0,229,255,0.1))`,
                  boxShadow: "0 0 16px rgba(0,229,255,0.25)",
                  minHeight: 8,
                }}
              />
              <span className="text-[10px] text-zinc-500 font-mono">{d.year}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Legal & Info */}
      <div
        className="p-5 rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.4)", backdropFilter: "blur(28px)", border: "1px solid rgba(255,255,255,0.03)" }}
      >
        <div className="flex items-start gap-3">
          <Info size={16} className="text-zinc-500 mt-0.5 flex-shrink-0" />
          <div className="text-xs text-zinc-500 leading-relaxed">
            <strong className="text-zinc-300">Solo 401(k) Tax Advantage:</strong> Contributions reduce your taxable income dollar-for-dollar.
            Growth is tax-deferred until withdrawal. The 2026 combined limit is $69,000 ($76,500 with catch-up for 50+).
            Withdrawals before age 59½ may incur penalties. Milli partners with a licensed retirement custodian. This is not tax or investment advice.
          </div>
        </div>
      </div>
    </div>
  );
}

function PageHeader() {
  return (
    <div className="mb-6">
      <div className="font-mono text-xs uppercase tracking-[0.3em]" style={{ color: "#00E5FF" }}>// Wealth Engine · Solo 401(k)</div>
      <h1 className="font-display text-3xl sm:text-4xl tracking-tight mt-1" style={{ background: "linear-gradient(135deg, #E8E8E8, #808080)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
        Pay your future self first.
      </h1>
      <p className="text-zinc-400 mt-1 text-sm">Tax-advantaged retirement · Auto-contribute from every payout.</p>
    </div>
  );
}

function LimitCard({ label, amount, highlight }) {
  return (
    <div
      className="p-3 rounded-xl"
      style={{
        background: highlight ? "rgba(0,229,255,0.06)" : "rgba(5,6,7,0.5)",
        border: highlight ? "1px solid rgba(0,229,255,0.2)" : "1px solid rgba(255,255,255,0.04)",
      }}
    >
      <div className="text-[10px] text-zinc-500 font-mono uppercase tracking-wider mb-1">{label}</div>
      <div className={`font-chrome font-bold text-lg ${highlight ? "" : ""}`} style={{ color: highlight ? "#00E5FF" : "#E8E8E8" }}>
        {money(amount)}
      </div>
    </div>
  );
}
