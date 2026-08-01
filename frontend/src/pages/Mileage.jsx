import { useEffect, useRef, useState } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { toast } from "sonner";
import { MapTrifold, Play, Stop, Plus, Trash, Crosshair } from "@phosphor-icons/react";
import RoadScene from "@/components/RoadScene";
import { isNative, startTrip as startNativeTrip, stopTrip as stopNativeTrip } from "@/native/mileageTracker";

export default function Mileage() {
  const [active, setActive] = useState(null);
  const [trips, setTrips] = useState([]);
  const [showManual, setShowManual] = useState(false);
  const [tracking, setTracking] = useState(false);
  const [livePoints, setLivePoints] = useState([]);
  const [liveMiles, setLiveMiles] = useState(0);
  const [elapsed, setElapsed] = useState(0);
  const watchIdRef = useRef(null);
  const startTimeRef = useRef(null);
  const tickRef = useRef(null);
  const [platform, setPlatform] = useState("Uber");

  async function load() {
    try {
      const [a, t] = await Promise.all([
        api.get("/trips/active"),
        api.get("/trips"),
      ]);
      setActive(a.data);
      setTrips(t.data);
      if (a.data) {
        // resume UI in active mode (no GPS state — we trust active flag)
        setTracking(true);
        startTimeRef.current = new Date(a.data.start_time).getTime();
        startTicker();
      }
    } catch (e) { toast.error(formatApiError(e)); }
  }

  useEffect(() => {
    load();
    return () => {
      if (watchIdRef.current && navigator.geolocation) navigator.geolocation.clearWatch(watchIdRef.current);
      if (tickRef.current) clearInterval(tickRef.current);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function startTicker() {
    if (tickRef.current) clearInterval(tickRef.current);
    tickRef.current = setInterval(() => {
      if (startTimeRef.current) setElapsed(Math.floor((Date.now() - startTimeRef.current) / 1000));
    }, 1000);
  }

  function hav(p1, p2) {
    const toRad = (d) => (d * Math.PI) / 180;
    const R = 3958.7613;
    const dLat = toRad(p2[0] - p1[0]);
    const dLng = toRad(p2[1] - p1[1]);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(p1[0])) * Math.cos(toRad(p2[0])) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(a));
  }

  async function startTrip() {
    // Native iOS/Android: use background-capable GPS so trips continue
    // while the screen is off or the app is backgrounded.
    if (isNative()) {
      try {
        // Get a one-shot fix to anchor the trip start on the server.
        const fix = await new Promise((resolve, reject) => {
          if (!navigator.geolocation) return reject(new Error("Geolocation not supported"));
          navigator.geolocation.getCurrentPosition(
            (p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
            (err) => reject(err),
            { enableHighAccuracy: true, timeout: 15000 }
          );
        });
        const { data } = await api.post("/trips/start", {
          platform,
          start_lat: fix.lat,
          start_lng: fix.lng,
        });
        setActive(data);
        setTracking(true);
        setLivePoints([[fix.lat, fix.lng]]);
        setLiveMiles(0);
        startTimeRef.current = Date.now();
        setElapsed(0);
        startTicker();
        await startNativeTrip(
          (loc) => {
            const pt = [loc.latitude, loc.longitude];
            setLivePoints((prev) => {
              if (prev.length) {
                const d = hav(prev[prev.length - 1], pt);
                if (d > 0.005) {
                  setLiveMiles((m) => m + d);
                  return [...prev, pt];
                }
                return prev;
              }
              return [pt];
            });
          },
          (err) => toast.error("GPS error: " + err.message)
        );
        toast.success("Trip started — background GPS active");
      } catch (e) {
        toast.error(typeof e === "string" ? e : (e?.message || formatApiError(e)));
      }
      return;
    }

    if (!navigator.geolocation) { toast.error("Geolocation not supported"); return; }
    navigator.geolocation.getCurrentPosition(async (pos) => {
      try {
        const { data } = await api.post("/trips/start", {
          platform,
          start_lat: pos.coords.latitude,
          start_lng: pos.coords.longitude,
        });
        setActive(data);
        setTracking(true);
        setLivePoints([[pos.coords.latitude, pos.coords.longitude]]);
        setLiveMiles(0);
        startTimeRef.current = Date.now();
        setElapsed(0);
        startTicker();
        watchIdRef.current = navigator.geolocation.watchPosition(
          (p) => {
            const pt = [p.coords.latitude, p.coords.longitude];
            setLivePoints((prev) => {
              if (prev.length) {
                const d = hav(prev[prev.length - 1], pt);
                if (d > 0.005) {
                  setLiveMiles((m) => m + d);
                  return [...prev, pt];
                }
                return prev;
              }
              return [pt];
            });
          },
          (err) => toast.error("GPS error: " + err.message),
          { enableHighAccuracy: true, maximumAge: 5000, timeout: 15000 }
        );
        toast.success("Trip started — drive safe");
      } catch (e) { toast.error(formatApiError(e)); }
    }, (err) => toast.error("Location denied: " + err.message), { enableHighAccuracy: true });
  }

  async function endTrip() {
    if (!active) return;
    if (isNative()) {
      try { await stopNativeTrip(); } catch (_) { /* noop */ }
    }
    if (watchIdRef.current && navigator.geolocation) navigator.geolocation.clearWatch(watchIdRef.current);
    if (tickRef.current) clearInterval(tickRef.current);
    const finalPoints = livePoints.map((p) => ({ lat: p[0], lng: p[1] }));
    try {
      const { data } = await api.post(`/trips/${active.id}/end`, {
        points: finalPoints,
        miles: liveMiles || undefined,
      });
      toast.success(`Trip saved — ${data.miles.toFixed(2)} mi · +${money(data.deductible_value)} deduction`);
      setActive(null);
      setTracking(false);
      setLivePoints([]);
      setLiveMiles(0);
      setElapsed(0);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  async function deleteTrip(id) {
    if (!window.confirm("Delete trip?")) return;
    try {
      await api.delete(`/trips/${id}`);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  const totalMiles = trips.reduce((s, t) => s + (t.miles || 0), 0);
  const totalDed = trips.reduce((s, t) => s + (t.deductible_value || 0), 0);

  return (
    <div className="p-6 lg:p-10 max-w-7xl" style={{ backgroundColor: "#050607", color: "#FFFFFF", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif", minHeight: "100%" }}>
      <div className="flex justify-between items-end mb-8 flex-wrap gap-4">
        <div>
          <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Mileage</div>
          <h1 className="font-display font-black text-4xl tracking-tighter mt-1">Trip tracker</h1>
          <p className="text-zinc-400 mt-1">GPS logs every mile. $0.70 / mi deduction.</p>
        </div>
        <button
          data-testid="mileage-add-manual"
          onClick={() => setShowManual(true)}
          className="px-4 py-2.5 border border-hairline text-xs font-bold uppercase tracking-wider hover:border-white inline-flex items-center gap-2"
        ><Plus size={14} weight="bold" /> Manual trip</button>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
        <Stat label="YTD Miles" value={num(totalMiles)} />
        <Stat label="YTD Deduction" value={money(totalDed)} accent />
        <Stat label="Trips" value={trips.length} />
      </div>

      {/* Live tracker */}
      <div
        className="milli-card mb-6 relative overflow-hidden"
        style={tracking ? {
          backgroundImage: "url(https://images.pexels.com/photos/5962471/pexels-photo-5962471.jpeg)",
          backgroundSize: "cover", backgroundPosition: "center",
          minHeight: 320,
        } : { minHeight: 320 }}
        data-testid="live-tracker"
      >
        {tracking && <div className="absolute inset-0 bg-black/80" />}
        {/* Idle road scene — only when not tracking */}
        {!tracking && (
          <div className="absolute inset-0 opacity-60">
            <RoadScene showLogo={false} />
          </div>
        )}
        {/* Soft gradient overlay so controls stay readable on the road */}
        {!tracking && (
          <div className="absolute inset-0 pointer-events-none" style={{
            background: "linear-gradient(180deg, rgba(5,6,7,0.85) 0%, rgba(5,6,7,0.55) 35%, rgba(5,6,7,0.45) 65%, rgba(5,6,7,0.9) 100%)",
          }} />
        )}
        <div className="relative p-8 h-full">
          <div className="text-volt font-mono text-xs uppercase tracking-[0.3em] mb-4">// Live tracker</div>
          {!tracking ? (
            <div className="flex flex-col md:flex-row items-start md:items-end gap-6">
              <div className="flex-1">
                <div className="font-display font-black text-3xl mb-2">Ready to roll?</div>
                <div className="text-zinc-400 text-sm mb-4">Pick your platform, hit Start. We&apos;ll track the rest.</div>
                <select
                  data-testid="live-platform"
                  value={platform}
                  onChange={(e) => setPlatform(e.target.value)}
                  className="bg-obsidian border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt"
                >
                  {["Uber", "DoorDash", "Spark", "Lyft", "Instacart", "Amazon Flex", "Grubhub", "Shipt", "Other"].map((o) => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>
              <button
                data-testid="trip-start"
                onClick={startTrip}
                className="btn-volt px-8 py-4 text-base font-bold uppercase tracking-wider inline-flex items-center gap-3 animate-pulse-volt"
              ><Play size={20} weight="fill" /> Start trip</button>
            </div>
          ) : (
            <div>
              <div className="flex items-center gap-3 mb-6">
                <span className="w-3 h-3 bg-danger rounded-full animate-pulse" />
                <span className="font-mono uppercase tracking-widest text-danger text-sm">Tracking · {active?.platform}</span>
              </div>
              <div className="grid grid-cols-3 gap-6 max-w-xl">
                <LiveStat label="Miles" value={num(liveMiles, 2)} accent />
                <LiveStat label="Time" value={formatTime(elapsed)} />
                <LiveStat label="Deductible" value={money(liveMiles * 0.70)} />
              </div>
              <div className="mt-4 flex items-center gap-2 text-xs text-zinc-500 font-mono">
                <Crosshair size={14} /> {livePoints.length} GPS pings
              </div>
              <button
                data-testid="trip-end"
                onClick={endTrip}
                className="mt-6 bg-danger text-white px-8 py-4 font-bold uppercase tracking-wider inline-flex items-center gap-3 hover:bg-danger/90"
              ><Stop size={20} weight="fill" /> End trip</button>
            </div>
          )}
        </div>
      </div>

      {/* Trip history */}
      <div className="milli-card p-6">
        <div className="font-display font-bold text-lg mb-4">Trip history</div>
        {trips.length === 0 ? (
          <div className="text-center py-12">
            <MapTrifold size={40} className="text-zinc-700 mx-auto" weight="bold" />
            <div className="font-display font-bold mt-3">No trips yet</div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="font-mono text-xs uppercase text-zinc-500 tracking-widest">
                <tr className="border-b border-hairline">
                  <th className="text-left py-2 px-2">Date</th>
                  <th className="text-left py-2 px-2">Platform</th>
                  <th className="text-right py-2 px-2">Miles</th>
                  <th className="text-right py-2 px-2">Deductible</th>
                  <th className="text-right py-2 px-2"></th>
                </tr>
              </thead>
              <tbody className="font-mono">
                {trips.map((t) => (
                  <tr key={t.id} className="border-b border-hairline/60 hover:bg-white/5" data-testid={`mileage-trip-${t.id}`}>
                    <td className="py-2.5 px-2 text-zinc-400">{(t.start_time || "").slice(0, 10)}</td>
                    <td className="py-2.5 px-2">{t.platform || "Delivery"} {t.manual && <span className="text-xs text-zinc-500 ml-1">(manual)</span>}</td>
                    <td className="py-2.5 px-2 text-right font-bold">{num(t.miles, 2)}</td>
                    <td className="py-2.5 px-2 text-right text-volt">+{money(t.deductible_value)}</td>
                    <td className="py-2.5 px-2 text-right">
                      <button onClick={() => deleteTrip(t.id)} data-testid={`mileage-delete-${t.id}`} className="text-zinc-500 hover:text-danger"><Trash size={14} weight="bold" /></button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showManual && <ManualTripDialog onClose={() => setShowManual(false)} onSaved={() => { setShowManual(false); load(); }} />}
    </div>
  );
}

function formatTime(s) {
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
}

function Stat({ label, value, accent }) {
  return (
    <div className="milli-card p-4">
      <div className="text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 truncate">{label}</div>
      <div className={`font-display font-black text-[22px] mt-2 tabular-nums truncate ${accent ? "text-volt" : ""}`}>{value}</div>
    </div>
  );
}

function LiveStat({ label, value, accent }) {
  return (
    <div className="min-w-0">
      <div className="text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 truncate">{label}</div>
      <div className={`font-display font-black text-[28px] mt-1 tabular-nums truncate ${accent ? "text-volt" : ""}`}>{value}</div>
    </div>
  );
}

function ManualTripDialog({ onClose, onSaved }) {
  const [form, setForm] = useState({
    date: new Date().toISOString().slice(0, 10),
    miles: "",
    platform: "Uber",
    notes: "",
  });
  const [busy, setBusy] = useState(false);

  async function save() {
    setBusy(true);
    try {
      await api.post("/trips/manual", { ...form, miles: parseFloat(form.miles) });
      toast.success("Trip added");
      onSaved();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="milli-card p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="font-display font-bold text-xl mb-4">Add manual trip</div>
        <div className="space-y-3">
          <FieldInput label="Date" type="date" id="manual-trip-date" value={form.date} onChange={(v) => setForm({ ...form, date: v })} />
          <FieldInput label="Miles" type="number" step="0.01" id="manual-trip-miles" value={form.miles} onChange={(v) => setForm({ ...form, miles: v })} />
          <FieldSelect label="Platform" id="manual-trip-platform" value={form.platform} onChange={(v) => setForm({ ...form, platform: v })} options={["Uber", "DoorDash", "Spark", "Lyft", "Instacart", "Amazon Flex", "Grubhub", "Shipt", "Other"]} />
          <FieldInput label="Notes" id="manual-trip-notes" value={form.notes} onChange={(v) => setForm({ ...form, notes: v })} />
        </div>
        <div className="flex gap-2 mt-6">
          <button onClick={onClose} className="flex-1 px-4 py-2.5 border border-hairline text-xs font-bold uppercase tracking-wider">Cancel</button>
          <button data-testid="manual-trip-save" onClick={save} disabled={busy || !form.miles} className="flex-1 btn-volt px-4 py-2.5 text-xs font-bold uppercase tracking-wider disabled:opacity-50">{busy ? "Saving..." : "Save"}</button>
        </div>
      </div>
    </div>
  );
}

function FieldInput({ label, id, onChange, ...props }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <input id={id} data-testid={id} onChange={(e) => onChange(e.target.value)} {...props} className="w-full bg-transparent border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt" />
    </div>
  );
}

function FieldSelect({ label, id, value, onChange, options }) {
  return (
    <div>
      <label className="block text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mb-1">{label}</label>
      <select id={id} data-testid={id} value={value} onChange={(e) => onChange(e.target.value)} className="w-full bg-obsidian border border-hairline px-3 py-2 font-mono text-sm focus:outline-none focus:border-volt">
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
    </div>
  );
}
