/**
 * Mileage.jsx — v4.2 Hollywood Blueprint Lock
 *
 * Cinematic Mileage page matching mockup:
 * - Header: "Mileage Tracker" with Auto-Tracking toggle
 * - Hero: LIVE Tracking Trip card with pulse, miles, time, deduction
 * - Map: Dark-mode map with glowing cyan path + "Today's Miles" overlay
 * - Trip History with View All
 * - Monthly Summary grid (4 columns)
 */
import { useEffect, useRef, useState } from "react";
import { api, money, num, formatApiError } from "@/lib/api";
import { toast } from "sonner";
import { Link } from "react-router-dom";
import {
  MapTrifold, Play, Stop, Car, Timer, CurrencyDollar,
  CaretRight, Path, Clock,
} from "@phosphor-icons/react";
import { isNative, startTrip as startNativeTrip, stopTrip as stopNativeTrip } from "@/native/mileageTracker";

export default function Mileage() {
  const [active, setActive] = useState(null);
  const [trips, setTrips] = useState([]);
  const [tracking, setTracking] = useState(false);
  const [liveMiles, setLiveMiles] = useState(0);
  const [elapsed, setElapsed] = useState(0);
  const [livePoints, setLivePoints] = useState([]);
  const [autoTracking, setAutoTracking] = useState(true);
  const watchIdRef = useRef(null);
  const startTimeRef = useRef(null);
  const tickRef = useRef(null);

  async function load() {
    try {
      const [a, t] = await Promise.all([
        api.get("/trips/active"),
        api.get("/trips"),
      ]);
      setActive(a.data);
      setTrips(t.data);
      if (a.data) {
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
    if (!navigator.geolocation) { toast.error("Geolocation not supported"); return; }
    navigator.geolocation.getCurrentPosition(async (pos) => {
      try {
        const { data } = await api.post("/trips/start", {
          platform: "Auto",
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

        if (isNative()) {
          await startNativeTrip(
            (loc) => {
              const pt = [loc.latitude, loc.longitude];
              setLivePoints(prev => {
                if (prev.length) {
                  const d = hav(prev[prev.length - 1], pt);
                  if (d > 0.005) { setLiveMiles(m => m + d); return [...prev, pt]; }
                  return prev;
                }
                return [pt];
              });
            },
            (err) => toast.error("GPS error: " + err.message)
          );
        } else {
          watchIdRef.current = navigator.geolocation.watchPosition(
            (p) => {
              const pt = [p.coords.latitude, p.coords.longitude];
              setLivePoints(prev => {
                if (prev.length) {
                  const d = hav(prev[prev.length - 1], pt);
                  if (d > 0.005) { setLiveMiles(m => m + d); return [...prev, pt]; }
                  return prev;
                }
                return [pt];
              });
            },
            (err) => toast.error("GPS error: " + err.message),
            { enableHighAccuracy: true, maximumAge: 5000, timeout: 15000 }
          );
        }
        toast.success("Trip started — drive safe");
      } catch (e) { toast.error(formatApiError(e)); }
    }, (err) => toast.error("Location denied"), { enableHighAccuracy: true });
  }

  async function endTrip() {
    if (!active) return;
    if (isNative()) { try { await stopNativeTrip(); } catch (_) {} }
    if (watchIdRef.current && navigator.geolocation) navigator.geolocation.clearWatch(watchIdRef.current);
    if (tickRef.current) clearInterval(tickRef.current);
    try {
      const { data } = await api.post(`/trips/${active.id}/end`, {
        points: livePoints.map(p => ({ lat: p[0], lng: p[1] })),
        miles: liveMiles || undefined,
      });
      toast.success(`Trip saved — ${data.miles.toFixed(2)} mi`);
      setActive(null);
      setTracking(false);
      setLivePoints([]);
      setLiveMiles(0);
      setElapsed(0);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  }

  const totalMiles = trips.reduce((s, t) => s + (t.miles || 0), 0);
  const totalDed = trips.reduce((s, t) => s + (t.deductible_value || 0), 0);
  const totalTrips = trips.length;
  const totalTime = trips.reduce((s, t) => s + (t.duration_seconds || 0), 0);

  return (
    <div style={{
      padding: '24px 16px',
      maxWidth: 600,
      margin: '0 auto',
      minHeight: '100vh',
      backgroundColor: '#0D0F12',
      color: '#FFFFFF',
    }}>

      {/* ═══════════════════════════════════════
          HEADER — Mileage Tracker + Auto-Tracking Toggle
          ═══════════════════════════════════════ */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <div style={{ fontSize: 10, fontFamily: 'monospace', letterSpacing: '0.3em', textTransform: 'uppercase', color: '#00E5FF' }}>
            // Mileage
          </div>
          <h1 style={{
            fontSize: 26, fontWeight: 800, marginTop: 4,
            background: 'linear-gradient(135deg, #E8E8E8, #808080)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          }}>
            Mileage Tracker
          </h1>
        </div>

        {/* Auto-Tracking Toggle */}
        <div style={{
          background: 'rgba(13,15,18,0.6)',
          backdropFilter: 'blur(20px)',
          border: '1px solid rgba(0,229,255,0.1)',
          borderRadius: 14,
          padding: '10px 14px',
          display: 'flex', alignItems: 'center', gap: 10,
        }} data-testid="auto-tracking-toggle">
          <span style={{ fontSize: 10, fontWeight: 600, color: '#8B9DAF', letterSpacing: '0.1em' }}>Auto-Tracking</span>
          <button
            onClick={() => setAutoTracking(!autoTracking)}
            style={{
              all: 'unset', cursor: 'pointer',
              width: 40, height: 22, borderRadius: 11, position: 'relative',
              background: autoTracking ? 'rgba(0,229,255,0.3)' : 'rgba(255,255,255,0.08)',
              border: autoTracking ? '1px solid rgba(0,229,255,0.5)' : '1px solid rgba(255,255,255,0.1)',
              transition: 'all 0.2s',
            }}
          >
            <div style={{
              width: 18, height: 18, borderRadius: '50%',
              background: autoTracking ? '#00E5FF' : '#5A6573',
              position: 'absolute', top: 1, left: autoTracking ? 20 : 1,
              transition: 'all 0.2s',
              boxShadow: autoTracking ? '0 0 8px rgba(0,229,255,0.5)' : 'none',
            }}/>
          </button>
        </div>
      </div>

      {/* ═══════════════════════════════════════
          HERO — LIVE Tracking Trip / Start Trip
          ═══════════════════════════════════════ */}
      <div style={{
        background: tracking
          ? 'linear-gradient(135deg, rgba(0,229,255,0.06), rgba(13,15,18,0.7))'
          : 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: tracking ? '1px solid rgba(0,229,255,0.2)' : '1px solid rgba(0,229,255,0.08)',
        borderRadius: 24,
        padding: '28px 24px',
        marginBottom: 16,
        position: 'relative',
        overflow: 'hidden',
      }} data-testid="live-tracking-hero">
        {tracking && (
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, height: 1,
            background: 'linear-gradient(90deg, transparent, rgba(0,229,255,0.6), transparent)',
          }}/>
        )}

        {tracking ? (
          <>
            {/* Live indicator */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
              {/* Pulse icon */}
              <div style={{
                width: 40, height: 40, borderRadius: '50%',
                background: 'rgba(0,229,255,0.1)',
                border: '2px solid rgba(0,229,255,0.4)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                position: 'relative',
              }}>
                <div style={{
                  position: 'absolute', inset: -4, borderRadius: '50%',
                  border: '1px solid rgba(0,229,255,0.2)',
                  animation: 'pulse 2s infinite',
                }}/>
                <Car size={18} weight="fill" style={{ color: '#00E5FF' }}/>
              </div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: '#00E5FF', letterSpacing: '0.15em', textTransform: 'uppercase' }}>
                  LIVE Tracking Trip
                </div>
                <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
                  GPS Active · {livePoints.length} points
                </div>
              </div>
            </div>

            {/* Stats row */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginBottom: 24 }}>
              <LiveStat icon={<Path size={14} style={{ color: '#00E5FF' }}/>} label="Miles" value={num(liveMiles, 2)} accent />
              <LiveStat icon={<Timer size={14} style={{ color: '#8B9DAF' }}/>} label="Time" value={formatTime(elapsed)} />
              <LiveStat icon={<CurrencyDollar size={14} style={{ color: '#34D399' }}/>} label="Est. Deduction" value={money(liveMiles * 0.70)} />
            </div>

            {/* Stop button */}
            <button
              onClick={endTrip}
              data-testid="trip-end"
              style={{
                all: 'unset', cursor: 'pointer',
                width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
                padding: '16px 24px', borderRadius: 14,
                background: 'linear-gradient(135deg, #FF4D6A, #CC2244)',
                fontSize: 14, fontWeight: 700, color: '#FFFFFF', letterSpacing: '0.1em', textTransform: 'uppercase',
              }}
            >
              <Stop size={18} weight="fill" /> Stop Tracking
            </button>
          </>
        ) : (
          <>
            <div style={{ textAlign: 'center' }}>
              <div style={{
                width: 60, height: 60, margin: '0 auto 16px', borderRadius: '50%',
                background: 'rgba(0,229,255,0.08)', border: '1px solid rgba(0,229,255,0.2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Car size={28} weight="duotone" style={{ color: '#00E5FF' }}/>
              </div>
              <div style={{ fontSize: 18, fontWeight: 700, color: '#FFFFFF', marginBottom: 6 }}>
                Ready to track?
              </div>
              <div style={{ fontSize: 12, color: '#8B9DAF', marginBottom: 20 }}>
                Start a trip and we'll track every mile at $0.70/mi
              </div>
              <button
                onClick={startTrip}
                data-testid="trip-start"
                style={{
                  all: 'unset', cursor: 'pointer',
                  display: 'inline-flex', alignItems: 'center', gap: 10,
                  padding: '14px 32px', borderRadius: 14,
                  background: 'linear-gradient(135deg, #00E5FF, #0B7A94)',
                  fontSize: 14, fontWeight: 700, color: '#0D0F12', letterSpacing: '0.1em', textTransform: 'uppercase',
                  boxShadow: '0 0 24px rgba(0,229,255,0.3)',
                }}
              >
                <Play size={16} weight="fill" /> Start Trip
              </button>
            </div>
          </>
        )}
      </div>

      {/* ═══════════════════════════════════════
          MAP SECTION — Dark mode map with path
          ═══════════════════════════════════════ */}
      <div style={{
        borderRadius: 22,
        overflow: 'hidden',
        marginBottom: 16,
        position: 'relative',
        height: 200,
        background: '#1a1a2e',
        border: '1px solid rgba(0,229,255,0.06)',
      }} data-testid="map-section">
        {/* Simulated dark map background */}
        <div style={{
          position: 'absolute', inset: 0,
          background: `
            linear-gradient(rgba(13,15,18,0.3), rgba(13,15,18,0.3)),
            radial-gradient(circle at 30% 50%, rgba(0,229,255,0.03) 0%, transparent 50%),
            linear-gradient(180deg, #0D0F12 0%, #1a1a2e 50%, #0D0F12 100%)
          `,
        }}>
          {/* Simulated road grid */}
          <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0, opacity: 0.15 }}>
            {[0.2, 0.4, 0.6, 0.8].map(f => (
              <line key={`h${f}`} x1="0" y1={`${f * 100}%`} x2="100%" y2={`${f * 100}%`} stroke="#00E5FF" strokeWidth="0.5"/>
            ))}
            {[0.2, 0.4, 0.6, 0.8].map(f => (
              <line key={`v${f}`} x1={`${f * 100}%`} y1="0" x2={`${f * 100}%`} y2="100%" stroke="#00E5FF" strokeWidth="0.5"/>
            ))}
          </svg>
          {/* Glowing cyan trip path */}
          <svg width="100%" height="100%" viewBox="0 0 400 200" style={{ position: 'absolute', inset: 0 }}>
            <defs>
              <filter id="path-glow">
                <feGaussianBlur stdDeviation="3" result="glow"/>
                <feMerge><feMergeNode in="glow"/><feMergeNode in="SourceGraphic"/></feMerge>
              </filter>
            </defs>
            <path
              d="M 40 160 C 80 140, 120 80, 160 100 S 240 40, 300 60 S 360 80, 380 50"
              fill="none" stroke="#00E5FF" strokeWidth="3" strokeLinecap="round"
              filter="url(#path-glow)" opacity="0.9"
            />
            {/* Start/end dots */}
            <circle cx="40" cy="160" r="5" fill="#00E5FF" opacity="0.8"/>
            <circle cx="380" cy="50" r="5" fill="#34D399" opacity="0.8"/>
          </svg>
        </div>

        {/* "Today's Miles" glass overlay */}
        <div style={{
          position: 'absolute', top: 16, left: 16,
          background: 'rgba(13,15,18,0.8)',
          backdropFilter: 'blur(12px)',
          border: '1px solid rgba(0,229,255,0.15)',
          borderRadius: 12,
          padding: '10px 14px',
        }}>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#8B9DAF' }}>
            Today's Miles
          </div>
          <div style={{ fontSize: 20, fontWeight: 800, color: '#00E5FF', fontFamily: "'SF Pro Display', -apple-system, sans-serif" }}>
            {num(tracking ? liveMiles : (trips.length > 0 ? trips[0].miles || 0 : 0), 1)} mi
          </div>
        </div>
      </div>

      {/* ═══════════════════════════════════════
          TRIP HISTORY
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.06)',
        borderRadius: 22,
        overflow: 'hidden',
        marginBottom: 16,
      }} data-testid="trip-history">
        <div style={{
          padding: '16px 20px',
          borderBottom: '1px solid rgba(255,255,255,0.03)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF' }}>
            Trip History
          </span>
          <Link to="/app/mileage" style={{
            fontSize: 10, color: '#5A6573', fontFamily: 'monospace',
            textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 4,
          }}>
            View All <CaretRight size={10} weight="bold"/>
          </Link>
        </div>
        {trips.length === 0 ? (
          <div style={{ padding: '32px 20px', textAlign: 'center', color: '#5A6573', fontSize: 13 }}>
            No trips yet — start tracking to see history.
          </div>
        ) : (
          trips.slice(0, 5).map((t, i) => (
            <div key={t.id || i} style={{
              display: 'flex', alignItems: 'center', padding: '14px 20px', gap: 12,
              borderBottom: i < Math.min(trips.length, 5) - 1 ? '1px solid rgba(255,255,255,0.03)' : 'none',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: 'rgba(0,229,255,0.06)', border: '1px solid rgba(0,229,255,0.12)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <Car size={16} weight="duotone" style={{ color: '#00E5FF' }}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#FFFFFF' }}>{t.platform || "Trip"}</div>
                <div style={{ fontSize: 10, color: '#5A6573', fontFamily: 'monospace' }}>
                  {(t.start_time || "").slice(0, 10)}
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 13, fontWeight: 700, color: '#FFFFFF', fontFamily: 'monospace' }}>
                  {num(t.miles, 1)} mi
                </div>
                <div style={{ fontSize: 10, color: '#34D399', fontFamily: 'monospace' }}>
                  +{money(t.deductible_value || t.miles * 0.70)}
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* ═══════════════════════════════════════
          MONTHLY SUMMARY GRID
          ═══════════════════════════════════════ */}
      <div style={{
        background: 'rgba(13,15,18,0.5)',
        backdropFilter: 'blur(28px)',
        border: '1px solid rgba(0,229,255,0.06)',
        borderRadius: 22,
        padding: '20px',
        marginBottom: 32,
      }} data-testid="monthly-summary">
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.2em', textTransform: 'uppercase', color: '#00E5FF', marginBottom: 16 }}>
          July 2026 Summary
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 10 }}>
          <SummaryCell label="Total Miles" value={num(totalMiles, 0)} color="#00E5FF" />
          <SummaryCell label="Est. Deduction" value={money(totalDed)} color="#34D399" />
          <SummaryCell label="Trips" value={totalTrips} color="#FFB800" />
          <SummaryCell label="Tracked Time" value={formatTimeShort(totalTime)} color="#C084FC" />
        </div>
      </div>

      {/* Floating AI Sphere */}
      <FloatingAISphere />

      {/* Pulse animation CSS */}
      <style>{`
        @keyframes pulse {
          0% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.4); opacity: 0; }
          100% { transform: scale(1); opacity: 0; }
        }
      `}</style>
    </div>
  );
}

/* ─── Sub-components ─── */

function LiveStat({ icon, label, value, accent }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 4 }}>{icon}</div>
      <div style={{
        fontSize: 18, fontWeight: 800,
        color: accent ? '#00E5FF' : '#FFFFFF',
        fontFamily: "'SF Pro Display', -apple-system, sans-serif",
        marginBottom: 2,
      }}>
        {value}
      </div>
      <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#5A6573' }}>
        {label}
      </div>
    </div>
  );
}

function SummaryCell({ label, value, color }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{
        fontSize: 18, fontWeight: 800, color: color,
        fontFamily: "'SF Pro Display', -apple-system, sans-serif",
        marginBottom: 4,
      }}>
        {value}
      </div>
      <div style={{ fontSize: 8, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: '#5A6573' }}>
        {label}
      </div>
    </div>
  );
}

function formatTime(s) {
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
}

function formatTimeShort(s) {
  if (!s) return "0h";
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

function FloatingAISphere() {
  return (
    <div style={{
      position: 'fixed',
      bottom: 90,
      right: 20,
      width: 56,
      height: 56,
      borderRadius: '50%',
      overflow: 'hidden',
      boxShadow: '0 0 30px rgba(0,229,255,0.3), 0 0 60px rgba(0,229,255,0.1)',
      border: '2px solid rgba(0,229,255,0.3)',
      zIndex: 100,
      cursor: 'pointer',
    }} data-testid="floating-ai-sphere">
      <img
        src="/weebo/milli-ai-sphere.png"
        alt="Milli AI"
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
      />
    </div>
  );
}
