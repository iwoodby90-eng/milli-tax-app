/**
 * Login — premium iOS-native sign-in screen.
 *
 * Single-column phone-first layout: cinematic chrome-M hero at the top,
 * floating-label inputs with cyan focus glow, big cyan CTA, and compact
 * trust footer. Wrapped in framer-motion for a Wallet-app-caliber entrance.
 */
import { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ArrowRight, EnvelopeSimple, Lock, Eye, EyeSlash,
  ShieldCheck, LockKey, Sparkle,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

const CYAN = "#00E5FF";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
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
    } catch (err) {
      toast.error(formatApiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      className="relative w-full min-h-full overflow-y-auto native-scroll text-white"
      data-testid="login-screen"
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
      {/* corner brackets — brand */}
      <div className="absolute top-3 left-3 w-5 h-5 border-l border-t"
           style={{ borderColor: "rgba(0,229,255,0.4)" }} />
      <div className="absolute bottom-3 right-3 w-5 h-5 border-r border-b"
           style={{ borderColor: "rgba(0,229,255,0.4)" }} />

      {/* Hero — chrome M with pulsing halo */}
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
            style={{
              background: "radial-gradient(circle, rgba(0,229,255,0.35), transparent 70%)",
              filter: "blur(10px)",
            }}
            animate={{ scale: [1, 1.15, 1], opacity: [0.5, 0.8, 0.5] }}
            transition={{ duration: 3.6, repeat: Infinity, ease: "easeInOut" }}
          />
          <MilliLogo size={80} className="relative" />
        </div>
        <div className="chrome-text font-display text-[26px] tracking-[0.24em] mt-3">MILLI</div>
      </motion.div>

      {/* Title */}
      <motion.div
        className="px-6 mt-6 text-center"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[9px] uppercase tracking-[0.28em] font-semibold mb-3"
             style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.32)", color: CYAN }}>
          <Sparkle size={10} weight="fill" /> Welcome back
        </div>
        <h1 className="font-display font-black text-[34px] leading-[1.05] tracking-tight">
          <span className="chrome-text">Back to</span>{" "}
          <span style={{ color: CYAN, textShadow: "0 0 22px rgba(0,229,255,0.4)" }}>Autopilot.</span>
        </h1>
        <p className="text-zinc-400 mt-2 text-[13.5px] max-w-[300px] mx-auto">
          Pick up where you left off. Your money kept moving.
        </p>
      </motion.div>

      {/* Form */}
      <motion.form
        onSubmit={onSubmit}
        className="mt-8 px-5 flex flex-col gap-4"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.35, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        <FloatingField
          id="login-email"
          label="Email address"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          icon={EnvelopeSimple}
          autoComplete="email"
          required
        />

        <FloatingField
          id="login-password"
          label="Password"
          type={showPw ? "text" : "password"}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          icon={Lock}
          autoComplete="current-password"
          required
          trailing={
            <button
              type="button"
              onClick={() => setShowPw((v) => !v)}
              className="text-zinc-500 active:opacity-60"
              data-testid="login-toggle-pw"
              aria-label={showPw ? "Hide password" : "Show password"}
            >
              {showPw ? <EyeSlash size={18} /> : <Eye size={18} />}
            </button>
          }
        />

        <div className="flex justify-end -mt-1">
          <Link
            to="/forgot"
            className="text-[12px] text-white/55 active:text-white"
            data-testid="login-forgot"
          >
            Forgot password?
          </Link>
        </div>

        <motion.button
          type="submit"
          disabled={submitting}
          data-testid="login-submit"
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
            style={{
              background:
                "linear-gradient(120deg, transparent 30%, rgba(255,255,255,0.4) 50%, transparent 70%)",
            }}
            initial={{ x: "-120%" }}
            animate={{ x: "120%" }}
            transition={{ duration: 2.6, repeat: Infinity, ease: "linear", repeatDelay: 1 }}
          />
          <span className="relative flex items-center gap-2">
            {submitting ? "Signing in…" : (<>Sign in <ArrowRight size={14} weight="bold" /></>)}
          </span>
        </motion.button>
      </motion.form>

      {/* Register CTA */}
      <motion.div
        className="mt-6 px-5 text-center text-[13px] text-zinc-400"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.55, duration: 0.6 }}
      >
        New to Milli?{" "}
        <Link
          to="/register"
          data-testid="login-link-register"
          className="font-semibold inline-flex items-center gap-1 active:opacity-70"
          style={{ color: CYAN, textShadow: "0 0 12px rgba(0,229,255,0.35)" }}
        >
          Start 3-day trial <ArrowRight size={11} weight="bold" />
        </Link>
      </motion.div>

      {/* Trust footer */}
      <motion.div
        className="mt-10 px-5 flex items-center justify-center gap-4 text-[10px] uppercase tracking-[0.22em] text-white/45"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.7, duration: 0.7 }}
      >
        <span className="inline-flex items-center gap-1.5"><LockKey size={11} weight="fill" style={{ color: CYAN }} /> 256-bit</span>
        <span className="w-px h-3 bg-white/15" />
        <span className="inline-flex items-center gap-1.5"><ShieldCheck size={11} weight="fill" style={{ color: CYAN }} /> PCI</span>
        <span className="w-px h-3 bg-white/15" />
        <span>SOC 2</span>
      </motion.div>
    </div>
  );
}

/* ------------------------------------------------------------------
 * FloatingField — iOS-native input with an animated floating label,
 * cyan focus glow, and glassmorphic surface.
 * ------------------------------------------------------------------ */
function FloatingField({ id, label, icon: Icon, trailing, value, onChange, ...props }) {
  const [focused, setFocused] = useState(false);
  const filled = String(value ?? "").length > 0;
  const active = focused || filled;

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
        <input
          id={id}
          data-testid={id}
          value={value}
          onChange={onChange}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          {...props}
          className="w-full bg-transparent outline-none text-white text-[15px] font-medium"
          style={{
            paddingLeft:  Icon ? 44 : 16,
            paddingRight: trailing ? 44 : 16,
            paddingTop: active ? 22 : 15,
            paddingBottom: active ? 10 : 15,
          }}
        />
        {trailing && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">{trailing}</div>
        )}
      </div>
    </div>
  );
}
