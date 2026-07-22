import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ShieldCheck, Lightning } from "@phosphor-icons/react";

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
    <div className="px-4 py-6 lg:px-6">
      <div className="mb-6">
        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.3em]">// Plans</div>
        <h1 className="font-display font-black text-3xl tracking-tighter mt-1 leading-[1.05]">Pick a plan, keep more of your money.</h1>
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
          return (
            <div
              key={t.id}
              data-testid={`tier-card-${t.id}`}
              className={`milli-card p-8 relative min-h-[440px] flex flex-col ${t.popular ? "border-volt shadow-[0_0_40px_rgba(0,229,255,0.15)]" : ""}`}
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
              <div className="font-mono text-[11px] uppercase tracking-[0.3em] text-zinc-500">{t.name}</div>
              <div className="mt-5 flex items-baseline gap-2">
                <div className="font-display font-black text-6xl chrome-text">${t.price}</div>
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
                className={`mt-8 w-full py-4 font-bold uppercase tracking-[0.15em] text-sm inline-flex items-center justify-center gap-2 rounded-lg ${
                  t.popular ? "btn-volt" : "border border-white/70 hover:bg-white hover:text-obsidian"
                } transition-colors disabled:opacity-50`}
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
