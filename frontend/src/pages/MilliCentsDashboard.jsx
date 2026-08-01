import { useMemo, useState } from "react";
import {
  Gauge, Lightning, MapPin, GasPump, HouseLine, CurrencyDollar,
  ArrowClockwise, CheckCircle, WarningCircle, XCircle, PlugsConnected,
} from "@phosphor-icons/react";
import { calculateProfit, verdict } from "@/lib/milli-cents";

const connectedPlatforms = ["Uber", "DoorDash", "Spark", "Amazon Flex"];

const verdictMeta = {
  ACCEPT: {
    icon: CheckCircle,
    title: "Accept",
    copy: "This offer clears your profitability target after operating costs and estimated taxes.",
    className: "is-accept",
  },
  MARGINAL: {
    icon: WarningCircle,
    title: "Marginal",
    copy: "This offer is close to your minimum. Traffic, wait time, or an unpaid return trip could erase the profit.",
    className: "is-marginal",
  },
  DECLINE: {
    icon: XCircle,
    title: "Decline",
    copy: "The payment does not adequately cover the full trip, operating costs, taxes, and return-to-base distance.",
    className: "is-decline",
  },
};

export default function MilliCentsDashboard() {
  const [offer, setOffer] = useState({
    platform: "Amazon Flex",
    pay: 78,
    deliveryMiles: 42,
    pickupMiles: 6.4,
    returnMiles: 18,
    gasPrice: 3.49,
    mpg: 24,
    taxRate: 25,
  });
  const [scanning, setScanning] = useState(false);

  const result = useMemo(() => {
    const totalTripMiles = offer.deliveryMiles + offer.pickupMiles;
    return calculateProfit({
      offerPrice: offer.pay,
      tripDistance: totalTripMiles,
      deadheadDistance: offer.returnMiles,
      gasPrice: offer.gasPrice,
      vehicleMpg: offer.mpg,
      taxSlice: offer.taxRate / 100,
    });
  }, [offer]);

  const decision = verdict(result);
  const meta = verdictMeta[decision];
  const VerdictIcon = meta.icon;
  const totalMiles = offer.deliveryMiles + offer.pickupMiles + offer.returnMiles;
  const grossPerMile = totalMiles > 0 ? offer.pay / totalMiles : 0;

  function refreshOffer() {
    setScanning(true);
    window.setTimeout(() => setScanning(false), 900);
  }

  return (
    <div className="cents-page">
      <section className="cents-header">
        <div>
          <div className="cents-kicker"><Gauge size={13} weight="fill" /> Milli Cents</div>
          <h1>Is this offer worth it?</h1>
          <p>Milli checks the complete trip—not just the advertised miles—before you commit.</p>
        </div>
        <button type="button" className="cents-refresh" onClick={refreshOffer} disabled={scanning}>
          <ArrowClockwise size={17} className={scanning ? "is-spinning" : ""} />
          {scanning ? "Checking" : "Refresh"}
        </button>
      </section>

      <section className="cents-connected" aria-label="Connected gig platforms">
        <div className="cents-connected-title"><PlugsConnected size={15} weight="duotone" /> Connected platforms</div>
        <div className="cents-platform-row">
          {connectedPlatforms.map((platform) => (
            <span key={platform} className={platform === offer.platform ? "is-current" : ""}>{platform}</span>
          ))}
        </div>
      </section>

      <section className="cents-offer-card">
        <div className="cents-offer-topline">
          <div>
            <div className="cents-label">New offer detected</div>
            <div className="cents-platform"><Lightning size={14} weight="fill" /> {offer.platform}</div>
          </div>
          <div className="cents-offer-pay">
            <span>$</span>{offer.pay.toFixed(2)}
          </div>
        </div>

        <div className="cents-route-strip">
          <Metric icon={MapPin} label="To pickup" value={`${offer.pickupMiles.toFixed(1)} mi`} />
          <Metric icon={MapPin} label="Offer route" value={`${offer.deliveryMiles.toFixed(1)} mi`} />
          <Metric icon={HouseLine} label="Return to base" value={`${offer.returnMiles.toFixed(1)} mi`} emphasized />
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
        <h2>Profitability breakdown</h2>
        <div className="cents-breakdown-grid">
          <Breakdown label="Total working miles" value={`${totalMiles.toFixed(1)} mi`} subvalue="Includes return to home base" />
          <Breakdown label="Gross per mile" value={`$${grossPerMile.toFixed(2)}`} subvalue="Before costs and taxes" />
          <Breakdown label="Estimated fuel" value={`-$${result.fuelCost.toFixed(2)}`} subvalue={`${offer.mpg} MPG at $${offer.gasPrice.toFixed(2)}/gal`} negative />
          <Breakdown label="Estimated taxes" value={`-$${result.taxOwed.toFixed(2)}`} subvalue={`${offer.taxRate}% reserve estimate`} negative />
          <Breakdown label="Net profit" value={`$${result.profit.toFixed(2)}`} subvalue={`${result.profitMargin.toFixed(0)}% margin`} highlight />
          <Breakdown label="Net per mile" value={`$${result.costPerMile.toFixed(2)}`} subvalue="After modeled costs" />
        </div>
      </section>

      <section className="cents-assumptions">
        <div><GasPump size={15} weight="duotone" /> Fuel and vehicle assumptions are editable in Milli Cents settings.</div>
        <div><CurrencyDollar size={15} weight="duotone" /> Tax estimates are guidance and update with the member’s tax profile.</div>
      </section>
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
