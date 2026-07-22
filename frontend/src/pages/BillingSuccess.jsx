import { useEffect, useState } from "react";
import { useSearchParams, Link, useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { CheckCircle, Lightning } from "@phosphor-icons/react";

export default function BillingSuccess() {
  const [params] = useSearchParams();
  const sessionId = params.get("session_id");
  const { refresh } = useAuth();
  const nav = useNavigate();
  const [status, setStatus] = useState("checking");
  const [attempts, setAttempts] = useState(0);

  useEffect(() => {
    if (!sessionId) { setStatus("error"); return; }
    let cancelled = false;

    async function poll() {
      try {
        const { data } = await api.get(`/stripe/status/${sessionId}`);
        if (cancelled) return;
        if (data.payment_status === "paid") {
          setStatus("paid");
          await refresh();
        } else if (data.status === "expired") {
          setStatus("expired");
        } else if (attempts < 8) {
          setAttempts((a) => a + 1);
          setTimeout(poll, 2000);
        } else {
          setStatus("timeout");
        }
      } catch {
        setStatus("error");
      }
    }
    poll();
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sessionId]);

  return (
    <div className="min-h-screen bg-obsidian flex items-center justify-center p-6" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100%" }}>
      <div className="milli-card p-10 max-w-md text-center">
        {status === "checking" && (
          <>
            <Lightning size={48} className="text-volt mx-auto animate-pulse-volt" weight="fill" />
            <div className="font-display font-black text-2xl mt-6">Confirming payment...</div>
            <div className="text-sm text-zinc-500 font-mono mt-2">attempt {attempts + 1}</div>
          </>
        )}
        {status === "paid" && (
          <>
            <CheckCircle size={56} className="text-success mx-auto" weight="fill" />
            <div className="font-display font-black text-3xl mt-6">You're in.</div>
            <div className="text-sm text-zinc-400 mt-2">Your plan is now active. Time to keep more of your money.</div>
            <button onClick={() => nav("/app")} data-testid="billing-go-dashboard" className="btn-volt mt-6 px-6 py-3 font-bold uppercase tracking-wider text-sm">Back to dashboard</button>
          </>
        )}
        {(status === "error" || status === "expired" || status === "timeout") && (
          <>
            <div className="font-display font-black text-2xl text-danger">Payment {status}</div>
            <Link to="/app/pricing" className="btn-volt mt-6 px-6 py-3 font-bold uppercase tracking-wider text-sm inline-block">Try again</Link>
          </>
        )}
      </div>
    </div>
  );
}
