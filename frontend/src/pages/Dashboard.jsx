/**
 * Dashboard.jsx — v5 cinematic reference alignment
 *
 * Home dashboard behind the raised center M button.
 */
import { useEffect, useState } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  CaretRight, PiggyBank, ChartLineUp, Car, Gauge,
} from "@phosphor-icons/react";
import {
  TaxReadyGauge, FinancialTimeline, TaxVaultCard,
  EliteSpendCard,
} from "@/components/MilliPrimitives";

export default function Dashboard() {
  const { user } = useAuth();
  const [summary, setSummary] = useState(null);
  const [deposits, setDeposits] = useState([]);
  const [trips, setTrips] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [vault, setVault] = useState(null);
  const [mileageSummary, setMileageSummary] = useState(null);

  async function load() {
    try {
      const [s, d, t, e, v, mil] = await Promise.all([
        api.get("/tax/summary"),
        api.get("/deposits"),
        api.get("/trips"),
        api.get("/expenses"),
        api.get("/vault").catch(() => ({ data: null })),
        api.get("/mileage/summary").catch(() => ({ data: null })),
      ]);
      setSummary(s.data);
      setDeposits(d.data || []);
      setTrips(t.data || []);
      setExpenses(e.data || []);
      setVault(v.data);
      setMileageSummary(mil.data);
    } catch (err) {
      toast.error(formatApiError(err));
    }
  }

  useEffect(() => { load(); }, []);

  if (!summary) {
    return (
      <div style={{
        padding: 48,
        fontFamily: "monospace",
        backgroundColor: "#050607",
        color: "#00E5FF",
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}>
        <div className="animate-pulse">[ LOADING MILLI... ]</div>
      </div>
    );
  }

  const checks = {
    income: (deposits?.length || 0) > 0,
    mileage: (trips?.length || 0) > 0,
    expenses: (expenses?.length || 0) > 0,
    quarterly: (summary?.estimated_tax || 0) > 0,
  };
  const filled = Object.values(checks).filter(Boolean).length;
  const score = Number.isFinite(Math.round((filled / 4) * 100)) ? Math.round((filled / 4) * 100) : 85;
  const vaultBalance = vault?.balance ?? summary?.savings_balance ?? 0;
  const firstName = user?.name?.split(" ")[0] || "Alex";

  const latestPayout = (Array.isArray(deposits) && deposits.length > 0) ? deposits[0] : {
    amount: 1247.50,
    platform: "Uber",
    date: "2026-07-28",
    gross: 1247.50,
    net: 984.20,
    taxes: 187.13,
    vault_amount: 76.17,
  };

  return (
    <div style={{
      padding: "24px 16px 28px",
      maxWidth: 600,
      margin: "0 auto",
      minHeight: "100vh",
      color: "#FFFFFF",
    }}>
      <div style={{ marginBottom: 24, paddingTop: 4 }}>
        <div style={{
          fontSize: 31,
          fontWeight: 800,
          color: "#FFFFFF",
          lineHeight: 1.12,
          letterSpacing: "-.035em",
          fontFamily: "'SF Pro Display', -apple-system, sans-serif",
        }}>
          Good morning, {firstName}
        </div>
        <div style={{ fontSize: 14, color: "#9AA5AF", marginTop: 7 }}>
          Here’s your financial overview.
        </div>
      </div>

      <div style={{ marginBottom: 16 }} data-testid="dashboard-elite-card">
        <EliteSpendCard available={24560.00} accountMask="•••• 4587" />
      </div>

      <div style={{
        background: "linear-gradient(180deg,rgba(17,24,30,.92),rgba(8,11,14,.96))",
        backdropFilter: "blur(28px)",
        border: "1px solid rgba(0,229,255,.14)",
        borderRadius: 22,
        padding: 20,
        marginBottom: 14,
        boxShadow: "0 18px 50px rgba(0,0,0,.28),inset 0 1px 0 rgba(255,255,255,.035)",
      }} data-testid="dashboard-latest-payout">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <div style={{ fontSize: 13, fontWeight: 750, color: "#FFFFFF" }}>Latest Payout</div>
          <div style={{ fontSize: 10, color: "#69747E", fontFamily: "monospace" }}>
            {new Date(latestPayout.date || latestPayout.created_at || Date.now()).toLocaleDateString("en-US", { month: "short", day: "numeric" })}
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          <PayoutStat label="Gross Payout" value={money(latestPayout.gross || latestPayout.amount)} />
          <PayoutStat label="Net Payout" value={money(latestPayout.net || (latestPayout.amount * 0.79))} accent />
          <PayoutStat label="Taxes" value={money(latestPayout.taxes || (latestPayout.amount * 0.15))} />
          <PayoutStat label="Milli Tax Vault™" value={money(latestPayout.vault_amount || (latestPayout.amount * 0.06))} accent />
        </div>
      </div>

      <Link
        to="/app/milli-cents"
        data-testid="dashboard-milli-cents-link"
        style={{
          display: "grid",
          gridTemplateColumns: "46px 1fr auto",
          alignItems: "center",
          gap: 12,
          minHeight: 76,
          marginBottom: 14,
          padding: "13px 16px",
          borderRadius: 20,
          border: "1px solid rgba(0,229,255,.38)",
          background: "radial-gradient(circle at 86% 0%,rgba(0,229,255,.15),transparent 28%),linear-gradient(180deg,rgba(16,29,36,.96),rgba(6,11,14,.98))",
          boxShadow: "0 0 24px rgba(0,229,255,.1),inset 0 1px 0 rgba(255,255,255,.06)",
          color: "#FFFFFF",
          textDecoration: "none",
        }}
      >
        <div style={{ width: 46, height: 46, borderRadius: 15, display: "grid", placeItems: "center", color: "#00E5FF", background: "rgba(0,229,255,.1)", border: "1px solid rgba(0,229,255,.25)", boxShadow: "0 0 17px rgba(0,229,255,.11)" }}>
          <Gauge size={25} weight="duotone" />
        </div>
        <div>
          <div style={{ color: "#00E5FF", fontSize: 11, fontWeight: 800, letterSpacing: ".12em", textTransform: "uppercase" }}>Milli Cents</div>
          <div style={{ marginTop: 4, color: "#E8EDF1", fontSize: 13, fontWeight: 650 }}>Analyze live offers before you accept.</div>
        </div>
        <CaretRight size={18} color="#00E5FF" weight="bold" />
      </Link>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 14 }} data-testid="dashboard-vault-score-row">
        <TaxVaultCard balance={vaultBalance || 3842.50} period={summary.next_quarterly?.label || "Q3"} locked={false} progress={76} />
        <div style={{
          background: "linear-gradient(180deg,rgba(16,23,29,.94),rgba(8,11,14,.97))",
          backdropFilter: "blur(28px)",
          border: "1px solid rgba(0,229,255,.18)",
          borderRadius: 22,
          padding: "18px 10px",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 0 22px rgba(0,229,255,.06),inset 0 1px 0 rgba(255,255,255,.035)",
        }}>
          <div style={{ color: "#DCE4EA", fontSize: 11, fontWeight: 700, marginBottom: 4 }}>Tax Ready Score™</div>
          <TaxReadyGauge score={score} size={130} />
        </div>
      </div>

      <div style={{
        background: "linear-gradient(180deg,rgba(16,23,29,.94),rgba(8,11,14,.97))",
        backdropFilter: "blur(28px)",
        border: "1px solid rgba(0,229,255,.13)",
        borderRadius: 22,
        overflow: "hidden",
        marginBottom: 14,
      }} data-testid="dashboard-timeline-card">
        <div style={{
          padding: "16px 20px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          borderBottom: "1px solid rgba(255,255,255,.04)",
        }}>
          <span style={{ fontSize: 13, fontWeight: 720, color: "#FFFFFF" }}>Financial Timeline</span>
          <Link to="/app/income" style={{ fontSize: 11, color: "#00E5FF", textDecoration: "none", display: "flex", alignItems: "center", gap: 4 }}>
            View all <CaretRight size={10} weight="bold" />
          </Link>
        </div>
        <FinancialTimeline payouts={deposits} />
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10, marginBottom: 12 }} data-testid="dashboard-footer-grid">
        <FooterTile
          to="/app/mileage"
          icon={<Car size={22} weight="duotone" style={{ color: "#00E5FF" }} />}
          label="Mileage"
          value={`${num(mileageSummary?.total_miles || summary?.total_miles || 0)} mi`}
        />
        <FooterTile
          to="/app/retirement"
          icon={<PiggyBank size={22} weight="duotone" style={{ color: "#00E5FF" }} />}
          label="Retirement"
          value={money(user?.retirement_balance || 12000)}
        />
        <FooterTile
          to="/app/investing"
          icon={<ChartLineUp size={22} weight="duotone" style={{ color: "#00E5FF" }} />}
          label="Investing"
          value={money(user?.investing_balance || 8500)}
        />
      </div>
    </div>
  );
}

function PayoutStat({ label, value, accent }) {
  return (
    <div style={{
      background: "rgba(2,5,7,.45)",
      borderRadius: 13,
      padding: "12px 13px",
      border: accent ? "1px solid rgba(0,229,255,.17)" : "1px solid rgba(255,255,255,.035)",
    }}>
      <div style={{ fontSize: 9, fontWeight: 650, letterSpacing: ".11em", textTransform: "uppercase", color: "#707B85", marginBottom: 5 }}>
        {label}
      </div>
      <div style={{ fontSize: 16, fontWeight: 750, color: accent ? "#00E5FF" : "#FFFFFF" }}>
        {value}
      </div>
    </div>
  );
}

function FooterTile({ to, icon, label, value }) {
  return (
    <Link to={to} style={{
      background: "linear-gradient(180deg,rgba(17,24,30,.92),rgba(8,11,14,.96))",
      backdropFilter: "blur(28px)",
      border: "1px solid rgba(0,229,255,.12)",
      borderRadius: 18,
      padding: "17px 9px",
      textAlign: "center",
      textDecoration: "none",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 7,
      boxShadow: "inset 0 1px 0 rgba(255,255,255,.035)",
    }}>
      {icon}
      <div style={{ fontSize: 9, fontWeight: 650, letterSpacing: ".08em", textTransform: "uppercase", color: "#98A2AB" }}>
        {label}
      </div>
      <div style={{ fontSize: 13, fontWeight: 750, color: "#FFFFFF" }}>
        {value}
      </div>
    </Link>
  );
}
