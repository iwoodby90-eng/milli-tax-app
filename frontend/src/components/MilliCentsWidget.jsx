import { useState, useMemo, useEffect } from "react";
import { calculateProfit, verdict } from "@/lib/milli-cents";
import { Gauge, CurrencyDollar, GasPump, Car, Percent, MapPin, ArrowRight, Plugs, CheckCircle, Lightning } from "@phosphor-icons/react";

/**
 * Milli-Cents Profitability Widget v2.0
 * NEW: 'Connect Gig Account' flow + Live Offer Detection + Auto-ACCEPT
 * inline prop: renders as a card in the page flow (no fixed overlay)
 */

const VERDICT_COLORS = {
  ACCEPT: { ring: "#00E5FF", glow: "rgba(0,229,255,0.35)", label: "ACCEPT", bg: "rgba(0,229,255,0.08)" },
  MARGINAL: { ring: "#FFB800", glow: "rgba(255,184,0,0.30)", label: "MARGINAL", bg: "rgba(255,184,0,0.06)" },
  DECLINE: { ring: "#FF3B5C", glow: "rgba(255,59,92,0.30)", label: "DECLINE", bg: "rgba(255,59,92,0.06)" },
};

const GIG_APPS = [
  { id: "uber", name: "Uber", color: "#000" },
  { id: "lyft", name: "Lyft", color: "#FF00BF" },
  { id: "doordash", name: "DoorDash", color: "#FF3008" },
  { id: "spark", name: "Spark", color: "#0071CE" },
];

export default function MilliCentsWidget({ onClose, inline = false }) {
  const [gigConnected, setGigConnected] = useState(false);
  const [connectingGig, setConnectingGig] = useState(null);
  const [liveOffer, setLiveOffer] = useState(null);
  const [autoVerdict, setAutoVerdict] = useState(null);

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

  // Simulate gig connection
  function connectGig(app) {
    setConnectingGig(app.id);
    setTimeout(() => {
      setConnectingGig(null);
      setGigConnected(true);
      // Simulate live offer detection after connection
      setTimeout(() => {
        const offerData = { price: 28.50, distance: 12.3, deadhead: 2.1, platform: app.name };
        setLiveOffer(offerData);
        // Auto-calc verdict
        const autoResult = calculateProfit({
          offerPrice: offerData.price,
          tripDistance: offerData.distance,
          deadheadDistance: offerData.deadhead,
          gasPrice: 3.49,
          vehicleMpg: 28,
          taxSlice: 0.25,
        });
        setAutoVerdict({ result: autoResult, verdict: verdict(autoResult) });
      }, 1500);
    }, 2000);
  }

  function update(field) {
    return (e) => setForm((f) => ({ ...f, [field]: e.target.value }));
  }

  const content = (
    <div
      className="w-full rounded-3xl overflow-hidden"
      style={{
        backgroundColor: "#0a0b0d",
        border: "1px solid rgba(40,44,52,0.8)",
        boxShadow: inline
          ? "0 0 40px rgba(0,229,255,0.04), inset 0 1px 0 rgba(255,255,255,0.03)"
          : "0 0 80px rgba(0,229,255,0.06)",
      }}
    >
      {/* Header */}
      <div className="px-6 pt-6 pb-4 flex items-center justify-between border-b" style={{ borderColor: "rgba(40,44,52,0.6)" }}>
        <div className="flex items-center gap-3">
          <Gauge size={22} weight="duotone" style={{ color: "#00E5FF" }} />
          <div>
            <div className="font-display text-sm tracking-[0.2em] text-white uppercase">Milli-Cents</div>
            <div className="text-[10px] text-zinc-500 font-mono tracking-wider">// PROFITABILITY ENGINE v2.0</div>
          </div>
        </div>
        {!inline && onClose && (
          <button
            onClick={onClose}
            className="text-zinc-500 hover:text-white text-lg font-mono"
            style={{ all: "unset", cursor: "pointer", color: "#8B9DAF", fontSize: 18 }}
            aria-label="Close"
          >
            &times;
          </button>
        )}
      </div>

      {/* ─── Connect Gig Account UI ─── */}
      {!gigConnected && (
        <div className="px-6 py-5" style={{ borderBottom: "1px solid rgba(40,44,52,0.4)" }}>
          <div className="flex items-center gap-2 mb-3">
            <Plugs size={16} weight="duotone" style={{ color: "#00E5FF" }} />
            <span className="text-xs font-semibold uppercase tracking-[0.15em]" style={{ color: "#00E5FF" }}>Connect Gig Account</span>
          </div>
          <p className="text-xs text-zinc-400 mb-4">Link a platform for live offer detection &amp; auto-verdicts.</p>
          <div className="grid grid-cols-2 gap-2">
            {GIG_APPS.map((app) => (
              <button
                key={app.id}
                onClick={() => connectGig(app)}
                disabled={!!connectingGig}
                data-testid={`connect-gig-${app.id}`}
                style={{
                  all: "unset",
                  cursor: connectingGig ? "wait" : "pointer",
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  padding: "10px 12px",
                  borderRadius: 12,
                  background: "rgba(5,6,7,0.6)",
                  border: connectingGig === app.id ? "1px solid rgba(0,229,255,0.4)" : "1px solid rgba(255,255,255,0.05)",
                  opacity: connectingGig && connectingGig !== app.id ? 0.4 : 1,
                  transition: "all 0.2s",
                  fontSize: 13,
                  fontWeight: 500,
                  color: "#FFFFFF",
                }}
              >
                <div style={{ width: 8, height: 8, borderRadius: "50%", background: app.color, flexShrink: 0 }} />
                {connectingGig === app.id ? "Linking..." : app.name}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ─── Live Offer Detected ─── */}
      {gigConnected && liveOffer && (
        <div className="px-6 py-5" style={{ background: "rgba(0,229,255,0.03)", borderBottom: "1px solid rgba(0,229,255,0.1)" }}>
          <div className="flex items-center gap-2 mb-3">
            <Lightning size={16} weight="fill" style={{ color: "#00E5FF" }} />
            <span className="text-xs font-bold uppercase tracking-[0.15em]" style={{ color: "#00E5FF" }}>Live Offer Detected</span>
            <span className="ml-auto text-[10px] text-zinc-500 font-mono">{liveOffer.platform}</span>
          </div>
          <div className="flex items-center gap-4 mb-3">
            <div>
              <div className="font-chrome font-bold text-3xl text-white">${liveOffer.price.toFixed(2)}</div>
              <div className="text-[10px] text-zinc-500 font-mono">{liveOffer.distance} mi + {liveOffer.deadhead} mi deadhead</div>
            </div>
            {autoVerdict && (
              <div className="ml-auto text-center">
                <div
                  className="px-4 py-2 rounded-full text-xs font-bold uppercase tracking-[0.2em] font-mono"
                  style={{
                    backgroundColor: VERDICT_COLORS[autoVerdict.verdict].bg,
                    color: VERDICT_COLORS[autoVerdict.verdict].ring,
                    border: `1px solid ${VERDICT_COLORS[autoVerdict.verdict].ring}40`,
                    boxShadow: `0 0 12px ${VERDICT_COLORS[autoVerdict.verdict].glow}`,
                  }}
                  data-testid="auto-verdict-badge"
                >
                  {autoVerdict.verdict}
                </div>
                <div className="text-[9px] text-zinc-500 mt-1 font-mono">
                  Net: ${autoVerdict.result.profit.toFixed(2)}
                </div>
              </div>
            )}
          </div>
          {autoVerdict?.verdict === "ACCEPT" && (
            <div className="flex items-center gap-2 text-xs" style={{ color: "#00E5FF" }}>
              <CheckCircle size={14} weight="fill" />
              <span className="font-mono uppercase tracking-wider">Auto-accepted by Milli-Cents formula</span>
            </div>
          )}
        </div>
      )}

      {/* Gig Connected indicator */}
      {gigConnected && !liveOffer && (
        <div className="px-6 py-4 flex items-center gap-2" style={{ borderBottom: "1px solid rgba(40,44,52,0.4)" }}>
          <CheckCircle size={16} weight="fill" style={{ color: "#34D399" }} />
          <span className="text-xs font-medium" style={{ color: "#34D399" }}>Gig account connected</span>
          <span className="text-[10px] text-zinc-500 ml-auto font-mono">Scanning for offers...</span>
        </div>
      )}

      {/* Bel Air Gauge */}
      <div className="flex justify-center py-6">
        <BelAirGauge margin={hasInput ? result.profitMargin : (autoVerdict ? autoVerdict.result.profitMargin : 0)} colors={autoVerdict ? VERDICT_COLORS[autoVerdict.verdict] : colors} active={hasInput || !!autoVerdict} />
      </div>

      {/* Manual Verdict */}
      {hasInput && (
        <div className="text-center -mt-2 mb-5">
          <span
            className="inline-block px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-[0.25em] font-mono"
            style={{ backgroundColor: colors.bg, color: colors.ring, border: `1px solid ${colors.ring}40` }}
          >
            {colors.label}
          </span>
          <div className="mt-2 text-zinc-400 text-sm font-mono">
            Net: <span className="text-white font-semibold">${result.profit.toFixed(2)}</span>
            <span className="text-zinc-600 mx-2">|</span>
            Fuel: <span className="text-zinc-300">${result.fuelCost.toFixed(2)}</span>
            <span className="text-zinc-600 mx-2">|</span>
            Tax: <span className="text-zinc-300">${result.taxOwed.toFixed(2)}</span>
          </div>
        </div>
      )}

      {/* Manual Input Form */}
      <div className="px-6 pb-6 grid grid-cols-2 gap-3">
        <InputField icon={CurrencyDollar} label="Offer $" value={form.offerPrice} onChange={update("offerPrice")} placeholder="12.50" testid="mc-offer" />
        <InputField icon={MapPin} label="Trip mi" value={form.tripDistance} onChange={update("tripDistance")} placeholder="8.2" testid="mc-trip" />
        <InputField icon={ArrowRight} label="Deadhead mi" value={form.deadheadDistance} onChange={update("deadheadDistance")} placeholder="3.0" testid="mc-deadhead" />
        <InputField icon={GasPump} label="Gas $/gal" value={form.gasPrice} onChange={update("gasPrice")} placeholder="3.49" testid="mc-gas" />
        <InputField icon={Car} label="MPG" value={form.vehicleMpg} onChange={update("vehicleMpg")} placeholder="28" testid="mc-mpg" />
        <InputField icon={Percent} label="Tax %" value={form.taxSlice} onChange={update("taxSlice")} placeholder="25" testid="mc-tax" />
      </div>

      {hasInput && (
        <div className="px-6 pb-6 flex items-center justify-between text-xs text-zinc-500 font-mono border-t pt-4" style={{ borderColor: "rgba(40,44,52,0.6)" }}>
          <span>Cost/mile: <span className="text-zinc-300">${result.costPerMile.toFixed(2)}</span></span>
          <span>Total miles: <span className="text-zinc-300">{result.totalMiles}</span></span>
        </div>
      )}
    </div>
  );

  // Inline mode: render directly in page flow, no overlay
  if (inline) {
    return content;
  }

  // Modal mode: fixed overlay
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ backgroundColor: "rgba(0,0,0,0.88)" }}>
      <div className="w-full max-w-md max-h-[90vh] overflow-y-auto" style={{ borderRadius: "1.5rem" }}>
        {content}
      </div>
    </div>
  );
}

function BelAirGauge({ margin, colors, active }) {
  const clampedMargin = Math.max(-100, Math.min(100, margin));
  const normalized = active ? (clampedMargin + 100) / 200 : 0;
  const startAngle = -210;
  const endAngle = 30;
  const sweepTotal = endAngle - startAngle;
  const needleAngle = startAngle + normalized * sweepTotal;
  const r = 70;
  const cx = 90;
  const cy = 90;
  const arcPath = describeArc(cx, cy, r, startAngle, endAngle);
  const filledEnd = startAngle + normalized * sweepTotal;
  const filledPath = normalized > 0 ? describeArc(cx, cy, r, startAngle, filledEnd) : "";
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
      <div className="absolute inset-0 rounded-full" style={{ background: "conic-gradient(from 0deg, #2a2a2a, #555, #2a2a2a, #444, #2a2a2a)", padding: 4 }}>
        <div className="w-full h-full rounded-full" style={{ backgroundColor: "#0a0b0d" }} />
      </div>
      <svg width="180" height="180" viewBox="0 0 180 180" className="absolute inset-0">
        {ticks.map((t, i) => (
          <line key={i} x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2} stroke="#555" strokeWidth="2" strokeLinecap="round" />
        ))}
        <path d={arcPath} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="6" strokeLinecap="round" />
        {filledPath && (
          <path d={filledPath} fill="none" stroke={colors.ring} strokeWidth="6" strokeLinecap="round" style={{ filter: `drop-shadow(0 0 6px ${colors.glow})`, transition: "d 600ms cubic-bezier(0.4, 0, 0.2, 1)" }} />
        )}
        {active && (
          <>
            <line x1={cx} y1={cy} x2={nx(cx, needleAngle, r - 18)} y2={ny(cy, needleAngle, r - 18)} stroke={colors.ring} strokeWidth="2.5" strokeLinecap="round" style={{ filter: `drop-shadow(0 0 4px ${colors.glow})`, transition: "all 600ms cubic-bezier(0.4, 0, 0.2, 1)" }} />
            <circle cx={cx} cy={cy} r="5" fill="#1a1a1a" stroke={colors.ring} strokeWidth="1.5" />
          </>
        )}
        <circle cx={cx} cy={cy} r="3" fill="#666" />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center pt-6">
        <div className="font-chrome font-bold text-2xl" style={{ color: active ? colors.ring : "#444", transition: "color 400ms" }}>
          {active ? `${Math.round(clampedMargin)}%` : "—"}
        </div>
        <div className="text-[9px] font-mono uppercase tracking-[0.3em] text-zinc-500 mt-0.5">margin</div>
      </div>
    </div>
  );
}

function nx(cx, angleDeg, radius) {
  return cx + radius * Math.cos((angleDeg * Math.PI) / 180);
}

function ny(cy, angleDeg, radius) {
  return cy + radius * Math.sin((angleDeg * Math.PI) / 180);
}

function InputField({ icon: Icon, label, value, onChange, placeholder, testid }) {
  return (
    <div className="relative">
      <label className="text-[9px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1 block">{label}</label>
      <div className="flex items-center gap-2 rounded-xl px-3 py-2.5" style={{ background: "rgba(5,6,7,0.6)", border: "1px solid rgba(40,44,52,0.6)" }}>
        <Icon size={14} weight="duotone" className="text-zinc-500 flex-shrink-0" />
        <input
          type="number"
          inputMode="decimal"
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          data-testid={testid}
          className="bg-transparent text-white text-sm font-mono w-full outline-none placeholder:text-zinc-700"
          style={{ background: "transparent", border: "none", padding: 0 }}
        />
      </div>
    </div>
  );
}

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
