/**
 * Paywall — 3-tier Apple IAP subscription screen.
 * Big City Futuristic + iOS-native pixel choices.
 * v1.9.2 — Executive Curve, Matte Charcoal, Obsidian borders, Elite glow.
 */
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useNavigate } from "react-router-dom";
import { Check, ArrowClockwise, X, Star, ShieldCheck } from "@phosphor-icons/react";
import { toast } from "sonner";
import MilliLogo from "@/components/MilliLogo";
import { useStoreKit } from "@/hooks/useStoreKit";
import { useAuth } from "@/context/AuthContext";

const CYAN = "#00E5FF";

const CARD_BASE = {
  borderRadius: "22px",
  background: "#0D0F12",
  border: "1px solid #1A1D21",
};

const CARD_ACTIVE = {
  borderRadius: "22px",
  background: "linear-gradient(180deg, rgba(0,229,255,0.08), rgba(0,229,255,0.02))",
  border: "1px solid rgba(0,229,255,0.7)",
  boxShadow: "0 0 24px rgba(0,229,255,0.18), inset 0 1px 0 rgba(255,255,255,0.06)",
};

const CARD_ELITE = {
  borderRadius: "22px",
  background: "#0D0F12",
  border: "1px solid rgba(0, 229, 255, 0.55)",
  boxShadow: "inset 0 0 20px rgba(0, 229, 255, 0.15)",
};

const CARD_ELITE_ACTIVE = {
  borderRadius: "22px",
  background: "linear-gradient(180deg, rgba(0,229,255,0.12), rgba(0,229,255,0.03))",
  border: "1px solid rgba(0,229,255,0.85)",
  boxShadow: "0 0 32px rgba(0,229,255,0.25), inset 0 0 20px rgba(0, 229, 255, 0.15)",
};

export default function Paywall() {
  const nav = useNavigate();
  const { user, refresh } = useAuth();
  const { products, purchase, restore, purchasing } = useStoreKit();
  const [selected, setSelected] = useState("milli.pro.monthly");
  const [restoring, setRestoring] = useState(false);

  async function handlePurchase() {
    const r = await purchase(selected);
    if (r.ok) {
      toast.success("Welcome to Milli. Your plan is active.");
      try { await refresh?.(); } catch (_) { /* noop */ }
      nav("/app");
    } else if (r.error) {
      toast.error(r.error.message || "Purchase failed. Please try again.");
    }
  }

  async function handleRestore() {
    setRestoring(true);
    try {
      const r = await restore();
      if (r.restored > 0) {
        toast.success(`Restored ${r.restored} subscription(s).`);
        try { await refresh?.(); } catch (_) { /* noop */ }
        nav("/app");
      } else {
        toast.message("No prior purchases found on this Apple ID.");
      }
    } finally {
      setRestoring(false);
    }
  }

  function getCardStyle(tier, isActive) {
    const isElite = tier.featured || tier.plan === "elite";
    if (isElite && isActive) return CARD_ELITE_ACTIVE;
    if (isElite) return CARD_ELITE;
    if (isActive) return CARD_ACTIVE;
    return CARD_BASE;
  }

  return (
    <div className="relative w-full min-h-full carbon-bg text-white overflow-y-auto native-scroll"
         style={{ paddingTop: "calc(var(--safe-top) + 8px)", paddingBottom: "calc(var(--safe-bottom) + 120px)" }}
         data-testid="paywall-screen">
      {/* Close */}
      <button
        onClick={() => nav(-1)}
        aria-label="Close"
        data-testid="paywall-close"
        className="absolute top-3 right-3 z-10 w-9 h-9 flex items-center justify-center rounded-full bg-white/[0.05] border border-white/10 text-zinc-400 active:opacity-60"
        style={{ marginTop: "var(--safe-top)" }}
      >
        <X size={16} weight="bold" />
      </button>

      {/* Hero */}
      <div className="flex flex-col items-center px-6 pt-6 pb-4 text-center">
        <MilliLogo size={72} />
        <div style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif" }} className="chrome-text text-3xl tracking-[0.2em] mt-3 font-bold">MILLI</div>
        <p className="text-white/85 text-[15px] mt-4 max-w-[320px]">
          <span className="chrome-text font-semibold">Every payout.</span>{" "}
          <span style={{ color: CYAN }}>On autopilot.</span>
        </p>
        <p className="text-zinc-400 text-[13px] mt-2 max-w-[320px]" style={{ fontFamily: "'Sora', sans-serif" }}>
          Pick the plan that fits how you earn. Cancel anytime from your Apple ID settings.
        </p>
      </div>

      {/* Tier cards */}
      <div className="px-4 flex flex-col gap-3 mt-2">
        {products.map((tier) => {
          const isActive = selected === tier.id;
          const isCurrent = user?.plan === tier.plan;
          const cardStyle = getCardStyle(tier, isActive);
          return (
            <motion.button
              key={tier.id}
              type="button"
              onClick={() => setSelected(tier.id)}
              data-testid={`paywall-tier-${tier.plan}`}
              whileTap={{ scale: 0.985 }}
              className="relative text-left overflow-hidden transition-all"
              style={{
                ...cardStyle,
                padding: 16,
              }}
            >
              {tier.featured && (
                <div className="absolute -top-2.5 left-4 flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest px-2.5 py-0.5 rounded-full"
                     style={{ color: "#001217", background: CYAN, boxShadow: "0 0 12px rgba(0,229,255,0.55)" }}>
                  <Star size={10} weight="fill" /> Most popular
                </div>
              )}
              <div className="flex items-baseline justify-between gap-4">
                <div className="flex-1 min-w-0 pr-2">
                  <div className="text-[11px] uppercase tracking-[0.24em] text-white/60" style={{ fontFamily: "'Sora', sans-serif" }}>Milli</div>
                  <div style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif", fontWeight: 700 }} className="chrome-text text-[22px] leading-none mt-0.5 truncate">{tier.name}</div>
                  <div className="text-zinc-400 text-[13px] mt-1 leading-snug">{tier.tagline}</div>
                </div>
                <div className="text-right flex-shrink-0">
                  <div style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif", fontWeight: 700 }} className="text-white text-[22px] leading-none tabular-nums whitespace-nowrap">
                    {tier.priceDisplay}
                  </div>
                  <div className="text-[10px] uppercase tracking-widest text-white/40 mt-1">/month</div>
                </div>
              </div>

              <ul className="mt-3 grid gap-1.5">
                {tier.features.map((f) => (
                  <li key={f} className="flex items-center gap-2 text-[13px] text-white/85">
                    <Check size={14} weight="bold" style={{ color: CYAN }} />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>

              {isCurrent && (
                <div className="mt-3 inline-flex items-center gap-1 text-[10px] uppercase tracking-widest font-semibold"
                     style={{ color: CYAN }}>
                  <ShieldCheck size={12} weight="fill" /> Your current plan
                </div>
              )}
            </motion.button>
          );
        })}
      </div>

      {/* Sticky CTA */}
      <div
        className="fixed left-0 right-0 z-30 px-4 pt-3"
        style={{
          bottom: 0,
          paddingBottom: "calc(var(--safe-bottom) + 12px)",
          background:
            "linear-gradient(180deg, rgba(5,6,7,0) 0%, rgba(5,6,7,0.85) 40%, rgba(5,6,7,0.98) 100%)",
        }}
      >
        <div className="max-w-[430px] mx-auto flex flex-col gap-2">
          <AnimatePresence mode="wait">
            <motion.button
              key={selected}
              type="button"
              onClick={handlePurchase}
              disabled={!!purchasing}
              data-testid="paywall-start-btn"
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              transition={{ duration: 0.25 }}
              className="w-full py-4 rounded-full font-bold uppercase tracking-[0.22em] text-[13px] disabled:opacity-60 relative overflow-hidden active:scale-[0.985]"
              style={{
                background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
                color: "#001217",
                boxShadow: "0 0 26px rgba(0,229,255,0.55), 0 0 60px rgba(0,229,255,0.22)",
              }}
            >
              {purchasing
                ? "Starting…"
                : `Start ${products.find((p) => p.id === selected)?.name} — ${products.find((p) => p.id === selected)?.priceDisplay}/mo`}
            </motion.button>
          </AnimatePresence>

          <button
            type="button"
            onClick={handleRestore}
            disabled={restoring}
            data-testid="paywall-restore-btn"
            className="inline-flex items-center justify-center gap-1.5 text-[12px] text-white/60 active:text-white py-2"
          >
            <ArrowClockwise size={12} weight="bold" />
            {restoring ? "Restoring…" : "Restore purchases"}
          </button>

          <p className="text-[10px] text-white/35 text-center px-4 leading-relaxed">
            Payment is charged to your Apple ID at confirmation. Subscription auto-renews unless
            cancelled at least 24 hours before the end of the current period. Manage your subscription
            in your Apple ID settings.
          </p>
        </div>
      </div>
    </div>
  );
}
