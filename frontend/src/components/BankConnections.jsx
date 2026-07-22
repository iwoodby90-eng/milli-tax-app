/**
 * BankConnections — reusable Plaid multi-bank manager.
 *
 * Lists every bank currently linked to the user's Milli account and lets
 * them:
 *   • Add another bank (opens Plaid Link, exchanges the public token,
 *     immediately syncs it and posts the deposits into MongoDB)
 *   • Sync all connected banks on demand
 *   • Disconnect an individual bank
 *
 * Backend endpoints used (already wired in server.py):
 *   POST /api/plaid/link-token
 *   POST /api/plaid/exchange
 *   GET  /api/plaid/items
 *   POST /api/plaid/sync
 *   DELETE /api/plaid/items/{item_id}
 */
import { useCallback, useEffect, useState } from "react";
import { usePlaidLink } from "react-plaid-link";
import { motion, AnimatePresence } from "framer-motion";
import { Bank, Plus, Trash, ArrowsClockwise, CheckCircle, Warning } from "@phosphor-icons/react";
import { toast } from "sonner";
import { api, formatApiError } from "@/lib/api";

const CYAN = "#00E5FF";

export default function BankConnections() {
  const [items, setItems] = useState([]);
  const [linkToken, setLinkToken] = useState(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [starting, setStarting] = useState(false);

  const load = useCallback(async () => {
    try {
      const { data } = await api.get("/plaid/items");
      setItems(Array.isArray(data) ? data : []);
    } catch (e) {
      toast.error(formatApiError(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const startLink = async () => {
    setStarting(true);
    try {
      const { data } = await api.post("/plaid/link-token");
      setLinkToken(data.link_token);
    } catch (e) {
      toast.error(formatApiError(e));
    } finally {
      setStarting(false);
    }
  };

  const onPlaidSuccess = useCallback(
    async (public_token, metadata) => {
      try {
        const { data } = await api.post("/plaid/exchange", {
          public_token,
          institution_name: metadata?.institution?.name || "Bank",
        });
        toast.success(
          `${data.institution_name} connected · ${data.synced_deposits} gig deposits imported`
        );
        setLinkToken(null);
        await load();
      } catch (e) {
        toast.error(formatApiError(e));
      }
    },
    [load]
  );

  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: onPlaidSuccess,
    onExit: () => setLinkToken(null),
  });
  useEffect(() => { if (linkToken && ready) open(); }, [linkToken, ready, open]);

  const syncAll = async () => {
    setSyncing(true);
    try {
      const { data } = await api.post("/plaid/sync");
      toast.success(`Synced ${data.synced} new deposit${data.synced === 1 ? "" : "s"}`);
      await load();
    } catch (e) {
      toast.error(formatApiError(e));
    } finally {
      setSyncing(false);
    }
  };

  const remove = async (item) => {
    if (!window.confirm(`Disconnect ${item.institution_name}? Milli will stop importing new deposits from this bank.`)) return;
    try {
      await api.delete(`/plaid/items/${item.id}`);
      toast.success(`${item.institution_name} disconnected`);
      await load();
    } catch (e) {
      toast.error(formatApiError(e));
    }
  };

  return (
    <section
      className="rounded-2xl overflow-hidden"
      data-testid="bank-connections"
      style={{
        background: "linear-gradient(180deg, rgba(255,255,255,0.03) 0%, rgba(255,255,255,0) 100%)",
        border: "1px solid rgba(192,192,192,0.16)",
        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.04)",
      }}
    >
      {/* Header */}
      <div className="flex items-center justify-between gap-2 px-4 py-3 border-b border-white/[0.06]">
        <div className="flex items-center gap-2">
          <Bank size={16} weight="duotone" style={{ color: CYAN }} />
          <div className="text-[11px] uppercase tracking-[0.22em] font-semibold" style={{ color: CYAN }}>
            Connected Banks
          </div>
        </div>
        <div className="flex items-center gap-2">
          {items.length > 0 && (
            <button
              onClick={syncAll}
              disabled={syncing}
              data-testid="bank-sync-all"
              className="inline-flex items-center gap-1 text-[11px] uppercase tracking-[0.18em] font-semibold text-white/70 active:opacity-60 disabled:opacity-40"
            >
              <ArrowsClockwise size={12} weight="bold" className={syncing ? "animate-spin" : ""} />
              {syncing ? "Syncing…" : "Sync all"}
            </button>
          )}
        </div>
      </div>

      {/* List */}
      <div className="divide-y divide-white/[0.06]">
        {loading && (
          <div className="px-4 py-6 text-center text-[13px] text-white/50" data-testid="bank-loading">Loading…</div>
        )}

        {!loading && items.length === 0 && (
          <div className="px-4 py-8 text-center" data-testid="bank-empty">
            <Warning size={22} weight="duotone" className="mx-auto text-white/40" />
            <div className="text-[14px] text-white mt-2 font-semibold">No banks connected yet</div>
            <p className="text-[12px] text-white/50 mt-1 max-w-[280px] mx-auto">
              Milli protects a % of every gig payout the moment it lands. Connect the account where
              your gig income deposits.
            </p>
          </div>
        )}

        <AnimatePresence initial={false}>
          {!loading && items.map((it) => (
            <motion.div
              key={it.id}
              layout
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.25 }}
              className="flex items-center gap-3 px-4 py-3"
              data-testid={`bank-item-${it.id}`}
            >
              <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                   style={{
                     background: "linear-gradient(180deg, rgba(0,229,255,0.10), rgba(0,229,255,0.02))",
                     border: "1px solid rgba(0,229,255,0.35)",
                   }}>
                <Bank size={16} weight="fill" style={{ color: CYAN }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-[14px] font-semibold text-white truncate">{it.institution_name}</div>
                <div className="text-[11px] text-white/50 mt-0.5 flex items-center gap-1.5">
                  <CheckCircle size={11} weight="fill" style={{ color: CYAN }} />
                  Active
                  {it.created_at && (
                    <span className="text-white/30">
                      · linked {new Date(it.created_at).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
                    </span>
                  )}
                </div>
              </div>
              <button
                onClick={() => remove(it)}
                data-testid={`bank-remove-${it.id}`}
                aria-label={`Disconnect ${it.institution_name}`}
                className="w-8 h-8 flex items-center justify-center rounded-lg text-white/50 active:text-red-400 active:bg-red-500/10"
              >
                <Trash size={14} weight="bold" />
              </button>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Footer CTA */}
      <div className="px-4 pt-3 pb-4 border-t border-white/[0.06]">
        <button
          onClick={startLink}
          disabled={starting || linkToken != null}
          data-testid="bank-connect-btn"
          className="w-full py-3 rounded-full font-bold uppercase tracking-[0.2em] text-[12px] inline-flex items-center justify-center gap-2 disabled:opacity-60 active:scale-[0.985] transition-transform"
          style={{
            background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
            color: "#001217",
            boxShadow: "0 0 20px rgba(0,229,255,0.4), 0 0 40px rgba(0,229,255,0.15)",
          }}
        >
          <Plus size={14} weight="bold" />
          {starting || linkToken
            ? "Opening Plaid…"
            : items.length === 0 ? "Connect your bank" : "Add another bank"}
        </button>
        <p className="text-[10px] text-white/40 text-center mt-2 leading-relaxed">
          Secured by <span className="text-white/60 font-semibold">Plaid</span>. Milli never sees or
          stores your bank credentials. Read-only transaction access can be revoked anytime.
        </p>
      </div>
    </section>
  );
}
