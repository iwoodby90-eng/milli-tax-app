import { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ArrowRight } from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const { setSession } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();

  async function onSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    try {
      const { data } = await api.post("/auth/login", { email, password });
      setSession(data.token, data.user);
      toast.success("Welcome back");
      nav(loc.state?.from || "/app");
    } catch (err) { toast.error(formatApiError(err)); }
    finally { setSubmitting(false); }
  }

  return (
    <div className="min-h-screen carbon-bg text-white flex">
      <div className="w-full lg:w-1/2 flex flex-col px-6 py-10 justify-center max-w-xl mx-auto">
        <Link to="/" className="flex items-center gap-3 mb-12" data-testid="login-logo">
          <MilliLogo size={36} />
          <span className="font-display chrome-text text-2xl tracking-[0.25em]">MILLI</span>
        </Link>
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Sign in</div>
        <h1 className="font-display chrome-text text-5xl tracking-tight mt-2">Back to the wheel.</h1>
        <p className="text-zinc-400 mt-4">Pick up where you left off.</p>
        <form onSubmit={onSubmit} className="mt-8 space-y-4">
          <Field label="Email" id="login-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" />
          <Field label="Password" id="login-password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required autoComplete="current-password" />
          <button type="submit" disabled={submitting} data-testid="login-submit" className="btn-volt w-full py-3.5 uppercase tracking-wider text-sm inline-flex items-center justify-center gap-2 disabled:opacity-60">
            {submitting ? "Signing in..." : <>Sign in <ArrowRight weight="bold" /></>}
          </button>
        </form>
        <div className="mt-6 text-sm text-zinc-400">
          No account?{" "}
          <Link to="/register" className="text-volt font-semibold" data-testid="login-link-register">Start 3-day trial</Link>
        </div>
      </div>
      <div className="hidden lg:flex lg:w-1/2 relative items-center justify-center rays-bg">
        <div className="text-center">
          <MilliLogo size={160} className="mx-auto" />
          <div className="font-display chrome-text text-5xl mt-6 tracking-[0.3em]">MILLI</div>
          <div className="text-volt mt-4 font-mono text-xs uppercase tracking-[0.3em]">// Every mile is a deduction</div>
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
