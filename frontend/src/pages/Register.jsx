import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ArrowRight, User, EnvelopeSimple, Lock, MapPin, Eye, EyeSlash,
  Shield, CheckCircle, CurrencyDollar,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import AuthHero from "@/components/AuthHero";

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

  async function onSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    try {
      const { data } = await api.post("/auth/register", form);
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
    <div className="min-h-screen carbon-bg text-white flex flex-col lg:flex-row">
      {/* ---------- LEFT: Form pane ---------- */}
      <div className="w-full lg:w-1/2 flex flex-col px-6 py-10 lg:px-16 lg:py-14 max-w-2xl mx-auto lg:mx-0">
        <Link
          to="/"
          className="flex items-center gap-3 mb-14"
          data-testid="register-logo"
        >
          <MilliLogo size={38} withRoad />
          <span className="font-display chrome-text text-2xl lg:text-[26px] tracking-[0.24em]">
            MILLI
          </span>
        </Link>

        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.32em]">
          // 3-day free trial
        </div>
        <h1 className="font-display font-black text-5xl lg:text-6xl tracking-tight mt-3 leading-[1.05]">
          <span className="chrome-text">Lock in your</span>
          <br />
          <span className="text-volt">deductions.</span>
        </h1>
        <p className="text-zinc-400 mt-4 text-[15px]">
          No credit card. Cancel anytime in 3 days.
        </p>

        <form onSubmit={onSubmit} className="mt-10 space-y-5">
          <IconField
            label="Your name"
            id="register-name"
            icon={User}
            required
            value={form.name}
            placeholder="Full name"
            autoComplete="name"
            onChange={(e) => setField("name", e.target.value)}
          />
          <IconField
            label="Email"
            id="register-email"
            icon={EnvelopeSimple}
            type="email"
            required
            value={form.email}
            placeholder="Email address"
            autoComplete="email"
            onChange={(e) => setField("email", e.target.value)}
          />
          <IconField
            label="Password"
            id="register-password"
            icon={Lock}
            type={showPw ? "text" : "password"}
            required
            minLength={6}
            value={form.password}
            placeholder="Create a password"
            autoComplete="new-password"
            onChange={(e) => setField("password", e.target.value)}
            trailing={
              <button
                type="button"
                onClick={() => setShowPw((v) => !v)}
                className="text-zinc-500 hover:text-white transition-colors"
                data-testid="register-toggle-pw"
                aria-label={showPw ? "Hide password" : "Show password"}
              >
                {showPw ? <EyeSlash size={18} /> : <Eye size={18} />}
              </button>
            }
          />

          {/* State — icon-prefixed native select */}
          <div>
            <label
              htmlFor="register-state"
              className="block text-[11px] font-mono uppercase tracking-[0.24em] text-zinc-500 mb-2"
            >
              State
            </label>
            <div className="relative">
              <MapPin
                size={18}
                weight="regular"
                className="absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none"
              />
              <select
                id="register-state"
                data-testid="register-state"
                value={form.state}
                onChange={(e) => setField("state", e.target.value)}
                className="w-full appearance-none bg-charcoal/60 border border-hairline rounded-2xl pl-11 pr-10 py-3.5 text-white font-medium focus:outline-none focus:border-volt focus:ring-1 focus:ring-volt/60 transition-colors"
              >
                {STATES.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>
            <p className="text-[11px] text-zinc-500 mt-1.5">
              Used to estimate your state self-employment tax.
            </p>
          </div>

          <button
            type="submit"
            disabled={submitting}
            data-testid="register-submit"
            className="btn-volt w-full py-4 rounded-2xl uppercase tracking-[0.24em] text-sm font-bold inline-flex items-center justify-center gap-3 disabled:opacity-60"
          >
            {submitting ? "Creating..." : (
              <>
                Start Trial <ArrowRight size={16} weight="bold" />
              </>
            )}
          </button>
        </form>

        <div className="mt-6 text-sm text-zinc-400">
          Already have an account?{" "}
          <Link
            to="/login"
            className="text-volt font-semibold inline-flex items-center gap-1"
            data-testid="register-link-login"
          >
            Sign in <ArrowRight size={12} weight="bold" />
          </Link>
        </div>

        {/* Trust row */}
        <div className="mt-auto pt-12 grid grid-cols-3 gap-3">
          <TrustBadge icon={Shield} title="Bank-level security" sub="256-bit encryption" />
          <TrustBadge icon={CheckCircle} title="PCI compliant" sub="Your data is protected" />
          <TrustBadge icon={CurrencyDollar} title="No commitment" sub="Cancel anytime" />
        </div>
      </div>

      {/* ---------- RIGHT: Hero pane ---------- */}
      <div
        className="hidden lg:block lg:w-1/2 min-h-screen relative"
        data-testid="register-hero-panel"
      >
        <AuthHero />
      </div>

      {/* On mobile, stack a compact hero at the top */}
      <div className="lg:hidden h-[52vh] w-full order-first" data-testid="register-hero-mobile">
        <AuthHero />
      </div>
    </div>
  );
}

/* ---------- Field with icon prefix ---------- */
function IconField({ label, id, icon: Icon, trailing, ...props }) {
  return (
    <div>
      <label
        htmlFor={id}
        className="block text-[11px] font-mono uppercase tracking-[0.24em] text-zinc-500 mb-2"
      >
        {label}
      </label>
      <div className="relative">
        <Icon
          size={18}
          weight="regular"
          className="absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none"
        />
        <input
          id={id}
          data-testid={id}
          {...props}
          className="w-full bg-charcoal/60 border border-hairline rounded-2xl pl-11 pr-10 py-3.5 text-white placeholder:text-zinc-600 font-medium focus:outline-none focus:border-volt focus:ring-1 focus:ring-volt/60 transition-colors"
        />
        {trailing && (
          <div className="absolute right-3.5 top-1/2 -translate-y-1/2">
            {trailing}
          </div>
        )}
      </div>
    </div>
  );
}

function TrustBadge({ icon: Icon, title, sub }) {
  return (
    <div className="flex items-start gap-2.5">
      <div className="w-8 h-8 rounded-lg bg-volt/8 border border-volt/20 flex items-center justify-center shrink-0">
        <Icon size={14} weight="fill" className="text-volt" />
      </div>
      <div className="min-w-0">
        <div className="text-[11px] font-bold text-white leading-tight">{title}</div>
        <div className="text-[10px] text-zinc-500 leading-tight mt-0.5">{sub}</div>
      </div>
    </div>
  );
}
