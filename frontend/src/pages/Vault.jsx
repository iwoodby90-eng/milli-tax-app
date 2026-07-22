import { useEffect, useState, useCallback } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { usePlaidLink } from "react-plaid-link";
import { toast } from "sonner";
import {
  ShieldCheck, ArrowDown, ArrowUp, Pause, Play, Sparkle, Info, LockKey, Bank, Plug,
} from "@phosphor-icons/react";

export default function Vault() {
  const { user, refresh } = useAuth();
  const [vault, setVault] = useState(undefined);
  const [summary, setSummary] = useState(null);
  const [busy, setBusy] = useState(false);
  const [transferOpen, setTransferOpen] = useState(null);
  const [ruleOpen, setRuleOpen] = useState(false);
  const [linkToken, setLinkToken] = useState(null);
  const [loadingLink, setLoadingLink] = useState(false);

  async function load() {
    try {
      const [v, s] = await Promise.all([api.get("/vault"), api.get("/tax/summary")]);
      setVault(v.data); setSummary(s.data);
    } catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  async function setupMilliReserve() {
    setBusy(true);
    try {
      await api.post("/vault/setup", {});
      toast.success("Milli Reserve vault opened");
      await load(); await refresh();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  async function startPlaidConnect() {
    setLoadingLink(true);
    try {
      const { data } = await api.post("/plaid/link-token");
      setLinkToken(data.link_token);
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setLoadingLink(false); }
  }

  const onPlaidSuccess = useCallback(async (public_token, metadata) => {
    try {
      // Prefer a savings account; fall back to first depository account.
      const accts = metadata?.accounts || [];
      const savings = accts.find((a) => a.subtype === "savings") || accts[0];
      await api.post("/vault/connect-plaid", {
        public_token,
        institution_name: metadata?.institution?.name || "Connected Bank",
        account_id: savings?.id,
        account_name: savings?.name,
        account_mask: savings?.mask,
        account_subtype: savings?.subtype,
      });
      toast.success(`${savings?.name || "Savings account"} connected as Tax Vault`);
      setLinkToken(null);
      await load(); await refresh();
    } catch (e) { toast.error(formatApiError(e)); }
  }, []);

  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: onPlaidSuccess,
    onExit: () => setLinkToken(null),
  });

  useEffect(() => { if (linkToken && ready) open(); }, [linkToken, ready, open]);

  async function togglePause() {
    if (!vault) return;
    const paused = !vault.rule?.paused;
    try {
      await api.put("/vault/rule", { paused });
      toast.success(paused ? "Auto-reserve paused" : "Auto-reserve resumed");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  if (vault === undefined) {
    return (
      <div className="p-10 font-mono text-volt text-xs uppercase tracking-[0.3em] animate-pulse">
        Loading vault…
      </div>
    );
  }

  if (!vault) {
    return (
      <div className="px-5 py-6 max-w-[440px] mx-auto" data-testid="vault-empty-state">
        <Header />

        {/* Hero card */}
        <div
          className="mt-4 rounded-3xl overflow-hidden"
          style={{
            background:
              "linear-gradient(180deg, rgba(0,229,255,0.06) 0%, rgba(255,255,255,0) 100%)",
            border: "1px solid rgba(0,229,255,0.28)",
            boxShadow:
              "0 0 24px rgba(0,229,255,0.14), inset 0 1px 0 rgba(255,255,255,0.05)",
          }}
        >
          <div className="p-6 text-center">
            <div className="w-16 h-16 mx-auto mb-4 rounded-2xl flex items-center justify-center"
                 style={{
                   background: "linear-gradient(180deg, rgba(0,229,255,0.15), rgba(0,229,255,0.03))",
                   border: "1px solid rgba(0,229,255,0.45)",
                   boxShadow: "0 0 18px rgba(0,229,255,0.28)",
                 }}>
              <LockKey size={28} weight="duotone" className="text-volt" />
            </div>
            <h2 className="font-display font-black chrome-text text-[24px] leading-[1.1] tracking-tight">
              Your tax money.<br />Held in your name.
            </h2>
            <p className="text-zinc-400 text-[13.5px] mt-3 leading-relaxed">
              A user-owned savings account. Milli auto-pulls your reserve % from every payout — you keep full control.
            </p>
          </div>

          {/* Two full-width iOS-style option cards, stacked */}
          <div className="px-4 pb-4 flex flex-col gap-2.5">
            <button
              onClick={startPlaidConnect}
              disabled={loadingLink}
              data-testid="vault-connect-plaid"
              className="w-full flex items-center gap-3 rounded-2xl p-4 text-left active:scale-[0.985] transition-transform disabled:opacity-60"
              style={{
                background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
                color: "#001217",
                boxShadow: "0 0 22px rgba(0,229,255,0.4), 0 0 50px rgba(0,229,255,0.18)",
              }}
            >
              <div className="w-10 h-10 rounded-xl bg-black/15 flex items-center justify-center flex-shrink-0">
                <Plug size={18} weight="bold" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-bold text-[14px] uppercase tracking-[0.14em] leading-none">
                  {loadingLink ? "Opening Plaid…" : "Connect via Plaid"}
                </div>
                <div className="text-[11px] mt-1 opacity-80">
                  Link your Ally, Marcus, Capital One 360 or any bank
                </div>
              </div>
              <ArrowUp size={14} weight="bold" className="rotate-45 flex-shrink-0" />
            </button>

            <button
              onClick={setupMilliReserve}
              disabled={busy}
              data-testid="vault-setup-btn"
              className="w-full flex items-center gap-3 rounded-2xl p-4 text-left active:scale-[0.985] transition-transform disabled:opacity-60"
              style={{
                background: "linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0))",
                border: "1px solid rgba(192,192,192,0.22)",
              }}
            >
              <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                   style={{
                     background: "linear-gradient(180deg, rgba(0,229,255,0.10), rgba(0,229,255,0.02))",
                     border: "1px solid rgba(0,229,255,0.35)",
                   }}>
                <Bank size={18} weight="duotone" className="text-volt" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-bold text-white text-[14px] uppercase tracking-[0.14em] leading-none">
                  {busy ? "Opening…" : "Open a Milli Reserve"}
                </div>
                <div className="text-[11px] text-zinc-400 mt-1">
                  New high-yield savings via our banking partner
                </div>
              </div>
              <ArrowUp size={14} weight="bold" className="rotate-45 text-zinc-500 flex-shrink-0" />
            </button>
          </div>
        </div>

        {/* Disclosure — larger, well-spaced */}
        <div className="mt-5 mx-1 rounded-2xl p-4"
             style={{
               background: "rgba(255,255,255,0.025)",
               border: "1px solid rgba(255,255,255,0.06)",
             }}>
          <div className="flex items-start gap-2">
            <Info size={13} className="text-zinc-500 flex-shrink-0 mt-0.5" />
            <p className="text-[11.5px] text-zinc-400 leading-[1.55]">
              Plaid uses read-only connections by default — you own the account. Milli is a technology platform, not a bank.
              FDIC and partner-specific disclosures appear once a production banking partner is connected.
            </p>
          </div>
        </div>
      </div>
    );
  }

  const annualTarget = summary?.estimated_tax || 0;
  const coverage = annualTarget ? Math.min(100, Math.round((vault.balance / annualTarget) * 100)) : 0;
  const rule = vault.rule || {};
  const isPlaid = vault.provider_type === "plaid_connected";

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-4xl mx-auto">
      <Header />

      <div className="milli-card-strong p-5 sm:p-7 mb-4 relative overflow-hidden" data-testid="vault-balance-card">
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-volt to-transparent" />
        <div className="flex items-start justify-between gap-3 flex-wrap">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2 flex-wrap">
              <LockKey size={14} weight="bold" className="text-volt flex-shrink-0" />
              <span className="text-volt text-[10px] font-semibold uppercase tracking-[0.2em]">Milli Tax Vault</span>
              {isPlaid && (
                <span className="px-2 py-0.5 rounded-full bg-success/20 text-success text-[9px] font-bold uppercase tracking-wider whitespace-nowrap">
                  Plaid&nbsp;·&nbsp;Live
                </span>
              )}
            </div>
            <div
              className="chrome-text font-chrome font-bold tabular-nums leading-none break-all"
              style={{ fontSize: "clamp(28px, 9vw, 48px)" }}
              data-testid="vault-balance"
            >
              {money(vault.balance)}
            </div>
            <div className="text-zinc-400 text-[12px] mt-3 leading-relaxed">
              Reserved this year · <span className="tabular-nums">{coverage}%</span> of estimated{" "}
              <span className="text-white/80 font-medium tabular-nums">{money(annualTarget)}</span> tax
            </div>
            <div className="mt-3 h-1.5 bg-white/5 rounded-full overflow-hidden max-w-md">
              <div className="h-full bg-gradient-to-r from-volt to-volt/60 rounded-full transition-all" style={{ width: `${coverage}%` }} />
            </div>
          </div>
          <div className="flex flex-col items-end gap-1 flex-shrink-0">
            <div className="text-[9px] text-zinc-500 font-mono uppercase tracking-widest">Interest YTD</div>
            <div className="text-success font-chrome font-bold text-[18px] tabular-nums">{money(vault.interest_earned_ytd)}</div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-2 mt-6">
          <button data-testid="vault-add" onClick={() => setTransferOpen("in")}
            className="btn-volt px-3 py-3 text-[11px] uppercase tracking-[0.14em] inline-flex items-center justify-center gap-1.5 min-w-0">
            <ArrowDown size={13} weight="bold" className="flex-shrink-0" /> <span className="truncate">Add</span>
          </button>
          <button data-testid="vault-withdraw" onClick={() => setTransferOpen("out")}
            className="btn-outline-cyan px-3 py-3 text-[11px] uppercase tracking-[0.14em] font-semibold inline-flex items-center justify-center gap-1.5 min-w-0">
            <ArrowUp size={13} weight="bold" className="flex-shrink-0" /> <span className="truncate">Withdraw</span>
          </button>
          <button data-testid="vault-rule" onClick={() => setRuleOpen(true)}
            className="btn-outline-cyan px-3 py-3 text-[11px] uppercase tracking-[0.14em] font-semibold inline-flex items-center justify-center gap-1.5 min-w-0">
            <Sparkle size={13} weight="bold" className="flex-shrink-0" /> <span className="truncate">Auto rule</span>
          </button>
          <button data-testid="vault-pause" onClick={togglePause}
            className="btn-outline-cyan px-3 py-3 text-[11px] uppercase tracking-[0.14em] font-semibold inline-flex items-center justify-center gap-1.5 min-w-0">
            {rule.paused
              ? <><Play size={13} weight="bold" className="flex-shrink-0" /> <span className="truncate">Resume</span></>
              : <><Pause size={13} weight="bold" className="flex-shrink-0" /> <span className="truncate">Pause</span></>}
          </button>
        </div>
      </div>

      <div className="milli-card p-5 mb-4">
        <div className="text-volt text-[10px] font-semibold uppercase tracking-[0.2em] mb-3">Account Details</div>
        <div className="space-y-3">
          <Detail label="Account type" value={isPlaid ? "Plaid-connected savings" : "Milli Reserve savings"} />
          <Detail label="Owner" value={user?.name || "—"} />
          <Detail label="Bank" value={vault.institution_name} />
          <Detail label="Nickname" value={vault.account_nickname} />
          <Detail label="Account" value={vault.account_number_masked} mono />
          {!isPlaid && <Detail label="Routing" value={vault.routing_number_masked} mono />}
          <Detail label="Strategy" value={(rule.strategy || "balanced").toUpperCase()} />
          <Detail label="Auto-pull per payout" value={`${Math.round((rule.fixed_percentage ?? 0.25) * 100)}%`} />
        </div>
        <div className="mt-4 text-[10px] text-zinc-500 leading-relaxed flex gap-2">
          <Info size={12} className="flex-shrink-0 mt-0.5" />
          <span>
            {isPlaid
              ? "This savings account is held at your bank, in your name. Milli uses Plaid for read-only balance + transaction access. Auto-pulls require a separate Plaid Transfer authorization (coming soon — production approval pending)."
              : "This savings account is yours — held at our banking partner under your name. Milli is a technology platform, not a bank. FDIC + partner disclosures will be shown when a production partner is connected."}
          </span>
        </div>
      </div>

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
    <div className="flex items-baseline justify-between gap-3 py-0.5">
      <div className="text-[11px] uppercase tracking-[0.18em] text-zinc-500 flex-shrink-0">{label}</div>
      <div className={`${mono ? "font-mono" : ""} text-[13px] font-semibold text-white text-right truncate min-w-0`} title={String(value ?? "")}>
        {value || "—"}
      </div>
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
      await api.put("/vault/rule", {
        mode: form.mode,
        strategy: form.strategy,
        fixed_percentage: form.fixed_percentage === "" ? null : parseFloat(form.fixed_percentage),
        min_checking_balance: parseFloat(form.min_checking_balance),
        max_daily_transfer: parseFloat(form.max_daily_transfer),
      });
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
