import { useEffect, useState, useMemo } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { Link } from "react-router-dom";
import {
  ChartLineUp, ArrowUpRight, TrendUp, Wallet, Info, CaretRight,
  ArrowDown, ArrowUp, Pause, Play, Sparkle, Bank,
} from "@phosphor-icons/react";

/**
 * Investing.jsx — Wealth Engine: Automated Portfolio Growth
 * AESTHETIC: 28px blur glassmorphism, #0D0F12 base, neon cyan charts
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

export default function Investing() {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);
  const [busy, setBusy] = useState(false);

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

      {/* Neon Cyan Chart */}
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
