import { useState } from "react";
import { Link } from "react-router-dom";
import { PiggyBank, ChartLineUp, Gauge, CaretRight, Sparkle } from "@phosphor-icons/react";
import MilliCentsWidget from "@/components/MilliCentsWidget";

export default function Wealth() {
  const [showMilliCents, setShowMilliCents] = useState(false);

  return (
    <div className="wealth-page">
      <section className="wealth-hero">
        <div className="wealth-kicker"><Sparkle size={12} weight="fill" /> Milli Wealth</div>
        <h1>Build wealth from every payout.</h1>
        <p>Retirement, investing, and smarter profitability tools designed for gig workers.</p>
      </section>

      <section className="wealth-grid" aria-label="Wealth tools">
        <Link to="/app/retirement" className="wealth-card" data-testid="wealth-retirement">
          <div className="wealth-card-icon"><PiggyBank size={24} weight="duotone" /></div>
          <div className="wealth-card-copy">
            <div className="wealth-card-eyebrow">Long-term security</div>
            <h2>Retirement</h2>
            <p>Set contributions and build a retirement plan around variable income.</p>
          </div>
          <CaretRight size={18} weight="bold" className="wealth-card-arrow" />
        </Link>

        <Link to="/app/investing" className="wealth-card" data-testid="wealth-investing">
          <div className="wealth-card-icon"><ChartLineUp size={24} weight="duotone" /></div>
          <div className="wealth-card-copy">
            <div className="wealth-card-eyebrow">Grow beyond the grind</div>
            <h2>Investing</h2>
            <p>Choose a strategy and automate contributions from future payouts.</p>
          </div>
          <CaretRight size={18} weight="bold" className="wealth-card-arrow" />
        </Link>

        <button type="button" className="wealth-card wealth-card-button" onClick={() => setShowMilliCents(true)} data-testid="wealth-milli-cents">
          <div className="wealth-card-icon"><Gauge size={24} weight="duotone" /></div>
          <div className="wealth-card-copy">
            <div className="wealth-card-eyebrow">Profitability engine</div>
            <h2>Milli Cents</h2>
            <p>Estimate net value after mileage, fuel, taxes, and unpaid driving distance.</p>
          </div>
          <CaretRight size={18} weight="bold" className="wealth-card-arrow" />
        </button>
      </section>

      {showMilliCents && <MilliCentsWidget onClose={() => setShowMilliCents(false)} />}
    </div>
  );
}
