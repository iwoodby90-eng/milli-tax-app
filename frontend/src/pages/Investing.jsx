import { useEffect, useState, useMemo } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { Link } from "react-router-dom";
import {
  ChartLineUp, ArrowUpRight, TrendUp, Wallet, Info, CaretRight,
  ArrowDown, ArrowUp, Pause, Play, Sparkle, Bank, MagnifyingGlass,
  Star,
} from "@phosphor-icons/react";

/**
 * Investing.jsx — Wealth Engine: Automated Portfolio Growth
 * v3.8 WEALTH ENGINE HARDENING:
 *   + Sector View carousel/badges (Tech, Energy, Finance, Healthcare, Consumer)
 *   + MILLI PICK badge on top 2 Gainers (Aggressive Growth strategy)
 *   + Highest Daily Movers — cinematic premium feel
 */

const PORTFOLIO_DATA = [
  { month: "Jan", value: 1200 },
  { month: "Feb", value: 1450 },
  { month: "Mar", value: 1380 },
  { month: "Apr", value: 1720 },
  { month: "May", value: 1950 },
  { month: "Jun", value: 2340 },
  { month: "Jul", value: 2180 },
  { month: "Aug", value: 2650 },
];

const HOLDINGS = [
  { name: "VTI — Total US Market", allocation: 45, gain: "+12.4%" },
  { name: "VXUS — International", allocation: 25, gain: "+8.2%" },
  { name: "BND — Total Bond", allocation: 15, gain: "+3.1%" },
  { name: "VNQ — Real Estate", allocation: 10, gain: "+6.8%" },
  { name: "VTIP — Inflation Protected", allocation: 5, gain: "+2.9%" },
];

// Mock market data for Live Market View
const MARKET_CANDLES = [
  { o: 445, h: 452, l: 440, c: 448 },
  { o: 448, h: 455, l: 446, c: 453 },
  { o: 453, h: 458, l: 449, c: 451 },
  { o: 451, h: 460, l: 448, c: 458 },
  { o: 458, h: 462, l: 454, c: 456 },
  { o: 456, h: 463, l: 452, c: 461 },
  { o: 461, h: 468, l: 457, c: 465 },
  { o: 465, h: 470, l: 460, c: 463 },
  { o: 463, h: 471, l: 459, c: 469 },
  { o: 469, h: 475, l: 466, c: 472 },
  { o: 472, h: 478, l: 468, c: 470 },
  { o: 470, h: 476, l: 465, c: 474 },
  { o: 474, h: 480, l: 471, c: 478 },
  { o: 478, h: 484, l: 474, c: 476 },
  { o: 476, h: 482, l: 472, c: 481 },
];

const DAILY_GAINERS = [
  { symbol: "NVDA", name: "NVIDIA Corp", change: "+4.82%", price: "$892.40" },
  { symbol: "SMCI", name: "Super Micro", change: "+3.91%", price: "$734.20" },
  { symbol: "META", name: "Meta Platforms", change: "+2.67%", price: "$528.15" },
  { symbol: "AMZN", name: "Amazon.com", change: "+2.14%", price: "$198.70" },
  { symbol: "TSLA", name: "Tesla Inc", change: "+1.89%", price: "$264.30" },
];

const DAILY_LOSERS = [
  { symbol: "PFE", name: "Pfizer Inc", change: "-3.21%", price: "$26.40" },
  { symbol: "BA", name: "Boeing Co", change: "-2.88%", price: "$172.50" },
  { symbol: "INTC", name: "Intel Corp", change: "-2.45%", price: "$31.80" },
  { symbol: "NKE", name: "Nike Inc", change: "-1.97%", price: "$74.20" },
  { symbol: "DIS", name: "Walt Disney", change: "-1.54%", price: "$101.30" },
];

const SECTORS = [
  { id: "tech", label: "Tech", color: "#00E5FF" },
  { id: "energy", label: "Energy", color: "#FFB800" },
  { id: "finance", label: "Finance", color: "#34D399" },
  { id: "healthcare", label: "Healthcare", color: "#C084FC" },
  { id: "consumer", label: "Consumer", color: "#FB923C" },
];

export default function Investing() {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);
  const [busy, setBusy] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [moversTab, setMoversTab] = useState("gainers");
  const [activeSector, setActiveSector] = useState(null);

  async function load() {
    try {
      const { data } = await api.get("/smart/investing");
      setAcct(data);
    } catch (e) { /* silent */ }
  }
  useEffect(() => { load(); }, []);

  async function setup() {
    setBusy(true);
    try {
      await api.post("/smart/investing/setup", {});
      toast.success("Brokerage account opened");
      await load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  const balance = acct?.balance || 0;
  const ytdGrowth = acct?.ytd_growth || 0;
  const rule = acct?.rule || {};
  const pct = Math.round((rule.fixed_percentage ?? 0.05) * 100);
  const maxVal = Math.max(...PORTFOLIO_DATA.map(d => d.value));

  if (acct === undefined) {
    return (
      <div className="p-12 font-mono animate-pulse" style={{ backgroundColor: "#0D0F12", color: "#00E5FF", minHeight: "100vh" }}>
        [ LOADING WEALTH ENGINE... ]
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
            <ChartLineUp size={32} weight="duotone" style={{ color: "#00E5FF" }} />
          </div>
          <div className="font-display text-2xl mb-2">Open your brokerage account.</div>
          <div className="text-zinc-400 text-sm mb-6 max-w-md mx-auto leading-relaxed">
            Set a small % of every payout to flow into a diversified brokerage. Milli auto-invests via dollar-cost averaging — build wealth without thinking about it.
          </div>
          <button
            onClick={setup}
            disabled={busy}
            data-testid="investing-setup-btn"
            className="btn-volt px-6 py-3 uppercase tracking-wider text-xs inline-flex items-center gap-2 disabled:opacity-50"
          >
            <Bank size={14} weight="bold" /> {busy ? "Opening..." : "Open Brokerage"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-4xl mx-auto" style={{ backgroundColor: "#0D0F12", color: "#FFFFFF", minHeight: "100%" }}>
      <PageHeader />

      {/* Search the Market + Sector View */}
      <div className="mb-5" data-testid="market-search">
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 10,
            padding: "12px 16px",
            borderRadius: 16,
            background: "rgba(13, 15, 18, 0.6)",
            border: "1px solid rgba(255, 255, 255, 0.06)",
            backdropFilter: "blur(20px)",
            marginBottom: 10,
          }}
        >
          <MagnifyingGlass size={16} weight="bold" style={{ color: "#8B9DAF", flexShrink: 0 }} />
          <input
            data-testid="market-search-input"
            type="text"
            placeholder="Search the Market"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              all: "unset",
              flex: 1,
              fontSize: 14,
              color: "#FFFFFF",
              fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif",
            }}
          />
        </div>

        {/* Sector View — scrollable badge carousel */}
        <SectorView activeSector={activeSector} onSectorChange={setActiveSector} />
      </div>

      {/* Live Market View (Candlestick Chart) */}
      <LiveMarketView candles={MARKET_CANDLES} activeSector={activeSector} />

      {/* Balance Hero */}
      <div
        className="p-7 mb-5 relative overflow-hidden rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px) brightness(1.15)", border: "1px solid rgba(0,229,255,0.1)" }}
        data-testid="investing-balance-card"
      >
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-cyan-400/40 to-transparent" />
        <div className="flex items-start justify-between flex-wrap gap-4">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <ChartLineUp size={14} weight="bold" style={{ color: "#00E5FF" }} />
              <span className="text-xs font-semibold uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>Portfolio Value</span>
            </div>
            <div className="font-chrome font-bold text-5xl sm:text-6xl tabular-nums" style={{ background: "linear-gradient(135deg, #E8E8E8, #808080)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              {money(balance)}
            </div>
            <div className="text-zinc-400 text-sm mt-2">
              {pct}% per payout · {rule.paused ? <span style={{ color: "#FFB800" }}>paused</span> : <span style={{ color: "#34D399" }}>active</span>}
            </div>
          </div>
          <div className="text-right">
            <div className="text-xs text-zinc-500 font-mono uppercase tracking-widest">YTD Return</div>
            <div className="font-chrome font-bold text-2xl" style={{ color: "#34D399" }}>
              <TrendUp size={16} weight="bold" className="inline mr-1" />
              {money(ytdGrowth)}
            </div>
          </div>
        </div>
      </div>

      {/* Daily Movers */}
      <DailyMovers tab={moversTab} onTabChange={setMoversTab} />

      {/* Portfolio Chart */}
      <div
        className="p-5 mb-5 rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
        data-testid="portfolio-chart"
      >
        <div className="flex items-center justify-between mb-4">
          <div className="text-xs font-mono uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>// Growth · 2026</div>
          <div className="text-xs text-zinc-500 font-mono">Auto-DCA Active</div>
        </div>
        <div className="flex items-end gap-2 h-32">
          {PORTFOLIO_DATA.map((d, i) => (
            <div key={i} className="flex-1 flex flex-col items-center gap-1">
              <div
                className="w-full rounded-t-lg transition-all"
                style={{
                  height: `${(d.value / maxVal) * 100}%`,
                  background: `linear-gradient(180deg, #00E5FF ${40}%, rgba(0,229,255,0.15))`,
                  boxShadow: "0 0 12px rgba(0,229,255,0.2)",
                  minHeight: 4,
                }}
              />
              <span className="text-[9px] text-zinc-600 font-mono">{d.month}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Holdings */}
      <div
        className="p-5 mb-5 rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
        data-testid="holdings-list"
      >
        <div className="text-xs font-semibold uppercase tracking-[0.2em] mb-4" style={{ color: "#00E5FF" }}>Portfolio Allocation</div>
        <div className="space-y-3">
          {HOLDINGS.map((h, i) => (
            <div key={i} className="flex items-center gap-3">
              <div className="w-8 text-right font-mono text-xs text-zinc-400">{h.allocation}%</div>
              <div className="flex-1 h-2 rounded-full overflow-hidden" style={{ background: "rgba(255,255,255,0.04)" }}>
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${h.allocation}%`,
                    background: "linear-gradient(90deg, #00E5FF, #0B7A94)",
                    boxShadow: "0 0 8px rgba(0,229,255,0.3)",
                  }}
                />
              </div>
              <div className="min-w-0 flex-1">
                <div className="text-sm font-medium text-white truncate">{h.name}</div>
              </div>
              <div className="text-xs font-mono" style={{ color: "#34D399" }}>{h.gain}</div>
            </div>
          ))}
        </div>
      </div>

      {/* DCA Explanation */}
      <div
        className="p-5 rounded-[22px]"
        style={{ background: "rgba(13,15,18,0.4)", backdropFilter: "blur(28px)", border: "1px solid rgba(255,255,255,0.03)" }}
      >
        <div className="flex items-start gap-3">
          <Info size={16} className="text-zinc-500 mt-0.5 flex-shrink-0" />
          <div className="text-xs text-zinc-500 leading-relaxed">
            <strong className="text-zinc-300">Dollar-Cost Averaging:</strong> Milli invests a fixed % from every detected payout automatically.
            This removes timing risk and builds wealth consistently over time. Investments are subject to market risk and may lose value.
            Securities offered through partner broker-dealer.
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
      <div className="font-mono text-xs uppercase tracking-[0.3em]" style={{ color: "#00E5FF" }}>// Wealth Engine · Investing</div>
      <h1 className="font-display text-3xl sm:text-4xl tracking-tight mt-1" style={{ background: "linear-gradient(135deg, #E8E8E8, #808080)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
        Build wealth on autopilot.
      </h1>
      <p className="text-zinc-400 mt-1 text-sm">Auto-invest a % from every payout into a diversified portfolio.</p>
    </div>
  );
}

function SectorView({ activeSector, onSectorChange }) {
  return (
    <div
      data-testid="sector-view"
      style={{
        display: "flex",
        gap: 8,
        overflowX: "auto",
        paddingBottom: 2,
        scrollbarWidth: "none",
        msOverflowStyle: "none",
      }}
    >
      {SECTORS.map((sector) => {
        const isActive = activeSector === sector.id;
        return (
          <button
            key={sector.id}
            data-testid={`sector-badge-${sector.id}`}
            onClick={() => onSectorChange(isActive ? null : sector.id)}
            style={{
              all: "unset",
              cursor: "pointer",
              flexShrink: 0,
              display: "inline-flex",
              alignItems: "center",
              gap: 5,
              padding: "5px 12px",
              borderRadius: 20,
              fontSize: 11,
              fontWeight: 700,
              letterSpacing: "0.05em",
              transition: "all 0.18s",
              background: isActive
                ? `rgba(${hexToRgb(sector.color)},0.15)`
                : "rgba(13,15,18,0.7)",
              border: isActive
                ? `1px solid ${sector.color}80`
                : "1px solid rgba(255,255,255,0.06)",
              color: isActive ? sector.color : "#8B9DAF",
              backdropFilter: "blur(12px)",
              boxShadow: isActive ? `0 0 10px ${sector.color}22` : "none",
            }}
          >
            <span
              style={{
                width: 5,
                height: 5,
                borderRadius: "50%",
                background: sector.color,
                opacity: isActive ? 1 : 0.4,
                flexShrink: 0,
              }}
            />
            {sector.label}
          </button>
        );
      })}
    </div>
  );
}

/* Utility: hex color to "r,g,b" string for rgba usage */
function hexToRgb(hex) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `${r},${g},${b}`;
}

function LiveMarketView({ candles, activeSector }) {
  const W = 340, H = 140;
  const padL = 5, padR = 5, padT = 15, padB = 5;
  const chartW = W - padL - padR;
  const chartH = H - padT - padB;

  const allPrices = candles.flatMap((c) => [c.h, c.l]);
  const minP = Math.min(...allPrices);
  const maxP = Math.max(...allPrices);
  const range = maxP - minP || 1;

  const candleW = chartW / candles.length;
  const bodyW = candleW * 0.5;

  // Sector label mapping for header
  const sectorLabel = activeSector
    ? SECTORS.find((s) => s.id === activeSector)?.label
    : "S&P 500";

  function yPos(price) {
    return padT + chartH - ((price - minP) / range) * chartH;
  }

  return (
    <div
      className="p-5 mb-5 rounded-[22px]"
      style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
      data-testid="live-market-view"
    >
      <div className="flex items-center justify-between mb-3">
        <div className="text-xs font-mono uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>
          // Live Market · {sectorLabel}
        </div>
        <div className="flex items-center gap-2">
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#34D399", boxShadow: "0 0 6px rgba(52,211,153,0.6)" }} />
          <span className="text-[10px] text-zinc-500 font-mono uppercase">Live</span>
        </div>
      </div>
      <div style={{ width: "100%", maxWidth: W, margin: "0 auto" }}>
        <svg viewBox={`0 0 ${W} ${H}`} width="100%" height="auto" style={{ display: "block" }}>
          <defs>
            <filter id="candle-glow">
              <feGaussianBlur stdDeviation="1.5" result="glow" />
              <feMerge>
                <feMergeNode in="glow" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>

          {/* Grid lines */}
          {[0.25, 0.5, 0.75].map((frac) => (
            <line
              key={frac}
              x1={padL}
              y1={padT + chartH * (1 - frac)}
              x2={padL + chartW}
              y2={padT + chartH * (1 - frac)}
              stroke="rgba(255,255,255,0.03)"
              strokeWidth="1"
            />
          ))}

          {/* Candlesticks */}
          {candles.map((c, i) => {
            const cx = padL + (i + 0.5) * candleW;
            const bullish = c.c >= c.o;
            const color = bullish ? "#00E5FF" : "#FF4D6A";
            const bodyTop = yPos(Math.max(c.o, c.c));
            const bodyBot = yPos(Math.min(c.o, c.c));
            const bodyH = Math.max(bodyBot - bodyTop, 1);

            return (
              <g key={i} filter="url(#candle-glow)">
                {/* Wick */}
                <line
                  x1={cx} y1={yPos(c.h)}
                  x2={cx} y2={yPos(c.l)}
                  stroke={color}
                  strokeWidth="1"
                  opacity="0.6"
                />
                {/* Body */}
                <rect
                  x={cx - bodyW / 2}
                  y={bodyTop}
                  width={bodyW}
                  height={bodyH}
                  fill={bullish ? color : color}
                  rx="1"
                  opacity="0.9"
                />
              </g>
            );
          })}
        </svg>
      </div>
      <div className="flex items-center justify-between mt-2">
        <span className="text-[10px] text-zinc-500 font-mono">15 periods</span>
        <span className="text-[11px] font-mono font-semibold" style={{ color: "#00E5FF" }}>
          $481.00
        </span>
      </div>
    </div>
  );
}

function DailyMovers({ tab, onTabChange }) {
  const movers = tab === "gainers" ? DAILY_GAINERS : DAILY_LOSERS;

  return (
    <div
      className="p-5 mb-5 rounded-[22px]"
      style={{ background: "rgba(13,15,18,0.5)", backdropFilter: "blur(28px)", border: "1px solid rgba(0,229,255,0.06)" }}
      data-testid="daily-movers"
    >
      {/* Cinematic section header */}
      <div className="mb-4">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-xs font-mono uppercase tracking-[0.2em]" style={{ color: "#00E5FF" }}>
              // Daily Movers
            </div>
            <div
              className="text-[11px] font-semibold uppercase tracking-[0.18em] mt-0.5"
              style={{ color: "#3A3F47", letterSpacing: "0.22em" }}
            >
              Highest Daily Movers
            </div>
          </div>
          <div style={{ display: "flex", gap: 4 }}>
            <button
              data-testid="movers-gainers-tab"
              onClick={() => onTabChange("gainers")}
              style={{
                all: "unset",
                cursor: "pointer",
                fontSize: 10,
                fontWeight: 600,
                padding: "4px 10px",
                borderRadius: 8,
                background: tab === "gainers" ? "rgba(0,229,255,0.1)" : "transparent",
                border: tab === "gainers" ? "1px solid rgba(0,229,255,0.3)" : "1px solid rgba(255,255,255,0.06)",
                color: tab === "gainers" ? "#00E5FF" : "#8B9DAF",
              }}
            >
              Gainers
            </button>
            <button
              data-testid="movers-losers-tab"
              onClick={() => onTabChange("losers")}
              style={{
                all: "unset",
                cursor: "pointer",
                fontSize: 10,
                fontWeight: 600,
                padding: "4px 10px",
                borderRadius: 8,
                background: tab === "losers" ? "rgba(255,77,106,0.1)" : "transparent",
                border: tab === "losers" ? "1px solid rgba(255,77,106,0.3)" : "1px solid rgba(255,255,255,0.06)",
                color: tab === "losers" ? "#FF4D6A" : "#8B9DAF",
              }}
            >
              Losers
            </button>
          </div>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {movers.map((m, i) => {
          const isMilliPick = tab === "gainers" && i < 2;

          return (
            <div
              key={m.symbol}
              data-testid={`mover-${m.symbol}`}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 12,
                padding: "10px 12px",
                borderRadius: 12,
                background: isMilliPick
                  ? "linear-gradient(135deg, rgba(0,229,255,0.05), rgba(5,6,7,0.8))"
                  : "rgba(5, 6, 7, 0.6)",
                border: isMilliPick
                  ? "1px solid rgba(0,229,255,0.14)"
                  : "1px solid rgba(255,255,255,0.04)",
                position: "relative",
                overflow: "hidden",
              }}
            >
              {/* Subtle top-edge shimmer for MILLI PICK rows */}
              {isMilliPick && (
                <div style={{
                  position: "absolute",
                  top: 0, left: 0, right: 0,
                  height: 1,
                  background: "linear-gradient(90deg, transparent, rgba(0,229,255,0.4), transparent)",
                }} />
              )}

              <div style={{
                width: 28, height: 28, borderRadius: 8,
                background: tab === "gainers" ? "rgba(0,229,255,0.08)" : "rgba(255,77,106,0.08)",
                display: "flex", alignItems: "center", justifyContent: "center",
                flexShrink: 0,
              }}>
                {tab === "gainers"
                  ? <ArrowUp size={14} weight="bold" style={{ color: "#00E5FF" }} />
                  : <ArrowDown size={14} weight="bold" style={{ color: "#FF4D6A" }} />
                }
              </div>

              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 2 }}>
                  <span style={{ fontSize: 13, fontWeight: 700, color: "#FFFFFF" }}>{m.symbol}</span>
                  {/* MILLI PICK badge — top 2 gainers only */}
                  {isMilliPick && (
                    <span
                      data-testid={`milli-pick-${m.symbol}`}
                      style={{
                        display: "inline-flex",
                        alignItems: "center",
                        gap: 3,
                        padding: "1px 6px",
                        borderRadius: 5,
                        fontSize: 8,
                        fontWeight: 800,
                        letterSpacing: "0.12em",
                        background: "linear-gradient(90deg, rgba(0,229,255,0.18), rgba(0,229,255,0.08))",
                        border: "1px solid rgba(0,229,255,0.35)",
                        color: "#00E5FF",
                        flexShrink: 0,
                      }}
                    >
                      <Star size={7} weight="fill" />
                      MILLI PICK
                    </span>
                  )}
                </div>
                <div style={{ fontSize: 10, color: "#8B9DAF", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{m.name}</div>
              </div>

              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: "#E8E8E8", fontFamily: "monospace" }}>{m.price}</div>
                <div style={{
                  fontSize: 11, fontWeight: 700, fontFamily: "monospace",
                  color: tab === "gainers" ? "#00E5FF" : "#FF4D6A",
                  marginTop: 1,
                }}>
                  {m.change}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Strategy footnote for gainers */}
      {tab === "gainers" && (
        <div
          style={{
            marginTop: 12,
            paddingTop: 10,
            borderTop: "1px solid rgba(255,255,255,0.04)",
            display: "flex",
            alignItems: "center",
            gap: 6,
          }}
        >
          <Star size={10} weight="fill" style={{ color: "#00E5FF", flexShrink: 0 }} />
          <span style={{ fontSize: 10, color: "#5A6573", fontStyle: "italic", letterSpacing: "0.02em" }}>
            MILLI PICK — Aligned with your Aggressive Growth strategy
          </span>
        </div>
      )}
    </div>
  );
}
