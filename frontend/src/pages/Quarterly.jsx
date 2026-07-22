import { useEffect, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { toast } from "sonner";
import { CalendarCheck, CheckCircle, Clock, Warning, Receipt, Info } from "@phosphor-icons/react";

export default function Quarterly() {
  const [data, setData] = useState(null);
  const [recordOpen, setRecordOpen] = useState(null);

  async function load() {
    try { const { data } = await api.get("/quarterly"); setData(data); }
    catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  if (!data) return <div className="p-12 font-mono text-volt animate-pulse">[ LOADING QUARTERLY... ]</div>;

  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-3xl mx-auto">
      <div className="mb-6">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Quarterly</div>
        <h1 className="font-display text-3xl sm:text-4xl tracking-tight mt-1 chrome-text">Stay ready for every deadline.</h1>
        <p className="text-zinc-400 mt-1 text-sm">Annual estimate {money(data.annual_estimate)} · 4 quarterly payments</p>
      </div>

      <div className="space-y-3">
        {data.quarters.map((q) => (
          <QuarterCard key={q.period} q={q} onRecord={() => setRecordOpen(q)} />
        ))}
      </div>

      <div className="mt-6 milli-card p-5 text-xs text-zinc-500 leading-relaxed flex gap-3">
        <Info size={16} className="flex-shrink-0 text-volt" />
        <div>
          Milli helps you prepare quarterly estimates. Pay directly via IRS Direct Pay or your state portal.
          Milli does not remit taxes on your behalf. After paying, record it here so Milli can track your readiness.
        </div>
      </div>

      {recordOpen && <RecordDialog quarter={recordOpen} year={data.year} onClose={() => setRecordOpen(null)} onDone={() => { setRecordOpen(null); load(); }} />}
    </div>
  );
}

function QuarterCard({ q, onRecord }) {
  const paid = q.status === "paid";
  const overdue = q.status === "overdue";
  const ringStroke = paid ? "#39D98A" : overdue ? "#FF5C67" : "#13D8D1";
  return (
    <div className="milli-card p-5" data-testid={`quarter-${q.period}`}>
      <div className="flex items-center gap-4">
        <Ring value={q.readiness} color={ringStroke} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-display text-xl">{q.period} {new Date(q.due_date).getFullYear()}</span>
            {paid && <span className="px-2 py-0.5 rounded-full bg-success/20 text-success text-[10px] font-bold uppercase tracking-wider">Paid</span>}
            {overdue && !paid && <span className="px-2 py-0.5 rounded-full bg-danger/20 text-danger text-[10px] font-bold uppercase tracking-wider">Overdue</span>}
          </div>
          <div className="text-zinc-400 text-xs mt-0.5">
            Due {new Date(q.due_date).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
            {!paid && ` · ${q.days_until >= 0 ? `${q.days_until} days` : `${-q.days_until} days late`}`}
          </div>
          <div className="mt-2 flex flex-wrap gap-x-6 gap-y-1 text-sm">
            <div><span className="text-zinc-500 text-xs">Estimated</span> <span className="font-mono font-semibold">{money(q.amount)}</span></div>
            <div><span className="text-zinc-500 text-xs">Reserved</span> <span className="font-mono font-semibold text-volt">{money(q.reserved)}</span></div>
          </div>
        </div>
        <div className="hidden sm:block">
          {!paid && (
            <button
              data-testid={`record-${q.period}`}
              onClick={onRecord}
              className="btn-outline-cyan px-4 py-2 text-xs uppercase tracking-wider font-semibold"
            >Record payment</button>
          )}
          {paid && q.payment && (
            <div className="text-right">
              <div className="text-[10px] uppercase tracking-wider text-zinc-500">Confirmation</div>
              <div className="font-mono text-xs">{q.payment.confirmation || "—"}</div>
            </div>
          )}
        </div>
      </div>
      {!paid && (
        <div className="sm:hidden mt-3">
          <button onClick={onRecord} data-testid={`record-mob-${q.period}`} className="btn-outline-cyan w-full px-4 py-2 text-xs uppercase tracking-wider font-semibold">Record payment</button>
        </div>
      )}
    </div>
  );
}

function Ring({ value, color }) {
  const r = 28, c = 2 * Math.PI * r;
  const off = c - (value / 100) * c;
  return (
    <div className="relative w-16 h-16 flex-shrink-0">
      <svg width="64" height="64" viewBox="0 0 64 64" className="-rotate-90">
        <circle cx="32" cy="32" r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="5" />
        <circle cx="32" cy="32" r={r} fill="none" stroke={color} strokeWidth="5" strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={off} style={{ transition: "stroke-dashoffset 600ms" }} />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center font-mono text-sm font-semibold">{value}%</div>
    </div>
  );
}

function RecordDialog({ quarter, year, onClose, onDone }) {
  const [form, setForm] = useState({
    amount: quarter.amount.toFixed(2),
    paid_on: new Date().toISOString().slice(0, 10),
    confirmation: "",
    method: "IRS Direct Pay",
  });
  const [busy, setBusy] = useState(false);

  async function save() {
    setBusy(true);
    try {
      await api.post("/quarterly/payment", {
        period: quarter.period,
        year,
        amount: parseFloat(form.amount),
        paid_on: form.paid_on,
        confirmation: form.confirmation || null,
        method: form.method,
      });
      toast.success(`${quarter.period} payment recorded`);
      onDone();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display text-xl mb-4">Record {quarter.period} payment</div>
        <div className="space-y-3">
          <Field id="q-amount" label="Amount paid ($)" type="number" step="0.01" value={form.amount} onChange={(v) => setForm({ ...form, amount: v })} />
          <Field id="q-date" label="Paid on" type="date" value={form.paid_on} onChange={(v) => setForm({ ...form, paid_on: v })} />
          <Field id="q-conf" label="Confirmation # (optional)" value={form.confirmation} onChange={(v) => setForm({ ...form, confirmation: v })} />
          <Field id="q-method" label="Method" value={form.method} onChange={(v) => setForm({ ...form, method: v })} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline rounded-xl text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid="q-save" onClick={save} disabled={busy} className="flex-1 btn-volt px-4 py-2.5 text-xs uppercase tracking-wider disabled:opacity-50">{busy ? "..." : "Save"}</button>
        </div>
      </div>
    </div>
  );
}

function Field({ id, label, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] uppercase tracking-[0.18em] text-zinc-500 mb-1">{label}</label>
      <input id={id} data-testid={id} onChange={(e) => onChange(e.target.value)} {...props}
        className="w-full bg-obsidian/60 border border-hairline rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-volt" />
    </div>
  );
}
