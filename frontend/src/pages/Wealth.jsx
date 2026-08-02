import { useState } from "react";
import Retirement from "@/pages/Retirement";
import Investing from "@/pages/Investing";

/**
 * Wealth — unified 401(k) + Investing hub with a segmented control.
 */
export default function Wealth() {
  const [tab, setTab] = useState("retirement");
  return (
    <div className="px-5 sm:px-6 pt-4 pb-2 max-w-2xl mx-auto">
      <header className="mb-4">
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          Wealth
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Retirement + brokerage, one glass.</p>
      </header>
      {/* Segment control */}
      <div
        className="grid grid-cols-2 rounded-2xl p-1 mb-1"
        style={{
          background: "rgba(10,14,18,0.7)",
          border: "1px solid rgba(255,255,255,0.06)",
        }}
      >
        <SegBtn active={tab === "retirement"} onClick={() => setTab("retirement")} testid="wealth-tab-retirement">
          Retirement
        </SegBtn>
        <SegBtn active={tab === "investing"} onClick={() => setTab("investing")} testid="wealth-tab-investing">
          Investing
        </SegBtn>
      </div>
      <div className="-mx-5 sm:-mx-6">
        {tab === "retirement" ? <Retirement /> : <Investing />}
      </div>
    </div>
  );
}

function SegBtn({ active, onClick, testid, children }) {
  return (
    <button
      onClick={onClick}
      data-testid={testid}
      className={`py-2.5 rounded-xl font-semibold text-[13px] transition ${
        active ? "text-volt" : "text-zinc-400"
      }`}
      style={active ? {
        background: "rgba(0,229,255,0.10)",
        border: "1px solid rgba(0,229,255,0.5)",
        textShadow: "0 0 8px rgba(0,229,255,0.5)",
      } : {}}
    >
      {children}
    </button>
  );
}
