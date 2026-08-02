import { useEffect, useState, useMemo } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  PiggyBank, TrendUp, Info, Bank, ArrowDown, ArrowUp,
  Pause, Play, Sparkle, ShieldCheck, Lightning, CheckCircle,
} from "@phosphor-icons/react";

/**
 * Retirement.jsx — Solo 401(k) Tax-Advantaged Growth
 * v3.8 WEALTH ENGINE HARDENING:
 *   + PlanSelector: fixed text visibility (active: cyan/white, inactive: ivory/zinc-400)
 *   + GrowthProjectionGraph: 5-Year / 10-Year projection toggle
 *   + Portfolio Allocation: 401k asset breakdown below graph
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
  { year: "2031", balance: 132000 },
  { year: "2032", balance: 170000 },
  { year: "2033", balance: 215000 },
  { year: "2034", balance: 268000 },
  { year: "2035", balance: 330000 },
];

const PLAN_TYPES = [
  { id: "traditional", label: "Traditional 401(k)", desc: "Pre-tax contributions, taxed on withdrawal" },
  { id: "roth", label: "Roth 401(k)", desc: "After-tax contributions, tax-free growth & withdrawal" },
  { id: "solo", label: "Solo 401(k)", desc: "Best for self-employed — up to $69K/year combined" },
];

const ALLOCATION_401K = [
  { name: "S&P 500 Index (VFIAX)", allocation: 60, color: "#00E5FF", gain: "+14.2%" },
  { name: "Intl Stocks (VXUS)", allocation: 20, color: "#34D399", gain: "+8.7%" },
  { name: "Total Bonds (BND)", allocation: 20, color: "#FFB800", gain: "+3.4%" },
];

export default function Retirement() {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);
  const [busy, setBusy] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState("solo");

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
      await api.post("/smart/retirement/setup", { plan_type: selectedPlan });
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

        {/* 401(k) Type Selector */}
        <PlanSelector selected={selectedPlan} onSelect={setSelectedPlan} />

        <div
          className="p-8 text-center rounded-[22px]"
          style={{ background: "rgba(13,15,18,0.6)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.08)" }}
        >
          <div className="w-16 h-16 mx-auto mb-5 rounded-2xl flex items-center justify-center" style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.3)" }}>
            <PiggyBank size={32} weight="duotone" style={{ color: "#00E5FF" }} />
          </div>
          <div className="font-display text-2xl mb-2">Open your {PLAN_TYPES.find(p => p.id === selectedPlan)?.label}.</div>
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

      {/* 401(k) Type Selector */}
      <PlanSelector selected={selectedPlan} onSelect={setSelectedPlan} />

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

      {/* High-Fidelity Growth Projection Graph (SVG Line Chart) with 5Y/10Y toggle */}
      <GrowthProjectionGraph data={GROWTH_PROJECTION} />

      {/* Portfolio Allocation — 401(k) breakdown */}
      <PortfolioAllocation401k />

      {/* Coming Soon: 3% Contribution Match */}
      <div
        className="p-5 mb-5 rounded-[22px]"
        style={{ background: "rgba(0, 229, 255, 0.04)", border: "1px solid rgba(0, 229, 255, 0.15)" }}
        data-testid="contribution-match-banner"
      >
        <div className="flex items-center gap-3">
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: "rgba(0,229,255,0.1)",
            border: "1px solid rgba(0,229,255,0.3)",
            display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
          }}>
            <Sparkle size={18} weight="fill" style={{ color: "#00E5FF" }} />
          </div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#FFFFFF" }}>
              Coming Soon: 3% Contribution Match
            </div>
            <div style={{ fontSize: 11, color: "#8B9DAF", marginTop: 2, lineHeight: 1.4 }}>
              For inputs up to 10%. Milli will match 3% of every contribution automatically — free money for your future.
            </div>
          </div>
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

/* =================== SUB-COMPONENTS =================== */

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

function PlanSelector({ selected, onSelect }) {
  return (
    <div
      className="mb-5 p-4 rounded-[22px]"
      style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
      data-testid="plan-type-selector"
    >
      <div className="text-xs font-mono uppercase tracking-[0.2em] mb-3" style={{ color: "#00E5FF" }}>
        // Select 401(k) Type
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {PLAN_TYPES.map((plan) => {
          const isActive = selected === plan.id;
          return (
            <button
              key={plan.id}
              data-testid={`plan-type-${plan.id}`}
              onClick={() => onSelect(plan.id)}
              style={{
                all: "unset",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                gap: 12,
                padding: "14px 16px",
                borderRadius: 14,
                background: isActive ? "rgba(0,229,255,0.06)" : "rgba(5,6,7,0.6)",
                border: isActive
                  ? "1px solid rgba(0,229,255,0.4)"
                  : "1px solid rgba(255,255,255,0.04)",
                transition: "all 0.2s",
              }}
            >
              <div style={{
                width: 20, height: 20, borderRadius: "50%",
                border: isActive ? "2px solid #00E5FF" : "2px solid #3A3F47",
                display: "flex", alignItems: "center", justifyContent: "center",
                flexShrink: 0,
              }}>
                {isActive && <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#00E5FF" }} />}
              </div>
              <div style={{ flex: 1 }}>
                {/* Title: neon cyan when active, ivory when inactive */}
                <div style={{ fontSize: 14, fontWeight: 600, color: isActive ? "#00E5FF" : "#F4F6F8" }}>
                  {plan.label}
                </div>
                {/* Description: white when active, zinc-400 when inactive */}
                <div style={{ fontSize: 11, color: isActive ? "#FFFFFF" : "#A1A1AA", marginTop: 2 }}>
                  {plan.desc}
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function GrowthProjectionGraph({ data }) {
  const [yearRange, setYearRange] = useState("10");

  const displayData = yearRange === "5" ? data.slice(0, 5) : data;

  const maxVal = Math.max(...displayData.map((d) => d.balance));
  const W = 340, H = 180;
  const padL = 10, padR = 10, padT = 20, padB = 30;
  const chartW = W - padL - padR;
  const chartH = H - padT - padB;

  const points = displayData.map((d, i) => {
    const x = padL + (i / (displayData.length - 1)) * chartW;
    const y = padT + chartH - (d.balance / maxVal) * chartH;
    return { x, y, ...d };
  });

  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ");
  const areaPath = `${linePath} L ${points[points.length - 1].x} ${padT + chartH} L ${points[0].x} ${padT + chartH} Z`;

  return (
    <div
      className="p-5 mb-5 rounded-[22px]"
      style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
      data-testid="growth-projection-graph"
    >
      <div className="flex items-center justify-between mb-4">
        <div className="text-xs font-mono uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>// Growth Projection</div>

        {/* 5Y / 10Y Segmented Toggle */}
        <div
          data-testid="projection-toggle"
          style={{
            display: "flex",
            gap: 2,
            background: "rgba(5,6,7,0.7)",
            border: "1px solid rgba(255,255,255,0.06)",
            borderRadius: 10,
            padding: 2,
          }}
        >
          {["5", "10"].map((yr) => (
            <button
              key={yr}
              data-testid={`projection-toggle-${yr}y`}
              onClick={() => setYearRange(yr)}
              style={{
                all: "unset",
                cursor: "pointer",
                fontSize: 10,
                fontWeight: 700,
                padding: "3px 10px",
                borderRadius: 8,
                letterSpacing: "0.06em",
                transition: "all 0.18s",
                background: yearRange === yr ? "rgba(0,229,255,0.12)" : "transparent",
                color: yearRange === yr ? "#00E5FF" : "#5A6573",
                border: yearRange === yr ? "1px solid rgba(0,229,255,0.3)" : "1px solid transparent",
              }}
            >
              {yr}Y
            </button>
          ))}
        </div>
      </div>

      <div style={{ width: "100%", maxWidth: W, margin: "0 auto" }}>
        <svg viewBox={`0 0 ${W} ${H}`} width="100%" height="auto" style={{ display: "block" }}>
          <defs>
            <linearGradient id="growth-area-grad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.25" />
              <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.0" />
            </linearGradient>
            <filter id="glow-line">
              <feGaussianBlur stdDeviation="2" result="glow" />
              <feMerge>
                <feMergeNode in="glow" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>

          {/* Grid lines */}
          {[0.25, 0.5, 0.75, 1].map((frac) => (
            <line
              key={frac}
              x1={padL}
              y1={padT + chartH - frac * chartH}
              x2={padL + chartW}
              y2={padT + chartH - frac * chartH}
              stroke="rgba(255,255,255,0.04)"
              strokeWidth="1"
            />
          ))}

          {/* Area fill */}
          <path d={areaPath} fill="url(#growth-area-grad)" />

          {/* Line */}
          <path
            d={linePath}
            fill="none"
            stroke="#00E5FF"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            filter="url(#glow-line)"
          />

          {/* Data points */}
          {points.map((p, i) => (
            <g key={i}>
              <circle cx={p.x} cy={p.y} r="4" fill="#0D0F12" stroke="#00E5FF" strokeWidth="2" />
              {/* Year label */}
              <text
                x={p.x}
                y={padT + chartH + 16}
                textAnchor="middle"
                fill="#5A6573"
                fontSize="8"
                fontFamily="monospace"
              >
                {p.year.slice(2)}
              </text>
              {/* Value label (show every other) */}
              {i % 2 === 0 && (
                <text
                  x={p.x}
                  y={p.y - 10}
                  textAnchor="middle"
                  fill="#00E5FF"
                  fontSize="7.5"
                  fontFamily="monospace"
                  fontWeight="600"
                >
                  ${Math.round(p.balance / 1000)}K
                </text>
              )}
            </g>
          ))}
        </svg>
      </div>
    </div>
  );
}

function PortfolioAllocation401k() {
  return (
    <div
      className="p-5 mb-5 rounded-[22px]"
      style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
      data-testid="portfolio-allocation-401k"
    >
      <div className="flex items-center justify-between mb-4">
        <div className="text-xs font-semibold uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>
          Portfolio Allocation
        </div>
        <div className="text-[10px] font-mono text-zinc-500 uppercase tracking-widest">
          401(k) Split
        </div>
      </div>

      <div className="space-y-3">
        {ALLOCATION_401K.map((h, i) => (
          <div key={i} className="flex items-center gap-3">
            {/* Allocation percentage */}
            <div
              className="w-9 text-right font-mono text-xs flex-shrink-0"
              style={{ color: h.color }}
            >
              {h.allocation}%
            </div>

            {/* Progress bar */}
            <div
              className="flex-shrink-0"
              style={{ flex: "0 0 40%", height: 6, borderRadius: 4, background: "rgba(255,255,255,0.04)" }}
            >
              <div
                style={{
                  width: `${h.allocation}%`,
                  height: "100%",
                  borderRadius: 4,
                  background: `linear-gradient(90deg, ${h.color}, ${h.color}99)`,
                  boxShadow: `0 0 8px ${h.color}55`,
                  transition: "width 0.6s cubic-bezier(0.4,0,0.2,1)",
                }}
              />
            </div>

            {/* Name */}
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium truncate" style={{ color: "#FFFFFF" }}>
                {h.name}
              </div>
            </div>

            {/* Gain */}
            <div className="text-xs font-mono flex-shrink-0" style={{ color: "#34D399" }}>
              {h.gain}
            </div>
          </div>
        ))}
      </div>

      {/* Donut-style visual summary */}
      <div className="mt-5 pt-4" style={{ borderTop: "1px solid rgba(255,255,255,0.04)" }}>
        <div className="flex gap-3 flex-wrap">
          {ALLOCATION_401K.map((h) => (
            <div key={h.name} className="flex items-center gap-1.5">
              <div style={{ width: 8, height: 8, borderRadius: 2, background: h.color, flexShrink: 0 }} />
              <span className="text-[10px] font-mono" style={{ color: "#8B9DAF" }}>
                {h.name.split(" (")[0]}
              </span>
            </div>
          ))}
        </div>
      </div>
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
      <div className={`font-chrome font-bold text-lg`} style={{ color: highlight ? "#00E5FF" : "#E8E8E8" }}>
        {money(amount)}
      </div>
    </div>
  );
}
