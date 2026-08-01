import { Link } from "react-router-dom";
import { PiggyBank, ChartLineUp, CaretRight, Sparkle } from "@phosphor-icons/react";

export default function Wealth() {
  return (
    <div className="wealth-page">
      <section className="wealth-hero">
        <div className="wealth-kicker"><Sparkle size={12} weight="fill" /> Milli Wealth</div>
        <h1>Build wealth from every payout.</h1>
        <p>Retirement and investing designed around variable gig income, with clear controls and automatic contributions.</p>
      </section>

      <section className="wealth-grid" aria-label="Wealth tools">
        <Link to="/app/retirement" className="wealth-card" data-testid="wealth-retirement">
          <div className="wealth-card-icon"><PiggyBank size={24} weight="duotone" /></div>
          <div className="wealth-card-copy">
            <div className="wealth-card-eyebrow">Long-term security</div>
            <h2>Retirement</h2>
            <p>Set contribution targets and build a retirement plan around variable income.</p>
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
      </section>
    </div>
  );
}
