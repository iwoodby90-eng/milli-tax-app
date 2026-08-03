/**
 * OnboardingCarousel — pre-auth marketing preview (3 pages).
 * Solid, visible, iOS-native. Ends with a Get-Started CTA that routes
 * users to /register → then the interactive onboarding at /onboarding
 * where they connect their bank, add their vehicle, and grant location.
 */
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useNavigate } from "react-router-dom";
import {
  ShieldCheck, Bank, Car, MapPin, Sparkle, Timer, ChartLineUp, CaretRight,
} from "@phosphor-icons/react";

const CYAN = "#00E5FF";

const SLIDES = [
  {
    kind: "vault",
    eyebrow: "Milli Autopilot™",
    headline: "Every payout, protected.",
    body: "The moment Uber or DoorDash pays you, Milli auto-slices your tax portion into a dedicated Tax Vault. No spreadsheets. No April panic.",
    Icon: ShieldCheck,
    stat: "$1,480.42",
    statLabel: "Protected this year",
    hint: "Auto-slicing is on the moment you connect your bank.",
  },
  {
    kind: "mileage",
    eyebrow: "Zero-Tap Mileage",
    headline: "Every mile, deducted.",
    body: "Background GPS detects when you're driving and logs the trip. Milli turns every business mile into a real IRS deduction.",
    Icon: MapPin,
    stat: "1,247 mi",
    statLabel: "Last 30 days · $872 write-off",
    hint: "Requires 'Always' location — you'll grant it next.",
  },
  {
    kind: "cents",
    eyebrow: "Milli Cents",
    headline: "Score every offer. Live.",
    body: "See net profit before you accept. Milli deducts your car's real gas cost, deadhead miles, and taxes so you only take offers that actually pay.",
    Icon: ChartLineUp,
    stat: "GO · 82/100",
    statLabel: "Live offer verdict",
    hint: "Tell Milli your car's make & model for exact fuel math.",
  },
];

export default function OnboardingCarousel({ onFinish }) {
  const [index, setIndex] = useState(0);
  const nav = useNavigate();
  const last = SLIDES.length - 1;
  const s = SLIDES[index];

  const finish = () => {
    try { localStorage.setItem("milli_onboarding_complete", "true"); } catch (e) { /* localStorage unavailable */ void e; }
    onFinish && onFinish();
    try { nav("/register"); } catch (e) { void e; }
  };
  const next = () => (index < last ? setIndex(index + 1) : finish());

  return (
    <div
      className="absolute inset-0 z-[150] carbon-bg text-white flex flex-col overflow-hidden"
      data-testid="onboarding-carousel"
      style={{
        paddingTop: "calc(var(--safe-top) + 12px)",
        paddingBottom: "calc(var(--safe-bottom) + 16px)",
        backgroundImage:
          "radial-gradient(ellipse 80% 45% at 50% 0%, rgba(0,229,255,0.10), transparent 60%)," +
          "repeating-linear-gradient(45deg, rgba(255,255,255,0.014) 0 2px, transparent 2px 6px)," +
          "repeating-linear-gradient(-45deg, rgba(255,255,255,0.010) 0 2px, transparent 2px 6px)",
      }}
    >
      {/* Top row: skip + progress */}
      <div className="flex items-center justify-between px-5 mb-2 flex-shrink-0">
        <div className="text-[10px] font-mono text-zinc-500 uppercase tracking-widest">
          {String(index + 1).padStart(2, "0")} / 03
        </div>
        <button
          onClick={finish}
          data-testid="onboarding-skip"
          className="text-white/60 active:opacity-60"
          style={{ fontSize: 11, letterSpacing: "0.18em", textTransform: "uppercase", fontWeight: 500 }}
        >
          Skip
        </button>
      </div>

      {/* Progress dots */}
      <div className="flex justify-center gap-2 mb-6 flex-shrink-0" data-testid="onboarding-dots">
        {SLIDES.map((_, i) => (
          <button
            key={`slide-dot-${i}`}
            onClick={() => setIndex(i)}
            data-testid={`onboarding-dot-${i}`}
            aria-label={`Slide ${i + 1}`}
            className="transition-all"
            style={{
              width: index === i ? 22 : 6,
              height: 6,
              borderRadius: 3,
              background: index === i ? CYAN : "rgba(180,190,200,0.35)",
              boxShadow: index === i ? `0 0 10px ${CYAN}` : "none",
              border: "none",
            }}
          />
        ))}
      </div>

      {/* Slide content — content-aware height, no drag needed */}
      <div className="flex-1 min-h-0 flex items-center justify-center px-6">
        <AnimatePresence mode="wait">
          <motion.div
            key={s.kind}
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -18 }}
            transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
            className="w-full max-w-md flex flex-col items-center text-center"
          >
            {/* Hero card */}
            <div
              className="w-full rounded-3xl p-6 mb-6 relative overflow-hidden"
              style={{
                background:
                  "linear-gradient(135deg, rgba(0,180,200,0.24) 0%, rgba(0,229,255,0.06) 40%, rgba(10,14,18,0.92) 75%)",
                border: "1px solid rgba(0,229,255,0.5)",
                boxShadow: "inset 0 1px 0 rgba(255,255,255,0.08), 0 0 28px rgba(0,229,255,0.35), 0 20px 44px rgba(0,0,0,0.55)",
              }}
            >
              <div className="flex items-center justify-between mb-4">
                <span
                  className="font-mono text-[10.5px] uppercase tracking-[0.28em]"
                  style={{ color: CYAN, textShadow: `0 0 8px ${CYAN}88` }}
                >
                  {s.eyebrow}
                </span>
                <div
                  className="w-10 h-10 rounded-2xl flex items-center justify-center"
                  style={{
                    background: `radial-gradient(circle at 30% 25%, ${CYAN}55 0%, rgba(0,0,0,0.5) 80%)`,
                    border: `1px solid ${CYAN}66`,
                    boxShadow: `0 0 14px ${CYAN}55`,
                  }}
                >
                  <s.Icon size={20} weight="duotone" style={{ color: CYAN }} />
                </div>
              </div>
              <div
                className="chrome-text font-chrome font-black text-[38px] leading-none tabular-nums text-left"
              >
                {s.stat}
              </div>
              <div className="text-white/70 text-[13px] mt-2 text-left">{s.statLabel}</div>
            </div>

            {/* Text block */}
            <h1 className="text-white font-chrome font-bold text-[28px] leading-tight tracking-tight">
              {s.headline}
            </h1>
            <p className="text-zinc-400 text-[15px] mt-3 leading-relaxed max-w-sm">
              {s.body}
            </p>
            <p
              className="mt-4 text-[12px] font-medium"
              style={{ color: CYAN, textShadow: `0 0 6px ${CYAN}44` }}
            >
              {s.hint}
            </p>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* CTA */}
      <div className="flex-shrink-0 px-6 mt-2">
        <button
          onClick={next}
          data-testid={index < last ? "onboarding-next" : "onboarding-get-started"}
          className="w-full rounded-full py-4 font-bold uppercase tracking-[0.22em] text-[13px] relative overflow-hidden active:scale-[0.985]"
          style={{
            background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
            color: "#001217",
            boxShadow: "0 0 26px rgba(0,229,255,0.55), 0 0 60px rgba(0,229,255,0.22)",
          }}
        >
          <span className="relative inline-flex items-center gap-2">
            {index < last ? "Continue" : "Get Started"}
            <CaretRight size={13} weight="bold" />
          </span>
        </button>
      </div>
    </div>
  );
}
