import { useEffect, useState } from "react";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { ShieldCheck, Sparkle, ChartLineUp } from "@phosphor-icons/react";
import BankConnections from "@/components/BankConnections";
import ManageSubscription from "@/components/ManageSubscription";
import MilliLogo from "@/components/MilliLogo";

/**
 * Settings — WWDC cinematic quality. Profile, automation rules, subscription.
 */

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };

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
    } catch (e) { console.debug("[Settings] accounts load failed:", e); }
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
    <div style={PAGE_STYLE}>
      {/* Header */}
      <header style={{ marginBottom: 20 }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }}>Settings</h1>
        <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Profile & automation rules.</p>
      </header>

      {/* Connected banks */}
      <section style={{ marginBottom: 16 }} data-testid="settings-banks-section">
        <BankConnections />
      </section>

      {/* Manage subscription */}
      <section style={{ marginBottom: 16 }} data-testid="settings-subscription-section">
        <ManageSubscription />
      </section>

      {/* Auto-Pilot Rules */}
      <section style={{ ...SURFACE, padding: "20px", marginBottom: 16 }} data-testid="settings-autopilot">
        <div style={{ fontSize: 11, fontWeight: 600, color: "#00E5FF", letterSpacing: "0.14em", textTransform: "uppercase", marginBottom: 16 }}>AUTO-PILOT RULES</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <ToggleRow
            testid="toggle-vault" icon={ShieldCheck}
            title="Tax Vault auto-pull"
            sub={vault ? `${Math.round((vault.rule?.fixed_percentage ?? 0.25) * 100)}% of every payout → Tax Vault` : "Open Vault first to enable"}
            on={vault && !vault.rule?.paused} disabled={!vault} onChange={toggleVaultAuto}
          />
          {vault && <SliderRow testid="slider-vault" label="Tax Vault %" value={Math.round((vault.rule?.fixed_percentage ?? 0.25) * 100)} min={10} max={40} onChange={updateVaultPct} />}

          <div style={{ height: 1, background: "rgba(255,255,255,0.05)" }} />

          <ToggleRow
            testid="toggle-retirement" icon={Sparkle}
            title="401(k) auto-deposit"
            sub={retire ? `${Math.round((retire.rule?.fixed_percentage ?? 0.08) * 100)}% of every payout → Solo 401(k)` : "Open 401(k) account first"}
            on={retire && !retire.rule?.paused} disabled={!retire} onChange={() => toggleSmart("retirement", retire)}
          />
          {retire && <SliderRow testid="slider-retirement" label="401(k) %" value={Math.round((retire.rule?.fixed_percentage ?? 0.08) * 100)} min={1} max={25} onChange={(v) => updateSmartPct("retirement", v)} />}

          <div style={{ height: 1, background: "rgba(255,255,255,0.05)" }} />

          <ToggleRow
            testid="toggle-investing" icon={ChartLineUp}
            title="Investing auto-deposit"
            sub={invest ? `${Math.round((invest.rule?.fixed_percentage ?? 0.05) * 100)}% of every payout → Brokerage` : "Open Investing account first"}
            on={invest && !invest.rule?.paused} disabled={!invest} onChange={() => toggleSmart("investing", invest)}
          />
          {invest && <SliderRow testid="slider-investing" label="Investing %" value={Math.round((invest.rule?.fixed_percentage ?? 0.05) * 100)} min={1} max={20} onChange={(v) => updateSmartPct("investing", v)} />}
        </div>
      </section>

      {/* Profile */}
      <section style={{ ...SURFACE, padding: "20px", marginBottom: 16 }} data-testid="settings-profile">
        <div style={{ fontSize: 11, fontWeight: 600, color: "#00E5FF", letterSpacing: "0.14em", textTransform: "uppercase", marginBottom: 16 }}>PROFILE</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <Field id="settings-email" label="Email" value={user?.email} disabled />
          <Field id="settings-name" label="Name" value={form.name} onChange={(v) => setForm({ ...form, name: v })} />
          <Select id="settings-state" label="Tax filing state" value={form.state} onChange={(v) => setForm({ ...form, state: v })} options={STATES.map((s) => [s, s])} />
          <Select id="settings-filing" label="Filing status" value={form.filing_status} onChange={(v) => setForm({ ...form, filing_status: v })} options={[["single","Single"],["married_joint","Married, Joint"],["married_separate","Married, Separate"],["head_of_household","Head of Household"]]} />
          <button data-testid="settings-save" onClick={saveProfile} disabled={busy} style={{ marginTop: 8, padding: "12px 24px", borderRadius: 16, fontWeight: 700, fontSize: 14, color: "#000", background: "linear-gradient(180deg, #00E5FF, #00B4D0)", boxShadow: "0 0 20px rgba(0,229,255,0.4)", border: "none", cursor: "pointer", opacity: busy ? 0.5 : 1, letterSpacing: "-0.01em" }}>
            {busy ? "Saving..." : "Save changes"}
          </button>
        </div>
      </section>

      {/* Subscription info */}
      <section style={{ ...SURFACE, padding: "20px" }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: "#00E5FF", letterSpacing: "0.14em", textTransform: "uppercase", marginBottom: 12 }}>SUBSCRIPTION</div>
        <div style={{ color: "#9CA3AF", fontSize: 14 }}>Current plan: <span style={{ color: "#00E5FF", fontWeight: 700, textTransform: "uppercase" }}>{user?.plan}</span></div>
        {user?.stripe_active_until && <div style={{ color: "#4B5563", fontSize: 12, marginTop: 4 }}>Active until {new Date(user.stripe_active_until).toLocaleDateString()}</div>}
        {user?.plan === "trial" && user?.trial_end && <div style={{ color: "#4B5563", fontSize: 12, marginTop: 4 }}>Trial ends {new Date(user.trial_end).toLocaleDateString()}</div>}
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */

function ToggleRow({ icon: Icon, title, sub, on, disabled, onChange, testid }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, opacity: disabled ? 0.5 : 1 }}>
      <Icon size={20} weight="duotone" color={on ? "#00E5FF" : "#6B7280"} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "#fff", fontSize: 14, fontWeight: 600 }}>{title}</div>
        <div style={{ color: "#6B7280", fontSize: 12, marginTop: 2 }}>{sub}</div>
      </div>
      <button data-testid={testid} role="switch" aria-checked={on} disabled={disabled} onClick={onChange} style={{ position: "relative", width: 48, height: 28, borderRadius: 14, border: "none", cursor: disabled ? "not-allowed" : "pointer", background: on ? "linear-gradient(180deg, #00E5FF, #00B4D0)" : "#374151", boxShadow: on ? "0 0 12px rgba(0,229,255,0.4)" : "none", transition: "background 0.2s" }}>
        <div style={{ position: "absolute", top: 3, left: on ? 23 : 3, width: 22, height: 22, borderRadius: 11, background: "#fff", transition: "left 0.2s", boxShadow: "0 2px 4px rgba(0,0,0,0.3)" }} />
      </button>
    </div>
  );
}

function SliderRow({ label, value, min, max, onChange, testid }) {
  const [local, setLocal] = useState(value);
  useEffect(() => setLocal(value), [value]);
  return (
    <div style={{ paddingLeft: 32, paddingRight: 4 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
        <span style={{ color: "#6B7280", fontSize: 12 }}>{label}</span>
        <span style={{ color: "#00E5FF", fontSize: 12, fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>{local}%</span>
      </div>
      <input type="range" data-testid={testid} min={min} max={max} value={local} onChange={(e) => setLocal(parseInt(e.target.value))} onMouseUp={() => onChange(local)} onTouchEnd={() => onChange(local)} style={{ width: "100%", accentColor: "#00E5FF" }} />
    </div>
  );
}

function Field({ label, id, onChange, disabled, value, ...props }) {
  return (
    <div>
      <label style={{ display: "block", fontSize: 10, fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase", color: "#6B7280", marginBottom: 6 }}>{label}</label>
      <input id={id} data-testid={id} value={value || ""} disabled={disabled} onChange={(e) => onChange?.(e.target.value)} {...props} style={{ width: "100%", background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12, padding: "10px 14px", color: "#fff", fontSize: 14, outline: "none", opacity: disabled ? 0.5 : 1 }} />
    </div>
  );
}

function Select({ label, id, value, onChange, options }) {
  return (
    <div>
      <label style={{ display: "block", fontSize: 10, fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase", color: "#6B7280", marginBottom: 6 }}>{label}</label>
      <select id={id} data-testid={id} value={value} onChange={(e) => onChange(e.target.value)} style={{ width: "100%", background: "rgba(5,6,7,0.8)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12, padding: "10px 14px", color: "#fff", fontSize: 14, outline: "none" }}>
        {options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
      </select>
    </div>
  );
}
