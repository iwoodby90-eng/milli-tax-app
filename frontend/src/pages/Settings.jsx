import { useState } from "react";
import { api, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";

const STATES = [
  "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
];

export default function Settings() {
  const { user, refresh } = useAuth();
  const [form, setForm] = useState({
    name: user?.name || "",
    state: user?.state || "TX",
    filing_status: user?.filing_status || "single",
  });
  const [busy, setBusy] = useState(false);

  async function save() {
    setBusy(true);
    try {
      await api.put("/auth/profile", form);
      await refresh();
      toast.success("Profile updated");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="p-6 lg:p-10 max-w-3xl">
      <div className="mb-8">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Settings</div>
        <h1 className="font-display font-black text-4xl tracking-tighter mt-1">Profile</h1>
        <p className="text-zinc-400 mt-1">Used for tax calculations & forms.</p>
      </div>

      <div className="milli-card p-6 space-y-4">
        <Field label="Email" value={user?.email} disabled id="settings-email" />
        <Field label="Name" value={form.name} onChange={(v) => setForm({ ...form, name: v })} id="settings-name" />
        <FieldSelect label="Tax filing state" value={form.state} onChange={(v) => setForm({ ...form, state: v })} id="settings-state" options={STATES} />
        <FieldSelect
          label="Filing status"
          id="settings-filing-status"
          value={form.filing_status}
          onChange={(v) => setForm({ ...form, filing_status: v })}
          options={[
            { value: "single", label: "Single" },
            { value: "married_joint", label: "Married, Joint" },
            { value: "married_separate", label: "Married, Separate" },
            { value: "head_of_household", label: "Head of Household" },
          ]}
        />
        <button
          data-testid="settings-save"
          onClick={save}
          disabled={busy}
          className="btn-volt px-6 py-3 font-bold uppercase tracking-wider text-sm disabled:opacity-50"
        >{busy ? "Saving..." : "Save changes"}</button>
      </div>

      <div className="milli-card p-6 mt-6">
        <div className="font-display font-bold text-lg mb-3">Subscription</div>
        <div className="text-sm text-zinc-400">Current plan: <span className="text-volt font-bold uppercase">{user?.plan}</span></div>
        {user?.stripe_active_until && (
          <div className="text-sm text-zinc-500 mt-1">Active until {new Date(user.stripe_active_until).toLocaleDateString()}</div>
        )}
        {user?.plan === "trial" && user?.trial_end && (
          <div className="text-sm text-zinc-500 mt-1">Trial ends {new Date(user.trial_end).toLocaleDateString()}</div>
        )}
      </div>
    </div>
  );
}

function Field({ label, id, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <input id={id} data-testid={id} onChange={(e) => onChange?.(e.target.value)} {...props} className="w-full bg-transparent border border-hairline px-4 py-3 font-mono text-sm focus:outline-none focus:border-volt disabled:opacity-50" />
    </div>
  );
}

function FieldSelect({ label, id, value, onChange, options }) {
  const opts = options.map((o) => typeof o === "string" ? { value: o, label: o } : o);
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <select id={id} data-testid={id} value={value} onChange={(e) => onChange(e.target.value)} className="w-full bg-obsidian border border-hairline px-4 py-3 font-mono text-sm focus:outline-none focus:border-volt">
        {opts.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  );
}
