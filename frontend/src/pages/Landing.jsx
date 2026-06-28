import { Link, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  MapTrifold, Bank, Robot, FileText, ShieldCheck, CaretRight,
  CurrencyDollar, Clock, ArrowUpRight, CheckCircle, Star, Sparkle,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

const PLATFORMS = ["UBER", "DOORDASH", "SPARK", "LYFT", "INSTACART", "AMAZON FLEX", "GRUBHUB", "SHIPT"];

export default function Landing() {
  const [tiers, setTiers] = useState([]);
  const { setSession } = useAuth();
  const navigate = useNavigate();
  useEffect(() => { api.get("/pricing/tiers").then(({ data }) => setTiers(data)).catch(() => {}); }, []);

  async function handleDemo() {
    try {
      const { data } = await api.post("/demo/seed");
      setSession(data.token, data.user);
      toast.success("Welcome to the Milli demo");
      navigate("/app");
    } catch (e) {
      toast.error("Demo unavailable — try again in a moment");
    }
  }

  return (
    <div className="min-h-screen carbon-bg text-white">
      {/* Nav */}
      <header className="sticky top-0 z-40 border-b border-hairline backdrop-blur-xl bg-obsidian/80">
        <div className="max-w-7xl mx-auto flex items-center justify-between px-5 py-4">
          <Link to="/" className="flex items-center gap-3" data-testid="landing-logo">
            <MilliLogo size={32} />
            <div className="font-display chrome-text text-2xl tracking-[0.25em]">MILLI</div>
          </Link>
          <nav className="hidden md:flex items-center gap-8 text-sm text-zinc-400 font-medium">
            <a href="#features" className="hover:text-white">Features</a>
            <a href="#how" className="hover:text-white">How it works</a>
            <a href="#pricing" className="hover:text-white">Pricing</a>
            <button onClick={() => handleDemo()} className="hover:text-volt" data-testid="nav-demo">Try demo</button>
          </nav>
          <div className="flex items-center gap-3">
            <Link to="/login" className="text-sm text-zinc-300 hover:text-white px-3 py-2" data-testid="nav-login">Sign in</Link>
            <Link to="/register" data-testid="nav-cta-start" className="btn-volt px-4 py-2 text-sm uppercase tracking-wider">Start trial</Link>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section className="relative overflow-hidden rays-bg">
        <div className="max-w-7xl mx-auto px-5 pt-20 pb-28 grid grid-cols-12 gap-6 relative">
          <div className="col-span-12 lg:col-span-7">
            <div className="inline-flex items-center gap-2 milli-card !rounded-full px-4 py-1.5 text-xs font-medium text-volt mb-8">
              <span className="w-1.5 h-1.5 bg-volt rounded-full animate-pulse-volt" />
              Tax Autopilot for Gig Workers
            </div>
            <h1 className="font-display chrome-text text-5xl sm:text-6xl lg:text-7xl tracking-tight leading-[0.95]">
              Earn freely.<br />
              <span className="text-volt" style={{ textShadow: "0 0 30px rgba(19,216,209,0.45)" }}>Milli handles<br />the tax side.</span>
            </h1>
            <p className="mt-8 text-lg text-zinc-400 max-w-xl leading-relaxed">
              Milli connects to your accounts, identifies every gig payout, auto-reserves your tax %,
              tracks every mile, and hands you tax-ready reports. Built for Uber, DoorDash, Spark, freelancers, and creators.
            </p>
            <div className="mt-10 flex flex-col sm:flex-row gap-4">
              <Link to="/register" data-testid="hero-cta-start" className="btn-volt px-7 py-4 text-base uppercase tracking-wider inline-flex items-center gap-2">
                Start 3-day free trial <CaretRight weight="bold" />
              </Link>
              <button onClick={handleDemo} data-testid="hero-cta-demo" className="btn-outline-cyan px-7 py-4 text-base uppercase tracking-wider inline-flex items-center gap-2 font-semibold">
                <Sparkle size={16} weight="fill" /> Try the demo
              </button>
            </div>
            <div className="mt-10 grid grid-cols-3 gap-6 max-w-md">
              <Stat label="Avg miles missed" value="3,200" suffix="mi/yr" />
              <Stat label="Avg refund lost" value="$2,240" />
              <Stat label="Time saved" value="11" suffix="hrs" />
            </div>
          </div>

          <div className="col-span-12 lg:col-span-5 grid grid-cols-2 gap-3 relative">
            {/* Phone-like preview */}
            <div className="col-span-2 milli-card p-5 relative overflow-hidden">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <MilliLogo size={24} />
                  <span className="font-display chrome-text text-sm tracking-[0.3em]">MILLI</span>
                </div>
                <span className="btn-outline-cyan px-2.5 py-1 text-[10px] font-semibold inline-flex items-center gap-1">
                  <Star size={10} weight="fill" /> Elite
                </span>
              </div>
              <div className="text-volt text-[10px] font-semibold uppercase tracking-[0.2em]">Next Quarterly Payment</div>
              <div className="chrome-text font-chrome font-bold text-4xl mt-1">$1,728<span className="text-2xl text-zinc-400">.42</span></div>
              <div className="text-xs text-zinc-400 font-mono mt-1">Q2 · Due Jun 15</div>
            </div>
            <div className="milli-card p-4">
              <CurrencyDollar size={20} weight="duotone" className="text-volt" />
              <div className="font-mono text-[10px] text-zinc-500 uppercase tracking-widest mt-3">Tax Score</div>
              <div className="chrome-text font-chrome font-bold text-3xl mt-1">92%</div>
            </div>
            <div className="milli-card p-4">
              <Clock size={20} weight="duotone" className="text-volt" />
              <div className="font-mono text-[10px] text-zinc-500 uppercase tracking-widest mt-3">Due in</div>
              <div className="chrome-text font-chrome font-bold text-3xl mt-1">23<span className="text-sm text-zinc-500 ml-1">days</span></div>
            </div>
          </div>
        </div>

        {/* Platform marquee */}
        <div className="border-y border-hairline overflow-hidden bg-obsidian/40">
          <div className="flex items-center gap-12 py-5 marquee-track whitespace-nowrap">
            {[...PLATFORMS, ...PLATFORMS, ...PLATFORMS].map((p, i) => (
              <div key={i} className="flex items-center gap-3 text-zinc-500 font-mono text-sm tracking-[0.3em]">
                <span className="w-1 h-1 bg-volt" />
                {p}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="max-w-7xl mx-auto px-5 py-24">
        <div className="flex items-end justify-between mb-14 flex-wrap gap-4">
          <div>
            <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Module 01</div>
            <h2 className="font-display chrome-text text-4xl sm:text-5xl tracking-tight mt-2">
              Four tools.<br />One job: keep your money.
            </h2>
          </div>
          <p className="max-w-md text-zinc-400">
            The IRS doesn't care that your "office" smells like Wendy's. Miss a mile and they'll happily take it.
            MILLI catches every dollar.
          </p>
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Feature icon={Bank} title="Bank-linked deposits" body="Plaid syncs your bank, finds Uber / DoorDash / Spark drops, skims the right tax %." />
          <Feature icon={MapTrifold} title="GPS mileage tracking" body="Tap Start — phone logs every mile. $0.70 / mi back from the IRS." />
          <Feature icon={Robot} title="AI tax assistant" body="Ask anything: 'Can I deduct phone bill?' Get a real answer in seconds." />
          <Feature icon={FileText} title="Tax vault" body="Schedule C + SE worksheet + mileage CSV. One click. Ready to file." />
        </div>
      </section>

      {/* How */}
      <section id="how" className="border-t border-hairline">
        <div className="max-w-7xl mx-auto px-5 py-24 grid lg:grid-cols-2 gap-16">
          <div>
            <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// How it works</div>
            <h2 className="font-display chrome-text text-4xl sm:text-5xl tracking-tight mt-2">Three taps.<br />Then you drive.</h2>
            <p className="mt-6 text-zinc-400 max-w-md">Set it up in under 4 minutes. Forget it exists until tax time, when MILLI hands you a finished return.</p>
          </div>
          <ol className="space-y-3">
            {[
              { n: "01", t: "Sign up + pick your state", b: "Needed to calculate state self-employment tax." },
              { n: "02", t: "Connect your bank via Plaid", b: "Read-only. We see deposits, ignore everything else." },
              { n: "03", t: "Drive. We track.", b: "Hit Start Trip when you go online. Every mile auto-deducted." },
              { n: "04", t: "Tax time → one-click forms", b: "Schedule C, SE, mileage CSV. You're done." },
            ].map((s) => (
              <li key={s.n} className="milli-card p-5 hover:border-volt/50 transition-colors group">
                <div className="flex items-baseline gap-5">
                  <div className="font-chrome font-bold text-3xl text-volt">{s.n}</div>
                  <div>
                    <h3 className="font-display chrome-text text-xl tracking-wide">{s.t}</h3>
                    <p className="text-sm text-zinc-400 mt-1">{s.b}</p>
                  </div>
                  <ArrowUpRight size={22} className="ml-auto text-zinc-600 group-hover:text-volt" />
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="border-t border-hairline rays-bg">
        <div className="max-w-7xl mx-auto px-5 py-24">
          <div className="text-center mb-14">
            <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Plans</div>
            <h2 className="font-display chrome-text text-4xl sm:text-5xl tracking-tight mt-2">
              Pay less in taxes.<br />Pay even less for MILLI.
            </h2>
            <p className="mt-4 text-zinc-400">3-day free trial on every plan. Cancel anytime.</p>
          </div>
          <div className="grid md:grid-cols-3 gap-4">
            {tiers.map((t) => (
              <div key={t.id} data-testid={`pricing-tier-${t.id}`} className={`milli-card p-6 relative ${t.popular ? "milli-card-strong" : ""}`}>
                {t.popular && (
                  <div className="absolute -top-3 left-6 btn-volt !rounded-full px-3 py-1 text-[10px] font-bold uppercase tracking-wider">
                    Most popular
                  </div>
                )}
                <div className="font-mono text-xs uppercase tracking-[0.3em] text-volt">{t.name}</div>
                <div className="mt-4 flex items-baseline gap-2">
                  <div className="chrome-text font-chrome font-bold text-5xl">${t.price}</div>
                  <div className="text-zinc-500 text-sm">/mo</div>
                </div>
                <div className="text-xs text-zinc-500 font-mono mt-1">{t.trial_days}-day free trial</div>
                <ul className="mt-6 space-y-2.5 text-sm text-zinc-300">
                  {t.features.map((f) => (
                    <li key={f} className="flex gap-2"><CheckCircle size={16} weight="fill" className="text-volt mt-0.5 flex-shrink-0" /> {f}</li>
                  ))}
                </ul>
                <Link to="/register" data-testid={`pricing-cta-${t.id}`} className={`mt-6 block w-full text-center py-3 uppercase tracking-wider text-sm font-bold ${t.popular ? "btn-volt" : "btn-outline-cyan"}`}>
                  Start trial
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="border-t border-hairline">
        <div className="max-w-5xl mx-auto px-5 py-24 text-center">
          <MilliLogo size={56} className="mx-auto mb-6" />
          <h2 className="font-display chrome-text text-5xl sm:text-6xl tracking-tight">
            Tax season ends.<br />
            <span className="text-volt">You kept your money — or you didn't.</span>
          </h2>
          <Link to="/register" data-testid="footer-cta-start" className="mt-10 inline-block btn-volt px-8 py-4 uppercase tracking-wider">
            Start 3-day trial
          </Link>
        </div>
      </section>

      <footer className="border-t border-hairline">
        <div className="max-w-7xl mx-auto px-5 py-8 flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-zinc-500">
          <div className="flex items-center gap-2"><MilliLogo size={18} /> MILLI © 2026</div>
          <div className="font-mono uppercase tracking-widest text-xs">Not a CPA · Not the IRS · On your side</div>
        </div>
      </footer>
    </div>
  );
}

function Stat({ label, value, suffix }) {
  return (
    <div>
      <div className="chrome-text font-chrome font-bold text-3xl">{value}<span className="text-volt text-base font-mono ml-1">{suffix}</span></div>
      <div className="text-[10px] text-zinc-500 mt-1 uppercase tracking-widest font-mono">{label}</div>
    </div>
  );
}

function Feature({ icon: Icon, title, body }) {
  return (
    <div className="milli-card p-6 h-full hover:border-volt/50 transition-colors group">
      <div className="w-12 h-12 rounded-xl bg-volt/10 border border-volt/40 text-volt flex items-center justify-center mb-5">
        <Icon size={22} weight="duotone" />
      </div>
      <h3 className="font-display chrome-text text-xl tracking-wide mb-2">{title}</h3>
      <p className="text-sm text-zinc-400 leading-relaxed">{body}</p>
    </div>
  );
}
