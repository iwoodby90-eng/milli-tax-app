import SmartAccount from "@/components/SmartAccount";
import { ChartLineUp } from "@phosphor-icons/react";

const config = {
  section: "Investing · Brokerage",
  title: "Investing",
  heading: "Build wealth on autopilot.",
  sub: "A user-owned brokerage account. Milli auto-invests a % from every payout.",
  emptyTitle: "Open your investing account.",
  emptyBody:
    "Set a small % of every payout to flow into a diversified brokerage account. Milli auto-invests on each deposit — dollar-cost averaging without thinking about it.",
  setupCta: "Open brokerage",
  defaultPct: 0.05,
  accountType: "User-owned brokerage",
  icon: ChartLineUp,
  legal:
    "Milli partners with a licensed broker-dealer. The brokerage account is held in your name. Investments are subject to market risk and may lose value. This is not investment advice. Securities offered through partner broker-dealer; Milli is not a broker-dealer or investment advisor.",
  disclaimer:
    "Demo brokerage sandbox. In production, contributions are routed via authorized ACH to your Milli Invest partner.",
};

export default function Investing() {
  return <SmartAccount kind="investing" config={config} />;
}
