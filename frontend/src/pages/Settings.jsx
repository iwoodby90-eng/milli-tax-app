import { useEffect, useState } from "react";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ShieldCheck, Sparkle, ChartLineUp } from "@phosphor-icons/react";
import BankConnections from "@/components/BankConnections";
import ManageSubscription from "@/components/ManageSubscription";

const STATES = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"];

export default function Settings() {
  const { user, refresh } = useAuth();
  const [form, setForm] = useState({
    name: user?.name || "",
    state: user?.state || "TX",
    filing_status: user?.filing_status || "single",
  });
  const [vault, setVault] = useState(null);
  const [retire, setRetire] = useState(null);
  const [invest, setInvest] = useState(null);
  const [busy, setBusy] = useState(false);

  async function loadAccounts() {
    try {
      const [v, r, i] = await Promise.all([
        api.get("/vault").catch(() => ({ data: null })),
        api.get("/smart/retirement").catch(() => ({ data: null })),
        api.get("/smart/investing").catch(() => ({ data: null })),
      ]);
      setVault(v.data); setRetire(r.data); setInvest(i.data);
    } catch (e) { console.debug("[Settings] accounts load failed (optional):", e); }
  }
  useEffect(() => { loadAccounts(); }, []);

  async function saveProfile() {
    setBusy(true);
    try { await api.put("/auth/profile", form); await refresh(); toast.success("Profile updated"); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  async function toggleVaultAuto() {
    if (!vault) { toast.error("Open your Tax Vault first"); return; }
    const paused = !vault.rule?.paused;
    try { await api.put("/vault/rule", { paused }); toast.success(paused ? "Auto-pull paused" : "Auto-pull resumed"); loadAccounts(); }
    catch (e) { toast.error(formatApiError(e)); }
  }

  async function toggleSmart(kind, current) {
    if (!current) { toast.error(`Open your ${kind} account first`); return; }
    const paused = !current.rule?.paused;
    try { await api.put(`/smart/${kind}/rule`, { paused }); toast.success(paused ? "Paused" : "Resumed"); loadAccounts(); }
    catch (e) { toast.error(formatApiError(e)); }
  }

  async function updateVaultPct(pct) {
    try { await api.put("/vault/rule", { fixed_percentage: pct / 100 }); toast.success(`Tax Vault: ${pct}% per payout`); loadAccounts(); }
    catch (e) { toast.error(formatApiError(e)); }
  }
  async function updateSmartPct(kind, pct) {
    try { await api.put(`/smart/${kind}/rule`, { fixed_percentage: pct / 100 }); toast.success(`${kind}: ${pct}% per payout`); loadAccounts(); }
    catch (e) { toast.error(formatApiError(e)); }
  }

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-3xl mx-auto">
      <div className="mb-8">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Settings</div>
        <h1 className="font-display chrome-text text-3xl sm:text-4xl tracking-tight mt-1">Profile & automation</h1>
        <p className="text-zinc-400 mt-1 text-sm">Toggle auto-pull and auto-deposit rules across your accounts.</p>
      </div>

      {/* Connected banks — Plaid multi-bank manager */}
      <div className="mb-4" data-testid="settings-banks-section">
        <BankConnections />
      </div>

      {/* Manage subscription — Stripe portal + Apple ID deep-link */}
      <div className="mb-4" data-testid="settings-subscription-section">
        <ManageSubscription />
      </div>

      {/* Auto-automation toggles */}
      <div className="milli-card p-5 mb-4">
        <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em] mb-4">Auto-Pilot Rules</div>
        <div className="space-y-3">
          <ToggleRow
            testid="toggle-vault"
            icon={ShieldCheck}
            title="Tax Vault auto-pull"
            sub={vault ? `${Math.round((vault.rule?.fixed_percentage ?? 0.25) * 100)}% of every payout → Tax Vault` : "Open Vault first to enable"}
            on={vault && !vault.rule?.paused}
            disabled={!vault}
            onChange={toggleVaultAuto}
          />
          {vault && (
            <SliderRow
              testid="slider-vault"
              label="Tax Vault %"
              value={Math.round((vault.rule?.fixed_percentage ?? 0.25) * 100)}
              min={10} max={40}
              onChange={updateVaultPct}
            />
          )}

          <div className="divider-tick my-3" />

          <ToggleRow
            testid="toggle-retirement"
            icon={Sparkle}
            title="401(k) auto-deposit"
            sub={retire ? `${Math.round((retire.rule?.fixed_percentage ?? 0.08) * 100)}% of every payout → Solo 401(k)` : "Open 401(k) account first"}
            on={retire && !retire.rule?.paused}
            disabled={!retire}
            onChange={() => toggleSmart("retirement", retire)}
          />
          {retire && (
            <SliderRow
              testid="slider-retirement"
              label="401(k) %"
              value={Math.round((retire.rule?.fixed_percentage ?? 0.08) * 100)}
              min={1} max={25}
              onChange={(v) => updateSmartPct("retirement", v)}
            />
          )}

          <div className="divider-tick my-3" />

          <ToggleRow
            testid="toggle-investing"
            icon={ChartLineUp}
            title="Investing auto-deposit"
            sub={invest ? `${Math.round((invest.rule?.fixed_percentage ?? 0.05) * 100)}% of every payout → Brokerage` : "Open Investing account first"}
            on={invest && !invest.rule?.paused}
            disabled={!invest}
            onChange={() => toggleSmart("investing", invest)}
          />
          {invest && (
            <SliderRow
              testid="slider-investing"
              label="Investing %"
              value={Math.round((invest.rule?.fixed_percentage ?? 0.05) * 100)}
              min={1} max={20}
              onChange={(v) => updateSmartPct("investing", v)}
            />
          )}
        </div>
      </div>

      {/* Profile */}
      <div className="milli-card p-5 mb-4 space-y-3">
        <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em]">Profile</div>
        <Field id="settings-email" label="Email" value={user?.email} disabled />
        <Field id="settings-name" label="Name" value={form.name} onChange={(v) => setForm({ ...form, name: v })} />
        <Select id="settings-state" label="Tax filing state" value={form.state} onChange={(v) => setForm({ ...form, state: v })} options={STATES.map((s) => [s, s])} />
        <Select id="settings-filing" label="Filing status" value={form.filing_status} onChange={(v) => setForm({ ...form, filing_status: v })}
          options={[["single","Single"],["married_joint","Married, Joint"],["married_separate","Married, Separate"],["head_of_household","Head of Household"]]} />
        <button data-testid="settings-save" onClick={saveProfile} disabled={busy} className="btn-volt px-6 py-3 uppercase tracking-wider text-sm disabled:opacity-50">
          {busy ? "Saving..." : "Save changes"}
        </button>
      </div>

      <div className="milli-card p-5">
        <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em] mb-2">Subscription</div>
        <div className="text-sm text-zinc-400">Current plan: <span className="text-volt font-bold uppercase">{user?.plan}</span></div>
        {user?.stripe_active_until && <div className="text-xs text-zinc-500 mt-1">Active until {new Date(user.stripe_active_until).toLocaleDateString()}</div>}
        {user?.plan === "trial" && user?.trial_end && <div className="text-xs text-zinc-500 mt-1">Trial ends {new Date(user.trial_end).toLocaleDateString()}</div>}
      </div>
    </div>
  );
}

function ToggleRow({ icon: Icon, title, sub, on, disabled, onChange, testid }) {
  return (
    <div className={`flex items-center gap-3 ${disabled ? "opacity-50" : ""}`}>
      <Icon size={20} weight="duotone" className={on ? "text-volt" : "text-zinc-500"} />
      <div className="flex-1 min-w-0">
        <div className="font-semibold text-sm">{title}</div>
        <div className="text-xs text-zinc-500">{sub}</div>
      </div>
      <button
        data-testid={testid}
        role="switch"
        aria-checked={on}
        disabled={disabled}
        onClick={onChange}
        className={`relative w-12 h-6 rounded-full transition-colors ${on ? "bg-volt" : "bg-zinc-700"} ${disabled ? "cursor-not-allowed" : ""}`}
      >
        <div className={`absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white transition-transform ${on ? "translate-x-6" : ""}`} />
      </button>
    </div>
  );
}

function SliderRow({ label, value, min, max, onChange, testid }) {
  const [local, setLocal] = useState(value);
  useEffect(() => setLocal(value), [value]);
  return (
    <div className="pl-8 pr-1">
      <div className="flex justify-between text-xs mb-1">
        <span className="text-zinc-500">{label}</span>
        <span className="font-mono font-bold text-volt">{local}%</span>
      </div>
      <input
        type="range"
        data-testid={testid}
        min={min} max={max} value={local}
        onChange={(e) => setLocal(parseInt(e.target.value))}
        onMouseUp={() => onChange(local)}
        onTouchEnd={() => onChange(local)}
        className="w-full accent-volt"
      />
    </div>
  );
}

function Field({ label, id, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</label>
      <input id={id} data-testid={id} onChange={(e) => onChange?.(e.target.value)} {...props}
        className="w-full bg-obsidian/60 border border-hairline rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-volt disabled:opacity-50" />
    </div>
  );
}

function Select({ label, id, value, onChange, options }) {
  return (
    <div>
      <label className="block text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</label>
      <select id={id} data-testid={id} value={value} onChange={(e) => onChange(e.target.value)}
        className="w-full bg-obsidian/60 border border-hairline rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-volt">
        {options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
      </select>
    </div>
  );
}
