import { useEffect, useRef, useState } from "react";
import { api, formatApiError } from "@/lib/api";
import { toast } from "sonner";
import { CaretRight, Stop, Play } from "@phosphor-icons/react";
import MilliLogo from "@/components/MilliLogo";

/**
 * Milli Mileage Tracker — WWDC cinematic quality.
 * Structure:
 *   Header + Auto-Tracking pill
 *   LIVE Tracking Trip card (cyan halo, big stats + Stop)
 *   Google Map with cyan-glow route + "Today's Miles" overlay
 *   Trip History list
 *   Monthly Summary card
 */

const PAGE_STYLE = { padding: "16px 24px calc(var(--safe-bottom, 34px) + 32px) 24px", fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif', maxWidth: 640, margin: "0 auto" };
const SURFACE = { background: "linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 20, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 4px 24px rgba(0,0,0,0.3)" };
const HERO_TEAL = { background: "linear-gradient(135deg, rgba(0,180,200,0.22), rgba(0,229,255,0.07) 45%, rgba(5,6,7,0.9))", border: "1.5px solid rgba(0,229,255,0.7)", borderRadius: 24, boxShadow: "0 0 34px rgba(0,229,255,0.35), inset 0 1px 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.4)" };

const GMAPS_KEY = process.env.REACT_APP_GOOGLE_MAPS_KEY;

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

const DEMO_ROUTE = [
  { lat: 34.0587, lng: -118.4210 }, { lat: 34.0680, lng: -118.4020 },
  { lat: 34.0790, lng: -118.3800 }, { lat: 34.0870, lng: -118.3600 },
  { lat: 34.0910, lng: -118.3400 }, { lat: 34.0870, lng: -118.3200 },
  { lat: 34.0770, lng: -118.3050 }, { lat: 34.0670, lng: -118.2900 },
];

const DEMO_TRIPS = [
  { platform: "Uber", kind: "Passenger", time: "8:42 AM", miles: 12.4, minutes: 27, deduction: 8.05 },
  { platform: "DoorDash", kind: "Delivery", time: "7:15 AM", miles: 5.2, minutes: 18, deduction: 3.38 },
  { platform: "Spark", kind: "Delivery", time: "6:30 AM", miles: 8.7, minutes: 22, deduction: 5.69 },
];

export default function Mileage() {
  const [active, setActive] = useState(null);
  const [trips, setTrips] = useState([]);
  const [autoTracking, setAutoTracking] = useState(true);
  const mapDivRef = useRef(null);

  async function load() {
    try {
      const [a, t] = await Promise.all([api.get("/trips/active"), api.get("/trips")]);
      setActive(a.data); setTrips(t.data || []);
    } catch (err) { toast.error(formatApiError(err)); }
  }
  useEffect(() => { load(); }, []);

  useEffect(() => {
    if (!mapDivRef.current || !GMAPS_KEY) return;
    let poly;
    loadGoogleMaps().then((google) => {
      const map = new google.maps.Map(mapDivRef.current, {
        center: { lat: 34.078, lng: -118.36 }, zoom: 12, disableDefaultUI: true,
        gestureHandling: "greedy", backgroundColor: "#05070A", styles: MAP_STYLE,
      });
      poly = new google.maps.Polyline({ path: DEMO_ROUTE, strokeColor: "#00E5FF", strokeOpacity: 1, strokeWeight: 4, map });
      new google.maps.Polyline({ path: DEMO_ROUTE, strokeColor: "#00E5FF", strokeOpacity: 0.25, strokeWeight: 12, map });
      new google.maps.Marker({ position: DEMO_ROUTE[0], map, icon: { path: google.maps.SymbolPath.CIRCLE, scale: 10, fillColor: "#00E5FF", fillOpacity: 1, strokeColor: "#FFFFFF", strokeWeight: 2 } });
      new google.maps.Marker({ position: DEMO_ROUTE[DEMO_ROUTE.length - 1], map, icon: { path: google.maps.SymbolPath.CIRCLE, scale: 8, fillColor: "#00E5FF", fillOpacity: 1, strokeColor: "#0A0C10", strokeWeight: 2 } });
    }).catch(() => {});
    return () => { poly?.setMap?.(null); };
  }, []);

  const totalMiles = trips.reduce((a, t) => a + Number(t.miles || 0), 0);
  const totalDeduction = totalMiles * 0.70;
  const trackedMinutes = trips.reduce((a, t) => a + Number(t.duration_minutes || 0), 0);
  const trackedTimeStr = `${Math.floor(trackedMinutes / 60)}h ${trackedMinutes % 60}m`;

  const today = new Date();
  const todaysTrips = trips.filter(t => { const d = new Date(t.date || t.created_at || 0); return d.toDateString() === today.toDateString(); });
  const todaysMiles = todaysTrips.reduce((a, t) => a + Number(t.miles || 0), 0) || 45.7;
  const todaysDeduction = todaysMiles * 0.70;

  const liveMiles = Number(active?.miles || 12.4);
  const liveMinutes = Number(active?.duration_minutes || 27);
  const liveDeduction = liveMiles * 0.70;
  const livePlatform = active?.platform || "Uber";

  return (
    <div style={PAGE_STYLE}>
      {/* Header */}
      <header style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12 }}>
        <div>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: "#FFFFFF", letterSpacing: "-0.035em", margin: 0 }}>Mileage Tracker</h1>
          <p style={{ color: "#9CA3AF", fontSize: 15, marginTop: 4 }}>Track. Save. Deduct.</p>
        </div>
        <AutoTrackingPill on={autoTracking} onToggle={() => setAutoTracking(v => !v)} />
      </header>

      <div style={{ height: 20 }} />

      {/* LIVE Tracking Trip Card */}
      <section style={{ ...HERO_TEAL, padding: "24px" }} data-testid="mileage-tracking-card">
        <div style={{ display: "flex", alignItems: "center", gap: 14, marginBottom: 16 }}>
          <LivePulse />
          <div>
            <div style={{ fontSize: 22, fontWeight: 700, color: "#fff", letterSpacing: "-0.02em" }}>Tracking Trip</div>
            <div style={{ color: "#00E5FF", fontSize: 14, fontWeight: 500, textShadow: "0 0 8px rgba(0,229,255,0.5)" }}>
              {livePlatform} <span style={{ color: "rgba(255,255,255,0.3)" }}>·</span> Passenger
            </div>
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 20, textAlign: "center" }}>
          <StatCol label="Miles" value={liveMiles.toFixed(1)} />
          <StatCol label="Time" value={`${liveMinutes}m`} />
          <StatCol label="Est. Deduction" value={`$${liveDeduction.toFixed(2)}`} />
        </div>
        <button
          data-testid="stop-tracking-btn"
          onClick={() => toast.info("Trip stopped (demo)")}
          style={{ width: "100%", borderRadius: 16, padding: "14px 0", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, fontWeight: 700, fontSize: 15, color: "#000", background: "linear-gradient(180deg, #00E5FF, #00B4D0)", boxShadow: "inset 0 1px 0 rgba(255,255,255,0.5), 0 0 24px rgba(0,229,255,0.55), 0 10px 24px rgba(0,229,255,0.3)", border: "none", cursor: "pointer" }}
        >
          <Stop size={16} weight="fill" /> Stop Tracking
        </button>
      </section>

      <div style={{ height: 16 }} />

      {/* Map + Today's Miles overlay */}
      <section data-testid="mileage-map-card" style={{ position: "relative", borderRadius: 24, overflow: "hidden", height: 240, border: "1px solid rgba(0,229,255,0.22)", boxShadow: "0 0 24px rgba(0,229,255,0.18), 0 18px 40px rgba(0,0,0,0.55)" }}>
        <div ref={mapDivRef} style={{ position: "absolute", inset: 0, background: "#05070A" }} />
        {!GMAPS_KEY && <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", color: "#4B5563", fontSize: 13 }}>Map key missing</div>}
        <div style={{ position: "absolute", top: 16, left: 16, borderRadius: 16, padding: "14px 16px", background: "rgba(5,7,10,0.78)", border: "1px solid rgba(0,229,255,0.35)", boxShadow: "0 0 18px rgba(0,229,255,0.25)", backdropFilter: "blur(12px)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 4, color: "rgba(255,255,255,0.6)", fontSize: 10, fontWeight: 600, letterSpacing: "0.18em", textTransform: "uppercase" }}>
            Today's Miles <CaretRight size={10} weight="bold" color="#00E5FF" />
          </div>
          <div style={{ fontSize: 26, fontWeight: 800, color: "#fff", marginTop: 4, fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em" }}>{todaysMiles.toFixed(1)}</div>
          <div style={{ color: "rgba(255,255,255,0.5)", fontSize: 9, fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase", marginTop: 6 }}>Est. Deduction</div>
          <div style={{ color: "#fff", fontWeight: 600, fontSize: 15, fontVariantNumeric: "tabular-nums" }}>${todaysDeduction.toFixed(2)}</div>
        </div>
      </section>

      <div style={{ height: 16 }} />

      {/* Trip History */}
      <section style={SURFACE} data-testid="mileage-history-card">
        <div style={{ padding: "16px 20px", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
          <h2 style={{ fontSize: 17, fontWeight: 600, color: "#fff", margin: 0 }}>Trip History</h2>
          <button style={{ color: "#00E5FF", fontSize: 13, fontWeight: 600, background: "none", border: "none", cursor: "pointer", textShadow: "0 0 8px rgba(0,229,255,0.4)" }}>View all</button>
        </div>
        <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
          {(trips.length ? trips.slice(0, 4) : DEMO_TRIPS).map((t, i, arr) => (
            <TripRow key={t.id || i} trip={t} last={i === arr.length - 1} />
          ))}
        </ul>
      </section>

      <div style={{ height: 16 }} />

      {/* Monthly Summary */}
      <section style={SURFACE} data-testid="mileage-summary-card">
        <div style={{ padding: "16px 20px", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
          <h2 style={{ fontSize: 17, fontWeight: 600, color: "#fff", margin: 0 }}>{today.toLocaleString("en-US", { month: "long", year: "numeric" })} Summary</h2>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr", gap: 8, padding: "16px 20px", textAlign: "center" }}>
          <SumCol big={totalMiles.toFixed(1)} label="Total Miles" />
          <SumCol big={`$${totalDeduction.toFixed(0)}`} label="Deduction" />
          <SumCol big={String(trips.length)} label="Trips" />
          <SumCol big={trackedTimeStr} label="Tracked" />
        </div>
      </section>
    </div>
  );
}

/* ============ Sub-components ============ */

function AutoTrackingPill({ on, onToggle }) {
  return (
    <button onClick={onToggle} data-testid="auto-tracking-pill" style={{ borderRadius: 16, padding: "8px 14px", display: "flex", alignItems: "center", gap: 8, flexShrink: 0, background: "rgba(5,7,10,0.7)", border: `1px solid ${on ? "rgba(0,229,255,0.55)" : "rgba(255,255,255,0.15)"}`, boxShadow: on ? "0 0 16px rgba(0,229,255,0.35)" : "none", cursor: "pointer" }}>
      <span style={{ width: 6, height: 6, borderRadius: "50%", background: on ? "#00E5FF" : "#4A5566", boxShadow: on ? "0 0 8px #00E5FF" : "none" }} />
      <span style={{ color: "#fff", fontSize: 11.5, fontWeight: 500 }}>Auto-Tracking</span>
      <span style={{ color: on ? "#00E5FF" : "#7A8390", fontSize: 11, fontWeight: 700, letterSpacing: "0.08em", textShadow: on ? "0 0 8px rgba(0,229,255,0.5)" : "none" }}>{on ? "ON" : "OFF"}</span>
    </button>
  );
}

function LivePulse() {
  return (
    <div style={{ position: "relative", width: 60, height: 60, flexShrink: 0 }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", border: "2px solid #00E5FF", boxShadow: "0 0 22px rgba(0,229,255,0.7), inset 0 0 12px rgba(0,229,255,0.35)" }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", border: "2px solid rgba(0,229,255,0.4)", animation: "milli-breathe 2s ease-in-out infinite" }} />
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", color: "#00E5FF", fontSize: 13, fontWeight: 700, letterSpacing: "0.12em", textShadow: "0 0 10px rgba(0,229,255,0.7)" }}>LIVE</div>
    </div>
  );
}

function StatCol({ label, value }) {
  return (
    <div>
      <div style={{ fontSize: 26, fontWeight: 800, color: "#fff", fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em" }}>{value}</div>
      <div style={{ color: "#9CA3AF", fontSize: 10, marginTop: 4, textTransform: "uppercase", letterSpacing: "0.14em" }}>{label}</div>
    </div>
  );
}

function TripRow({ trip, last }) {
  const platform = trip.platform || "Uber";
  const kind = trip.kind || "Passenger";
  const time = trip.time || (trip.date ? new Date(trip.date).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" }) : "—");
  const miles = Number(trip.miles || 0);
  const minutes = Number(trip.minutes || trip.duration_minutes || 0);
  const deduction = Number(trip.deduction || miles * 0.70);

  return (
    <li style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 20px", borderBottom: last ? "none" : "1px solid rgba(255,255,255,0.05)" }}>
      <PlatformBadge platform={platform} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "#fff", fontSize: 14, fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{platform} <span style={{ color: "#4B5563" }}>·</span> {kind}</div>
        <div style={{ color: "#4B5563", fontSize: 11 }}>{time}</div>
      </div>
      <div style={{ color: "#D1D5DB", fontSize: 13, fontVariantNumeric: "tabular-nums", width: 52, textAlign: "right" }}>{miles.toFixed(1)} mi</div>
      <div style={{ color: "#6B7280", fontSize: 12, fontVariantNumeric: "tabular-nums", width: 36, textAlign: "right" }}>{minutes}m</div>
      <div style={{ color: "#fff", fontWeight: 700, fontSize: 14, fontVariantNumeric: "tabular-nums", width: 56, textAlign: "right" }}>${deduction.toFixed(2)}</div>
      <CaretRight size={13} weight="bold" color="#4B5563" style={{ flexShrink: 0 }} />
    </li>
  );
}

function PlatformBadge({ platform }) {
  const map = { Uber: { bg: "#000", fg: "#fff", l: "U" }, Lyft: { bg: "#FF00BF", fg: "#fff", l: "L" }, DoorDash: { bg: "#EB1700", fg: "#fff", l: "DD" }, Spark: { bg: "#0071DC", fg: "#FFC220", l: "★" }, Instacart: { bg: "#43B02A", fg: "#fff", l: "IC" } };
  const cfg = map[platform] || { bg: "#1a1e24", fg: "#fff", l: platform?.[0] || "$" };
  return (
    <div style={{ width: 36, height: 36, borderRadius: 10, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 11, background: cfg.bg, color: cfg.fg, boxShadow: "0 4px 8px rgba(0,0,0,0.35)" }}>{cfg.l}</div>
  );
}

function SumCol({ big, label }) {
  return (
    <div>
      <div style={{ fontSize: 18, fontWeight: 800, color: "#fff", fontVariantNumeric: "tabular-nums" }}>{big}</div>
      <div style={{ color: "#6B7280", fontSize: 10, marginTop: 4, letterSpacing: "0.08em" }}>{label}</div>
    </div>
  );
}
