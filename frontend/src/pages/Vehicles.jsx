import { useState, useEffect } from "react";
import {
  Car, Plus, TrashSimple, PencilSimple, Gauge,
  GasPump, Calendar, Check,
} from "@phosphor-icons/react";

const STORAGE_KEY = "milli_vehicles";

const FUEL_TYPES = ["Gasoline", "Diesel", "Hybrid", "Electric", "Flex Fuel"];

export default function Vehicles() {
  const [vehicles, setVehicles] = useState([]);
  const [showAdd, setShowAdd] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState({
    name: "", year: "", make: "", model: "",
    fuelType: "Gasoline", mpg: "", odometer: "", businessUsePct: "100",
    isPrimary: false,
  });

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) setVehicles(JSON.parse(stored));
    } catch {}
  }, []);

  const saveVehicles = (updated) => {
    setVehicles(updated);
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(updated)); } catch {}
  };

  const handleSave = () => {
    if (!form.name || !form.make || !form.model) return;
    const vehicle = {
      id: editingId || `vehicle-${Date.now()}`,
      ...form,
      year: parseInt(form.year) || new Date().getFullYear(),
      mpg: parseFloat(form.mpg) || 0,
      odometer: parseInt(form.odometer) || 0,
      businessUsePct: parseInt(form.businessUsePct) || 100,
      isPrimary: form.isPrimary || vehicles.length === 0,
    };
    let updated;
    if (editingId) {
      updated = vehicles.map(v => v.id === editingId ? vehicle : v);
    } else {
      // If new vehicle is primary, unset others
      updated = vehicle.isPrimary
        ? [...vehicles.map(v => ({ ...v, isPrimary: false })), vehicle]
        : [...vehicles, vehicle];
    }
    saveVehicles(updated);
    setForm({ name: "", year: "", make: "", model: "", fuelType: "Gasoline", mpg: "", odometer: "", businessUsePct: "100", isPrimary: false });
    setEditingId(null);
    setShowAdd(false);
  };

  const handleEdit = (v) => {
    setEditingId(v.id);
    setForm({
      name: v.name, year: String(v.year), make: v.make, model: v.model,
      fuelType: v.fuelType, mpg: String(v.mpg), odometer: String(v.odometer),
      businessUsePct: String(v.businessUsePct), isPrimary: v.isPrimary,
    });
    setShowAdd(true);
  };

  const handleDelete = (id) => {
    saveVehicles(vehicles.filter(v => v.id !== id));
  };

  const handleSetPrimary = (id) => {
    saveVehicles(vehicles.map(v => ({ ...v, isPrimary: v.id === id })));
  };

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">
      {/* Header */}
      <header>
        <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
          Vehicles
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">
          Manage vehicles for mileage tracking and deductions.
        </p>
      </header>

      {/* Add button */}
      <button
        onClick={() => { setShowAdd(!showAdd); if (!showAdd) { setEditingId(null); setForm({ name: "", year: "", make: "", model: "", fuelType: "Gasoline", mpg: "", odometer: "", businessUsePct: "100", isPrimary: false }); } }}
        data-testid="vehicles-add-toggle"
        className="w-full milli-card rounded-2xl py-3.5 flex items-center justify-center gap-2 text-[14px] font-semibold active:scale-[0.99] transition-transform"
        style={{ background: "rgba(0,229,255,0.06)", border: "1px solid rgba(0,229,255,0.2)" }}
      >
        <Plus size={18} weight="bold" className="text-volt" />
        <span className="text-volt">{editingId ? "Edit Vehicle" : "Add Vehicle"}</span>
      </button>

      {/* Add/Edit form */}
      {showAdd && (
        <div className="milli-card rounded-2xl p-4 space-y-3" style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}>
          <div className="grid grid-cols-2 gap-3">
            <input type="text" placeholder="Nickname" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
              className="bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40" />
            <input type="number" placeholder="Year" value={form.year} onChange={e => setForm({ ...form, year: e.target.value })}
              className="bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <input type="text" placeholder="Make" value={form.make} onChange={e => setForm({ ...form, make: e.target.value })}
              className="bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40" />
            <input type="text" placeholder="Model" value={form.model} onChange={e => setForm({ ...form, model: e.target.value })}
              className="bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40" />
          </div>
          <select value={form.fuelType} onChange={e => setForm({ ...form, fuelType: e.target.value })}
            className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt/40">
            {FUEL_TYPES.map(f => <option key={f} value={f} className="bg-zinc-900">{f}</option>)}
          </select>
          <div className="grid grid-cols-2 gap-3">
            <input type="number" placeholder="MPG" value={form.mpg} onChange={e => setForm({ ...form, mpg: e.target.value })}
              className="bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40" />
            <input type="number" placeholder="Odometer (mi)" value={form.odometer} onChange={e => setForm({ ...form, odometer: e.target.value })}
              className="bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] placeholder:text-zinc-500 focus:outline-none focus:border-volt/40" />
          </div>
          <div>
            <label className="text-zinc-400 text-[12px] font-chrome uppercase tracking-wider">Business Use %</label>
            <input type="number" min="0" max="100" value={form.businessUsePct} onChange={e => setForm({ ...form, businessUsePct: e.target.value })}
              className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2.5 text-white text-[14px] focus:outline-none focus:border-volt/40 mt-1" />
          </div>
          <label className="flex items-center gap-2 text-zinc-300 text-[13px] cursor-pointer">
            <input type="checkbox" checked={form.isPrimary} onChange={e => setForm({ ...form, isPrimary: e.target.checked })}
              className="w-4 h-4 rounded accent-volt" />
            Set as primary vehicle
          </label>
          <button onClick={handleSave} data-testid="vehicles-save"
            className="w-full rounded-xl py-3 text-[14px] font-bold uppercase tracking-wide text-black transition-transform active:scale-[0.99]"
            style={{ background: "#D4FF00" }}>
            {editingId ? "Update Vehicle" : "Add Vehicle"}
          </button>
        </div>
      )}

      {/* Vehicle cards */}
      {vehicles.map(v => (
        <div key={v.id} className="milli-card rounded-3xl p-5 space-y-4"
          style={{ background: "rgba(10,14,18,0.7)", border: v.isPrimary ? "1px solid rgba(212,255,0,0.2)" : "1px solid rgba(255,255,255,0.06)" }}>
          {/* Header */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl flex items-center justify-center"
                style={{ background: v.isPrimary ? "rgba(212,255,0,0.08)" : "rgba(0,229,255,0.08)", border: v.isPrimary ? "1px solid rgba(212,255,0,0.3)" : "1px solid rgba(0,229,255,0.2)" }}>
                <Car size={20} weight="fill" className={v.isPrimary ? "text-volt" : "text-volt"} />
              </div>
              <div>
                <div className="text-white font-semibold text-[15px] flex items-center gap-2">
                  {v.name}
                  {v.isPrimary && (
                    <span className="text-[10px] font-chrome uppercase tracking-wider px-1.5 py-0.5 rounded-full"
                      style={{ background: "rgba(212,255,0,0.1)", color: "#D4FF00", border: "1px solid rgba(212,255,0,0.2)" }}>
                      Primary
                    </span>
                  )}
                </div>
                <div className="text-zinc-500 text-[12px] font-chrome">{v.year} {v.make} {v.model}</div>
              </div>
            </div>
            <div className="flex gap-1">
              <button onClick={() => handleEdit(v)} className="text-zinc-600 hover:text-volt transition-colors p-1">
                <PencilSimple size={15} />
              </button>
              <button onClick={() => handleDelete(v.id)} className="text-zinc-600 hover:text-red-400 transition-colors p-1">
                <TrashSimple size={15} />
              </button>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-3">
            <div className="rounded-xl p-3" style={{ background: "rgba(255,255,255,0.03)" }}>
              <GasPump size={14} className="text-zinc-500 mb-1" />
              <div className="text-white text-[14px] font-semibold">{v.mpg || "--"}</div>
              <div className="text-zinc-600 text-[10px] font-chrome uppercase">MPG</div>
            </div>
            <div className="rounded-xl p-3" style={{ background: "rgba(255,255,255,0.03)" }}>
              <Gauge size={14} className="text-zinc-500 mb-1" />
              <div className="text-white text-[14px] font-semibold">{v.odometer.toLocaleString()}</div>
              <div className="text-zinc-600 text-[10px] font-chrome uppercase">Odometer</div>
            </div>
            <div className="rounded-xl p-3" style={{ background: "rgba(255,255,255,0.03)" }}>
              <Calendar size={14} className="text-zinc-500 mb-1" />
              <div className="text-white text-[14px] font-semibold">{v.businessUsePct}%</div>
              <div className="text-zinc-600 text-[10px] font-chrome uppercase">Business</div>
            </div>
          </div>

          {/* Fuel type badge */}
          <div className="flex items-center gap-2">
            <span className="text-[11px] font-chrome uppercase tracking-wider px-2 py-1 rounded-lg"
              style={{ background: "rgba(0,229,255,0.06)", color: "#00E5FF", border: "1px solid rgba(0,229,255,0.15)" }}>
              {v.fuelType}
            </span>
          </div>

          {/* Set primary */}
          {!v.isPrimary && (
            <button onClick={() => handleSetPrimary(v.id)}
              className="w-full rounded-xl py-2 text-[12px] font-semibold text-zinc-400 border border-white/10 active:scale-[0.99] transition-transform">
              Set as Primary
            </button>
          )}
        </div>
      ))}

      {/* Empty state */}
      {vehicles.length === 0 && !showAdd && (
        <div className="milli-card rounded-3xl p-8 text-center" style={{ background: "rgba(10,14,18,0.7)", border: "1px solid rgba(255,255,255,0.06)" }}>
          <Car size={40} weight="thin" className="text-zinc-600 mx-auto mb-3" />
          <p className="text-white font-semibold text-[16px]">No vehicles added yet</p>
          <p className="text-zinc-500 text-[13px] mt-1 max-w-xs mx-auto">
            Add your vehicle to start tracking mileage and calculating deductions for every trip.
          </p>
        </div>
      )}

      <div className="text-center text-zinc-600 text-[11px] font-chrome pt-2">
        Vehicle data is used for mileage deductions and Milli Cents¢ profitability calculations.
      </div>
    </div>
  );
}