import { useState } from "react";
import { CaretDown, ArrowUp, ArrowDown, Info } from "@phosphor-icons/react";

/**
 * Retirement — matches the reference mockup.
 * Sections:
 *   1. Projected Balance hero (glowing tree on chrome M base)
 *   2. Projection Range dropdown + Future Value / Income segmented control
 *   3. Line chart projection with hover callout ($2.65M in 10 years)
 *   4. Your Contribution % · Employer Match % · Goal Progress (3-up)
 *   5. Est. Monthly Income + Confidence Level
 *   6. Scenario Comparison (Current Plan · Increase to 20% · Delay 2 Years)
 */
export default function Retirement() {
  const [range, setRange] = useState("10 Years");
  const [viewBy, setViewBy] = useState("Future Value");

  const projected = 2652113;
  const today = 1412020;
  const delta = projected - today;
  const deltaPct = Math.round((delta / today) * 100);

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">
      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          Retirement
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Plan today. Prosper tomorrow.</p>
      </header>

      {/* 1 · Projected Balance Hero */}
      <section
        className="relative overflow-hidden rounded-3xl p-5"
        data-testid="retirement-projected-card"
        style={{
          background: "linear-gradient(135deg, rgba(0,180,200,0.25) 0%, rgba(0,229,255,0.06) 30%, rgba(10,14,18,0.9) 70%)",
          border: "1px solid rgba(0,229,255,0.5)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.08), 0 0 28px rgba(0,229,255,0.3), 0 20px 44px rgba(0,0,0,0.6)",
        }}
      >
        <div className="absolute top-4 right-4 pointer-events-none">
          <GlowingTree />
        </div>
        <div className="relative z-10">
          <div className="text-white/85 text-[14px] font-medium">Projected Balance <span className="text-white/50 ml-1">👁</span></div>
          <div className="font-chrome font-black text-white tabular-nums leading-[1] tracking-tight mt-2 text-[36px] sm:text-[42px]">
            ${projected.toLocaleString("en-US")}
          </div>
          <div className="text-zinc-400 text-[13px] mt-2">at age 65</div>
          <div className="text-volt text-[13px] mt-3 flex items-center gap-1" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            <ArrowUp size={12} weight="bold" />
            ${delta.toLocaleString("en-US")} ({deltaPct}%) more than today
          </div>
        </div>
      </section>

      {/* 2 · Range + View By controls */}
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="flex items-center gap-2">
          <span className="text-zinc-400 text-[13px]">Projection Range</span>
          <button
            className="milli-card rounded-xl px-3 py-1.5 text-white text-[13px] font-medium inline-flex items-center gap-1.5"
            data-testid="retirement-range-select"
          >
            {range} <CaretDown size={12} weight="bold" className="text-zinc-500" />
          </button>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-zinc-400 text-[13px]">View by</span>
          <Segmented
            value={viewBy}
            onChange={setViewBy}
            options={["Future Value", "Income"]}
          />
        </div>
      </div>

      {/* 3 · Line chart */}
      <ProjectionChart projected={projected} range={range} />

      {/* 4 · Contribution / Match / Goal (3-up) */}
      <div className="grid grid-cols-3 gap-2.5">
        <ContribCard label="Your Contribution" pct={15} money="$1,240/mo" ringPct={75} />
        <ContribCard label="Employer Match"    pct={5}  money="$413/mo"   ringPct={25} icon="match" />
        <GoalProgressCard pct={68} goal="$1,800,000" />
      </div>

      {/* 5 · Monthly Income + Confidence */}
      <section className="milli-card rounded-2xl p-5" data-testid="retirement-income-card">
        <div className="grid grid-cols-2 gap-5">
          <div>
            <div className="text-zinc-400 text-[13px] flex items-center gap-1.5">
              Est. Monthly Income <Info size={13} weight="regular" className="text-zinc-600" />
            </div>
            <div className="chrome-text font-chrome font-bold text-[28px] leading-tight mt-1 tabular-nums">
              $10,842 <span className="text-white/50 text-[16px]">/mo</span>
            </div>
            <div className="text-zinc-500 text-[12px] mt-1">At retirement</div>
          </div>
          <div>
            <div className="text-zinc-400 text-[13px]">Confidence Level</div>
            <div className="text-white font-semibold text-[15px] mt-1">High</div>
            <div className="mt-2 flex items-center gap-1">
              {[1, 2, 3, 4, 5].map((n) => (
                <span
                  key={n}
                  className="flex-1 h-1.5 rounded-full"
                  style={{
                    background: n <= 4 ? "linear-gradient(90deg, #00E5FF 0%, #4DE0FF 100%)" : "rgba(255,255,255,0.08)",
                    boxShadow: n <= 4 ? "0 0 10px rgba(0,229,255,0.5)" : "none",
                  }}
                />
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 6 · Scenario Comparison */}
      <section className="milli-card rounded-2xl p-5" data-testid="retirement-scenarios-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[16px]">Scenario Comparison</h2>
          <button className="text-volt text-[13.5px] font-semibold active:opacity-70">View details &rsaquo;</button>
        </div>
        <div className="grid grid-cols-3 gap-2.5">
          <ScenarioCard title="Current Plan" active balance="$2.65M" income="$10,842/mo" note="10 yr forecast" />
          <ScenarioCard title="Increase to 20%" balance="$3.35M" income="$13,680/mo" note="10 yr forecast" delta="up" />
          <ScenarioCard title="Delay 2 Years"   balance="$2.05M" income="$8,420/mo"  note="10 yr forecast" delta="down" />
        </div>
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */

function Segmented({ value, onChange, options }) {
  return (
    <div className="milli-card rounded-xl p-1 flex text-[12px] font-medium">
      {options.map((o) => {
        const active = o === value;
        return (
          <button
            key={o}
            onClick={() => onChange(o)}
            data-testid={`retirement-viewby-${o.toLowerCase().replace(/\s/g, "-")}`}
            className={`px-3 py-1 rounded-lg transition ${active ? "text-volt" : "text-zinc-400"}`}
            style={active
              ? { background: "rgba(0,229,255,0.10)", border: "1px solid rgba(0,229,255,0.5)", textShadow: "0 0 8px rgba(0,229,255,0.5)" }
              : {}}
          >
            {o}
          </button>
        );
      })}
    </div>
  );
}

function ProjectionChart({ projected, range }) {
  // Generate a smooth exponential-ish curve
  const points = [];
  const years = 10;
  const w = 320, h = 160;
  for (let i = 0; i <= years; i++) {
    const t = i / years;
    const v = Math.pow(t, 1.6); // convex growth
    points.push({
      x: (i / years) * w,
      y: h - v * h * 0.85 - 10,
    });
  }
  const pathD = points.reduce((acc, p, i) => acc + (i === 0 ? `M${p.x},${p.y}` : ` L${p.x},${p.y}`), "");
  const areaD = pathD + ` L${w},${h} L0,${h} Z`;
  const last = points[points.length - 1];
  return (
    <section className="milli-card rounded-2xl p-4 pt-5" data-testid="retirement-chart-card">
      <div className="flex">
        {/* Y axis */}
        <div className="flex flex-col justify-between text-[10px] text-zinc-500 pr-2 tabular-nums" style={{ height: 160 }}>
          <span>$3M</span><span>$2M</span><span>$1M</span><span>$0</span>
        </div>
        {/* Chart */}
        <div className="flex-1 relative">
          <svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} preserveAspectRatio="none" style={{ overflow: "visible" }}>
            <defs>
              <linearGradient id="rt-area" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.35" />
                <stop offset="100%" stopColor="#00E5FF" stopOpacity="0" />
              </linearGradient>
              <filter id="rt-glow">
                <feGaussianBlur stdDeviation="2" result="b" />
                <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
              </filter>
            </defs>
            <path d={areaD} fill="url(#rt-area)" />
            <path d={pathD} fill="none" stroke="#00E5FF" strokeWidth={2.5} strokeLinecap="round" filter="url(#rt-glow)" />
            {points.map((p, i) => (
              <circle key={i} cx={p.x} cy={p.y} r={3} fill="#00E5FF" stroke="#05070A" strokeWidth={1.5} />
            ))}
          </svg>
          {/* Hover callout at end */}
          <div
            className="absolute rounded-xl px-3 py-2"
            style={{
              left: `calc(${(last.x / w) * 100}% - 55px)`,
              top: last.y - 40,
              background: "linear-gradient(180deg, rgba(0,229,255,0.18) 0%, rgba(10,14,18,0.9) 100%)",
              border: "1px solid rgba(0,229,255,0.55)",
              boxShadow: "0 0 16px rgba(0,229,255,0.35)",
              minWidth: 90,
            }}
          >
            <div className="text-white font-bold text-[14px] tabular-nums">
              ${(projected / 1_000_000).toFixed(2)}M
            </div>
            <div className="text-white/70 text-[10px]">in {range.toLowerCase()}</div>
          </div>
          {/* X axis */}
          <div className="flex justify-between text-[10px] text-zinc-500 mt-1">
            <span>Today</span><span>2 Yrs</span><span>4 Yrs</span><span>6 Yrs</span><span>8 Yrs</span><span>10 Yrs</span>
          </div>
        </div>
      </div>
    </section>
  );
}

function ContribCard({ label, pct, money, ringPct, icon }) {
  const size = 44, stroke = 4, r = (size - stroke) / 2, c = 2 * Math.PI * r;
  const off = c - (ringPct / 100) * c;
  return (
    <div className="milli-card rounded-2xl p-3" data-testid={`retirement-contrib-${label.toLowerCase().replace(/\s/g, "-")}`}>
      <div className="text-zinc-400 text-[11.5px]">{label}</div>
      <div className="flex items-end justify-between mt-1">
        <div className="chrome-text font-chrome font-bold text-[26px] leading-none tabular-nums">{pct}%</div>
        {icon === "match" ? (
          <div className="w-10 h-10 rounded-full bg-white/[0.05] border border-white/10 flex items-center justify-center">
            <MatchIcon />
          </div>
        ) : (
          <svg width={size} height={size} className="-rotate-90">
            <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(0,229,255,0.15)" strokeWidth={stroke} />
            <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#00E5FF" strokeWidth={stroke}
                    strokeLinecap="round" strokeDasharray={c} strokeDashoffset={off}
                    style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.6))" }} />
          </svg>
        )}
      </div>
      <div className="text-zinc-400 text-[11.5px] mt-1">{money}</div>
    </div>
  );
}

function GoalProgressCard({ pct, goal }) {
  return (
    <div className="milli-card rounded-2xl p-3" data-testid="retirement-goal-card">
      <div className="flex items-center justify-between">
        <div className="text-zinc-400 text-[11.5px]">Goal Progress</div>
        <div className="flex items-center gap-1 text-volt text-[11px] font-bold" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
          <span className="w-1.5 h-1.5 rounded-full bg-volt shadow-[0_0_6px_#00E5FF]" />{pct}%
        </div>
      </div>
      <div className="mt-2 h-1.5 rounded-full bg-white/[0.08] overflow-hidden">
        <div
          className="h-full rounded-full"
          style={{
            width: `${pct}%`,
            background: "linear-gradient(90deg, #00E5FF 0%, #4DE0FF 100%)",
            boxShadow: "0 0 10px rgba(0,229,255,0.6)",
          }}
        />
      </div>
      <div className="text-zinc-400 text-[10.5px] mt-2">On track for retirement</div>
      <div className="text-white font-bold text-[13px] mt-2 tabular-nums">{goal}</div>
      <div className="text-zinc-500 text-[10px]">Your Goal</div>
    </div>
  );
}

function MatchIcon() {
  return (
    <svg width="18" height="14" viewBox="0 0 18 14" fill="none">
      <circle cx="6" cy="7" r="3" stroke="#00E5FF" strokeWidth="1.4" opacity="0.85" />
      <circle cx="12" cy="7" r="3" stroke="#00E5FF" strokeWidth="1.4" opacity="0.85" />
    </svg>
  );
}

function ScenarioCard({ title, active, balance, income, note, delta }) {
  const stroke = active ? "rgba(0,229,255,0.65)" : "rgba(255,255,255,0.08)";
  const glow   = active ? "0 0 18px rgba(0,229,255,0.35)" : "none";
  return (
    <div
      className="rounded-2xl p-3"
      data-testid={`retirement-scenario-${title.toLowerCase().replace(/\s/g, "-")}`}
      style={{
        background: "rgba(10,14,18,0.9)",
        border: `1px solid ${stroke}`,
        boxShadow: glow,
      }}
    >
      <div className="flex items-center justify-between mb-1.5">
        <span className={`text-[11px] px-2 py-0.5 rounded-full ${active ? "text-volt" : "text-zinc-400"}`}
              style={active ? { background: "rgba(0,229,255,0.1)", border: "1px solid rgba(0,229,255,0.4)" } : {}}>
          {title}
        </span>
        {delta === "up" && <ArrowUp size={12} weight="bold" className="text-volt" />}
        {delta === "down" && <ArrowDown size={12} weight="bold" className="text-rose-400" />}
      </div>
      <div className="chrome-text font-chrome font-bold text-[19px] leading-tight tabular-nums">{balance}</div>
      <div className="text-zinc-400 text-[11px] mt-0.5">{income}</div>
      <div className="text-zinc-500 text-[10px] mt-1">{note}</div>
      {/* mini sparkline */}
      <MiniSpark up={delta !== "down"} />
    </div>
  );
}

function MiniSpark({ up }) {
  const w = 74, h = 28;
  const pts = up
    ? [[0, 24], [12, 22], [24, 20], [36, 17], [48, 13], [60, 9], [74, 4]]
    : [[0, 8],  [12, 11], [24, 14], [36, 16], [48, 19], [60, 22], [74, 24]];
  const d = pts.reduce((acc, p, i) => acc + (i === 0 ? `M${p[0]},${p[1]}` : ` L${p[0]},${p[1]}`), "");
  return (
    <svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} className="mt-1.5" preserveAspectRatio="none">
      <path d={d} fill="none" stroke="#00E5FF" strokeWidth={1.5} strokeLinecap="round"
            style={{ filter: "drop-shadow(0 0 4px rgba(0,229,255,0.6))" }} />
      {pts.map((p, i) => <circle key={i} cx={p[0]} cy={p[1]} r={1.5} fill="#00E5FF" />)}
    </svg>
  );
}

function GlowingTree() {
  return (
    <div
      className="relative w-[130px] h-[130px] flex items-center justify-center"
      style={{ filter: "drop-shadow(0 0 24px rgba(0,229,255,0.55))" }}
    >
      {/* chrome pedestal with M */}
      <div
        className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[100px] h-[24px] rounded-full flex items-center justify-center"
        style={{
          background: "radial-gradient(ellipse at 50% 40%, #E8EBEF 0%, #A0A5AB 40%, #4A4E54 80%, #1E2126 100%)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.6), inset 0 -3px 6px rgba(0,0,0,0.6), 0 4px 10px rgba(0,0,0,0.6)",
        }}
      >
        <span
          style={{
            fontFamily: "'Sora','Inter',sans-serif",
            fontWeight: 900, fontSize: 12,
            background: "linear-gradient(180deg, #FFFFFF 0%, #808388 100%)",
            WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
          }}
        >M</span>
      </div>
      {/* Tree */}
      <svg width="118" height="120" viewBox="0 0 118 120" style={{ marginBottom: 8 }}>
        <defs>
          <radialGradient id="crown" cx="50%" cy="50%" r="60%">
            <stop offset="0%" stopColor="#7BF3FF" />
            <stop offset="60%" stopColor="#00E5FF" />
            <stop offset="100%" stopColor="#00A2C0" stopOpacity="0.85" />
          </radialGradient>
        </defs>
        {/* trunk */}
        <path d="M55 96 L59 65 L63 96 Z" fill="#00E5FF" opacity="0.85" />
        {/* branches (blobs) */}
        <g opacity="0.95" style={{ filter: "drop-shadow(0 0 8px rgba(0,229,255,0.7))" }}>
          <circle cx="59" cy="46" r="26" fill="url(#crown)" />
          <circle cx="38" cy="58" r="18" fill="url(#crown)" />
          <circle cx="80" cy="58" r="18" fill="url(#crown)" />
          <circle cx="45" cy="34" r="12" fill="url(#crown)" />
          <circle cx="72" cy="34" r="12" fill="url(#crown)" />
          <circle cx="59" cy="22" r="10" fill="url(#crown)" />
        </g>
      </svg>
    </div>
  );
}
