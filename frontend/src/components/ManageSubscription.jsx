/**
 * ManageSubscription — dual-path subscription management card.
 *
 * Users who signed up via Stripe web checkout → tap "Manage on the web"
 * to open the Stripe Customer Portal (update card, cancel, view invoices).
 *
 * Users who subscribed via Apple IAP inside the iOS app → tap "Manage
 * via Apple ID" to jump directly into their App Store subscription
 * management sheet. Apple **requires** this deep-link exists in any app
 * offering auto-renewable subscriptions.
 */
import { useState } from "react";
import { motion } from "framer-motion";
import {
  Crown, CreditCard, AppleLogo, ArrowSquareOut, ShieldCheck,
} from "@phosphor-icons/react";
import { toast } from "sonner";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";

const CYAN = "#00E5FF";
const APPLE_SUBS_URL = "https://apps.apple.com/account/subscriptions";

export default function ManageSubscription() {
  const { user } = useAuth();
  const [busy, setBusy] = useState(false);

  const planLabel = ((user?.plan || "trial")[0]?.toUpperCase() +
    (user?.plan || "trial").slice(1));

  async function openStripePortal() {
    setBusy(true);
    try {
      const { data } = await api.post("/stripe/portal", {
        return_url: window.location.origin + "/app/settings",
      });
      if (data?.url) {
        window.location.href = data.url;
      } else {
        toast.error("Portal unavailable");
      }
    } catch (e) {
      toast.error(formatApiError(e));
    } finally {
      setBusy(false);
    }
  }

  function openAppleSubs() {
    window.open(APPLE_SUBS_URL, "_blank", "noopener,noreferrer");
  }

  return (
    <section
      className="rounded-2xl overflow-hidden"
      data-testid="manage-subscription"
      style={{
        background: "linear-gradient(180deg, rgba(255,255,255,0.03), rgba(255,255,255,0))",
        border: "1px solid rgba(192,192,192,0.16)",
        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.04)",
      }}
    >
      {/* Header */}
      <div className="flex items-center justify-between gap-2 px-4 py-3 border-b border-white/[0.06]">
        <div className="flex items-center gap-2 min-w-0">
          <Crown size={16} weight="duotone" style={{ color: CYAN }} className="flex-shrink-0" />
          <div className="text-[11px] uppercase tracking-[0.22em] font-semibold truncate" style={{ color: CYAN }}>
            Subscription
          </div>
        </div>
        <div className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-[0.16em] flex-shrink-0"
             style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.35)", color: CYAN }}>
          <ShieldCheck size={10} weight="fill" />
          {planLabel}
        </div>
      </div>

      {/* Two action rows */}
      <div className="divide-y divide-white/[0.06]">
        {/* Stripe (web) */}
        <motion.button
          whileTap={{ scale: 0.985 }}
          onClick={openStripePortal}
          disabled={busy}
          data-testid="subscription-manage-web"
          className="w-full flex items-center gap-3 px-4 py-3.5 text-left active:bg-white/[0.03] disabled:opacity-60"
        >
          <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
               style={{ background: "linear-gradient(180deg, rgba(0,229,255,0.10), rgba(0,229,255,0.02))",
                        border: "1px solid rgba(0,229,255,0.35)" }}>
            <CreditCard size={16} weight="duotone" style={{ color: CYAN }} />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-[14px] font-semibold text-white truncate">Manage on the web</div>
            <div className="text-[11.5px] text-white/60 truncate">Card, invoices, cancel — via Stripe</div>
          </div>
          <ArrowSquareOut size={14} weight="bold" className="text-white/40 flex-shrink-0" />
        </motion.button>

        {/* Apple IAP */}
        <motion.button
          whileTap={{ scale: 0.985 }}
          onClick={openAppleSubs}
          data-testid="subscription-manage-apple"
          className="w-full flex items-center gap-3 px-4 py-3.5 text-left active:bg-white/[0.03]"
        >
          <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
               style={{ background: "rgba(255,255,255,0.06)",
                        border: "1px solid rgba(255,255,255,0.12)" }}>
            <AppleLogo size={16} weight="fill" className="text-white" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-[14px] font-semibold text-white truncate">Manage via Apple ID</div>
            <div className="text-[11.5px] text-white/60 truncate">In-app purchase subscriptions</div>
          </div>
          <ArrowSquareOut size={14} weight="bold" className="text-white/40 flex-shrink-0" />
        </motion.button>
      </div>

      <div className="px-4 py-3 border-t border-white/[0.06]">
        <p className="text-[10.5px] text-white/40 leading-relaxed">
          If you subscribed in the iOS app, use <span className="text-white/70 font-semibold">Manage via Apple ID</span> —
          Apple handles billing for iOS subscriptions. If you subscribed on the web, use{" "}
          <span className="text-white/70 font-semibold">Manage on the web</span> — Stripe handles it.
        </p>
      </div>
    </section>
  );
}
