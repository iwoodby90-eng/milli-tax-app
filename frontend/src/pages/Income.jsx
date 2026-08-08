import { useEffect, useState, useCallback } from "react";
import { api, formatApiError } from "@/lib/api";
import { usePlaidLink } from "react-plaid-link";
import { toast } from "sonner";
import {
  Bank, Plus, ArrowsClockwise, CaretRight, Trash,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };
const HERO_TEAL = { background: "linear-gradient(135deg, rgba(0,180,200,0.22), rgba(0,229,255,0.07) 45%, rgba(5,6,7,0.9))", border: "1px solid rgba(0,229,255,0.45)", borderRadius: 24, boxShadow: "0 0 32px rgba(0,229,255,0.2), inset 0 1px 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.4)" };

const FILTER_PILLS = ["All", "Stripe", "PayPal", "Venmo", "Cash"];

export default function Income() {
  const [items, setItems] = useState([]);
  const [deposits, setDeposits] = useState([]);
  const [linkToken, setLinkToken] = useState(null);
  const [loadingLink, setLoadingLink] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [showManual, setShowManual] = useState(false);
  const [activeFilter, setActiveFilter] = useState("All");

  async function load() {
    try {
      const [i, d] = await Promise.all([api.get("/plaid/items"), api.get("/deposits")]);
      setItems(i.data); setDeposits(d.data);
    } catch (e) { toast.error(formatApiError(e)); }
  }
  useEffect(() => { load(); }, []);

  async function startLink() {
    setLoadingLink(true);
    try {
      const { data } = await api.post("/plaid/link-token");
      setLinkToken(data.link_token);
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setLoadingLink(false); }
  }

  const onPlaidSuccess = useCallback(async (public_token, metadata) => {
    try {
      const { data } = await api.post("/plaid/exchange", { public_token, institution_name: metadata?.institution?.name || "Bank" });
      toast.success(`Connected — ${data.synced_deposits} gig deposits found`);
      setLinkToken(null); load();
    } catch (e) { toast.error(formatApiError(e)); }
  }, []);

  const { open, ready } = usePlaidLink({ token: linkToken, onSuccess: onPlaidSuccess, onExit: () => setLinkToken(null) });
  useEffect(() => { if (linkToken && ready) open(); }, [linkToken, ready, open]);

  async function syncAll() {
    setSyncing(true);
    try { const { data } = await api.post("/plaid/sync"); toast.success(`+${data.synced} new payouts`); load(); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setSyncing(false); }
  }

  async function removeItem(id) {
    if (!window.confirm("Disconnect this bank?")) return;
    try { await api.delete(`/plaid/items/${id}`); toast.success("Bank disconnected"); load(); }
    catch (e) { toast.error(formatApiError(e)); }
  }

  const total = deposits.reduce((s, d) => s + Number(d.amount || 0), 0);
  const reserved = deposits.reduce((s, d) => s + Number(d.savings_set_aside || 0), 0);
  const filtered = activeFilter === "All" ? deposits : deposits.filter(d => (d.platform || "").toLowerCase() === activeFilter.toLowerCase());
  const groupedByMonth = groupByMonth(filtered);

  return (
    <div style={PAGE_STYLE}>
      {/* Header */}
      <header style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12 }}>
        <div>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }}>Income</h1>
          <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Your payouts, tracked and protected.</p>
        </div>
        <div style={{ display: "flex", gap: 8, flexShrink: 0 }}>
          <IconBtn testid="income-sync" disabled={syncing || items.length === 0} onClick={syncAll} icon={ArrowsClockwise} />
          <IconBtn testid="income-add-manual" onClick={() => setShowManual(true)} icon={Plus} />
        </div>
      </header>

      <div style={{ height: 20 }} />

      {/* Hero Card — Total Earned */}
      <section style={{ ...HERO_TEAL, padding: "24px" }} data-testid="income-hero">
        <div style={{ fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.14em", textTransform: "uppercase" }}>TOTAL EARNED THIS YEAR</div>
        <div style={{ fontSize: 38, fontWeight: 800, color: "#fff", letterSpacing: "-0.04em", fontVariantNumeric: "tabular-nums", marginTop: 8 }}>
          ${total.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </div>
        <div style={{ color: "#00E5FF", fontSize: 13, marginTop: 6 }}>
          ↑ vs last period · ${reserved.toLocaleString("en-US", { minimumFractionDigits: 2 })} reserved
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Filter Pills */}
      <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 4 }}>
        {FILTER_PILLS.map(pill => (
          <button
            key={pill}
            onClick={() => setActiveFilter(pill)}
            style={{
              flexShrink: 0, padding: "8px 16px", borderRadius: 999, fontSize: 12, fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.12em", cursor: "pointer", transition: "all 0.2s",
              background: activeFilter === pill ? "rgba(0,229,255,0.12)" : "rgba(255,255,255,0.04)",
              color: activeFilter === pill ? "#00E5FF" : "#6B7280",
              border: `1px solid ${activeFilter === pill ? "rgba(0,229,255,0.45)" : "rgba(255,255,255,0.06)"}`,
            }}
          >
            {pill}
          </button>
        ))}
      </div>

      <div style={{ height: 16 }} />

      {/* Connected Banks */}
      <section style={{ ...SURFACE, padding: 16 }} data-testid="banks-card">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: "#fff", letterSpacing: "-0.02em", margin: 0 }}>Connected banks</h2>
          <button onClick={startLink} disabled={loadingLink} data-testid="income-connect-bank" style={{ color: "#00E5FF", fontSize: 12, fontWeight: 600, background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 4, textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            <Bank size={14} weight="bold" color="#00E5FF" /> {loadingLink ? "Loading..." : "Connect bank"}
          </button>
        </div>
        {items.length === 0 ? (
          <div style={{ color: "#4B5563", fontSize: 13, textAlign: "center", padding: "16px 0" }}>No banks connected yet.</div>
        ) : (
          <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
            {items.map(it => (
              <li key={it.id} data-testid={`bank-row-${it.id}`} style={{ display: "flex", alignItems: "center", gap: 12, padding: "8px 0" }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.3)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Bank size={16} weight="regular" color="#00E5FF" />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ color: "#fff", fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{it.institution_name}</div>
                  <div style={{ color: "#4B5563", fontSize: 11 }}>Connected {String(it.created_at || "").slice(0, 10)}</div>
                </div>
                <button onClick={() => removeItem(it.id)} data-testid={`bank-remove-${it.id}`} style={{ color: "#4B5563", background: "none", border: "none", padding: 8, cursor: "pointer" }}><Trash size={14} /></button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <div style={{ height: 16 }} />

      {/* Payouts list */}
      <section data-testid="payouts-list">
        {deposits.length === 0 ? (
          <div style={{ ...SURFACE, padding: 32, textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
            <MilliLogo size={40} animate={false} />
            <div style={{ color: "#fff", fontWeight: 600, fontSize: 15 }}>Your payouts appear here</div>
            <div style={{ color: "#4B5563", fontSize: 13 }}>Connect a bank or add one manually.</div>
            <button onClick={startLink} style={{ marginTop: 8, height: 52, borderRadius: 16, padding: "0 24px", background: "#00E5FF", color: "#000", fontWeight: 700, fontSize: 16, border: "none", cursor: "pointer", boxShadow: "0 0 24px rgba(0,229,255,0.45), 0 4px 16px rgba(0,0,0,0.3)", letterSpacing: "-0.01em" }}>
              Connect Income Source
            </button>
          </div>
        ) : (
          Object.entries(groupedByMonth).map(([monthLabel, group]) => (
            <div key={monthLabel} style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.14em", textTransform: "uppercase", marginBottom: 8, paddingLeft: 4 }}>{monthLabel}</div>
              <div style={SURFACE}>
                <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
                  {group.map((d, idx) => (
                    <PayoutRow key={d.id || idx} deposit={d} last={idx === group.length - 1} />
                  ))}
                </ul>
              </div>
            </div>
          ))
        )}
      </section>

      {showManual && <ManualDepositDialog onClose={() => setShowManual(false)} onSaved={() => { setShowManual(false); load(); }} />}
    </div>
  );
}

/* ============ Sub-components ============ */
function fmt(n) { return `$${Number(n || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`; }

function groupByMonth(deposits) {
  const out = {};
  for (const d of deposits) {
    const dt = new Date(d.date || d.created_at || Date.now());
    const key = dt.toLocaleString("en-US", { month: "long", year: "numeric" });
    (out[key] = out[key] || []).push(d);
  }
  return out;
}

function IconBtn({ icon: Icon, testid, onClick, disabled }) {
  return (
    <button data-testid={testid} onClick={onClick} disabled={disabled} style={{ width: 36, height: 36, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", background: "rgba(5,6,7,0.8)", border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 10px rgba(0,229,255,0.2)", cursor: "pointer", opacity: disabled ? 0.4 : 1 }}>
      <Icon size={16} weight="regular" color="#00E5FF" />
    </button>
  );
}

function PayoutRow({ deposit, last }) {
  const d = deposit;
  const platform = d.platform || "Payout";
  const date = new Date(d.date || d.created_at || Date.now());
  const dateStr = date.toLocaleDateString("en-US", { weekday: "short", day: "numeric" });
  const time = date.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
  const amt = Number(d.amount || 0);
  const saved = Number(d.savings_set_aside || 0);

  return (
    <li data-testid={`payout-${d.id || dateStr}`} style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 16px", borderBottom: last ? "none" : "1px solid rgba(255,255,255,0.05)" }}>
      <PlatformBadge platform={platform} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "#fff", fontSize: 14, fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{platform}</div>
        <div style={{ color: "#4B5563", fontSize: 11, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{dateStr} · {time}</div>
      </div>
      <div style={{ textAlign: "right", flexShrink: 0 }}>
        <div style={{ color: "#fff", fontWeight: 700, fontSize: 14, fontVariantNumeric: "tabular-nums" }}>+{fmt(amt)}</div>
        {saved > 0 && <div style={{ color: "#00E5FF", fontSize: 10, fontVariantNumeric: "tabular-nums", textShadow: "0 0 6px rgba(0,229,255,0.4)" }}>−{fmt(saved)} to Vault</div>}
      </div>
      <span style={{ color: "#00E5FF", fontSize: 10, fontWeight: 600, padding: "2px 8px", borderRadius: 999, background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.3)" }}>Received</span>
      <CaretRight size={13} weight="bold" color="#4B5563" style={{ flexShrink: 0 }} />
    </li>
  );
}

function PlatformBadge({ platform }) {
  const map = { Uber: { bg: "#000", fg: "#fff", l: "U" }, Lyft: { bg: "#FF00BF", fg: "#fff", l: "L" }, DoorDash: { bg: "#EB1700", fg: "#fff", l: "DD" }, Spark: { bg: "#0071DC", fg: "#FFC220", l: "★" }, Instacart: { bg: "#43B02A", fg: "#fff", l: "IC" }, Stripe: { bg: "#635BFF", fg: "#fff", l: "S" }, PayPal: { bg: "#003087", fg: "#fff", l: "PP" }, Venmo: { bg: "#3D95CE", fg: "#fff", l: "V" }, Cash: { bg: "#00D632", fg: "#fff", l: "$" } };
  const cfg = map[platform] || { bg: "#1a1e24", fg: "#fff", l: "$" };
  return (
    <div style={{ width: 36, height: 36, borderRadius: 10, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 11, background: cfg.bg, color: cfg.fg, boxShadow: "0 4px 8px rgba(0,0,0,0.35)" }}>
      {cfg.l}
    </div>
  );
}

function ManualDepositDialog({ onClose, onSaved }) {
  const [form, setForm] = useState({ date: new Date().toISOString().slice(0, 10), amount: "", platform: "Uber", merchant: "" });
  const [busy, setBusy] = useState(false);
  async function save() {
    setBusy(true);
    try { await api.post("/deposits/manual", { ...form, amount: parseFloat(form.amount) }); toast.success("Payout added"); onSaved(); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }
  return (
    <div onClick={onClose} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.8)", display: "flex", alignItems: "flex-end", justifyContent: "center", zIndex: 50, padding: 12 }}>
      <div onClick={e => e.stopPropagation()} style={{ width: "100%", maxWidth: 420, borderRadius: 24, padding: 20, background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 32px rgba(0,229,255,0.25)" }}>
        <div style={{ color: "#fff", fontWeight: 600, fontSize: 17, marginBottom: 16 }}>Add manual payout</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Field label="Date"><input data-testid="manual-deposit-date" type="date" value={form.date} onChange={e => setForm({ ...form, date: e.target.value })} style={inputStyle} /></Field>
          <Field label="Amount ($)"><input data-testid="manual-deposit-amount" type="number" step="0.01" placeholder="0.00" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} style={inputStyle} /></Field>
          <Field label="Platform"><select data-testid="manual-deposit-platform" value={form.platform} onChange={e => setForm({ ...form, platform: e.target.value })} style={inputStyle}>
            {["Uber", "Lyft", "DoorDash", "Spark", "Instacart", "Amazon Flex", "Grubhub", "Shipt", "Other"].map(o => <option key={o} value={o}>{o}</option>)}
          </select></Field>
        </div>
        <div style={{ display: "flex", gap: 8, marginTop: 20 }}>
          <button onClick={onClose} style={{ flex: 1, borderRadius: 16, padding: "12px 0", color: "rgba(255,255,255,0.7)", fontSize: 13, fontWeight: 600, border: "1px solid rgba(255,255,255,0.1)", background: "transparent", cursor: "pointer" }}>Cancel</button>
          <button data-testid="manual-deposit-save" onClick={save} disabled={busy || !form.amount} style={{ flex: 1, borderRadius: 16, padding: "12px 0", fontWeight: 700, fontSize: 13, color: "#000", background: "linear-gradient(180deg, #00E5FF, #00B4D0)", boxShadow: "0 0 20px rgba(0,229,255,0.4)", border: "none", cursor: "pointer", opacity: (busy || !form.amount) ? 0.5 : 1 }}>{busy ? "Saving..." : "Save"}</button>
        </div>
      </div>
    </div>
  );
}

const inputStyle = { width: "100%", background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12, padding: "10px 12px", color: "#fff", fontSize: 14, outline: "none" };

function Field({ label, children }) {
  return <div><label style={{ display: "block", color: "#6B7280", fontSize: 11, marginBottom: 6, letterSpacing: "0.08em" }}>{label}</label>{children}</div>;
}
