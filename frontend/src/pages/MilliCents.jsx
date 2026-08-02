import { useState } from "react";
import { api } from "@/lib/api";
import { toast } from "sonner";
import {
  ArrowUp, ArrowDown, Minus, MapPin, ArrowClockwise, GasPump,
  Coins, Path, ShieldCheck, CaretRight,
} from "@phosphor-icons/react";

/**
 * Milli Cents — Offer Profitability Engine.
 * Matches the reference mockup exactly:
 *   1. LIVE Offer Analysis card (Uber logo + $18.42 + 82/100 half-arc score gauge + verdict)
 *   2. Breakdown rows (Trip / Pickup / Deadhead / Return / Gas / Taxes / Total / Net Profit)
 *   3. GO CTA card
 *   4. Compare Live Offers — 4-up ranked cards (UberX, DoorDash, Spark, Lyft)
 *   5. Bottom safety pill (shield + "You're set to earn")
 */

const PLATFORMS = [
  { id: "uber",     name: "UberX",    kind: "Customer Ride", logo: "uber",     bg: "#000000", fg: "#FFFFFF" },
  { id: "doordash", name: "DoorDash", kind: "Delivery",       logo: "doordash", bg: "#EB1700", fg: "#FFFFFF" },
  { id: "spark",    name: "Spark",    kind: "Delivery",       logo: "spark",    bg: "#0071DC", fg: "#FFC220" },
  { id: "lyft",     name: "Lyft",     kind: "Customer Ride",  logo: "lyft",     bg: "#FF00BF", fg: "#FFFFFF" },
];

const DEMO_OFFERS = [
  { platform: "uber",     payout: 18.42, miles: 12.4, net: 9.94, score: 82, rank: 1 },
  { platform: "doordash", payout: 16.75, miles: 8.7,  net: 6.31, score: 68, rank: 2 },
  { platform: "spark",    payout: 14.62, miles: 6.2,  net: 5.08, score: 60, rank: 3 },
  { platform: "lyft",     payout: 21.31, miles: 15.8, net: 4.21, score: 45, rank: 4 },
];

export default function MilliCents() {
  const [selected, setSelected] = useState("uber");
  const [live] = useState(true);

  const offer = DEMO_OFFERS.find(o => o.platform === selected) || DEMO_OFFERS[0];
  const platform = PLATFORMS.find(p => p.id === offer.platform);

  // Breakdown (matches mockup)
  const breakdown = {
    trip_miles:     12.4,
    pickup_miles:   2.1,
    deadhead_miles: 2.1,
    return_miles:   3.7,
    gas_gal:        0.9,
    gas_cost:       2.81,
    per_mile_cost:  { pickup: 0.38, deadhead: 0.38, return: 0.67 },
    taxes:          4.24,
    total_cost:     8.48,
    net_profit:     offer.net,
  };

  const verdict = offer.score >= 75 ? "GO"
                 : offer.score >= 55 ? "MARGINAL"
                 : "SKIP";

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4">

      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          Milli Cents
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Offer Profitability Engine</p>
      </header>

      {/* 1 · LIVE Offer Analysis */}
      <section
        className="relative rounded-3xl p-5"
        data-testid="millicents-live-card"
        style={{
          background: "linear-gradient(180deg, rgba(0,229,255,0.05) 0%, rgba(10,14,18,0.9) 100%)",
          border: "1px solid rgba(0,229,255,0.4)",
          boxShadow: "0 0 22px rgba(0,229,255,0.2), 0 18px 40px rgba(0,0,0,0.55)",
        }}
      >
        <div className="flex items-center justify-between mb-4">
          <span className="font-mono text-[10.5px] uppercase tracking-[0.28em] text-volt"
                style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
            Live Offer Analysis
          </span>
          {live && (
            <span className="text-emerald-400 text-[10.5px] font-bold px-2 py-0.5 rounded-md tracking-wider"
                  style={{ background: "rgba(52,211,153,0.10)", border: "1px solid rgba(52,211,153,0.4)" }}>
              LIVE
            </span>
          )}
        </div>
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-start gap-3 flex-1 min-w-0">
            <PlatformLogo platform={platform} size={48} />
            <div className="flex-1 min-w-0">
              <div className="chrome-text font-chrome font-bold text-[20px] leading-tight">{platform.name}</div>
              <div className="text-zinc-400 text-[12px] mt-0.5">{platform.kind}</div>
              <div className="chrome-text font-chrome font-black text-[34px] sm:text-[38px] tabular-nums leading-none mt-3">
                ${offer.payout.toFixed(2)}
              </div>
              <div className="text-zinc-500 text-[11.5px] mt-1">Est. Total Payout</div>
            </div>
          </div>
          <HalfArcGauge value={offer.score} verdict={verdict} />
        </div>
      </section>

      {/* 2 · Breakdown table */}
      <section className="milli-card rounded-2xl p-4" data-testid="millicents-breakdown-card">
        <BreakRow icon={Path}       label="Trip Distance"      middle={`${breakdown.trip_miles} mi`}     right="—" />
        <BreakRow icon={ArrowUp}    label="Pickup Distance"    middle={`${breakdown.pickup_miles} mi`}   right={`$${breakdown.per_mile_cost.pickup.toFixed(2)}`} />
        <BreakRow icon={ArrowClockwise} label="Deadhead Distance" middle={`${breakdown.deadhead_miles} mi`} right={`$${breakdown.per_mile_cost.deadhead.toFixed(2)}`} />
        <BreakRow icon={ArrowDown}  label="Return Distance"    middle={`${breakdown.return_miles} mi`}   right={`$${breakdown.per_mile_cost.return.toFixed(2)}`} />
        <BreakRow icon={GasPump}    label="Est. Gas Used"      middle={`${breakdown.gas_gal} gal`}       right={`$${breakdown.gas_cost.toFixed(2)}`} />
        <BreakRow icon={Coins}      label="Est. Taxes (23%)"   middle="—"                                 right={`$${breakdown.taxes.toFixed(2)}`} />
        <BreakRow                    label="Total Estimated Cost" middle="—"                              right={`$${breakdown.total_cost.toFixed(2)}`} bold last />
        <div className="border-t border-volt/40 mt-1.5 pt-2.5"
             style={{ boxShadow: "0 -2px 8px rgba(0,229,255,0.2)" }}>
          <div className="flex items-center justify-between">
            <span className="text-volt text-[15px] font-bold" style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
              Projected Net Profit
            </span>
            <span className="text-volt text-[18px] font-black tabular-nums"
                  style={{ textShadow: "0 0 10px rgba(0,229,255,0.6)" }}>
              ${breakdown.net_profit.toFixed(2)}
            </span>
          </div>
        </div>
      </section>

      {/* 3 · GO CTA */}
      <button
        onClick={() => toast.success(`${verdict === "GO" ? "Accepted" : "Passed"} — you'll be tracked`)}
        data-testid="millicents-cta"
        className="w-full rounded-2xl p-4 flex items-center gap-4 text-left active:scale-[0.995] transition-transform"
        style={{
          background: "linear-gradient(180deg, rgba(0,229,255,0.06) 0%, rgba(10,14,18,0.85) 100%)",
          border: "1.5px solid rgba(0,229,255,0.55)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 0 22px rgba(0,229,255,0.35)",
        }}
      >
        <VerdictBadge verdict={verdict} />
        <div className="flex-1 min-w-0">
          <div className="chrome-text font-chrome font-black text-[26px] leading-none"
               style={{ textShadow: verdict === "GO" ? "0 0 10px rgba(0,229,255,0.5)" : "" }}>
            {verdict === "GO" ? "GO" : verdict === "MARGINAL" ? "OKAY" : "SKIP"}
          </div>
          <div className="text-zinc-400 text-[12px] mt-1">
            {verdict === "GO" ? "This offer meets your goals." : "Below your profit floor."}
          </div>
        </div>
        <div
          className="rounded-xl px-3 py-2 inline-flex items-center gap-1.5 text-[12px] font-semibold"
          style={{
            background: "rgba(0,229,255,0.10)",
            border: "1px solid rgba(0,229,255,0.5)",
            color: "#00E5FF",
            textShadow: "0 0 6px rgba(0,229,255,0.5)",
          }}
        >
          View Details <CaretRight size={12} weight="bold" />
        </div>
      </button>

      {/* 4 · Compare Live Offers */}
      <section>
        <div className="flex items-center justify-between mb-3 px-1">
          <span className="font-mono text-[10.5px] uppercase tracking-[0.28em] text-volt"
                style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
            Compare Live Offers
          </span>
          <button className="text-zinc-400 text-[11.5px] font-medium">Sort: Profit &rsaquo;</button>
        </div>
        <div className="grid grid-cols-4 gap-2">
          {DEMO_OFFERS.map((o) => {
            const p = PLATFORMS.find(x => x.id === o.platform);
            const active = selected === o.platform;
            return (
              <button
                key={o.platform}
                onClick={() => setSelected(o.platform)}
                data-testid={`compare-${o.platform}`}
                className="rounded-2xl p-2.5 pb-3 text-left active:scale-[0.97] transition-transform relative"
                style={{
                  background: "rgba(10,14,18,0.85)",
                  border: `1.5px solid ${active ? "rgba(0,229,255,0.7)" : "rgba(255,255,255,0.08)"}`,
                  boxShadow: active ? "0 0 18px rgba(0,229,255,0.35)" : "none",
                }}
              >
                <span
                  className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold"
                  style={{
                    background: "rgba(5,7,10,0.95)",
                    border: `1px solid ${active ? "rgba(0,229,255,0.7)" : "rgba(255,255,255,0.2)"}`,
                    color: active ? "#00E5FF" : "#B0B6BF",
                  }}
                >
                  {o.rank}
                </span>
                <PlatformLogo platform={p} size={32} />
                <div className="text-white text-[12px] font-semibold mt-1.5">{p.name}</div>
                <div className="chrome-text font-chrome font-bold text-[15px] mt-0.5 tabular-nums"
                     style={active ? { color: "#00E5FF", background: "none", WebkitTextFillColor: "#00E5FF", textShadow: "0 0 8px rgba(0,229,255,0.4)" } : {}}>
                  ${o.payout.toFixed(2)}
                </div>
                <div className="text-zinc-500 text-[10px] mt-1">{o.miles} mi</div>
                <div className="text-white text-[11px] tabular-nums">${o.net.toFixed(2)}</div>
                <MiniScore value={o.score} active={active} />
              </button>
            );
          })}
        </div>
      </section>

      {/* 5 · Safety pill */}
      <div
        className="rounded-2xl p-3.5 flex items-center gap-3"
        style={{
          background: "rgba(10,14,18,0.7)",
          border: "1px solid rgba(0,229,255,0.25)",
        }}
      >
        <ShieldCheck size={24} weight="duotone" className="text-volt flex-shrink-0"
                     style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.5))" }} />
        <div className="flex-1 min-w-0">
          <div className="text-white font-semibold text-[13.5px]">You&apos;re set to earn.</div>
          <div className="text-zinc-400 text-[11.5px]">Stay safe and maximize profits.</div>
        </div>
      </div>
    </div>
  );
}

/* ============ Sub-components ============ */

function PlatformLogo({ platform, size = 40 }) {
  if (!platform) return null;
  const p = platform;
  return (
    <div
      className="rounded-lg flex items-center justify-center font-bold overflow-hidden flex-shrink-0"
      style={{
        width: size, height: size,
        background: p.bg, color: p.fg,
        fontSize: size * 0.42,
        letterSpacing: "-0.02em",
      }}
    >
      {p.logo === "uber" && <span style={{ fontFamily: "'Sora','Inter',sans-serif" }}>Uber</span>}
      {p.logo === "lyft" && <span style={{ fontFamily: "'Sora','Inter',sans-serif" }}>lyft</span>}
      {p.logo === "doordash" && <svg width={size*0.55} height={size*0.55} viewBox="0 0 24 24" fill="#FFFFFF"><path d="M22.65 8.85c-.98-1.25-2.5-1.98-4.08-1.98H2.35c-.31 0-.5.35-.32.6l3.68 5.2c.11.15.28.24.47.24h11.42c.44 0 .8.36.8.8s-.36.8-.8.8H7.5c-.31 0-.5.35-.32.6l3.68 5.2c.11.15.28.24.47.24h7.24c3.98 0 7.15-3.55 6.55-7.62-.15-1.03-.6-2.03-1.47-3.08z"/></svg>}
      {p.logo === "spark" && <svg width={size*0.55} height={size*0.55} viewBox="0 0 24 24" fill="#FFC220"><path d="M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z"/></svg>}
    </div>
  );
}

/* Half-arc gauge (75° → 285°) with big score and verdict label */
function HalfArcGauge({ value = 82, verdict = "GO" }) {
  const size = 118;
  const r = 50;
  const cx = size / 2, cy = size / 2 + 8;
  // Arc from 135° to 45° (going clockwise via bottom) — but we want a top-open arc
  // Use 150° to 30° going the LONG way (240° span), open at top
  const startAngle = 210;   // bottom-left
  const endAngle   = 330;   // bottom-right → wait we want inverted
  // For the mockup the arc opens at BOTTOM with score sitting inside
  // Actually the mockup: arc opens at bottom-right, going from ~140° clockwise through top to ~40°
  // We'll do a simple 3/4 arc.
  const startA = 135, endA = 45; // going clockwise via 270 (top)
  const span = 360 - (startA - endA); // = 360-90 = 270
  const pct = Math.max(0, Math.min(100, value));
  const filledSpan = (pct / 100) * span;
  const arc = (a0, a1) => describeArc(cx, cy, r, a0, a1);
  const fillEnd = (startA + filledSpan) % 360;

  const verdictColor =
    verdict === "GO" ? "#00E5FF" :
    verdict === "MARGINAL" ? "#FFCC33" : "#FF5C77";
  const verdictLabel =
    verdict === "GO" ? "Very Good" :
    verdict === "MARGINAL" ? "Marginal" : "Skip";

  return (
    <div
      className="relative flex-shrink-0"
      style={{ width: size, height: size, filter: "drop-shadow(0 0 20px rgba(0,229,255,0.35))" }}
    >
      <svg width={size} height={size}>
        <path d={arc(startA, endA)} stroke="rgba(255,255,255,0.10)" strokeWidth={9} fill="none" strokeLinecap="round" />
        <path d={arc(startA, fillEnd)} stroke={verdictColor} strokeWidth={9} fill="none" strokeLinecap="round"
              style={{ filter: `drop-shadow(0 0 8px ${verdictColor})` }} />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center pt-3">
        <div className="chrome-text font-chrome font-black text-[34px] leading-none tabular-nums">{Math.round(value)}</div>
        <div className="text-zinc-400 text-[10px] mt-0.5">/100</div>
        <div className="text-zinc-400 text-[9px] uppercase tracking-widest mt-1.5">Profit Score</div>
        <div className="text-[11px] font-bold mt-0.5"
             style={{ color: verdictColor, textShadow: `0 0 8px ${verdictColor}66` }}>
          {verdictLabel}
        </div>
      </div>
    </div>
  );
}

/* SVG arc helper */
function polar(cx, cy, r, angleDeg) {
  const rad = (angleDeg - 90) * Math.PI / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}
function describeArc(cx, cy, r, startAngle, endAngle) {
  const start = polar(cx, cy, r, endAngle);
  const end   = polar(cx, cy, r, startAngle);
  const largeArc = ((endAngle - startAngle + 360) % 360) > 180 ? 1 : 0;
  return `M ${start.x} ${start.y} A ${r} ${r} 0 ${largeArc} 0 ${end.x} ${end.y}`;
}

function BreakRow({ icon: Icon, label, middle, right, bold, last }) {
  return (
    <div className={`flex items-center gap-2 py-2 ${last ? "" : "border-b border-white/[0.05]"}`}>
      {Icon
        ? <Icon size={14} weight="regular" className="text-volt/80 flex-shrink-0" />
        : <span className="w-3.5 flex-shrink-0" />}
      <span className={`flex-1 text-[13px] ${bold ? "text-white font-semibold" : "text-zinc-400"}`}>{label}</span>
      <span className="text-zinc-300 text-[12.5px] w-16 text-right tabular-nums">{middle}</span>
      <span className={`text-[13px] w-14 text-right tabular-nums ${bold ? "text-white font-semibold" : "text-white/80"}`}>{right}</span>
    </div>
  );
}

function VerdictBadge({ verdict }) {
  const color = verdict === "GO" ? "#00E5FF" : verdict === "MARGINAL" ? "#FFCC33" : "#FF5C77";
  const Icon = verdict === "GO" ? ArrowUp : verdict === "MARGINAL" ? Minus : ArrowDown;
  return (
    <div
      className="w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0"
      style={{
        background: `radial-gradient(circle at 30% 30%, ${color}55 0%, rgba(0,0,0,0.7) 70%)`,
        border: `2px solid ${color}`,
        boxShadow: `0 0 16px ${color}88, inset 0 0 12px ${color}66`,
      }}
    >
      <Icon size={20} weight="bold" style={{ color, filter: `drop-shadow(0 0 6px ${color})` }} />
    </div>
  );
}

function MiniScore({ value, active }) {
  const size = 22, stroke = 2.5, r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c - (value / 100) * c;
  return (
    <div className="flex items-center justify-center mt-1.5">
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} className="-rotate-90">
          <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(255,255,255,0.10)" strokeWidth={stroke} />
          <circle cx={size/2} cy={size/2} r={r} fill="none"
                  stroke={active ? "#00E5FF" : "#7A8390"} strokeWidth={stroke}
                  strokeLinecap="round" strokeDasharray={c} strokeDashoffset={off} />
        </svg>
        <span className="absolute inset-0 flex items-center justify-center text-[9px] font-bold tabular-nums"
              style={{ color: active ? "#00E5FF" : "#B0B6BF" }}>
          {value}
        </span>
      </div>
    </div>
  );
}
