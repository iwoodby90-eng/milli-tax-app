import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ShieldCheck, Lightning } from "@phosphor-icons/react";

const CARD_STYLES = {
  borderRadius: "22px",
  background: "#0D0F12",
  border: "1px solid #1A1D21",
};

const ELITE_STYLES = {
  borderRadius: "22px",
  background: "#0D0F12",
  border: "1px solid rgba(0, 229, 255, 0.55)",
  boxShadow: "inset 0 0 20px rgba(0, 229, 255, 0.15)",
};

export default function Pricing() {
  const { user } = useAuth();
  const [tiers, setTiers] = useState([]);
  const [loading, setLoading] = useState(null);

  useEffect(() => { api.get("/pricing/tiers").then(({ data }) => setTiers(data)).catch(() => {}); }, []);

  async function subscribe(tier) {
    setLoading(tier);
    try {
      const { data } = await api.post("/stripe/checkout", { tier, origin_url: window.location.origin });
      window.location.href = data.url;
    } catch (e) { toast.error(formatApiError(e)); setLoading(null); }
  }

  return (
    <div className="px-4 py-6 lg:px-6" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100%" }}>
      <div className="mb-6">
        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.3em]">// Plans</div>
        <h1 style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif", fontWeight: 900 }} className="text-3xl tracking-tighter mt-1 leading-[1.05]">Pick a plan, keep more of your money.</h1>
        <p className="text-zinc-400 mt-2 text-sm">
          You're on <span className="text-volt uppercase font-bold">{user?.plan}</span>
          {user?.plan === "trial" && user?.trial_end && (
            <> · trial ends {new Date(user.trial_end).toLocaleDateString()}</>
          )}
        </p>
      </div>

      <div className="flex flex-col gap-6">
        {tiers.map((t) => {
          const isCurrent = user?.plan === t.id;
          const isElite = t.id === "elite" || t.popular;
          const cardStyle = isElite ? ELITE_STYLES : CARD_STYLES;
          return (
            <div
              key={t.id}
              data-testid={`tier-card-${t.id}`}
              className="p-8 relative min-h-[440px] flex flex-col"
              style={cardStyle}
            >
              {t.popular && (
                <div className="absolute -top-3 left-6 bg-volt text-obsidian text-[10px] font-bold uppercase tracking-[0.2em] px-3 py-1 rounded-full">
                  Most popular
                </div>
              )}
              {isCurrent && (
                <div className="absolute -top-3 right-6 bg-success text-obsidian text-[10px] font-bold uppercase tracking-[0.2em] px-3 py-1 rounded-full">
                  Current
                </div>
              )}
              <div style={{ fontFamily: "'Sora', sans-serif" }} className="font-mono text-[11px] uppercase tracking-[0.3em] text-zinc-500">{t.name}</div>
              <div className="mt-5 flex items-baseline gap-2">
                <div style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif", fontWeight: 900 }} className="text-6xl chrome-text">${t.price}</div>
                <div className="text-zinc-500 text-sm">/mo</div>
              </div>
              <div className="text-[11px] text-zinc-500 font-mono mt-1 uppercase tracking-wider">{t.trial_days}-day free trial</div>
              <ul className="mt-7 space-y-3 text-[14px] flex-1">
                {t.features.map((f) => (
                  <li key={f} className="flex gap-2.5 items-start"><ShieldCheck size={16} weight="bold" className="text-volt mt-0.5 flex-shrink-0" /> <span className="text-zinc-200">{f}</span></li>
                ))}
              </ul>
              <button
                data-testid={`tier-subscribe-${t.id}`}
                disabled={isCurrent || loading === t.id}
                onClick={() => subscribe(t.id)}
                className={`mt-8 w-full py-4 font-bold uppercase tracking-[0.15em] text-sm inline-flex items-center justify-center gap-2 transition-colors disabled:opacity-50`}
                style={{ borderRadius: "12px", ...(t.popular ? {} : { border: "1px solid rgba(255,255,255,0.7)" }) }}
              >
                {isCurrent ? "Current plan" : loading === t.id ? "Loading..." : <>Choose {t.name} <Lightning weight="fill" /></>}
              </button>
            </div>
          );
        })}
      </div>

      <div className="mt-8 text-[11px] text-zinc-500 font-mono uppercase tracking-wider text-center">
        Powered by Stripe · Test card 4242 4242 4242 4242
      </div>
    </div>
  );
}
