import { useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  X, CalendarCheck, Receipt, ShieldCheck, TrendUp, Bell,
} from "@phosphor-icons/react";

/**
 * NotificationSheet — bottom sheet drawer with milestones, reminders, and
 * payout confirmations. Real data can be piped in via `items`; the fallback
 * demo list matches the app's Milli Tax Vault narrative.
 */
export default function NotificationSheet({ open, onClose, items }) {
  useEffect(() => {
    if (!open) return;
    document.body.style.overflow = "hidden";
    return () => { document.body.style.overflow = ""; };
  }, [open]);

  const list = items && items.length ? items : DEMO_ITEMS;
  const unread = list.filter((x) => x.unread).length;

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm"
            onClick={onClose}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            data-testid="notif-overlay"
          />
          <motion.div
            className="fixed left-0 right-0 bottom-0 z-50 rounded-t-3xl overflow-hidden"
            style={{
              background: "linear-gradient(180deg, rgba(15,18,22,0.98) 0%, rgba(5,7,10,0.98) 100%)",
              border: "1px solid rgba(0,229,255,0.30)",
              boxShadow: "0 -18px 60px rgba(0,229,255,0.15), 0 -32px 80px rgba(0,0,0,0.7)",
              maxHeight: "80vh",
            }}
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "100%" }}
            transition={{ type: "spring", damping: 32, stiffness: 320 }}
            data-testid="notif-sheet"
          >
            {/* grabber */}
            <div className="flex justify-center pt-3 pb-1">
              <span className="w-10 h-1 rounded-full bg-white/20" />
            </div>
            {/* header */}
            <div className="flex items-center justify-between px-5 pt-2 pb-3">
              <div className="flex items-center gap-2">
                <Bell size={18} weight="fill" className="text-volt"
                      style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.55))" }} />
                <h2 className="text-white font-semibold text-[17px]">Notifications</h2>
                {unread > 0 && (
                  <span
                    className="text-volt text-[10.5px] font-bold px-2 py-0.5 rounded-full tracking-wider"
                    style={{ background: "rgba(0,229,255,0.10)", border: "1px solid rgba(0,229,255,0.35)" }}
                  >
                    {unread} NEW
                  </span>
                )}
              </div>
              <button
                onClick={onClose}
                data-testid="notif-close"
                className="w-9 h-9 rounded-full bg-white/[0.06] flex items-center justify-center active:opacity-60"
              >
                <X size={16} weight="bold" className="text-zinc-300" />
              </button>
            </div>
            {/* list */}
            <ul
              className="overflow-y-auto px-3 pb-6"
              style={{ maxHeight: "calc(80vh - 80px)", paddingBottom: "calc(env(safe-area-inset-bottom, 0px) + 24px)" }}
            >
              {list.map((n, i) => (
                <NotifRow key={n.id || i} n={n} />
              ))}
              {list.length === 0 && (
                <li className="text-center text-zinc-500 py-10">You&apos;re all caught up.</li>
              )}
            </ul>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

const KIND = {
  quarterly: { Icon: CalendarCheck, tint: "#00E5FF", label: "Quarterly Tax" },
  payout:    { Icon: Receipt,       tint: "#00E5FF", label: "Payout" },
  vault:     { Icon: ShieldCheck,   tint: "#4DE0FF", label: "Vault" },
  milestone: { Icon: TrendUp,       tint: "#00E5FF", label: "Milestone" },
};

function NotifRow({ n }) {
  const cfg = KIND[n.kind] || KIND.quarterly;
  return (
    <li
      className="flex items-start gap-3 py-3 px-3 rounded-2xl mb-1 relative"
      style={{
        background: n.unread ? "rgba(0,229,255,0.05)" : "transparent",
        border: n.unread ? "1px solid rgba(0,229,255,0.20)" : "1px solid transparent",
      }}
      data-testid={`notif-row-${n.id || n.kind}`}
    >
      <div
        className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
        style={{
          background: `radial-gradient(circle at 30% 30%, ${cfg.tint}33 0%, rgba(0,0,0,0.4) 80%)`,
          border: `1px solid ${cfg.tint}66`,
          boxShadow: `0 0 12px ${cfg.tint}55`,
        }}
      >
        <cfg.Icon size={18} weight="duotone" style={{ color: cfg.tint }} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-1.5">
          <span
            className="text-[10px] uppercase tracking-widest font-bold"
            style={{ color: cfg.tint, textShadow: `0 0 6px ${cfg.tint}55` }}
          >
            {cfg.label}
          </span>
          <span className="text-zinc-500 text-[11px]">· {n.when}</span>
        </div>
        <div className="text-white font-semibold text-[14px] mt-0.5 leading-tight">{n.title}</div>
        <div className="text-zinc-400 text-[12.5px] leading-snug mt-0.5">{n.body}</div>
      </div>
      {n.unread && (
        <span
          className="absolute top-4 right-4 w-2 h-2 rounded-full bg-volt"
          style={{ boxShadow: "0 0 6px rgba(0,229,255,0.8)" }}
        />
      )}
    </li>
  );
}

const DEMO_ITEMS = [
  {
    id: "n1", kind: "quarterly", unread: true, when: "in 12 days",
    title: "Q3 estimated payment is due Sept 15",
    body: "Milli has $1,310.00 reserved. Tap to schedule the ACH now.",
  },
  {
    id: "n2", kind: "payout", unread: true, when: "just now",
    title: "New payout from Uber · +$111.77",
    body: "$7.38 auto-routed to your Milli Tax Vault™.",
  },
  {
    id: "n3", kind: "milestone", unread: true, when: "today",
    title: "You crossed 7% of your 2026 tax goal 🎯",
    body: "$1,480.42 of $20,000 protected — keep the momentum.",
  },
  {
    id: "n4", kind: "vault", unread: false, when: "yesterday",
    title: "Vault deposit posted · $43.75",
    body: "From DoorDash payout on Aug 1, 2026.",
  },
  {
    id: "n5", kind: "quarterly", unread: false, when: "Jul 12",
    title: "Q2 estimated payment confirmed",
    body: "$1,240.00 filed and receipt saved to your Tax Vault.",
  },
];
