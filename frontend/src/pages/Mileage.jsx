import { useEffect, useRef, useState } from "react";
import { api, formatApiError } from "@/lib/api";
import { toast } from "sonner";
import { Gear, CaretRight, Stop, Play } from "@phosphor-icons/react";

/**
 * Milli Mileage Tracker — matches the reference mockup exactly.
 * Structure:
 *   Header: title "Mileage Tracker" + "Auto-Tracking ON" pill (top-right).
 *   1. LIVE Tracking Trip card (cyan halo, big stats + Stop button).
 *   2. Google Map with cyan-glow route + "Today's Miles" overlay card.
 *   3. Trip History list.
 *   4. Monthly Summary card (Total Miles / Deduction / Trips / Tracked Time).
 */

const GMAPS_KEY = process.env.REACT_APP_GOOGLE_MAPS_KEY;

/* Load Google Maps JS SDK once. */
let gmapsPromise = null;
function loadGoogleMaps() {
  if (!GMAPS_KEY) return Promise.reject(new Error("Missing REACT_APP_GOOGLE_MAPS_KEY"));
  if (window.google?.maps) return Promise.resolve(window.google);
  if (gmapsPromise) return gmapsPromise;
  gmapsPromise = new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = `https://maps.googleapis.com/maps/api/js?key=${GMAPS_KEY}&v=quarterly`;
    s.async = true; s.defer = true;
    s.onload = () => resolve(window.google);
    s.onerror = reject;
    document.head.appendChild(s);
  });
  return gmapsPromise;
}

/* Milli-branded dark map style (deep noir + cyan roads) */
const MAP_STYLE = [
  { elementType: "geometry", stylers: [{ color: "#05070A" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#4A5566" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#05070A" }] },
  { featureType: "administrative", elementType: "geometry", stylers: [{ color: "#1B2027" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#151A22" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#0B0E13" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#1E2530" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#02060A" }] },
];

/* Demo route (Wilshire → West Hollywood → Beverly Hills → Culver City area) */
const DEMO_ROUTE = [
  { lat: 34.0587, lng: -118.4210 },
  { lat: 34.0680, lng: -118.4020 },
  { lat: 34.0790, lng: -118.3800 },
  { lat: 34.0870, lng: -118.3600 },
  { lat: 34.0910, lng: -118.3400 },
  { lat: 34.0870, lng: -118.3200 },
  { lat: 34.0770, lng: -118.3050 },
  { lat: 34.0670, lng: -118.2900 },
];

export default function Mileage() {
  const [active, setActive] = useState(null);
  const [trips, setTrips] = useState([]);
  const [autoTracking, setAutoTracking] = useState(true);
  const mapDivRef = useRef(null);
  const mapRef = useRef(null);

  async function load() {
    try {
      const [a, t] = await Promise.all([
        api.get("/trips/active"),
        api.get("/trips"),
      ]);
      setActive(a.data);
      setTrips(t.data || []);
    } catch (err) { toast.error(formatApiError(err)); }
  }
  useEffect(() => { load(); }, []);

  // Load & render the map
  useEffect(() => {
    if (!mapDivRef.current || !GMAPS_KEY) return;
    let poly, startPin, endPin;
    loadGoogleMaps().then((google) => {
      const map = new google.maps.Map(mapDivRef.current, {
        center: { lat: 34.078, lng: -118.36 },
        zoom: 12,
        disableDefaultUI: true,
        gestureHandling: "greedy",
        backgroundColor: "#05070A",
        styles: MAP_STYLE,
      });
      mapRef.current = map;

      // Glow polyline (double-stroke technique for neon effect)
      poly = new google.maps.Polyline({
        path: DEMO_ROUTE,
        strokeColor: "#00E5FF",
        strokeOpacity: 1,
        strokeWeight: 4,
        map,
      });
      new google.maps.Polyline({
        path: DEMO_ROUTE,
        strokeColor: "#00E5FF",
        strokeOpacity: 0.25,
        strokeWeight: 12,
        map,
      });

      // Start pin
      startPin = new google.maps.Marker({
        position: DEMO_ROUTE[0],
        map,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 10,
          fillColor: "#00E5FF",
          fillOpacity: 1,
          strokeColor: "#FFFFFF",
          strokeWeight: 2,
        },
      });
      endPin = new google.maps.Marker({
        position: DEMO_ROUTE[DEMO_ROUTE.length - 1],
        map,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 8,
          fillColor: "#00E5FF",
          fillOpacity: 1,
          strokeColor: "#0A0C10",
          strokeWeight: 2,
        },
      });
    }).catch(() => {/* silent — placeholder shown */});
    return () => { poly?.setMap?.(null); startPin?.setMap?.(null); endPin?.setMap?.(null); };
  }, []);

  // Derived data
  const totalMiles = trips.reduce((a, t) => a + Number(t.miles || 0), 0);
  const totalDeduction = totalMiles * 0.70;
  const trackedMinutes = trips.reduce((a, t) => a + Number(t.duration_minutes || 0), 0);
  const trackedTimeStr = `${Math.floor(trackedMinutes / 60)}h ${trackedMinutes % 60}m`;

  const today = new Date();
  const todaysTrips = trips.filter(t => {
    const d = new Date(t.date || t.created_at || 0);
    return d.toDateString() === today.toDateString();
  });
  const todaysMiles = todaysTrips.reduce((a, t) => a + Number(t.miles || 0), 0) || 45.7;
  const todaysDeduction = todaysMiles * 0.70;

  // Live trip stats — either from `active` or demo values
  const liveMiles  = Number(active?.miles || 12.4);
  const liveMinutes = Number(active?.duration_minutes || 27);
  const liveDeduction = liveMiles * 0.70;
  const livePlatform = active?.platform || "Uber";

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-5">

      {/* Header */}
      <header className="flex items-start justify-between gap-3">
        <div>
          <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight">
            Mileage Tracker
          </h1>
          <p className="text-zinc-400 text-[14px] mt-1">Track. Save. Deduct.</p>
        </div>
        <AutoTrackingPill on={autoTracking} onToggle={() => setAutoTracking(v => !v)} />
      </header>

      {/* 1 · LIVE Tracking Trip Card */}
      <section
        className="relative rounded-3xl p-5"
        data-testid="mileage-tracking-card"
        style={{
          background: "linear-gradient(180deg, rgba(0,229,255,0.05) 0%, rgba(10,14,18,0.85) 100%)",
          border: "1.5px solid rgba(0,229,255,0.7)",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.08), 0 0 34px rgba(0,229,255,0.35), 0 0 80px rgba(0,229,255,0.12)",
        }}
      >
        <div className="flex items-center gap-4 mb-4">
          <LivePulse />
          <div>
            <div className="font-chrome font-bold text-white text-[24px] leading-tight">Tracking Trip</div>
            <div className="text-volt text-[14px] font-medium" style={{ textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
              {livePlatform} <span className="text-white/40">•</span> Passenger
            </div>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-2 mb-5 text-center">
          <StatCol label="Miles" value={liveMiles.toFixed(1)} />
          <StatCol label="Time"  value={`${liveMinutes}m`} />
          <StatCol label="Est. Deduction" value={`$${liveDeduction.toFixed(2)}`} />
        </div>
        <button
          data-testid="stop-tracking-btn"
          onClick={() => toast.info("Trip stopped (demo)")}
          className="w-full rounded-2xl py-3.5 flex items-center justify-center gap-2 font-bold text-[15px] text-obsidian active:brightness-95 transition"
          style={{
            background: "linear-gradient(180deg, #00E5FF 0%, #00B4D0 100%)",
            boxShadow: "inset 0 1px 0 rgba(255,255,255,0.5), 0 0 24px rgba(0,229,255,0.55), 0 10px 24px rgba(0,229,255,0.3)",
          }}
        >
          <Stop size={16} weight="fill" /> Stop Tracking
        </button>
      </section>

      {/* 2 · Map with Today's Miles overlay */}
      <section
        className="relative rounded-3xl overflow-hidden"
        data-testid="mileage-map-card"
        style={{
          border: "1px solid rgba(0,229,255,0.22)",
          boxShadow: "0 0 24px rgba(0,229,255,0.18), 0 18px 40px rgba(0,0,0,0.55)",
          height: 260,
        }}
      >
        <div ref={mapDivRef} className="absolute inset-0" style={{ background: "#05070A" }} />
        {!GMAPS_KEY && (
          <div className="absolute inset-0 flex items-center justify-center text-zinc-500 text-sm">
            Map key missing
          </div>
        )}
        {/* Today's Miles overlay */}
        <div
          className="absolute top-4 left-4 rounded-2xl p-3.5 pr-4 backdrop-blur-md"
          style={{
            background: "rgba(5,7,10,0.78)",
            border: "1px solid rgba(0,229,255,0.35)",
            boxShadow: "0 0 18px rgba(0,229,255,0.25)",
          }}
        >
          <div className="flex items-center gap-2 text-white/80 text-[10px] font-mono tracking-[0.22em] uppercase">
            Today&apos;s Miles <CaretRight size={10} weight="bold" className="text-volt" />
          </div>
          <div className="chrome-text font-chrome font-bold text-[26px] leading-none mt-1 tabular-nums">
            {todaysMiles.toFixed(1)}
          </div>
          <div className="text-white/60 text-[9px] font-mono tracking-widest uppercase mt-2">Est. Deduction</div>
          <div className="text-white font-semibold text-[15px] tabular-nums">
            ${todaysDeduction.toFixed(2)}
          </div>
        </div>
      </section>

      {/* 3 · Trip History */}
      <section className="milli-card rounded-2xl p-5" data-testid="mileage-history-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[16px]">Trip History</h2>
          <button className="text-volt text-[13.5px] font-semibold active:opacity-70" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            View all
          </button>
        </div>
        <ul className="divide-y divide-white/[0.05]">
          {(trips.length ? trips.slice(0, 3) : DEMO_TRIPS).map((t, i) => (
            <TripRow key={t.id || i} trip={t} />
          ))}
        </ul>
      </section>

      {/* 4 · Monthly Summary */}
      <section className="milli-card rounded-2xl p-5" data-testid="mileage-summary-card">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-white font-semibold text-[16px]">
            {today.toLocaleString("en-US", { month: "long", year: "numeric" })} Summary
          </h2>
          <button className="text-volt text-[13.5px] font-semibold active:opacity-70" style={{ textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>
            View all
          </button>
        </div>
        <div className="grid grid-cols-4 gap-2 text-center">
          <SumCol big={totalMiles.toFixed(1)} label="Total Miles" />
          <SumCol big={`$${totalDeduction.toFixed(2)}`} label="Est. Deduction" />
          <SumCol big={trips.length} label="Trips" />
          <SumCol big={trackedTimeStr} label="Tracked Time" />
        </div>
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */

const DEMO_TRIPS = [
  { platform: "Uber",     kind: "Passenger", time: "8:42 AM", miles: 12.4, minutes: 27, deduction: 8.05 },
  { platform: "DoorDash", kind: "Delivery",  time: "7:15 AM", miles: 5.2,  minutes: 18, deduction: 3.38 },
  { platform: "Spark",    kind: "Delivery",  time: "6:30 AM", miles: 8.7,  minutes: 22, deduction: 5.69 },
];

function AutoTrackingPill({ on, onToggle }) {
  return (
    <button
      onClick={onToggle}
      data-testid="auto-tracking-pill"
      className="rounded-2xl px-3.5 py-2 flex items-center gap-2.5 active:scale-95 transition-transform flex-shrink-0"
      style={{
        background: "rgba(5,7,10,0.7)",
        border: `1px solid ${on ? "rgba(0,229,255,0.55)" : "rgba(255,255,255,0.15)"}`,
        boxShadow: on ? "0 0 16px rgba(0,229,255,0.35)" : "none",
      }}
    >
      <span className="flex items-center gap-1.5">
        <span
          className="w-1.5 h-1.5 rounded-full flex-shrink-0"
          style={{ background: on ? "#00E5FF" : "#4A5566", boxShadow: on ? "0 0 8px #00E5FF" : "none" }}
        />
        <span className="text-white text-[11.5px] font-medium whitespace-nowrap">Auto-Tracking</span>
      </span>
      <span
        className="text-[11px] font-bold tracking-wider"
        style={{
          color: on ? "#00E5FF" : "#7A8390",
          textShadow: on ? "0 0 8px rgba(0,229,255,0.5)" : "none",
        }}
      >
        {on ? "ON" : "OFF"}
      </span>
    </button>
  );
}

function LivePulse() {
  return (
    <div className="relative w-[68px] h-[68px] flex-shrink-0">
      <div
        className="absolute inset-0 rounded-full"
        style={{
          border: "2px solid #00E5FF",
          boxShadow: "0 0 22px rgba(0,229,255,0.7), inset 0 0 12px rgba(0,229,255,0.35)",
        }}
      />
      <div
        className="absolute inset-0 rounded-full animate-ping"
        style={{ border: "2px solid rgba(0,229,255,0.4)" }}
      />
      <div className="absolute inset-0 flex items-center justify-center text-volt text-[15px] font-bold tracking-wider"
           style={{ textShadow: "0 0 10px rgba(0,229,255,0.7)" }}>
        LIVE
      </div>
    </div>
  );
}

function StatCol({ label, value }) {
  return (
    <div>
      <div className="chrome-text font-chrome font-bold text-[28px] leading-none tabular-nums">{value}</div>
      <div className="text-zinc-400 text-[11px] mt-1 uppercase tracking-widest">{label}</div>
    </div>
  );
}

function TripRow({ trip }) {
  const platform = trip.platform || "Uber";
  const kind = trip.kind || (trip.category === "delivery" ? "Delivery" : "Passenger");
  const time = trip.time || (trip.date
    ? new Date(trip.date).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" })
    : "—");
  const miles = Number(trip.miles || 0);
  const minutes = Number(trip.minutes || trip.duration_minutes || 0);
  const deduction = Number(trip.deduction || miles * 0.70);
  return (
    <li className="flex items-center gap-3 py-3">
      <PlatformBadge platform={platform} />
      <div className="flex-1 min-w-0">
        <div className="text-white text-[14.5px] font-medium truncate">
          {platform} <span className="text-zinc-500 mx-0.5">•</span> {kind}
        </div>
        <div className="text-zinc-500 text-[12px]">{time}</div>
      </div>
      <div className="text-zinc-300 text-[13.5px] tabular-nums w-14 text-right">{miles.toFixed(1)} mi</div>
      <div className="text-zinc-500 text-[12.5px] tabular-nums w-12 text-right">{minutes}m</div>
      <div className="text-white font-semibold text-[14.5px] tabular-nums w-16 text-right">
        ${deduction.toFixed(2)}
      </div>
      <CaretRight size={14} weight="bold" className="text-zinc-600" />
    </li>
  );
}

function PlatformBadge({ platform }) {
  const map = {
    Uber:     { bg: "#000000", text: "#FFFFFF", label: "Uber" },
    Lyft:     { bg: "#FF00BF", text: "#FFFFFF", label: "Lyft" },
    DoorDash: { bg: "#EB1700", text: "#FFFFFF", label: "DD" },
    Spark:    { bg: "#0071DC", text: "#FFC220", label: "★" },
    Instacart:{ bg: "#43B02A", text: "#FFFFFF", label: "IC" },
  };
  const cfg = map[platform] || map.Uber;
  return (
    <div
      className="w-9 h-9 rounded-lg flex-shrink-0 flex items-center justify-center font-bold text-[11px] uppercase"
      style={{ background: cfg.bg, color: cfg.text, boxShadow: "0 4px 10px rgba(0,0,0,0.4)" }}
    >
      {cfg.label}
    </div>
  );
}

function SumCol({ big, label }) {
  return (
    <div>
      <div className="chrome-text font-chrome font-bold text-[19px] leading-tight tabular-nums">{big}</div>
      <div className="text-zinc-500 text-[10.5px] mt-1">{label}</div>
    </div>
  );
}
