/**
 * Investing.jsx — v4.3 Senior Defense
 *
 * Cinematic Investing page matching mockup:
 * - Hero: Elite Spend Card
 * - Market Overview: Large candlestick chart with time toggles
 * - Two-column: Today's Gain/Loss + Buying Power
 * - Watchlist with logos, symbols, prices, % changes
 * - Asset Allocation donut chart
 * - Footer: Milli AI Insight card
 */
import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ChartLineUp, TrendUp, Sparkle, Coins, ArrowUp, ArrowDown,
} from "@phosphor-icons/react";
import { EliteSpendCard } from "@/components/MilliPrimitives";

const CANDLES = [
  { o: 445, h: 452, l: 440, c: 448 },
  { o: 448, h: 455, l: 444, c: 453 },
  { o: 453, h: 458, l: 449, c: 451 },
  { o: 451, h: 460, l: 448, c: 458 },
  { o: 458, h: 462, l: 454, c: 456 },
  { o: 456, h: 463, l: 450, c: 461 },
  { o: 461, h: 468, l: 457, c: 465 },
  { o: 465, h: 470, l: 460, c: 463 },
  { o: 463, h: 471, l: 459, c: 469 },
  { o: 469, h: 475, l: 466, c: 472 },
  { o: 472, h: 478, l: 468, c: 470 },
  { o: 470, h: 476, l: 463, c: 474 },
  { o: 474, h: 480, l: 471, c: 478 },
  { o: 478, h: 484, l: 474, c: 476 },
  { o: 476, h: 485, l: 472, c: 483 },
  { o: 483, h: 490, l: 479, c: 487 },
  { o: 487, h: 492, l: 483, c: 485 },
  { o: 485, h: 491, l: 480, c: 489 },
  { o: 489, h: 496, l: 486, c: 493 },
  { o: 493, h: 498, l: 489, c: 495 },
];

const WATCHLIST = [
  { symbol: "AAPL", name: "Apple Inc", price: "$198.45", change: "+1.82%", up: true, logo: "🍎" },
  { symbol: "NVDA", name: "NVIDIA Corp", price: "$892.40", change: "+4.12%", up: true, logo: "🟢" },
  { symbol: "TSLA", name: "Tesla Inc", price: "$264.30", change: "-0.85%", up: false, logo: "⚡" },
  { symbol: "MSFT", name: "Microsoft", price: "$442.18", change: "+0.94%", up: true, logo: "🟦" },
  { symbol: "AMZN", name: "Amazon", price: "$198.70", change: "+2.14%", up: true, logo: "📦" },
];

const ALLOCATION = [
  { label: "Stocks", pct: 55, color: "#00E5FF" },
  { label: "ETFs", pct: 25, color: "#34D399" },
  { label: "Cash", pct: 12, color: "#FFB800" },
  { label: "Crypto", pct: 8, color: "#C084FC" },
];

const TIME_TOGGLES = ["1D", "1W", "1M", "1Y", "All"];

export default function Investing() {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);
  const [timeRange, setTimeRange] = useState("1M");

  async function load() {
    try {
      const { data } = await api.get("/smart/investing");
      setAcct(data);
    } catch (e) { /* silent */ }
  }
  useEffect(() => { load(); }, []);

  if (acct === undefined) {
    return (
      <div style={{
        padding: 48, fontFamily: 'monospace',
        backgroundColor: '#0D0F12', color: '#00E5FF', minHeight: '100vh',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div className="animate-pulse">[ LOADING WEALTH ENGINE... ]</div>
      </div>
    );
  }

  const todayGain = 1247.83;
  const todayPct = 2.34;
  const buyingPower = 8420.00;

  return (
    <div style={{
      padding: '24px 16px',
      maxWidth: 600,
      margin: '0 auto',
      minHeight: '100vh',
      backgroundColor: '#0D0F12',
      color: '#FFFFFF',
    }}>

      {/* ═══════════════════════════════════════
          HEADER
          ═══════════════════════════════════════ */}
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 10, fontFamily: 'monospace', letterSpacing: '0.3em', textTransform: 'uppercase', color: '#00E5FF' }}>
          // Wealth Engine · Investing
        </div>
        <h1 style={{
          fontSize: 28, fontWeight: 800, marginTop: 4, lineHeight: 1.2,
          background: 'linear-gradient(135deg, #E8E8E8, #808080)',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
        }}>
          Build wealth on autopilot.
        </h1>
      </div>

      {/* ═══════════════════════════════════════
          HERO — Elite Spend Card
          ═══════════════════════════════════════ */}
      <div style={{ marginBottom: 16 }} data-testid="investing-elite-card">
        <EliteSpendCard available={24560.00} accountMask="•••• 4821" />
      </div>

      {/* ═══════════════════════════════════════
          MARKET OVERVIEW — Candlestick Chart
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.08)',
        borderRadius: 22,
        padding: '24px 20px',
        marginBottom: 16,
      }} data-testid="market-overview">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
              Market Overview
            </div>
            <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace', marginTop: 2 }}>
              S&P 500 · $4,950.23
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#34D399', boxShadow: '0 0 6px rgba(52,211,153,0.6)' }}/>
            <span style={{ fontSize: 9, color: '#5A6573', fontFamily: 'monospace' }}>LIVE</span>
          </div>
        </div>

        {/* Time toggles */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 16 }}>
          {TIME_TOGGLES.map(t => (
            <button key={t} onClick={() => setTimeRange(t)} style={{
              all: 'unset', cursor: 'pointer',
              fontSize: 10, fontWeight: 700, padding: '4px 10px', borderRadius: 8,
              background: timeRange === t ? 'rgba(0,229,255,0.12)' : 'transparent',
              border: timeRange === t ? '1px solid rgba(0,229,255,0.3)' : '1px solid rgba(255,255,255,0.04)',
              color: timeRange === t ? '#00E5FF' : '#5A6573',
              transition: 'all 0.15s',
            }}>
              {t}
            </button>
          ))}
        </div>

        {/* Candlestick chart */}
        <CandlestickChart candles={CANDLES} />
      </div>

      {/* ═══════════════════════════════════════
          TWO-COLUMN — Today's Gain/Loss + Buying Power
          ═══════════════════════════════════════ */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }} data-testid="gain-buying-row">
        {/* Today's Gain/Loss */}
        <div style={{
          background: 'rgba(13,15,18,0.5)',
          backdropFilter: 'blur(28px)',
          border: '1px solid rgba(0,229,255,0.08)',
          borderRadius: 18,
          padding: '20px 16px',
        }}>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#8B9DAF', marginBottom: 8 }}>
            Today's Gain
          </div>
          <div style={{ fontSize: 22, fontWeight: 800, color: '#34D399', fontFamily: "'SF Pro Display', -apple-system, sans-serif", marginBottom: 4 }}>
            +${todayGain.toLocaleString('en-US', { minimumFractionDigits: 2 })}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: '#34D399' }}>
            <ArrowUp size={12} weight="bold" />
            <span style={{ fontFamily: 'monospace' }}>+{todayPct}%</span>
          </div>
          {/* Mini sparkline */}
          <svg width="100%" height="24" viewBox="0 0 100 24" style={{ marginTop: 8 }}>
            <path d="M0 20 L10 16 L20 18 L30 12 L40 14 L50 8 L60 10 L70 6 L80 8 L90 4 L100 2"
              fill="none" stroke="#34D399" strokeWidth="1.5" strokeLinecap="round" opacity="0.8"/>
          </svg>
        </div>

        {/* Buying Power */}
        <div style={{
          background: 'rgba(13,15,18,0.5)',
          backdropFilter: 'blur(28px)',
          border: '1px solid rgba(0,229,255,0.08)',
          borderRadius: 18,
          padding: '20px 16px',
        }}>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#8B9DAF', marginBottom: 8 }}>
            Buying Power
          </div>
          <div style={{ fontSize: 22, fontWeight: 800, color: '#FFFFFF', fontFamily: "'SF Pro Display', -apple-system, sans-serif", marginBottom: 4 }}>
            ${buyingPower.toLocaleString('en-US', { minimumFractionDigits: 2 })}
          </div>
          <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
            Available to invest
          </div>
          {/* Stacked coin icons */}
          <div style={{ marginTop: 8, display: 'flex', gap: -4 }}>
            {[0,1,2].map(i => (
              <div key={i} style={{
                width: 20, height: 20, borderRadius: '50%',
                background: 'linear-gradient(135deg, #C0C0C0, #808080)',
                border: '1px solid rgba(255,255,255,0.2)',
                marginLeft: i > 0 ? -6 : 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 8, fontWeight: 800, color: '#FFD700',
              }}>$</div>
            ))}
          </div>
        </div>
      </div>

      {/* ═══════════════════════════════════════
          WATCHLIST
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.08)',
        borderRadius: 22,
        overflow: 'hidden',
        marginBottom: 16,
      }} data-testid="watchlist">
        <div style={{
          padding: '16px 20px',
          borderBottom: '1px solid rgba(255,255,255,0.03)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
            Watchlist
          </span>
          <span style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
            {WATCHLIST.length} stocks
          </span>
        </div>
        {WATCHLIST.map((stock, i) => (
          <div key={stock.symbol} style={{
            display: 'flex', alignItems: 'center', padding: '14px 20px', gap: 12,
            borderBottom: i < WATCHLIST.length - 1 ? '1px solid rgba(255,255,255,0.03)' : 'none',
          }}>
            {/* Logo */}
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'rgba(0,229,255,0.06)', border: '1px solid rgba(0,229,255,0.12)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 16, flexShrink: 0,
            }}>
              {stock.logo}
            </div>
            {/* Symbol + Name */}
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: '#FFFFFF' }}>{stock.symbol}</div>
              <div style={{ fontSize: 11, color: '#5A6573' }}>{stock.name}</div>
            </div>
            {/* Price + Change */}
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 14, fontWeight: 600, color: '#FFFFFF', fontFamily: 'monospace' }}>{stock.price}</div>
              <div style={{
                fontSize: 11, fontWeight: 700, fontFamily: 'monospace',
                color: stock.up ? '#34D399' : '#FF4D6A',
                display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 2,
              }}>
                {stock.up ? <ArrowUp size={10} weight="bold"/> : <ArrowDown size={10} weight="bold"/>}
                {stock.change}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* ═══════════════════════════════════════
          ASSET ALLOCATION — Donut Chart
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.06)',
        borderRadius: 22,
        padding: '24px 20px',
        marginBottom: 16,
      }} data-testid="asset-allocation">
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF', marginBottom: 20 }}>
          Asset Allocation
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 24, flexWrap: 'wrap' }}>
          {/* Donut */}
          <DonutChart data={ALLOCATION} />
          {/* Legend */}
          <div style={{ flex: 1, minWidth: 120 }}>
            {ALLOCATION.map((a, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <div style={{ width: 10, height: 10, borderRadius: 3, background: a.color, flexShrink: 0 }}/>
                <span style={{ fontSize: 12, color: '#FFFFFF', flex: 1 }}>{a.label}</span>
                <span style={{ fontSize: 12, fontWeight: 700, color: a.color, fontFamily: 'monospace' }}>{a.pct}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ═══════════════════════════════════════
          FOOTER — Milli AI Insight
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'linear-gradient(135deg, rgba(0,229,255,0.04), rgba(13,15,18,0.6))',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.15)',
        borderRadius: 22,
        padding: '20px',
        marginBottom: 32,
        position: 'relative',
        overflow: 'hidden',
      }} data-testid="ai-insight-card">
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 1,
          background: 'linear-gradient(90deg, transparent, rgba(0,229,255,0.4), transparent)',
        }}/>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 12,
            background: 'rgba(0,229,255,0.1)', border: '1px solid rgba(0,229,255,0.3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            boxShadow: '0 0 20px rgba(0,229,255,0.15)',
          }}>
            <Sparkle size={20} weight="fill" style={{ color: '#00E5FF' }}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#FFFFFF', marginBottom: 4 }}>
              Milli AI Insight
            </div>
            <div style={{ fontSize: 12, color: '#8B9DAF', lineHeight: 1.5, marginBottom: 8 }}>
              Your portfolio is outperforming the S&P 500 by 3.2% this quarter. Consider rebalancing crypto allocation if it exceeds 10%.
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ height: 4, flex: 1, borderRadius: 2, background: 'rgba(255,255,255,0.04)', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: '87%', borderRadius: 2, background: 'linear-gradient(90deg, #00E5FF, #34D399)' }}/>
              </div>
              <span style={{ fontSize: 9, color: '#00E5FF', fontFamily: 'monospace', fontWeight: 700 }}>87% confidence</span>
            </div>
          </div>
        </div>
      </div>

      {/* Floating AI Sphere */}
      <FloatingAISphere />
    </div>
  );
}

/* ─── Sub-components ─── */

function CandlestickChart({ candles }) {
  if (!Array.isArray(candles) || candles.length < 2) {
    return (
      <div style={{
        padding: '32px 16px',
        textAlign: 'center',
        color: '#5A6573',
        fontFamily: 'monospace',
        fontSize: 12,
      }} data-testid="candlestick-placeholder">
        Waiting for more data...
      </div>
    );
  }

  const W = 340, H = 180;
  const padL = 5, padR = 5, padT = 10, padB = 10;
  const chartW = W - padL - padR;
  const chartH = H - padT - padB;

  const allPrices = candles.flatMap(c => [c.h, c.l]);
  const minP = Math.min(...allPrices);
  const maxP = Math.max(...allPrices);
  const range = maxP - minP || 1;

  const candleW = chartW / candles.length;
  const bodyW = candleW * 0.55;

  function yPos(price) {
    return padT + chartH - ((price - minP) / range) * chartH;
  }

  return (
    <div style={{ width: '100%', maxWidth: W, margin: '0 auto' }}>
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" height="auto" style={{ display: 'block' }}>
        <defs>
          <filter id="candle-glow-v4">
            <feGaussianBlur stdDeviation="1.5" result="glow"/>
            <feMerge>
              <feMergeNode in="glow"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>
        </defs>

        {/* Grid */}
        {[0.25, 0.5, 0.75].map(frac => (
          <line key={frac} x1={padL} y1={padT + chartH * (1 - frac)} x2={padL + chartW} y2={padT + chartH * (1 - frac)} stroke="rgba(255,255,255,0.03)" strokeWidth="0.5"/>
        ))}

        {/* Candles */}
        {candles.map((c, i) => {
          const cx = padL + (i + 0.5) * candleW;
          const bullish = c.c >= c.o;
          const color = bullish ? "#00E5FF" : "#FF4D6A";
          const bodyTop = yPos(Math.max(c.o, c.c));
          const bodyBot = yPos(Math.min(c.o, c.c));
          const bodyH = Math.max(bodyBot - bodyTop, 1.5);

          return (
            <g key={i} filter="url(#candle-glow-v4)">
              <line x1={cx} y1={yPos(c.h)} x2={cx} y2={yPos(c.l)} stroke={color} strokeWidth="1" opacity="0.7"/>
              <rect x={cx - bodyW / 2} y={bodyTop} width={bodyW} height={bodyH} fill={color} rx="1" opacity="0.9"/>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

function DonutChart({ data }) {
  if (!Array.isArray(data) || data.length === 0) {
    return (
      <div style={{
        width: 120, height: 120, flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#5A6573', fontFamily: 'monospace', fontSize: 11,
      }} data-testid="donut-placeholder">
        No allocation data
      </div>
    );
  }

  const size = 120;
  const cx = size / 2, cy = size / 2;
  const r = 44;
  const strokeWidth = 14;
  const circumference = 2 * Math.PI * r;
  let offset = 0;

  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        {data.map((seg, i) => {
          const dash = (seg.pct / 100) * circumference;
          const gap = circumference - dash;
          const currentOffset = offset;
          offset += dash;
          return (
            <circle key={i}
              cx={cx} cy={cy} r={r}
              fill="none"
              stroke={seg.color}
              strokeWidth={strokeWidth}
              strokeDasharray={`${dash} ${gap}`}
              strokeDashoffset={-currentOffset}
              style={{ transform: 'rotate(-90deg)', transformOrigin: '50% 50%' }}
              opacity="0.9"
            />
          );
        })}
      </svg>
      {/* Center label */}
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ fontSize: 16, fontWeight: 800, color: '#FFFFFF' }}>100%</div>
        <div style={{ fontSize: 8, color: '#5A6573', fontFamily: 'monospace', letterSpacing: '0.1em' }}>INVESTED</div>
      </div>
    </div>
  );
}

function FloatingAISphere() {
  return (
    <div style={{
      position: 'fixed',
      bottom: 90,
      right: 20,
      width: 56,
      height: 56,
      borderRadius: '50%',
      overflow: 'hidden',
      boxShadow: '0 0 30px rgba(0,229,255,0.3), 0 0 60px rgba(0,229,255,0.1)',
      border: '2px solid rgba(0,229,255,0.3)',
      zIndex: 100,
      cursor: 'pointer',
    }} data-testid="floating-ai-sphere">
      <img
        src="/weebo/milli-ai-sphere.png"
        alt="Milli AI"
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
      />
    </div>
  );
}
