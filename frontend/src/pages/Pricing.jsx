import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ShieldCheck, Lightning, Star, Crown, AppleLogo } from "@phosphor-icons/react";

const CYAN = "#00E5FF";

const CARD_STYLES = {
  borderRadius: "22px",
  background: "#0D0F12",
  border: "1px solid #1A1D21",
  boxShadow: "0 4px 24px rgba(0,0,0,0.4)",
};

const ELITE_STYLES = {
  borderRadius: "22px",
  background: "#0D0F12",
  border: "2px solid rgba(0, 229, 255, 0.6)",
  boxShadow: "0 0 32px rgba(0,229,255,0.2), 0 0 60px rgba(0,229,255,0.08), inset 0 0 24px rgba(0,229,255,0.1), 0 4px 24px rgba(0,0,0,0.4)",
};

/**
 * Detect if running in Capacitor (native iOS) for StoreKit 2 IAP.
 */
function isNativeIOS() {
  try {
    return !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
  } catch { return false; }
}

/**
 * StoreKit 2 purchase flow via @capgo/native-purchases plugin.
 * Product IDs map: pro → milli.pro.monthly, elite → milli.elite.monthly
 */
async function purchaseNativeIAP(tier) {
  try {
    const { NativePurchases } = await import("@capgo/native-purchases");
    const productId = tier === "elite" ? "milli.elite.monthly" : "milli.pro.monthly";
    const result = await NativePurchases.purchaseProduct({ productIdentifier: productId });
    if (result && result.transactionId) {
      // Verify receipt server-side
      await api.post("/iap/verify", {
        platform: "apple",
        transaction_id: result.transactionId,
        product_id: productId,
        receipt: result.receipt || "",
      });
      toast.success("Subscription activated via Apple");
      return true;
    }
  } catch (e) {
    if (e?.code === "USER_CANCELLED") {
      toast("Purchase cancelled");
    } else {
      toast.error("Purchase failed. Try again or use card payment.");
    }
  }
  return false;
}

export default function Pricing() {
  const { user, refresh } = useAuth();
  const [tiers, setTiers] = useState([]);
  const [loading, setLoading] = useState(null);
  const native = isNativeIOS();

  useEffect(() => { api.get("/pricing/tiers").then(({ data }) => setTiers(data)).catch(() => {}); }, []);

  async function subscribe(tier) {
    setLoading(tier);
    try {
      if (native) {
        const ok = await purchaseNativeIAP(tier);
        if (ok) await refresh();
      } else {
        const { data } = await api.post("/stripe/checkout", { tier, origin_url: window.location.origin });
        window.location.href = data.url;
      }
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setLoading(null); }
  }

  return (
    <div className="px-4 py-6 lg:px-6" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100%" }}>
      <div className="mb-8">
        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.3em]">// Plans</div>
        <h1 style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif", fontWeight: 900 }} className="text-3xl tracking-tighter mt-1 leading-[1.05]">Pick a plan, keep more of your money.</h1>
        <p className="text-zinc-400 mt-2 text-sm">
          You're on <span className="text-volt uppercase font-bold">{user?.plan}</span>
          {user?.plan === "trial" && user?.trial_end && (
            <> · trial ends {new Date(user.trial_end).toLocaleDateString()}</>
          )}
        </p>
        {native && (
          <div className="mt-2 flex items-center gap-1.5 text-xs text-zinc-500">
            <AppleLogo size={12} weight="fill" />
            <span className="font-mono uppercase tracking-wider">Apple In-App Purchase enabled</span>
          </div>
        )}
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
              className="relative overflow-hidden flex flex-col"
              style={{ ...cardStyle, padding: "32px 28px" }}
            >
              {isElite && (
                <div
                  className="absolute -top-px left-0 right-0 h-[3px]"
                  style={{ background: `linear-gradient(90deg, transparent 5%, ${CYAN} 50%, transparent 95%)` }}
                />
              )}
              {isElite && (
                <div className="flex items-center gap-1.5 mb-4">
                  <Crown size={14} weight="fill" style={{ color: CYAN }} />
                  <span
                    className="text-[10px] font-bold uppercase tracking-[0.25em]"
                    style={{ color: CYAN, textShadow: `0 0 10px rgba(0,229,255,0.4)` }}
                  >
                    Member of Distinction
                  </span>
                </div>
              )}
              {isCurrent && (
                <div className="absolute -top-3 right-6 bg-success text-obsidian text-[10px] font-bold uppercase tracking-[0.2em] px-3 py-1 rounded-full">
                  Current
                </div>
              )}

              <div
                className="text-[11px] uppercase tracking-[0.3em] text-zinc-500"
                style={{ fontFamily: "'Sora', sans-serif", fontWeight: 500 }}
              >
                {t.name}
              </div>

              <div className="mt-5 flex items-baseline gap-2">
                <div
                  className="text-6xl chrome-text"
                  style={{ fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, system-ui, sans-serif", fontWeight: 900, letterSpacing: "-0.03em" }}
                >
                  ${t.price}
                </div>
                <div className="text-zinc-500 text-sm" style={{ fontFamily: "'Sora', sans-serif" }}>/mo</div>
              </div>

              <div className="text-[11px] text-zinc-500 font-mono mt-1.5 uppercase tracking-wider">{t.trial_days}-day free trial</div>

              <ul className="mt-7 space-y-3 text-[14px] flex-1">
                {t.features.map((f) => (
                  <li key={f} className="flex gap-2.5 items-start">
                    <ShieldCheck size={16} weight="bold" className="text-volt mt-0.5 flex-shrink-0" />
                    <span className="text-zinc-200">{f}</span>
                  </li>
                ))}
              </ul>

              <button
                data-testid={`tier-subscribe-${t.id}`}
                disabled={isCurrent || loading === t.id}
                onClick={() => subscribe(t.id)}
                className="mt-8 w-full py-4 font-bold uppercase tracking-[0.15em] text-sm inline-flex items-center justify-center gap-2 transition-all disabled:opacity-50 active:scale-[0.98]"
                style={{
                  borderRadius: "14px",
                  ...(isElite
                    ? {
                        background: `linear-gradient(135deg, ${CYAN} 0%, #00B8D4 100%)`,
                        color: "#001217",
                        boxShadow: `0 0 20px rgba(0,229,255,0.45), 0 4px 12px rgba(0,0,0,0.4)`,
                      }
                    : {
                        background: "transparent",
                        border: "1px solid rgba(255,255,255,0.15)",
                        color: "#FFFFFF",
                      }),
                }}
              >
                {isCurrent ? (
                  <><ShieldCheck size={16} weight="fill" /> Current plan</>
                ) : loading === t.id ? (
                  "Processing..."
                ) : native ? (
                  <>Subscribe</>
                ) : (
                  <>Choose {t.name} <Lightning weight="fill" size={16} /></>
                )}
              </button>
            </div>
          );
        })}
      </div>

      <div className="mt-8 text-[10px] text-zinc-600 font-mono uppercase tracking-wider text-center">
        {native ? "Managed by Apple · StoreKit 2" : "Powered by Stripe · Secure checkout"}
      </div>
    </div>
  );
}
