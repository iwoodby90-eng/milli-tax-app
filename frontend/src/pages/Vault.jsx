import { useEffect, useState, useRef } from "react";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { Link } from "react-router-dom";
import {
  ShieldCheck, ArrowDown, ArrowUp, Sparkle, Star, LockKey,
  CaretRight, Bank, Clock,
} from "@phosphor-icons/react";
import MilliVaultBridge from "@/plugins/MilliVaultBridge";

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };
const HERO_TEAL = { background: "linear-gradient(135deg, rgba(0,180,200,0.22), rgba(0,229,255,0.07) 45%, rgba(5,6,7,0.9))", border: "1px solid rgba(0,229,255,0.45)", borderRadius: 24, boxShadow: "0 0 32px rgba(0,229,255,0.2), inset 0 1px 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.4)" };

export default function Vault() {
  const { user } = useAuth();
  const [vault, setVault] = useState(null);
  const [summary, setSummary] = useState(null);
  const [showConfetti, setShowConfetti] = useState(false);
  const celebratedRef = useRef(false);

  async function load() {
    try {
      const [v, s] = await Promise.all([api.get("/vault"), api.get("/tax/summary")]);
      setVault(v.data); setSummary(s.data);
    } catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  const balance = Number(vault?.balance ?? summary?.savings_balance ?? 0);
  const thisMonth = Number(vault?.this_month ?? summary?.vault_this_month ?? 0);
  const taxGoal = Number(vault?.tax_goal ?? summary?.tax_goal ?? 20000);
  const pct = Math.min(100, Math.round((balance / Math.max(1, taxGoal)) * 100));
  const isElite = user?.plan === "elite";
  const year = new Date().getFullYear();
  const rate = Number(vault?.rate_pct ?? 0.06);

  useEffect(() => {
    if (!balance && !taxGoal) return;
    const firstName = user?.name?.split(" ")[0] || "";
    MilliVaultBridge.update({ balance, goal: taxGoal, thisMonth, firstName })
      .catch((e) => { console.debug("[Vault] widget bridge:", e); });
  }, [balance, taxGoal, thisMonth, user?.name]);

  useEffect(() => {
    if (!balance) return;
    const milestones = [25, 50, 75, 100];
    const crossed = milestones.some((m) => pct >= m && pct - 4 < m);
    if (crossed && !celebratedRef.current) {
      celebratedRef.current = true;
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 3200);
    }
  }, [pct, balance]);

  const nextMilestone = [25, 50, 75, 100].find(m => m > pct) || 100;
  const dollarsToNext = Math.max(0, Math.round((nextMilestone / 100) * taxGoal - balance));

  // Progress ring SVG params
  const ringSize = 140;
  const ringStroke = 10;
  const ringR = (ringSize - ringStroke) / 2;
  const ringC = 2 * Math.PI * ringR;
  const ringOffset = ringC - (pct / 100) * ringC;

  return (
    <div style={PAGE_STYLE}>
      {showConfetti && <ConfettiBurst />}

      {/* Subtle teal glow from top-center */}
      <div aria-hidden style={{ position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)", width: 400, height: 300, background: "radial-gradient(ellipse at center top, rgba(0,229,255,0.08) 0%, transparent 70%)", pointerEvents: "none" }} />

      {/* Header */}
      <header style={{ position: "relative" }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }} data-testid="vault-header">
          Tax Vault
        </h1>
        <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Private. Protected. Automated.</p>
      </header>

      <div style={{ height: 24 }} />

      {/* Hero — Circular Progress Ring */}
      <section data-testid="vault-progress-hero" style={{ ...HERO_TEAL, padding: "32px 24px", display: "flex", flexDirection: "column", alignItems: "center", position: "relative", overflow: "hidden" }}>
        {/* SVG Ring */}
        <div style={{ position: "relative", width: ringSize, height: ringSize, filter: "drop-shadow(0 0 20px rgba(0,229,255,0.35))" }}>
          <svg width={ringSize} height={ringSize} style={{ transform: "rotate(-90deg)" }}>
            <circle cx={ringSize/2} cy={ringSize/2} r={ringR} fill="none" stroke="rgba(0,229,255,0.1)" strokeWidth={ringStroke} />
            <circle cx={ringSize/2} cy={ringSize/2} r={ringR} fill="none" stroke="#00E5FF" strokeWidth={ringStroke} strokeLinecap="round" strokeDasharray={ringC} strokeDashoffset={ringOffset} style={{ transition: "stroke-dashoffset 1.2s cubic-bezier(0.16, 1, 0.3, 1)" }} />
          </svg>
          <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
            <div style={{ fontSize: 32, fontWeight: 800, color: "#fff", fontVariantNumeric: "tabular-nums", letterSpacing: "-0.04em" }}>
              ${balance.toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
            </div>
          </div>
        </div>
        <div style={{ marginTop: 12, fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.14em", textTransform: "uppercase" }}>Tax Vault Balance</div>
        <div style={{ marginTop: 4, color: "#9CA3AF", fontSize: 13 }}>
          {pct}% of <span style={{ color: "rgba(255,255,255,0.8)" }}>${taxGoal.toLocaleString("en-US")}</span> goal
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Monthly Goal Progress */}
      <section style={{ ...SURFACE, padding: 20 }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Monthly Goal</h2>
          <span style={{ color: "#00E5FF", fontSize: 13, fontWeight: 600, textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            +${thisMonth.toLocaleString("en-US", { minimumFractionDigits: 2 })}
          </span>
        </div>
        <div style={{ height: 8, borderRadius: 999, background: "rgba(255,255,255,0.06)", overflow: "hidden" }}>
          <div style={{ height: "100%", borderRadius: 999, width: `${Math.min(100, (thisMonth / Math.max(1, taxGoal / 12)) * 100)}%`, background: "linear-gradient(90deg, #00B4D0, #00E5FF)", boxShadow: "0 0 12px rgba(0,229,255,0.7)", transition: "width 1s ease" }} />
        </div>
        <div style={{ color: "#4B5563", fontSize: 11, marginTop: 8 }}>
          ${dollarsToNext.toLocaleString("en-US")} to {nextMilestone}% milestone
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Action Buttons */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        <button style={{ ...SURFACE, padding: "14px 0", textAlign: "center", cursor: "pointer", color: "#00E5FF", fontSize: 14, fontWeight: 600, borderRadius: 16 }}>
          Add Funds
        </button>
        <button style={{ ...SURFACE, padding: "14px 0", textAlign: "center", cursor: "pointer", color: "#9CA3AF", fontSize: 14, fontWeight: 600, borderRadius: 16 }}>
          View History
        </button>
      </div>

      <div style={{ height: 16 }} />

      {/* Recent Deposits */}
      <section style={{ ...SURFACE, padding: 20 }} data-testid="vault-transfers-card">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Recent Deposits</h2>
          <Link to="/app/income" style={{ color: "#00E5FF", fontSize: 13, fontWeight: 600, textDecoration: "none", textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>View all</Link>
        </div>
        <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
          {(vault?.recent_transfers?.length ? vault.recent_transfers : DEMO_TRANSFERS).slice(0, 5).map((t, i) => (
            <TransferRow key={t.id || i} t={t} last={i === Math.min(4, (vault?.recent_transfers?.length || DEMO_TRANSFERS.length) - 1)} />
          ))}
        </ul>
      </section>

      <div style={{ height: 16 }} />

      {/* Tax Ready Score bar */}
      <section style={{ ...SURFACE, padding: 20 }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Tax Ready Score</h2>
          <span style={{ fontSize: 18, fontWeight: 700, color: "#00E5FF", fontVariantNumeric: "tabular-nums" }}>{pct}%</span>
        </div>
        <div style={{ height: 10, borderRadius: 999, background: "rgba(255,255,255,0.06)", overflow: "hidden" }}>
          <div style={{ height: "100%", borderRadius: 999, width: `${pct}%`, background: "linear-gradient(90deg, #00B4D0, #00E5FF, #7BF3FF)", boxShadow: "0 0 14px rgba(0,229,255,0.8)", transition: "width 1s ease" }} />
        </div>
        <div style={{ color: "#4B5563", fontSize: 11, marginTop: 6 }}>
          {pct >= 100 ? "Goal reached!" : pct >= 75 ? "Almost there — excellent progress" : pct >= 50 ? "On track for this year" : "Building your tax safety net"}
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Autopilot */}
      <section style={{ ...SURFACE, padding: 20 }} data-testid="vault-autopilot-card">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <Sparkle size={16} weight="fill" color="#00E5FF" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.55))" }} />
              <span style={{ color: "#fff", fontWeight: 600, fontSize: 15 }}>Milli Autopilot</span>
            </div>
            <div style={{ color: "#9CA3AF", fontSize: 12, marginTop: 4 }}>
              {Math.round(rate * 100)}% of every payout auto-slices to your Vault.
            </div>
          </div>
          <span style={{ color: "#00E5FF", fontSize: 11, fontWeight: 700, padding: "4px 10px", borderRadius: 999, background: "rgba(0,229,255,0.10)", border: "1px solid rgba(0,229,255,0.5)", textShadow: "0 0 6px rgba(0,229,255,0.5)" }}>ON</span>
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Elite Perks */}
      <section
        data-testid="vault-perks-card"
        style={{
          borderRadius: 20, padding: 20, position: "relative", overflow: "hidden",
          background: "linear-gradient(180deg, rgba(0,229,255,0.04) 0%, rgba(5,6,7,0.9) 100%)",
          border: `1px solid ${isElite ? "rgba(0,229,255,0.45)" : "rgba(255,255,255,0.07)"}`,
          boxShadow: isElite ? "0 0 22px rgba(0,229,255,0.28)" : "0 4px 24px rgba(0,0,0,0.3)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <Star size={16} weight="fill" color="#00E5FF" style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.55))" }} />
            <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Elite Perks</h2>
          </div>
          {!isElite && (
            <Link to="/app/pricing" data-testid="vault-elite-upgrade" style={{ color: "#000", fontSize: 12, fontWeight: 700, padding: "6px 12px", borderRadius: 999, background: "linear-gradient(180deg, #00E5FF, #00B4D0)", boxShadow: "0 0 14px rgba(0,229,255,0.55)", textDecoration: "none" }}>UPGRADE</Link>
          )}
        </div>
        <ul style={{ listStyle: "none", margin: 0, padding: 0, display: "flex", flexDirection: "column", gap: 10 }}>
          <PerkRow unlocked={pct >= 25 || isElite} label="Priority Milli AI" sub="Faster, higher-quality answers" />
          <PerkRow unlocked={pct >= 50 || isElite} label="Auto Quarterly Filing" sub="ACH IRS + state payments" />
          <PerkRow unlocked={pct >= 75 || isElite} label="1099 auto-import" sub="Every gig platform, end of year" />
          <PerkRow unlocked={pct >= 100 || isElite} label="Federal + State e-file" sub="Milli files Schedule C & SE for you" />
        </ul>
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */
const DEMO_TRANSFERS = [
  { id: "d1", direction: "in", source: "Uber payout · Aug 1", amount: 7.38 },
  { id: "d2", direction: "in", source: "DoorDash payout · Jul 25", amount: 43.75 },
  { id: "d3", direction: "in", source: "Instacart payout · Jul 21", amount: 38.29 },
  { id: "d4", direction: "out", source: "Q2 IRS payment · Jul 12", amount: 1240.00 },
  { id: "d5", direction: "in", source: "Upwork payout · Jul 19", amount: 28.78 },
];

function TransferRow({ t, last }) {
  const isIn = t.direction === "in";
  return (
    <li style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 0", borderBottom: last ? "none" : "1px solid rgba(255,255,255,0.05)" }}>
      <div style={{ width: 36, height: 36, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, background: isIn ? "rgba(0,229,255,0.08)" : "rgba(255,92,103,0.08)", border: `1px solid ${isIn ? "rgba(0,229,255,0.35)" : "rgba(255,92,103,0.35)"}` }}>
        {isIn ? <ArrowDown size={16} weight="bold" color="#00E5FF" /> : <ArrowUp size={16} weight="bold" color="#FF5C67" />}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "#fff", fontSize: 13, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{isIn ? "To Vault" : "From Vault"}</div>
        <div style={{ color: "#4B5563", fontSize: 11, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t.source}</div>
      </div>
      <div style={{ fontWeight: 700, fontSize: 14, fontVariantNumeric: "tabular-nums", color: isIn ? "#00E5FF" : "#FF5C67", textShadow: isIn ? "0 0 6px rgba(0,229,255,0.4)" : "none" }}>
        {isIn ? "+" : "−"}${Number(t.amount).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
      </div>
    </li>
  );
}

function PerkRow({ unlocked, label, sub }) {
  return (
    <li style={{ display: "flex", alignItems: "center", gap: 12 }}>
      <div style={{ width: 32, height: 32, borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, background: unlocked ? "rgba(0,229,255,0.10)" : "rgba(255,255,255,0.03)", border: unlocked ? "1px solid rgba(0,229,255,0.5)" : "1px solid rgba(255,255,255,0.06)", boxShadow: unlocked ? "0 0 10px rgba(0,229,255,0.35)" : "none" }}>
        {unlocked ? <ShieldCheck size={16} weight="duotone" color="#00E5FF" /> : <LockKey size={14} weight="regular" color="#4B5563" />}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 600, fontSize: 13, color: unlocked ? "#fff" : "#4B5563" }}>{label}</div>
        <div style={{ color: "#4B5563", fontSize: 11 }}>{sub}</div>
      </div>
      {unlocked && <CaretRight size={12} weight="bold" color="#4B5563" />}
    </li>
  );
}

function ConfettiBurst() {
  const bits = Array.from({ length: 48 });
  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 40, overflow: "hidden", pointerEvents: "none" }} data-testid="confetti">
      {bits.map((_, i) => {
        const left = Math.random() * 100;
        const delay = Math.random() * 0.3;
        const dur = 1.6 + Math.random() * 1.2;
        const rot = Math.random() * 360;
        const color = ["#00E5FF", "#7BF3FF", "#FFFFFF", "#4DE0FF"][i % 4];
        return (
          <span key={i} style={{ position: "absolute", top: -20, left: `${left}%`, width: 8, height: 12, background: color, borderRadius: 2, boxShadow: `0 0 8px ${color}`, transform: `rotate(${rot}deg)`, animation: `mv-confetti ${dur}s cubic-bezier(0.2,0.7,0.4,1) ${delay}s forwards` }} />
        );
      })}
      <style>{`@keyframes mv-confetti { 0% { transform: translateY(0) rotate(0deg); opacity: 1; } 100% { transform: translateY(110vh) rotate(720deg); opacity: 0; } }`}</style>
    </div>
  );
}
