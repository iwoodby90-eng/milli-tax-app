/**
 * Generic auto-allocate account UI used by 401(k) Retirement and Investing pages.
 * Mirrors the Vault page but driven by config + the /api/smart/{kind} endpoints.
 */
import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  ArrowDown, ArrowUp, Pause, Play, Sparkle, Info, Bank,
} from "@phosphor-icons/react";

export default function SmartAccount({ kind, config }) {
  const { user } = useAuth();
  const [acct, setAcct] = useState(undefined);
  const [busy, setBusy] = useState(false);
  const [transferOpen, setTransferOpen] = useState(null);
  const [ruleOpen, setRuleOpen] = useState(false);

  async function load() {
    try {
      const { data } = await api.get(`/smart/${kind}`);
      setAcct(data);
    } catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, [kind]);

  async function setup() {
    setBusy(true);
    try { await api.post(`/smart/${kind}/setup`, {}); toast.success(`${config.title} opened`); await load(); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  async function togglePause() {
    if (!acct) return;
    try {
      await api.put(`/smart/${kind}/rule`, { paused: !acct.rule?.paused });
      toast.success(acct.rule?.paused ? "Auto-contribute resumed" : "Auto-contribute paused");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  if (acct === undefined) {
    return <div className="p-12 font-mono text-volt animate-pulse">[ LOADING {config.title.toUpperCase()}... ]</div>;
  }

  if (!acct) {
    return (
      <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-3xl mx-auto">
        <Header config={config} />
        <div className="milli-card p-8 text-center" data-testid={`${kind}-empty`}>
          <div className="w-16 h-16 mx-auto mb-5 rounded-2xl bg-volt/10 border border-volt/40 flex items-center justify-center">
            <config.icon size={32} weight="duotone" className="text-volt" />
          </div>
          <div className="font-display text-2xl mb-2">{config.emptyTitle}</div>
          <div className="text-zinc-400 text-sm mb-6 max-w-md mx-auto leading-relaxed">{config.emptyBody}</div>
          <button
            onClick={setup}
            disabled={busy}
            data-testid={`${kind}-setup-btn`}
            className="btn-volt px-6 py-3 uppercase tracking-wider text-xs inline-flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <Bank size={14} weight="bold" /> {busy ? "Opening..." : config.setupCta}
          </button>
          <div className="mt-6 text-[10px] text-zinc-500 max-w-md mx-auto leading-relaxed">
            <Info size={10} className="inline mr-1" /> {config.disclaimer}
          </div>
        </div>
      </div>
    );
  }

  const rule = acct.rule || {};
  const pct = Math.round((rule.fixed_percentage ?? config.defaultPct) * 100);

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-4xl mx-auto">
      <Header config={config} />

      <div className="milli-card-strong p-7 mb-4 relative overflow-hidden" data-testid={`${kind}-balance-card`}>
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-volt to-transparent" />
        <div className="flex items-start justify-between flex-wrap gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2">
              <config.icon size={14} weight="bold" className="text-volt" />
              <span className="text-volt text-xs font-semibold uppercase tracking-[0.2em]">{config.title}</span>
            </div>
            <div className="chrome-text font-chrome font-bold text-5xl sm:text-6xl tabular-nums" data-testid={`${kind}-balance`}>
              {money(acct.balance)}
            </div>
            <div className="text-zinc-400 text-sm mt-3">
              {pct}% of every detected payout · {rule.paused ? <span className="text-warning">paused</span> : <span className="text-success">active</span>}
            </div>
          </div>
          <div className="flex flex-col items-end gap-2">
            <div className="text-xs text-zinc-500 font-mono uppercase tracking-widest">YTD Growth</div>
            <div className="text-success font-chrome font-bold text-2xl">{money(acct.ytd_growth || 0)}</div>
          </div>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-7">
          <button data-testid={`${kind}-add`} onClick={() => setTransferOpen("in")} className="btn-volt px-2 py-2.5 text-[10px] uppercase tracking-[0.08em] inline-flex items-center justify-center gap-1 whitespace-nowrap">
            <ArrowDown size={12} weight="bold" /> Contribute
          </button>
          <button data-testid={`${kind}-withdraw`} onClick={() => setTransferOpen("out")} className="btn-outline-cyan px-2 py-2.5 text-[10px] uppercase tracking-[0.08em] font-semibold inline-flex items-center justify-center gap-1 whitespace-nowrap">
            <ArrowUp size={12} weight="bold" /> Withdraw
          </button>
          <button data-testid={`${kind}-rule`} onClick={() => setRuleOpen(true)} className="btn-outline-cyan px-2 py-2.5 text-[10px] uppercase tracking-[0.08em] font-semibold inline-flex items-center justify-center gap-1 whitespace-nowrap">
            <Sparkle size={12} weight="bold" /> Auto-Rule
          </button>
          <button data-testid={`${kind}-pause`} onClick={togglePause} className="btn-outline-cyan px-2 py-2.5 text-[10px] uppercase tracking-[0.08em] font-semibold inline-flex items-center justify-center gap-1 whitespace-nowrap">
            {rule.paused ? <><Play size={12} weight="bold" /> Resume</> : <><Pause size={12} weight="bold" /> Pause</>}
          </button>
        </div>
      </div>

      <div className="milli-card p-5 mb-4">
        <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em] mb-3">Account Details</div>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <Detail label="Account type" value={config.accountType} />
          <Detail label="Owner" value={user?.name || "—"} />
          <Detail label="Partner" value={acct.institution_name} />
          <Detail label="Nickname" value={acct.account_nickname} />
          <Detail label="Account" value={acct.account_number_masked} mono />
          <Detail label="Auto-contribute" value={`${pct}% per payout`} />
        </div>
        <div className="mt-4 text-[10px] text-zinc-500 leading-relaxed flex gap-2">
          <Info size={12} className="flex-shrink-0 mt-0.5" />
          <span>{config.legal}</span>
        </div>
      </div>

      <div className="milli-card p-5">
        <div className="flex items-center justify-between mb-3">
          <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em]">Contributions</div>
          <div className="text-xs text-zinc-500 font-mono">{acct.transfers?.length || 0} total</div>
        </div>
        {(acct.transfers || []).length === 0 ? (
          <div className="text-center py-8 text-sm text-zinc-500">No contributions yet.</div>
        ) : (
          <div className="divide-y divide-hairline/60">
            {(acct.transfers || []).slice(0, 12).map((t) => (
              <div key={t.id} className="flex items-center justify-between py-3" data-testid={`${kind}-tx-${t.id}`}>
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

      {transferOpen && <TxDialog kind={kind} dir={transferOpen} maxOut={acct.balance} onClose={() => setTransferOpen(null)} onDone={() => { setTransferOpen(null); load(); }} />}
      {ruleOpen && <RuleDialog kind={kind} rule={rule} defaultPct={config.defaultPct} onClose={() => setRuleOpen(false)} onDone={() => { setRuleOpen(false); load(); }} />}
    </div>
  );
}

function Header({ config }) {
  return (
    <div className="mb-6">
      <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// {config.section}</div>
      <h1 className="font-display text-3xl sm:text-4xl tracking-tight mt-1 chrome-text">{config.heading}</h1>
      <p className="text-zinc-400 mt-1 text-sm">{config.sub}</p>
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

function TxDialog({ kind, dir, maxOut, onClose, onDone }) {
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  async function save() {
    setBusy(true);
    try {
      await api.post(`/smart/${kind}/transfer`, { amount: parseFloat(amount), direction: dir, note });
      toast.success(dir === "in" ? "Contribution added" : "Withdrawal complete");
      onDone();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }
  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display text-xl mb-4">{dir === "in" ? "Add contribution" : "Withdraw funds"}</div>
        {dir === "out" && <div className="text-xs text-zinc-500 mb-3">Available: {money(maxOut)}</div>}
        <Input id={`${kind}-amount`} label="Amount ($)" type="number" step="0.01" value={amount} onChange={(v) => setAmount(v)} />
        <div className="h-3" />
        <Input id={`${kind}-note`} label="Note (optional)" value={note} onChange={(v) => setNote(v)} />
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline rounded-xl text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid={`${kind}-tx-save`} onClick={save} disabled={busy || !amount} className="flex-1 btn-volt px-4 py-2.5 text-xs uppercase tracking-wider disabled:opacity-50">{busy ? "..." : "Confirm"}</button>
        </div>
      </div>
    </div>
  );
}

function RuleDialog({ kind, rule, defaultPct, onClose, onDone }) {
  const [form, setForm] = useState({
    mode: rule.mode || "auto",
    fixed_percentage: ((rule.fixed_percentage ?? defaultPct) * 100).toFixed(1),
    max_daily_transfer: rule.max_daily_transfer ?? 500,
  });
  const [busy, setBusy] = useState(false);
  async function save() {
    setBusy(true);
    try {
      await api.put(`/smart/${kind}/rule`, {
        mode: form.mode,
        fixed_percentage: parseFloat(form.fixed_percentage) / 100,
        max_daily_transfer: parseFloat(form.max_daily_transfer),
      });
      toast.success("Rule saved");
      onDone();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }
  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display text-xl mb-4">Auto-contribute rule</div>
        <div className="space-y-3">
          <Select id={`${kind}-rule-mode`} label="Mode" value={form.mode} onChange={(v) => setForm({ ...form, mode: v })}
            options={[["auto", "Automatic per payout"], ["manual", "Manual only"]]} />
          <Input id={`${kind}-rule-pct`} label="% of each payout" type="number" step="0.1" value={form.fixed_percentage} onChange={(v) => setForm({ ...form, fixed_percentage: v })} />
          <Input id={`${kind}-rule-max`} label="Max daily transfer ($)" type="number" value={form.max_daily_transfer} onChange={(v) => setForm({ ...form, max_daily_transfer: v })} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline rounded-xl text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid={`${kind}-rule-save`} onClick={save} disabled={busy} className="flex-1 btn-volt px-4 py-2.5 text-xs uppercase tracking-wider disabled:opacity-50">{busy ? "..." : "Save"}</button>
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
