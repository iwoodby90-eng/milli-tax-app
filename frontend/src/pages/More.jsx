import { Link } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { useState } from "react";
import {
  Gear, ShieldCheck, Users, Gift, Question, Sparkle, FileText, Car, BellRinging, SignOut,
  CaretRight,
} from "@phosphor-icons/react";

const ITEMS = [
  { to: "/app/quarterly", icon: Sparkle, label: "Quarterly Tax Center", sub: "Deadlines, payments, readiness", testid: "more-quarterly" },
  { to: "/app/reports", icon: FileText, label: "Tax Vault Reports", sub: "Schedule C · SE · Mileage CSV", testid: "more-reports" },
  { to: "/app/ai", icon: Sparkle, label: "Milli Assistant", sub: "Ask anything about your numbers", testid: "more-ai" },
  { to: "/app/pricing", icon: Gift, label: "Plans & Billing", sub: "Essential · Pro · Elite", testid: "more-pricing" },
  { to: "/app/settings", icon: Gear, label: "Settings", sub: "Profile, state, filing status", testid: "more-settings" },
];

export default function More() {
  const { user, logout } = useAuth();
  return (
    <div className="px-4 sm:px-6 lg:px-10 py-6 lg:py-10 max-w-3xl mx-auto">
      <div className="mb-6">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// More</div>
        <h1 className="font-display text-3xl sm:text-4xl tracking-tight mt-1 chrome-text">{user?.name || "Account"}</h1>
        <div className="text-zinc-400 text-sm mt-1">{user?.email}</div>
      </div>

      <div className="milli-card p-1 mb-4 divide-y divide-hairline/60">
        {ITEMS.map((it) => (
          <Link key={it.to} to={it.to} data-testid={it.testid} className="flex items-center gap-4 p-4 hover:bg-white/[0.02] transition-colors">
            <div className="w-10 h-10 rounded-xl bg-volt/10 border border-volt/30 flex items-center justify-center flex-shrink-0">
              <it.icon size={18} weight="duotone" className="text-volt" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="font-semibold text-sm">{it.label}</div>
              <div className="text-xs text-zinc-500 truncate">{it.sub}</div>
            </div>
            <CaretRight size={16} className="text-zinc-600" />
          </Link>
        ))}
      </div>

      <div className="milli-card p-5 mb-4">
        <div className="text-volt text-xs font-semibold uppercase tracking-[0.2em] mb-3">Coming Soon</div>
        <ul className="space-y-2 text-sm text-zinc-400">
          <li className="flex items-center gap-2"><Users size={14} className="text-zinc-500" /> Accountant collaboration</li>
          <li className="flex items-center gap-2"><BellRinging size={14} className="text-zinc-500" /> Smart notifications</li>
          <li className="flex items-center gap-2"><ShieldCheck size={14} className="text-zinc-500" /> Security center · MFA · device sessions</li>
          <li className="flex items-center gap-2"><Gift size={14} className="text-zinc-500" /> Refer-a-driver rewards</li>
          <li className="flex items-center gap-2"><Car size={14} className="text-zinc-500" /> Multi-vehicle management</li>
        </ul>
      </div>

      <button
        onClick={() => { logout(); window.location.href = "/"; }}
        data-testid="more-signout"
        className="w-full milli-card p-4 flex items-center justify-center gap-2 text-danger hover:bg-danger/5 transition-colors"
      ><SignOut size={16} weight="bold" /> Sign out</button>
    </div>
  );
}
