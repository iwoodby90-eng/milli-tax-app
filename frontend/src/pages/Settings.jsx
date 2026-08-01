import { useEffect, useState } from "react";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import {
  User, CreditCard, Car, GasPump, Speedometer, Plugs,
  ShieldCheck, Key, FingerprintSimple, Bell, CaretRight,
  DeviceMobile, Wallet, SignOut,
} from "@phosphor-icons/react";
import BankConnections from "@/components/BankConnections";
import ManageSubscription from "@/components/ManageSubscription";

/**
 * Settings.jsx — iOS Grouped List Standard
 * Groups: Account & Billing, Vehicle Profile, Payout Sourcing, Security
 * Aesthetic: SF Pro typography, Phosphor duotone icons, grouped inset cards
 */

const STATES = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"];

const GIG_PLATFORMS = [
  { id: "uber", name: "Uber", connected: true },
  { id: "lyft", name: "Lyft", connected: true },
  { id: "doordash", name: "DoorDash", connected: false },
  { id: "instacart", name: "Instacart", connected: false },
  { id: "spark", name: "Spark (Walmart)", connected: true },
  { id: "amazon_flex", name: "Amazon Flex", connected: false },
];

export default function Settings() {
  const { user, refresh, logout } = useAuth();
  const [form, setForm] = useState({
    name: user?.name || "",
    state: user?.state || "TX",
    filing_status: user?.filing_status || "single",
  });
  const [vehicle, setVehicle] = useState({
    mpg: "28",
    fuel_type: "regular",
    vehicle_name: "My Vehicle",
  });
  const [busy, setBusy] = useState(false);

  async function saveProfile() {
    setBusy(true);
    try {
      await api.put("/auth/profile", form);
      await refresh();
      toast.success("Profile updated");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-2xl mx-auto" style={{ backgroundColor: "#0D0F12", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', system-ui, sans-serif", minHeight: "100%" }}>
      {/* Page Header */}
      <div className="mb-8">
        <div className="font-mono text-xs uppercase tracking-[0.3em]" style={{ color: "#00E5FF" }}>// Settings</div>
        <h1 className="text-3xl font-bold tracking-tight mt-1" style={{ fontFamily: "'SF Pro Display', -apple-system, sans-serif" }}>Settings</h1>
      </div>

      {/* ─── GROUP 1: Account & Billing ─── */}
      <SettingsGroup title="Account & Billing" testid="group-account">
        <SettingsRow
          icon={User}
          label="Name"
          value={form.name || user?.name}
          testid="setting-name"
        />
        <SettingsRow
          icon={DeviceMobile}
          label="Email"
          value={user?.email}
          testid="setting-email"
          disabled
        />
        <SettingsRow
          icon={CreditCard}
          label="Plan"
          value={(user?.plan || "trial").toUpperCase()}
          accent
          testid="setting-plan"
          to="/app/pricing"
        />
        <SettingsRow
          icon={Wallet}
          label="Manage Subscription"
          chevron
          testid="setting-subscription"
        />
      </SettingsGroup>

      {/* Connected Banks */}
      <div className="mb-6" data-testid="settings-banks-section">
        <BankConnections />
      </div>

      {/* Subscription management */}
      <div className="mb-6" data-testid="settings-subscription-section">
        <ManageSubscription />
      </div>

      {/* ─── GROUP 2: Vehicle Profile ─── */}
      <SettingsGroup title="Vehicle Profile" testid="group-vehicle">
        <SettingsRow
          icon={Car}
          label="Vehicle"
          value={vehicle.vehicle_name}
          testid="setting-vehicle-name"
        />
        <SettingsRow
          icon={Speedometer}
          label="MPG"
          value={`${vehicle.mpg} mpg`}
          testid="setting-mpg"
          editable
          editValue={vehicle.mpg}
          onEdit={(v) => setVehicle({ ...vehicle, mpg: v })}
        />
        <SettingsRow
          icon={GasPump}
          label="Fuel Type"
          value={vehicle.fuel_type === "regular" ? "Regular Unleaded" : vehicle.fuel_type === "premium" ? "Premium" : "Diesel"}
          testid="setting-fuel"
        />
      </SettingsGroup>

      {/* ─── GROUP 3: Payout Sourcing (Gig Apps) ─── */}
      <SettingsGroup title="Payout Sourcing" testid="group-payout">
        {GIG_PLATFORMS.map((platform) => (
          <SettingsRow
            key={platform.id}
            icon={Plugs}
            label={platform.name}
            value={platform.connected ? "Connected" : "Not Connected"}
            accent={platform.connected}
            testid={`gig-${platform.id}`}
            chevron
          />
        ))}
      </SettingsGroup>

      {/* ─── GROUP 4: Security ─── */}
      <SettingsGroup title="Security" testid="group-security">
        <SettingsRow
          icon={Key}
          label="Change Password"
          chevron
          testid="setting-password"
        />
        <SettingsRow
          icon={FingerprintSimple}
          label="Face ID / Touch ID"
          value="Enabled"
          accent
          testid="setting-biometric"
        />
        <SettingsRow
          icon={ShieldCheck}
          label="Two-Factor Auth"
          value="Active"
          accent
          testid="setting-2fa"
        />
        <SettingsRow
          icon={Bell}
          label="Notifications"
          value="On"
          testid="setting-notifications"
          chevron
        />
      </SettingsGroup>

      {/* Profile Form (collapsed into clean edit) */}
      <SettingsGroup title="Tax Profile" testid="group-tax-profile">
        <div className="px-4 py-3 space-y-4">
          <InlineField label="Full Name" value={form.name} onChange={(v) => setForm({ ...form, name: v })} testid="settings-name" />
          <InlineSelect label="Filing State" value={form.state} onChange={(v) => setForm({ ...form, state: v })} options={STATES.map(s => [s, s])} testid="settings-state" />
          <InlineSelect
            label="Filing Status"
            value={form.filing_status}
            onChange={(v) => setForm({ ...form, filing_status: v })}
            options={[["single","Single"],["married_joint","Married, Joint"],["married_separate","Married, Separate"],["head_of_household","Head of Household"]]}
            testid="settings-filing"
          />
          <button
            onClick={saveProfile}
            disabled={busy}
            data-testid="settings-save"
            className="w-full py-3 rounded-xl text-sm font-semibold uppercase tracking-wider"
            style={{ background: "#00E5FF", color: "#050607" }}
          >
            {busy ? "Saving..." : "Save Changes"}
          </button>
        </div>
      </SettingsGroup>

      {/* Sign Out */}
      <div className="mt-8 mb-12">
        <button
          onClick={logout}
          data-testid="settings-signout"
          className="w-full flex items-center justify-center gap-2 py-4 rounded-2xl text-sm font-medium"
          style={{ background: "rgba(255,59,92,0.06)", border: "1px solid rgba(255,59,92,0.15)", color: "#FF3B5C" }}
        >
          <SignOut size={16} weight="bold" /> Sign Out
        </button>
      </div>
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────────
   iOS Grouped List Primitives
   ───────────────────────────────────────────────────────────────── */

function SettingsGroup({ title, children, testid }) {
  return (
    <div className="mb-6" data-testid={testid}>
      <div className="text-xs font-semibold uppercase tracking-[0.15em] text-zinc-500 mb-2 px-1" style={{ fontFamily: "'SF Pro Text', -apple-system, sans-serif" }}>
        {title}
      </div>
      <div
        className="rounded-2xl overflow-hidden divide-y"
        style={{
          background: "rgba(13,15,18,0.6)",
          backdropFilter: "blur(28px)",
          border: "1px solid rgba(40,44,52,0.6)",
          divideColor: "rgba(255,255,255,0.04)",
        }}
      >
        {children}
      </div>
    </div>
  );
}

function SettingsRow({ icon: Icon, label, value, accent, chevron, disabled, testid, to, editable, editValue, onEdit }) {
  const Wrapper = to ? "a" : "div";
  return (
    <Wrapper
      href={to}
      className="flex items-center gap-3 px-4 py-3.5"
      style={{ borderBottom: "1px solid rgba(255,255,255,0.03)", opacity: disabled ? 0.5 : 1 }}
      data-testid={testid}
    >
      <div className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0" style={{ background: "rgba(0,229,255,0.06)" }}>
        <Icon size={18} weight="duotone" style={{ color: "#00E5FF" }} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-[15px] font-medium text-white" style={{ fontFamily: "'SF Pro Text', -apple-system, sans-serif" }}>{label}</div>
      </div>
      {value && (
        <div className={`text-sm font-medium ${accent ? "" : "text-zinc-400"}`} style={accent ? { color: "#00E5FF" } : {}}>
          {value}
        </div>
      )}
      {chevron && <CaretRight size={14} weight="bold" className="text-zinc-600" />}
    </Wrapper>
  );
}

function InlineField({ label, value, onChange, testid }) {
  return (
    <div>
      <label className="block text-[11px] uppercase tracking-[0.15em] text-zinc-500 mb-1.5" style={{ fontFamily: "'SF Pro Text', -apple-system, sans-serif" }}>{label}</label>
      <input
        data-testid={testid}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl px-4 py-3 text-sm text-white outline-none"
        style={{ background: "rgba(5,6,7,0.7)", border: "1px solid rgba(0,229,255,0.08)", fontFamily: "'SF Pro Text', -apple-system, sans-serif" }}
      />
    </div>
  );
}

function InlineSelect({ label, value, onChange, options, testid }) {
  return (
    <div>
      <label className="block text-[11px] uppercase tracking-[0.15em] text-zinc-500 mb-1.5" style={{ fontFamily: "'SF Pro Text', -apple-system, sans-serif" }}>{label}</label>
      <select
        data-testid={testid}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl px-4 py-3 text-sm text-white outline-none appearance-none"
        style={{ background: "rgba(5,6,7,0.7)", border: "1px solid rgba(0,229,255,0.08)", fontFamily: "'SF Pro Text', -apple-system, sans-serif" }}
      >
        {options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
      </select>
    </div>
  );
}
