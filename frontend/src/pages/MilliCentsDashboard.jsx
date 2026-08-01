import { useCallback, useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  Gauge, Lightning, MapPin, GasPump, HouseLine, CurrencyDollar,
  ArrowClockwise, CheckCircle, WarningCircle, XCircle, PlugsConnected,
  ShieldCheck, ShareNetwork, Timer, LockKey,
} from "@phosphor-icons/react";
import { useAuth } from "@/context/AuthContext";
import { calculateProfit, verdict } from "@/lib/milli-cents";
import {
  fetchActiveOffers,
  fetchPlatformConnections,
  sourceLabel,
  subscribeToNativeOffers,
} from "@/lib/gigOfferService";

const verdictMeta = {
  ACCEPT: { icon: CheckCircle, title: "Accept", className: "is-accept" },
  MARGINAL: { icon: WarningCircle, title: "Marginal", className: "is-marginal" },
  DECLINE: { icon: XCircle, title: "Decline", className: "is-decline" },
};

function analyze(offer) {
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
  return {
    result,
    decision: verdict(result, {
      minimumNetPerMile: offer.minimumNetPerMile,
      minimumNetPerHour: offer.minimumNetPerHour,
    }),
  };
}

function secondsRemaining(expiresAt, now) {
  if (!expiresAt) return null;
  return Math.max(0, Math.ceil((new Date(expiresAt).getTime() - now) / 1000));
}

function formatCountdown(seconds) {
  if (seconds == null) return "Limited time";
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return mins > 0 ? `${mins}:${String(secs).padStart(2, "0")}` : `${secs}s`;
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
    fetchPlatformConnections().then((rows) => { if (active) setConnections(rows); }).catch(() => {});
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

  const selectedOffer = activeOffers.find((offer) => offer.id === selectedId) || activeOffers[0] || null;
  const analysis = selectedOffer ? analyze(selectedOffer) : null;
  const meta = analysis ? verdictMeta[analysis.decision] : null;
  const VerdictIcon = meta?.icon;

  if (!hasAccess) {
    return (
      <div className="cents-page">
        <section className="cents-header">
          <div>
            <div className="cents-kicker"><Gauge size={13} weight="fill" /> Milli Cents</div>
            <h1>Know which offer is actually worth it.</h1>
            <p>Compare time-limited offers after pickup miles, delivery distance, return-to-base travel, fuel, vehicle costs, and estimated taxes.</p>
          </div>
        </section>
        <section className="cents-offer-card cents-empty-state">
          <div className="cents-verdict-icon"><LockKey size={28} weight="duotone" /></div>
          <h2>Included with Pro and Elite</h2>
          <p>Upgrade to unlock automatic offer detection, live countdowns, side-by-side profitability comparisons, and instant Accept, Marginal, or Decline guidance.</p>
          <Link to="/app/pricing" className="btn-volt" style={{ marginTop: 18, display: "inline-flex", padding: "12px 18px", borderRadius: 14, textDecoration: "none" }}>
            View Pro and Elite
          </Link>
        </section>
      </div>
    );
  }

  return (
    <div className="cents-page">
      <section className="cents-header">
        <div>
          <div className="cents-kicker"><Gauge size={13} weight="fill" /> Milli Cents</div>
          <h1>Choose the best offer before time runs out.</h1>
          <p>Milli compares simultaneous offers from supported on-demand platforms and evaluates the full work cycle—not just the advertised payout.</p>
        </div>
        <button type="button" className="cents-refresh" onClick={() => loadOffers()} disabled={scanning}>
          <ArrowClockwise size={17} className={scanning ? "is-spinning" : ""} />
          {scanning ? "Checking" : "Refresh"}
        </button>
      </section>

      <section className="cents-connected" aria-label="Connected gig platforms">
        <div className="cents-connected-title"><PlugsConnected size={15} weight="duotone" /> Supported live-offer connections</div>
        <div className="cents-platform-row">
          {connections.length ? connections.map((connection) => (
            <span key={connection.platform || connection.id} className="is-current">
              {connection.display_name || connection.platform}
            </span>
          )) : <span>Connect Uber, Spark, DoorDash, Instacart, Grubhub, or Shipt</span>}
        </div>
      </section>

      {activeOffers.length > 1 && (
        <section className="cents-connected" aria-label="Active offers">
          <div className="cents-connected-title"><Timer size={15} weight="duotone" /> {activeOffers.length} offers available now</div>
          <div className="cents-platform-row">
            {activeOffers.map((offer) => {
              const item = analyze(offer);
              const remaining = secondsRemaining(offer.expiresAt, now);
              return (
                <button
                  key={offer.id}
                  type="button"
                  onClick={() => setSelectedId(offer.id)}
                  className={offer.id === selectedOffer?.id ? "is-current" : ""}
                  style={{ border: 0, cursor: "pointer" }}
                >
                  {offer.platform} · ${offer.offeredPay.toFixed(2)} · {item.decision} · {formatCountdown(remaining)}
                </button>
              );
            })}
          </div>
        </section>
      )}

      {!selectedOffer ? (
        <section className="cents-offer-card cents-empty-state">
          <div className="cents-verdict-icon"><Lightning size={30} weight="duotone" /></div>
          <h2>Waiting for the next time-limited offer</h2>
          <p>Milli Cents watches supported selectable-offer platforms. Scheduled block products such as Amazon Flex are intentionally excluded.</p>
          <div className="cents-assumptions">
            <div><ShieldCheck size={15} weight="duotone" /> Every recommendation shows its source and confidence.</div>
            <div><ShareNetwork size={15} weight="duotone" /> The driver always makes the final accept or decline decision.</div>
          </div>
        </section>
      ) : (
        <>
          <section className="cents-offer-card">
            <div className="cents-offer-topline">
              <div>
                <div className="cents-label">Time-limited offer</div>
                <div className="cents-platform"><Lightning size={14} weight="fill" /> {selectedOffer.platform}</div>
                <div className="cents-source-line">{sourceLabel(selectedOffer.source)} · {Math.round(selectedOffer.confidence * 100)}% confidence</div>
                <div className="cents-source-line"><Timer size={12} /> {formatCountdown(secondsRemaining(selectedOffer.expiresAt, now))} remaining</div>
              </div>
              <div className="cents-offer-pay"><span>$</span>{selectedOffer.offeredPay.toFixed(2)}</div>
            </div>

            <div className="cents-route-strip">
              <Metric icon={MapPin} label="To pickup" value={`${selectedOffer.pickupMiles.toFixed(1)} mi`} />
              <Metric icon={MapPin} label="Offer route" value={`${selectedOffer.routeMiles.toFixed(1)} mi`} />
              <Metric icon={HouseLine} label="Return to base" value={`${selectedOffer.returnToBaseMiles.toFixed(1)} mi`} emphasized />
            </div>

            <div className={`cents-verdict ${meta.className}`}>
              <div className="cents-verdict-icon"><VerdictIcon size={28} weight="fill" /></div>
              <div>
                <div className="cents-verdict-label">Milli verdict</div>
                <h2>{meta.title}</h2>
                <p>{analysis.decision === "ACCEPT" ? "This offer clears your saved net-per-mile and net-per-hour targets." : analysis.decision === "MARGINAL" ? "This offer is close to your minimum and could lose value from traffic or wait time." : "This offer does not adequately cover the complete trip and your minimum profit targets."}</p>
              </div>
            </div>
          </section>

          <section className="cents-breakdown">
            <h2>True-cycle profitability</h2>
            <div className="cents-breakdown-grid">
              <Breakdown label="Total working miles" value={`${analysis.result.totalMiles.toFixed(1)} mi`} subvalue="Pickup + route + return to base" />
              <Breakdown label="Gross per mile" value={`$${analysis.result.grossPerMile.toFixed(2)}`} subvalue="Before costs and taxes" />
              <Breakdown label="Estimated fuel" value={`-$${analysis.result.fuelCost.toFixed(2)}`} subvalue={`${selectedOffer.vehicleMpg} MPG at $${selectedOffer.gasPrice.toFixed(2)}/gal`} negative />
              <Breakdown label="Vehicle operating cost" value={`-$${analysis.result.operatingCost.toFixed(2)}`} subvalue={`$${selectedOffer.vehicleCostPerMile.toFixed(2)} per mile`} negative />
              <Breakdown label="Estimated taxes" value={`-$${analysis.result.taxOwed.toFixed(2)}`} subvalue={`${selectedOffer.taxRate}% reserve estimate`} negative />
              <Breakdown label="Net profit" value={`$${analysis.result.profit.toFixed(2)}`} subvalue={`${analysis.result.profitMargin.toFixed(0)}% margin`} highlight />
              <Breakdown label="Net per mile" value={`$${analysis.result.netPerMile.toFixed(2)}`} subvalue={`Target $${selectedOffer.minimumNetPerMile.toFixed(2)}`} />
              <Breakdown label="Net per hour" value={analysis.result.netPerHour > 0 ? `$${analysis.result.netPerHour.toFixed(2)}` : "Not available"} subvalue={analysis.result.netPerHour > 0 ? `Target $${selectedOffer.minimumNetPerHour.toFixed(2)}` : "Platform did not provide time"} />
            </div>
          </section>

          <section className="cents-assumptions">
            <div><GasPump size={15} weight="duotone" /> Fuel and vehicle assumptions come from the member’s saved vehicle profile.</div>
            <div><CurrencyDollar size={15} weight="duotone" /> Tax estimates update from the member’s Milli tax profile.</div>
          </section>
        </>
      )}
    </div>
  );
}

function Metric({ icon: Icon, label, value, emphasized = false }) {
  return <div className={`cents-route-metric ${emphasized ? "is-emphasized" : ""}`}><Icon size={16} weight="duotone" /><div><span>{label}</span><strong>{value}</strong></div></div>;
}

function Breakdown({ label, value, subvalue, negative = false, highlight = false }) {
  return <div className={`cents-breakdown-item ${highlight ? "is-highlight" : ""}`}><span>{label}</span><strong className={negative ? "is-negative" : ""}>{value}</strong><small>{subvalue}</small></div>;
}
