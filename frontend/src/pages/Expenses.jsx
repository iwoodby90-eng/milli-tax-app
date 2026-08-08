import { useEffect, useRef, useState } from "react";
import { api, money, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { toast } from "sonner";
import { Receipt, Plus, Trash, Camera, Sparkle, CaretRight } from "@phosphor-icons/react";
import { Link } from "react-router-dom";
import MilliLogo from "@/components/MilliLogo";

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };
const HERO_AMBER = { background: "linear-gradient(135deg, rgba(255,176,0,0.18), rgba(255,200,50,0.06) 45%, rgba(5,6,7,0.9))", border: "1px solid rgba(255,176,0,0.45)", borderRadius: 24, boxShadow: "0 0 32px rgba(255,176,0,0.15), inset 0 1px 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.4)" };

const CATS = ["gas", "maintenance", "supplies", "food", "insurance", "phone", "parking", "tolls", "other"];
const CAT_ICONS = { gas: "⛽", maintenance: "🔧", supplies: "📦", food: "🍔", insurance: "🛡️", phone: "📱", parking: "🅿️", tolls: "🛣️", other: "📋" };

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

  const total = expenses.reduce((s, e) => s + Number(e.amount || 0), 0);
  const byCat = expenses.reduce((acc, e) => { acc[e.category] = (acc[e.category] || 0) + Number(e.amount || 0); return acc; }, {});
  const topCats = Object.entries(byCat).sort((a, b) => b[1] - a[1]).slice(0, 4);

  return (
    <div style={PAGE_STYLE}>
      {/* Header */}
      <header style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12 }}>
        <div>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }}>Expenses</h1>
          <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Track deductions. Keep more money.</p>
        </div>
        <div style={{ display: "flex", gap: 8, flexShrink: 0 }}>
          <input ref={fileRef} type="file" accept="image/*" capture="environment" style={{ display: "none" }} onChange={(e) => onScan(e.target.files?.[0])} data-testid="expense-file-input" />
          <IconBtn testid="expense-scan-btn" disabled={!isPaid || scanning} onClick={() => isPaid ? fileRef.current?.click() : toast.error("Upgrade to Pro to use AI receipt scanner")} icon={Camera} />
          <IconBtn testid="expense-add" onClick={() => { setPrefill(null); setShowForm(true); }} icon={Plus} />
        </div>
      </header>

      <div style={{ height: 20 }} />

      {/* Hero Card — Total YTD */}
      <section style={{ ...HERO_AMBER, padding: "24px" }} data-testid="expenses-hero">
        <div style={{ fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.14em", textTransform: "uppercase" }}>YTD DEDUCTIONS</div>
        <div style={{ fontSize: 38, fontWeight: 800, color: "#fff", letterSpacing: "-0.04em", fontVariantNumeric: "tabular-nums", marginTop: 8 }}>
          ${total.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </div>
        <div style={{ color: "#FFB000", fontSize: 13, marginTop: 6 }}>
          {expenses.length} expense{expenses.length !== 1 ? "s" : ""} logged this year
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* AI Scanner upsell (non-paid) */}
      {!isPaid && (
        <section style={{ ...SURFACE, padding: "16px 20px", display: "flex", alignItems: "center", gap: 14, marginBottom: 16 }} data-testid="expenses-upgrade-card">
          <div style={{ width: 40, height: 40, borderRadius: 14, background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.3)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            <Sparkle size={18} weight="fill" color="#00E5FF" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ color: "#fff", fontSize: 14, fontWeight: 600 }}>Snap & forget</div>
            <div style={{ color: "#6B7280", fontSize: 12, marginTop: 2 }}>AI receipt scanner reads totals, dates & categories from your photos.</div>
          </div>
          <Link to="/app/pricing" style={{ color: "#00E5FF", fontSize: 11, fontWeight: 700, textDecoration: "none", letterSpacing: "0.08em", textTransform: "uppercase", textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>Upgrade</Link>
        </section>
      )}

      {/* Category breakdown */}
      {topCats.length > 0 && (
        <section style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 10, marginBottom: 16 }} data-testid="expenses-categories">
          {topCats.map(([cat, amt]) => (
            <div key={cat} style={{ ...SURFACE, padding: "14px 16px" }}>
              <div style={{ fontSize: 18, marginBottom: 4 }}>{CAT_ICONS[cat] || "📋"}</div>
              <div style={{ fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.12em", textTransform: "uppercase" }}>{cat}</div>
              <div style={{ fontSize: 20, fontWeight: 800, color: "#fff", marginTop: 4, fontVariantNumeric: "tabular-nums" }}>${amt.toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</div>
            </div>
          ))}
        </section>
      )}

      {/* Expense Ledger */}
      <section style={SURFACE} data-testid="expenses-ledger">
        <div style={{ padding: "16px 20px", borderBottom: "1px solid rgba(255,255,255,0.05)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <h2 style={{ fontSize: 17, fontWeight: 600, color: "#fff", margin: 0 }}>Expense Ledger</h2>
          <span style={{ color: "#6B7280", fontSize: 12 }}>{expenses.length} items</span>
        </div>
        {expenses.length === 0 ? (
          <div style={{ padding: "40px 20px", textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
            <MilliLogo size={40} animate={false} />
            <div style={{ color: "#fff", fontWeight: 600, fontSize: 15 }}>No expenses yet</div>
            <div style={{ color: "#4B5563", fontSize: 13 }}>Tap + to add your first deduction.</div>
          </div>
        ) : (
          <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
            {expenses.map((e, idx) => (
              <ExpenseRow key={e.id || idx} expense={e} last={idx === expenses.length - 1} onDelete={() => del(e.id)} />
            ))}
          </ul>
        )}
      </section>

      {showForm && <ExpenseDialog initial={prefill} onClose={() => setShowForm(false)} onSaved={() => { setShowForm(false); load(); }} />}
    </div>
  );
}

/* ============ Sub-components ============ */

function IconBtn({ icon: Icon, testid, onClick, disabled }) {
  return (
    <button data-testid={testid} onClick={onClick} disabled={disabled} style={{ width: 36, height: 36, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", background: "rgba(5,6,7,0.8)", border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 10px rgba(0,229,255,0.2)", cursor: "pointer", opacity: disabled ? 0.4 : 1 }}>
      <Icon size={16} weight="regular" color="#00E5FF" />
    </button>
  );
}

function ExpenseRow({ expense, last, onDelete }) {
  const e = expense;
  const cat = e.category || "other";
  const date = new Date(e.date || e.created_at || Date.now());
  const dateStr = date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  const amt = Number(e.amount || 0);

  return (
    <li data-testid={`expense-row-${e.id}`} style={{ display: "flex", alignItems: "center", gap: 12, padding: "14px 20px", borderBottom: last ? "none" : "1px solid rgba(255,255,255,0.05)" }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, background: "rgba(255,176,0,0.08)", border: "1px solid rgba(255,176,0,0.25)" }}>
        {CAT_ICONS[cat] || "📋"}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "#fff", fontSize: 14, fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{e.merchant || cat}</div>
        <div style={{ color: "#4B5563", fontSize: 11 }}>{dateStr} · {cat}</div>
      </div>
      <div style={{ color: "#fff", fontWeight: 700, fontSize: 15, fontVariantNumeric: "tabular-nums", flexShrink: 0 }}>
        −${amt.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
      </div>
      <button onClick={onDelete} data-testid={`expense-delete-${e.id}`} style={{ color: "#4B5563", background: "none", border: "none", padding: 6, cursor: "pointer" }}>
        <Trash size={14} weight="regular" />
      </button>
    </li>
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
    <div onClick={onClose} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.8)", display: "flex", alignItems: "flex-end", justifyContent: "center", zIndex: 50, padding: 12 }}>
      <div onClick={e => e.stopPropagation()} style={{ width: "100%", maxWidth: 420, borderRadius: 24, padding: 20, background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 32px rgba(0,229,255,0.25)" }}>
        <div style={{ color: "#fff", fontWeight: 600, fontSize: 17, marginBottom: 16 }}>{initial ? "Confirm expense" : "Add expense"}</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Field label="Date"><input data-testid="exp-date" type="date" value={form.date} onChange={e => setForm({ ...form, date: e.target.value })} style={inputStyle} /></Field>
          <Field label="Amount ($)"><input data-testid="exp-amount" type="number" step="0.01" placeholder="0.00" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} style={inputStyle} /></Field>
          <Field label="Category"><select data-testid="exp-category" value={form.category} onChange={e => setForm({ ...form, category: e.target.value })} style={inputStyle}>
            {CATS.map(o => <option key={o} value={o}>{o}</option>)}
          </select></Field>
          <Field label="Merchant"><input data-testid="exp-merchant" type="text" placeholder="Shell, Costco..." value={form.merchant} onChange={e => setForm({ ...form, merchant: e.target.value })} style={inputStyle} /></Field>
        </div>
        <div style={{ display: "flex", gap: 8, marginTop: 20 }}>
          <button onClick={onClose} style={{ flex: 1, borderRadius: 16, padding: "12px 0", color: "rgba(255,255,255,0.7)", fontSize: 13, fontWeight: 600, border: "1px solid rgba(255,255,255,0.1)", background: "transparent", cursor: "pointer" }}>Cancel</button>
          <button data-testid="exp-save" onClick={save} disabled={busy || !form.amount} style={{ flex: 1, borderRadius: 16, padding: "12px 0", fontWeight: 700, fontSize: 13, color: "#000", background: "linear-gradient(180deg, #00E5FF, #00B4D0)", boxShadow: "0 0 20px rgba(0,229,255,0.4)", border: "none", cursor: "pointer", opacity: (busy || !form.amount) ? 0.5 : 1 }}>{busy ? "Saving..." : "Save"}</button>
        </div>
      </div>
    </div>
  );
}

const inputStyle = { width: "100%", background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12, padding: "10px 12px", color: "#fff", fontSize: 14, outline: "none" };

function Field({ label, children }) {
  return <div><label style={{ display: "block", color: "#6B7280", fontSize: 11, marginBottom: 6, letterSpacing: "0.08em", textTransform: "uppercase" }}>{label}</label>{children}</div>;
}
