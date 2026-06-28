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
    <div className="p-6 lg:p-10 max-w-7xl">
      <div className="mb-8">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Plans</div>
        <h1 className="font-display font-black text-4xl tracking-tighter mt-1">Pick a plan, keep more of your money.</h1>
        <p className="text-zinc-400 mt-1">
          You're on <span className="text-volt uppercase font-bold">{user?.plan}</span>
          {user?.plan === "trial" && user?.trial_end && (
            <> · trial ends {new Date(user.trial_end).toLocaleDateString()}</>
          )}
        </p>
      </div>

      <div className="grid md:grid-cols-3 gap-4">
        {tiers.map((t) => {
          const isCurrent = user?.plan === t.id;
          return (
            <div
              key={t.id}
              data-testid={`tier-card-${t.id}`}
              className={`milli-card p-6 relative ${t.popular ? "border-volt" : ""}`}
            >
              {t.popular && (
                <div className="absolute -top-3 left-6 bg-volt text-obsidian text-xs font-bold uppercase tracking-wider px-3 py-1">
                  Most popular
                </div>
              )}
              {isCurrent && (
                <div className="absolute -top-3 right-6 bg-success text-obsidian text-xs font-bold uppercase tracking-wider px-3 py-1">
                  Current
                </div>
              )}
              <div className="font-mono text-xs uppercase tracking-[0.3em] text-zinc-500">{t.name}</div>
              <div className="mt-4 flex items-baseline gap-2">
                <div className="font-display font-black text-5xl">${t.price}</div>
                <div className="text-zinc-500 text-sm">/mo</div>
              </div>
              <div className="text-xs text-zinc-500 font-mono mt-1">{t.trial_days}-day free trial</div>
              <ul className="mt-6 space-y-2.5 text-sm">
                {t.features.map((f) => (
                  <li key={f} className="flex gap-2"><ShieldCheck size={16} weight="bold" className="text-volt mt-0.5 flex-shrink-0" /> {f}</li>
                ))}
              </ul>
              <button
                data-testid={`tier-subscribe-${t.id}`}
                disabled={isCurrent || loading === t.id}
                onClick={() => subscribe(t.id)}
                className={`mt-6 w-full py-3 font-bold uppercase tracking-wider text-sm inline-flex items-center justify-center gap-2 ${
                  t.popular ? "btn-volt" : "border border-white hover:bg-white hover:text-obsidian"
                } transition-colors disabled:opacity-50`}
              >
                {isCurrent ? "Current plan" : loading === t.id ? "Loading..." : <>Choose {t.name} <Lightning weight="fill" /></>}
              </button>
            </div>
          );
        })}
      </div>

      <div className="mt-8 text-sm text-zinc-500 font-mono">
        Powered by Stripe. Test card: 4242 4242 4242 4242 · any future expiry · any CVC.
      </div>
    </div>
  );
}
