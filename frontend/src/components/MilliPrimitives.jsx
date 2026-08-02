/**
 * MilliPrimitives.jsx — v4.1 Hollywood Blueprint Lock
 *
 * Cinematic design-system primitives for Milli Tax App.
 * Compose these anywhere. Each renders design-system.css classes so the
 * theme is one file to update.
 */
import { Shield, Car, ChartLineUp, Vault, Star } from "@phosphor-icons/react";


/* ---------- 1 · Tax Ready Score Gauge ---------- */
export function TaxReadyGauge({ score = 85, size = 200, label = "Tax Ready Score" }) {
    const radius = (size - 28) / 2;
    const circumference = 2 * Math.PI * radius;
    const dashoffset = circumference * (1 - Math.max(0, Math.min(100, score)) / 100);
    const status = score >= 90 ? "Excellent"
        : score >= 70 ? "Excellent"
        : score >= 40 ? "Building up"
        : "Getting started";
    return (
        <div className="milli-gauge" style={{ '--gauge-size': `${size}px`, position: 'relative', width: size, height: size, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              data-testid="tax-ready-gauge">
            <svg width={size} height={size} style={{ position: 'absolute', top: 0, left: 0 }}>
                <defs>
                    <linearGradient id="milli-gauge-grad" x1="0" y1="0" x2="1" y2="1">
                        <stop offset="0%" stopColor="#00E5FF"/>
                        <stop offset="55%" stopColor="#FFFFFF"/>
                        <stop offset="100%" stopColor="#00E5FF"/>
                    </linearGradient>
                    <filter id="gauge-glow">
                        <feGaussianBlur stdDeviation="4" result="glow"/>
                        <feMerge>
                            <feMergeNode in="glow"/>
                            <feMergeNode in="SourceGraphic"/>
                        </feMerge>
                    </filter>
                </defs>
                {/* Background track */}
                <circle cx={size / 2} cy={size / 2} r={radius}
                    fill="none" strokeWidth="10" stroke="rgba(255,255,255,0.04)"
                    className="milli-gauge__track"/>
                {/* Neon cyan ring with glow */}
                <circle cx={size / 2} cy={size / 2} r={radius}
                    fill="none" strokeWidth="10"
                    stroke="#00E5FF"
                    strokeDasharray={circumference} strokeDashoffset={dashoffset}
                    strokeLinecap="round"
                    filter="url(#gauge-glow)"
                    style={{
                        transform: 'rotate(-90deg)',
                        transformOrigin: '50% 50%',
                        transition: 'stroke-dashoffset 1s cubic-bezier(0.4, 0, 0.2, 1)',
                    }}
                    className="milli-gauge__value"/>
            </svg>
            {/* Center content */}
            <div style={{ textAlign: 'center', zIndex: 1 }}>
                <div style={{
                    fontSize: size * 0.22,
                    fontWeight: 800,
                    color: '#FFFFFF',
                    lineHeight: 1,
                    fontFamily: "'SF Pro Display', -apple-system, sans-serif",
                }} data-testid="tax-ready-gauge-value">
                    {Math.round(score)}
                </div>
                <div style={{
                    fontSize: size * 0.07,
                    fontWeight: 600,
                    color: '#00E5FF',
                    letterSpacing: '0.15em',
                    textTransform: 'uppercase',
                    marginTop: 4,
                }}>
                    {status}
                </div>
            </div>
        </div>
    );
}

/* ---------- 2 · Milli-Cents Semi-Circular Gauge Widget ---------- */
export function MilliCentsWidget({ score = 82, inline = false }) {
    const costs = [
        { label: "Pickup", value: "$12.50", icon: "📍" },
        { label: "Deadhead", value: "$3.20", icon: "🔄" },
        { label: "Gas", value: "$4.80", icon: "⛽" },
        { label: "Taxes", value: "$6.25", icon: "🏛" },
    ];

    const content = (
        <div style={{
            background: 'rgba(13,15,18,0.6)',
            backdropFilter: 'blur(28px)',
            border: '1px solid rgba(0,229,255,0.08)',
            borderRadius: 22,
            padding: '28px 24px',
            width: '100%',
        }} data-testid="milli-cents-widget">
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
                <div>
                    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
                        Milli-Cents
                    </div>
                    <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace', marginTop: 2 }}>
                        // PROFIT SCORE
                    </div>
                </div>
                <div style={{
                    fontSize: 10,
                    color: '#5A6573',
                    fontFamily: 'monospace',
                    padding: '4px 10px',
                    borderRadius: 8,
                    background: 'rgba(0,229,255,0.04)',
                    border: '1px solid rgba(0,229,255,0.1)',
                }}>
                    LIVE
                </div>
            </div>

            {/* Semi-circular gauge */}
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 20 }}>
                <SemiCircularGauge score={score} />
            </div>

            {/* Cost Breakdown Table */}
            <div style={{
                background: 'rgba(5,6,7,0.5)',
                borderRadius: 14,
                border: '1px solid rgba(255,255,255,0.04)',
                overflow: 'hidden',
            }}>
                <div style={{
                    padding: '10px 16px',
                    borderBottom: '1px solid rgba(255,255,255,0.04)',
                    display: 'flex',
                    justifyContent: 'space-between',
                }}>
                    <span style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#8B9DAF' }}>Cost Breakdown</span>
                    <span style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>Per Trip</span>
                </div>
                {costs.map((c, i) => (
                    <div key={i} style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '12px 16px',
                        borderBottom: i < costs.length - 1 ? '1px solid rgba(255,255,255,0.03)' : 'none',
                    }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <span style={{ fontSize: 14 }}>{c.icon}</span>
                            <span style={{ fontSize: 13, color: '#FFFFFF', fontWeight: 500 }}>{c.label}</span>
                        </div>
                        <span style={{ fontSize: 13, fontFamily: 'monospace', color: '#00E5FF', fontWeight: 600 }}>{c.value}</span>
                    </div>
                ))}
            </div>
        </div>
    );

    return content;
}

function SemiCircularGauge({ score = 82 }) {
    const size = 180;
    const cx = size / 2;
    const cy = size / 2 + 10;
    const r = 65;
    const startAngle = -180;
    const endAngle = 0;
    const sweepTotal = endAngle - startAngle;
    const normalized = Math.max(0, Math.min(100, score)) / 100;
    const filledEnd = startAngle + normalized * sweepTotal;

    const arcBg = describeArc(cx, cy, r, startAngle, endAngle);
    const arcFilled = describeArc(cx, cy, r, startAngle, filledEnd);

    return (
        <div style={{ position: 'relative', width: size, height: size * 0.6 }}>
            <svg width={size} height={size * 0.7} viewBox={`0 0 ${size} ${size * 0.7}`}>
                <defs>
                    <filter id="semi-glow">
                        <feGaussianBlur stdDeviation="3" result="glow"/>
                        <feMerge>
                            <feMergeNode in="glow"/>
                            <feMergeNode in="SourceGraphic"/>
                        </feMerge>
                    </filter>
                    <linearGradient id="semi-grad" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stopColor="#FF3B5C"/>
                        <stop offset="50%" stopColor="#FFB800"/>
                        <stop offset="100%" stopColor="#00E5FF"/>
                    </linearGradient>
                </defs>
                {/* Background arc */}
                <path d={arcBg} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="10" strokeLinecap="round"/>
                {/* Filled arc */}
                <path d={arcFilled} fill="none" stroke="url(#semi-grad)" strokeWidth="10" strokeLinecap="round" filter="url(#semi-glow)"/>
            </svg>
            {/* Center text */}
            <div style={{
                position: 'absolute',
                bottom: 0,
                left: '50%',
                transform: 'translateX(-50%)',
                textAlign: 'center',
            }}>
                <div style={{
                    fontSize: 36,
                    fontWeight: 800,
                    color: '#FFFFFF',
                    lineHeight: 1,
                    fontFamily: "'SF Pro Display', -apple-system, sans-serif",
                }}>
                    {score}<span style={{ fontSize: 18, color: '#5A6573' }}>/100</span>
                </div>
                <div style={{
                    fontSize: 10,
                    fontWeight: 600,
                    color: '#00E5FF',
                    letterSpacing: '0.2em',
                    textTransform: 'uppercase',
                    marginTop: 2,
                }}>
                    Profit Score
                </div>
            </div>
        </div>
    );
}

/* ---------- 3 · Elite Spend Card ---------- */
export function EliteSpendCard({
    available = 24560.00,
    accountMask = "•••• 4821",
}) {
    return (
        <div style={{
            background: 'rgba(13,15,18,0.5)',
            backdropFilter: 'blur(32px)',
            border: '1px solid rgba(0,229,255,0.2)',
            borderRadius: 24,
            padding: '32px 28px',
            position: 'relative',
            overflow: 'hidden',
            boxShadow: '0 0 60px rgba(0,229,255,0.06), inset 0 1px 0 rgba(255,255,255,0.04)',
        }} data-testid="elite-spend-card">
            {/* Glowing border effect */}
            <div style={{
                position: 'absolute',
                top: 0, left: 0, right: 0, height: 1,
                background: 'linear-gradient(90deg, transparent, rgba(0,229,255,0.5), transparent)',
            }}/>
            <div style={{
                position: 'absolute',
                bottom: 0, left: 0, right: 0, height: 1,
                background: 'linear-gradient(90deg, transparent, rgba(0,229,255,0.3), transparent)',
            }}/>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 20 }}>
                {/* Left side: Amount info */}
                <div style={{ flex: 1, minWidth: 200 }}>
                    <div style={{
                        fontSize: 11,
                        fontWeight: 600,
                        letterSpacing: '0.2em',
                        textTransform: 'uppercase',
                        color: '#8B9DAF',
                        marginBottom: 8,
                    }}>
                        Available to Spend
                    </div>
                    <div style={{
                        fontSize: 42,
                        fontWeight: 800,
                        lineHeight: 1,
                        background: 'linear-gradient(135deg, #FFFFFF, #C0C0C0)',
                        WebkitBackgroundClip: 'text',
                        WebkitTextFillColor: 'transparent',
                        fontFamily: "'SF Pro Display', -apple-system, sans-serif",
                        marginBottom: 10,
                    }} data-testid="elite-spend-amount">
                        ${available.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </div>
                    <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 8,
                    }}>
                        <div style={{
                            fontSize: 12,
                            color: '#5A6573',
                            fontFamily: 'monospace',
                            letterSpacing: '0.1em',
                        }}>
                            {accountMask}
                        </div>
                        <div style={{
                            fontSize: 9,
                            padding: '3px 8px',
                            borderRadius: 6,
                            background: 'rgba(0,229,255,0.08)',
                            border: '1px solid rgba(0,229,255,0.2)',
                            color: '#00E5FF',
                            fontWeight: 700,
                            letterSpacing: '0.1em',
                        }}>
                            ELITE
                        </div>
                    </div>
                </div>

                {/* Right side: Card visual */}
                <div style={{
                    width: 160,
                    height: 100,
                    borderRadius: 14,
                    background: 'linear-gradient(135deg, #1a1a2e 0%, #0D0F12 50%, #1a1a2e 100%)',
                    border: '1px solid rgba(0,229,255,0.2)',
                    position: 'relative',
                    overflow: 'hidden',
                    boxShadow: '0 8px 32px rgba(0,0,0,0.5), 0 0 20px rgba(0,229,255,0.1)',
                    transform: 'rotate(-5deg)',
                    flexShrink: 0,
                }}>
                    {/* Diagonal split */}
                    <div style={{
                        position: 'absolute',
                        top: 0, left: 0, right: 0, bottom: 0,
                        background: 'linear-gradient(135deg, rgba(0,229,255,0.08) 0%, transparent 50%, rgba(192,192,192,0.05) 100%)',
                    }}/>
                    {/* Card chip */}
                    <div style={{
                        position: 'absolute',
                        top: 18,
                        left: 16,
                        width: 28,
                        height: 20,
                        borderRadius: 4,
                        background: 'linear-gradient(135deg, #C0A040, #FFD700, #C0A040)',
                        border: '1px solid rgba(255,215,0,0.3)',
                    }}/>
                    {/* VISA text */}
                    <div style={{
                        position: 'absolute',
                        bottom: 12,
                        right: 14,
                        fontSize: 14,
                        fontWeight: 800,
                        fontStyle: 'italic',
                        color: 'rgba(255,255,255,0.7)',
                        letterSpacing: '0.05em',
                    }}>
                        VISA
                    </div>
                    {/* MILLI branding */}
                    <div style={{
                        position: 'absolute',
                        bottom: 12,
                        left: 16,
                        fontSize: 8,
                        fontWeight: 700,
                        letterSpacing: '0.3em',
                        color: '#00E5FF',
                    }}>
                        MILLI
                    </div>
                    {/* Titanium texture lines */}
                    <div style={{
                        position: 'absolute',
                        top: 0, left: 0, right: 0, bottom: 0,
                        background: 'repeating-linear-gradient(135deg, transparent, transparent 2px, rgba(255,255,255,0.01) 2px, rgba(255,255,255,0.01) 4px)',
                    }}/>
                </div>
            </div>
        </div>
    );
}


/* ---------- 4 · Financial Timeline ---------- */
export function FinancialTimeline({ payouts = [] }) {
    const defaults = [
        { id: 1, platform: "Uber", amount: 342.50, date: "2026-07-28" },
        { id: 2, platform: "DoorDash", amount: 187.20, date: "2026-07-25" },
        { id: 3, platform: "Lyft", amount: 256.80, date: "2026-07-22" },
        { id: 4, platform: "Uber", amount: 412.00, date: "2026-07-19" },
    ];
    const items = payouts.length ? payouts : defaults;

    return (
        <div data-testid="financial-timeline" style={{ padding: '8px 0' }}>
            {items.slice(0, 8).map((p, i) => {
                const amt = Number(p.amount || 0);
                const date = new Date(p.date || p.created_at || Date.now())
                    .toLocaleDateString("en-US", { month: "short", day: "numeric" });
                const platform = p.platform || p.merchant || "Payout";
                return (
                    <div key={p.id || i} style={{
                        display: 'flex',
                        alignItems: 'center',
                        padding: '14px 16px',
                        borderBottom: i < items.length - 1 ? '1px solid rgba(255,255,255,0.03)' : 'none',
                        gap: 12,
                    }} data-testid={`payout-node-${i}`}>
                        {/* Icon */}
                        <div style={{
                            width: 36, height: 36, borderRadius: 10,
                            background: 'rgba(0,229,255,0.06)',
                            border: '1px solid rgba(0,229,255,0.15)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            flexShrink: 0,
                        }}>
                            <span style={{ fontSize: 14, color: '#00E5FF', fontWeight: 700 }}>
                                {platform.slice(0, 2).toUpperCase()}
                            </span>
                        </div>
                        {/* Details */}
                        <div style={{ flex: 1 }}>
                            <div style={{ fontSize: 14, fontWeight: 600, color: '#FFFFFF' }}>{platform}</div>
                            <div style={{ fontSize: 11, color: '#5A6573', fontFamily: 'monospace' }}>{date}</div>
                        </div>
                        {/* Amount */}
                        <div style={{
                            fontSize: 15,
                            fontWeight: 700,
                            color: '#00E5FF',
                            fontFamily: 'monospace',
                        }}>
                            +${amt.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </div>
                    </div>
                );
            })}
        </div>
    );
}

/* ---------- 5 · Tax Vault Card ---------- */
export function TaxVaultCard({ balance = 0, period = "Q3", locked = false, progress = 76 }) {
    return (
        <div style={{
            background: 'rgba(13,15,18,0.5)',
            backdropFilter: 'blur(28px)',
            border: '1px solid rgba(0,229,255,0.08)',
            borderRadius: 22,
            padding: '24px',
        }} data-testid="tax-vault-card">
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <Vault size={16} weight="duotone" style={{ color: '#00E5FF' }}/>
                <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
                    Milli Tax Vault™
                </span>
            </div>
            <div style={{
                fontSize: 32,
                fontWeight: 800,
                background: 'linear-gradient(135deg, #E8E8E8, #808080)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                marginBottom: 8,
                fontFamily: "'SF Pro Display', -apple-system, sans-serif",
            }} data-testid="vault-balance">
                {locked ? "$—.—" : `$${Number(balance).toLocaleString('en-US', {
                    minimumFractionDigits: 2, maximumFractionDigits: 2,
                })}`}
            </div>
            {/* Progress bar */}
            <div style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                    <span style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
                        {locked ? "Upgrade to unlock" : `Protected for ${period}`}
                    </span>
                    <span style={{ fontSize: 10, color: '#00E5FF', fontFamily: 'monospace', fontWeight: 700 }}>
                        {progress}%
                    </span>
                </div>
                <div style={{ height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.04)', overflow: 'hidden' }}>
                    <div style={{
                        height: '100%',
                        width: `${progress}%`,
                        borderRadius: 3,
                        background: 'linear-gradient(90deg, #00E5FF, #0B7A94)',
                        boxShadow: '0 0 12px rgba(0,229,255,0.4)',
                        transition: 'width 0.6s cubic-bezier(0.4,0,0.2,1)',
                    }}/>
                </div>
            </div>
        </div>
    );
}

/* ---------- 6 · Insight Cards ---------- */
export function InsightRow({ items = [] }) {
    const defaults = [
        { icon: Shield, title: "Tax Protection", metric: "$0.00", sub: "Reserved YTD" },
        { icon: Car, title: "Miles Tracked", metric: "0 mi", sub: "IRS $0.70/mi" },
        { icon: ChartLineUp, title: "Projections", metric: "$0.00", sub: "Annual estimated tax" },
    ];
    const rows = items.length ? items : defaults;
    return (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4" data-testid="insight-row">
            {rows.map((it, i) => (
                <div key={i} className="milli-card milli-insight" data-testid={`insight-${i}`}>
                    <div className="milli-insight__icon-wrap">
                        <it.icon size={20} weight="duotone"/>
                    </div>
                    <div className="milli-insight__title">{it.title}</div>
                    <div className="milli-insight__metric">{it.metric}</div>
                    <div className="milli-insight__sub">{it.sub}</div>
                </div>
            ))}
        </div>
    );
}

/* ---------- 7 · Elite Badge ---------- */
export function EliteBadge({ size = 96 }) {
    return (
        <div className="milli-elite" data-testid="elite-badge">
            <div className="milli-elite__wreath" style={{ width: size, height: size }}>
                <svg viewBox="0 0 96 96" width={size} height={size}>
                    <defs>
                        <linearGradient id="e-chrome" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stopColor="#F0F0F0"/>
                            <stop offset="50%" stopColor="#C0C0C0"/>
                            <stop offset="100%" stopColor="#808080"/>
                        </linearGradient>
                    </defs>
                    <g fill="url(#e-chrome)">
                        <ellipse cx="18" cy="30" rx="4" ry="9" transform="rotate(-40 18 30)"/>
                        <ellipse cx="14" cy="46" rx="4" ry="9" transform="rotate(-15 14 46)"/>
                        <ellipse cx="18" cy="62" rx="4" ry="9" transform="rotate(15  18 62)"/>
                        <ellipse cx="26" cy="76" rx="4" ry="9" transform="rotate(40  26 76)"/>
                    </g>
                    <g fill="url(#e-chrome)">
                        <ellipse cx="78" cy="30" rx="4" ry="9" transform="rotate(40  78 30)"/>
                        <ellipse cx="82" cy="46" rx="4" ry="9" transform="rotate(15  82 46)"/>
                        <ellipse cx="78" cy="62" rx="4" ry="9" transform="rotate(-15 78 62)"/>
                        <ellipse cx="70" cy="76" rx="4" ry="9" transform="rotate(-40 70 76)"/>
                    </g>
                    <path d="M48 22 L52.2 40 L70 40 L55.5 51 L60.5 68 L48 57.5 L35.5 68 L40.5 51 L26 40 L43.8 40 Z"
                        fill="#00E5FF" stroke="#FFFFFF" strokeWidth="0.5"
                        style={{ filter: 'drop-shadow(0 0 6px rgba(0,229,255,0.9))' }}/>
                </svg>
            </div>
            <div className="milli-elite__label">ELITE</div>
        </div>
    );
}

/* ---------- 8 · MilliMark (SVG logo) ---------- */
export function MilliMark({ size = 40 }) {
    return (
        <img
            src="/brand/milli-logo.svg"
            width={size}
            height={size}
            alt="Milli"
            data-testid="milli-mark"
            style={{ objectFit: "contain" }}
        />
    );
}

/* ---------- Utility ---------- */
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

export { Vault as VaultIcon, Star as StarIcon };
