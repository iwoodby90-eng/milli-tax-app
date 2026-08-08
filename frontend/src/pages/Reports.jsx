import { useEffect, useState } from "react";
import { api, money, num, formatApiError, API_BASE } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { FileText, DownloadSimple, FileCsv, Lock, Sparkle } from "@phosphor-icons/react";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import MilliLogo from "@/components/MilliLogo";

/**
 * Reports — WWDC cinematic quality. Year-end tax snapshot + IRS-ready downloads.
 */

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };
const HERO_GREEN = { background: "linear-gradient(135deg, rgba(16,185,129,0.18), rgba(52,211,153,0.06) 45%, rgba(5,6,7,0.9))", border: "1px solid rgba(16,185,129,0.45)", borderRadius: 24, boxShadow: "0 0 32px rgba(16,185,129,0.15), inset 0 1px 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.4)" };
const CYAN = "#00E5FF";

export default function Reports() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const year = new Date().getFullYear();
  const isPaid = user && user.plan !== "trial" && user.plan !== "basic";

  useEffect(() => {
    api.get(`/tax/summary?year=${year}`).then(({ data }) => setSummary(data)).catch((e) => toast.error(formatApiError(e)));
  }, [year]);

  async function download(path, filename) {
    try {
      const res = await fetch(`${API_BASE}${path}`, { headers: { Authorization: `Bearer ${localStorage.getItem("milli_token")}` } });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a"); a.href = url; a.download = filename;
      document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
    } catch (e) { toast.error(`Download failed: ${e.message}`); }
  }

  if (!summary) {
    return (
      <div style={{ ...PAGE_STYLE, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", minHeight: "60vh", gap: 12 }}>
        <MilliLogo size={48} animate={true} />
        <p style={{ color: "#6B7280", fontSize: 14 }}>Loading reports...</p>
      </div>
    );
  }

  return (
    <div style={PAGE_STYLE} data-testid="reports-screen">
      {/* Header */}
      <header style={{ marginBottom: 20 }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }}>Tax {summary.year}</h1>
        <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Year-end exports, IRS-ready.</p>
      </header>

      {/* Snapshot Hero */}
      <section style={{ ...HERO_GREEN, padding: "24px" }} data-testid="reports-snapshot">
        <div style={{ fontSize: 11, fontWeight: 600, color: "#6B7280", letterSpacing: "0.14em", textTransform: "uppercase", marginBottom: 16 }}>SNAPSHOT</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px 24px" }}>
          <Snapshot label="Gross income" value={money(summary.gross_income)} />
          <Snapshot label="Mileage deduction" value={money(summary.mileage_deduction)} sub={`${num(summary.total_miles)} mi`} />
          <Snapshot label="Net income" value={money(summary.net_income)} />
          <Snapshot label="Est. tax owed" value={money(summary.estimated_tax)} accent />
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Tax Breakdown */}
      <section style={SURFACE} data-testid="reports-breakdown">
        <div style={{ padding: "16px 20px", borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: CYAN, letterSpacing: "0.14em", textTransform: "uppercase" }}>TAX BREAKDOWN</div>
        </div>
        <div style={{ padding: "14px 20px", display: "flex", flexDirection: "column", gap: 10 }}>
          <TaxRow label="Self-employment tax (15.3%)" value={money(summary.se_tax)} />
          <TaxRow label="Federal income (est.)" value={money(summary.fed_income_tax)} />
          <TaxRow label={`${user?.state || "State"} tax (${(summary.state_rate * 100).toFixed(2)}%)`} value={money(summary.state_tax)} />
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Downloads */}
      <section style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <ReportCard testid="report-schedule-c" icon={FileText} title="Schedule C + SE worksheet" subtitle="Profit/Loss from business — ready to file with the IRS" locked={!isPaid} filename={`schedule-c-${year}.pdf`} onDownload={() => download(`/reports/schedule-c.pdf?year=${year}`, `schedule-c-${year}.pdf`)} />
        <ReportCard testid="report-mileage-csv" icon={FileCsv} title="Mileage log CSV" subtitle="Every business trip, IRS audit-ready" filename={`mileage-${year}.csv`} onDownload={() => download(`/reports/mileage.csv?year=${year}`, `mileage-${year}.csv`)} />
      </section>

      <div style={{ height: 16 }} />

      {/* Upgrade prompt */}
      {!isPaid && (
        <section style={{ ...SURFACE, padding: "16px 20px", display: "flex", alignItems: "flex-start", gap: 14, border: "1px solid rgba(0,229,255,0.4)", boxShadow: "0 0 20px rgba(0,229,255,0.15)" }} data-testid="reports-upgrade-card">
          <div style={{ width: 40, height: 40, borderRadius: 14, background: "rgba(0,229,255,0.12)", border: "1px solid rgba(0,229,255,0.4)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            <Sparkle size={18} weight="fill" color={CYAN} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ color: "#fff", fontSize: 14, fontWeight: 600 }}>Schedule C PDF is on Pro</div>
            <div style={{ color: "#6B7280", fontSize: 12, marginTop: 4, lineHeight: 1.5 }}>Elite users get auto-generated forms ready to hand to a CPA.</div>
            <Link to="/app/pricing" data-testid="reports-upgrade" style={{ display: "inline-flex", alignItems: "center", gap: 6, marginTop: 12, padding: "8px 16px", borderRadius: 999, fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase", textDecoration: "none", color: "#001217", background: "linear-gradient(180deg, #00E5FF, #00B8D4)", boxShadow: "0 0 16px rgba(0,229,255,0.4)" }}>
              Upgrade to Pro
            </Link>
          </div>
        </section>
      )}
    </div>
  );
}

/* ============ Sub-components ============ */

function Snapshot({ label, value, sub, accent }) {
  return (
    <div>
      <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: "0.16em", textTransform: "uppercase", color: "rgba(255,255,255,0.45)" }}>{label}</div>
      <div style={{ fontSize: 22, fontWeight: 800, color: accent ? "#10B981" : "#fff", marginTop: 6, fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em", textShadow: accent ? "0 0 14px rgba(16,185,129,0.35)" : "none" }}>{value}</div>
      {sub && <div style={{ color: "#6B7280", fontSize: 10.5, marginTop: 2 }}>{sub}</div>}
    </div>
  );
}

function TaxRow({ label, value }) {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
      <div style={{ color: "#9CA3AF", fontSize: 13, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", minWidth: 0 }}>{label}</div>
      <div style={{ color: "#fff", fontSize: 14, fontWeight: 600, fontVariantNumeric: "tabular-nums", flexShrink: 0 }}>{value}</div>
    </div>
  );
}

function ReportCard({ icon: Icon, title, subtitle, onDownload, locked, filename, testid }) {
  return (
    <div style={{ ...SURFACE, overflow: "hidden", border: locked ? "1px solid rgba(255,255,255,0.07)" : "1px solid rgba(0,229,255,0.28)", boxShadow: locked ? "0 4px 24px rgba(0,0,0,0.3)" : "0 0 18px rgba(0,229,255,0.10), inset 0 1px 0 rgba(255,255,255,0.04), 0 4px 24px rgba(0,0,0,0.3)", opacity: locked ? 0.7 : 1 }} data-testid={testid}>
      <div style={{ padding: "16px 20px", display: "flex", alignItems: "flex-start", gap: 14 }}>
        <div style={{ width: 40, height: 40, borderRadius: 14, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, background: locked ? "rgba(255,255,255,0.04)" : "linear-gradient(180deg, rgba(0,229,255,0.15), rgba(0,229,255,0.03))", border: `1px solid ${locked ? "rgba(255,255,255,0.08)" : "rgba(0,229,255,0.4)"}` }}>
          <Icon size={18} weight="duotone" color={locked ? "#7A8189" : CYAN} />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ color: "#fff", fontSize: 14, fontWeight: 600, lineHeight: 1.3 }}>{title}</div>
          <div style={{ color: "#6B7280", fontSize: 11.5, marginTop: 4, lineHeight: 1.4 }}>{subtitle}</div>
          {filename && !locked && <div style={{ color: "#4B5563", fontSize: 10, marginTop: 6, fontFamily: "monospace" }}>{filename}</div>}
        </div>
      </div>
      <button onClick={onDownload} disabled={locked} data-testid={`${testid}-btn`} style={{ width: "100%", padding: "12px 0", fontSize: 11.5, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, cursor: locked ? "not-allowed" : "pointer", border: "none", borderTop: `1px solid ${locked ? "rgba(255,255,255,0.05)" : "rgba(0,229,255,0.3)"}`, background: locked ? "rgba(255,255,255,0.03)" : "linear-gradient(180deg, rgba(0,229,255,0.12), rgba(0,229,255,0.04))", color: locked ? "#7A8189" : CYAN }}>
        {locked ? <><Lock size={12} weight="bold" /> Upgrade to download</> : <><DownloadSimple size={12} weight="bold" /> Download</>}
      </button>
    </div>
  );
}
