import { useState } from "react";
import { motion } from "framer-motion";
import {
  ArrowDown, ArrowUp, Receipt, Car, ShoppingBag, Wallet,
  CurrencyDollar, House, Coffee, Lightning,
} from "@phosphor-icons/react";

const CYAN = "#00E5FF";

const MOCK_TRANSACTIONS = [
  { id: 1, type: "income",   label: "Stripe Payout",      amount: 2480.00, date: "Today, 9:41 AM",     icon: CurrencyDollar, category: "Income" },
  { id: 2, type: "expense",  label: "Adobe Creative Cloud", amount: -54.99, date: "Today, 8:12 AM",     icon: Lightning,     category: "Software" },
  { id: 3, type: "income",   label: "Client Invoice #214", amount: 1200.00, date: "Yesterday",          icon: Wallet,        category: "Income" },
  { id: 4, type: "deduct",   label: "Business Mileage",    amount: -0,      date: "Yesterday",          icon: Car,           category: "Deduction",  note: "48 mi · $33.60" },
  { id: 5, type: "expense",  label: "Office Supplies",     amount: -89.40,  date: "Aug 5",              icon: ShoppingBag,   category: "Office" },
  { id: 6, type: "expense",  label: "WeWork Day Pass",     amount: -49.00,  date: "Aug 5",              icon: House,         category: "Office" },
  { id: 7, type: "income",   label: "Stripe Payout",       amount: 3100.00, date: "Aug 4",              icon: CurrencyDollar, category: "Income" },
  { id: 8, type: "expense",  label: "Client Dinner",       amount: -127.80, date: "Aug 3",              icon: Coffee,        category: "Meals" },
  { id: 9, type: "deduct",   label: "Home Office Expense", amount: -0,      date: "Aug 3",              icon: House,         category: "Deduction", note: "20% of rent" },
  { id: 10, type: "expense", label: "Notion Pro",          amount: -16.00,  date: "Aug 2",              icon: Receipt,       category: "Software" },
];

const TABS = ["All", "Income", "Expenses", "Deductions"];
const FILTER_MAP = { All: null, Income: "income", Expenses: "expense", Deductions: "deduct" };

export default function Activity() {
  const [tab, setTab] = useState("All");
  const filter = FILTER_MAP[tab];
  const items = filter ? MOCK_TRANSACTIONS.filter((t) => t.type === filter) : MOCK_TRANSACTIONS;

  const totalIn  = MOCK_TRANSACTIONS.filter(t => t.type === "income").reduce((s,t) => s + t.amount, 0);
  const totalOut = MOCK_TRANSACTIONS.filter(t => t.type === "expense").reduce((s,t) => s + Math.abs(t.amount), 0);

  return (
    <div
      className="min-h-full px-4 pb-8 pt-6"
      style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif' }}
    >
      {/* Header */}
      <div className="mb-5">
        <h1
          className="text-2xl font-bold text-white"
          style={{ letterSpacing: "-0.02em" }}
        >
          Activity
        </h1>
        <p className="text-zinc-500 text-[13px] mt-0.5">Recent financial events</p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 gap-3 mb-6">
        {[
          { label: "Money In",  value: `+$${totalIn.toLocaleString("en-US", { minimumFractionDigits: 2 })}`, color: CYAN,      icon: ArrowDown  },
          { label: "Money Out", value: `-$${totalOut.toLocaleString("en-US", { minimumFractionDigits: 2 })}`, color: "#FF5C67", icon: ArrowUp },
        ].map((card) => (
          <div
            key={card.label}
            className="rounded-2xl p-4"
            style={{
              background: "linear-gradient(135deg, rgba(255,255,255,0.04), rgba(255,255,255,0.01))",
              border: "1px solid rgba(255,255,255,0.07)",
            }}
          >
            <div className="flex items-center gap-2 mb-2">
              <div
                className="w-7 h-7 rounded-full flex items-center justify-center"
                style={{ background: `${card.color}18` }}
              >
                <card.icon size={14} weight="bold" style={{ color: card.color }} />
              </div>
              <span className="text-zinc-500 text-[11px] uppercase tracking-widest">{card.label}</span>
            </div>
            <div
              className="text-[18px] font-bold"
              style={{ color: card.color, letterSpacing: "-0.02em" }}
            >
              {card.value}
            </div>
          </div>
        ))}
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2 mb-5 overflow-x-auto no-scrollbar pb-1">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className="flex-shrink-0 px-4 py-2 rounded-full text-[12px] font-semibold uppercase tracking-widest transition-all"
            style={
              tab === t
                ? { background: `${CYAN}18`, color: CYAN, border: `1px solid ${CYAN}55` }
                : { background: "rgba(255,255,255,0.04)", color: "#6B7280", border: "1px solid rgba(255,255,255,0.06)" }
            }
          >
            {t}
          </button>
        ))}
      </div>

      {/* Transaction list */}
      <div className="flex flex-col gap-2">
        {items.map((txn, i) => (
          <motion.div
            key={txn.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.25, delay: i * 0.04 }}
            className="flex items-center gap-3 px-4 py-3.5 rounded-2xl"
            style={{
              background: "linear-gradient(135deg, rgba(255,255,255,0.04), rgba(255,255,255,0.01))",
              border: "1px solid rgba(255,255,255,0.06)",
            }}
          >
            {/* Icon */}
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
              style={{
                background:
                  txn.type === "income"  ? `${CYAN}14` :
                  txn.type === "deduct"  ? "rgba(147,51,234,0.14)" :
                  "rgba(255,92,103,0.12)",
              }}
            >
              <txn.icon
                size={18}
                weight="duotone"
                style={{
                  color:
                    txn.type === "income"  ? CYAN :
                    txn.type === "deduct"  ? "#A855F7" :
                    "#FF5C67",
                }}
              />
            </div>

            {/* Details */}
            <div className="flex-1 min-w-0">
              <div className="text-[14px] font-semibold text-white truncate">{txn.label}</div>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span
                  className="text-[10px] uppercase tracking-widest px-1.5 py-0.5 rounded-full font-medium"
                  style={{ background: "rgba(255,255,255,0.06)", color: "#6B7280" }}
                >
                  {txn.category}
                </span>
                <span className="text-zinc-600 text-[11px]">{txn.date}</span>
              </div>
              {txn.note && (
                <div className="text-[11px] mt-0.5" style={{ color: CYAN + "99" }}>{txn.note}</div>
              )}
            </div>

            {/* Amount */}
            <div
              className="text-[15px] font-bold flex-shrink-0"
              style={{
                color:
                  txn.type === "income"  ? CYAN :
                  txn.type === "deduct"  ? "#A855F7" :
                  "#FF5C67",
              }}
            >
              {txn.type === "income" ? "+" : txn.type === "deduct" ? "" : "-"}
              {txn.type === "deduct" ? txn.note?.split("·")[1]?.trim() || "—" : `$${Math.abs(txn.amount).toFixed(2)}`}
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
