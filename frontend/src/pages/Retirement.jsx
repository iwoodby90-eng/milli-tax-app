/**
 * Retirement.jsx — v4.1 Hollywood Blueprint Lock
 *
 * Cinematic 401(k) page:
 * - Hero: "Projected Balance" with glowing tree asset
 * - Main: 10-year projection graph with glowing cyan line
 * - Grid: "Your Contribution", "Employer Match", "Goal Progress"
 * - Footer: "Scenario Comparison" horizontal cards
 */
import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  PiggyBank, TrendUp, Info, Sparkle, Target, ArrowUp,
} from "@phosphor-icons/react";

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

const SCENARIOS = [
  { label: "Conservative", rate: "6%", projected: "$245,000", color: "#8B9DAF" },
  { label: "Moderate", rate: "8%", projected: "$330,000", color: "#00E5FF" },
  { label: "Aggressive", rate: "11%", projected: "$480,000", color: "#34D399" },
];

export default function Retirement() {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);

  async function load() {
    try {
      const { data } = await api.get("/smart/retirement");
      setAcct(data);
    } catch (e) { /* silent */ }
  }
  useEffect(() => { load(); }, []);

  const balance = acct?.balance || 12000;
  const ytdContributed = acct?.ytd_contributed || balance * 0.6;
  const goalTarget = 330000;
  const goalProgress = Math.min(Math.round((balance / goalTarget) * 100), 100);

  if (acct === undefined) {
    return (
      <div style={{
        padding: 48, fontFamily: 'monospace',
        backgroundColor: '#0D0F12', color: '#00E5FF', minHeight: '100vh',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div className="animate-pulse">[ LOADING SOLO 401(k)... ]</div>
      </div>
    );
  }

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
          // Wealth Engine · Solo 401(k)
        </div>
        <h1 style={{
          fontSize: 28, fontWeight: 800, marginTop: 4, lineHeight: 1.2,
          background: 'linear-gradient(135deg, #E8E8E8, #808080)',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
        }}>
          Pay your future self first.
        </h1>
      </div>

      {/* ═══════════════════════════════════════
          HERO — Projected Balance with Growth Tree
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.1)',
        borderRadius: 24,
        padding: '32px 24px',
        marginBottom: 16,
        position: 'relative',
        overflow: 'hidden',
        textAlign: 'center',
      }} data-testid="retirement-hero">
        {/* Top glow line */}
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 1,
          background: 'linear-gradient(90deg, transparent, rgba(0,229,255,0.5), transparent)',
        }}/>

        {/* Growth Tree Image */}
        <div style={{
          width: 140, height: 140, margin: '0 auto 20px',
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute', inset: -10,
            background: 'radial-gradient(circle, rgba(0,229,255,0.12) 0%, transparent 70%)',
            borderRadius: '50%',
          }}/>
          <img
            src="/weebo/milli-growth-tree.png"
            alt="Growth Tree"
            style={{ width: '100%', height: '100%', objectFit: 'contain', position: 'relative' }}
          />
        </div>

        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#8B9DAF', marginBottom: 8 }}>
          Projected Balance · 2035
        </div>
        <div style={{
          fontSize: 48, fontWeight: 800, lineHeight: 1,
          background: 'linear-gradient(135deg, #FFFFFF, #C0C0C0)',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          fontFamily: "'SF Pro Display', -apple-system, sans-serif",
          marginBottom: 8,
        }} data-testid="projected-balance">
          $330,000
        </div>
        <div style={{ fontSize: 12, color: '#34D399', fontFamily: 'monospace', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4 }}>
          <TrendUp size={14} weight="bold" />
          <span>+8% avg. annual return</span>
        </div>
      </div>

      {/* ═══════════════════════════════════════
          10-Year Growth Projection Graph
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.06)',
        borderRadius: 22,
        padding: '24px 20px',
        marginBottom: 16,
      }} data-testid="growth-projection-graph">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
            10-Year Projection
          </span>
          <span style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
            Compound Growth
          </span>
        </div>

        <GrowthGraph data={GROWTH_PROJECTION} />
      </div>

      {/* ═══════════════════════════════════════
          GRID — Contribution, Match, Goal Progress
          ═══════════════════════════════════════ */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr 1fr',
        gap: 12,
        marginBottom: 16,
      }} data-testid="retirement-grid">
        <StatCard
          label="Your Contribution"
          value={money(ytdContributed)}
          sub="YTD"
          color="#00E5FF"
        />
        <StatCard
          label="Employer Match"
          value="3%"
          sub="Coming Soon"
          color="#34D399"
        />
        <StatCard
          label="Goal Progress"
          value={`${goalProgress}%`}
          sub={`of ${money(goalTarget)}`}
          color="#FFB800"
          progress={goalProgress}
        />
      </div>

      {/* ═══════════════════════════════════════
          FOOTER — Scenario Comparison
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.06)',
        borderRadius: 22,
        padding: '20px',
        marginBottom: 32,
      }} data-testid="scenario-comparison">
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF', marginBottom: 16 }}>
          Scenario Comparison
        </div>
        <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 4 }}>
          {SCENARIOS.map((s, i) => (
            <div key={i} style={{
              flex: '0 0 auto',
              minWidth: 140,
              background: 'rgba(5,6,7,0.6)',
              border: `1px solid ${s.color}30`,
              borderRadius: 16,
              padding: '16px 14px',
              textAlign: 'center',
            }}>
              <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.1em', color: s.color, marginBottom: 6, textTransform: 'uppercase' }}>
                {s.label}
              </div>
              <div style={{ fontSize: 20, fontWeight: 800, color: '#FFFFFF', marginBottom: 4, fontFamily: "'SF Pro Display', -apple-system, sans-serif" }}>
                {s.projected}
              </div>
              <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
                @ {s.rate} return
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Floating AI Sphere */}
      <FloatingAISphere />
    </div>
  );
}

/* ─── Sub-components ─── */

function GrowthGraph({ data }) {
  const W = 320, H = 160;
  const padL = 8, padR = 8, padT = 20, padB = 28;
  const chartW = W - padL - padR;
  const chartH = H - padT - padB;
  const maxVal = Math.max(...data.map(d => d.balance));

  const points = data.map((d, i) => {
    const x = padL + (i / (data.length - 1)) * chartW;
    const y = padT + chartH - (d.balance / maxVal) * chartH;
    return { x, y, ...d };
  });

  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ");
  const areaPath = `${linePath} L ${points[points.length - 1].x} ${padT + chartH} L ${points[0].x} ${padT + chartH} Z`;

  return (
    <div style={{ width: '100%', maxWidth: W, margin: '0 auto' }}>
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" height="auto" style={{ display: 'block' }}>
        <defs>
          <linearGradient id="growth-area-v4" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.25"/>
            <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.0"/>
          </linearGradient>
          <filter id="line-glow-v4">
            <feGaussianBlur stdDeviation="3" result="glow"/>
            <feMerge>
              <feMergeNode in="glow"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>
        </defs>

        {/* Grid */}
        {[0.25, 0.5, 0.75].map(frac => (
          <line key={frac} x1={padL} y1={padT + chartH - frac * chartH} x2={padL + chartW} y2={padT + chartH - frac * chartH} stroke="rgba(255,255,255,0.04)" strokeWidth="1"/>
        ))}

        {/* Area */}
        <path d={areaPath} fill="url(#growth-area-v4)"/>

        {/* Glowing line */}
        <path d={linePath} fill="none" stroke="#00E5FF" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" filter="url(#line-glow-v4)"/>

        {/* Data points + labels */}
        {points.map((p, i) => (
          <g key={i}>
            <circle cx={p.x} cy={p.y} r="3.5" fill="#0D0F12" stroke="#00E5FF" strokeWidth="2"/>
            <text x={p.x} y={padT + chartH + 16} textAnchor="middle" fill="#5A6573" fontSize="7" fontFamily="monospace">
              {p.year.slice(2)}
            </text>
            {i % 3 === 0 && (
              <text x={p.x} y={p.y - 9} textAnchor="middle" fill="#00E5FF" fontSize="7" fontFamily="monospace" fontWeight="600">
                ${Math.round(p.balance / 1000)}K
              </text>
            )}
          </g>
        ))}
      </svg>
    </div>
  );
}

function StatCard({ label, value, sub, color, progress }) {
  return (
    <div style={{
      background: 'rgba(13,15,18,0.5)',
      backdropFilter: 'blur(28px)',
      border: '1px solid rgba(255,255,255,0.04)',
      borderRadius: 16,
      padding: '16px 12px',
      textAlign: 'center',
    }}>
      <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#8B9DAF', marginBottom: 8 }}>
        {label}
      </div>
      <div style={{ fontSize: 22, fontWeight: 800, color: color, fontFamily: "'SF Pro Display', -apple-system, sans-serif", marginBottom: 4 }}>
        {value}
      </div>
      <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
        {sub}
      </div>
      {progress !== undefined && (
        <div style={{ marginTop: 8, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.04)', overflow: 'hidden' }}>
          <div style={{
            height: '100%', width: `${progress}%`, borderRadius: 2,
            background: `linear-gradient(90deg, ${color}, ${color}80)`,
            boxShadow: `0 0 8px ${color}40`,
          }}/>
        </div>
      )}
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
