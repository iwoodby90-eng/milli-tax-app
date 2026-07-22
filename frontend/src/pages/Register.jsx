/**
 * Register — premium iOS-native sign-up screen.
 *
 * Single-column phone-first layout. Reads the previously-selected tier
 * from `localStorage.milli_selected_plan` (set by WelcomePaywall) and
 * displays a "Starting: Milli <Tier> · Free until <date>" banner, then
 * posts the account with the pending plan to the backend.
 */
import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ArrowRight, User, EnvelopeSimple, Lock, MapPin, Eye, EyeSlash, Sparkle, Star,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

const CYAN = "#00E5FF";

const STATES = [
  "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA",
  "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM",
  "NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA",
  "WV","WI","WY",
];

export default function Register() {
  const [form, setForm] = useState({ name: "", email: "", password: "", state: "TX" });
  const [showPw, setShowPw] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const { setSession } = useAuth();
  const nav = useNavigate();
  const setField = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  // Pull the tier the user picked on the WelcomePaywall
  const [plan, setPlan] = useState(null);
  useEffect(() => {
    try {
      const raw = localStorage.getItem("milli_selected_plan");
      if (raw) setPlan(JSON.parse(raw));
    } catch (_) { /* noop */ }
  }, []);
  const chargeDateLabel = useMemo(() => {
    if (!plan?.first_charge_at) return null;
    return new Date(plan.first_charge_at).toLocaleDateString("en-US", { month: "long", day: "numeric" });
  }, [plan]);

  async function onSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    try {
      const { data } = await api.post("/auth/register", {
        ...form,
        pending_plan: plan?.plan || null,
        pending_product_id: plan?.product_id || null,
        trial_starts_at: plan?.trial_started_at || new Date().toISOString(),
        first_charge_at: plan?.first_charge_at || null,
      });
      setSession(data.token, data.user);
      toast.success("Trial activated — welcome to Milli");
      nav("/app");
    } catch (err) {
      toast.error(formatApiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      className="relative w-full min-h-full overflow-y-auto native-scroll text-white"
      data-testid="register-screen"
      style={{
        paddingTop:    "calc(var(--safe-top) + 20px)",
        paddingBottom: "calc(var(--safe-bottom) + 40px)",
        backgroundColor: "#050607",
        backgroundImage:
          "radial-gradient(ellipse 70% 40% at 50% -5%, rgba(0,229,255,0.20), transparent 65%)," +
          "radial-gradient(ellipse 40% 30% at 10% 80%, rgba(0,229,255,0.08), transparent 70%)," +
          "radial-gradient(ellipse 40% 30% at 90% 60%, rgba(0,229,255,0.08), transparent 70%)," +
          "repeating-linear-gradient(45deg, rgba(255,255,255,0.014) 0 2px, transparent 2px 6px)," +
          "repeating-linear-gradient(-45deg, rgba(255,255,255,0.010) 0 2px, transparent 2px 6px)",
      }}
    >
      <div className="absolute top-3 left-3 w-5 h-5 border-l border-t" style={{ borderColor: "rgba(0,229,255,0.4)" }} />
      <div className="absolute bottom-3 right-3 w-5 h-5 border-r border-b" style={{ borderColor: "rgba(0,229,255,0.4)" }} />

      {/* Hero */}
      <motion.div
        className="flex flex-col items-center px-6 pt-4"
        initial={{ opacity: 0, y: -16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
      >
        <div className="relative">
          <motion.div
            aria-hidden="true"
            className="absolute inset-0 rounded-full"
            style={{ background: "radial-gradient(circle, rgba(0,229,255,0.35), transparent 70%)", filter: "blur(10px)" }}
            animate={{ scale: [1, 1.15, 1], opacity: [0.5, 0.8, 0.5] }}
            transition={{ duration: 3.6, repeat: Infinity, ease: "easeInOut" }}
          />
          <MilliLogo size={72} className="relative" />
        </div>
        <div className="chrome-text font-display text-[24px] tracking-[0.24em] mt-3">MILLI</div>
      </motion.div>

      {/* Title */}
      <motion.div
        className="px-6 mt-5 text-center"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[9px] uppercase tracking-[0.28em] font-semibold mb-3"
             style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.32)", color: CYAN }}>
          <Sparkle size={10} weight="fill" /> 3-day free trial
        </div>
        <h1 className="font-display font-black text-[30px] leading-[1.05] tracking-tight">
          <span className="chrome-text">Lock in your</span>{" "}
          <span style={{ color: CYAN, textShadow: "0 0 22px rgba(0,229,255,0.4)" }}>deductions.</span>
        </h1>
        <p className="text-zinc-400 mt-2 text-[13.5px] max-w-[300px] mx-auto">
          No card charged today. Cancel anytime before day 3.
        </p>
      </motion.div>

      {/* Selected plan pill */}
      {plan && (
        <motion.div
          className="mx-5 mt-5 rounded-2xl px-4 py-3 flex items-center gap-3"
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          style={{
            background: "linear-gradient(180deg, rgba(0,229,255,0.09), rgba(0,229,255,0.02))",
            border: "1px solid rgba(0,229,255,0.4)",
            boxShadow: "0 0 20px rgba(0,229,255,0.15), inset 0 1px 0 rgba(255,255,255,0.05)",
          }}
          data-testid="register-plan-banner"
        >
          <Star size={16} weight="fill" style={{ color: CYAN }} />
          <div className="flex-1 min-w-0">
            <div className="text-[10px] uppercase tracking-[0.22em] text-white/60">Starting</div>
            <div className="text-white text-[14px] font-semibold leading-tight">
              Milli {plan.plan?.[0]?.toUpperCase()}{plan.plan?.slice(1)} · {plan.price_display}/mo
            </div>
            {chargeDateLabel && (
              <div className="text-[11px] text-white/60 mt-0.5">
                Free until <span className="text-white font-medium">{chargeDateLabel}</span>
              </div>
            )}
          </div>
          <Link
            to="/"
            data-testid="register-change-plan"
            className="text-[11px] uppercase tracking-[0.18em] font-semibold active:opacity-60"
            style={{ color: CYAN }}
          >
            Change
          </Link>
        </motion.div>
      )}

      {/* Form */}
      <motion.form
        onSubmit={onSubmit}
        className="mt-5 px-5 flex flex-col gap-4"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        <FloatingField
          id="register-name" label="Full name" icon={User}
          value={form.name} onChange={(e) => setField("name", e.target.value)}
          autoComplete="name" required
        />
        <FloatingField
          id="register-email" label="Email address" icon={EnvelopeSimple} type="email"
          value={form.email} onChange={(e) => setField("email", e.target.value)}
          autoComplete="email" required
        />
        <FloatingField
          id="register-password" label="Create a password" icon={Lock}
          type={showPw ? "text" : "password"}
          value={form.password} onChange={(e) => setField("password", e.target.value)}
          autoComplete="new-password" required minLength={8}
          trailing={
            <button type="button" onClick={() => setShowPw((v) => !v)}
              className="text-zinc-500 active:opacity-60"
              data-testid="register-toggle-pw"
              aria-label={showPw ? "Hide password" : "Show password"}>
              {showPw ? <EyeSlash size={18} /> : <Eye size={18} />}
            </button>
          }
        />
        <FloatingField
          id="register-state" label="Filing state" icon={MapPin}
          as="select"
          value={form.state} onChange={(e) => setField("state", e.target.value)}
        >
          {STATES.map((s) => <option key={s} value={s} className="bg-[#0A0C0F] text-white">{s}</option>)}
        </FloatingField>

        <motion.button
          type="submit"
          disabled={submitting}
          data-testid="register-submit"
          whileTap={{ scale: 0.985 }}
          className="mt-2 relative w-full py-4 rounded-full uppercase tracking-[0.24em] text-[13px] font-bold inline-flex items-center justify-center gap-3 disabled:opacity-60 overflow-hidden"
          style={{
            background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
            color: "#001217",
            boxShadow: "0 0 26px rgba(0,229,255,0.55), 0 0 60px rgba(0,229,255,0.22)",
          }}
        >
          <motion.span
            className="absolute inset-0 pointer-events-none"
            style={{ background: "linear-gradient(120deg, transparent 30%, rgba(255,255,255,0.4) 50%, transparent 70%)" }}
            initial={{ x: "-120%" }}
            animate={{ x: "120%" }}
            transition={{ duration: 2.6, repeat: Infinity, ease: "linear", repeatDelay: 1 }}
          />
          <span className="relative flex items-center gap-2">
            {submitting ? "Creating account…" : (<>Start 3-day trial <ArrowRight size={14} weight="bold" /></>)}
          </span>
        </motion.button>

        <p className="text-[10.5px] text-white/40 text-center leading-relaxed px-2 mt-1">
          By continuing you agree to the <Link to="/terms" className="text-white/70 active:opacity-70">Terms</Link>{" "}
          and <Link to="/privacy" className="text-white/70 active:opacity-70">Privacy Policy</Link>.
          {plan && chargeDateLabel && (
            <> Your card is charged {plan.price_display} on {chargeDateLabel} unless you cancel.</>
          )}
        </p>
      </motion.form>

      <motion.div
        className="mt-6 px-5 text-center text-[13px] text-zinc-400"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.55, duration: 0.6 }}
      >
        Already have an account?{" "}
        <Link to="/login" data-testid="register-link-login"
          className="font-semibold inline-flex items-center gap-1 active:opacity-70"
          style={{ color: CYAN, textShadow: "0 0 12px rgba(0,229,255,0.35)" }}>
          Sign in <ArrowRight size={11} weight="bold" />
        </Link>
      </motion.div>
    </div>
  );
}

/* ------------------------------------------------------------------
 * FloatingField — shared iOS-native input with animated floating label.
 * Supports `<input>` and `<select>` via `as="select"`.
 * ------------------------------------------------------------------ */
function FloatingField({ id, label, icon: Icon, trailing, value, onChange, as = "input", children, ...props }) {
  const [focused, setFocused] = useState(false);
  const filled = String(value ?? "").length > 0;
  const active = focused || filled;

  const commonInputStyle = {
    paddingLeft:  Icon ? 44 : 16,
    paddingRight: trailing ? 44 : 16,
    paddingTop: active ? 22 : 15,
    paddingBottom: active ? 10 : 15,
  };

  return (
    <div className="relative">
      <div
        className="relative rounded-2xl transition-all"
        style={{
          background: "linear-gradient(180deg, rgba(255,255,255,0.03) 0%, rgba(255,255,255,0.01) 100%)",
          border: `1px solid ${focused ? "rgba(0,229,255,0.75)" : "rgba(192,192,192,0.16)"}`,
          boxShadow: focused
            ? "0 0 22px rgba(0,229,255,0.22), inset 0 1px 0 rgba(255,255,255,0.05)"
            : "inset 0 1px 0 rgba(255,255,255,0.04)",
        }}
      >
        {Icon && (
          <Icon
            size={17}
            weight="regular"
            className="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none transition-colors"
            style={{ color: focused ? CYAN : "rgba(255,255,255,0.4)" }}
          />
        )}
        <label
          htmlFor={id}
          className="absolute pointer-events-none transition-all"
          style={{
            left: Icon ? 44 : 16,
            top: active ? 8 : "50%",
            transform: active ? "translateY(0)" : "translateY(-50%)",
            fontSize: active ? 10 : 14,
            letterSpacing: active ? "0.2em" : "0.02em",
            textTransform: active ? "uppercase" : "none",
            color: focused ? CYAN : "rgba(255,255,255,0.42)",
            fontWeight: active ? 600 : 400,
          }}
        >
          {label}
        </label>
        {as === "select" ? (
          <select
            id={id}
            data-testid={id}
            value={value}
            onChange={onChange}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            {...props}
            className="w-full bg-transparent outline-none text-white text-[15px] font-medium appearance-none"
            style={commonInputStyle}
          >
            {children}
          </select>
        ) : (
          <input
            id={id}
            data-testid={id}
            value={value}
            onChange={onChange}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            {...props}
            className="w-full bg-transparent outline-none text-white text-[15px] font-medium"
            style={commonInputStyle}
          />
        )}
        {trailing && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">{trailing}</div>
        )}
      </div>
    </div>
  );
}
