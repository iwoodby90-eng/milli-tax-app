import { useEffect, useState, useCallback } from "react";
import { api, formatApiError } from "@/lib/api";
import { usePlaidLink } from "react-plaid-link";
import { toast } from "sonner";
import {
  Bank, Plus, ArrowsClockwise, CaretRight, Trash,
} from "@phosphor-icons/react";

/**
 * Activity — the Payouts feed.
 * Native card list matching Milli's cyan-glow aesthetic.
 * Sections:
 *   1. Header
 *   2. YTD summary strip (Gross / Reserved / Count)
 *   3. Connected banks card
 *   4. Payouts list (chronological)
 */
export default function Income() {
  const [items, setItems] = useState([]);
  const [deposits, setDeposits] = useState([]);
  const [linkToken, setLinkToken] = useState(null);
  const [loadingLink, setLoadingLink] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [showManual, setShowManual] = useState(false);

  async function load() {
    try {
      const [i, d] = await Promise.all([
        api.get("/plaid/items"),
        api.get("/deposits"),
      ]);
      setItems(i.data);
      setDeposits(d.data);
    } catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  async function startLink() {
    setLoadingLink(true);
    try {
      const { data } = await api.post("/plaid/link-token");
      setLinkToken(data.link_token);
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setLoadingLink(false); }
  }

  const onPlaidSuccess = useCallback(async (public_token, metadata) => {
    try {
      const { data } = await api.post("/plaid/exchange", {
        public_token,
        institution_name: metadata?.institution?.name || "Bank",
      });
      toast.success(`Connected — ${data.synced_deposits} gig deposits found`);
      setLinkToken(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }, []);

  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: onPlaidSuccess,
    onExit: () => setLinkToken(null),
  });
  useEffect(() => { if (linkToken && ready) open(); }, [linkToken, ready, open]);

  async function syncAll() {
    setSyncing(true);
    try {
      const { data } = await api.post("/plaid/sync");
      toast.success(`+${data.synced} new payouts`);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setSyncing(false); }
  }

  async function removeItem(id) {
    if (!window.confirm("Disconnect this bank?")) return;
    try {
      await api.delete(`/plaid/items/${id}`);
      toast.success("Bank disconnected");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  const total = deposits.reduce((s, d) => s + Number(d.amount || 0), 0);
  const reserved = deposits.reduce((s, d) => s + Number(d.savings_set_aside || 0), 0);
  const groupedByMonth = groupByMonth(deposits);

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4">

      {/* Header */}
      <header className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
            Activity
          </h1>
          <p className="text-zinc-400 text-[14px] mt-1">Your payouts, in order.</p>
        </div>
        <div className="flex gap-2 flex-shrink-0">
          <IconBtn
            testid="income-sync"
            disabled={syncing || items.length === 0}
            onClick={syncAll}
            title={syncing ? "Syncing" : "Sync"}
            icon={ArrowsClockwise}
          />
          <IconBtn
            testid="income-add-manual"
            onClick={() => setShowManual(true)}
            title="Add manual"
            icon={Plus}
          />
        </div>
      </header>

      {/* 1 · Summary strip */}
      <section className="grid grid-cols-3 gap-2.5">
        <SummaryTile label="YTD Gross"        value={fmt(total)}    />
        <SummaryTile label="Reserved"          value={fmt(reserved)} accent />
        <SummaryTile label="Payouts"           value={deposits.length} />
      </section>

      {/* 2 · Connected banks */}
      <section className="milli-card rounded-2xl p-4" data-testid="banks-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[15.5px]">Connected banks</h2>
          <button
            onClick={startLink}
            disabled={loadingLink}
            data-testid="income-connect-bank"
            className="text-volt text-[12.5px] font-semibold inline-flex items-center gap-1 active:opacity-70 disabled:opacity-50"
            style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}
          >
            <Bank size={14} weight="bold" /> {loadingLink ? "Loading..." : "Connect bank"}
          </button>
        </div>
        {items.length === 0 ? (
          <div className="text-zinc-500 text-[13px] text-center py-4">
            No banks connected yet.
          </div>
        ) : (
          <ul className="space-y-2">
            {items.map((it) => (
              <li
                key={it.id}
                className="flex items-center gap-3 py-2"
                data-testid={`bank-row-${it.id}`}
              >
                <div className="w-9 h-9 rounded-lg bg-volt/10 border border-volt/40 flex items-center justify-center flex-shrink-0"
                     style={{ boxShadow: "0 0 10px rgba(0,229,255,0.2)" }}>
                  <Bank size={16} weight="regular" className="text-volt" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-white text-[14px] font-medium truncate">{it.institution_name}</div>
                  <div className="text-zinc-500 text-[11.5px]">
                    Connected {String(it.created_at || "").slice(0, 10)}
                  </div>
                </div>
                <button
                  onClick={() => removeItem(it.id)}
                  data-testid={`bank-remove-${it.id}`}
                  className="text-zinc-600 hover:text-rose-400 p-2"
                  aria-label="Remove"
                >
                  <Trash size={14} weight="regular" />
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* 3 · Payouts list */}
      <section data-testid="payouts-list">
        {deposits.length === 0 ? (
          <div className="milli-card rounded-2xl p-8 text-center">
            <Bank size={32} className="text-zinc-700 mx-auto" weight="regular" />
            <div className="text-white font-semibold text-[15px] mt-3">No payouts yet</div>
            <div className="text-zinc-500 text-[13px] mt-1">Connect a bank or add one manually.</div>
          </div>
        ) : (
          Object.entries(groupedByMonth).map(([monthLabel, group]) => (
            <div key={monthLabel} className="mb-4">
              <div className="px-1 mb-2 font-mono text-[10.5px] uppercase tracking-[0.28em] text-zinc-500">
                {monthLabel}
              </div>
              <div className="milli-card rounded-2xl overflow-hidden">
                <ul>
                  {group.map((d, idx) => (
                    <PayoutRow
                      key={d.id || idx}
                      deposit={d}
                      last={idx === group.length - 1}
                    />
                  ))}
                </ul>
              </div>
            </div>
          ))
        )}
      </section>

      {showManual && (
        <ManualDepositDialog
          onClose={() => setShowManual(false)}
          onSaved={() => { setShowManual(false); load(); }}
        />
      )}
    </div>
  );
}

/* ============ Sub-components ============ */

function fmt(n) {
  return `$${Number(n || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function groupByMonth(deposits) {
  const out = {};
  for (const d of deposits) {
    const dt = new Date(d.date || d.created_at || Date.now());
    const key = dt.toLocaleString("en-US", { month: "long", year: "numeric" });
    (out[key] = out[key] || []).push(d);
  }
  return out;
}

function SummaryTile({ label, value, accent }) {
  return (
    <div className="milli-card rounded-2xl p-3">
      <div className="text-zinc-500 text-[10.5px] uppercase tracking-widest">{label}</div>
      <div
        className={`font-chrome font-bold text-[17px] leading-tight tabular-nums mt-1 truncate ${
          accent ? "text-volt" : "chrome-text"
        }`}
        style={accent ? { textShadow: "0 0 8px rgba(0,229,255,0.4)" } : {}}
      >
        {value}
      </div>
    </div>
  );
}

function IconBtn({ icon: Icon, testid, onClick, disabled, title }) {
  return (
    <button
      data-testid={testid}
      onClick={onClick}
      disabled={disabled}
      title={title}
      aria-label={title}
      className="w-9 h-9 rounded-xl flex items-center justify-center active:opacity-60 disabled:opacity-40"
      style={{
        background: "rgba(10,14,18,0.85)",
        border: "1px solid rgba(0,229,255,0.35)",
        boxShadow: "0 0 10px rgba(0,229,255,0.2)",
      }}
    >
      <Icon size={16} weight="regular" className="text-volt" />
    </button>
  );
}

function PayoutRow({ deposit, last }) {
  const d = deposit;
  const platform = d.platform || "Payout";
  const merchant = d.merchant || d.description || platform;
  const date = new Date(d.date || d.created_at || Date.now());
  const dateStr = date.toLocaleDateString("en-US", { weekday: "short", day: "numeric" });
  const time = date.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
  const amt = Number(d.amount || 0);
  const saved = Number(d.savings_set_aside || 0);

  return (
    <li
      className={`flex items-center gap-3 py-3 px-3 ${last ? "" : "border-b border-white/[0.05]"}`}
      data-testid={`payout-${d.id || dateStr}`}
    >
      <PlatformBadge platform={platform} />
      <div className="flex-1 min-w-0">
        <div className="text-white text-[14px] font-semibold leading-tight truncate">{platform}</div>
        <div className="text-zinc-500 text-[11.5px] truncate">
          {dateStr} · {time}{merchant && merchant !== platform ? ` · ${merchant}` : ""}
        </div>
      </div>
      <div className="text-right flex-shrink-0">
        <div className="text-white font-bold text-[14.5px] tabular-nums">+{fmt(amt).replace("$", "$")}</div>
        {saved > 0 && (
          <div className="text-volt text-[10.5px] tabular-nums" style={{ textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>
            −{fmt(saved)} to Vault
          </div>
        )}
      </div>
      <CaretRight size={13} weight="bold" className="text-zinc-600 flex-shrink-0" />
    </li>
  );
}

function PlatformBadge({ platform }) {
  const map = {
    Uber:       { bg: "#000000", fg: "#FFFFFF", label: "Uber" },
    UberX:      { bg: "#000000", fg: "#FFFFFF", label: "Uber" },
    Lyft:       { bg: "#FF00BF", fg: "#FFFFFF", label: "lyft" },
    DoorDash:   { bg: "#EB1700", fg: "#FFFFFF", label: "DD" },
    Spark:      { bg: "#0071DC", fg: "#FFC220", label: "★" },
    Instacart:  { bg: "#43B02A", fg: "#FFFFFF", label: "IC" },
    "Amazon Flex": { bg: "#FF9900", fg: "#232F3E", label: "AF" },
    Grubhub:    { bg: "#F63440", fg: "#FFFFFF", label: "GH" },
    Shipt:      { bg: "#1DAA36", fg: "#FFFFFF", label: "SH" },
  };
  const cfg = map[platform] || { bg: "#2A2E33", fg: "#FFFFFF", label: "$" };
  return (
    <div
      className="w-9 h-9 rounded-lg flex-shrink-0 flex items-center justify-center font-bold text-[10.5px]"
      style={{
        background: cfg.bg, color: cfg.fg,
        boxShadow: "0 4px 8px rgba(0,0,0,0.35)",
        fontFamily: "'Sora','Inter',sans-serif",
      }}
    >
      {cfg.label}
    </div>
  );
}

function ManualDepositDialog({ onClose, onSaved }) {
  const [form, setForm] = useState({
    date: new Date().toISOString().slice(0, 10),
    amount: "",
    platform: "Uber",
    merchant: "",
  });
  const [busy, setBusy] = useState(false);

  async function save() {
    setBusy(true);
    try {
      await api.post("/deposits/manual", { ...form, amount: parseFloat(form.amount) });
      toast.success("Payout added");
      onSaved();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-end sm:items-center justify-center z-50 p-3" onClick={onClose}>
      <div
        className="milli-card w-full sm:max-w-md rounded-3xl p-5"
        onClick={(e) => e.stopPropagation()}
        style={{ border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 32px rgba(0,229,255,0.25)" }}
      >
        <div className="text-white font-semibold text-[17px] mb-4">Add manual payout</div>
        <div className="space-y-3">
          <Field label="Date">
            <input
              data-testid="manual-deposit-date"
              type="date"
              value={form.date}
              onChange={(e) => setForm({ ...form, date: e.target.value })}
              className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt"
            />
          </Field>
          <Field label="Amount ($)">
            <input
              data-testid="manual-deposit-amount"
              type="number" step="0.01" placeholder="0.00"
              value={form.amount}
              onChange={(e) => setForm({ ...form, amount: e.target.value })}
              className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt tabular-nums"
            />
          </Field>
          <Field label="Platform">
            <select
              data-testid="manual-deposit-platform"
              value={form.platform}
              onChange={(e) => setForm({ ...form, platform: e.target.value })}
              className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt"
            >
              {["Uber", "Lyft", "DoorDash", "Spark", "Instacart", "Amazon Flex", "Grubhub", "Shipt", "Other"].map(o => <option key={o} value={o}>{o}</option>)}
            </select>
          </Field>
        </div>
        <div className="flex gap-2 mt-5">
          <button
            onClick={onClose}
            className="flex-1 rounded-xl py-3 text-white/70 text-[13px] font-semibold border border-white/10 active:opacity-70"
          >
            Cancel
          </button>
          <button
            data-testid="manual-deposit-save"
            onClick={save}
            disabled={busy || !form.amount}
            className="flex-1 rounded-xl py-3 font-bold text-[13px] text-obsidian disabled:opacity-50 active:brightness-95"
            style={{
              background: "linear-gradient(180deg, #00E5FF 0%, #00B4D0 100%)",
              boxShadow: "0 0 20px rgba(0,229,255,0.4), inset 0 1px 0 rgba(255,255,255,0.5)",
            }}
          >
            {busy ? "Saving..." : "Save"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div>
      <label className="block text-zinc-400 text-[11px] mb-1.5">{label}</label>
      {children}
    </div>
  );
}
