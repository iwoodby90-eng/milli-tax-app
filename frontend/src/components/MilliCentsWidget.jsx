import { useState, useMemo } from "react";
import { calculateProfit, verdict } from "@/lib/milli-cents";
import { Gauge, CurrencyDollar, GasPump, Car, Percent, MapPin, ArrowRight } from "@phosphor-icons/react";

/**
 * Milli-Cents Profitability Widget
 * Style: Industrial-Noir with Bel Air Gauge (circular chrome speedo aesthetic)
 * Gated: Pro/Elite users only (gating enforced at route level in Dashboard)
 */

const VERDICT_COLORS = {
  ACCEPT: { ring: "#00E5FF", glow: "rgba(0,229,255,0.35)", label: "ACCEPT", bg: "rgba(0,229,255,0.08)" },
  MARGINAL: { ring: "#FFB800", glow: "rgba(255,184,0,0.30)", label: "MARGINAL", bg: "rgba(255,184,0,0.06)" },
  DECLINE: { ring: "#FF3B5C", glow: "rgba(255,59,92,0.30)", label: "DECLINE", bg: "rgba(255,59,92,0.06)" },
};

export default function MilliCentsWidget({ onClose }) {
  const [form, setForm] = useState({
    offerPrice: "",
    tripDistance: "",
    deadheadDistance: "",
    gasPrice: "3.49",
    vehicleMpg: "28",
    taxSlice: "25",
  });

  const parsed = useMemo(() => ({
    offerPrice: parseFloat(form.offerPrice) || 0,
    tripDistance: parseFloat(form.tripDistance) || 0,
    deadheadDistance: parseFloat(form.deadheadDistance) || 0,
    gasPrice: parseFloat(form.gasPrice) || 0,
    vehicleMpg: parseFloat(form.vehicleMpg) || 1,
    taxSlice: (parseFloat(form.taxSlice) || 0) / 100,
  }), [form]);

  const result = useMemo(() => calculateProfit(parsed), [parsed]);
  const vrd = verdict(result);
  const colors = VERDICT_COLORS[vrd];

  const hasInput = parsed.offerPrice > 0 && parsed.tripDistance > 0;

  function update(field) {
    return (e) => setForm((f) => ({ ...f, [field]: e.target.value }));
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ backgroundColor: "rgba(0,0,0,0.85)" }}>
      <div
        className="w-full max-w-md rounded-3xl border border-zinc-800 overflow-hidden"
        style={{ backgroundColor: "#0a0b0d", boxShadow: "0 0 80px rgba(0,229,255,0.06)" }}
      >
        {/* Header */}
        <div className="px-6 pt-6 pb-4 flex items-center justify-between border-b border-zinc-800/60">
          <div className="flex items-center gap-3">
            <Gauge size={22} weight="duotone" className="text-volt" />
            <div>
              <div className="font-display text-sm tracking-[0.2em] text-white uppercase">Milli-Cents</div>
              <div className="text-[10px] text-zinc-500 font-mono tracking-wider">// PROFITABILITY ENGINE v1.9</div>
            </div>
          </div>
          {onClose && (
            <button
              onClick={onClose}
              className="text-zinc-500 hover:text-white text-lg font-mono transition-colors"
              aria-label="Close"
            >
              ✕
            </button>
          )}
        </div>

        {/* Bel Air Gauge */}
        <div className="flex justify-center py-8">
          <BelAirGauge margin={hasInput ? result.profitMargin : 0} colors={colors} active={hasInput} />
        </div>

        {/* Verdict */}
        {hasInput && (
          <div className="text-center -mt-4 mb-6">
            <span
              className="inline-block px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-[0.25em] font-mono"
              style={{ backgroundColor: colors.bg, color: colors.ring, border: `1px solid ${colors.ring}40` }}
            >
              {colors.label}
            </span>
            <div className="mt-2 text-zinc-400 text-sm font-mono">
              Net Profit: <span className="text-white font-semibold">${result.profit.toFixed(2)}</span>
              <span className="text-zinc-600 mx-2">|</span>
              Fuel: <span className="text-zinc-300">${result.fuelCost.toFixed(2)}</span>
              <span className="text-zinc-600 mx-2">|</span>
              Tax: <span className="text-zinc-300">${result.taxOwed.toFixed(2)}</span>
            </div>
          </div>
        )}

        {/* Input Form */}
        <div className="px-6 pb-6 grid grid-cols-2 gap-3">
          <InputField
            icon={CurrencyDollar}
            label="Offer $"
            value={form.offerPrice}
            onChange={update("offerPrice")}
            placeholder="12.50"
            testid="mc-offer"
          />
          <InputField
            icon={MapPin}
            label="Trip mi"
            value={form.tripDistance}
            onChange={update("tripDistance")}
            placeholder="8.2"
            testid="mc-trip"
          />
          <InputField
            icon={ArrowRight}
            label="Deadhead mi"
            value={form.deadheadDistance}
            onChange={update("deadheadDistance")}
            placeholder="3.0"
            testid="mc-deadhead"
          />
          <InputField
            icon={GasPump}
            label="Gas $/gal"
            value={form.gasPrice}
            onChange={update("gasPrice")}
            placeholder="3.49"
            testid="mc-gas"
          />
          <InputField
            icon={Car}
            label="MPG"
            value={form.vehicleMpg}
            onChange={update("vehicleMpg")}
            placeholder="28"
            testid="mc-mpg"
          />
          <InputField
            icon={Percent}
            label="Tax %"
            value={form.taxSlice}
            onChange={update("taxSlice")}
            placeholder="25"
            testid="mc-tax"
          />
        </div>

        {/* Cost per mile footer */}
        {hasInput && (
          <div className="px-6 pb-6 flex items-center justify-between text-xs text-zinc-500 font-mono border-t border-zinc-800/60 pt-4">
            <span>Cost/mile: <span className="text-zinc-300">${result.costPerMile.toFixed(2)}</span></span>
            <span>Total miles: <span className="text-zinc-300">{result.totalMiles}</span></span>
          </div>
        )}
      </div>
    </div>
  );
}

/**
 * Bel Air Gauge — Circular chrome speedometer inspired by 1954 Chevy Bel Air.
 * Shows profit margin 0-100% with gradient arc and needle.
 */
function BelAirGauge({ margin, colors, active }) {
  const clampedMargin = Math.max(-100, Math.min(100, margin));
  // Map -100..100 to 0..1 for the arc (center at 0.5 for 0%)
  const normalized = active ? (clampedMargin + 100) / 200 : 0;

  // Arc geometry: 240-degree sweep (-210 to 30 degrees)
  const startAngle = -210;
  const endAngle = 30;
  const sweepTotal = endAngle - startAngle; // 240
  const needleAngle = startAngle + normalized * sweepTotal;

  const r = 70;
  const cx = 90;
  const cy = 90;

  // Arc path for background
  const arcPath = describeArc(cx, cy, r, startAngle, endAngle);
  // Arc path for filled portion
  const filledEnd = startAngle + normalized * sweepTotal;
  const filledPath = normalized > 0 ? describeArc(cx, cy, r, startAngle, filledEnd) : "";

  // Needle endpoint
  const needleR = r - 18;
  const nx = cx + needleR * Math.cos((needleAngle * Math.PI) / 180);
  const ny = cy + needleR * Math.sin((needleAngle * Math.PI) / 180);

  // Tick marks
  const ticks = [0, 0.25, 0.5, 0.75, 1].map((pct) => {
    const angle = startAngle + pct * sweepTotal;
    const outerR = r + 6;
    const innerR = r - 6;
    return {
      x1: cx + outerR * Math.cos((angle * Math.PI) / 180),
      y1: cy + outerR * Math.sin((angle * Math.PI) / 180),
      x2: cx + innerR * Math.cos((angle * Math.PI) / 180),
      y2: cy + innerR * Math.sin((angle * Math.PI) / 180),
    };
  });

  return (
    <div className="relative w-[180px] h-[180px]">
      {/* Chrome bezel ring */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          background: "conic-gradient(from 0deg, #2a2a2a, #555, #2a2a2a, #444, #2a2a2a)",
          padding: "4px",
        }}
      >
        <div className="w-full h-full rounded-full" style={{ backgroundColor: "#0a0b0d" }} />
      </div>

      {/* SVG gauge face */}
      <svg width="180" height="180" viewBox="0 0 180 180" className="absolute inset-0">
        {/* Tick marks */}
        {ticks.map((t, i) => (
          <line key={i} x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2} stroke="#555" strokeWidth="2" strokeLinecap="round" />
        ))}

        {/* Background arc */}
        <path d={arcPath} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="6" strokeLinecap="round" />

        {/* Filled arc */}
        {filledPath && (
          <path
            d={filledPath}
            fill="none"
            stroke={colors.ring}
            strokeWidth="6"
            strokeLinecap="round"
            style={{
              filter: `drop-shadow(0 0 6px ${colors.glow})`,
              transition: "d 600ms cubic-bezier(0.4, 0, 0.2, 1)",
            }}
          />
        )}

        {/* Needle */}
        {active && (
          <>
            <line
              x1={cx}
              y1={cy}
              x2={nx}
              y2={ny}
              stroke={colors.ring}
              strokeWidth="2.5"
              strokeLinecap="round"
              style={{
                filter: `drop-shadow(0 0 4px ${colors.glow})`,
                transition: "all 600ms cubic-bezier(0.4, 0, 0.2, 1)",
              }}
            />
            {/* Needle hub */}
            <circle cx={cx} cy={cy} r="5" fill="#1a1a1a" stroke={colors.ring} strokeWidth="1.5" />
          </>
        )}

        {/* Center chrome dot */}
        <circle cx={cx} cy={cy} r="3" fill="#666" />
      </svg>

      {/* Center readout */}
      <div className="absolute inset-0 flex flex-col items-center justify-center pt-6">
        <div
          className="font-chrome font-bold text-2xl"
          style={{ color: active ? colors.ring : "#444", transition: "color 400ms" }}
        >
          {active ? `${Math.round(clampedMargin)}%` : "—"}
        </div>
        <div className="text-[9px] font-mono uppercase tracking-[0.3em] text-zinc-500 mt-0.5">
          margin
        </div>
      </div>
    </div>
  );
}

function InputField({ icon: Icon, label, value, onChange, placeholder, testid }) {
  return (
    <div className="relative">
      <label className="text-[9px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1 block">{label}</label>
      <div className="flex items-center gap-2 rounded-xl border border-zinc-800 bg-zinc-900/50 px-3 py-2.5 focus-within:border-volt/40 transition-colors">
        <Icon size={14} weight="duotone" className="text-zinc-500 flex-shrink-0" />
        <input
          type="number"
          inputMode="decimal"
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          data-testid={testid}
          className="bg-transparent text-white text-sm font-mono w-full outline-none placeholder:text-zinc-700"
        />
      </div>
    </div>
  );
}

/**
 * SVG arc path utility for the Bel Air Gauge.
 */
function describeArc(cx, cy, r, startAngle, endAngle) {
  const start = polarToCartesian(cx, cy, r, endAngle);
  const end = polarToCartesian(cx, cy, r, startAngle);
  const largeArc = endAngle - startAngle <= 180 ? "0" : "1";
  return `M ${start.x} ${start.y} A ${r} ${r} 0 ${largeArc} 0 ${end.x} ${end.y}`;
}

function polarToCartesian(cx, cy, r, angleDeg) {
  const rad = (angleDeg * Math.PI) / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}
