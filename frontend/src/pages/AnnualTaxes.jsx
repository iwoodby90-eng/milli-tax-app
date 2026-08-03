import { useState, useEffect } from "react";
import { useAuth } from "@/context/AuthContext";
import {
  FileText, Calendar, ArrowUpRight, ArrowDownRight,
  CheckCircle, Clock, Warning, Download, CaretRight,
  Percent, CurrencyDollar, Buildings,
} from "@phosphor-icons/react";

const STORAGE_KEY = "milli_annual_taxes";

export default function AnnualTaxes() {
  const { user } = useAuth();
  const [taxData, setTaxData] = useState(null);
  const [activeYear, setActiveYear] = useState(2025);

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        setTaxData(JSON.parse(stored));
      } else {
        const defaults = {
          "2025": {
            totalIncome: 67500,
            totalExpenses: 12300,
            estimatedTax: 8420,
            quarterlyPaid: 6300,
            effectiveRate: 12.5,
            filingStatus: "in_progress",
            filingDeadline: "2026-04-15",
            scheduleC: { grossReceipts: 67500, returns: 0, netProfit: 55200, seTax: 7803, deductions: 12300 },
            deductions: [
              { label: "Vehicle Expenses (Mileage)", amount: 4200 },
              { label: "Home Office", amount: 1800 },
              { label: "Phone & Internet", amount: 960 },
              { label: "Equipment & Supplies", amount: 2100 },
              { label: "Health Insurance Premium", amount: 3240 },
            ],
            credits: [
              { label: "Earned Income Credit", amount: 0 },
              { label: "Child Tax Credit", amount: 0 },
            ],
            quarterly: [
              { q: "Q1", due: "2025-04-15", amount: 2105, paid: true },
              { q: "Q2", due: "2025-06-15", amount: 2105, paid: true },
              { q: "Q3", due: "2025-09-15", amount: 2105, paid: true },
              { q: "Q4", due: "2026-01-15", amount: 2105, paid: false },
            ],
          },
        };
        setTaxData(defaults);
        localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults));
      }
    } catch { setTaxData({}); }
  }, []);

  if (!taxData) return null;

  const yearData = taxData[String(activeYear)] || {};
  const remaining = (yearData.estimatedTax || 0) - (yearData.quarterlyPaid || 0);

  const statusInfo = {
    not_started: { label: "Not Started", icon: Clock, color: "text-zinc-400" },
    in_progress: { label: "In Progress", icon: Warning, color: "text-yellow-400" },
    filed: { label: "Filed", icon: CheckCircle, color: "text-green-400" },
    completed: { label: "Completed", icon: CheckCircle, color: "text-green-400" },
  };
  const status = statusInfo[yearData.filingStatus] || statusInfo.not_started;
  const StatusIcon = status.icon;

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4">
      {/* Header */}
      <header>
        <h1
          className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight"
          style={{ fontFamily: "'Outfit', system-ui, sans-serif" }}
        >
          Annual Taxes
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Your year-end tax summary, filing status, and quarterly payments.</p>
      </header>

      {/* Year selector */}
      <div className="flex gap-2">
        {[2025, 2024].map((year) => (
          <button
            key={year}
            onClick={() => setActiveYear(year)}
            className={`px-4 py-2 rounded-xl text-[14px] font-medium transition ${
              activeYear === year ? "bg-volt text-black" : "milli-card text-zinc-400"
            }`}
          >
            {year}
          </button>
        ))}
      </div>

      {/* Filing status card */}
      <section
        className="milli-card rounded-3xl p-5"
        style={{ background: "linear-gradient(180deg, rgba(0,229,255,0.04) 0%, rgba(10,14,18,0.9) 100%)", border: "1px solid rgba(0,229,255,0.15)" }}
      >
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <StatusIcon size={20} weight="fill" className={status.color} />
            <span className="text-white text-[15px] font-semibold">Filing: {status.label}</span>
          </div>
          <div className="text-zinc-500 text-[12px] flex items-center gap-1">
            <Calendar size={14} />
            Due {yearData.filingDeadline}
          </div>
        </div>

        {/* Summary grid */}
        <div className="grid grid-cols-2 gap-3">
          <SummaryCard
            icon={CurrencyDollar}
            label="Total Income"
            value={`$${(yearData.totalIncome || 0).toLocaleString()}`}
            trend="up"
          />
          <SummaryCard
            icon={Percent}
            label="Effective Rate"
            value={`${yearData.effectiveRate || 0}%`}
          />
          <SummaryCard
            icon={ArrowUpRight}
            label="Estimated Tax"
            value={`$${(yearData.estimatedTax || 0).toLocaleString()}`}
          />
          <SummaryCard
            icon={ArrowDownRight}
            label="Remaining"
            value={`$${remaining.toLocaleString()}`}
            highlight={remaining > 0}
          />
        </div>
      </section>

      {/* Schedule C breakdown */}
      {yearData.scheduleC && (
        <section className="milli-card rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Buildings size={18} className="text-volt" />
            <h3 className="text-white text-[15px] font-semibold">Schedule C Breakdown</h3>
          </div>
          <div className="space-y-2">
            <Row label="Gross Receipts" value={`$${yearData.scheduleC.grossReceipts.toLocaleString()}`} />
            <Row label="Returns & Allowances" value={`$${yearData.scheduleC.returns.toLocaleString()}`} />
            <Row label="Total Deductions" value={`$${yearData.scheduleC.deductions.toLocaleString()}`} />
            <Row label="Net Profit" value={`$${yearData.scheduleC.netProfit.toLocaleString()}`} bold />
            <Row label="Self-Employment Tax" value={`$${yearData.scheduleC.seTax.toLocaleString()}`} />
          </div>
        </section>
      )}

      {/* Deductions */}
      {yearData.deductions && (
        <section className="milli-card rounded-2xl p-4">
          <h3 className="text-white text-[15px] font-semibold mb-3">Deductions</h3>
          <div className="space-y-2">
            {yearData.deductions.map((d, i) => (
              <Row key={i} label={d.label} value={`$${d.amount.toLocaleString()}`} />
            ))}
            <div className="border-t border-white/5 pt-2 mt-2">
              <Row label="Total Deductions" value={`$${yearData.deductions.reduce((s, d) => s + d.amount, 0).toLocaleString()}`} bold />
            </div>
          </div>
        </section>
      )}

      {/* Quarterly payments */}
      {yearData.quarterly && (
        <section className="milli-card rounded-2xl p-4">
          <h3 className="text-white text-[15px] font-semibold mb-3">Quarterly Estimated Payments</h3>
          <div className="space-y-2">
            {yearData.quarterly.map((q) => (
              <div key={q.q} className="flex items-center justify-between py-2 border-b border-white/5 last:border-0">
                <div className="flex items-center gap-3">
                  <div
                    className="w-9 h-9 rounded-lg flex items-center justify-center text-[12px] font-bold"
                    style={{
                      background: q.paid ? "rgba(52,211,153,0.1)" : "rgba(0,229,255,0.08)",
                      color: q.paid ? "#34D399" : "#00E5FF",
                    }}
                  >
                    {q.q}
                  </div>
                  <div>
                    <div className="text-white text-[13px] font-medium">{q.q} Payment</div>
                    <div className="text-zinc-500 text-[11px]">Due {q.due}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white text-[14px] font-semibold tabular-nums">${q.amount.toLocaleString()}</span>
                  {q.paid ? (
                    <CheckCircle size={16} weight="fill" className="text-green-400" />
                  ) : (
                    <Clock size={16} className="text-yellow-400" />
                  )}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Action buttons */}
      <div className="grid grid-cols-2 gap-3">
        <button
          className="milli-card rounded-2xl py-3 flex items-center justify-center gap-2 text-[14px] font-semibold text-volt active:scale-[0.99] transition"
          style={{ border: "1px solid rgba(0,229,255,0.2)" }}
        >
          <Download size={18} />
          Export PDF
        </button>
        <button
          className="rounded-2xl py-3 flex items-center justify-center gap-2 text-[14px] font-bold text-black active:scale-[0.99] transition"
          style={{ background: "#D4FF00" }}
        >
          <FileText size={18} weight="bold" />
          E-File Now
        </button>
      </div>
    </div>
  );
}

function SummaryCard({ icon: Icon, label, value, trend, highlight }) {
  return (
    <div
      className="rounded-2xl p-3.5"
      style={{ background: "rgba(10,14,18,0.6)", border: "1px solid rgba(255,255,255,0.04)" }}
    >
      <div className="flex items-center gap-1.5 mb-1">
        <Icon size={14} className="text-zinc-500" />
        <span className="text-zinc-500 text-[11px] uppercase tracking-wide">{label}</span>
      </div>
      <div className={`text-[18px] font-bold tabular-nums ${highlight ? "text-yellow-400" : "text-white"}`}>
        {value}
      </div>
    </div>
  );
}

function Row({ label, value, bold }) {
  return (
    <div className="flex items-center justify-between">
      <span className={`text-[13px] ${bold ? "text-white font-semibold" : "text-zinc-400"}`}>{label}</span>
      <span className={`text-[13px] tabular-nums ${bold ? "text-white font-bold" : "text-zinc-300"}`}>{value}</span>
    </div>
  );
}