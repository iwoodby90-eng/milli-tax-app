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
    tax_goal: 20000,
    vehicle: { year: "", make: "", model: "", trim: "", mpg: "" },
    location_permission: "not_asked",
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
        tax_goal: parseFloat(data.tax_goal || 20000),
        mileage_mode: data.mileage_mode,
      });
      // Save vehicle (if provided) — enables per-gallon fuel math in Milli Cents.
      if (data.vehicle?.make && data.vehicle?.model) {
        try {
          await api.post("/vehicles", {
            year: parseInt(data.vehicle.year || new Date().getFullYear()),
            make: data.vehicle.make,
            model: data.vehicle.model,
            trim: data.vehicle.trim || "",
            mpg: parseFloat(data.vehicle.mpg || 25),
            default: true,
          });
        } catch (e) { console.debug("[Onboarding] step 1 non-fatal:", e); }
      }
      // Request iOS Always-On location if the user opted in
      if (data.location_permission === "granted") {
        try {
          const { Capacitor } = await import("@capacitor/core");
          if (Capacitor.isNativePlatform()) {
            const mod = await import("@capacitor/geolocation");
            await mod.Geolocation.requestPermissions({ permissions: ["location"] });
          }
        } catch (e) { console.debug("[Onboarding] native plugin missing on web:", e); }
      }
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
    <VaultGoalStep key="6" data={data} update={update} onBack={() => setStep(5)} onNext={() => setStep(7)} />,
    <VehicleStep key="7" data={data} update={update} onBack={() => setStep(6)} onNext={() => setStep(8)} />,
    <LocationStep key="8" data={data} update={update} onBack={() => setStep(7)} onNext={() => setStep(9)} />,
    <Mileage key="9" data={data} update={update} onBack={() => setStep(8)} onNext={() => setStep(10)} />,
    <Ready key="10" data={data} onBack={() => setStep(9)} onFinish={finish} />,
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
            <div key={`step-${i}`} className={`h-1 rounded-full transition-all ${i <= step ? "bg-volt w-6" : "bg-zinc-700 w-3"}`} />
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

function VaultGoalStep({ data, update, onBack, onNext }) {
  const goal = Number(data.tax_goal || 0);
  const [custom, setCustom] = useState(String(goal || ""));
  const presets = [10000, 15000, 20000, 25000, 30000, 40000];
  const monthly = Math.round(goal / 12);
  const perPayout = Math.round(goal / 260); // ~5 payouts/wk

  return (
    <div>
      <Eyebrow>// 07 · Vault Goal</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">
        How much do you want to protect this year?
      </h2>
      <p className="text-zinc-400 text-sm mt-3 max-w-md">
        We&apos;ll show your progress in the Milli Tax Vault so you always know how far ahead you are.
        You can change this anytime.
      </p>

      {/* Preset chips */}
      <div className="grid grid-cols-3 gap-2 mt-6">
        {presets.map((p) => {
          const active = goal === p;
          return (
            <button
              key={p}
              data-testid={`ob-goal-${p}`}
              onClick={() => { update("tax_goal", p); setCustom(String(p)); }}
              className="rounded-2xl p-3.5 text-center transition-all"
              style={{
                background: active ? "rgba(0,229,255,0.10)" : "rgba(10,14,18,0.6)",
                border: active ? "1px solid rgba(0,229,255,0.7)" : "1px solid rgba(255,255,255,0.08)",
                boxShadow: active ? "0 0 16px rgba(0,229,255,0.35)" : "none",
              }}
            >
              <div className={`font-chrome font-bold text-[22px] leading-none tabular-nums ${active ? "text-volt" : "chrome-text"}`}
                   style={active ? { textShadow: "0 0 8px rgba(0,229,255,0.55)" } : {}}>
                ${(p/1000).toFixed(0)}K
              </div>
              <div className="text-zinc-500 text-[10.5px] mt-1">
                {p === 20000 ? "Most popular" : `$${Math.round(p/12).toLocaleString()}/mo`}
              </div>
            </button>
          );
        })}
      </div>

      {/* Custom input */}
      <div className="milli-card p-4 mt-4 rounded-2xl">
        <label className="text-zinc-400 text-[11px] uppercase tracking-widest">Custom amount</label>
        <div className="flex items-center gap-2 mt-1.5">
          <span className="chrome-text font-chrome font-bold text-[26px]">$</span>
          <input
            data-testid="ob-goal-custom"
            type="number" min="1000" step="1000"
            value={custom}
            onChange={(e) => { setCustom(e.target.value); update("tax_goal", parseFloat(e.target.value || 0)); }}
            placeholder="20000"
            className="flex-1 bg-transparent chrome-text font-chrome font-bold text-[26px] tabular-nums focus:outline-none"
          />
        </div>
        {goal > 0 && (
          <div className="grid grid-cols-2 gap-3 mt-4 pt-4 border-t border-white/10">
            <div>
              <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest">Monthly pace</div>
              <div className="text-white font-chrome font-bold text-[17px] tabular-nums">
                ${monthly.toLocaleString("en-US")}
              </div>
            </div>
            <div>
              <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest">Per payout</div>
              <div className="text-volt font-chrome font-bold text-[17px] tabular-nums"
                   style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
                ~${perPayout.toLocaleString("en-US")}
              </div>
            </div>
          </div>
        )}
      </div>

      <p className="text-[11px] text-zinc-500 mt-4 leading-relaxed">
        Milli Autopilot™ will automatically route a % of every payout into your Tax Vault so you hit this goal by December 31.
      </p>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-vault-goal" disabled={!goal} />
    </div>
  );
}

function VehicleStep({ data, update, onBack, onNext }) {
  const v = data.vehicle || {};
  const setV = (k, val) => update("vehicle", { ...v, [k]: val });
  const CURRENT_YEAR = new Date().getFullYear();
  const YEARS = Array.from({ length: 30 }, (_, i) => CURRENT_YEAR - i);
  const MAKES = ["Toyota", "Honda", "Tesla", "Ford", "Chevrolet", "Nissan", "Hyundai", "Kia", "Subaru", "Mazda", "Jeep", "GMC", "Ram", "BMW", "Mercedes-Benz", "Audi", "Volkswagen", "Lexus", "Acura", "Volvo", "Other"];
  const canContinue = v.make && v.model && v.year;

  return (
    <div>
      <Eyebrow>// 08 · Your Vehicle</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">What are you driving?</h2>
      <p className="text-zinc-400 text-sm mt-3 max-w-md">
        Milli Cents uses your car&apos;s MPG to calculate real gas cost per trip — so every offer&apos;s NET profit is accurate.
      </p>
      <div className="grid grid-cols-2 gap-3 mt-6">
        <VField label="Year">
          <select
            data-testid="ob-vehicle-year"
            value={v.year || ""}
            onChange={(e) => setV("year", e.target.value)}
            className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt"
          >
            <option value="">Select</option>
            {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </VField>
        <VField label="Make">
          <select
            data-testid="ob-vehicle-make"
            value={v.make || ""}
            onChange={(e) => setV("make", e.target.value)}
            className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt"
          >
            <option value="">Select</option>
            {MAKES.map((m) => <option key={m} value={m}>{m}</option>)}
          </select>
        </VField>
        <VField label="Model">
          <input
            data-testid="ob-vehicle-model"
            type="text" placeholder="Camry, Model 3, F-150…"
            value={v.model || ""}
            onChange={(e) => setV("model", e.target.value)}
            className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt"
          />
        </VField>
        <VField label="Combined MPG">
          <input
            data-testid="ob-vehicle-mpg"
            type="number" step="0.1" placeholder="25"
            value={v.mpg || ""}
            onChange={(e) => setV("mpg", e.target.value)}
            className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt tabular-nums"
          />
        </VField>
      </div>
      <p className="text-[11px] text-zinc-500 mt-4">
        Not sure about MPG? Check fueleconomy.gov — Milli will refine it as we see your real fill-ups.
      </p>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-vehicle" disabled={!canContinue} />
    </div>
  );
}

function LocationStep({ data, update, onBack, onNext }) {
  const status = data.location_permission || "not_asked";
  async function requestPerm() {
    try {
      const { Capacitor } = await import("@capacitor/core");
      if (Capacitor.isNativePlatform()) {
        const mod = await import("@capacitor/geolocation");
        const res = await mod.Geolocation.requestPermissions({ permissions: ["location"] });
        update("location_permission", (res?.location === "granted") ? "granted" : "denied");
      } else {
        // Web fallback — try navigator.geolocation
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            () => update("location_permission", "granted"),
            () => update("location_permission", "denied"),
            { timeout: 8000 }
          );
        } else {
          update("location_permission", "granted"); // no-op on preview
        }
      }
    } catch (_) {
      update("location_permission", "granted"); // preview no-op
    }
  }

  return (
    <div>
      <Eyebrow>// 09 · Location Services</Eyebrow>
      <h2 className="font-display chrome-text text-3xl mt-2">Turn on auto-mileage.</h2>
      <p className="text-zinc-400 text-sm mt-3 max-w-md">
        Milli needs <span className="text-volt font-semibold">Always</span> location to detect
        when you start driving and log the trip automatically. Nothing shows up on your battery graph.
      </p>

      <div className="milli-card rounded-2xl p-5 mt-6" data-testid="ob-location-card">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl flex items-center justify-center flex-shrink-0"
               style={{
                 background: "rgba(0,229,255,0.08)",
                 border: "1px solid rgba(0,229,255,0.5)",
                 boxShadow: "0 0 12px rgba(0,229,255,0.35)",
               }}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
              <circle cx="10" cy="8" r="3" stroke="#00E5FF" strokeWidth="1.6" />
              <path d="M10 1 C6 1 3 4 3 8 C3 13 10 19 10 19 C10 19 17 13 17 8 C17 4 14 1 10 1 Z"
                    stroke="#00E5FF" strokeWidth="1.6" fill="none" />
            </svg>
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-white font-semibold text-[14.5px]">Always-On Location</div>
            <div className="text-zinc-500 text-[12px] mt-0.5">Background trip detection</div>
          </div>
          {status === "granted" && (
            <span className="text-volt text-[10.5px] font-bold px-2 py-1 rounded-full"
                  style={{ background: "rgba(0,229,255,0.10)", border: "1px solid rgba(0,229,255,0.5)" }}>
              GRANTED
            </span>
          )}
          {status === "denied" && (
            <span className="text-rose-400 text-[10.5px] font-bold px-2 py-1 rounded-full"
                  style={{ background: "rgba(255,92,119,0.10)", border: "1px solid rgba(255,92,119,0.5)" }}>
              DENIED
            </span>
          )}
        </div>
        <button
          onClick={requestPerm}
          data-testid="ob-location-enable"
          className="w-full mt-4 rounded-xl py-3 font-bold text-[13px] text-obsidian active:brightness-95"
          style={{
            background: "linear-gradient(180deg, #00E5FF 0%, #00B4D0 100%)",
            boxShadow: "0 0 20px rgba(0,229,255,0.4), inset 0 1px 0 rgba(255,255,255,0.5)",
          }}
        >
          {status === "granted" ? "Permissions Granted ✓"
           : status === "denied" ? "Retry Location Access"
           : "Enable Location Services"}
        </button>
      </div>

      <p className="text-[11px] text-zinc-500 mt-4">
        Milli only records mileage during detected trips. Location data stays on your device except for encrypted trip summaries.
      </p>
      <NavRow onBack={onBack} onNext={onNext} testid="ob-location" />
    </div>
  );
}

function VField({ label, children }) {
  return (
    <div>
      <label className="block text-zinc-400 text-[11px] mb-1.5 uppercase tracking-widest">{label}</label>
      {children}
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
  const NUM = "07";
  return (
    <div>
      <Eyebrow>// 08 · Mileage</Eyebrow>
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
