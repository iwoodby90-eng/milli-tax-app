import SmartAccount from "@/components/SmartAccount";
import { Vault as RetirementIcon } from "@phosphor-icons/react";

const config = {
  section: "Retirement · Solo 401(k)",
  title: "Solo 401(k)",
  heading: "Pay your future self first.",
  sub: "A user-owned retirement account. Milli auto-contributes a % from every payout.",
  emptyTitle: "Open your Solo 401(k).",
  emptyBody:
    "Gig drivers and freelancers can stash up to ~25% of net self-employment earnings (subject to IRS limits) into a Solo 401(k). Milli sets one up through our retirement partner and pulls your chosen % from each payout — automatic, tax-advantaged, and yours.",
  setupCta: "Open my 401(k)",
  defaultPct: 0.08,
  accountType: "User-owned retirement",
  icon: RetirementIcon,
  legal:
    "Milli partners with a licensed retirement custodian. The 401(k) is held in your name. Contributions are subject to IRS annual limits ($23,000 employee deferral for 2026, plus employer profit-sharing up to the combined limit). Withdrawals before age 59½ may incur taxes and penalties. This is not investment, tax, or legal advice.",
  disclaimer:
    "Demo custodian sandbox. In production, contributions move from your checking account to your Milli Retirement partner via authorized ACH transfers.",
};

export default function Retirement() {
  return <SmartAccount kind="retirement" config={config} />;
}
