import { useState } from "react";
import Retirement from "@/pages/Retirement";
import Investing from "@/pages/Investing";
import { ChartLineUp, PiggyBank } from "@phosphor-icons/react";

/**
 * Wealth — unified 401(k) + Investing hub.
 * Segment control at the top lets the driver flip between retirement and
 * brokerage views without leaving this route.
 */
export default function Wealth() {
  const [tab, setTab] = useState("retirement");
  return (
    <div className="px-4 pt-4 sm:px-6">
      <div className="mb-4">
        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.3em]">// Wealth</div>
        <h1 className="font-display font-black text-3xl tracking-tighter mt-1 leading-[1.05]">
          Grow. Compound. Retire.
        </h1>
        <p className="text-zinc-400 text-sm mt-1">Retirement + brokerage — one glass, one glance.</p>
      </div>
      {/* Segment control */}
      <div
        className="grid grid-cols-2 rounded-2xl p-1 mb-5 border border-white/[0.08]"
        style={{ background: "rgba(5,7,10,0.7)" }}
        data-testid="wealth-tabs"
      >
        {[
          { id: "retirement", icon: PiggyBank, label: "Retirement" },
          { id: "investing",  icon: ChartLineUp, label: "Investing" },
        ].map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            data-testid={`wealth-tab-${t.id}`}
            className={`flex items-center justify-center gap-2 py-2.5 text-[12px] font-bold uppercase tracking-[0.15em] rounded-xl transition ${
              tab === t.id
                ? "bg-volt text-obsidian shadow-[0_0_20px_rgba(0,229,255,0.35)]"
                : "text-zinc-400 hover:text-white"
            }`}
          >
            <t.icon size={14} weight="fill" /> {t.label}
          </button>
        ))}
      </div>
      {tab === "retirement" ? <Retirement /> : <Investing />}
    </div>
  );
}
