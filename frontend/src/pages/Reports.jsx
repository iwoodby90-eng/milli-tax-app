import { useEffect, useState } from "react";
import { api, money, num, formatApiError, API_BASE } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { FileText, DownloadSimple, FileCsv, Lock, Sparkle } from "@phosphor-icons/react";
import { Link } from "react-router-dom";
import { toast } from "sonner";

const CYAN = "#00E5FF";

export default function Reports() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const year = new Date().getFullYear();
  const isPaid = user && user.plan !== "trial" && user.plan !== "basic";

  useEffect(() => {
    api
      .get(`/tax/summary?year=${year}`)
      .then(({ data }) => setSummary(data))
      .catch((e) => toast.error(formatApiError(e)));
  }, [year]);

  async function download(path, filename) {
    try {
      const res = await fetch(`${API_BASE}${path}`, {
        headers: { Authorization: `Bearer ${localStorage.getItem("milli_token")}` },
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (e) {
      toast.error(`Download failed: ${e.message}`);
    }
  }

  if (!summary) {
    return (
      <div className="p-10 font-mono text-volt text-xs uppercase tracking-[0.3em] animate-pulse" style={{ backgroundColor: "#050607", color: "#00E5FF", minHeight: "100vh" }}>
        Loading reports…
      </div>
    );
  }

  return (
    <div className="px-5 py-6 max-w-[440px] mx-auto" data-testid="reports-screen" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100%" }}>
      {/* Title */}
      <div className="mb-5">
        <div className="text-volt text-[10px] font-semibold uppercase tracking-[0.3em]">
          // Reports
        </div>
        <h1 className="font-display font-black chrome-text text-[32px] leading-none tracking-tight mt-1">
          Tax {summary.year}
        </h1>
        <p className="text-zinc-400 mt-1 text-[13px]">Year-end exports, IRS-ready.</p>
      </div>

      {/* Snapshot */}
      <section
        className="rounded-2xl overflow-hidden mb-4"
        style={{
          background: "linear-gradient(180deg, rgba(255,255,255,0.03), rgba(255,255,255,0))",
          border: "1px solid rgba(192,192,192,0.16)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.04)",
        }}
      >
        <div className="px-4 py-3 border-b border-white/[0.06]">
          <div className="text-[10px] font-semibold uppercase tracking-[0.24em]" style={{ color: CYAN }}>
            Snapshot
          </div>
        </div>
        <div className="grid grid-cols-2 gap-x-4 gap-y-4 p-4">
          <Snapshot label="Gross income" value={money(summary.gross_income)} />
          <Snapshot
            label="Mileage deduction"
            value={money(summary.mileage_deduction)}
            sub={`${num(summary.total_miles)} mi`}
          />
          <Snapshot label="Net income" value={money(summary.net_income)} />
          <Snapshot label="Est. tax owed" value={money(summary.estimated_tax)} accent />
        </div>

        {/* Tax breakdown — stacked list, not a jammed grid */}
        <div className="border-t border-white/[0.06] px-4 py-3 space-y-2">
          <TaxRow label="Self-employment tax (15.3%)" value={money(summary.se_tax)} />
          <TaxRow label="Federal income (est.)" value={money(summary.fed_income_tax)} />
          <TaxRow
            label={`${user?.state || "State"} tax (${(summary.state_rate * 100).toFixed(2)}%)`}
            value={money(summary.state_tax)}
          />
        </div>
      </section>

      {/* Downloads — stacked cards, each with a full-width action button */}
      <div className="flex flex-col gap-3">
        <Report
          testid="report-schedule-c"
          icon={FileText}
          title="Schedule C + SE worksheet"
          subtitle="Profit/Loss from business — ready to file with the IRS"
          locked={!isPaid}
          filename={`schedule-c-${year}.pdf`}
          onDownload={() =>
            download(`/reports/schedule-c.pdf?year=${year}`, `schedule-c-${year}.pdf`)
          }
        />
        <Report
          testid="report-mileage-csv"
          icon={FileCsv}
          title="Mileage log CSV"
          subtitle="Every business trip, IRS audit-ready"
          filename={`mileage-${year}.csv`}
          onDownload={() =>
            download(`/reports/mileage.csv?year=${year}`, `mileage-${year}.csv`)
          }
        />
      </div>

      {/* Upgrade prompt */}
      {!isPaid && (
        <div
          className="mt-5 rounded-2xl p-4 flex items-start gap-3"
          style={{
            background: "linear-gradient(180deg, rgba(0,229,255,0.08), rgba(0,229,255,0.02))",
            border: "1px solid rgba(0,229,255,0.4)",
            boxShadow: "0 0 20px rgba(0,229,255,0.15)",
          }}
        >
          <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
               style={{ background: "rgba(0,229,255,0.15)", border: "1px solid rgba(0,229,255,0.4)" }}>
            <Sparkle size={16} weight="fill" style={{ color: CYAN }} />
          </div>
          <div className="flex-1 min-w-0">
            <div className="font-semibold text-white text-[14px]">
              Schedule C PDF is on Pro
            </div>
            <div className="text-[12px] text-zinc-400 mt-0.5 leading-relaxed">
              Elite users get auto-generated forms ready to hand to a CPA.
            </div>
            <Link
              to="/app/pricing"
              data-testid="reports-upgrade"
              className="mt-3 inline-flex items-center gap-1.5 px-4 py-2 rounded-full text-[11px] font-bold uppercase tracking-[0.2em] active:scale-[0.97] transition-transform"
              style={{
                background: "linear-gradient(180deg, #00E5FF 0%, #00B8D4 100%)",
                color: "#001217",
                boxShadow: "0 0 16px rgba(0,229,255,0.4)",
              }}
            >
              Upgrade to Pro
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}

function Snapshot({ label, value, sub, accent }) {
  return (
    <div>
      <div className="text-[10px] font-semibold uppercase tracking-[0.2em] text-white/50">
        {label}
      </div>
      <div
        className={`font-chrome font-bold text-[22px] leading-tight mt-1 tabular-nums ${accent ? "" : "chrome-text"}`}
        style={accent ? { color: CYAN, textShadow: "0 0 14px rgba(0,229,255,0.35)" } : {}}
      >
        {value}
      </div>
      {sub && (
        <div className="text-[10.5px] text-zinc-500 mt-0.5 font-mono">{sub}</div>
      )}
    </div>
  );
}

function TaxRow({ label, value }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <div className="text-[12.5px] text-zinc-400 min-w-0 truncate">{label}</div>
      <div className="text-[13px] font-semibold text-white tabular-nums flex-shrink-0">
        {value}
      </div>
    </div>
  );
}

function Report({ icon: Icon, title, subtitle, onDownload, locked, filename, testid }) {
  return (
    <div
      className="rounded-2xl overflow-hidden"
      data-testid={testid}
      style={{
        background: "linear-gradient(180deg, rgba(255,255,255,0.03), rgba(255,255,255,0))",
        border: `1px solid ${locked ? "rgba(192,192,192,0.12)" : "rgba(0,229,255,0.28)"}`,
        boxShadow: locked ? "none" : "0 0 18px rgba(0,229,255,0.10), inset 0 1px 0 rgba(255,255,255,0.04)",
        opacity: locked ? 0.7 : 1,
      }}
    >
      <div className="p-4 flex items-start gap-3">
        <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
             style={{
               background: locked
                 ? "rgba(255,255,255,0.04)"
                 : "linear-gradient(180deg, rgba(0,229,255,0.15), rgba(0,229,255,0.03))",
               border: `1px solid ${locked ? "rgba(255,255,255,0.08)" : "rgba(0,229,255,0.4)"}`,
             }}>
          <Icon size={18} weight="duotone" style={{ color: locked ? "#7A8189" : CYAN }} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="font-semibold text-white text-[14px] leading-tight">{title}</div>
          <div className="text-[11.5px] text-zinc-400 mt-1 leading-snug">{subtitle}</div>
          {filename && !locked && (
            <div className="text-[10px] text-zinc-500 mt-1.5 font-mono truncate">{filename}</div>
          )}
        </div>
      </div>
      <button
        onClick={onDownload}
        disabled={locked}
        data-testid={`${testid}-btn`}
        className="w-full py-3 text-[11.5px] font-bold uppercase tracking-[0.18em] inline-flex items-center justify-center gap-2 active:scale-[0.985] transition-transform disabled:opacity-70"
        style={
          locked
            ? { background: "rgba(255,255,255,0.03)", color: "#7A8189", borderTop: "1px solid rgba(255,255,255,0.05)" }
            : {
                background: "linear-gradient(180deg, rgba(0,229,255,0.12), rgba(0,229,255,0.04))",
                color: CYAN,
                borderTop: "1px solid rgba(0,229,255,0.3)",
              }
        }
      >
        {locked ? (
          <><Lock size={12} weight="bold" /> Upgrade to download</>
        ) : (
          <><DownloadSimple size={12} weight="bold" /> Download</>
        )}
      </button>
    </div>
  );
}
