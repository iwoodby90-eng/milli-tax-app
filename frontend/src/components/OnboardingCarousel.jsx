/**
 * OnboardingCarousel — 3-slide activation flow shown once after
 * SplashScreen dismisses (when `milli_onboarding_complete` is not set).
 *
 * Slides:
 *   1. Auto Tax Slicing — animated ring filling to 92%
 *   2. Zero-Tap Mileage — SVG road that draws itself
 *   3. Build Wealth While You Earn — stacked chrome coins growing
 *
 * Controls:
 *   • horizontal swipe (touch / mouse drag via framer-motion)
 *   • dot indicators
 *   • "Skip" top-right — writes flag + calls onFinish
 *   • "Next" on 1&2 · "Get Started" on 3
 *
 * Completing OR skipping writes `milli_onboarding_complete = "true"`.
 */
import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Shield, MapPin, TrendingUp } from "lucide-react";

const CYAN = "#00E5FF";
const CYAN_SOFT = "rgba(0, 229, 255, 0.55)";
const CARBON_BG = "#0A0A0A";

// -----------------------------------------------------------------------
// Slide 1 visual — animated tax-ready ring filling to 92%
// -----------------------------------------------------------------------
function TaxRingVisual({ active }) {
  const size = 210;
  const strokeW = 10;
  const radius = (size - strokeW) / 2;
  const circumference = 2 * Math.PI * radius;
  const target = 0.92;

  return (
    <div
      className="relative"
      style={{ width: size, height: size }}
      data-testid="slide-1-visual"
    >
      {/* soft glow behind the ring */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          background:
            "radial-gradient(circle at center, rgba(0,229,255,0.18), transparent 65%)",
          filter: "blur(10px)",
        }}
      />
      <svg width={size} height={size} className="relative">
        <defs>
          <linearGradient id="ringFill" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#7CF6FF" />
            <stop offset="100%" stopColor={CYAN} />
          </linearGradient>
        </defs>
        {/* track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="rgba(255,255,255,0.06)"
          strokeWidth={strokeW}
        />
        {/* progress */}
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="url(#ringFill)"
          strokeWidth={strokeW}
          strokeLinecap="round"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{
            strokeDashoffset: active
              ? circumference * (1 - target)
              : circumference,
          }}
          transition={{ duration: 1.8, ease: [0.16, 1, 0.3, 1] }}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
          style={{ filter: `drop-shadow(0 0 12px ${CYAN_SOFT})` }}
        />
      </svg>
      {/* percent label */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <motion.div
          className="text-white tabular-nums"
          style={{
            fontSize: 44,
            fontWeight: 700,
            letterSpacing: "-0.02em",
            textShadow: "0 0 20px rgba(0,229,255,0.35)",
          }}
          initial={{ opacity: 0 }}
          animate={{ opacity: active ? 1 : 0 }}
          transition={{ delay: 0.4, duration: 0.8 }}
        >
          <AnimatedNumber active={active} target={92} suffix="%" />
        </motion.div>
        <div
          className="text-[10px] uppercase text-white/60"
          style={{ letterSpacing: "0.22em" }}
        >
          Tax Ready
        </div>
      </div>
    </div>
  );
}

function AnimatedNumber({ active, target, suffix = "" }) {
  const [value, setValue] = useState(0);
  useEffect(() => {
    if (!active) {
      setValue(0);
      return;
    }
    const duration = 1500;
    const start = performance.now();
    let raf;
    const step = (t) => {
      const p = Math.min(1, (t - start) / duration);
      const eased = 1 - Math.pow(1 - p, 3);
      setValue(Math.round(eased * target));
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [active, target]);
  return (
    <>
      {value}
      {suffix}
    </>
  );
}

// -----------------------------------------------------------------------
// Slide 2 visual — road that draws itself with mile markers
// -----------------------------------------------------------------------
function RoadVisual({ active }) {
  return (
    <div className="relative w-full max-w-[320px] h-[210px]" data-testid="slide-2-visual">
      <svg viewBox="0 0 320 210" className="w-full h-full">
        <defs>
          <linearGradient id="roadStroke" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor={CYAN} stopOpacity="0.1" />
            <stop offset="50%" stopColor={CYAN} stopOpacity="1" />
            <stop offset="100%" stopColor={CYAN} stopOpacity="0.4" />
          </linearGradient>
        </defs>

        {/* horizon */}
        <line
          x1="20" y1="170" x2="300" y2="170"
          stroke="rgba(255,255,255,0.08)" strokeWidth="1"
        />

        {/* main road path */}
        <motion.path
          d="M 20 170 Q 90 90, 160 130 T 300 40"
          fill="none"
          stroke="url(#roadStroke)"
          strokeWidth="3"
          strokeLinecap="round"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: active ? 1 : 0 }}
          transition={{ duration: 2.0, ease: "easeInOut" }}
          style={{ filter: `drop-shadow(0 0 8px ${CYAN_SOFT})` }}
        />

        {/* road ghost (thinner, delayed, above the main) */}
        <motion.path
          d="M 20 170 Q 90 90, 160 130 T 300 40"
          fill="none"
          stroke={CYAN}
          strokeWidth="0.8"
          strokeLinecap="round"
          strokeDasharray="4 6"
          initial={{ pathLength: 0, opacity: 0 }}
          animate={{ pathLength: active ? 1 : 0, opacity: active ? 0.6 : 0 }}
          transition={{ duration: 2.4, ease: "easeInOut", delay: 0.5 }}
        />

        {/* mile markers */}
        {[
          { cx: 82, cy: 115, delay: 0.6, label: "MI 1" },
          { cx: 168, cy: 128, delay: 1.0, label: "MI 2" },
          { cx: 250, cy: 78, delay: 1.4, label: "MI 3" },
        ].map((m) => (
          <g key={m.label}>
            <motion.circle
              cx={m.cx}
              cy={m.cy}
              r="4"
              fill={CYAN}
              initial={{ scale: 0, opacity: 0 }}
              animate={{
                scale: active ? 1 : 0,
                opacity: active ? 1 : 0,
              }}
              transition={{ delay: m.delay, duration: 0.4 }}
              style={{ filter: `drop-shadow(0 0 6px ${CYAN})` }}
            />
            <motion.text
              x={m.cx}
              y={m.cy - 10}
              fill="rgba(255,255,255,0.7)"
              fontSize="8"
              textAnchor="middle"
              style={{ letterSpacing: "0.15em", fontFamily: "Inter" }}
              initial={{ opacity: 0 }}
              animate={{ opacity: active ? 1 : 0 }}
              transition={{ delay: m.delay + 0.2, duration: 0.4 }}
            >
              {m.label}
            </motion.text>
          </g>
        ))}

        {/* car icon at the leading edge */}
        <motion.g
          initial={{ opacity: 0 }}
          animate={{ opacity: active ? 1 : 0 }}
          transition={{ delay: 1.8, duration: 0.4 }}
        >
          <MapPin size={0} />
        </motion.g>
      </svg>

      {/* label */}
      <div className="absolute top-2 left-2 flex items-center gap-1.5">
        <MapPin size={12} color={CYAN} strokeWidth={2} />
        <span className="text-[9px] uppercase text-white/60" style={{ letterSpacing: "0.2em" }}>
          Live Trip
        </span>
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------
// Slide 3 visual — chrome coins stacking up with cyan glow
// -----------------------------------------------------------------------
function WealthVisual({ active }) {
  // 6 bars, each with staggered rise + growing height
  const bars = [
    { h: 42, delay: 0.05 },
    { h: 62, delay: 0.15 },
    { h: 90, delay: 0.25 },
    { h: 118, delay: 0.35 },
    { h: 148, delay: 0.45 },
    { h: 178, delay: 0.55 },
  ];
  return (
    <div className="relative w-full max-w-[300px] h-[210px] flex items-end justify-center gap-3" data-testid="slide-3-visual">
      {/* baseline glow */}
      <div
        className="absolute bottom-0 left-0 right-0 h-px"
        style={{
          background:
            "linear-gradient(90deg, transparent, rgba(0,229,255,0.6), transparent)",
          boxShadow: `0 0 8px ${CYAN}`,
        }}
      />
      {bars.map((b, i) => (
        <motion.div
          key={i}
          className="w-8 rounded-t-md relative overflow-hidden"
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: active ? b.h : 0, opacity: active ? 1 : 0 }}
          transition={{ delay: b.delay, duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
          style={{
            background:
              "linear-gradient(180deg, #EEF1F4 0%, #C7CDD3 40%, #8A9096 75%, #6F7479 100%)",
            border: "1px solid rgba(255,255,255,0.18)",
            boxShadow: `0 0 12px rgba(0, 229, 255, ${0.15 + i * 0.06}), inset 0 -6px 12px rgba(0,0,0,0.4)`,
          }}
        >
          {/* cyan accent stripe on top */}
          <div
            className="absolute top-0 left-0 right-0 h-1"
            style={{
              background: CYAN,
              boxShadow: `0 0 8px ${CYAN}`,
            }}
          />
        </motion.div>
      ))}
      {/* trending arrow */}
      <motion.div
        className="absolute top-2 right-2 flex items-center gap-1"
        initial={{ opacity: 0, x: -8 }}
        animate={{ opacity: active ? 1 : 0, x: active ? 0 : -8 }}
        transition={{ delay: 0.9, duration: 0.5 }}
      >
        <TrendingUp size={14} color={CYAN} strokeWidth={2} />
        <span
          className="text-[10px] font-medium tabular-nums"
          style={{ color: CYAN, letterSpacing: "0.05em" }}
        >
          +24.6%
        </span>
      </motion.div>
    </div>
  );
}

// -----------------------------------------------------------------------
// Slide chrome / layout
// -----------------------------------------------------------------------
function Slide({ index, active, headline, sub, tagline, children, testid }) {
  return (
    <div
      className="flex flex-col items-center justify-between px-6 pt-14 pb-32 h-full"
      style={{ width: "100%", flex: "0 0 100%" }}
      data-testid={testid}
    >
      {/* visual card */}
      <div
        className="w-full max-w-[360px] rounded-2xl flex items-center justify-center"
        style={{
          height: 260,
          background:
            "linear-gradient(180deg, rgba(13,17,23,0.6) 0%, rgba(10,10,10,0.3) 100%)",
          border: "1px solid rgba(180, 190, 200, 0.12)",
          backdropFilter: "blur(12px)",
          WebkitBackdropFilter: "blur(12px)",
          boxShadow:
            "inset 0 1px 0 rgba(255,255,255,0.05), 0 20px 60px rgba(0,0,0,0.55), 0 0 40px rgba(0,229,255,0.06)",
        }}
      >
        {children}
      </div>

      {/* text block */}
      <div className="flex flex-col items-center gap-3 mt-8 text-center max-w-[380px]">
        <motion.h2
          key={`h-${active}`}
          className="text-white"
          style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-0.01em" }}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: active ? 1 : 0, y: active ? 0 : 10 }}
          transition={{ delay: 0.15, duration: 0.5 }}
        >
          {headline}
        </motion.h2>
        <motion.p
          key={`s-${active}`}
          className="text-[15px] leading-relaxed"
          style={{ color: "#8B9DAF", fontWeight: 400 }}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: active ? 1 : 0, y: active ? 0 : 8 }}
          transition={{ delay: 0.28, duration: 0.5 }}
        >
          {sub}
        </motion.p>
        <motion.p
          key={`t-${active}`}
          className="text-[14px] text-white/85 mt-1"
          style={{ fontWeight: 500 }}
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: active ? 1 : 0, y: active ? 0 : 6 }}
          transition={{ delay: 0.4, duration: 0.5 }}
        >
          {tagline}
        </motion.p>
      </div>

      {/* index number bottom-left decoration */}
      <div
        className="absolute bottom-4 left-6 text-[10px] uppercase text-white/25 tabular-nums"
        style={{ letterSpacing: "0.25em" }}
      >
        0{index + 1} / 03
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------
// OnboardingCarousel
// -----------------------------------------------------------------------
const SLIDES = [
  {
    headline: "Automatic Tax Slicing",
    sub: "Every dollar you earn, Milli instantly calculates and sets aside your tax obligation.",
    tagline: "No thinking. No quarterly panic. Always ready.",
    visual: TaxRingVisual,
    testid: "onboarding-slide-1",
  },
  {
    headline: "Zero-Tap Mileage",
    sub: "Background GPS tracks every work mile. No buttons to press. IRS-compliant logs, automatically.",
    tagline: "Just drive. Milli handles the rest.",
    visual: RoadVisual,
    testid: "onboarding-slide-2",
  },
  {
    headline: "Build Wealth While You Earn",
    sub: "Solo 401k tracking. Tax-advantaged investing guidance. See how much you can shelter.",
    tagline: "Your money, working harder.",
    visual: WealthVisual,
    testid: "onboarding-slide-3",
  },
];

export default function OnboardingCarousel({ onFinish }) {
  const [index, setIndex] = useState(0);
  const last = SLIDES.length - 1;

  const finish = () => {
    try {
      localStorage.setItem("milli_onboarding_complete", "true");
    } catch (_) {
      /* localStorage unavailable — proceed anyway */
    }
    onFinish && onFinish();
  };

  const next = () => {
    if (index < last) setIndex(index + 1);
    else finish();
  };

  return (
    <motion.div
      className="absolute inset-0 z-[150] overflow-hidden"
      data-testid="onboarding-carousel"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.5 }}
      style={{
        backgroundColor: CARBON_BG,
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
        paddingTop:    "var(--safe-top)",
        paddingBottom: "var(--safe-bottom)",
        backgroundImage:
          "repeating-linear-gradient(45deg, rgba(255,255,255,0.014) 0 2px, transparent 2px 6px), repeating-linear-gradient(-45deg, rgba(255,255,255,0.010) 0 2px, transparent 2px 6px), radial-gradient(ellipse 80% 50% at 50% 0%, rgba(0,229,255,0.06), transparent 60%)",
      }}
    >
      {/* Skip */}
      <button
        type="button"
        onClick={finish}
        data-testid="onboarding-skip"
        className="absolute top-4 right-5 z-20 text-white/55 hover:text-white transition-colors"
        style={{
          fontSize: 12,
          fontWeight: 500,
          letterSpacing: "0.18em",
          textTransform: "uppercase",
        }}
      >
        Skip
      </button>

      {/* Corner brackets — brand */}
      <div className="absolute top-4 left-4 w-6 h-6 border-l border-t" style={{ borderColor: "rgba(0,229,255,0.35)" }} />
      <div className="absolute bottom-4 right-4 w-6 h-6 border-r border-b" style={{ borderColor: "rgba(0,229,255,0.35)" }} />

      {/* Slide track — swipeable */}
      <motion.div
        className="flex h-full"
        drag="x"
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.18}
        onDragEnd={(_, info) => {
          if (info.offset.x < -60 && index < last) setIndex(index + 1);
          else if (info.offset.x > 60 && index > 0) setIndex(index - 1);
        }}
        animate={{ x: `-${index * 100}%` }}
        transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
        style={{ width: `${SLIDES.length * 100}%` }}
      >
        {SLIDES.map((slide, i) => {
          const Visual = slide.visual;
          return (
            <Slide
              key={i}
              index={i}
              active={index === i}
              headline={slide.headline}
              sub={slide.sub}
              tagline={slide.tagline}
              testid={slide.testid}
            >
              <Visual active={index === i} />
            </Slide>
          );
        })}
      </motion.div>

      {/* Dots + Next/Get Started */}
      <div className="absolute bottom-0 left-0 right-0 flex flex-col items-center gap-5 pb-8 px-6 z-10 pointer-events-none">
        {/* dots */}
        <div className="flex items-center gap-2 pointer-events-auto" data-testid="onboarding-dots">
          {SLIDES.map((_, i) => (
            <button
              key={i}
              type="button"
              onClick={() => setIndex(i)}
              data-testid={`onboarding-dot-${i}`}
              aria-label={`Go to slide ${i + 1}`}
              className="transition-all"
              style={{
                width: index === i ? 22 : 6,
                height: 6,
                borderRadius: 3,
                background: index === i ? CYAN : "rgba(180,190,200,0.35)",
                boxShadow: index === i ? `0 0 10px ${CYAN}` : "none",
                border: "none",
                cursor: "pointer",
              }}
            />
          ))}
        </div>

        {/* CTA */}
        <div className="w-full max-w-[380px] pointer-events-auto">
          <AnimatePresence mode="wait">
            {index < last ? (
              <motion.button
                key="next"
                type="button"
                onClick={next}
                data-testid="onboarding-next"
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={{ duration: 0.35 }}
                className="mx-auto flex items-center justify-center gap-2 rounded-full transition-transform active:scale-[0.97]"
                style={{
                  padding: "12px 32px",
                  background: "linear-gradient(180deg, rgba(0,229,255,0.18), rgba(0,229,255,0.05))",
                  border: `1px solid ${CYAN_SOFT}`,
                  color: "#EAF9FD",
                  fontSize: 13,
                  fontWeight: 600,
                  letterSpacing: "0.18em",
                  textTransform: "uppercase",
                  boxShadow: `0 0 20px rgba(0,229,255,0.18)`,
                  cursor: "pointer",
                }}
              >
                Next <span style={{ color: CYAN }}>›</span>
              </motion.button>
            ) : (
              <motion.button
                key="start"
                type="button"
                onClick={finish}
                data-testid="onboarding-get-started"
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={{ duration: 0.35 }}
                className="w-full flex items-center justify-center rounded-full transition-transform active:scale-[0.98] relative overflow-hidden"
                style={{
                  padding: "16px 24px",
                  background:
                    "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
                  border: `1px solid rgba(255,255,255,0.25)`,
                  color: "#001217",
                  fontSize: 14,
                  fontWeight: 700,
                  letterSpacing: "0.22em",
                  textTransform: "uppercase",
                  boxShadow: `0 0 26px rgba(0,229,255,0.55), 0 0 60px rgba(0,229,255,0.25)`,
                  cursor: "pointer",
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
                  transition={{
                    duration: 2.4,
                    repeat: Infinity,
                    ease: "linear",
                    repeatDelay: 0.8,
                  }}
                />
                <span className="relative">Get Started</span>
              </motion.button>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Brand mini watermark */}
      <div
        className="absolute top-4 left-1/2 -translate-x-1/2 text-[10px] uppercase text-white/40"
        style={{ letterSpacing: "0.4em" }}
      >
        Milli
      </div>

      {/* Feature badges/icons on side */}
      {index === 0 && (
        <div className="absolute top-24 left-8 pointer-events-none opacity-30">
          <Shield size={12} color={CYAN} />
        </div>
      )}
    </motion.div>
  );
}
