import { useCallback, useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  ArrowClockwise,
  CheckCircle,
  CurrencyDollar,
  GasPump,
  Gauge,
  HouseLine,
  Lightning,
  LockKey,
  MapPin,
  PlugsConnected,
  ShieldCheck,
  Timer,
  WarningCircle,
  XCircle,
} from "@phosphor-icons/react";
import { useAuth } from "@/context/AuthContext";
import { calculateProfit, verdict } from "@/lib/milli-cents";
import {
  fetchActiveOffers,
  fetchPlatformConnections,
  sourceLabel,
  subscribeToNativeOffers,
} from "@/lib/gigOfferService";

const decisionMeta = {
  ACCEPT: {
    label: "GO",
    title: "Profitable",
    className: "is-go",
    icon: CheckCircle,
    copy: "This offer clears your saved net-per-mile and net-per-hour goals.",
  },
  MARGINAL: {
    label: "MAYBE",
    title: "Borderline",
    className: "is-maybe",
    icon: WarningCircle,
    copy: "This offer is close to your minimum. Traffic, wait time, or a longer return could erase the profit.",
  },
  DECLINE: {
    label: "NO",
    title: "Not profitable",
    className: "is-no",
    icon: XCircle,
    copy: "The complete work cycle does not adequately cover mileage, fuel, vehicle cost, and taxes.",
  },
};

function analyzeOffer(offer) {
  const result = calculateProfit({
    offerPrice: offer.offeredPay,
    tripDistance: offer.pickupMiles + offer.routeMiles,
    deadheadDistance: offer.returnToBaseMiles,
    gasPrice: offer.gasPrice,
    vehicleMpg: offer.vehicleMpg,
    vehicleCostPerMile: offer.vehicleCostPerMile,
    estimatedMinutes: offer.estimatedMinutes,
    taxSlice: offer.taxRate / 100,
  });

  const decision = verdict(result, {
    minimumNetPerMile: offer.minimumNetPerMile,
    minimumNetPerHour: offer.minimumNetPerHour,
  });

  const mileRatio = result.netPerMile / Math.max(offer.minimumNetPerMile || 1, 0.01);
  const hourRatio = result.netPerHour > 0
    ? result.netPerHour / Math.max(offer.minimumNetPerHour || 1, 0.01)
    : mileRatio;
  const profitScore = Math.max(0, Math.min(100, Math.round(((mileRatio * 0.58) + (hourRatio * 0.42)) * 72)));

  return { offer, result, decision, profitScore, meta: decisionMeta[decision] };
}

function secondsRemaining(expiresAt, now) {
  if (!expiresAt) return null;
  return Math.max(0, Math.ceil((new Date(expiresAt).getTime() - now) / 1000));
}

function formatCountdown(seconds) {
  if (seconds == null) return "Limited time";
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return minutes > 0 ? `${minutes}:${String(remainder).padStart(2, "0")}` : `${remainder}s`;
}

function money(value) {
  return `$${Number(value || 0).toFixed(2)}`;
}

export default function MilliCentsDashboard() {
  const { user } = useAuth();
  const plan = String(user?.plan || "trial").toLowerCase();
  const hasAccess = plan === "pro" || plan === "elite";

  const [offers, setOffers] = useState([]);
  const [selectedId, setSelectedId] = useState(null);
  const [connections, setConnections] = useState([]);
  const [scanning, setScanning] = useState(true);
  const [now, setNow] = useState(Date.now());

  const loadOffers = useCallback(async ({ silent = false } = {}) => {
    if (!hasAccess) return;
    if (!silent) setScanning(true);
    try {
      const rows = await fetchActiveOffers();
      setOffers(rows);
      setSelectedId((current) => rows.some((offer) => offer.id === current) ? current : rows[0]?.id ?? null);
    } finally {
      if (!silent) setScanning(false);
    }
  }, [hasAccess]);

  useEffect(() => {
    if (!hasAccess) return undefined;
    let active = true;

    fetchPlatformConnections()
      .then((rows) => { if (active) setConnections(rows); })
      .catch(() => {});

    loadOffers();

    const unsubscribe = subscribeToNativeOffers((offer) => {
      setOffers((current) => [offer, ...current.filter((row) => row.id !== offer.id)]);
      setSelectedId(offer.id);
      setScanning(false);
    });
    const poll = window.setInterval(() => loadOffers({ silent: true }), 5000);
    const clock = window.setInterval(() => setNow(Date.now()), 1000);

    return () => {
      active = false;
      unsubscribe();
      window.clearInterval(poll);
      window.clearInterval(clock);
    };
  }, [hasAccess, loadOffers]);

  const activeOffers = useMemo(() => offers.filter((offer) => {
    const remaining = secondsRemaining(offer.expiresAt, now);
    return remaining == null || remaining > 0;
  }), [offers, now]);

  const analyzedOffers = useMemo(
    () => activeOffers.map(analyzeOffer).sort((a, b) => b.result.profit - a.result.profit),
    [activeOffers],
  );

  const selected = analyzedOffers.find((item) => item.offer.id === selectedId) || analyzedOffers[0] || null;

  if (!hasAccess) {
    return (
      <div className="cents-page">
        <header className="cents-screen-header">
          <div className="cents-brand-line"><Gauge size={15} weight="fill" /> Milli Cents</div>
          <h1>Offer Profitability Engine</h1>
          <p>Know whether the offer deserves your time before the countdown wins.</p>
        </header>

        <section className="cents-access-card">
          <div className="cents-lock"><LockKey size={31} weight="duotone" /></div>
          <h2>Milli Cents is included with Pro and Elite</h2>
          <p>Unlock live multi-offer comparison, pickup and deadhead mileage, return distance, fuel use, taxes, true net profit, and instant GO, MAYBE, or NO guidance.</p>
          <Link to="/app/pricing" className="cents-primary-button">View Pro and Elite</Link>
        </section>
      </div>
    );
  }

  return (
    <div className="cents-page">
      <header className="cents-screen-header">
        <div>
          <div className="cents-brand-line"><Gauge size={15} weight="fill" /> Milli Cents</div>
          <h1>Offer Profitability Engine</h1>
          <p>Analyzing every payable mile—and every unpaid one—before you accept.</p>
        </div>
        <button type="button" className="cents-refresh" onClick={() => loadOffers()} disabled={scanning}>
          <ArrowClockwise size={17} className={scanning ? "is-spinning" : ""} />
          {scanning ? "Scanning" : "Refresh"}
        </button>
      </header>

      <section className="cents-connection-strip">
        <div className="cents-strip-title"><PlugsConnected size={16} weight="duotone" /> Live platform connections</div>
        <div className="cents-platform-chips">
          {connections.length ? connections.map((connection) => (
            <span key={connection.platform || connection.id} className="is-connected">
              {connection.display_name || connection.platform}
            </span>
          )) : <span>Connect Uber, Lyft, Spark, DoorDash, Instacart, Grubhub, or Shipt</span>}
        </div>
      </section>

      {!selected ? (
        <section className="cents-access-card">
          <div className="cents-lock"><Lightning size={31} weight="duotone" /></div>
          <h2>Waiting for the next selectable offer</h2>
          <p>Milli Cents is watching supported platforms. When a new offer appears, the full profitability calculation will populate automatically.</p>
        </section>
      ) : (
        <>
          <section className="cents-live-card" data-testid="milli-cents-live-analysis">
            <div className="cents-live-heading">
              <span>Live Offer Analysis</span>
              <span className="cents-live-pill"><i /> LIVE</span>
            </div>

            <div className="cents-offer-hero">
              <div className="cents-platform-block">
                <div className="cents-platform-logo">{selected.offer.platform?.slice(0, 1) || "M"}</div>
                <div>
                  <strong>{selected.offer.platform}</strong>
                  <span>{sourceLabel(selected.offer.source)} · {Math.round(selected.offer.confidence * 100)}% confidence</span>
                  <small><Timer size={12} /> {formatCountdown(secondsRemaining(selected.offer.expiresAt, now))} remaining</small>
                </div>
              </div>

              <div className="cents-offer-price">
                <strong>{money(selected.offer.offeredPay)}</strong>
                <span>Estimated payout</span>
              </div>

              <ProfitGauge score={selected.profitScore} label={selected.meta.title} />
            </div>

            <div className="cents-cost-table">
              <CostRow label="Offer route" value={`${selected.offer.routeMiles.toFixed(1)} mi`} icon={MapPin} />
              <CostRow label="Pickup distance" value={`${selected.offer.pickupMiles.toFixed(1)} mi`} cost={money((selected.offer.pickupMiles || 0) * selected.offer.vehicleCostPerMile)} icon={MapPin} />
              <CostRow label="Deadhead distance" value={`${(selected.offer.pickupMiles + selected.offer.returnToBaseMiles).toFixed(1)} mi`} cost={money((selected.offer.pickupMiles + selected.offer.returnToBaseMiles) * selected.offer.vehicleCostPerMile)} icon={HouseLine} />
              <CostRow label="Return distance" value={`${selected.offer.returnToBaseMiles.toFixed(1)} mi`} cost={money(selected.offer.returnToBaseMiles * selected.offer.vehicleCostPerMile)} icon={HouseLine} />
              <CostRow label="Estimated gas used" value={`${(selected.result.totalMiles / Math.max(selected.offer.vehicleMpg, 1)).toFixed(2)} gal`} cost={money(selected.result.fuelCost)} icon={GasPump} />
              <CostRow label={`Estimated taxes (${selected.offer.taxRate}%)`} value="Reserve" cost={money(selected.result.taxOwed)} icon={CurrencyDollar} />
              <CostRow label="Vehicle operating cost" value={`${money(selected.offer.vehicleCostPerMile)}/mi`} cost={money(selected.result.operatingCost)} icon={Gauge} />
              <CostRow label="Total estimated costs" value={`${selected.result.totalMiles.toFixed(1)} total mi`} cost={money(selected.result.fuelCost + selected.result.operatingCost + selected.result.taxOwed)} total />
              <CostRow label="Projected net profit" value={`${selected.result.netPerMile.toFixed(2)} net/mi`} cost={money(selected.result.profit)} profit />
            </div>

            <div className={`cents-recommendation ${selected.meta.className}`}>
              <selected.meta.icon size={30} weight="fill" />
              <div>
                <span>Recommendation</span>
                <strong>{selected.meta.label}</strong>
                <p>{selected.meta.copy}</p>
              </div>
              <div className="cents-recommendation-metrics">
                <span>{selected.result.netPerHour > 0 ? money(selected.result.netPerHour) : "—"}<small>net/hour</small></span>
                <span>{selected.result.netPerMile.toFixed(2)}<small>net/mile</small></span>
              </div>
            </div>
          </section>

          <section className="cents-compare-section" data-testid="milli-cents-offer-comparison">
            <div className="cents-section-heading">
              <div>
                <span>Compare Live Offers</span>
                <small>{analyzedOffers.length} available now</small>
              </div>
              <span>Sorted by net profit</span>
            </div>

            <div className="cents-offer-grid">
              {analyzedOffers.map((item, index) => (
                <button
                  type="button"
                  key={item.offer.id}
                  onClick={() => setSelectedId(item.offer.id)}
                  className={`cents-compare-card ${item.offer.id === selected.offer.id ? "is-selected" : ""} ${item.meta.className}`}
                >
                  <div className="cents-rank">{index + 1}</div>
                  <div className="cents-compare-platform">{item.offer.platform}</div>
                  <strong>{money(item.offer.offeredPay)}</strong>
                  <div className="cents-compare-details">
                    <span>{item.result.totalMiles.toFixed(1)} mi total</span>
                    <span>{money(item.result.profit)} net</span>
                  </div>
                  <div className="cents-score-row">
                    <span>{item.profitScore}/100</span>
                    <b>{item.meta.label}</b>
                  </div>
                </button>
              ))}
            </div>
          </section>

          <section className="cents-trust-note">
            <ShieldCheck size={19} weight="duotone" />
            <div>
              <strong>You make the final call.</strong>
              <span>Milli bases each recommendation on your vehicle profile, current fuel assumptions, saved profitability goals, complete mileage cycle, and estimated tax reserve.</span>
            </div>
          </section>
        </>
      )}
    </div>
  );
}

function CostRow({ icon: Icon, label, value, cost, total = false, profit = false }) {
  return (
    <div className={`cents-cost-row ${total ? "is-total" : ""} ${profit ? "is-profit" : ""}`}>
      <div className="cents-cost-label">
        {Icon ? <Icon size={16} weight="duotone" /> : null}
        <span>{label}</span>
      </div>
      <span className="cents-cost-value">{value}</span>
      <strong>{cost}</strong>
    </div>
  );
}

function ProfitGauge({ score, label }) {
  const radius = 47;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - score / 100);

  return (
    <div className="cents-profit-gauge" aria-label={`Profit score ${score} out of 100`}>
      <svg viewBox="0 0 112 112" aria-hidden="true">
        <defs>
          <filter id="cents-gauge-glow"><feGaussianBlur stdDeviation="3.2" result="blur" /><feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge></filter>
        </defs>
        <circle cx="56" cy="56" r={radius} className="cents-gauge-track" />
        <circle
          cx="56"
          cy="56"
          r={radius}
          className="cents-gauge-value"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
        />
      </svg>
      <div>
        <strong>{score}</strong>
        <span>/100</span>
        <small>Profit Score</small>
        <b>{label}</b>
      </div>
    </div>
  );
}
