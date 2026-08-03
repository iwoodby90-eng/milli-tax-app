import { useEffect, useState, useRef } from "react";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { Link } from "react-router-dom";
import {
  ShieldCheck, ArrowDown, ArrowUp, Sparkle, Star, LockKey,
  CaretRight, Bank, Confetti,
} from "@phosphor-icons/react";
import MilliVaultBridge from "@/plugins/MilliVaultBridge";

/**
 * Milli Tax Vault — matches Milli aesthetic (dashboard style).
 * Sections:
 *   1. Progress Story hero — "You're X% to your 2026 goal" with confetti on milestone
 *   2. Autopilot toggle + rules
 *   3. Recent Transfers list
 *   4. Elite Perks (with lock overlay for non-Elite)
 */
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

  // Push the latest vault snapshot into the iOS App Group so the home-screen widget
  // AND the Milli Watch complication both stay fresh.
  useEffect(() => {
    if (!balance && !taxGoal) return;
    const firstName = user?.name?.split(" ")[0] || "";
    MilliVaultBridge.update({ balance, goal: taxGoal, thisMonth, firstName }).catch(() => {});
  }, [balance, taxGoal, thisMonth, user?.name]);

  // Confetti on milestone crossings (25/50/75/100)
  useEffect(() => {
    if (!balance) return;
    const milestones = [25, 50, 75, 100];
    const crossed = milestones.some((m) => pct >= m && pct - 4 < m); // in-range
    if (crossed && !celebratedRef.current) {
      celebratedRef.current = true;
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 3200);
    }
  }, [pct, balance]);

  const nextMilestone = [25, 50, 75, 100].find(m => m > pct) || 100;
  const dollarsToNext = Math.max(0, Math.round((nextMilestone / 100) * taxGoal - balance));

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4 relative">
      {showConfetti && <ConfettiBurst />}

      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight" data-testid="vault-header">
          {(user?.name?.split(" ")[0] || "Your")}&apos;s Tax Vault<sup className="text-[16px] align-super">™</sup>
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Every payout protected. Automatically.</p>
      </header>

      {/* 1 · Progress Story hero */}
      <section
        className="relative overflow-hidden rounded-3xl p-5"
        data-testid="vault-progress-hero"
        style={{
          background: "linear-gradient(135deg, rgba(0,180,200,0.28) 0%, rgba(0,229,255,0.06) 40%, rgba(10,14,18,0.9) 75%)",
          border: "1px solid rgba(0,229,255,0.55)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.08), 0 0 30px rgba(0,229,255,0.4), 0 20px 44px rgba(0,0,0,0.55)",
        }}
      >
        <div className="flex items-start justify-between gap-3 mb-3">
          <div>
            <div className="flex items-center gap-2 text-white/85 text-[13.5px] font-medium">
              <span>You&apos;re</span>
              <span
                className="text-volt font-chrome font-bold text-[15px]"
                style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}
              >
                {pct}%
              </span>
              <span>to your {year} goal</span>
            </div>
            <div className="font-chrome font-black text-white tabular-nums leading-[1] tracking-tight mt-2 text-[34px] sm:text-[40px]">
              ${balance.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <div className="text-zinc-400 text-[12.5px] mt-1">
              of <span className="text-white/80 tabular-nums">${taxGoal.toLocaleString("en-US")}</span> tax goal
            </div>
          </div>
          <VaultShield />
        </div>

        {/* Big cyan progress bar with milestone dots */}
        <div className="relative mt-4">
          <div className="h-2.5 rounded-full bg-white/[0.06] overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-1000"
              style={{
                width: `${pct}%`,
                background: "linear-gradient(90deg, #00B4D0 0%, #00E5FF 50%, #7BF3FF 100%)",
                boxShadow: "0 0 14px rgba(0,229,255,0.8)",
              }}
            />
          </div>
          {/* milestone dots */}
          <div className="absolute inset-0 flex items-center pointer-events-none">
            {[25, 50, 75, 100].map((m) => (
              <div key={m} className="absolute" style={{ left: `calc(${m}% - 5px)` }}>
                <div
                  className="w-2.5 h-2.5 rounded-full"
                  style={{
                    background: pct >= m ? "#FFFFFF" : "#3A404A",
                    border: pct >= m ? "1.5px solid #00E5FF" : "1.5px solid rgba(255,255,255,0.15)",
                    boxShadow: pct >= m ? "0 0 8px rgba(0,229,255,0.9)" : "none",
                  }}
                />
              </div>
            ))}
          </div>
        </div>

        <div className="flex items-center justify-between text-[11.5px] mt-3">
          <span className="text-volt font-medium" style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
            +${thisMonth.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} this month
          </span>
          <span className="text-zinc-400">
            {pct >= 100
              ? "Goal reached! 🎯"
              : `$${dollarsToNext.toLocaleString("en-US")} to ${nextMilestone}%`}
          </span>
        </div>
      </section>

      {/* 2 · Autopilot */}
      <section className="milli-card rounded-2xl p-5" data-testid="vault-autopilot-card">
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2">
              <Sparkle size={16} weight="fill" className="text-volt"
                       style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.55))" }} />
              <span className="text-white font-semibold text-[15px]">Milli Autopilot</span>
            </div>
            <div className="text-zinc-400 text-[12px] mt-1">
              {Math.round(rate * 100)}% of every payout auto-slices to your Vault.
            </div>
          </div>
          <span
            className="text-volt text-[11px] font-bold px-2.5 py-1 rounded-full tracking-wider"
            style={{
              background: "rgba(0,229,255,0.10)",
              border: "1px solid rgba(0,229,255,0.5)",
              textShadow: "0 0 6px rgba(0,229,255,0.5)",
            }}
          >
            ON
          </span>
        </div>
      </section>

      {/* 3 · Recent Transfers */}
      <section className="milli-card rounded-2xl p-5" data-testid="vault-transfers-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[16px]">Recent Transfers</h2>
          <Link to="/app/income" className="text-volt text-[13px] font-semibold"
                style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>View all</Link>
        </div>
        <ul className="divide-y divide-white/[0.05]">
          {(vault?.recent_transfers?.length ? vault.recent_transfers : DEMO_TRANSFERS).slice(0, 5).map((t, i) => (
            <TransferRow key={t.id || i} t={t} />
          ))}
        </ul>
      </section>

      {/* 4 · Elite Perks */}
      <section
        className="rounded-2xl p-5 relative overflow-hidden"
        data-testid="vault-perks-card"
        style={{
          background: "linear-gradient(180deg, rgba(0,229,255,0.05) 0%, rgba(10,14,18,0.9) 100%)",
          border: `1px solid ${isElite ? "rgba(0,229,255,0.55)" : "rgba(255,255,255,0.10)"}`,
          boxShadow: isElite ? "0 0 22px rgba(0,229,255,0.28)" : "none",
        }}
      >
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Star size={16} weight="fill" className="text-volt"
                  style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.55))" }} />
            <h2 className="text-white font-semibold text-[16px]">Elite Perks</h2>
          </div>
          {!isElite && (
            <Link
              to="/app/pricing"
              data-testid="vault-elite-upgrade"
              className="text-obsidian text-[12px] font-bold px-3 py-1.5 rounded-full"
              style={{
                background: "linear-gradient(180deg, #00E5FF 0%, #00B4D0 100%)",
                boxShadow: "0 0 14px rgba(0,229,255,0.55), inset 0 1px 0 rgba(255,255,255,0.5)",
              }}
            >
              UPGRADE
            </Link>
          )}
        </div>
        <ul className="space-y-2.5">
          <PerkRow unlocked={pct >= 25 || isElite} label="Priority Milli AI"       sub="Faster, higher-quality answers" />
          <PerkRow unlocked={pct >= 50 || isElite} label="Auto Quarterly Filing"   sub="ACH IRS + state payments" />
          <PerkRow unlocked={pct >= 75 || isElite} label="1099 auto-import"         sub="Every gig platform, end of year" />
          <PerkRow unlocked={pct >= 100 || isElite} label="Federal + State e-file" sub="Milli files Schedule C & SE for you" />
        </ul>
        {!isElite && (
          <div
            className="absolute -bottom-1 -right-1 w-24 h-24 pointer-events-none"
            style={{
              background: "radial-gradient(circle at 100% 100%, rgba(0,229,255,0.25) 0%, transparent 70%)",
            }}
          />
        )}
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */

const DEMO_TRANSFERS = [
  { id: "d1", direction: "in",  source: "Uber payout · Aug 1",      amount: 7.38,  net: 111.77 },
  { id: "d2", direction: "in",  source: "DoorDash payout · Jul 25", amount: 43.75, net: 186.72 },
  { id: "d3", direction: "in",  source: "Instacart payout · Jul 21",amount: 38.29, net: 163.44 },
  { id: "d4", direction: "out", source: "Q2 IRS payment · Jul 12",  amount: 1240.00 },
  { id: "d5", direction: "in",  source: "Upwork payout · Jul 19",   amount: 28.78, net: 122.83 },
];

function TransferRow({ t }) {
  const isIn = t.direction === "in";
  return (
    <li className="flex items-center gap-3 py-3">
      <div
        className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
        style={{
          background: isIn ? "rgba(0,229,255,0.08)" : "rgba(255,92,119,0.08)",
          border: `1px solid ${isIn ? "rgba(0,229,255,0.35)" : "rgba(255,92,119,0.35)"}`,
        }}
      >
        {isIn
          ? <ArrowDown size={16} weight="bold" className="text-volt" />
          : <ArrowUp   size={16} weight="bold" style={{ color: "#FF5C77" }} />}
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-white text-[13.5px] font-medium truncate">
          {isIn ? "To Vault" : "From Vault"}
        </div>
        <div className="text-zinc-500 text-[11.5px] truncate">{t.source}</div>
      </div>
      <div className="text-right flex-shrink-0">
        <div className={`font-bold text-[14px] tabular-nums ${isIn ? "text-volt" : "text-white"}`}
             style={isIn ? { textShadow: "0 0 6px rgba(0,229,255,0.4)" } : {}}>
          {isIn ? "+" : "−"}${Number(t.amount).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </div>
      </div>
    </li>
  );
}

function PerkRow({ unlocked, label, sub }) {
  return (
    <li className="flex items-center gap-3">
      <div
        className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
        style={{
          background: unlocked ? "rgba(0,229,255,0.10)" : "rgba(255,255,255,0.04)",
          border: unlocked ? "1px solid rgba(0,229,255,0.5)" : "1px solid rgba(255,255,255,0.08)",
          boxShadow: unlocked ? "0 0 10px rgba(0,229,255,0.35)" : "none",
        }}
      >
        {unlocked
          ? <ShieldCheck size={16} weight="duotone" className="text-volt" />
          : <LockKey size={14} weight="regular" className="text-zinc-500" />}
      </div>
      <div className="flex-1 min-w-0">
        <div className={`font-semibold text-[13.5px] ${unlocked ? "text-white" : "text-zinc-500"}`}>{label}</div>
        <div className="text-zinc-500 text-[11.5px]">{sub}</div>
      </div>
      {unlocked && <CaretRight size={12} weight="bold" className="text-zinc-600" />}
    </li>
  );
}

function VaultShield() {
  return (
    <div
      className="relative w-[86px] h-[86px] flex items-center justify-center flex-shrink-0"
      style={{ filter: "drop-shadow(0 0 22px rgba(0,229,255,0.55))" }}
      aria-hidden
    >
      <svg width="80" height="80" viewBox="0 0 80 80" fill="none">
        <defs>
          <linearGradient id="v-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#00E5FF" stopOpacity="0.25" />
            <stop offset="100%" stopColor="#00E5FF" stopOpacity="0.05" />
          </linearGradient>
        </defs>
        <path d="M40 5 L68 16 V38 C68 55 55 68 40 74 C25 68 12 55 12 38 V16 Z"
              fill="url(#v-fill)" stroke="#00E5FF" strokeWidth="2" />
        <path d="M28 40 L37 49 L52 32" stroke="#00E5FF" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none" />
      </svg>
    </div>
  );
}

/* Simple CSS confetti burst */
function ConfettiBurst() {
  const bits = Array.from({ length: 48 });
  return (
    <div className="pointer-events-none fixed inset-0 z-40 overflow-hidden" data-testid="confetti">
      {bits.map((_, i) => {
        const left = Math.random() * 100;
        const delay = Math.random() * 0.3;
        const dur = 1.6 + Math.random() * 1.2;
        const rot = Math.random() * 360;
        const color = ["#00E5FF", "#7BF3FF", "#FFFFFF", "#4DE0FF"][i % 4];
        return (
          <span
            key={i}
            style={{
              position: "absolute",
              top: "-20px",
              left: `${left}%`,
              width: 8, height: 12,
              background: color,
              borderRadius: 2,
              boxShadow: `0 0 8px ${color}`,
              transform: `rotate(${rot}deg)`,
              animation: `mv-confetti ${dur}s cubic-bezier(0.2,0.7,0.4,1) ${delay}s forwards`,
            }}
          />
        );
      })}
      <style>{`@keyframes mv-confetti { 0% { transform: translateY(0) rotate(0deg); opacity: 1; } 100% { transform: translateY(110vh) rotate(720deg); opacity: 0; } }`}</style>
    </div>
  );
}
