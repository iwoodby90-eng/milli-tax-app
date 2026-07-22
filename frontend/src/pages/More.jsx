import { Link } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { useNavigate } from "react-router-dom";
import {
  Shield, Car, FileText, Receipt, Gift, Robot, ChartLineUp, PiggyBank,
  Gear, SignOut, CaretRight, Question, Headset, Star,
} from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

const sections = [
  {
    title: "Financial Tools",
    items: [
      { to: "/app/vault", icon: Shield, label: "Tax Vault", sub: "Protected tax savings" },
      { to: "/app/retirement", icon: PiggyBank, label: "Solo 401(k)", sub: "Retirement auto-deposits" },
      { to: "/app/investing", icon: ChartLineUp, label: "Investing", sub: "Brokerage auto-deposits" },
      { to: "/app/mileage", icon: Car, label: "Mileage Tracker", sub: "IRS-compliant GPS logging" },
      { to: "/app/expenses", icon: Receipt, label: "Expenses", sub: "Categorized deductions" },
    ],
  },
  {
    title: "Intelligence",
    items: [
      { to: "/app/ai", icon: Robot, label: "Milli AI", sub: "Tax strategy assistant" },
      { to: "/app/reports", icon: FileText, label: "Reports & 1099s", sub: "Schedule C, SE tax" },
      { to: "/app/quarterly", icon: Receipt, label: "Quarterly Taxes", sub: "IRS payment estimates" },
    ],
  },
  {
    title: "Account",
    items: [
      { to: "/app/referral", icon: Gift, label: "Invite & Earn", sub: "$10 per referral" },
      { to: "/app/pricing", icon: Star, label: "Upgrade Plan", sub: "Go Elite for full filing" },
      { to: "/app/settings", icon: Gear, label: "Settings", sub: "Profile, banks, automation" },
    ],
  },
];

export default function More() {
  const { logout } = useAuth();
  const nav = useNavigate();

  function handleSignOut() {
    logout();
    nav("/");
  }

  return (
    <div
      className="min-h-full"
      style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif" }}
    >
      {/* Page content */}
      <div className="px-5 pt-4 pb-8 max-w-lg mx-auto">
        {/* Page Title */}
        <div className="mb-6">
          <p className="text-[11px] font-mono uppercase tracking-[0.3em] text-zinc-500 mb-1">
            // Navigation
          </p>
          <h1 className="font-display text-2xl font-bold chrome-text tracking-tight">
            More
          </h1>
        </div>

        {/* Sections */}
        {sections.map((section) => (
          <div key={section.title} className="mb-5">
            <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-volt mb-2 pl-1">
              {section.title}
            </p>
            <div className="ios-section">
              {section.items.map((item) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className="ios-section__row"
                  style={{ color: "#FFFFFF", textDecoration: "none" }}
                >
                  <div className="ios-section__row-icon">
                    <item.icon size={16} weight="duotone" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="ios-section__row-label">{item.label}</div>
                    <div className="text-[12px] text-zinc-500 mt-0.5">{item.sub}</div>
                  </div>
                  <CaretRight size={14} weight="bold" className="ios-section__row-chevron" />
                </Link>
              ))}
            </div>
          </div>
        ))}

        {/* Support Section */}
        <div className="mb-5">
          <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-volt mb-2 pl-1">
            Support
          </p>
          <div className="ios-section">
            <Link
              to="/app/settings"
              className="ios-section__row"
              style={{ color: "#FFFFFF", textDecoration: "none" }}
            >
              <div className="ios-section__row-icon">
                <Headset size={16} weight="duotone" />
              </div>
              <div className="ios-section__row-label">Help & Support</div>
              <CaretRight size={14} weight="bold" className="ios-section__row-chevron" />
            </Link>
            <Link
              to="/app/settings"
              className="ios-section__row"
              style={{ color: "#FFFFFF", textDecoration: "none" }}
            >
              <div className="ios-section__row-icon">
                <Question size={16} weight="duotone" />
              </div>
              <div className="ios-section__row-label">FAQ</div>
              <CaretRight size={14} weight="bold" className="ios-section__row-chevron" />
            </Link>
          </div>
        </div>

        {/* Sign Out */}
        <button
          onClick={handleSignOut}
          className="w-full mt-4 flex items-center justify-center gap-3 py-4 rounded-2xl border border-white/10 bg-white/[0.02] text-zinc-400 active:bg-white/[0.05] transition-colors"
          data-testid="more-sign-out"
          style={{ color: "#a1a1aa" }}
        >
          <SignOut size={18} weight="bold" />
          <span className="font-semibold text-sm tracking-wide">Sign Out</span>
        </button>

        {/* Brand footer */}
        <div className="mt-8 flex flex-col items-center gap-2 opacity-40">
          <MilliLogo size={20} />
          <p className="text-[10px] font-mono tracking-[0.2em] uppercase">Milli v1.4</p>
        </div>
      </div>
    </div>
  );
}
