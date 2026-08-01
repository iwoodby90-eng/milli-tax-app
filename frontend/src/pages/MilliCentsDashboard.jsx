import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Gauge, Lightning, MapPin, GasPump, HouseLine, CurrencyDollar,
  ArrowClockwise, CheckCircle, WarningCircle, XCircle, PlugsConnected,
  ShieldCheck, ShareNetwork,
} from "@phosphor-icons/react";
import { calculateProfit, verdict } from "@/lib/milli-cents";
import {
  fetchCurrentOffer,
  fetchPlatformConnections,
  normalizeGigOffer,
  sourceLabel,
  subscribeToNativeOffers,
} from "@/lib/gigOfferService";

const verdictMeta = {
  ACCEPT: {
    icon: CheckCircle,
    title: "Accept",
    copy: "This offer clears your profit-per-mile and profit-per-hour targets after the complete work cycle.",
    className: "is-accept",
  },
  MARGINAL: {
    icon: WarningCircle,
    title: "Marginal",
    copy: "This offer is close to your minimum. Wait time, traffic, or a longer return trip could erase the remaining margin.",
    className: "is-marginal",
  },
  DECLINE: {
    icon: XCircle,
    title: "Decline",
    copy: "The payment does not adequately cover pickup, delivery, return-to-base, operating costs, and estimated taxes.",
    className: "is-decline",
  },
};

export default function MilliCentsDashboard() {
  const [offer, setOffer] = useState(null);
  const [connections, setConnections] = useState([]);
  const [scanning, setScanning] = useState(true);
  const [status, setStatus] = useState("Looking for a new offer…");

  const loadOffer = useCallback(async ({ silent = false } = {}) => {
    if (!silent) setScanning(true);
    try {
      const current = await fetchCurrentOffer();
      if (current) {
        setOffer(current);
        setStatus(`Offer detected from ${current.platform}`);
      } else {
        setStatus("Connected and waiting for the next offer");
      }
    } catch {
      setStatus("Waiting for a platform, shared offer, or screenshot");
    } finally {
      if (!silent) setScanning(false);
    }
  }, []);

  useEffect(() => {
    let active = true;
    fetchPlatformConnections()
      .then((items) => { if (active) setConnections(items); })
      .catch(() => { if (active) setConnections([]); });

    loadOffer();
    const unsubscribe = subscribeToNativeOffers((nextOffer) => {
      setOffer(nextOffer);
      setStatus(`Offer detected from ${nextOffer.platform}`);
      setScanning(false);
    });
    const poll = window.setInterval(() => loadOffer({ silent: true }), 15000);

    return () => {
      active = false;
      unsubscribe();
      window.clearInterval(poll);
    };
  }, [loadOffer]);

  const result = useMemo(() => {
    if (!offer) return null;
    return calculateProfit({
      offerPrice: offer.offeredPay,
      tripDistance: offer.pickupMiles + offer.routeMiles,
      deadheadDistance: offer.returnToBaseMiles,
      gasPrice: offer.gasPrice,
      vehicleMpg: offer.vehicleMpg,
      vehicleCostPerMile: offer.vehicleCostPerMile,
      estimatedMinutes: offer.estimatedMinutes,
      taxSlice: offer.taxRate / 100,
    });
  }, [offer]);

  const decision = result
    ? verdict(result, {
        minimumNetPerMile: offer.minimumNetPerMile,
        minimumNetPerHour: offer.minimumNetPerHour,
      })
    : null;
  const meta = decision ? verdictMeta[decision] : null;
  const VerdictIcon = meta?.icon;

  return (
    <div className="cents-page">
      <section className="cents-header">
        <div>
          <div className="cents-kicker"><Gauge size={13} weight="fill" /> Milli Cents</div>
          <h1>Is this offer worth it?</h1>
          <p>Milli evaluates the complete work cycle automatically—not just the miles advertised by the platform.</p>
        </div>
        <button type="button" className="cents-refresh" onClick={() => loadOffer()} disabled={scanning}>
          <ArrowClockwise size={17} className={scanning ? "is-spinning" : ""} />
          {scanning ? "Checking" : "Check now"}
        </button>
      </section>

      <section className="cents-connected" aria-label="Connected gig platforms">
        <div className="cents-connected-title"><PlugsConnected size={15} weight="duotone" /> Platform connections</div>
        <div className="cents-platform-row">
          {connections.length > 0 ? connections.map((connection) => (
            <span key={connection.platform || connection.id} className={connection.connected === false ? "" : "is-current"}>
              {connection.display_name || connection.platform || connection.id}
            </span>
          )) : <span>{status}</span>}
        </div>
      </section>

      {!offer ? (
        <section className="cents-offer-card cents-empty-state">
          <div className="cents-verdict-icon"><Lightning size={30} weight="duotone" /></div>
          <h2>Ready for the next offer</h2>
          <p>{status}. On Android, authorized notification detection can feed supported offers automatically. On iPhone, official connections, Share to Milli, or on-device screenshot recognition can supply the offer.</p>
          <div className="cents-assumptions">
            <div><ShieldCheck size={15} weight="duotone" /> Milli shows the source and confidence before recommending a decision.</div>
            <div><ShareNetwork size={15} weight="duotone" /> The final accept or decline action always stays with the driver.</div>
          </div>
        </section>
      ) : (
        <>
          <section className="cents-offer-card">
            <div className="cents-offer-topline">
              <div>
                <div className="cents-label">New offer detected</div>
                <div className="cents-platform"><Lightning size={14} weight="fill" /> {offer.platform}</div>
                <div className="cents-source-line">
                  {sourceLabel(offer.source)} · {Math.round(offer.confidence * 100)}% confidence
                </div>
              </div>
              <div className="cents-offer-pay"><span>$</span>{offer.offeredPay.toFixed(2)}</div>
            </div>

            <div className="cents-route-strip">
              <Metric icon={MapPin} label="To pickup" value={`${offer.pickupMiles.toFixed(1)} mi`} />
              <Metric icon={MapPin} label="Offer route" value={`${offer.routeMiles.toFixed(1)} mi`} />
              <Metric icon={HouseLine} label="Return to base" value={`${offer.returnToBaseMiles.toFixed(1)} mi`} emphasized />
            </div>

            <div className={`cents-verdict ${meta.className}`}>
              <div className="cents-verdict-icon"><VerdictIcon size={28} weight="fill" /></div>
              <div>
                <div className="cents-verdict-label">Milli verdict</div>
                <h2>{meta.title}</h2>
                <p>{meta.copy}</p>
              </div>
            </div>
          </section>

          <section className="cents-breakdown">
            <h2>True-cycle profitability</h2>
            <div className="cents-breakdown-grid">
              <Breakdown label="Total working miles" value={`${result.totalMiles.toFixed(1)} mi`} subvalue="Pickup + route + return to home base" />
              <Breakdown label="Gross per mile" value={`$${result.grossPerMile.toFixed(2)}`} subvalue="Before costs and taxes" />
              <Breakdown label="Estimated fuel" value={`-$${result.fuelCost.toFixed(2)}`} subvalue={`${offer.vehicleMpg} MPG at $${offer.gasPrice.toFixed(2)}/gal`} negative />
              <Breakdown label="Vehicle operating cost" value={`-$${result.operatingCost.toFixed(2)}`} subvalue={`$${offer.vehicleCostPerMile.toFixed(2)} per mile model`} negative />
              <Breakdown label="Estimated taxes" value={`-$${result.taxOwed.toFixed(2)}`} subvalue={`${offer.taxRate}% reserve estimate`} negative />
              <Breakdown label="Net profit" value={`$${result.profit.toFixed(2)}`} subvalue={`${result.profitMargin.toFixed(0)}% margin`} highlight />
              <Breakdown label="Net per mile" value={`$${result.netPerMile.toFixed(2)}`} subvalue={`Target $${offer.minimumNetPerMile.toFixed(2)}`} />
              <Breakdown label="Net per hour" value={result.netPerHour > 0 ? `$${result.netPerHour.toFixed(2)}` : "Not available"} subvalue={result.netPerHour > 0 ? `Target $${offer.minimumNetPerHour.toFixed(2)}` : "Platform did not provide time"} />
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
  return (
    <div className={`cents-route-metric ${emphasized ? "is-emphasized" : ""}`}>
      <Icon size={16} weight="duotone" />
      <div><span>{label}</span><strong>{value}</strong></div>
    </div>
  );
}

function Breakdown({ label, value, subvalue, negative = false, highlight = false }) {
  return (
    <div className={`cents-breakdown-item ${highlight ? "is-highlight" : ""}`}>
      <span>{label}</span>
      <strong className={negative ? "is-negative" : ""}>{value}</strong>
      <small>{subvalue}</small>
    </div>
  );
}

export { normalizeGigOffer };
