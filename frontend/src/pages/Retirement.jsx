import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/context/AuthContext";
import { CaretDown, ArrowUp, ArrowDown, Info, LockKey, Target } from "@phosphor-icons/react";
import ChromeBonsai from "@/components/ChromeBonsai";
import BloomPetals from "@/components/BloomPetals";
import { api } from "@/lib/api";

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
  const { user } = useAuth();
  const isElite = user?.plan === "elite";
  const firstName = user?.name?.split(" ")[0] || "friend";
  const currentYear = new Date().getFullYear();
  const [range, setRange] = useState("10 Years");
  const [viewBy, setViewBy] = useState("Future Value");
  const [detailScenario, setDetailScenario] = useState(null);
  const [goals, setGoals] = useState({
    retirement_year: user?.retirement_year || (new Date().getFullYear() + 30),
    target_income:   user?.retirement_target_income || 10000,
    goal_notes:      user?.retirement_goal_notes || "",
    account_type:    user?.retirement_account_type || "roth_ira",
    contribution_pct: user?.retirement_contribution_pct ?? 15,
  });

  const projected = 2652113;
  const today = 1412020;
  const delta = projected - today;
  const deltaPct = Math.round((delta / today) * 100);
  // 4% rule (Trinity study): safe annual withdrawal = 4% of nest egg
  const estMonthlyIncome = Math.round(projected * 0.04 / 12);

  // Bonsai growth reflects vault progress toward the annual tax goal —
  // the tree grows and blooms as Jordan's Milli Tax Vault™ climbs milestones.
  // Fetch-once on mount — subsequent updates come via a full page navigation.
  const [bonsaiProgress, setBonsaiProgress] = useState(0);
  useEffect(() => {
    let alive = true;
    api.get("/tax/summary").then(({ data }) => {
      if (!alive) return;
      const bal  = Number(data?.savings_balance || 0);
      const goal = Number(data?.tax_goal || 20000);
      setBonsaiProgress(Math.max(0, Math.min(1, bal / Math.max(1, goal))));
    }).catch((e) => { console.debug("[Retirement] tax summary fetch:", e); });
    return () => { alive = false; };
  }, []);

  // ============ BLOOM CONFETTI on new bonsai milestone ============
  // Fires cyan petals the moment Jordan crosses 25 / 50 / 75 / 100 % for the
  // FIRST time. Highest tier reached is persisted per-user so a re-fetch after
  // reload does not refire an already-celebrated tier.
  const [petalsKey, setPetalsKey] = useState(0);
  const petalsTimer = useRef(null);
  useEffect(() => {
    if (!bonsaiProgress) return;
    const tier = bonsaiProgress >= 1 ? 4 : bonsaiProgress >= 0.75 ? 3
               : bonsaiProgress >= 0.5 ? 2 : bonsaiProgress >= 0.25 ? 1 : 0;
    if (tier === 0) return;
    const storageKey = `milli_bonsai_tier_${user?.id || "self"}`;
    let prev = 0;
    try { prev = parseInt(localStorage.getItem(storageKey) || "0", 10); } catch { /* storage off */ }
    if (tier > prev) {
      try { localStorage.setItem(storageKey, String(tier)); } catch { /* storage off */ }
      setPetalsKey(k => k + 1);
      try { navigator.vibrate && navigator.vibrate([8, 40, 8, 40, 8]); } catch { /* haptics off */ }
      clearTimeout(petalsTimer.current);
      petalsTimer.current = setTimeout(() => setPetalsKey(0), 3400);
    }
    return () => clearTimeout(petalsTimer.current);
  }, [bonsaiProgress, user?.id]);

  const SCENARIOS = [
    { id: "current",  title: "Current Plan",    active: true,  balance_num: projected,          contribution_pct: goals.contribution_pct, note: "10 yr forecast" },
    { id: "increase", title: "Increase to 20%", active: false, balance_num: 3_350_000,          contribution_pct: 20, delta: "up",   note: "10 yr forecast" },
    { id: "delay",    title: "Delay 2 Years",   active: false, balance_num: 2_050_000,          contribution_pct: goals.contribution_pct, delta: "down", note: "10 yr forecast" },
  ];

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">
      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          {firstName}&apos;s Retirement
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1" data-testid="retirement-subheader">
          Retire in <span className="text-white/90 font-semibold">{Math.max(0, goals.retirement_year - currentYear)} years</span> · target ${Number(goals.target_income).toLocaleString("en-US")}/mo
        </p>
      </header>

      {petalsKey > 0 && <BloomPetals key={petalsKey} testid="retirement-bloom-petals" />}

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
        <div className="absolute top-2 right-2 pointer-events-none" data-testid="retirement-chrome-bonsai">
          <ChromeBonsai size={148} progress={bonsaiProgress} />
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
          {/* Milestone-locked bonsai stage caption */}
          <div
            className="mt-2 inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10.5px] font-semibold tracking-wider uppercase"
            data-testid="retirement-bonsai-stage"
            style={{
              background: "rgba(0,229,255,0.08)",
              border: "1px solid rgba(0,229,255,0.35)",
              color: "#7BF3FF",
              textShadow: "0 0 6px rgba(0,229,255,0.35)",
            }}
            title={`Bonsai grows with your Milli Tax Vault™ balance · currently ${Math.round(bonsaiProgress * 100)}% of tax goal`}
          >
            {(() => {
              const p = bonsaiProgress;
              const s = p >= 1 ? "Crowned · 10 blooms"
                     : p >= 0.75 ? "Blooming · 7 blooms"
                     : p >= 0.5  ? "Branching · 4 blooms"
                     : p >= 0.25 ? "Young · 2 blooms"
                     : "Sapling";
              return `Bonsai · ${s}`;
            })()}
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
        <ContribCard
          label="Your Contribution"
          pct={goals.contribution_pct}
          money={`$${Math.round((goals.contribution_pct/100) * 60000 / 12).toLocaleString()}/mo`}
          ringPct={Math.min(100, goals.contribution_pct * 5)}
        />
        <ContribCard
          label="Employer Match"
          pct={isElite ? 5 : 0}
          money={isElite ? "$413/mo" : "Coming Soon"}
          ringPct={isElite ? 25 : 0}
          icon="match"
          soon={!isElite}
        />
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
              ${estMonthlyIncome.toLocaleString("en-US")}
              <span className="text-white/50 text-[16px]">/mo</span>
            </div>
            <div className="text-zinc-500 text-[12px] mt-1">
              4% rule · at retirement · ~{Math.round((estMonthlyIncome / (goals.target_income || 1)) * 100)}% of goal
            </div>
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

      {/* Retirement Goals — user's long-term plan */}
      <RetirementGoalsCard goals={goals} setGoals={setGoals} />

      {/* 6 · Scenario Comparison */}
      <section className="milli-card rounded-2xl p-5" data-testid="retirement-scenarios-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[16px]">Scenario Comparison</h2>
          <button
            onClick={() => setDetailScenario(SCENARIOS.find(s => s.active) || SCENARIOS[0])}
            data-testid="retirement-scenarios-viewdetails"
            className="text-volt text-[13.5px] font-semibold active:opacity-70"
            style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}
          >
            View details &rsaquo;
          </button>
        </div>
        <div className="grid grid-cols-3 gap-2.5">
          {SCENARIOS.map((s) => (
            <ScenarioCard
              key={s.id}
              title={s.title}
              active={s.active}
              balance={fmtMoneyMillions(s.balance_num)}
              income={`$${Math.round(s.balance_num * 0.04 / 12).toLocaleString()}/mo`}
              note={s.note}
              delta={s.delta}
              onClick={() => setDetailScenario(s)}
              testid={`retirement-scenario-${s.id}`}
            />
          ))}
        </div>
      </section>

      {/* Scenario detail modal */}
      {detailScenario && (
        <ScenarioDetailModal scenario={detailScenario} onClose={() => setDetailScenario(null)} estIncome={Math.round(detailScenario.balance_num * 0.04 / 12)} />
      )}
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
            {points.map((p) => (
              <circle key={`pt-${p.x}-${p.y}`} cx={p.x} cy={p.y} r={3} fill="#00E5FF" stroke="#05070A" strokeWidth={1.5} />
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

function ContribCard({ label, pct, money, ringPct, icon, soon }) {
  const size = 44, stroke = 4, r = (size - stroke) / 2, c = 2 * Math.PI * r;
  const off = c - (ringPct / 100) * c;
  return (
    <div className="milli-card rounded-2xl p-3 relative" data-testid={`retirement-contrib-${label.toLowerCase().replace(/\s/g, "-")}`}>
      {soon && (
        <span className="absolute -top-1.5 right-2 text-[9px] font-bold px-1.5 py-0.5 rounded-full"
              style={{ background: "rgba(255,204,51,0.12)", border: "1px solid rgba(255,204,51,0.55)",
                       color: "#FFCC33", letterSpacing: "0.05em" }}>
          ELITE
        </span>
      )}
      <div className="text-zinc-400 text-[11.5px]">{label}</div>
      <div className="flex items-end justify-between mt-1">
        <div className={`chrome-text font-chrome font-bold text-[26px] leading-none tabular-nums ${soon ? "opacity-40" : ""}`}>
          {soon ? "—" : `${pct}%`}
        </div>
        {icon === "match" ? (
          <div className="w-10 h-10 rounded-full bg-white/[0.05] border border-white/10 flex items-center justify-center">
            {soon ? <LockKey size={14} weight="regular" className="text-zinc-500" /> : <MatchIcon />}
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
      <div className={`text-zinc-400 text-[11.5px] mt-1 ${soon ? "text-amber-300/80 font-semibold" : ""}`}>{money}</div>
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

function ScenarioCard({ title, active, balance, income, note, delta, onClick, testid }) {
  const stroke = active ? "rgba(0,229,255,0.65)" : "rgba(255,255,255,0.08)";
  const glow   = active ? "0 0 18px rgba(0,229,255,0.35)" : "none";
  return (
    <button
      onClick={onClick}
      className="rounded-2xl p-3 text-left active:scale-[0.98] transition-transform"
      data-testid={testid || `retirement-scenario-${title.toLowerCase().replace(/\s/g, "-")}`}
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
    </button>
  );
}

function fmtMoneyMillions(v) {
  if (v >= 1_000_000) return `$${(v/1_000_000).toFixed(2)}M`;
  if (v >= 1_000) return `$${(v/1_000).toFixed(0)}K`;
  return `$${v}`;
}

/* Interactive scenario detail modal */
function ScenarioDetailModal({ scenario, onClose, estIncome }) {
  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-end sm:items-center justify-center p-3" onClick={onClose} data-testid="retirement-scenario-modal">
      <div onClick={(e) => e.stopPropagation()}
           className="w-full max-w-md rounded-3xl p-5"
           style={{
             background: "linear-gradient(180deg, rgba(15,18,22,0.98) 0%, rgba(5,7,10,0.98) 100%)",
             border: "1px solid rgba(0,229,255,0.35)",
             boxShadow: "0 0 40px rgba(0,229,255,0.25), 0 30px 80px rgba(0,0,0,0.7)",
           }}>
        <div className="flex items-center justify-between mb-4">
          <div>
            <div className="font-mono text-[10.5px] uppercase tracking-[0.28em] text-volt" style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
              Scenario
            </div>
            <h3 className="chrome-text font-chrome font-bold text-[22px] mt-1">{scenario.title}</h3>
          </div>
          <button onClick={onClose} data-testid="retirement-scenario-modal-close" className="w-9 h-9 rounded-full bg-white/[0.06] flex items-center justify-center active:opacity-60">
            <span className="text-white text-[18px] leading-none">×</span>
          </button>
        </div>

        <div className="milli-card rounded-2xl p-4 mb-3">
          <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest">Projected balance</div>
          <div className="chrome-text font-chrome font-bold text-[32px] leading-none tabular-nums mt-1">
            ${scenario.balance_num.toLocaleString("en-US")}
          </div>
          <div className="text-zinc-400 text-[12.5px] mt-1">at age 65 · 10 yr forecast</div>
        </div>

        <div className="grid grid-cols-2 gap-3 mb-3">
          <div className="milli-card rounded-xl p-3">
            <div className="text-zinc-500 text-[10px] uppercase tracking-widest">Monthly income</div>
            <div className="chrome-text font-chrome font-bold text-[18px] tabular-nums mt-1">${estIncome.toLocaleString()}</div>
            <div className="text-zinc-500 text-[10.5px] mt-1">4% withdrawal rule</div>
          </div>
          <div className="milli-card rounded-xl p-3">
            <div className="text-zinc-500 text-[10px] uppercase tracking-widest">Contribution</div>
            <div className="chrome-text font-chrome font-bold text-[18px] tabular-nums mt-1">{scenario.contribution_pct}%</div>
            <div className="text-zinc-500 text-[10.5px] mt-1">of pre-tax income</div>
          </div>
        </div>

        <ul className="text-zinc-300 text-[13px] space-y-2 mb-4">
          <li className="flex gap-2"><span className="text-volt">•</span> Assumes 7% average annual return</li>
          <li className="flex gap-2"><span className="text-volt">•</span> Contributions increase 3%/year with inflation</li>
          <li className="flex gap-2"><span className="text-volt">•</span> Tax-advantaged growth ({scenario.title === "Delay 2 Years" ? "starts in 2 years" : "starts today"})</li>
          {scenario.delta === "up"   && <li className="flex gap-2 text-volt"><span>✓</span> This scenario reaches your goal $700K earlier.</li>}
          {scenario.delta === "down" && <li className="flex gap-2 text-rose-300"><span>⚠</span> This scenario is $600K short of the Current Plan.</li>}
        </ul>

        <button onClick={onClose} data-testid="retirement-scenario-modal-done"
                className="w-full rounded-xl py-3 font-bold text-[13px] text-obsidian active:brightness-95"
                style={{ background: "linear-gradient(180deg, #00E5FF 0%, #00B4D0 100%)",
                         boxShadow: "0 0 20px rgba(0,229,255,0.5), inset 0 1px 0 rgba(255,255,255,0.5)" }}>
          Got it
        </button>
      </div>
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
      {pts.map((p) => <circle key={`sp-${p[0]}-${p[1]}`} cx={p[0]} cy={p[1]} r={1.5} fill="#00E5FF" />)}
    </svg>
  );
}

function GlowingTree() { return null; /* deprecated: see ChromeBonsai */ }

/* ===================== Retirement Goals ===================== */
function RetirementGoalsCard({ goals, setGoals }) {
  const [editing, setEditing] = useState(false);
  const currentAge = 35;
  const yearsLeft = Math.max(0, goals.retirement_year - new Date().getFullYear());
  const targetAge = currentAge + yearsLeft;

  async function save() {
    try {
      const { api } = await import("@/lib/api");
      await api.put("/auth/profile", {
        retirement_year: parseInt(goals.retirement_year),
        retirement_target_income: parseFloat(goals.target_income),
        retirement_goal_notes: goals.goal_notes,
        retirement_account_type: goals.account_type,
        retirement_contribution_pct: parseFloat(goals.contribution_pct),
      });
      const { toast } = await import("sonner");
      toast.success("Goals saved");
    } catch (e) {
      // Backend rejected the save — keep the local optimistic update but log for diagnosis
      console.warn("[Retirement] Goals save failed, keeping local state:", e);
    }
    setEditing(false);
  }

  return (
    <section className="milli-card rounded-2xl p-5" data-testid="retirement-goals-card">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Target size={16} weight="fill" className="text-volt"
                  style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.55))" }} />
          <h2 className="text-white font-semibold text-[16px]">Your Retirement Goals</h2>
        </div>
        <button onClick={() => (editing ? save() : setEditing(true))}
                data-testid="retirement-goals-edit"
                className="text-volt text-[13px] font-semibold"
                style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
          {editing ? "Save" : "Edit"}
        </button>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="milli-card rounded-xl p-3">
          <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest">Retire in year</div>
          {editing ? (
            <input
              data-testid="retirement-year-input"
              type="number" min={new Date().getFullYear()} max={new Date().getFullYear()+80}
              value={goals.retirement_year}
              onChange={(e) => setGoals({...goals, retirement_year: e.target.value})}
              className="w-full bg-transparent chrome-text font-chrome font-bold text-[22px] tabular-nums mt-1 focus:outline-none"
            />
          ) : (
            <div className="chrome-text font-chrome font-bold text-[22px] tabular-nums mt-1">{goals.retirement_year}</div>
          )}
          <div className="text-zinc-500 text-[11px] mt-1">Age {targetAge} · {yearsLeft} yrs away</div>
        </div>
        <div className="milli-card rounded-xl p-3">
          <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest">Target monthly income</div>
          {editing ? (
            <div className="flex items-center gap-1 mt-1">
              <span className="chrome-text font-chrome font-bold text-[22px]">$</span>
              <input
                data-testid="retirement-income-input"
                type="number" min="0" step="500"
                value={goals.target_income}
                onChange={(e) => setGoals({...goals, target_income: e.target.value})}
                className="flex-1 bg-transparent chrome-text font-chrome font-bold text-[22px] tabular-nums focus:outline-none"
              />
            </div>
          ) : (
            <div className="chrome-text font-chrome font-bold text-[22px] tabular-nums mt-1">
              ${Number(goals.target_income).toLocaleString()}
            </div>
          )}
          <div className="text-zinc-500 text-[11px] mt-1">Post-retirement lifestyle</div>
        </div>
      </div>

      <div className="mt-3">
        <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest mb-1.5">Long-term goals</div>
        {editing ? (
          <textarea
            data-testid="retirement-notes-input"
            rows={3}
            placeholder="Buy a house, travel, kids' college, second home in Costa Rica…"
            value={goals.goal_notes}
            onChange={(e) => setGoals({...goals, goal_notes: e.target.value})}
            className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2 text-white text-[13px] focus:outline-none focus:border-volt resize-none"
          />
        ) : (
          <div className="text-white text-[13px] leading-relaxed min-h-[40px]">
            {goals.goal_notes || <span className="text-zinc-600 italic">Tap Edit to add your long-term goals.</span>}
          </div>
        )}
      </div>

      {/* Account type + Contribution % */}
      <div className="mt-4 pt-4 border-t border-white/[0.06]">
        <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest mb-2">Account Type</div>
        <div className="grid grid-cols-3 gap-2">
          {[
            { id: "roth_ira",        label: "Roth IRA",        hint: "Tax-free growth" },
            { id: "traditional_ira", label: "Traditional IRA", hint: "Tax deferred" },
            { id: "sep_ira",         label: "SEP IRA",         hint: "For 1099 self-emp." },
            { id: "solo_401k",       label: "Solo 401(k)",     hint: "Highest limit" },
            { id: "hsa",             label: "HSA",             hint: "Triple tax-free" },
            { id: "taxable",         label: "Brokerage",       hint: "Post-tax" },
          ].map((a) => {
            const active = goals.account_type === a.id;
            return (
              <button
                key={a.id}
                onClick={() => editing && setGoals({...goals, account_type: a.id})}
                disabled={!editing}
                data-testid={`retirement-account-${a.id}`}
                className="rounded-xl p-2.5 text-center transition-all disabled:cursor-not-allowed"
                style={{
                  background: active ? "rgba(0,229,255,0.10)" : "rgba(10,14,18,0.6)",
                  border: active ? "1px solid rgba(0,229,255,0.6)" : "1px solid rgba(255,255,255,0.06)",
                  boxShadow: active ? "0 0 14px rgba(0,229,255,0.3)" : "none",
                  opacity: editing ? 1 : (active ? 1 : 0.55),
                }}
              >
                <div className={`text-[12px] font-semibold ${active ? "text-volt" : "text-white"}`}>{a.label}</div>
                <div className="text-zinc-500 text-[9.5px] mt-0.5">{a.hint}</div>
              </button>
            );
          })}
        </div>

        <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest mt-4 mb-2 flex items-center justify-between">
          <span>Contribution</span>
          <span className="text-volt font-bold text-[13px] tabular-nums normal-case tracking-normal"
                style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
            {goals.contribution_pct}%
          </span>
        </div>
        <input
          data-testid="retirement-contribution-slider"
          type="range" min="0" max="30" step="1"
          value={goals.contribution_pct}
          onChange={(e) => editing && setGoals({...goals, contribution_pct: e.target.value})}
          disabled={!editing}
          className="w-full accent-volt cursor-pointer disabled:cursor-not-allowed"
        />
        <div className="flex justify-between text-[10px] text-zinc-500 tabular-nums mt-1 uppercase tracking-widest">
          <span>0%</span><span>10%</span><span>20%</span><span>30%</span>
        </div>
      </div>
    </section>
  );
}

