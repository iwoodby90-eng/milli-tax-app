import { useEffect, useState, useCallback } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { usePlaidLink } from "react-plaid-link";
import { toast } from "sonner";
import { Bank, Plus, Trash, ArrowsClockwise } from "@phosphor-icons/react";

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
      toast.success(`+${data.synced} new deposits`);
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

  const total = deposits.reduce((s, d) => s + d.amount, 0);
  const savings = deposits.reduce((s, d) => s + d.savings_set_aside, 0);

  return (
    <div className="p-6 lg:p-10 max-w-7xl">
      <div className="flex justify-between items-end mb-8 flex-wrap gap-4">
        <div>
          <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Income</div>
          <h1 className="font-display font-black text-4xl tracking-tighter mt-1">Deposits</h1>
          <p className="text-zinc-400 mt-1">Bank-linked gig income · auto-detected.</p>
        </div>
        <div className="flex gap-2">
          <button
            data-testid="income-sync"
            onClick={syncAll}
            disabled={syncing || items.length === 0}
            className="px-4 py-2.5 border border-volt text-volt text-xs font-bold uppercase tracking-wider inline-flex items-center gap-2 hover:bg-volt hover:text-obsidian transition-colors disabled:opacity-50"
          >
            <ArrowsClockwise size={14} weight="bold" /> {syncing ? "Syncing" : "Sync"}
          </button>
          <button
            data-testid="income-add-manual"
            onClick={() => setShowManual(true)}
            className="px-4 py-2.5 border border-hairline text-xs font-bold uppercase tracking-wider hover:border-white inline-flex items-center gap-2"
          >
            <Plus size={14} weight="bold" /> Manual
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <Stat label="YTD Gross" value={money(total)} />
        <Stat label="Suggested savings" value={money(savings)} accent />
        <Stat label="Deposits" value={deposits.length} />
      </div>

      {/* Connected banks */}
      <div className="milli-card p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="font-display font-bold text-lg">Connected banks</div>
          <button
            onClick={startLink}
            disabled={loadingLink}
            data-testid="income-connect-bank"
            className="btn-volt px-4 py-2 text-xs font-bold uppercase tracking-wider inline-flex items-center gap-2 disabled:opacity-60"
          >
            <Bank size={14} weight="bold" /> {loadingLink ? "Loading..." : "Connect bank"}
          </button>
        </div>
        {items.length === 0 ? (
          <div className="text-center py-8 text-zinc-500 font-mono text-sm">[ NO BANKS CONNECTED ]</div>
        ) : (
          <div className="divide-y divide-hairline">
            {items.map((it) => (
              <div key={it.id} className="flex items-center justify-between py-3" data-testid={`bank-row-${it.id}`}>
                <div className="flex items-center gap-3">
                  <Bank size={20} className="text-volt" weight="bold" />
                  <div>
                    <div className="font-semibold">{it.institution_name}</div>
                    <div className="text-xs text-zinc-500 font-mono">Connected {it.created_at.slice(0, 10)}</div>
                  </div>
                </div>
                <button
                  onClick={() => removeItem(it.id)}
                  data-testid={`bank-remove-${it.id}`}
                  className="text-zinc-500 hover:text-danger p-2"
                ><Trash size={16} weight="bold" /></button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Deposit ledger */}
      <div className="milli-card p-6">
        <div className="font-display font-bold text-lg mb-4">Deposit ledger</div>
        {deposits.length === 0 ? (
          <div className="text-center py-12">
            <Bank size={40} className="text-zinc-700 mx-auto" weight="bold" />
            <div className="font-display font-bold mt-3">No deposits yet</div>
            <div className="text-sm text-zinc-500 mt-1">Connect a bank or add one manually.</div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="font-mono text-xs uppercase text-zinc-500 tracking-widest">
                <tr className="border-b border-hairline">
                  <th className="text-left py-2 px-2">Date</th>
                  <th className="text-left py-2 px-2">Platform</th>
                  <th className="text-left py-2 px-2">Merchant</th>
                  <th className="text-right py-2 px-2">Amount</th>
                  <th className="text-right py-2 px-2">Save</th>
                </tr>
              </thead>
              <tbody className="font-mono">
                {deposits.map((d) => (
                  <tr key={d.id} className="border-b border-hairline/60 hover:bg-white/5">
                    <td className="py-2.5 px-2 text-zinc-400">{d.date}</td>
                    <td className="py-2.5 px-2">
                      <span className="inline-block px-2 py-0.5 bg-volt/20 text-volt text-xs">{d.platform}</span>
                    </td>
                    <td className="py-2.5 px-2 text-zinc-400">{d.merchant}</td>
                    <td className="py-2.5 px-2 text-right font-bold text-success">+{money(d.amount)}</td>
                    <td className="py-2.5 px-2 text-right text-zinc-400">{money(d.savings_set_aside)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showManual && <ManualDepositDialog onClose={() => setShowManual(false)} onSaved={() => { setShowManual(false); load(); }} />}
    </div>
  );
}

function Stat({ label, value, accent }) {
  return (
    <div className="milli-card p-5">
      <div className="text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500">{label}</div>
      <div className={`font-display font-black text-3xl mt-2 ${accent ? "text-volt" : ""}`}>{value}</div>
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
      toast.success("Deposit added");
      onSaved();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display font-bold text-xl mb-4">Add manual deposit</div>
        <div className="space-y-3">
          <Input label="Date" type="date" value={form.date} onChange={(v) => setForm({ ...form, date: v })} id="manual-deposit-date" />
          <Input label="Amount ($)" type="number" step="0.01" value={form.amount} onChange={(v) => setForm({ ...form, amount: v })} id="manual-deposit-amount" />
          <Select label="Platform" value={form.platform} onChange={(v) => setForm({ ...form, platform: v })} id="manual-deposit-platform" options={["Uber", "DoorDash", "Spark", "Lyft", "Instacart", "Amazon Flex", "Grubhub", "Shipt", "Other"]} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid="manual-deposit-save" onClick={save} disabled={busy || !form.amount} className="flex-1 btn-volt px-4 py-2.5 text-xs font-bold uppercase tracking-wider disabled:opacity-50">{busy ? "Saving..." : "Save"}</button>
        </div>
      </div>
    </div>
  );
}

function Input({ label, id, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <input
        id={id}
        data-testid={id}
        onChange={(e) => onChange(e.target.value)}
        {...props}
        className="w-full bg-transparent border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt"
      />
    </div>
  );
}

function Select({ label, id, value, onChange, options }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <select
        id={id}
        data-testid={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full bg-obsidian border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt"
      >
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
    </div>
  );
}
