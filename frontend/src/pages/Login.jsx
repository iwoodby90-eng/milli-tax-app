/**
 * Login — WWDC-quality cinematic sign-in screen.
 *
 * Full-bleed dark background, radial teal glow, Milli logo + wordmark,
 * floating-label inputs, cinematic "Sign In" CTA, and vertically distributed layout.
 */
import { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ArrowRight, EnvelopeSimple, Lock, Eye, EyeSlash,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";
import SignInTransition from "@/components/SignInTransition";

const CYAN = "#00E5FF";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [transition, setTransition] = useState(null);
  const { setSession } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();

  async function onSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    try {
      const { data } = await api.post("/auth/login", { email, password });
      setSession(data.token, data.user);
      setTransition({ name: data.user?.name || "" });
    } catch (err) {
      toast.error(formatApiError(err));
      setSubmitting(false);
    }
  }

  return (
    <div
      data-testid="login-screen"
      style={{
        minHeight: "100dvh",
        background: "radial-gradient(ellipse 80% 60% at 50% 110%, rgba(0,229,255,0.18) 0%, rgba(0,0,0,0) 70%), linear-gradient(180deg, #050607 0%, #080C0F 100%)",
        display: "flex",
        flexDirection: "column",
        paddingLeft: 24,
        paddingRight: 24,
        paddingTop: "calc(var(--safe-top) + 32px)",
        paddingBottom: "calc(var(--safe-bottom) + 32px)",
      }}
    >
      {/* Logo + Wordmark */}
      <motion.div
        className="flex flex-col items-center"
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
              filter: "blur(12px)",
            }}
            animate={{ scale: [1, 1.15, 1], opacity: [0.5, 0.8, 0.5] }}
            transition={{ duration: 3.6, repeat: Infinity, ease: "easeInOut" }}
          />
          <MilliLogo size={72} className="relative" />
        </div>
        <span
          className="mt-3 font-display text-[22px] tracking-[0.24em] select-none"
          style={{
            fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            fontWeight: 700,
            background: "linear-gradient(180deg, #FFFFFF 0%, #E0E4E8 40%, #A0A8B0 70%, #6E7379 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            filter: "drop-shadow(0 0 8px rgba(0,229,255,0.3))",
          }}
        >
          MILLI
        </span>
      </motion.div>

      {/* Headline + Subtitle */}
      <motion.div
        className="mt-10 text-center"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        <h1
          style={{
            fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, sans-serif",
            fontSize: 34,
            fontWeight: 700,
            color: "#FFFFFF",
            letterSpacing: "-0.02em",
            lineHeight: 1.1,
          }}
        >
          Welcome back.
        </h1>
        <p style={{ color: "#a1a1aa", fontSize: 16, marginTop: 8 }}>
          Your money is waiting.
        </p>
      </motion.div>

      {/* Form — centered vertically with flex-1 */}
      <motion.form
        onSubmit={onSubmit}
        className="mt-10 flex flex-col gap-4 flex-1"
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

        {/* Sign In button */}
        <motion.button
          type="submit"
          disabled={submitting}
          data-testid="login-submit"
          whileTap={{ scale: 0.98 }}
          style={{
            width: "100%",
            height: 50,
            borderRadius: 16,
            background: CYAN,
            color: "#000000",
            fontWeight: 700,
            fontSize: 16,
            letterSpacing: "0.04em",
            border: "none",
            cursor: "pointer",
            boxShadow: "0 0 28px rgba(0,229,255,0.45), 0 4px 16px rgba(0,229,255,0.25)",
            marginTop: 8,
          }}
          className="disabled:opacity-60 active:opacity-90"
        >
          {submitting ? "Signing in…" : "Sign In"}
        </motion.button>

        {/* Spacer to push bottom content down */}
        <div className="flex-1" />

        {/* Create Account link */}
        <motion.div
          className="text-center text-[14px] text-zinc-400 pb-2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.55, duration: 0.6 }}
        >
          Don't have an account?{" "}
          <Link
            to="/register"
            data-testid="login-link-register"
            className="font-semibold active:opacity-70"
            style={{ color: CYAN }}
          >
            Create Account
          </Link>
        </motion.div>
      </motion.form>

      {/* Cinematic handoff */}
      <SignInTransition
        show={!!transition}
        mode="back"
        name={transition?.name}
        to={loc.state?.from || "/app"}
      />
    </div>
  );
}

/* ------------------------------------------------------------------
 * FloatingField — iOS-native input with animated floating label,
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
            paddingLeft: Icon ? 44 : 16,
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
