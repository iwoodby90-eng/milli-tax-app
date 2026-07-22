/**
 * WelcomePaywall — pre-auth tier-selection gate.
 *
 * Rendered as an overlay after the splash auto-fades, BEFORE the user
 * ever hits the onboarding carousel or the auth screens. Enforces the
 * product rule: nobody uses Milli without picking a subscription first.
 *
 * The user isn't authenticated yet, so this component does NOT call
 * StoreKit or the backend. It only:
 *   1. Records the intended tier + trial start date in localStorage
 *   2. Displays the 3-day-free-trial disclosure with the exact date
 *      they'll be charged and the exact amount
 *
 * The actual native purchase happens after they finish onboarding +
 * create an account (which reads `milli_selected_plan` from storage).
 */
import { useMemo, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Check, Star, ShieldCheck } from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import { IAP_PRODUCTS } from "@/hooks/useStoreKit";

const CYAN = "#00E5FF";

// Same 3 tiers the native paywall uses — priced identically.
const TIERS = IAP_PRODUCTS;

function formatChargeDate(d) {
  return d.toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" });
}

export default function WelcomePaywall({ onSelected }) {
  const [selected, setSelected] = useState("milli.pro.monthly");
  const chargeDate = useMemo(() => {
    const d = new Date();
    d.setDate(d.getDate() + 3);
    return d;
  }, []);
  const tier = TIERS.find((t) => t.id === selected) || TIERS[1];

  function handleStart() {
    try {
      const record = {
        product_id: selected,
        plan: tier.plan,
        price: tier.price,
        price_display: tier.priceDisplay,
        trial_started_at: new Date().toISOString(),
        first_charge_at: chargeDate.toISOString(),
      };
      localStorage.setItem("milli_selected_plan", JSON.stringify(record));
    } catch (_) { /* localStorage unavailable — proceed anyway */ }
    onSelected && onSelected(tier);
  }

  return (
    <motion.div
      className="absolute inset-0 z-[180] overflow-y-auto native-scroll"
      data-testid="welcome-paywall"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.6 }}
      style={{
        backgroundColor: "#050607",
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
        paddingTop:    "calc(var(--safe-top) + 12px)",
        paddingBottom: "calc(var(--safe-bottom) + 140px)",
        backgroundImage:
          "radial-gradient(ellipse 60% 40% at 50% -5%,  rgba(0, 229, 255, 0.14), transparent 65%)," +
          "repeating-linear-gradient(45deg, rgba(255,255,255,0.014) 0 2px, transparent 2px 6px)," +
          "repeating-linear-gradient(-45deg, rgba(255,255,255,0.010) 0 2px, transparent 2px 6px)",
      }}
    >
      {/* Hero */}
      <div className="flex flex-col items-center px-6 text-center">
        <MilliLogo size={72} />
        <div className="chrome-text font-display text-3xl tracking-[0.2em] mt-3">MILLI</div>
        <div className="mt-3 inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] uppercase tracking-[0.24em] font-semibold"
             style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.35)", color: CYAN }}>
          <ShieldCheck size={11} weight="fill" /> 3-Day Free Trial
        </div>
        <h1 className="text-white text-[26px] leading-tight font-bold mt-4 max-w-[300px]">
          Pick your plan to <span style={{ color: CYAN }}>start earning smarter</span>.
        </h1>
        <p className="text-zinc-400 text-[13px] mt-2 max-w-[320px]">
          Full access to Milli for 3 days. Cancel anytime before day 3 and you won&apos;t be charged.
        </p>
      </div>

      {/* Tier cards */}
      <div className="px-4 flex flex-col gap-3 mt-6">
        {TIERS.map((t) => {
          const isActive = selected === t.id;
          return (
            <motion.button
              key={t.id}
              type="button"
              onClick={() => setSelected(t.id)}
              data-testid={`welcome-tier-${t.plan}`}
              whileTap={{ scale: 0.985 }}
              className="relative text-left rounded-2xl overflow-hidden transition-all"
              style={{
                background: isActive
                  ? "linear-gradient(180deg, rgba(0,229,255,0.10), rgba(0,229,255,0.02))"
                  : "linear-gradient(180deg, rgba(255,255,255,0.03), rgba(255,255,255,0))",
                border: `1px solid ${isActive ? "rgba(0,229,255,0.75)" : "rgba(192,192,192,0.16)"}`,
                boxShadow: isActive
                  ? "0 0 26px rgba(0,229,255,0.22), inset 0 1px 0 rgba(255,255,255,0.06)"
                  : "inset 0 1px 0 rgba(255,255,255,0.04)",
                padding: 16,
              }}
            >
              {t.featured && (
                <div className="absolute -top-2.5 left-4 flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest px-2.5 py-0.5 rounded-full"
                     style={{ color: "#001217", background: CYAN, boxShadow: "0 0 12px rgba(0,229,255,0.55)" }}>
                  <Star size={10} weight="fill" /> Most popular
                </div>
              )}
              <div className="flex items-baseline justify-between gap-4">
                <div className="flex-1 min-w-0 pr-2">
                  <div className="text-[11px] uppercase tracking-[0.24em] text-white/60">Milli</div>
                  <div className="chrome-text font-display text-[22px] leading-none mt-0.5 truncate">{t.name}</div>
                  <div className="text-zinc-400 text-[13px] mt-1 leading-snug">{t.tagline}</div>
                </div>
                <div className="text-right flex-shrink-0">
                  <div className="font-chrome font-bold text-white text-[22px] leading-none tabular-nums whitespace-nowrap">
                    {t.priceDisplay}
                  </div>
                  <div className="text-[10px] uppercase tracking-widest text-white/40 mt-1">/month</div>
                </div>
              </div>
              <ul className="mt-3 grid gap-1.5">
                {t.features.slice(0, 4).map((f) => (
                  <li key={f} className="flex items-center gap-2 text-[13px] text-white/85">
                    <Check size={14} weight="bold" style={{ color: CYAN }} />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>
              {isActive && (
                <div className="mt-3 inline-flex items-center gap-1 text-[10px] uppercase tracking-widest font-semibold"
                     style={{ color: CYAN }}>
                  Selected ✓
                </div>
              )}
            </motion.button>
          );
        })}
      </div>

      {/* Sticky CTA */}
      <div
        className="fixed left-0 right-0 z-40 px-4 pt-3"
        style={{
          bottom: 0,
          paddingBottom: "calc(var(--safe-bottom) + 14px)",
          background:
            "linear-gradient(180deg, rgba(5,6,7,0) 0%, rgba(5,6,7,0.9) 40%, rgba(5,6,7,0.98) 100%)",
        }}
      >
        <div className="max-w-[430px] mx-auto flex flex-col gap-2">
          <AnimatePresence mode="wait">
            <motion.button
              key={selected}
              type="button"
              onClick={handleStart}
              data-testid="welcome-start-trial-btn"
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              transition={{ duration: 0.25 }}
              className="w-full py-4 rounded-full font-bold uppercase tracking-[0.22em] text-[13px] relative overflow-hidden active:scale-[0.985]"
              style={{
                background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
                color: "#001217",
                boxShadow: "0 0 26px rgba(0,229,255,0.55), 0 0 60px rgba(0,229,255,0.22)",
              }}
            >
              <motion.span
                className="absolute inset-0 pointer-events-none"
                style={{
                  background:
                    "linear-gradient(120deg, transparent 30%, rgba(255,255,255,0.4) 50%, transparent 70%)",
                }}
                initial={{ x: "-120%" }}
                animate={{ x: "120%" }}
                transition={{ duration: 2.4, repeat: Infinity, ease: "linear", repeatDelay: 0.8 }}
              />
              <span className="relative">Start 3-Day Free Trial</span>
            </motion.button>
          </AnimatePresence>

          {/* Trial disclosure — exact billing date + amount */}
          <p
            className="text-[11px] text-white/70 text-center px-2 leading-relaxed"
            data-testid="welcome-trial-disclosure"
          >
            Your free trial ends on{" "}
            <span className="text-white font-semibold">{formatChargeDate(chargeDate)}</span>.
            After that, you&apos;ll be charged{" "}
            <span className="font-semibold" style={{ color: CYAN }}>{tier.priceDisplay}/month</span>{" "}
            for <span className="text-white font-semibold">Milli {tier.name}</span> unless you
            cancel at least 24 hours beforehand. Manage or cancel anytime in your Apple ID
            settings.
          </p>
        </div>
      </div>
    </motion.div>
  );
}
