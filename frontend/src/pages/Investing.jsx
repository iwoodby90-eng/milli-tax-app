import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { Eye, CaretDown, CaretRight, Sparkle, ArrowUp, ArrowDown } from "@phosphor-icons/react";

/**
 * Investing — matches the reference mockup + LIVE market data.
 */
export default function Investing() {
  const [range, setRange] = useState("1D");
  const [overview, setOverview] = useState(null);
  const [movers, setMovers] = useState(null);

  useEffect(() => {
    const rangeMap = { "1D": "1d", "1W": "1w", "1M": "1m", "1Y": "1y", "All": "all" };
    api.get(`/market/overview?range_=${rangeMap[range] || "1d"}`)
      .then(r => setOverview(r.data)).catch(() => {});
  }, [range]);
  useEffect(() => {
    api.get("/market/movers").then(r => setMovers(r.data)).catch(() => {});
    const iv = setInterval(() => {
      api.get("/market/movers").then(r => setMovers(r.data)).catch(() => {});
    }, 120000);
    return () => clearInterval(iv);
  }, []);

  const total = 124560;
  const todayGain = 2340.50;
  const todayPct = 1.91;
  const buyingPower = 8750;

  const spx = overview?.index?.price ?? 5321.41;
  const spxDelta = overview?.index?.change ?? 24.39;
  const spxPct = overview?.index?.change_pct ?? 0.46;
  const spxUp = (spxDelta || 0) >= 0;

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4">
      {/* Header */}
      <header className="flex items-start justify-between gap-3">
        <div>
          <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
            Investing
          </h1>
          <p className="text-zinc-400 text-[14px] mt-1">Track. Analyze. Grow.</p>
        </div>
        <button className="milli-card rounded-xl px-3 py-1.5 text-white text-[12.5px] font-medium inline-flex items-center gap-1.5 h-fit">
          All Accounts <CaretDown size={12} weight="bold" className="text-zinc-500" />
        </button>
      </header>

      {/* 1 · Total Portfolio Value */}
      <section
        className="relative overflow-hidden rounded-3xl p-5"
        data-testid="investing-total-card"
        style={{
          background: "linear-gradient(135deg, rgba(0,180,200,0.25) 0%, rgba(0,229,255,0.06) 40%, rgba(10,14,18,0.9) 75%)",
          border: "1px solid rgba(0,229,255,0.55)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.08), 0 0 28px rgba(0,229,255,0.35), 0 20px 44px rgba(0,0,0,0.55)",
        }}
      >
        <div className="absolute top-4 right-4 pointer-events-none">
          <MetallicMCard />
        </div>
        <div className="relative z-10">
          <div className="flex items-center gap-2 text-white/85 text-[14px] font-medium">
            <span>Total Portfolio Value</span>
            <Eye size={16} weight="regular" className="text-white/60" />
          </div>
          <div className="font-chrome font-black text-white tabular-nums leading-[1] tracking-tight mt-2 text-[34px] sm:text-[40px]">
            ${total.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="text-volt text-[13px] mt-3" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            +${todayGain.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ({todayPct}%) today
          </div>
        </div>
      </section>

      {/* 2 · Market Overview */}
      <section className="milli-card rounded-2xl p-4 pt-5" data-testid="investing-market-card">
        <div className="flex items-start justify-between mb-2">
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-white font-semibold text-[16px]">Market Overview</h2>
              <span className="flex items-center gap-1 text-[11px] text-volt font-semibold"
                    style={{ textShadow: "0 0 6px rgba(0,229,255,0.5)" }}>
                <span className="w-1.5 h-1.5 rounded-full bg-volt shadow-[0_0_6px_#00E5FF] animate-pulse" />
                Live
              </span>
            </div>
            <div className="text-zinc-500 text-[12.5px] mt-0.5">S&amp;P 500 <span className="text-zinc-700 mx-1">•</span> SPX</div>
            <div className="chrome-text font-chrome font-bold text-[28px] leading-tight tabular-nums mt-1">
              {spx.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <div className={spxUp ? "text-volt text-[13px]" : "text-rose-400 text-[13px]"}
                 style={spxUp ? { textShadow: "0 0 6px rgba(0,229,255,0.4)" } : {}}>
              {spxUp ? "+" : ""}{spxDelta.toFixed(2)} ({spxPct.toFixed(2)}%)
            </div>
          </div>
          <PriceTicks />
        </div>
        <CandleChart />
        <div className="flex items-center justify-between mt-3 border-t border-white/[0.05] pt-3">
          {["1D", "1W", "1M", "1Y", "All"].map((r) => {
            const active = r === range;
            return (
              <button
                key={r}
                onClick={() => setRange(r)}
                data-testid={`investing-range-${r}`}
                className={`text-[13px] font-semibold px-2 ${active ? "text-volt" : "text-zinc-500"}`}
                style={active ? {
                  borderBottom: "2px solid #00E5FF",
                  paddingBottom: "3px",
                  textShadow: "0 0 8px rgba(0,229,255,0.5)",
                } : { paddingBottom: "5px" }}
              >
                {r}
              </button>
            );
          })}
        </div>
      </section>

      {/* Live Top Movers (from real market data) */}
      <MoversSection movers={movers} />

      {/* 3 · Today's Gain/Loss + Buying Power */}
      <div className="grid grid-cols-2 gap-3">
        <div className="milli-card rounded-2xl p-4" data-testid="investing-gain-card">
          <div className="text-zinc-400 text-[13px]">Today&apos;s Gain/Loss</div>
          <div className="text-volt font-chrome font-bold text-[22px] leading-tight tabular-nums mt-1"
               style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            +${todayGain.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="mt-1.5 inline-block px-2 py-0.5 rounded-md text-volt text-[10.5px] font-bold"
               style={{ background: "rgba(0,229,255,0.10)", border: "1px solid rgba(0,229,255,0.35)" }}>
            {todayPct}%
          </div>
          <MiniLineChart up />
          <div className="text-zinc-400 text-[11.5px] mt-1 flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
            Market opened
          </div>
        </div>
        <div className="milli-card rounded-2xl p-4 relative overflow-hidden" data-testid="investing-buying-card">
          <div className="text-zinc-400 text-[13px]">Buying Power</div>
          <div className="chrome-text font-chrome font-bold text-[22px] leading-tight tabular-nums mt-1">
            ${buyingPower.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="text-zinc-400 text-[11.5px] mt-2">Available to invest</div>
          <MilliCoinStack />
        </div>
      </div>

      {/* 4 · Watchlist + Asset Allocation */}
      <div className="grid grid-cols-2 gap-3">
        <section className="milli-card rounded-2xl p-4" data-testid="investing-watchlist-card">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-white font-semibold text-[14.5px]">Watchlist</h2>
            <button className="text-volt text-[12px] font-semibold">View all</button>
          </div>
          <ul className="space-y-2.5">
            <StockRow logo="apple"  ticker="AAPL" name="Apple Inc."   price="$192.58" delta="+1.35%" up />
            <StockRow logo="tesla"  ticker="TSLA" name="Tesla, Inc."  price="$178.65" delta="−0.85%" />
            <StockRow logo="nvidia" ticker="NVDA" name="NVIDIA Corp." price="$950.02" delta="+2.35%" up />
          </ul>
        </section>
        <section className="milli-card rounded-2xl p-4" data-testid="investing-allocation-card">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-white font-semibold text-[14.5px]">Asset Allocation</h2>
            <button className="text-volt text-[12px] font-semibold">View all</button>
          </div>
          <div className="flex items-center gap-3">
            <DonutChart segments={[
              { pct: 65, color: "#00B4D0" },
              { pct: 20, color: "#00E5FF" },
              { pct: 10, color: "#7BF3FF" },
              { pct: 5,  color: "#4A5566" },
            ]} />
            <ul className="flex-1 space-y-1.5 text-[11.5px]">
              <AllocLegend color="#00B4D0" label="Stocks" pct="65%" />
              <AllocLegend color="#00E5FF" label="ETFs"   pct="20%" />
              <AllocLegend color="#7BF3FF" label="Cash"   pct="10%" />
              <AllocLegend color="#4A5566" label="Crypto" pct="5%" />
            </ul>
          </div>
        </section>
      </div>

      {/* 5 · Milli AI Insight */}
      <section
        className="rounded-2xl p-4 relative overflow-hidden"
        data-testid="investing-ai-insight-card"
        style={{
          background: "linear-gradient(135deg, rgba(0,229,255,0.06) 0%, rgba(10,14,18,0.92) 60%)",
          border: "1px solid rgba(0,229,255,0.28)",
          boxShadow: "0 0 22px rgba(0,229,255,0.15), 0 12px 26px rgba(0,0,0,0.5)",
        }}
      >
        <div className="flex items-start gap-3">
          <Sparkle size={18} weight="fill" className="text-volt flex-shrink-0 mt-0.5"
                   style={{ filter: "drop-shadow(0 0 8px rgba(0,229,255,0.7))" }} />
          <div className="flex-1 min-w-0">
            <div className="text-white font-semibold text-[14.5px]">Milli AI Insight</div>
            <div className="text-zinc-300 text-[13px] mt-1.5 leading-relaxed">
              Tech sector momentum is strong. Your exposure is aligned with growth trends and positioned for long-term compounding.
            </div>
            <div className="text-volt text-[12.5px] mt-2 font-semibold"
                 style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
              AI Confidence: High
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */

function MetallicMCard() {
  return (
    <div
      className="relative w-[100px] h-[62px] flex-shrink-0 rounded-lg overflow-hidden"
      style={{
        background: "linear-gradient(135deg, #E4E7EA 0%, #A8ADB4 20%, #4B4F55 50%, #1E2126 80%, #0A0C10 100%)",
        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.55), inset 0 -6px 12px rgba(0,0,0,0.5), 0 6px 14px rgba(0,0,0,0.55)",
        transform: "rotate(-6deg)",
      }}
    >
      <div className="absolute inset-0"
           style={{ background: "linear-gradient(120deg, transparent 30%, rgba(255,255,255,0.28) 45%, transparent 60%)" }} />
      <div className="absolute top-2 left-2 w-5 h-3.5 rounded-sm"
           style={{ background: "linear-gradient(180deg, #C8B970 0%, #8A7A3E 100%)" }} />
      <div className="absolute inset-0 flex items-center justify-end pr-2.5"
           style={{
             fontFamily: "'Sora','Inter',sans-serif", fontWeight: 900, fontSize: 32,
             background: "linear-gradient(180deg, #FFFFFF 0%, #D0D3D8 40%, #6E7379 100%)",
             WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
             filter: "drop-shadow(0 1px 0 rgba(0,0,0,0.5))",
           }}>M</div>
    </div>
  );
}

function PriceTicks() {
  return (
    <div className="text-right text-[10px] text-zinc-500 font-mono tabular-nums leading-relaxed pt-1">
      <div className="text-volt" style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>5,321.41</div>
      <div>5,300</div>
      <div>5,250</div>
      <div>5,200</div>
      <div>5,150</div>
      <div>5,100</div>
    </div>
  );
}

function CandleChart() {
  // 20 candles with a general uptrend for the mockup vibe
  const w = 300, h = 130;
  const candles = [];
  let price = 5150;
  for (let i = 0; i < 20; i++) {
    const drift = (i / 20) * 220;
    const noise = (Math.sin(i * 1.3) + Math.cos(i * 0.7)) * 15;
    const open  = price;
    const close = 5150 + drift + noise + (i > 15 ? 10 : 0);
    const high  = Math.max(open, close) + Math.abs(noise) * 0.6 + 6;
    const low   = Math.min(open, close) - Math.abs(noise) * 0.6 - 6;
    candles.push({ open, close, high, low });
    price = close;
  }
  const minP = Math.min(...candles.map(c => c.low));
  const maxP = Math.max(...candles.map(c => c.high));
  const y = (p) => h - ((p - minP) / (maxP - minP)) * (h - 10) - 5;
  const cw = w / candles.length - 2;
  return (
    <svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} className="mt-1">
      {candles.map((c, i) => {
        const cx = i * (w / candles.length) + (w / candles.length) / 2;
        const bull = c.close > c.open;
        const bodyTop = y(Math.max(c.open, c.close));
        const bodyH  = Math.max(1.4, Math.abs(y(c.open) - y(c.close)));
        const color = bull ? "#00E5FF" : "#FF5C77";
        return (
          <g key={i}>
            <line x1={cx} x2={cx} y1={y(c.high)} y2={y(c.low)} stroke={color} strokeWidth={1} opacity={0.85} />
            <rect x={cx - cw/2} y={bodyTop} width={cw} height={bodyH} fill={color}
                  opacity={bull ? 0.95 : 0.85}
                  style={bull ? { filter: "drop-shadow(0 0 4px rgba(0,229,255,0.6))" } : {}} />
          </g>
        );
      })}
      {/* dashed guide line at final close */}
      <line x1="0" x2={w} y1={y(candles[candles.length-1].close)} y2={y(candles[candles.length-1].close)}
            stroke="#00E5FF" strokeWidth={1} strokeDasharray="3 3" opacity={0.55} />
    </svg>
  );
}

function MiniLineChart({ up }) {
  const w = 100, h = 32;
  const pts = up
    ? [[0, 26], [15, 24], [30, 22], [45, 18], [60, 15], [75, 11], [100, 6]]
    : [[0, 6], [15, 10], [30, 14], [45, 18], [60, 22], [75, 26], [100, 28]];
  const d = pts.reduce((acc, p, i) => acc + (i === 0 ? `M${p[0]},${p[1]}` : ` L${p[0]},${p[1]}`), "");
  return (
    <svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} preserveAspectRatio="none" className="mt-2">
      <path d={d} fill="none" stroke="#00E5FF" strokeWidth={1.5}
            style={{ filter: "drop-shadow(0 0 4px rgba(0,229,255,0.6))" }} />
    </svg>
  );
}

function MilliCoinStack() {
  return (
    <div className="absolute bottom-2 right-2 flex items-end gap-0.5" aria-hidden>
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          className="w-10 h-3 rounded-full"
          style={{
            background: "radial-gradient(ellipse at 30% 30%, #E4E7EA 0%, #808388 55%, #2A2E33 100%)",
            border: "1px solid rgba(0,229,255,0.35)",
            boxShadow: "0 0 8px rgba(0,229,255,0.35), inset 0 1px 0 rgba(255,255,255,0.5)",
            transform: `translateY(${-i * 2}px)`,
          }}
        />
      ))}
      <div
        className="w-10 h-10 rounded-full ml-1 flex items-center justify-center"
        style={{
          background: "radial-gradient(circle at 35% 30%, #E4E7EA 0%, #808388 60%, #2A2E33 100%)",
          border: "1.5px solid rgba(0,229,255,0.55)",
          boxShadow: "0 0 14px rgba(0,229,255,0.55), inset 0 1px 0 rgba(255,255,255,0.5)",
        }}
      >
        <span style={{
          fontFamily: "'Sora','Inter',sans-serif", fontWeight: 900, fontSize: 16,
          background: "linear-gradient(180deg, #FFFFFF 0%, #6E7379 100%)",
          WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
        }}>M</span>
      </div>
    </div>
  );
}

function StockRow({ logo, ticker, name, price, delta, up }) {
  return (
    <li className="flex items-center gap-2.5" data-testid={`watchlist-${ticker}`}>
      <StockLogo logo={logo} />
      <div className="flex-1 min-w-0">
        <div className="text-white font-semibold text-[13px] leading-tight">{ticker}</div>
        <div className="text-zinc-500 text-[10.5px] truncate">{name}</div>
      </div>
      <div className="text-right">
        <div className="text-white text-[12.5px] tabular-nums">{price}</div>
        <div className={`text-[10.5px] font-medium ${up ? "text-volt" : "text-rose-400"}`}
             style={up ? { textShadow: "0 0 6px rgba(0,229,255,0.4)" } : {}}>
          {delta}
        </div>
      </div>
    </li>
  );
}

function StockLogo({ logo }) {
  const cfg = {
    apple:  { bg: "#FFFFFF", fg: "#000", label: "" },
    tesla:  { bg: "#E31937", fg: "#FFF", label: "T" },
    nvidia: { bg: "#76B900", fg: "#000", label: "N" },
  };
  const c = cfg[logo] || { bg: "#333", fg: "#FFF", label: "?" };
  if (logo === "apple") {
    return (
      <div className="w-7 h-7 rounded-lg flex items-center justify-center" style={{ background: c.bg }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="#000"><path d="M17.6 12.8c0-2.4 2-3.5 2-3.6-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.8-3.5.8-.7 0-1.9-.8-3.1-.8-1.6 0-3 .9-3.9 2.4-1.7 2.9-.4 7.1 1.2 9.5.8 1.1 1.7 2.4 3 2.4 1.2 0 1.6-.8 3.1-.8 1.4 0 1.8.8 3.1.8 1.3 0 2.1-1.2 2.9-2.3.9-1.3 1.3-2.6 1.3-2.7-.1 0-2.4-1-2.7-3.9zM15 5.2c.6-.7 1.1-1.8 1-2.9-.9.1-2 .6-2.6 1.4-.6.7-1.1 1.8-1 2.9 1 .1 2-.6 2.6-1.4z" /></svg>
      </div>
    );
  }
  return (
    <div className="w-7 h-7 rounded-lg flex items-center justify-center font-bold text-[12px]"
         style={{ background: c.bg, color: c.fg }}>{c.label}</div>
  );
}

function DonutChart({ segments }) {
  const size = 80, stroke = 14, r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  let offset = 0;
  return (
    <svg width={size} height={size} className="-rotate-90 flex-shrink-0"
         style={{ filter: "drop-shadow(0 0 8px rgba(0,229,255,0.25))" }}>
      {segments.map((s, i) => {
        const dash = (s.pct / 100) * c;
        const el = (
          <circle
            key={i}
            cx={size/2} cy={size/2} r={r} fill="none"
            stroke={s.color} strokeWidth={stroke}
            strokeDasharray={`${dash} ${c - dash}`}
            strokeDashoffset={-offset}
          />
        );
        offset += dash;
        return el;
      })}
    </svg>
  );
}

function AllocLegend({ color, label, pct }) {
  return (
    <li className="flex items-center justify-between">
      <span className="flex items-center gap-1.5">
        <span className="w-2 h-2 rounded-full" style={{ background: color }} />
        <span className="text-white/85">{label}</span>
      </span>
      <span className="text-zinc-400 tabular-nums">{pct}</span>
    </li>
  );
}

/* Live Top Movers — powered by /api/market/movers */
function MoversSection({ movers }) {
  const [tab, setTab] = useState("gainers");
  const rows = movers?.[tab] || [];
  return (
    <section className="milli-card rounded-2xl p-4" data-testid="investing-movers-card">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-white font-semibold text-[15px]">Today&apos;s Movers</h2>
        <div className="flex gap-1 text-[11px] font-semibold">
          {["gainers", "losers", "actives"].map((k) => (
            <button
              key={k}
              onClick={() => setTab(k)}
              data-testid={`movers-tab-${k}`}
              className="px-2.5 py-1 rounded-full transition"
              style={tab === k
                ? { background: "rgba(0,229,255,0.10)", color: "#00E5FF", border: "1px solid rgba(0,229,255,0.5)", textShadow: "0 0 6px rgba(0,229,255,0.4)" }
                : { color: "#8B95A5", border: "1px solid rgba(255,255,255,0.08)" }}
            >
              {k === "gainers" ? "Gainers" : k === "losers" ? "Losers" : "Active"}
            </button>
          ))}
        </div>
      </div>
      {!movers && (
        <div className="text-zinc-500 text-[12.5px] py-4 text-center">Loading live market…</div>
      )}
      <ul className="divide-y divide-white/[0.05]">
        {rows.slice(0, 5).map((m) => {
          const up = (m.change_pct || 0) >= 0;
          return (
            <li key={m.ticker} className="flex items-center gap-3 py-2.5"
                data-testid={`mover-${m.ticker}`}>
              <div className="w-9 h-9 rounded-lg bg-white/[0.04] border border-white/10 flex items-center justify-center text-white text-[11px] font-bold flex-shrink-0">
                {m.ticker.replace("-", "")}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-white text-[13.5px] font-medium truncate">{m.name || m.ticker}</div>
                <div className="text-zinc-500 text-[11.5px] tabular-nums">${m.price?.toFixed(2)}</div>
              </div>
              <div className="text-right flex-shrink-0">
                <div className={`text-[13.5px] font-semibold tabular-nums ${up ? "text-volt" : "text-rose-400"}`}
                     style={up ? { textShadow: "0 0 6px rgba(0,229,255,0.4)" } : {}}>
                  {up ? "+" : ""}{m.change_pct?.toFixed(2)}%
                </div>
                <div className="text-zinc-500 text-[10.5px] tabular-nums">
                  {up ? <ArrowUp size={9} weight="bold" className="inline" /> : <ArrowDown size={9} weight="bold" className="inline" />}
                  {" "}${Math.abs(m.change || 0).toFixed(2)}
                </div>
              </div>
            </li>
          );
        })}
      </ul>
      {movers?.last_updated && (
        <div className="text-[10px] text-zinc-600 text-center mt-2 uppercase tracking-widest">
          Updated {new Date(movers.last_updated).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" })} · Live
        </div>
      )}
    </section>
  );
}

