import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { CopySimple, Share, Users, Gift, CheckCircle } from "@phosphor-icons/react";

export default function Referral() {
  const [data, setData] = useState(null);
  const [redeemCode, setRedeemCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [copied, setCopied] = useState(false);

  async function load() {
    try {
      const r = await api.get("/referral/me");
      setData(r.data);
    } catch (e) {
      toast.error("Could not load referral code");
    }
  }
  useEffect(() => { load(); }, []);

  function copyLink() {
    if (!data) return;
    navigator.clipboard.writeText(data.share_url).then(() => {
      setCopied(true);
      toast.success("Link copied");
      setTimeout(() => setCopied(false), 1600);
    });
  }

  function share() {
    if (!data) return;
    const message = `Try Milli — it auto-slices taxes off every payout so April never surprises you. Use my code ${data.code} and we both get $10. ${data.share_url}`;
    if (navigator.share) {
      navigator.share({ title: "Milli", text: message, url: data.share_url }).catch(() => {});
    } else {
      copyLink();
    }
  }

  async function redeem() {
    const code = redeemCode.trim().toUpperCase();
    if (!code) return;
    setBusy(true);
    try {
      const r = await api.post("/referral/apply", { code });
      toast.success(`+$${(r.data.reward_cents / 100).toFixed(0)} vault credit unlocked!`);
      setRedeemCode("");
      await load();
    } catch (e) {
      toast.error(e?.response?.data?.detail || "Could not redeem code");
    } finally {
      setBusy(false);
    }
  }

  if (!data) {
    return <div className="p-6 text-zinc-500 font-mono text-sm">Loading referrals…</div>;
  }

  const rewardDollars = data.reward_cents / 100;
  const creditDollars = data.credit_cents / 100;

  return (
    <div className="p-4 sm:p-6 max-w-3xl mx-auto space-y-5">
      {/* Header */}
      <div>
        <div className="text-volt font-mono text-[11px] uppercase tracking-[0.3em]">// Referrals</div>
        <h1 className="font-display font-black text-3xl tracking-tighter mt-1 leading-[1.05]">
          Invite a driver. Get ${rewardDollars.toFixed(0)} each.
        </h1>
        <p className="text-zinc-400 mt-2 text-sm leading-relaxed">
          Every friend who signs up with your code gets ${rewardDollars.toFixed(0)} in Tax Vault credit — and so do you. No cap.
        </p>
      </div>

      {/* Big reward card */}
      <div
        className="milli-card p-6 relative overflow-hidden"
        style={{
          background:
            "radial-gradient(120% 80% at 100% 0%, rgba(0,229,255,0.14) 0%, rgba(0,0,0,0) 55%), #06080B",
        }}
        data-testid="referral-hero"
      >
        <div className="flex items-center gap-2 text-volt font-mono text-[10px] uppercase tracking-[0.28em]">
          <Gift size={12} weight="bold" /> Your code
        </div>
        <div className="mt-3 flex items-center gap-3 flex-wrap">
          <div
            data-testid="referral-code"
            className="font-chrome font-bold text-3xl chrome-text tracking-widest select-all"
          >
            {data.code}
          </div>
        </div>
        <div className="mt-6 grid grid-cols-2 gap-2">
          <button
            data-testid="referral-copy"
            onClick={copyLink}
            className="btn-volt px-3 py-3 text-[11px] uppercase tracking-[0.14em] inline-flex items-center justify-center gap-1.5 whitespace-nowrap"
          >
            {copied ? <><CheckCircle size={14} weight="fill" /> Copied</> : <><CopySimple size={14} weight="bold" /> Copy link</>}
          </button>
          <button
            data-testid="referral-share"
            onClick={share}
            className="btn-outline-cyan px-3 py-3 text-[11px] uppercase tracking-[0.14em] font-semibold inline-flex items-center justify-center gap-1.5 whitespace-nowrap"
          >
            <Share size={14} weight="bold" /> Share
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3">
        <div className="milli-card p-4">
          <div className="flex items-center gap-1.5 text-zinc-500 font-mono text-[10px] uppercase tracking-widest">
            <Users size={12} weight="bold" /> Invited
          </div>
          <div className="font-chrome text-3xl mt-1 tabular-nums" data-testid="referral-invited">
            {data.invited_count}
          </div>
        </div>
        <div className="milli-card p-4">
          <div className="flex items-center gap-1.5 text-zinc-500 font-mono text-[10px] uppercase tracking-widest">
            <Gift size={12} weight="bold" /> Credit earned
          </div>
          <div className="font-chrome text-3xl mt-1 text-volt tabular-nums" data-testid="referral-credit">
            ${creditDollars.toFixed(0)}
          </div>
        </div>
      </div>

      {/* Redeem */}
      <div className="milli-card p-5">
        <div className="text-zinc-400 font-mono text-[10px] uppercase tracking-widest">Redeem a code</div>
        <div className="mt-3 flex gap-2">
          <input
            data-testid="referral-redeem-input"
            value={redeemCode}
            onChange={(e) => setRedeemCode(e.target.value.toUpperCase())}
            placeholder="MILLI-XXXXXX"
            className="flex-1 bg-transparent border border-hairline px-3 py-2.5 rounded-xl font-mono text-sm focus:outline-none focus:border-volt tracking-widest"
          />
          <button
            data-testid="referral-redeem-btn"
            onClick={redeem}
            disabled={busy || !redeemCode}
            className="btn-volt px-4 py-2.5 text-[11px] uppercase tracking-[0.14em] disabled:opacity-50 whitespace-nowrap"
          >
            {busy ? "..." : "Redeem"}
          </button>
        </div>
        <p className="mt-2 text-[11px] text-zinc-500 leading-relaxed">
          Enter a friend&apos;s code within your first 30 days and you&apos;ll each get ${rewardDollars.toFixed(0)} in Tax Vault credit.
        </p>
      </div>

      {/* How it works */}
      <div className="milli-card p-5">
        <div className="text-zinc-400 font-mono text-[10px] uppercase tracking-widest mb-3">How it works</div>
        <ol className="space-y-2.5 text-sm text-zinc-300 list-decimal list-inside">
          <li>Share your code or link.</li>
          <li>They sign up for Milli & activate any plan.</li>
          <li>You <span className="text-volt font-bold">both</span> get ${rewardDollars.toFixed(0)} deposited to your Tax Vault. No cap on invites.</li>
        </ol>
      </div>
    </div>
  );
}
