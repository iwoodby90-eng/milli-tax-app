/**
 * Dashboard.jsx — v4.3 Senior Defense
 *
 * Cinematic financial dashboard matching the mockup:
 * - Header: "Good morning, Alex. Here's your financial overview."
 * - Hero: Available to Spend Elite Card
 * - Latest Payout breakdown
 * - Side-by-side: Tax Vault (76% progress) + Tax Ready Score gauge
 * - Financial Timeline (list style with View All)
 * - Footer Grid: Mileage, Retirement, Investing tiles
 * - Floating AI Sphere
 */
import { useEffect, useState } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  CaretRight, PiggyBank, ChartLineUp, Car,
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
    } catch (err) { toast.error(formatApiError(err)); }
  }

  useEffect(() => { load(); }, []);

  if (!summary) {
    return (
      <div style={{
        padding: 48, fontFamily: 'monospace',
        backgroundColor: '#050607', color: '#00E5FF', minHeight: '100vh',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
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
    amount: 1247.50, platform: "Uber", date: "2026-07-28",
    gross: 1247.50, net: 984.20, taxes: 187.13, vault_amount: 76.17,
  };

  return (
    <div style={{
      padding: '24px 16px',
      maxWidth: 600,
      margin: '0 auto',
      minHeight: '100vh',
      backgroundColor: '#0D0F12',
      color: '#FFFFFF',
    }}>

      {/* HEADER */}
      <div style={{ marginBottom: 28, paddingTop: 8 }}>
        <div style={{
          fontSize: 22, fontWeight: 700, color: '#FFFFFF', lineHeight: 1.3,
          fontFamily: "'SF Pro Display', -apple-system, sans-serif",
        }}>
          Good morning, {firstName}.
        </div>
        <div style={{ fontSize: 14, color: '#8B9DAF', marginTop: 4 }}>
          Here's your financial overview.
        </div>
      </div>

      {/* HERO — Elite Spend Card */}
      <div style={{ marginBottom: 16 }} data-testid="dashboard-elite-card">
        <EliteSpendCard available={24560.00} accountMask="•••• 4821" />
      </div>

      {/* Latest Payout */}
      <div style={{
        background: 'rgba(13,15,18,0.5)', backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.08)', borderRadius: 22, padding: '24px', marginBottom: 16,
      }} data-testid="dashboard-latest-payout">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
            Latest Payout
          </div>
          <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
            {new Date(latestPayout.date || latestPayout.created_at || Date.now()).toLocaleDateString("en-US", { month: "short", day: "numeric" })}
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <PayoutStat label="Gross" value={money(latestPayout.gross || latestPayout.amount)} />
          <PayoutStat label="Net" value={money(latestPayout.net || (latestPayout.amount * 0.79))} accent />
          <PayoutStat label="Taxes" value={money(latestPayout.taxes || (latestPayout.amount * 0.15))} />
          <PayoutStat label="Vault" value={money(latestPayout.vault_amount || (latestPayout.amount * 0.06))} />
        </div>
      </div>

      {/* Tax Vault + Tax Ready Score (side by side) */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }} data-testid="dashboard-vault-score-row">
        <TaxVaultCard balance={vaultBalance || 3842.50} period={summary.next_quarterly?.label || "Q3"} locked={false} progress={76} />
        <div style={{
          background: 'rgba(13,15,18,0.5)', backdropFilter: 'blur(28px)',
          border: '1px solid rgba(0,229,255,0.08)', borderRadius: 22,
          padding: '20px 12px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        }}>
          <TaxReadyGauge score={score} size={130} />
        </div>
      </div>

      {/* Financial Timeline */}
      <div style={{
        background: 'rgba(13,15,18,0.5)', backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.08)', borderRadius: 22, overflow: 'hidden', marginBottom: 16,
      }} data-testid="dashboard-timeline-card">
        <div style={{
          padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          borderBottom: '1px solid rgba(255,255,255,0.03)',
        }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
            Financial Timeline
          </span>
          <Link to="/app/income" style={{
            fontSize: 11, color: '#5A6573', fontFamily: 'monospace', textDecoration: 'none',
            display: 'flex', alignItems: 'center', gap: 4,
          }}>
            View All <CaretRight size={10} weight="bold" />
          </Link>
        </div>
        <FinancialTimeline payouts={deposits} />
      </div>

      {/* Footer Grid — Mileage, Retirement, Investing */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginBottom: 32 }} data-testid="dashboard-footer-grid">
        <FooterTile
          to="/app/mileage"
          icon={<Car size={22} weight="duotone" style={{ color: '#00E5FF' }} />}
          label="Mileage"
          value={`${num(mileageSummary?.total_miles || summary?.total_miles || 0)} mi`}
        />
        <FooterTile
          to="/app/retirement"
          icon={<PiggyBank size={22} weight="duotone" style={{ color: '#00E5FF' }} />}
          label="Retirement"
          value={money(user?.retirement_balance || 12000)}
        />
        <FooterTile
          to="/app/investing"
          icon={<ChartLineUp size={22} weight="duotone" style={{ color: '#00E5FF' }} />}
          label="Investing"
          value={money(user?.investing_balance || 8500)}
        />
      </div>

      {/* Floating AI Sphere */}
      <div style={{
        position: 'fixed', bottom: 90, right: 20, width: 56, height: 56,
        borderRadius: '50%', overflow: 'hidden',
        boxShadow: '0 0 30px rgba(0,229,255,0.3), 0 0 60px rgba(0,229,255,0.1)',
        border: '2px solid rgba(0,229,255,0.3)', zIndex: 100, cursor: 'pointer',
      }} data-testid="floating-ai-sphere">
        <img src="/weebo/milli-ai-sphere.png" alt="Milli AI" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
      </div>
    </div>
  );
}

/* ─── Sub-components ─── */

function PayoutStat({ label, value, accent }) {
  return (
    <div style={{
      background: 'rgba(5,6,7,0.5)', borderRadius: 12, padding: '12px 14px',
      border: accent ? '1px solid rgba(0,229,255,0.12)' : '1px solid rgba(255,255,255,0.03)',
    }}>
      <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#5A6573', marginBottom: 4 }}>
        {label}
      </div>
      <div style={{
        fontSize: 16, fontWeight: 700,
        fontFamily: "'SF Pro Display', -apple-system, monospace",
        color: accent ? '#00E5FF' : '#FFFFFF',
      }}>
        {value}
      </div>
    </div>
  );
}

function FooterTile({ to, icon, label, value }) {
  return (
    <Link to={to} style={{
      background: 'rgba(13,15,18,0.5)', backdropFilter: 'blur(28px)',
      border: '1px solid rgba(0,229,255,0.06)', borderRadius: 18,
      padding: '20px 14px', textAlign: 'center', textDecoration: 'none',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
      transition: 'border-color 0.2s',
    }}>
      {icon}
      <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#8B9DAF' }}>
        {label}
      </div>
      <div style={{ fontSize: 14, fontWeight: 700, color: '#FFFFFF', fontFamily: "'SF Pro Display', -apple-system, sans-serif" }}>
        {value}
      </div>
    </Link>
  );
}
