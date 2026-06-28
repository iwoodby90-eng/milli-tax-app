import { useEffect, useState } from "react";
import { api, money, num, formatApiError, API_BASE } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { FileText, DownloadSimple, FileCsv, Lock } from "@phosphor-icons/react";
import { Link } from "react-router-dom";
import { toast } from "sonner";

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
      const res = await fetch(`${API_BASE}${path}`, {
        headers: { Authorization: `Bearer ${localStorage.getItem("milli_token")}` },
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url; a.download = filename;
      document.body.appendChild(a); a.click(); a.remove();
      URL.revokeObjectURL(url);
    } catch (e) { toast.error(`Download failed: ${e.message}`); }
  }

  if (!summary) return <div className="p-12 font-mono text-volt animate-pulse">[ LOADING REPORTS... ]</div>;

  return (
    <div className="p-6 lg:p-10 max-w-7xl">
      <div className="mb-8">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Reports</div>
        <h1 className="font-display font-black text-4xl tracking-tighter mt-1">Tax {summary.year}</h1>
        <p className="text-zinc-400 mt-1">Year-end exports, IRS-ready.</p>
      </div>

      {/* Estimate summary */}
      <div className="milli-card p-6 mb-6">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em] mb-4">// Snapshot</div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          <Snapshot label="Gross income" value={money(summary.gross_income)} />
          <Snapshot label="Mileage deduction" value={money(summary.mileage_deduction)} sub={`${num(summary.total_miles)} mi`} />
          <Snapshot label="Net income" value={money(summary.net_income)} />
          <Snapshot label="Est. tax owed" value={money(summary.estimated_tax)} accent />
        </div>
        <div className="divider-tick my-6" />
        <div className="grid grid-cols-2 md:grid-cols-3 gap-6 text-sm">
          <div><span className="text-zinc-500">SE Tax (15.3%): </span><span className="font-mono font-bold">{money(summary.se_tax)}</span></div>
          <div><span className="text-zinc-500">Federal Income (est): </span><span className="font-mono font-bold">{money(summary.fed_income_tax)}</span></div>
          <div><span className="text-zinc-500">{user?.state} state ({(summary.state_rate * 100).toFixed(2)}%): </span><span className="font-mono font-bold">{money(summary.state_tax)}</span></div>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        <Report
          testid="report-schedule-c"
          icon={FileText}
          title="Schedule C + SE worksheet"
          subtitle="Profit/Loss from business — ready to file"
          locked={!isPaid}
          onDownload={() => download(`/reports/schedule-c.pdf?year=${year}`, `schedule-c-${year}.pdf`)}
        />
        <Report
          testid="report-mileage-csv"
          icon={FileCsv}
          title="Mileage log CSV"
          subtitle="Every trip, IRS audit-ready"
          onDownload={() => download(`/reports/mileage.csv?year=${year}`, `mileage-${year}.csv`)}
        />
      </div>

      {!isPaid && (
        <div className="mt-6 milli-card border-volt p-5 flex items-center gap-4">
          <Lock size={24} className="text-volt" weight="bold" />
          <div className="flex-1">
            <div className="font-display font-bold">Schedule C PDF is on Pro</div>
            <div className="text-sm text-zinc-400">Elite users get auto-generated forms ready to hand to your CPA.</div>
          </div>
          <Link to="/app/pricing" className="px-4 py-2 border border-volt text-volt text-xs font-bold uppercase tracking-wider hover:bg-volt hover:text-obsidian transition-colors">Upgrade</Link>
        </div>
      )}
    </div>
  );
}

function Snapshot({ label, value, sub, accent }) {
  return (
    <div>
      <div className="text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500">{label}</div>
      <div className={`font-display font-black text-3xl mt-1 ${accent ? "text-volt" : ""}`}>{value}</div>
      {sub && <div className="text-xs text-zinc-500 font-mono mt-1">{sub}</div>}
    </div>
  );
}

function Report({ icon: Icon, title, subtitle, onDownload, locked, testid }) {
  return (
    <div className={`milli-card p-6 flex items-center gap-4 ${locked ? "opacity-60" : "hover:border-volt"} transition-colors`} data-testid={testid}>
      <div className="w-12 h-12 bg-volt text-obsidian flex items-center justify-center flex-shrink-0">
        <Icon size={24} weight="bold" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-display font-bold">{title}</div>
        <div className="text-sm text-zinc-400 truncate">{subtitle}</div>
      </div>
      <button
        onClick={onDownload}
        disabled={locked}
        className="px-4 py-2 border border-volt text-volt text-xs font-bold uppercase tracking-wider hover:bg-volt hover:text-obsidian transition-colors disabled:opacity-50 inline-flex items-center gap-2"
      >
        {locked ? <><Lock size={14} weight="bold" /> Locked</> : <><DownloadSimple size={14} weight="bold" /> Download</>}
      </button>
    </div>
  );
}
