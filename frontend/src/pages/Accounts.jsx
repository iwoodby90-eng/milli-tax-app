import { useState, useEffect } from "react";
import { useAuth } from "@/context/AuthContext";
import {
  Bank, CreditCard, Wallet, ArrowLeftRight, Plug,
  ShieldCheck, Lock, Crown, Eye, EyeSlash, ArrowClockwise,
} from "@phosphor-icons/react";

const STORAGE_KEY = "milli_connected_accounts";

export default function Accounts() {
  const { user } = useAuth();
  const [accounts, setAccounts] = useState([]);
  const [showBalances, setShowBalances] = useState(true);

  const isElite = user?.plan === "elite";

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        setAccounts(JSON.parse(stored));
      } else {
        // Default accounts: Tax Vault and Investing are available to all tiers
        const defaults = [
          { id: "vault", name: "Milli Tax Vault", type: "Tax Vault", balance: 0, status: "active", icon: "vault", tier: "all" },
          { id: "investing", name: "Investing Account", type: "Investment", balance: 0, status: "active", icon: "chart", tier: "pro" },
          { id: "retirement", name: "Retirement Account", type: "Retirement", balance: 0, status: "active", icon: "piggy", tier: "pro" },
          { id: "checking", name: "Milli Checking", type: "Checking", balance: 0, status: "elite-only", icon: "bank", tier: "elite" },
          { id: "visa", name: "Milli Visa Debit Card", type: "Debit Card", balance: 0, status: "elite-only", icon: "card", tier: "elite" },
        ];
        setAccounts(defaults);
        localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults));
      }
    } catch { setAccounts([]); }
  }, []);

  const accessibleAccounts = accounts.filter(a => {
    if (a.tier === "elite") return isElite;
    if (a.tier === "pro") return user?.plan === "pro" || user?.plan === "elite";
    return true;
  });

  const eliteLockedAccounts = accounts.filter(a => a.tier === "elite" && !isElite);

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">
      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          Accounts
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">
          Connected financial accounts and cards.
        </p>
      </header>

      {/* Balance visibility toggle */}
      <div className="flex items-center justify-between">
        <div className="text-zinc-400 text-[12px] uppercase tracking-wider font-chrome">
          {accessibleAccounts.length} Account{accessibleAccounts.length !== 1 ? "s" : ""}
        </div>
        <button
          onClick={() => setShowBalances(!showBalances)}
          className="flex items-center gap-1.5 text-zinc-400 text-[12px] font-chrome"
        >
          {showBalances ? <Eye size={14} /> : <EyeSlash size={14} />}
          {showBalances ? "Hide" : "Show"} Balances
        </button>
      </div>

      {/* Accessible accounts */}
      {accessibleAccounts.map(account => (
        <AccountCard
          key={account.id}
          account={account}
          showBalance={showBalances}
        />
      ))}

      {/* Elite-only accounts (locked for non-Elite) */}
      {eliteLockedAccounts.length > 0 && (
        <>
          <div className="pt-2 pb-1 font-mono text-[10.5px] uppercase tracking-[0.28em] text-zinc-500">
            Elite Plan Required
          </div>
          {eliteLockedAccounts.map(account => (
            <LockedAccountCard key={account.id} account={account} />
          ))}
        </>
      )}

      {/* Connect bank account */}
      <button
        className="w-full milli-card rounded-2xl py-3.5 flex items-center justify-center gap-2 text-[14px] font-semibold active:scale-[0.99] transition-transform"
        style={{ background: "rgba(0,229,255,0.06)", border: "1px solid rgba(0,229,255,0.2)" }}
      >
        <Plug size={18} weight="bold" className="text-volt" />
        <span className="text-volt">Connect Bank Account</span>
      </button>

      {/* Security note */}
      <div className="milli-card rounded-2xl p-4 flex items-start gap-3" style={{ background: "rgba(10,14,18,0.5)", border: "1px solid rgba(255,255,255,0.04)" }}>
        <ShieldCheck size={18} weight="regular" className="text-zinc-500 flex-shrink-0 mt-0.5" />
        <p className="text-zinc-500 text-[12px] leading-relaxed">
          Milli uses Plaid for secure bank connections. Your credentials are never stored by Milli.
          Banking services require a regulated partner. Milli is a technology platform, not a bank.
        </p>
      </div>

      {/* Version */}
      <div className="text-center text-zinc-600 text-[11px] font-chrome pt-2">
        Milli Tax Vault™ · v2.6.0
      </div>
    </div>
  );
}

function AccountCard({ account, showBalance }) {
  const iconMap = {
    vault: <ArrowLeftRight size={20} weight="fill" className="text-volt" />,
    chart: <Wallet size={20} weight="fill" className="text-volt" />,
    piggy: <Bank size={20} weight="fill" className="text-volt" />,
    bank: <Bank size={20} weight="fill" className="text-volt" />,
    card: <CreditCard size={20} weight="fill" className="text-volt" />,
  };

  return (
    <div
      className="milli-card rounded-3xl p-5"
      style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div
            className="w-11 h-11 rounded-xl flex items-center justify-center"
            style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.2)" }}
          >
            {iconMap[account.icon] || <Wallet size={20} className="text-volt" />}
          </div>
          <div>
            <div className="text-white font-semibold text-[15px]">{account.name}</div>
            <div className="text-zinc-500 text-[12px] font-chrome">{account.type}</div>
          </div>
        </div>
        <div className="text-right">
          {showBalance ? (
            <div className="font-display text-[18px] font-bold text-white">
              ${account.balance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          ) : (
            <div className="font-display text-[18px] font-bold text-zinc-600">••••••</div>
          )}
          <div className="text-[11px] text-zinc-500 font-chrome flex items-center gap-1 justify-end mt-0.5">
            <span className="w-1.5 h-1.5 rounded-full" style={{ background: account.status === "active" ? "#D4FF00" : "#C0C0C0" }} />
            {account.status === "active" ? "Connected" : "Pending"}
          </div>
        </div>
      </div>
    </div>
  );
}

function LockedAccountCard({ account }) {
  return (
    <div
      className="milli-card rounded-3xl p-5 relative overflow-hidden"
      style={{ background: "rgba(10,14,18,0.5)", border: "1px solid rgba(255,255,255,0.04)" }}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3 opacity-50">
          <div
            className="w-11 h-11 rounded-xl flex items-center justify-center"
            style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.06)" }}
          >
            {account.icon === "card"
              ? <CreditCard size={20} className="text-zinc-500" />
              : <Bank size={20} className="text-zinc-500" />}
          </div>
          <div>
            <div className="text-zinc-400 font-semibold text-[15px]">{account.name}</div>
            <div className="text-zinc-600 text-[12px] font-chrome">{account.type}</div>
          </div>
        </div>
        <div className="flex items-center gap-1.5 text-zinc-500">
          <Lock size={14} weight="fill" />
        </div>
      </div>

      {/* Upgrade prompt */}
      <div className="mt-4 rounded-2xl p-3 flex items-center gap-3" style={{ background: "rgba(212,255,0,0.04)", border: "1px solid rgba(212,255,0,0.12)" }}>
        <Crown size={18} weight="fill" className="text-volt flex-shrink-0" />
        <div className="flex-1">
          <div className="text-white text-[13px] font-semibold">
            Elite Plan Required
          </div>
          <div className="text-zinc-400 text-[12px] mt-0.5">
            Upgrade to Elite ($49.99/mo) to unlock {account.name}.
          </div>
        </div>
        <a
          href="/app/pricing"
          className="rounded-xl px-3 py-2 text-[12px] font-bold text-black whitespace-nowrap"
          style={{ background: "#D4FF00" }}
        >
          Upgrade
        </a>
      </div>
    </div>
  );
}