/**
 * AuthHero — the cinematic right-pane used on Login and Register.
 *
 * Shows the polished-chrome Milli mark + wordmark, the two Milli taglines,
 * and the 4-icon feature grid. Uses the extracted hero PNG for the mark itself
 * and CSS-composed text so the taglines remain crisp and responsive.
 */
import { Calculator, MapPin, ChartLine, ShieldCheck, Lock } from "@phosphor-icons/react";

const FEATURES = [
  {
    icon: Calculator,
    title: "AUTOMATE TAXES",
    body: "We calculate and\nprotect automatically.",
  },
  {
    icon: MapPin,
    title: "TRACK MILEAGE",
    body: "Every mile tracked.\nEvery deduction.",
  },
  {
    icon: ChartLine,
    title: "BUILD WEALTH",
    body: "Invest. Save. Retire.\nYour future, automated.",
  },
  {
    icon: ShieldCheck,
    title: "TAX SEASON READY",
    body: "Always prepared.\nAlways protected.",
  },
];

export default function AuthHero() {
  return (
    <div
      className="relative h-full w-full overflow-hidden"
      style={{
        background:
          "radial-gradient(120% 60% at 50% 100%, rgba(0,229,255,0.22), transparent 70%), " +
          "radial-gradient(90% 40% at 50% 0%, rgba(0,180,194,0.10), transparent 70%), " +
          "linear-gradient(180deg, #07090B 0%, #0B0F12 50%, #07090B 100%)",
      }}
      data-testid="auth-hero"
    >
      {/* Subtle floor gradient / horizon line */}
      <div
        className="absolute left-0 right-0 pointer-events-none"
        style={{
          top: "58%",
          height: "1px",
          background:
            "linear-gradient(90deg, transparent 0%, rgba(0,229,255,0.45) 50%, transparent 100%)",
          filter: "blur(0.5px)",
        }}
      />
      {/* Perspective runway */}
      <div
        className="absolute pointer-events-none"
        style={{
          left: "50%",
          top: "56%",
          transform: "translateX(-50%)",
          width: "180%",
          height: "44%",
          background:
            "radial-gradient(ellipse 50% 100% at 50% 0%, rgba(0,229,255,0.18), transparent 70%)",
        }}
      />

      {/* Hero content */}
      <div className="relative h-full w-full flex flex-col items-center justify-between p-8 lg:p-12">
        {/* Big M + MILLI */}
        <div className="flex-1 flex flex-col items-center justify-center w-full">
          <img
            src={`${process.env.PUBLIC_URL || ""}/brand/hero-m.png`}
            alt="Milli"
            className="w-[70%] max-w-[420px] h-auto select-none pointer-events-none drop-shadow-[0_0_80px_rgba(0,229,255,0.25)]"
            data-testid="auth-hero-mark"
          />

          {/* Taglines */}
          <div className="mt-8 text-center">
            <div
              className="font-mono text-[13px] lg:text-sm tracking-[0.32em] text-volt uppercase"
              data-testid="auth-hero-tagline"
            >
              Money, Made Intelligent.
            </div>
            <div className="mt-3 mx-auto h-px w-24 bg-gradient-to-r from-transparent via-white/25 to-transparent" />
            <div className="mt-3 font-mono text-[11px] lg:text-xs tracking-[0.35em] text-chrome-300 uppercase">
              Every payout, on Autopilot.
            </div>
          </div>
        </div>

        {/* Feature grid */}
        <div className="w-full max-w-2xl mx-auto">
          <div className="milli-card rounded-2xl px-4 py-5 lg:px-6 lg:py-6">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6">
              {FEATURES.map((f) => (
                <div key={f.title} className="text-center">
                  <div className="mx-auto w-11 h-11 rounded-xl bg-volt/10 border border-volt/25 flex items-center justify-center">
                    <f.icon size={20} weight="duotone" className="text-volt" />
                  </div>
                  <div className="mt-3 font-display font-bold text-[10px] lg:text-[11px] tracking-[0.2em] text-chrome-300 uppercase whitespace-nowrap">
                    {f.title}
                  </div>
                  <div className="mt-1.5 text-[10.5px] lg:text-[11px] text-zinc-400 leading-tight whitespace-pre-line">
                    {f.body}
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="mt-4 flex items-center justify-center gap-2 text-[10px] lg:text-[11px] text-zinc-500 font-mono tracking-wider uppercase">
            <Lock size={12} weight="fill" className="text-chrome-300" />
            Trusted by gig workers and self-employed professionals
          </div>
        </div>
      </div>
    </div>
  );
}
