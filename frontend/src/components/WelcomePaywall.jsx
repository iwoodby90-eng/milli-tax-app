/**
 * WelcomePaywall — pre-auth tier-selection gate (2-step trial-first flow).
 *
 * Step 0: Trial intro — full-screen pitch with feature list
 * Step 1: Plan selection — tier cards + fixed CTA
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

const TIERS = IAP_PRODUCTS;

function formatChargeDate(d) {
  return d.toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" });
}

export default function WelcomePaywall({ onSelect }) {
  const [step, setStep] = useState(0);
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
    } catch (e) { console.debug("[WelcomePaywall] localStorage save:", e); }
    onSelect?.(tier);
  }

  const bgStyle = {
    backgroundColor: "#050607",
    fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", "IBM Plex Sans", system-ui, sans-serif',
    backgroundImage:
      "radial-gradient(ellipse 60% 40% at 50% -5%, rgba(0, 229, 255, 0.14), transparent 65%)," +
      "repeating-linear-gradient(45deg, rgba(255,255,255,0.014) 0 2px, transparent 2px 6px)," +
      "repeating-linear-gradient(-45deg, rgba(255,255,255,0.010) 0 2px, transparent 2px 6px)",
  };

  return (
    <motion.div
      className="fixed inset-0 z-[200]"
      data-testid="welcome-paywall"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.6 }}
      style={bgStyle}
    >
      <AnimatePresence mode="wait">
        {step === 0 && (
          <motion.div
            key="step-0"
            className="fixed inset-0 z-[200] flex flex-col items-center justify-center px-6 text-center"
            style={bgStyle}
            initial={{ opacity: 0, x: 0 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
            transition={{ duration: 0.35 }}
          >
            <MilliLogo size={80} />
            <div className="chrome-text font-display text-3xl tracking-[0.2em] mt-4">MILLI</div>

            <h1 className="text-white font-display font-black mt-8" style={{ fontSize: 36 }}>
              Try Milli Free
            </h1>
            <p className="mt-2" style={{ color: CYAN, fontSize: 15 }}>
              3 Days. Your card will not be charged today.
            </p>

            <ul className="mt-8 flex flex-col gap-3 text-left max-w-[320px] w-full">
              {[
                "Full access to every Milli feature",
                "Auto-tracks income, expenses & mileage",
                "Keeps more of your money — automatically",
                "Cancel anytime before day 3, no charge",
              ].map((feat) => (
                <li key={feat} className="flex items-center gap-3 text-[15px] text-white/90">
                  <Check size={18} weight="bold" style={{ color: CYAN, flexShrink: 0 }} />
                  <span>{feat}</span>
                </li>
              ))}
            </ul>

            <div className="mt-10 w-full max-w-[340px]">
              <button
                type="button"
                onClick={() => setStep(1)}
                data-testid="welcome-start-free-btn"
                className="w-full py-4 rounded-full font-bold uppercase tracking-[0.22em] text-[13px] relative overflow-hidden active:scale-[0.985]"
                style={{
                  background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
                  color: "#001217",
                  boxShadow: "0 0 26px rgba(0,229,255,0.55), 0 0 60px rgba(0,229,255,0.22)",
                }}
              >
                Start My Free Trial →
              </button>
              <p className="text-center mt-3" style={{ fontSize: 11, color: "rgb(161 161 170)" }}>
                No payment due today. Cancel anytime in Apple ID settings.
              </p>
            </div>
          </motion.div>
        )}

        {step === 1 && (
          <motion.div
            key="step-1"
            className="fixed inset-0 z-[200] overflow-y-auto native-scroll"
            style={{
              ...bgStyle,
              paddingTop: "calc(var(--safe-top) + 16px)",
              paddingBottom: "calc(var(--safe-bottom) + 160px)",
            }}
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
            transition={{ duration: 0.35 }}
          >
            {/* Header */}
            <div className="flex flex-col items-center px-6 text-center">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] uppercase tracking-[0.24em] font-semibold"
                   style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.35)", color: CYAN }}>
                <ShieldCheck size={11} weight="fill" /> 3-Day Free Trial
              </div>
              <h1 className="text-white font-display font-black mt-4" style={{ fontSize: 28 }}>
                Choose your plan.
              </h1>
              <p className="text-zinc-400 text-[13px] mt-2 max-w-[320px]">
                Card not charged today. Free for 3 days, then billed monthly.
              </p>
            </div>

            {/* Plan cards */}
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
                    className="relative text-left rounded-2xl transition-all"
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

            {/* Fixed bottom CTA */}
            <div
              className="fixed bottom-0 left-0 right-0 z-[210] px-4 pt-3"
              style={{
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
                    <span className="relative">Start Free Trial — {tier.name} · {tier.priceDisplay}/mo</span>
                  </motion.button>
                </AnimatePresence>

                <p
                  className="text-[11px] text-white/70 text-center px-2 leading-relaxed"
                  data-testid="welcome-trial-disclosure"
                >
                  Your free trial ends {formatChargeDate(chargeDate)}.
                  After that, {tier.priceDisplay}/mo for Milli {tier.name} unless cancelled 24 hours before renewal.
                </p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
