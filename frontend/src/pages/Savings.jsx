import { useState, useEffect } from "react";
import { PiggyBank, Plus, TrashSimple, PencilSimple, Target, CalendarBlank, TrendUp } from "@phosphor-icons/react";

const STORAGE_KEY = "milli_savings_goals";

const DEFAULT_GOALS = [
  { id: "emergency", name: "Emergency Fund", target: 5000, saved: 0, color: "#00E5FF", icon: "shield" },
  { id: "vehicle", name: "Vehicle Repair Fund", target: 2000, saved: 0, color: "#D4FF00", icon: "car" },
  { id: "vacation", name: "Vacation Fund", target: 1500, saved: 0, color: "#00B4C2", icon: "airplane" },
  { id: "equipment", name: "Equipment Fund", target: 800, saved: 0, color: "#C0C0C0", icon: "package" },
];

export default function Savings() {
  const [goals, setGoals] = useState([]);
  const [showAdd, setShowAdd] = useState(false);
  const [newGoal, setNewGoal] = useState({ name: "", target: "", color: "#00E5FF" });
  const [editingId, setEditingId] = useState(null);
  const [contributeAmount, setContributeAmount] = useState("");
  const [contributingTo, setContributingTo] = useState(null);

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        setGoals(JSON.parse(stored));
      } else {
        setGoals(DEFAULT_GOALS);
        localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_GOALS));
      }
    } catch { setGoals(DEFAULT_GOALS); }
  }, []);

  const saveGoals = (updated) => {
    setGoals(updated);
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(updated)); } catch {}
  };

  const totalSaved = goals.reduce((sum, g) => sum + g.saved, 0);
  const totalTarget = goals.reduce((sum, g) => sum + g.target, 0);
  const overallProgress = totalTarget > 0 ? Math.min(100, (totalSaved / totalTarget) * 100) : 0;

  const handleAddGoal = () => {
    if (!newGoal.name || !newGoal.target) return;
    const goal = {
      id: `custom-${Date.now()}`,
      name: newGoal.name,
      target: parseFloat(newGoal.target),
      saved: 0,
      color: newGoal.color,
      icon: "target",
    };
    saveGoals([...goals, goal]);
    setNewGoal({ name: "", target: "", color: "#00E5FF" });
    setShowAdd(false);
  };

  const handleContribute = (goalId) => {
    const amount = parseFloat(contributeAmount);
    if (!amount || amount <= 0) return;
    const updated = goals.map(g =>
      g.id === goalId ? { ...g, saved: g.saved + amount } : g
    );
    saveGoals(updated);
    setContributeAmount("");
    setContributingTo(null);
  };

  const handleDelete = (goalId) => {
    saveGoals(goals.filter(g => g.id !== goalId));
  };

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">
      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          Savings
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">
          Build financial stability beyond tax season.
        </p>
      </header>

      {/* Overview card */}
      <div className="milli-card rounded-3xl p-5" style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}>
        <div className="flex items-center justify-between mb-4">
          <div>
            <div className="text-zinc-400 text-[12px] uppercase tracking-wider font-chrome">Total Saved</div>
            <div className="font-display text-[32px] font-bold text-white leading-none mt-1">
              ${totalSaved.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
          <div className="text-right">
            <div className="text-zinc-400 text-[12px] uppercase tracking-wider font-chrome">Target</div>
            <div className="font-display text-[20px] font-semibold text-zinc-300 mt-1">
              ${totalTarget.toLocaleString()}
            </div>
          </div>
        </div>
        {/* Progress bar */}
        <div className="h-3 rounded-full bg-white/5 overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-700"
            style={{
              width: `${overallProgress}%`,
              background: "linear-gradient(90deg, #D4FF00, #00E5FF)",
            }}
          />
        </div>
        <div className="text-zinc-500 text-[12px] mt-2 text-right font-chrome">
          {overallProgress.toFixed(1)}% of total target
        </div>
      </div>

      {/* Add goal button */}
      <button
        onClick={() => setShowAdd(!showAdd)}
        data-testid="savings-add-goal-toggle"
        className="w-full milli-card rounded-2xl py-3.5 flex items-center justify-center gap-2 text-[14px] font-semibold active:scale-[0.99] transition-transform"
        style={{ background: "rgba(0,229,255,0.06)", border: "1px solid rgba(0,229,255,0.2)" }}
      >
        <Plus size={18} weight="bold" className="text-volt" />
        <span className="text-volt">Add Savings Goal</span>
      </button>

      {/* Add goal form */}
      {showAdd && (
        <div className="milli-card rounded-2xl p-4 space-y-3" style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}>
          <input
            type="text"
            placeholder="Goal name (e.g. New Laptop)"
            value={newGoal.name}
            onChange={e => setNewGoal({ ...newGoal, name: e.target.value })}
            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40"
          />
          <input
            type="number"
            placeholder="Target amount ($)"
            value={newGoal.target}
            onChange={e => setNewGoal({ ...newGoal, target: e.target.value })}
            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40"
          />
          <div className="flex gap-2">
            {["#00E5FF", "#D4FF00", "#00B4C2", "#C0C0C0"].map(c => (
              <button
                key={c}
                onClick={() => setNewGoal({ ...newGoal, color: c })}
                className="w-8 h-8 rounded-full transition-transform"
                style={{
                  background: c,
                  transform: newGoal.color === c ? "scale(1.2)" : "scale(1)",
                  boxShadow: newGoal.color === c ? `0 0 12px ${c}` : "none",
                }}
              />
            ))}
          </div>
          <button
            onClick={handleAddGoal}
            data-testid="savings-add-goal-confirm"
            className="w-full rounded-xl py-3 text-[14px] font-bold uppercase tracking-wide text-black transition-transform active:scale-[0.99]"
            style={{ background: "#D4FF00" }}
          >
            Create Goal
          </button>
        </div>
      )}

      {/* Goal cards */}
      {goals.map(goal => {
        const progress = goal.target > 0 ? Math.min(100, (goal.saved / goal.target) * 100) : 0;
        const remaining = Math.max(0, goal.target - goal.saved);
        const isComplete = goal.saved >= goal.target;

        return (
          <div
            key={goal.id}
            className="milli-card rounded-3xl p-5 space-y-4"
            style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}
          >
            {/* Goal header */}
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: `${goal.color}15`, border: `1px solid ${goal.color}40` }}
                >
                  <PiggyBank size={20} weight="fill" style={{ color: goal.color }} />
                </div>
                <div>
                  <div className="text-white font-semibold text-[15px]">{goal.name}</div>
                  <div className="text-zinc-500 text-[12px] font-chrome">
                    {isComplete ? "Goal reached!" : `$${remaining.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })} to go"}
                  </div>
                </div>
              </div>
              <button
                onClick={() => handleDelete(goal.id)}
                className="text-zinc-600 hover:text-red-400 transition-colors p-1"
              >
                <TrashSimple size={16} weight="regular" />
              </button>
            </div>

            {/* Progress */}
            <div>
              <div className="flex items-baseline justify-between mb-2">
                <span className="font-display text-[22px] font-bold text-white">
                  ${goal.saved.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </span>
                <span className="text-zinc-400 text-[13px] font-chrome">
                  of ${goal.target.toLocaleString()}
                </span>
              </div>
              <div className="h-2.5 rounded-full bg-white/5 overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-700"
                  style={{
                    width: `${progress}%`,
                    background: isComplete
                      ? "linear-gradient(90deg, #D4FF00, #00E5FF)"
                      : goal.color,
                  }}
                />
              </div>
              <div className="text-right text-[11px] text-zinc-500 mt-1 font-chrome">
                {progress.toFixed(1)}%
              </div>
            </div>

            {/* Contribute */}
            {contributingTo === goal.id ? (
              <div className="flex gap-2">
                <input
                  type="number"
                  placeholder="Amount ($)"
                  value={contributeAmount}
                  onChange={e => setContributeAmount(e.target.value)}
                  autoFocus
                  className="flex-1 bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40"
                />
                <button
                  onClick={() => handleContribute(goal.id)}
                  data-testid={`savings-contribute-${goal.id}`}
                  className="rounded-xl px-4 py-2.5 text-[13px] font-bold text-black"
                  style={{ background: "#D4FF00" }}
                >
                  Add
                </button>
                <button
                  onClick={() => { setContributingTo(null); setContributeAmount(""); }}
                  className="rounded-xl px-3 py-2.5 text-[13px] text-zinc-400 border border-white/10"
                >
                  Cancel
                </button>
              </div>
            ) : (
              <button
                onClick={() => setContributingTo(goal.id)}
                className="w-full rounded-xl py-2.5 text-[13px] font-semibold flex items-center justify-center gap-2 transition-transform active:scale-[0.99]"
                style={{ background: "rgba(0,229,255,0.06)", border: "1px solid rgba(0,229,255,0.15)" }}
              >
                <TrendUp size={15} weight="bold" className="text-volt" />
                <span className="text-volt">Add Money</span>
              </button>
            )}
          </div>
        );
      })}

      {/* Empty state */}
      {goals.length === 0 && !showAdd && (
        <div className="milli-card rounded-3xl p-8 text-center" style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}>
          <Target size={40} weight="thin" className="text-zinc-600 mx-auto mb-3" />
          <p className="text-white font-semibold text-[16px]">No savings goals yet</p>
          <p className="text-zinc-500 text-[13px] mt-1 max-w-xs mx-auto">
            Create your first savings goal to start building financial stability beyond tax season.
          </p>
        </div>
      )}

      {/* Info note */}
      <div className="text-center text-zinc-600 text-[11px] font-chrome pt-2">
        Savings goals are separate from your Milli Tax Vault. Funds remain under your control.
      </div>
    </div>
  );
}