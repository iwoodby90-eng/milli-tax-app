import { useAuth } from "@/context/AuthContext";
import { Lock, Crown } from "@phosphor-icons/react";
import { Link } from "react-router-dom";

/**
 * TierGate — wraps children and only renders them if the user's plan
 * is in the `allowed` list. Otherwise shows an upgrade prompt.
 *
 * Usage: <TierGate allowed={["pro","elite"]}><MilliCents /></TierGate>
 */
export default function TierGate({ allowed = [], children, featureName = "This feature" }) {
  const { user } = useAuth();
  const plan = user?.plan || "basic";

  if (allowed.includes(plan)) return children;

  const isEliteOnly = allowed.length === 1 && allowed[0] === "elite";
  const upgradePlan = isEliteOnly ? "MILLI Elite" : "MILLI Pro";
  const upgradePrice = isEliteOnly ? "$49.99/mo" : "$29.99/mo";

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4">
      <div
        className="milli-card rounded-3xl p-8 flex flex-col items-center text-center gap-4"
        style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}
      >
        <div
          className="w-16 h-16 rounded-2xl flex items-center justify-center"
          style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.2)" }}
        >
          <Lock size={28} weight="fill" className="text-volt" />
        </div>
        <div>
          <h2
            className="font-chrome font-bold text-white text-[22px] leading-tight tracking-tight"
            style={{ fontFamily: "'Outfit', system-ui, sans-serif" }}
          >
            {featureName} requires {upgradePlan}
          </h2>
          <p className="text-zinc-400 text-[14px] mt-1.5 max-w-xs mx-auto">
            Upgrade to {upgradePlan} ({upgradePrice}) to unlock {featureName.toLowerCase()} and more premium features.
          </p>
        </div>
        <Link
          to="/app/pricing"
          className="rounded-xl px-6 py-3 text-[14px] font-bold text-black whitespace-nowrap transition-transform active:scale-95"
          style={{ background: "#D4FF00" }}
        >
          <Crown size={16} weight="fill" className="inline mr-1.5" />
          Upgrade to {upgradePlan}
        </Link>
      </div>
    </div>
  );
}