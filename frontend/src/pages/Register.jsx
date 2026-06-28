import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ArrowRight } from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

const STATES = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"];

export default function Register() {
  const [form, setForm] = useState({ name: "", email: "", password: "", state: "TX" });
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
      toast.success("Trial activated — welcome to MILLI");
      nav("/app");
    } catch (err) { toast.error(formatApiError(err)); }
    finally { setSubmitting(false); }
  }

  return (
    <div className="min-h-screen carbon-bg text-white flex">
      <div className="w-full lg:w-1/2 flex flex-col px-6 py-10 justify-center max-w-xl mx-auto">
        <Link to="/" className="flex items-center gap-3 mb-12" data-testid="register-logo">
          <MilliLogo size={36} />
          <span className="font-display chrome-text text-2xl tracking-[0.25em]">MILLI</span>
        </Link>
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// 3-day free trial</div>
        <h1 className="font-display chrome-text text-5xl tracking-tight mt-2">Lock in your<br />deductions.</h1>
        <p className="text-zinc-400 mt-4">No credit card. Cancel anytime in 3 days.</p>
        <form onSubmit={onSubmit} className="mt-8 space-y-4">
          <Field label="Your name" id="register-name" required value={form.name} onChange={(e) => setField("name", e.target.value)} autoComplete="name" />
          <Field label="Email" id="register-email" type="email" required value={form.email} onChange={(e) => setField("email", e.target.value)} autoComplete="email" />
          <Field label="Password" id="register-password" type="password" required minLength={6} value={form.password} onChange={(e) => setField("password", e.target.value)} autoComplete="new-password" />
          <div>
            <label className="block text-xs font-mono uppercase tracking-[0.2em] text-zinc-500 mb-2" htmlFor="register-state">State</label>
            <select id="register-state" data-testid="register-state" value={form.state} onChange={(e) => setField("state", e.target.value)}
              className="w-full bg-obsidian/60 border border-hairline rounded-xl px-4 py-3 text-white font-mono focus:outline-none focus:border-volt">
              {STATES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
            <p className="text-xs text-zinc-500 mt-1">Used to estimate your state self-employment tax.</p>
          </div>
          <button type="submit" disabled={submitting} data-testid="register-submit" className="btn-volt w-full py-3.5 uppercase tracking-wider text-sm inline-flex items-center justify-center gap-2 disabled:opacity-60">
            {submitting ? "Creating..." : <>Start trial <ArrowRight weight="bold" /></>}
          </button>
        </form>
        <div className="mt-6 text-sm text-zinc-400">
          Already have an account?{" "}
          <Link to="/login" className="text-volt font-semibold" data-testid="register-link-login">Sign in</Link>
        </div>
      </div>
      <div className="hidden lg:flex lg:w-1/2 relative items-center justify-center rays-bg">
        <div className="text-center">
          <MilliLogo size={160} className="mx-auto" />
          <div className="font-display chrome-text text-5xl mt-6 tracking-[0.3em]">MILLI</div>
          <div className="text-volt mt-4 font-mono text-xs uppercase tracking-[0.3em]">// You drive. We chase deductions</div>
        </div>
      </div>
    </div>
  );
}

function Field({ label, id, ...props }) {
  return (
    <div>
      <label htmlFor={id} className="block text-xs font-mono uppercase tracking-[0.2em] text-zinc-500 mb-2">{label}</label>
      <input id={id} data-testid={id} {...props} className="w-full bg-obsidian/60 border border-hairline rounded-xl px-4 py-3 text-white font-mono focus:outline-none focus:border-volt focus:ring-1 focus:ring-volt" />
    </div>
  );
}
