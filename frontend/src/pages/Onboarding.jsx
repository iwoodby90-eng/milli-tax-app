/**
 * 8-step cinematic onboarding flow — Welcome → Employment Type → Income Sources
 * → Tax Profile → Connect Accounts → Tax Vault → Mileage Permissions → Ready.
 */
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { useAuth } from "@/context/AuthContext";
import { api, formatApiError } from "@/lib/api";
import { toast } from "sonner";
import MilliLogo from "@/components/MilliLogo";
import {
  Car, ForkKnife, Sparkle, VideoCamera, ShoppingBag, Briefcase, Wrench,
  Stack, ShieldCheck, ArrowRight, ArrowLeft, MapPin, Bank, CheckCircle,
} from "@phosphor-icons/react";

const EMPLOYMENT_TYPES = [
  { id: "rideshare", icon: Car, label: "Rideshare" },
  { id: "delivery", icon: ForkKnife, label: "Delivery" },
  { id: "freelance", icon: Sparkle, label: "Freelance services" },
  { id: "creator", icon: VideoCamera, label: "Content creation" },
  { id: "selling", icon: ShoppingBag, label: "Online selling" },
  { id: "consulting", icon: Briefcase, label: "Consulting" },
  { id: "home_services", icon: Wrench, label: "Home services" },
  { id: "multiple", icon: Stack, label: "Multiple sources" },
];

const PLATFORMS = [
  "Uber", "Lyft", "DoorDash", "Instacart", "Grubhub", "Amazon Flex", "Spark",
  "Etsy", "Shopify", "Stripe", "PayPal", "Venmo Business",
  "Square", "Upwork", "Fiverr", "Direct deposits",
];

const STATES = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"];

export default function Onboarding() {
  const { user, refresh } = useAuth();
  const nav = useNavigate();
  const [step, setStep] = useState(0);
  const [data, setData] = useState({
    employment_types: [],
    income_sources: [],
    state: user?.state || "TX",
    filing_status: user?.filing_status || "single",
    expected_income: "",
    dependents: 0,
    reserve_strategy: "balanced",
    mileage_mode: "auto",
  });

  const update = (k, v) => setData((d) => ({ ...d, [k]: v }));
  const toggle = (k, v) => setData((d) => ({
    ...d, [k]: d[k].includes(v) ? d[k].filter((x) => x !== v) : [...d[k], v]
  }));

  async function finish() {
    try {
      await api.put("/auth/profile", {
        state: data.state,
        filing_status: data.filing_status,
      });
      await api.post("/onboarding/complete", {
        employment_types: data.employment_types,
        income_sources: data.income_sources,
        expected_income: parseFloat(data.expected_income || 0),
        dependents: parseInt(data.dependents || 0),
        reserve_strategy: data.reserve_strategy,
        mileage_mode: data.mileage_mode,
      });
      await refresh();
      toast.success("Milli is ready");
      nav("/app");
    } catch (e) { toast.error(formatApiError(e)); }
  }

  const steps = [
    <Welcome key="0" onNext={() => setStep(1)} />,
    <Employment key="1" data={data} toggle={toggle} onBack={() => setStep(0)} onNext={() => setStep(2)} />,
    <Sources key="2" data={data} toggle={toggle} onBack={() => setStep(1)} onNext={() => setStep(3)} />,
    <TaxProfile key="3" data={data} update={update} onBack={() => setStep(2)} onNext={() => setStep(4)} />,
    <Connect key="4" onBack={() => setStep(3)} onNext={() => setStep(5)} />,
    <VaultStep key="5" data={data} update={update} onBack={() => setStep(4)} onNext={() => setStep(6)} />,
    <Mileage key="6" data={data} update={update} onBack={() => setStep(5)} onNext={() => setStep(7)} />,
    <Ready key="7" data={data} onBack={() => setStep(6)} onFinish={finish} />,
  ];

  return (
    <div className="min-h-screen carbon-bg text-white relative overflow-hidden flex flex-col">
      {/* Backdrop rays */}
      <div className="absolute inset-0 rays-bg opacity-60 pointer-events-none" />

      {/* Top bar */}
      <div className="relative z-10 flex items-center justify-between px-6 py-5 border-b border-hairline/50">
        <div className="flex items-center gap-2">
          <MilliLogo size={26} />
          <span className="font-display tracking-[0.3em] chrome-text text-sm">MILLI</span>
        </div>
        <div className="flex gap-1" data-testid="onboarding-progress">
          {steps.map((_, i) => (
            <div key={i} className={`h-1 rounded-full transition-all ${i <= step ? "bg-volt w-6" : "bg-zinc-700 w-3"}`} />
          ))}
        </div>
        <div className="text-xs font-mono text-zinc-500 uppercase tracking-widest">{step + 1}/{steps.length}</div>
      </div>

      <div className="relative z-10 flex-1 flex items-center justify-center px-5 py-10">
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 32 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -32 }}
            transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
            className="w-full max-w-xl"
          >
            {steps[step]}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

function Welcome({ onNext }) {
  return (
    <div className="text-center">
      <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ duration: 0.6 }} className="mx-auto mb-8">
        <MilliLogo size={96} />
      </motion.div>
      <h1 className="font-display chrome-text text-4xl sm:text-5xl tracking-tight">Taxes should not surprise you.</h1>
      <p className="text-zinc-400 mt-5 max-w-md mx-auto leading-relaxed">
        Milli tracks what you earn, estimates what you owe, and helps reserve it automatically.
        Three minutes to set up. Then it works in the background.
      </p>
      <button onClick={onNext} data-testid="ob-welcome-next" className="btn-volt mt-10 px-8 py-4 uppercase tracking-wider text-sm inline-flex items-center gap-2">
        Set up my Milli <ArrowRight weight="bold" />
      </button>
    </div>
  );
}

function Employment({ data, toggle, onBack, onNext }) {
  return (
    <div>
      <Eyebrow>// 02 · Employment</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">How do you earn?</h2>
      <p className="text-zinc-400 text-sm mt-2">Pick all that apply.</p>
      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mt-8">
        {EMPLOYMENT_TYPES.map((e) => {
          const on = data.employment_types.includes(e.id);
          return (
            <button
              key={e.id}
              data-testid={`ob-emp-${e.id}`}
              onClick={() => toggle("employment_types", e.id)}
              className={`milli-card p-4 text-left transition-all ${on ? "border-volt bg-volt/5" : "hover:border-volt/40"}`}
            >
              <e.icon size={22} weight="duotone" className={on ? "text-volt" : "text-zinc-400"} />
              <div className="mt-2 text-sm font-medium">{e.label}</div>
            </button>
          );
        })}
      </div>
      <NavRow onBack={onBack} onNext={onNext} disabled={data.employment_types.length === 0} testid="ob-emp" />
    </div>
  );
}

function Sources({ data, toggle, onBack, onNext }) {
  return (
    <div>
      <Eyebrow>// 03 · Income sources</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">Where does your money come from?</h2>
      <p className="text-zinc-400 text-sm mt-2">We'll watch your bank for deposits from these platforms.</p>
      <div className="flex flex-wrap gap-2 mt-8">
        {PLATFORMS.map((p) => {
          const on = data.income_sources.includes(p);
          return (
            <button
              key={p}
              data-testid={`ob-src-${p.toLowerCase().replace(/\s+/g, "-")}`}
              onClick={() => toggle("income_sources", p)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${on ? "bg-volt text-obsidian border border-volt" : "border border-hairline text-zinc-300 hover:border-volt/40"}`}
            >{p}</button>
          );
        })}
      </div>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-src" />
    </div>
  );
}

function TaxProfile({ data, update, onBack, onNext }) {
  return (
    <div>
      <Eyebrow>// 04 · Tax profile</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">A few numbers to dial it in.</h2>
      <div className="grid sm:grid-cols-2 gap-3 mt-8">
        <Field id="ob-state" label="State of residence">
          <select id="ob-state" data-testid="ob-state" value={data.state} onChange={(e) => update("state", e.target.value)} className="ob-input">
            {STATES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        </Field>
        <Field id="ob-filing" label="Filing status">
          <select id="ob-filing" data-testid="ob-filing" value={data.filing_status} onChange={(e) => update("filing_status", e.target.value)} className="ob-input">
            <option value="single">Single</option>
            <option value="married_joint">Married, Joint</option>
            <option value="married_separate">Married, Separate</option>
            <option value="head_of_household">Head of Household</option>
          </select>
        </Field>
        <Field id="ob-income" label="Expected annual self-employment income">
          <input id="ob-income" data-testid="ob-income" type="number" placeholder="e.g. 48000" value={data.expected_income} onChange={(e) => update("expected_income", e.target.value)} className="ob-input" />
        </Field>
        <Field id="ob-deps" label="Dependents">
          <input id="ob-deps" data-testid="ob-deps" type="number" min="0" value={data.dependents} onChange={(e) => update("dependents", e.target.value)} className="ob-input" />
        </Field>
        <Field id="ob-strategy" label="Reserve strategy">
          <select id="ob-strategy" data-testid="ob-strategy" value={data.reserve_strategy} onChange={(e) => update("reserve_strategy", e.target.value)} className="ob-input">
            <option value="conservative">Conservative · 30%</option>
            <option value="balanced">Balanced · 25%</option>
            <option value="minimum">Minimum · 20%</option>
          </select>
        </Field>
      </div>
      <p className="text-[10px] text-zinc-500 mt-4 leading-relaxed">
        Calculations are estimates and don't constitute legal or tax advice. Consult a CPA for complex situations.
      </p>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-tax" />
      <style>{`.ob-input { width: 100%; background: rgba(5,6,7,0.6); border: 1px solid #1B2027; border-radius: 12px; padding: 10px 14px; font-size: 14px; color: white; outline: none; }
        .ob-input:focus { border-color: #13D8D1; }`}</style>
    </div>
  );
}

function Connect({ onBack, onNext }) {
  return (
    <div>
      <Eyebrow>// 05 · Connect accounts</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">Read-only access. Encrypted.</h2>
      <p className="text-zinc-400 text-sm mt-3 max-w-md">
        After setup, you'll connect your bank, business, and credit accounts via Plaid.
        Milli sees transactions only — no credentials are ever stored.
      </p>
      <div className="milli-card p-5 mt-6 space-y-3">
        <Row icon={Bank} title="Checking + savings" body="Detect gig payouts and recurring deposits." />
        <Row icon={ShoppingBag} title="Payment accounts" body="PayPal, Venmo Business, Stripe payouts." />
        <Row icon={ShieldCheck} title="Read-only by default" body="Transfer authorization is granted separately when you connect a Tax Vault." />
      </div>
      <NavRow onBack={onBack} onNext={onNext} nextLabel="Continue" testid="ob-connect" />
    </div>
  );
}

function VaultStep({ data, update, onBack, onNext }) {
  return (
    <div>
      <Eyebrow>// 06 · Tax Vault</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">Your tax reserve stays yours.</h2>
      <p className="text-zinc-400 text-sm mt-3 max-w-md">
        After setup you'll connect or open a user-owned savings account.
        Milli auto-pulls your reserve % from each payout. You can pause, adjust, or withdraw any time.
      </p>
      <div className="milli-card p-5 mt-6">
        <div className="text-xs text-volt font-semibold uppercase tracking-[0.18em] mb-3">Pre-select your reserve strategy</div>
        <div className="grid grid-cols-3 gap-2">
          {[["conservative", "30%", "Conservative"], ["balanced", "25%", "Balanced"], ["minimum", "20%", "Minimum"]].map(([k, p, l]) => (
            <button
              key={k}
              data-testid={`ob-strat-${k}`}
              onClick={() => update("reserve_strategy", k)}
              className={`p-3 rounded-xl border text-center transition-all ${data.reserve_strategy === k ? "border-volt bg-volt/5" : "border-hairline"}`}
            >
              <div className="font-chrome font-bold text-2xl chrome-text">{p}</div>
              <div className="text-xs text-zinc-400 mt-1">{l}</div>
            </button>
          ))}
        </div>
      </div>
      <p className="text-[10px] text-zinc-500 mt-4 leading-relaxed">
        Milli is a technology platform — not a bank. Funds are held at our partner under your name with applicable disclosures.
      </p>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-vault" />
    </div>
  );
}

function Mileage({ data, update, onBack, onNext }) {
  const opts = [
    { v: "auto", t: "Automatic tracking", b: "Background location detects trips. Best for active drivers." },
    { v: "work_only", t: "Only while working", b: "Track when you toggle on a work session." },
    { v: "manual", t: "Manual entry", b: "Add trips yourself when you remember." },
    { v: "skip", t: "Skip for now", b: "You can turn this on later in Settings." },
  ];
  return (
    <div>
      <Eyebrow>// 07 · Mileage</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">Every mile is a deduction.</h2>
      <p className="text-zinc-400 text-sm mt-3 max-w-md">IRS standard mileage rate is $0.70/mi. Pick how you want to capture trips.</p>
      <div className="space-y-2 mt-6">
        {opts.map((o) => (
          <button
            key={o.v}
            data-testid={`ob-mileage-${o.v}`}
            onClick={() => update("mileage_mode", o.v)}
            className={`milli-card p-4 w-full text-left flex items-start gap-3 transition-all ${data.mileage_mode === o.v ? "border-volt bg-volt/5" : "hover:border-volt/40"}`}
          >
            <MapPin size={20} weight="duotone" className={data.mileage_mode === o.v ? "text-volt mt-0.5" : "text-zinc-500 mt-0.5"} />
            <div className="flex-1">
              <div className="font-semibold text-sm">{o.t}</div>
              <div className="text-xs text-zinc-500 mt-0.5">{o.b}</div>
            </div>
            {data.mileage_mode === o.v && <CheckCircle size={20} weight="fill" className="text-volt" />}
          </button>
        ))}
      </div>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-mileage" />
    </div>
  );
}

function Ready({ data, onBack, onFinish }) {
  return (
    <div className="text-center">
      <motion.div
        initial={{ scale: 0.7, rotate: -8, opacity: 0 }}
        animate={{ scale: 1, rotate: 0, opacity: 1 }}
        transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
        className="mx-auto mb-6"
      >
        <MilliLogo size={88} />
      </motion.div>
      <h2 className="font-display chrome-text text-4xl">Milli is ready to work.</h2>
      <p className="text-zinc-400 mt-4 max-w-md mx-auto">Your profile is dialed in. Time to connect accounts and start auto-reserving.</p>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-8 max-w-md mx-auto">
        <Pill label="Employment" value={`${data.employment_types.length} type(s)`} />
        <Pill label="Sources" value={`${data.income_sources.length}`} />
        <Pill label="Reserve" value={data.reserve_strategy.toUpperCase()} />
        <Pill label="Mileage" value={data.mileage_mode === "skip" ? "Off" : "On"} />
      </div>
      <button onClick={onFinish} data-testid="ob-finish" className="btn-volt mt-10 px-8 py-4 uppercase tracking-wider text-sm inline-flex items-center gap-2">
        Open my dashboard <ArrowRight weight="bold" />
      </button>
      <button onClick={onBack} className="mt-3 text-xs text-zinc-500 hover:text-white">← Back</button>
    </div>
  );
}

function Eyebrow({ children }) {
  return <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">{children}</div>;
}

function Field({ label, children }) {
  return (
    <div>
      <label className="block text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</label>
      {children}
    </div>
  );
}

function Row({ icon: Icon, title, body }) {
  return (
    <div className="flex items-start gap-3">
      <Icon size={18} weight="duotone" className="text-volt mt-0.5" />
      <div>
        <div className="text-sm font-semibold">{title}</div>
        <div className="text-xs text-zinc-500">{body}</div>
      </div>
    </div>
  );
}

function Pill({ label, value }) {
  return (
    <div className="milli-card p-3">
      <div className="text-[9px] uppercase tracking-[0.18em] text-zinc-500">{label}</div>
      <div className="font-semibold text-sm mt-0.5">{value}</div>
    </div>
  );
}

function NavRow({ onBack, onNext, disabled, nextLabel = "Continue", testid }) {
  return (
    <div className="flex items-center justify-between mt-10">
      <button onClick={onBack} data-testid={`${testid}-back`} className="text-sm text-zinc-400 hover:text-white inline-flex items-center gap-1">
        <ArrowLeft weight="bold" size={14} /> Back
      </button>
      <button
        onClick={onNext}
        disabled={disabled}
        data-testid={`${testid}-next`}
        className="btn-volt px-6 py-3 uppercase tracking-wider text-xs inline-flex items-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed"
      >
        {nextLabel} <ArrowRight weight="bold" />
      </button>
    </div>
  );
}
