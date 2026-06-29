import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ShieldCheck, ArrowDown, ArrowUp, Plus, Pause, Play, Sparkle, Info, LockKey, Bank, CaretRight,
} from "@phosphor-icons/react";

export default function Vault() {
  const { user, refresh } = useAuth();
  const [vault, setVault] = useState(null);
  const [summary, setSummary] = useState(null);
  const [busy, setBusy] = useState(false);
  const [transferOpen, setTransferOpen] = useState(null); // 'in' | 'out' | null
  const [ruleOpen, setRuleOpen] = useState(false);

  async function load() {
    try {
      const [v, s] = await Promise.all([api.get("/vault"), api.get("/tax/summary")]);
      setVault(v.data); setSummary(s.data);
    } catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  async function setup() {
    setBusy(true);
    try {
      await api.post("/vault/setup", {});
      toast.success("Tax Vault opened");
      await load(); await refresh();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  async function togglePause() {
    if (!vault) return;
    const paused = !vault.rule?.paused;
    try {
      await api.put("/vault/rule", { paused });
      toast.success(paused ? "Auto-reserve paused" : "Auto-reserve resumed");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  // Setup flow if no vault
  if (vault === null || vault === undefined) {
    return <div className="p-12 font-mono text-volt animate-pulse">[ LOADING VAULT... ]</div>;
  }

  if (!vault) {
    return (
      <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-3xl mx-auto">
        <Header />
        <div className="milli-card p-8 text-center" data-testid="vault-empty-state">
          <div className="w-16 h-16 mx-auto mb-5 rounded-2xl bg-volt/10 border border-volt/40 flex items-center justify-center">
            <ShieldCheck size={32} weight="duotone" className="text-volt" />
          </div>
          <div className="font-display text-2xl mb-2">Your savings account. Your tax money.</div>
          <div className="text-zinc-400 text-sm mb-6 max-w-md mx-auto leading-relaxed">
            The Tax Vault is a <strong className="text-white">user-owned savings account</strong> you set up through our banking partner.
            Each time a payout from Uber, DoorDash, Spark, or any gig platform hits your checking account,
            Milli automatically transfers a tax % into your Vault — so the money is there when the IRS asks.
          </div>
          <div className="grid sm:grid-cols-2 gap-3 max-w-md mx-auto">
            <button
              onClick={setup}
              disabled={busy}
              data-testid="vault-setup-btn"
              className="btn-volt px-4 py-3 uppercase tracking-wider text-xs disabled:opacity-50 inline-flex items-center justify-center gap-2"
            >
              <Bank size={14} weight="bold" /> {busy ? "Opening..." : "Open Milli Reserve"}
            </button>
            <button
              disabled
              title="Coming soon"
              data-testid="vault-connect-existing"
              className="btn-outline-cyan px-4 py-3 uppercase tracking-wider text-xs font-semibold opacity-60 cursor-not-allowed"
            >
              Connect existing savings
            </button>
          </div>
          <div className="mt-6 text-[10px] text-zinc-500 max-w-md mx-auto leading-relaxed">
            <Info size={10} className="inline mr-1" /> Banking partner: Demo Reserve Bank (sandbox).
            You own the account — Milli initiates transfers on your behalf with read-write access you authorize.
            FDIC + partner-specific disclosures will be shown when connected to a production partner.
          </div>
        </div>
      </div>
    );
  }

  const annualTarget = summary?.estimated_tax || 0;
  const coverage = annualTarget ? Math.min(100, Math.round((vault.balance / annualTarget) * 100)) : 0;
  const rule = vault.rule || {};

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-4xl mx-auto">
      <Header />

      {/* Vault balance card */}
      <div className="milli-card-strong p-7 mb-4 relative overflow-hidden" data-testid="vault-balance-card">
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-volt to-transparent" />
        <div className="flex items-start justify-between flex-wrap gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2">
              <LockKey size={14} weight="bold" className="text-volt" />
              <span className="text-volt text-xs font-semibold uppercase tracking-[0.2em]">Milli Tax Vault</span>
            </div>
            <div className="chrome-text font-chrome font-bold text-5xl sm:text-6xl tabular-nums" data-testid="vault-balance">
              {money(vault.balance)}
            </div>
            <div className="text-zinc-400 text-sm mt-3">
              Reserved this year · {coverage}% of estimated {money(annualTarget)} annual taxes
            </div>
            <div className="mt-3 h-1.5 bg-white/5 rounded-full overflow-hidden max-w-md">
              <div className="h-full bg-gradient-to-r from-volt to-volt/60 rounded-full transition-all" style={{ width: `${coverage}%` }} />
            </div>
          </div>
          <div className="flex flex-col items-end gap-2">
            <div className="text-xs text-zinc-500 font-mono uppercase tracking-widest">Interest YTD</div>
            <div className="text-success font-chrome font-bold text-2xl">{money(vault.interest_earned_ytd)}</div>
          </div>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-7">
          <button data-testid="vault-add" onClick={() => setTransferOpen("in")} className="btn-volt px-4 py-3 text-xs uppercase tracking-wider inline-flex items-center justify-center gap-1.5">
            <ArrowDown size={14} weight="bold" /> Add
          </button>
          <button data-testid="vault-withdraw" onClick={() => setTransferOpen("out")} className="btn-outline-cyan px-4 py-3 text-xs uppercase tracking-wider font-semibold inline-flex items-center justify-center gap-1.5">
            <ArrowUp size={14} weight="bold" /> Withdraw
          </button>
          <button data-testid="vault-rule" onClick={() => setRuleOpen(true)} className="btn-outline-cyan px-4 py-3 text-xs uppercase tracking-wider font-semibold inline-flex items-center justify-center gap-1.5">
            <Sparkle size={14} weight="bold" /> Auto-Reserve
          </button>
          <button data-testid="vault-pause" onClick={togglePause} className="btn-outline-cyan px-4 py-3 text-xs uppercase tracking-wider font-semibold inline-flex items-center justify-center gap-1.5">
            {rule.paused ? <><Play size={14} weight="bold" /> Resume</> : <><Pause size={14} weight="bold" /> Pause</>}
          </button>
        </div>
      </div>

      {/* Account details */}
      <div className="milli-card p-5 mb-4">
        <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em] mb-3">Account Details</div>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <Detail label="Account type" value="User-owned savings" />
          <Detail label="Owner" value={user?.name || "—"} />
          <Detail label="Bank partner" value={vault.institution_name} />
          <Detail label="Nickname" value={vault.account_nickname} />
          <Detail label="Account" value={vault.account_number_masked} mono />
          <Detail label="Routing" value={vault.routing_number_masked} mono />
          <Detail label="Strategy" value={(rule.strategy || "balanced").toUpperCase()} />
          <Detail label="Auto-pull per payout" value={`${Math.round((rule.fixed_percentage ?? 0.25) * 100)}%`} />
        </div>
        <div className="mt-4 text-[10px] text-zinc-500 leading-relaxed flex gap-2">
          <Info size={12} className="flex-shrink-0 mt-0.5" />
          <span>This savings account is yours. Milli is a technology platform — not a bank.
            Funds are held at our banking partner under your name. Each detected payout
            triggers an automatic transfer of your selected tax % from your checking account into this Vault.
            FDIC and partner-specific disclosures will be displayed when connected to a production partner.</span>
        </div>
      </div>

      {/* Recent transfers */}
      <div className="milli-card p-5">
        <div className="flex items-center justify-between mb-3">
          <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em]">Recent Transfers</div>
          <div className="text-xs text-zinc-500 font-mono">{vault.transfers?.length || 0} total</div>
        </div>
        {(vault.transfers || []).length === 0 ? (
          <div className="text-center py-8 text-sm text-zinc-500">No transfers yet.</div>
        ) : (
          <div className="divide-y divide-hairline/60">
            {(vault.transfers || []).slice(0, 12).map((t) => (
              <div key={t.id} className="flex items-center justify-between py-3" data-testid={`vault-transfer-${t.id}`}>
                <div className="flex items-center gap-3">
                  {t.direction === "in"
                    ? <ArrowDown size={18} weight="bold" className="text-success" />
                    : <ArrowUp size={18} weight="bold" className="text-warning" />}
                  <div>
                    <div className="font-medium text-sm">{t.note}</div>
                    <div className="text-xs text-zinc-500 font-mono">{(t.created_at || "").slice(0, 10)} · {t.source}</div>
                  </div>
                </div>
                <div className={`font-mono font-bold ${t.direction === "in" ? "text-success" : "text-warning"}`}>
                  {t.direction === "in" ? "+" : "−"}{money(t.amount)}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {transferOpen && <TransferDialog dir={transferOpen} maxOut={vault.balance} onClose={() => setTransferOpen(null)} onDone={() => { setTransferOpen(null); load(); refresh(); }} />}
      {ruleOpen && <RuleDialog rule={rule} onClose={() => setRuleOpen(false)} onDone={() => { setRuleOpen(false); load(); }} />}
    </div>
  );
}

function Header() {
  return (
    <div className="mb-6">
      <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Tax Vault · User-owned savings</div>
      <h1 className="font-display text-3xl sm:text-4xl tracking-tight mt-1 chrome-text">Your tax money lives here.</h1>
      <p className="text-zinc-400 mt-1 text-sm">A savings account you own. Milli auto-pulls the tax % from every payout.</p>
    </div>
  );
}

function Detail({ label, value, mono }) {
  return (
    <div>
      <div className="text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</div>
      <div className={`${mono ? "font-mono" : ""} text-sm font-semibold`}>{value}</div>
    </div>
  );
}

function TransferDialog({ dir, maxOut, onClose, onDone }) {
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);

  async function save() {
    setBusy(true);
    try {
      await api.post("/vault/transfer", { amount: parseFloat(amount), direction: dir, note });
      toast.success(`${dir === "in" ? "Added to" : "Withdrew from"} Tax Vault`);
      onDone();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display text-xl mb-4">{dir === "in" ? "Add to Vault" : "Withdraw from Vault"}</div>
        {dir === "out" && <div className="text-xs text-zinc-500 mb-3">Available: {money(maxOut)}</div>}
        <div className="space-y-3">
          <Input id="vault-amount" label="Amount ($)" type="number" step="0.01" value={amount} onChange={(v) => setAmount(v)} />
          <Input id="vault-note" label="Note (optional)" value={note} onChange={(v) => setNote(v)} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline rounded-xl text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid="vault-transfer-save" onClick={save} disabled={busy || !amount} className="flex-1 btn-volt px-4 py-2.5 text-xs uppercase tracking-wider disabled:opacity-50">{busy ? "..." : "Confirm"}</button>
        </div>
      </div>
    </div>
  );
}

function RuleDialog({ rule, onClose, onDone }) {
  const [form, setForm] = useState({
    mode: rule.mode || "auto",
    strategy: rule.strategy || "balanced",
    fixed_percentage: rule.fixed_percentage ?? "",
    min_checking_balance: rule.min_checking_balance ?? 200,
    max_daily_transfer: rule.max_daily_transfer ?? 1000,
  });
  const [busy, setBusy] = useState(false);
  async function save() {
    setBusy(true);
    try {
      const body = {
        mode: form.mode,
        strategy: form.strategy,
        fixed_percentage: form.fixed_percentage === "" ? null : parseFloat(form.fixed_percentage),
        min_checking_balance: parseFloat(form.min_checking_balance),
        max_daily_transfer: parseFloat(form.max_daily_transfer),
      };
      await api.put("/vault/rule", body);
      toast.success("Rules saved");
      onDone();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display text-xl mb-4">Auto-Reserve Rules</div>
        <div className="space-y-3">
          <Select id="rule-mode" label="Mode" value={form.mode} onChange={(v) => setForm({ ...form, mode: v })}
            options={[["auto", "Automatic"], ["approval", "Approval required"], ["manual", "Manual only"]]} />
          <Select id="rule-strategy" label="Strategy" value={form.strategy} onChange={(v) => setForm({ ...form, strategy: v })}
            options={[["conservative", "Conservative · 30%"], ["balanced", "Balanced · 25%"], ["minimum", "Minimum · 20%"]]} />
          <Input id="rule-fixed-pct" label="Override % (0.0–1.0, blank = use strategy)" value={form.fixed_percentage} onChange={(v) => setForm({ ...form, fixed_percentage: v })} />
          <Input id="rule-min-bal" label="Min checking balance ($)" type="number" value={form.min_checking_balance} onChange={(v) => setForm({ ...form, min_checking_balance: v })} />
          <Input id="rule-max-daily" label="Max daily transfer ($)" type="number" value={form.max_daily_transfer} onChange={(v) => setForm({ ...form, max_daily_transfer: v })} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline rounded-xl text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid="rule-save" onClick={save} disabled={busy} className="flex-1 btn-volt px-4 py-2.5 text-xs uppercase tracking-wider disabled:opacity-50">{busy ? "..." : "Save rules"}</button>
        </div>
      </div>
    </div>
  );
}

function Input({ id, label, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</label>
      <input id={id} data-testid={id} onChange={(e) => onChange(e.target.value)} {...props}
        className="w-full bg-obsidian/60 border border-hairline rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-volt" />
    </div>
  );
}

function Select({ id, label, value, onChange, options }) {
  return (
    <div>
      <label className="block text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</label>
      <select id={id} data-testid={id} value={value} onChange={(e) => onChange(e.target.value)}
        className="w-full bg-obsidian/60 border border-hairline rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-volt">
        {options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
      </select>
    </div>
  );
}
