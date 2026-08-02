import { useState } from "react";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { CheckCircle, Warning, XCircle, Coins, TrendUp } from "@phosphor-icons/react";

const PLATFORMS = [
  { id: "uber",      name: "UberX",      color: "#000" },
  { id: "lyft",      name: "Lyft",       color: "#FF00BF" },
  { id: "doordash",  name: "DoorDash",   color: "#EB1700" },
  { id: "spark",     name: "Spark",      color: "#0071DC" },
  { id: "instacart", name: "Instacart",  color: "#43B02A" },
];

const DEFAULT_FORM = {
  platform: "uber",
  payout: 18.42,
  trip_miles: 12.4,
  pickup_miles: 2.1,
  deadhead_miles: 2.1,
  return_miles: 3.7,
  duration_min: 34,
  mpg: 26,
  gas_price: 3.85,
  tax_rate: 0.23,
};

function ScoreGauge({ score = 0, label = "" }) {
  const pct = Math.max(0, Math.min(100, score));
  const R = 54, C = 2 * Math.PI * R;
  const dash = (pct / 100) * C;
  const color = pct >= 75 ? "#00E5FF" : pct >= 55 ? "#FFC24C" : "#FF5A6A";
  return (
    <div className="relative w-[128px] h-[128px] shrink-0" data-testid="score-gauge">
      <svg viewBox="0 0 128 128" width="128" height="128">
        <circle cx="64" cy="64" r={R} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="8" />
        <circle
          cx="64" cy="64" r={R} fill="none"
          stroke={color} strokeWidth="8" strokeLinecap="round"
          strokeDasharray={`${dash} ${C}`}
          transform="rotate(-90 64 64)"
          style={{ filter: `drop-shadow(0 0 6px ${color})`, transition: "stroke-dasharray 0.6s ease" }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="font-chrome font-bold text-4xl tabular-nums" style={{ color }}>{pct}</div>
        <div className="text-[10px] uppercase tracking-widest text-zinc-500">/100</div>
        <div className="text-[10px] uppercase tracking-widest mt-0.5" style={{ color }}>{label}</div>
      </div>
    </div>
  );
}

export default function MilliCents() {
  const [form, setForm] = useState(DEFAULT_FORM);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  function set(k, v) { setForm((f) => ({ ...f, [k]: v })); }

  async function analyze() {
    setLoading(true);
    try {
      const r = await api.post("/milli-cents/score", form);
      setResult(r.data);
    } catch (e) {
      toast.error(e?.response?.data?.detail || "Scoring failed");
    } finally {
      setLoading(false);
    }
  }

  const platform = PLATFORMS.find((p) => p.id === form.platform) || PLATFORMS[0];
  const verdictBadge = result?.verdict === "accept"   ? { label: "GO", color: "#00E5FF", Icon: CheckCircle }
                    : result?.verdict === "marginal" ? { label: "MARGINAL", color: "#FFC24C", Icon: Warning }
                    : result?.verdict === "decline"  ? { label: "SKIP", color: "#FF5A6A", Icon: XCircle }
                    : null;

  return (
    <div className="p-4 sm:p-6 max-w-3xl mx-auto">
      <div className="mb-5">
        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.3em] flex items-center gap-1.5">
          <Coins size={12} weight="fill" /> Milli Cents
        </div>
        <h1 className="font-display font-black text-3xl tracking-tighter mt-1 leading-[1.05]">
          Milli Cents
        </h1>
        <p className="text-zinc-400 text-sm mt-1">Offer Profitability Engine — know which offer is actually worth it.</p>
      </div>

      {/* Live Offer Analysis card */}
      <div
        className="rounded-3xl p-5 mb-5 border border-volt/40 relative overflow-hidden"
        style={{ background: "radial-gradient(120% 80% at 0% 0%, rgba(0,229,255,0.12) 0%, rgba(0,0,0,0) 60%), #06080B",
                 boxShadow: "0 0 32px rgba(0,229,255,0.18)" }}
        data-testid="milli-cents-card"
      >
        <div className="flex items-center justify-between mb-3">
          <div className="text-volt font-mono text-[10px] uppercase tracking-[0.28em]">Live Offer Analysis</div>
          <div className="text-[10px] px-2 py-0.5 rounded-full border border-emerald-400/40 text-emerald-400 font-bold tracking-widest uppercase">LIVE</div>
        </div>
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1">
            <div className="flex items-center gap-2.5 mb-1">
              <div className="w-9 h-9 rounded-lg flex items-center justify-center text-white font-black text-xs" style={{ background: platform.color }}>
                {platform.name.slice(0, 4)}
              </div>
              <div>
                <div className="font-display text-lg leading-none">{platform.name}</div>
                <div className="text-[11px] text-zinc-500">{form.trip_miles} mi · ${form.payout.toFixed(2)}</div>
              </div>
            </div>
            <div className="font-chrome font-bold text-5xl mt-2">${(result?.payout ?? form.payout).toFixed(2)}</div>
            <div className="text-[11px] text-zinc-500 uppercase tracking-widest mt-1">Est. Total Payout</div>
          </div>
          <ScoreGauge score={result?.score ?? 0} label={result?.label ?? "—"} />
        </div>

        {/* Breakdown table */}
        <div className="mt-5 divide-y divide-white/[0.06] text-[13px]">
          {[
            ["Trip Distance",    `${form.trip_miles} mi`,   "—"],
            ["Pickup Distance",  `${form.pickup_miles} mi`, `$${result ? result.gas_cost.toFixed(2) : "—"}`],
            ["Deadhead",         `${form.deadhead_miles} mi`, "—"],
            ["Return",           `${form.return_miles} mi`, "—"],
            ["Gas Used",         `${result ? result.gas_used_gal : "—"} gal`, `$${result ? result.gas_cost.toFixed(2) : "—"}`],
            ["Wear & Tear",      "—",                       `$${result ? result.wear_cost.toFixed(2) : "—"}`],
            [`Est. Taxes (${(form.tax_rate*100)|0}%)`, "—", `$${result ? result.tax_cost.toFixed(2) : "—"}`],
          ].map(([l, m, r]) => (
            <div key={l} className="flex items-center justify-between py-2">
              <div className="text-zinc-400">{l}</div>
              <div className="text-zinc-500 text-right flex-1 mx-3 tabular-nums">{m}</div>
              <div className="text-white tabular-nums">{r}</div>
            </div>
          ))}
          <div className="flex items-center justify-between py-2 font-semibold">
            <div className="text-white">Total Est. Cost</div>
            <div className="text-white tabular-nums">${result ? result.total_cost.toFixed(2) : "—"}</div>
          </div>
          <div className="flex items-center justify-between py-2 font-bold">
            <div className="text-volt">Projected Net Profit</div>
            <div className="text-volt tabular-nums text-lg">${result ? result.net_profit.toFixed(2) : "—"}</div>
          </div>
        </div>

        {verdictBadge && (
          <div className="mt-4 flex items-center gap-3 px-4 py-3 rounded-2xl border" style={{ borderColor: `${verdictBadge.color}66`, background: `${verdictBadge.color}11` }}>
            <verdictBadge.Icon size={22} weight="fill" style={{ color: verdictBadge.color }} />
            <div className="flex-1">
              <div className="font-black text-xl leading-none" style={{ color: verdictBadge.color }}>{verdictBadge.label}</div>
              <div className="text-[11px] text-zinc-400 mt-0.5">
                {verdictBadge.label === "GO"       ? "This offer meets your goals." :
                 verdictBadge.label === "MARGINAL" ? "Only if you're near the pickup." :
                                                    "Time and gas eat the profit."}
              </div>
            </div>
            <TrendUp size={20} className="text-zinc-500" />
          </div>
        )}
      </div>

      {/* Inputs */}
      <div className="milli-card p-4">
        <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500 mb-3">Offer inputs</div>
        <div className="grid grid-cols-2 gap-2.5">
          <label className="text-xs">
            <div className="text-zinc-500 mb-1 uppercase tracking-wider text-[10px]">Platform</div>
            <select value={form.platform} onChange={(e) => set("platform", e.target.value)} className="w-full bg-black/40 border border-white/[0.08] rounded-lg px-2 py-2 text-sm">
              {PLATFORMS.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </label>
          {[
            ["Payout $", "payout"],
            ["Trip miles", "trip_miles"],
            ["Pickup miles", "pickup_miles"],
            ["Deadhead miles", "deadhead_miles"],
            ["Return miles", "return_miles"],
            ["Duration (min)", "duration_min"],
            ["MPG", "mpg"],
            ["Gas $ / gal", "gas_price"],
          ].map(([label, key]) => (
            <label key={key} className="text-xs">
              <div className="text-zinc-500 mb-1 uppercase tracking-wider text-[10px]">{label}</div>
              <input
                type="number" step="0.1" value={form[key]}
                data-testid={`mc-input-${key}`}
                onChange={(e) => set(key, parseFloat(e.target.value) || 0)}
                className="w-full bg-black/40 border border-white/[0.08] rounded-lg px-2 py-2 text-sm tabular-nums"
              />
            </label>
          ))}
        </div>
        <button
          data-testid="mc-analyze"
          onClick={analyze}
          disabled={loading}
          className="mt-4 w-full btn-volt py-3 uppercase tracking-widest text-sm font-bold rounded-xl disabled:opacity-50"
        >
          {loading ? "Scoring..." : "Analyze offer"}
        </button>
      </div>
    </div>
  );
}
