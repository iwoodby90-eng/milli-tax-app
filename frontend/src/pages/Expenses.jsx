import { useEffect, useRef, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { Receipt, Plus, Trash, Camera, Sparkle } from "@phosphor-icons/react";
import { Link } from "react-router-dom";

const CATS = ["gas", "maintenance", "supplies", "food", "insurance", "phone", "parking", "tolls", "other"];

export default function Expenses() {
  const { user } = useAuth();
  const [expenses, setExpenses] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [scanning, setScanning] = useState(false);
  const fileRef = useRef(null);
  const [prefill, setPrefill] = useState(null);

  const isPaid = user && user.plan !== "trial" && user.plan !== "basic";

  async function load() {
    try { const { data } = await api.get("/expenses"); setExpenses(data); }
    catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  async function del(id) {
    if (!window.confirm("Delete expense?")) return;
    await api.delete(`/expenses/${id}`); load();
  }

  async function onScan(file) {
    if (!file) return;
    setScanning(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const { data } = await api.post("/expenses/scan", fd, { headers: { "Content-Type": "multipart/form-data" } });
      setPrefill({
        date: data.date || new Date().toISOString().slice(0, 10),
        amount: data.amount || "",
        category: CATS.includes(data.category) ? data.category : "other",
        merchant: data.merchant || "",
      });
      setShowForm(true);
      toast.success("Receipt parsed — review and save");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setScanning(false); if (fileRef.current) fileRef.current.value = ""; }
  }

  const total = expenses.reduce((s, e) => s + e.amount, 0);
  const byCat = expenses.reduce((acc, e) => { acc[e.category] = (acc[e.category] || 0) + e.amount; return acc; }, {});

  return (
    <div className="p-6 lg:p-10 max-w-7xl" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100%" }}>
      <div className="flex justify-between items-end mb-8 flex-wrap gap-4">
        <div>
          <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Expenses</div>
          <h1 className="font-display font-black text-4xl tracking-tighter mt-1">Deductions</h1>
          <p className="text-zinc-400 mt-1">Track gas, supplies, phone — anything used for work.</p>
        </div>
        <div className="flex gap-2">
          <input ref={fileRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={(e) => onScan(e.target.files?.[0])} data-testid="expense-file-input" />
          <button
            data-testid="expense-scan-btn"
            disabled={!isPaid || scanning}
            onClick={() => isPaid ? fileRef.current?.click() : toast.error("Upgrade to Pro to use AI receipt scanner")}
            className="px-4 py-2.5 border border-volt text-volt text-xs font-bold uppercase tracking-wider inline-flex items-center gap-2 hover:bg-volt hover:text-obsidian transition-colors disabled:opacity-40"
          >
            <Camera size={14} weight="bold" /> {scanning ? "Scanning..." : "Scan receipt (AI)"}
          </button>
          <button
            data-testid="expense-add"
            onClick={() => { setPrefill(null); setShowForm(true); }}
            className="btn-volt px-4 py-2.5 text-xs font-bold uppercase tracking-wider inline-flex items-center gap-2"
          ><Plus size={14} weight="bold" /> Add</button>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <Stat label="YTD total" value={money(total)} accent />
        <Stat label="Gas" value={money(byCat.gas || 0)} />
        <Stat label="Phone" value={money(byCat.phone || 0)} />
        <Stat label="Maintenance" value={money(byCat.maintenance || 0)} />
      </div>

      {!isPaid && (
        <div className="milli-card border-volt p-5 mb-6 flex items-center gap-4">
          <Sparkle size={24} className="text-volt" weight="fill" />
          <div className="flex-1">
            <div className="font-display font-bold">Snap & forget</div>
            <div className="text-sm text-zinc-400">AI receipt scanner reads totals, dates, and categories from your photos. Pro plan unlocks it.</div>
          </div>
          <Link to="/app/pricing" className="px-4 py-2 border border-volt text-volt text-xs font-bold uppercase tracking-wider hover:bg-volt hover:text-obsidian transition-colors">Upgrade</Link>
        </div>
      )}

      <div className="milli-card p-6">
        <div className="font-display font-bold text-lg mb-4">Expense ledger</div>
        {expenses.length === 0 ? (
          <div className="text-center py-12">
            <Receipt size={40} className="text-zinc-700 mx-auto" weight="bold" />
            <div className="font-display font-bold mt-3">No expenses logged</div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="font-mono text-xs uppercase text-zinc-500 tracking-widest">
                <tr className="border-b border-hairline">
                  <th className="text-left py-2 px-2">Date</th>
                  <th className="text-left py-2 px-2">Category</th>
                  <th className="text-left py-2 px-2">Merchant</th>
                  <th className="text-right py-2 px-2">Amount</th>
                  <th></th>
                </tr>
              </thead>
              <tbody className="font-mono">
                {expenses.map((e) => (
                  <tr key={e.id} className="border-b border-hairline/60 hover:bg-white/5" data-testid={`expense-row-${e.id}`}>
                    <td className="py-2.5 px-2 text-zinc-400">{e.date}</td>
                    <td className="py-2.5 px-2"><span className="px-2 py-0.5 bg-white/5 border border-hairline text-xs uppercase">{e.category}</span></td>
                    <td className="py-2.5 px-2 text-zinc-400">{e.merchant}</td>
                    <td className="py-2.5 px-2 text-right font-bold">{money(e.amount)}</td>
                    <td className="py-2.5 px-2 text-right">
                      <button onClick={() => del(e.id)} data-testid={`expense-delete-${e.id}`} className="text-zinc-500 hover:text-danger"><Trash size={14} weight="bold" /></button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showForm && <ExpenseDialog initial={prefill} onClose={() => setShowForm(false)} onSaved={() => { setShowForm(false); load(); }} />}
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

function ExpenseDialog({ initial, onClose, onSaved }) {
  const [form, setForm] = useState(initial || {
    date: new Date().toISOString().slice(0, 10),
    amount: "",
    category: "gas",
    merchant: "",
  });
  const [busy, setBusy] = useState(false);

  async function save() {
    setBusy(true);
    try {
      await api.post("/expenses", { ...form, amount: parseFloat(form.amount) });
      toast.success("Expense saved");
      onSaved();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display font-bold text-xl mb-4">{initial ? "Confirm expense" : "Add expense"}</div>
        <div className="space-y-3">
          <FieldInput id="exp-date" label="Date" type="date" value={form.date} onChange={(v) => setForm({ ...form, date: v })} />
          <FieldInput id="exp-amount" label="Amount ($)" type="number" step="0.01" value={form.amount} onChange={(v) => setForm({ ...form, amount: v })} />
          <FieldSelect id="exp-category" label="Category" value={form.category} onChange={(v) => setForm({ ...form, category: v })} options={CATS} />
          <FieldInput id="exp-merchant" label="Merchant" value={form.merchant} onChange={(v) => setForm({ ...form, merchant: v })} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid="exp-save" onClick={save} disabled={busy || !form.amount} className="flex-1 btn-volt px-4 py-2.5 text-xs font-bold uppercase tracking-wider disabled:opacity-50">{busy ? "Saving..." : "Save"}</button>
        </div>
      </div>
    </div>
  );
}

function FieldInput({ label, id, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <input id={id} data-testid={id} onChange={(e) => onChange(e.target.value)} {...props} className="w-full bg-transparent border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt" />
    </div>
  );
}

function FieldSelect({ label, id, value, onChange, options }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <select id={id} data-testid={id} value={value} onChange={(e) => onChange(e.target.value)} className="w-full bg-obsidian border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt">
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
    </div>
  );
}
