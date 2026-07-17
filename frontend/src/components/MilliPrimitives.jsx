/**
 * Big City Futuristic primitive components.
 *
 * Compose these anywhere. Each renders design-system.css classes so the
 * theme is one file to update. No props are required for defaults —
 * everything degrades gracefully if data isn't wired yet.
 */
import { Shield, Car, ChartLineUp, Vault, Star } from "@phosphor-icons/react";


/* ---------- 1 · Tax Ready Score Gauge ---------- */
export function TaxReadyGauge({ score = 0, size = 220, label = "Tax Ready Score" }) {
    const radius = (size - 24) / 2;
    const circumference = 2 * Math.PI * radius;
    const dashoffset = circumference * (1 - Math.max(0, Math.min(100, score)) / 100);
    const status = score >= 90 ? "Excellent"
        : score >= 70 ? "On track"
        : score >= 40 ? "Building up"
        : "Getting started";
    return (
        <div className="milli-gauge" style={{ '--gauge-size': `${size}px` }}
              data-testid="tax-ready-gauge">
            <svg width={size} height={size}>
                <defs>
                    <linearGradient id="milli-gauge-grad" x1="0" y1="0" x2="1" y2="1">
                        <stop offset="0%" stopColor="#00E5FF"/>
                        <stop offset="55%" stopColor="#FFFFFF"/>
                        <stop offset="100%" stopColor="#00E5FF"/>
                    </linearGradient>
                </defs>
                <circle cx={size / 2} cy={size / 2} r={radius}
                    fill="none" strokeWidth="8" className="milli-gauge__track"/>
                <circle cx={size / 2} cy={size / 2} r={radius}
                    fill="none" strokeWidth="8"
                    strokeDasharray={circumference} strokeDashoffset={dashoffset}
                    className="milli-gauge__value"/>
            </svg>
            <div className="milli-gauge__label">
                <div className="milli-gauge__pct" data-testid="tax-ready-gauge-value">
                    {Math.round(score)}<span style={{ fontSize: '0.55em' }}>%</span>
                </div>
                <div className="milli-gauge__caption">{label}</div>
                <div className="milli-gauge__status">{status}</div>
            </div>
        </div>
    );
}

/* ---------- 2 · Financial Timeline ---------- */
export function FinancialTimeline({ payouts = [] }) {
    if (!payouts.length) {
        return <div style={{ color: 'var(--milli-muted)', padding: '32px',
            textAlign: 'center', fontSize: 13 }}>
            No payouts yet — link a payout account to see the timeline light up.
        </div>;
    }
    return (
        <div className="milli-timeline" data-testid="financial-timeline">
            {payouts.slice(0, 12).map((p, i) => {
                const isActive = i === payouts.length - 1;
                const short = (p.platform || p.merchant || "?").slice(0, 3).toUpperCase();
                const amt = Number(p.amount || 0);
                const date = new Date(p.date || p.created_at || Date.now())
                    .toLocaleDateString("en-US", { month: "short", day: "numeric" });
                return (
                    <div key={p.id || i}
                          className={`milli-node ${isActive ? 'milli-node--active' : ''}`}
                          data-testid={`payout-node-${i}`}>
                        <div className="milli-node__date">{date}</div>
                        <div className="milli-node__dot">{short}</div>
                        <div className="milli-node__amount">${amt.toLocaleString('en-US', {
                            minimumFractionDigits: 2, maximumFractionDigits: 2,
                        })}</div>
                    </div>
                );
            })}
        </div>
    );
}

/* ---------- 3 · Tax Vault Card ---------- */
export function TaxVaultCard({ balance = 0, period = "Q3", locked = false }) {
    return (
        <div className="milli-card-strong milli-vault" data-testid="tax-vault-card">
            <svg className="milli-vault__icon" viewBox="0 0 96 96" fill="none">
                <defs>
                    <linearGradient id="v-chrome" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.15"/>
                        <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.05"/>
                    </linearGradient>
                </defs>
                <rect x="10" y="14" width="76" height="68" rx="10" fill="url(#v-chrome)"
                    stroke="#00E5FF" strokeWidth="2"/>
                <circle cx="48" cy="48" r="22" fill="none" stroke="#00E5FF" strokeWidth="2.5"/>
                <circle cx="48" cy="48" r="14" fill="none" stroke="#00E5FF" strokeWidth="1.5"
                    strokeDasharray="4 2"/>
                <circle cx="48" cy="48" r="4" fill="#00E5FF"/>
                <line x1="48" y1="26" x2="48" y2="30" stroke="#00E5FF" strokeWidth="2"/>
                <line x1="70" y1="48" x2="66" y2="48" stroke="#00E5FF" strokeWidth="2"/>
                <line x1="48" y1="70" x2="48" y2="66" stroke="#00E5FF" strokeWidth="2"/>
                <line x1="26" y1="48" x2="30" y2="48" stroke="#00E5FF" strokeWidth="2"/>
                {/* Vault door hinges */}
                <rect x="14" y="20" width="3" height="8" fill="#00E5FF" opacity="0.7"/>
                <rect x="14" y="68" width="3" height="8" fill="#00E5FF" opacity="0.7"/>
            </svg>
            <div className="milli-vault__label">Milli Tax Vault™</div>
            <div className="milli-vault__balance" data-testid="vault-balance">
                {locked ? "$—.—" : `$${Number(balance).toLocaleString('en-US', {
                    minimumFractionDigits: 2, maximumFractionDigits: 2,
                })}`}
            </div>
            <div className="milli-vault__sub">
                {locked
                    ? "Upgrade to Elite to unlock the full vault"
                    : `Protected for ${period} estimated payment`}
            </div>
        </div>
    );
}

/* ---------- 4 · Insight Cards ---------- */
export function InsightRow({ items = [] }) {
    const defaults = [
        {
            icon: Shield, title: "Tax Protection",
            metric: "$0.00", sub: "Reserved YTD",
        },
        {
            icon: Car, title: "Miles Tracked",
            metric: "0 mi", sub: "IRS $0.70/mi",
        },
        {
            icon: ChartLineUp, title: "Projections",
            metric: "$0.00", sub: "Annual estimated tax",
        },
    ];
    const rows = items.length ? items : defaults;
    return (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4"
              data-testid="insight-row">
            {rows.map((it, i) => (
                <div key={i} className="milli-card milli-insight"
                      data-testid={`insight-${i}`}>
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

/* ---------- 5 · Elite Badge ---------- */
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
                    {/* Left laurel */}
                    <g fill="url(#e-chrome)">
                        <ellipse cx="18" cy="30" rx="4" ry="9" transform="rotate(-40 18 30)"/>
                        <ellipse cx="14" cy="46" rx="4" ry="9" transform="rotate(-15 14 46)"/>
                        <ellipse cx="18" cy="62" rx="4" ry="9" transform="rotate(15  18 62)"/>
                        <ellipse cx="26" cy="76" rx="4" ry="9" transform="rotate(40  26 76)"/>
                    </g>
                    {/* Right laurel (mirrored) */}
                    <g fill="url(#e-chrome)">
                        <ellipse cx="78" cy="30" rx="4" ry="9" transform="rotate(40  78 30)"/>
                        <ellipse cx="82" cy="46" rx="4" ry="9" transform="rotate(15  82 46)"/>
                        <ellipse cx="78" cy="62" rx="4" ry="9" transform="rotate(-15 78 62)"/>
                        <ellipse cx="70" cy="76" rx="4" ry="9" transform="rotate(-40 70 76)"/>
                    </g>
                    {/* Center star */}
                    <path d="M48 22 L52.2 40 L70 40 L55.5 51 L60.5 68 L48 57.5 L35.5 68 L40.5 51 L26 40 L43.8 40 Z"
                        fill="#00E5FF"
                        stroke="#FFFFFF" strokeWidth="0.5"
                        style={{ filter: 'drop-shadow(0 0 6px rgba(0,229,255,0.9))' }}/>
                </svg>
            </div>
            <div className="milli-elite__label">ELITE</div>
        </div>
    );
}

/* ---------- 6 · MilliMark (SVG logo) ---------- */
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

/* export the vault icon so pages can reuse it */
export { Vault as VaultIcon, Star as StarIcon };
