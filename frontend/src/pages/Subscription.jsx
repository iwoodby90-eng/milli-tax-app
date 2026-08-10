import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import {
  Check, Crown, Star, Sparkle, ArrowRight, CreditCard,
  Calendar, Bell, Download, CaretRight,
} from "@phosphor-icons/react";

const PLANS = [
  {
    id: "basic",
    name: "MILLI Basic",
    price: 19.99,
    period: "month",
    icon: Star,
    color: "#71717A",
    features: [
      "Payout tracking",
      "Mileage tracking",
      "Tax savings vault",
      "Quarterly tax estimates",
    ],
    limitations: [],
  },
  {
    id: "pro",
    name: "MILLI Pro",
    price: 29.99,
    period: "month",
    icon: Sparkle,
    color: "#00E5FF",
    features: [
      "Everything in Basic",
      "Milli Cents unlocked",
      "Tax forms provided",
      "Guided filing assistance",
    ],
    limitations: [],
  },
  {
    id: "elite",
    name: "MILLI Elite",
    price: 49.99,
    period: "month",
    icon: Crown,
    color: "#D4FF00",
    features: [
      "Everything in Pro",
      "Tax forms pre-filled automatically",
      "Auto-filed and submitted",
      "Brushed Titanium Visa Card (3% cash back)",
    ],
    limitations: [],
  },
];

export default function Subscription() {
  const { user } = useAuth();
  const currentPlan = user?.plan || "basic";
  const [billingCycle, setBillingCycle] = useState("monthly");

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-6">
      <header>
        <h1
          className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight"
          style={{ fontFamily: "'Outfit', system-ui, sans-serif" }}
        >
          Subscription
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Manage your plan, billing, and premium features.</p>
      </header>

      <section
        className="rounded-3xl p-5"
        style={{
          background: "linear-gradient(180deg, rgba(0,229,255,0.06) 0%, rgba(10,14,18,0.9) 100%)",
          border: "1px solid rgba(0,229,255,0.2)",
        }}
      >
        <div className="flex items-center justify-between">
          <div>
            <div className="text-zinc-400 text-[12px] uppercase tracking-wide">Current Plan</div>
            <div className="flex items-center gap-2 mt-1">
              {(() => {
                const plan = PLANS.find((p) => p.id === currentPlan) || PLANS[0];
                const Icon = plan.icon;
                return (
                  <>
                    <Icon size={24} weight="fill" style={{ color: plan.color }} />
                    <span className="text-white text-[22px] font-bold">{plan.name}</span>
                  </>
                );
              })()}
            </div>
          </div>
          <div className="text-right">
            <div className="text-white text-[20px] font-bold tabular-nums">
              {PLANS.find((p) => p.id === currentPlan)?.price === 0
                ? "Free"
                : `$${PLANS.find((p) => p.id === currentPlan)?.price}/mo`}
            </div>
            <div className="text-zinc-500 text-[11px]">
              {currentPlan === "basic" ? "No expiry" : "Renews monthly"}
            </div>
          </div>
        </div>
      </section>

      {/* Elite Card CTA */}
      {currentPlan === "elite" && (
        <section
          className="rounded-3xl p-5 relative overflow-hidden"
          style={{
            background: "linear-gradient(135deg, rgba(212,255,0,0.08) 0%, rgba(10,14,18,0.95) 60%)",
            border: "1.5px solid rgba(212,255,0,0.3)",
          }}
        >
          <div className="flex items-start gap-4">
            <div
              className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0"
              style={{
                background: "linear-gradient(135deg, #F5F6F8 0%, #B8BCC2 38%, #8F9399 58%, #2E3136 100%)",
              }}
            >
              <CreditCard size={26} weight="fill" className="text-white/80" />
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <Crown size={16} weight="fill" className="text-[#D4FF00]" />
                <h3 className="text-white text-[16px] font-bold">Milli Visa Elite Card</h3>
              </div>
              <p className="text-zinc-400 text-[13px] mt-1 leading-relaxed">
                Order your premium metal or titanium debit card. Included with your Elite membership.
              </p>
              <a
                href="/app/card-order"
                className="inline-flex items-center gap-1.5 mt-3 px-4 py-2 rounded-xl bg-[#D4FF00] text-black text-[13px] font-bold active:scale-[0.99] transition"
              >
                Order your card
                <ArrowRight size={15} weight="bold" />
              </a>
            </div>
          </div>
        </section>
      )}

      {/* Upgrade CTA for non-Elite */}
      {currentPlan !== "elite" && (
        <section
          className="rounded-3xl p-5"
          style={{
            background: "linear-gradient(135deg, rgba(212,255,0,0.06) 0%, rgba(10,14,18,0.9) 100%)",
            border: "1px solid rgba(212,255,0,0.15)",
          }}
        >
          <div className="flex items-start gap-3">
            <Crown size={20} weight="fill" className="text-[#D4FF00] mt-0.5" />
            <div>
              <h3 className="text-white text-[15px] font-semibold">Upgrade to Elite for the Visa card</h3>
              <p className="text-zinc-400 text-[13px] mt-1">
                Get the Milli Visa Elite debit card in brushed metal or aerospace titanium, plus checking, banking, and concierge support.
              </p>
              <a
                href="/app/pricing"
                className="inline-flex items-center gap-1.5 mt-3 px-4 py-2 rounded-xl bg-[#D4FF00] text-black text-[13px] font-bold active:scale-[0.99] transition"
              >
                Upgrade now
                <ArrowRight size={15} weight="bold" />
              </a>
            </div>
          </div>
        </section>
      )}

      <div className="flex items-center justify-center gap-2 milli-card rounded-full p-1.5 w-fit mx-auto">
        <button
          onClick={() => setBillingCycle("monthly")}
          className={`px-4 py-1.5 rounded-full text-[13px] font-medium transition ${
            billingCycle === "monthly" ? "bg-volt text-black" : "text-zinc-400"
          }`}
          style={billingCycle === "monthly" ? { backgroundColor: '#D4FF00' } : {}}
        >
          Monthly
        </button>
        <button
          onClick={() => setBillingCycle("annual")}
          className={`px-4 py-1.5 rounded-full text-[13px] font-medium transition ${
            billingCycle === "annual" ? "bg-volt text-black" : "text-zinc-400"
          }`}
          style={billingCycle === "annual" ? { backgroundColor: '#D4FF00' } : {}}
        >
          Annual (Save 20%)
        </button>
      </div>

      <div className="space-y-3">
        {PLANS.map((plan) => {
          const isCurrent = plan.id === currentPlan;
          const Icon = plan.icon;
          const displayPrice = billingCycle === "annual"
            ? (plan.price * 12 * 0.8).toFixed(2)
            : plan.price.toFixed(2);

          return (
            <div
              key={plan.id}
              className="milli-card rounded-3xl p-5"
              style={{
                border: isCurrent
                  ? `1.5px solid ${plan.color}`
                  : "1px solid rgba(255,255,255,0.06)",
                boxShadow: isCurrent ? `0 0 20px ${plan.color}22` : "none",
              }}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2.5">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center"
                    style={{ background: `${plan.color}15`, border: `1px solid ${plan.color}30` }}
                  >
                    <Icon size={20} weight="fill" style={{ color: plan.color }} />
                  </div>
                  <div>
                    <div className="text-white text-[17px] font-bold">{plan.name}</div>
                    {isCurrent && (
                      <span
                        className="text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full"
                        style={{ background: `${plan.color}20`, color: plan.color }}
                      >
                        Current
                      </span>
                    )}
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-white text-[20px] font-bold tabular-nums">
                    {plan.price === 0 ? "Free" : `$${displayPrice}`}
                  </div>
                  <div className="text-zinc-500 text-[11px]">
                    {plan.price === 0 ? "" : billingCycle === "annual" ? "/year" : "/month"}
                  </div>
                </div>
              </div>

              <ul className="space-y-1.5 mb-4">
                {plan.features.map((f, i) => (
                  <li key={i} className="flex items-center gap-2 text-[13px] text-zinc-300">
                    <Check size={14} weight="bold" className="text-green-400 flex-shrink-0" />
                    {f}
                  </li>
                ))}
                {plan.limitations.map((l, i) => (
                  <li key={i} className="flex items-center gap-2 text-[13px] text-zinc-600">
                    <span className="w-3.5 h-3.5 rounded-full border border-zinc-700 flex-shrink-0" />
                    {l}
                  </li>
                ))}
              </ul>

              {isCurrent ? (
                <div className="w-full text-center py-2.5 rounded-xl text-[13px] font-medium text-zinc-500 milli-card">
                  Your current plan
                </div>
              ) : (
                <a
                  href="/app/pricing"
                  className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-[14px] font-bold text-black active:scale-[0.99] transition"
                  style={{ background: plan.color }}
                >
                  {plan.price === 0 ? "Downgrade" : "Upgrade"}
                  <ArrowRight size={16} weight="bold" />
                </a>
              )}
            </div>
          );
        })}
      </div>

      <section className="milli-card rounded-2xl p-4">
        <h3 className="text-white text-[15px] font-semibold mb-3">Billing History</h3>
        {currentPlan === "basic" ? (
          <p className="text-zinc-500 text-[13px]">No billing history. You are on the free plan.</p>
        ) : (
          <div className="space-y-2">
            {[
              { date: "2026-08-01", amount: 49.99, plan: "Elite" },
              { date: "2026-07-01", amount: 49.99, plan: "Elite" },
              { date: "2026-06-01", amount: 29.99, plan: "Pro" },
            ].map((item, i) => (
              <div key={i} className="flex items-center justify-between py-2 border-b border-white/5 last:border-0">
                <div className="flex items-center gap-3">
                  <CreditCard size={16} className="text-zinc-500" />
                  <div>
                    <div className="text-white text-[13px] font-medium">{item.plan} - Monthly</div>
                    <div className="text-zinc-500 text-[11px]">{item.date}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white text-[13px] tabular-nums">${item.amount}</span>
                  <button className="text-zinc-500 active:text-volt p-1">
                    <Download size={14} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="milli-card rounded-2xl overflow-hidden">
        <button className="w-full flex items-center gap-3 p-4 active:bg-white/5">
          <Bell size={18} className="text-zinc-400" />
          <span className="flex-1 text-left text-white text-[14px]">Renewal Reminders</span>
          <span className="text-zinc-500 text-[12px]">On</span>
          <CaretRight size={16} className="text-zinc-600" />
        </button>
        <button className="w-full flex items-center gap-3 p-4 active:bg-white/5 border-t border-white/5">
          <CreditCard size={18} className="text-zinc-400" />
          <span className="flex-1 text-left text-white text-[14px]">Payment Method</span>
          <span className="text-zinc-500 text-[12px]">Apple Pay</span>
          <CaretRight size={16} className="text-zinc-600" />
        </button>
        <button className="w-full flex items-center gap-3 p-4 active:bg-white/5 border-t border-white/5">
          <Calendar size={18} className="text-zinc-400" />
          <span className="flex-1 text-left text-white text-[14px]">Next Renewal</span>
          <span className="text-zinc-500 text-[12px]">Sep 1, 2026</span>
          <CaretRight size={16} className="text-zinc-600" />
        </button>
      </section>
    </div>
  );
}