/**
 * Animated perspective road — pure CSS, tap-to-pulse acceleration.
 * Lane dashes scroll from the vanishing point toward the viewer.
 * Tap anywhere → speed-streak burst + cyan flash + 20ms haptic pulse.
 */
import { useState, useRef } from "react";
import MilliLogo from "@/components/MilliLogo";

const DASH_COUNT = 18;
const STREAK_COUNT = 9;

export default function RoadScene({ tagline = "Every mile is a deduction", showLogo = true }) {
  const [pulses, setPulses] = useState([]);
  const idRef = useRef(0);

  const onTap = () => {
    const id = ++idRef.current;
    setPulses((p) => [...p, id]);
    if (typeof navigator !== "undefined" && navigator.vibrate) {
      try { navigator.vibrate(20); } catch {}
    }
    setTimeout(() => setPulses((p) => p.filter((x) => x !== id)), 900);
  };

  return (
    <div
      className="absolute inset-0 overflow-hidden cursor-pointer select-none"
      data-testid="road-scene"
      onClick={onTap}
      onTouchStart={onTap}
    >
      {/* Sky / horizon gradient */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(180deg, #050607 0%, #050607 40%, #06141a 60%, #082a32 78%, #0a3b46 90%, #062d36 100%)",
        }}
      />

      {/* Horizon glow */}
      <div
        className="absolute left-0 right-0"
        style={{
          top: "55%",
          height: "120px",
          background:
            "radial-gradient(ellipse 60% 100% at 50% 0%, rgba(19, 216, 209, 0.45), transparent 70%)",
          filter: "blur(8px)",
        }}
      />

      {/* Distant city lights */}
      {Array.from({ length: 20 }).map((_, i) => (
        <span
          key={`city-${i}`}
          className="absolute rounded-full"
          style={{
            top: `${55 + Math.random() * 3}%`,
            left: `${10 + Math.random() * 80}%`,
            width: 1.5, height: 1.5,
            background: i % 3 === 0 ? "#13D8D1" : "#D9E0E4",
            boxShadow: "0 0 4px currentColor",
            opacity: 0.4 + Math.random() * 0.6,
            animation: `twinkle ${1.4 + Math.random() * 2}s ease-in-out ${Math.random() * 2}s infinite`,
          }}
        />
      ))}

      {/* Road plane */}
      <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
        <defs>
          <linearGradient id="road-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#06141a" />
            <stop offset="100%" stopColor="#0a1218" />
          </linearGradient>
          <linearGradient id="edge-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="rgba(19,216,209,0.0)" />
            <stop offset="100%" stopColor="rgba(19,216,209,0.9)" />
          </linearGradient>
        </defs>
        <polygon points="48,58 52,58 95,100 5,100" fill="url(#road-grad)" />
        <line x1="48" y1="58" x2="5" y2="100" stroke="url(#edge-grad)" strokeWidth="0.3" />
        <line x1="52" y1="58" x2="95" y2="100" stroke="url(#edge-grad)" strokeWidth="0.3" />
        <line x1="50" y1="58" x2="50" y2="100" stroke="rgba(217,224,228,0.06)" strokeWidth="0.15" strokeDasharray="0.6 1" />
      </svg>

      {/* Lane dashes */}
      <div className="absolute left-1/2 top-[58%] bottom-0 -translate-x-1/2" style={{ width: "60%" }}>
        {Array.from({ length: DASH_COUNT }).map((_, i) => (
          <div
            key={`dash-${i}`}
            className="absolute left-1/2 -translate-x-1/2 milli-road-dash"
            style={{ animationDelay: `${(i * 2.4) / DASH_COUNT}s` }}
          />
        ))}
      </div>

      {/* Guard rails */}
      <div className="absolute left-0 right-0 top-[58%] bottom-0">
        {Array.from({ length: 14 }).map((_, i) => (
          <div key={`rail-l-${i}`} className="absolute milli-rail milli-rail-l" style={{ animationDelay: `${(i * 2.0) / 14}s` }} />
        ))}
        {Array.from({ length: 14 }).map((_, i) => (
          <div key={`rail-r-${i}`} className="absolute milli-rail milli-rail-r" style={{ animationDelay: `${(i * 2.0) / 14}s` }} />
        ))}
      </div>

      {/* Dust motes */}
      {Array.from({ length: 14 }).map((_, i) => (
        <div
          key={`dust-${i}`}
          className="absolute rounded-full"
          style={{
            left: `${5 + Math.random() * 90}%`,
            bottom: 0,
            width: 1 + Math.random() * 1.5,
            height: 1 + Math.random() * 1.5,
            background: "rgba(19, 216, 209, 0.6)",
            boxShadow: "0 0 6px rgba(19,216,209,0.6)",
            animation: `dust-rise ${4 + Math.random() * 4}s linear ${Math.random() * 3}s infinite`,
          }}
        />
      ))}

      {/* TAP BURST overlays — one-shot per tap */}
      {pulses.map((id) => (
        <div key={id} className="absolute inset-0 pointer-events-none" data-testid="road-tap-burst">
          {/* Cyan radial flash from horizon */}
          <div className="absolute inset-0 milli-boost-flash" />
          {/* Speed streaks radiating from horizon */}
          {Array.from({ length: STREAK_COUNT }).map((_, i) => {
            const angle = (i / STREAK_COUNT) * 360;
            const offset = ((i * 137) % 60) - 30; // pseudo-random horizontal
            return (
              <div
                key={i}
                className="absolute milli-streak"
                style={{
                  left: `${50 + offset}%`,
                  top: "58%",
                  transform: `rotate(${angle}deg)`,
                  animationDelay: `${i * 25}ms`,
                }}
              />
            );
          })}
          {/* Horizon spotlight burst */}
          <div className="absolute left-1/2 top-[58%] -translate-x-1/2 -translate-y-1/2 milli-burst-ring" />
        </div>
      ))}

      {/* Foreground content */}
      {showLogo && (
        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none px-6">
          <div className="mb-3 sm:mb-6 scale-75 sm:scale-100"><MilliLogo size={140} /></div>
          <div className="font-display chrome-text text-3xl sm:text-5xl tracking-[0.35em] text-center">MILLI</div>
          <div className="mt-3 sm:mt-4 h-px w-24 sm:w-32" style={{
            background: "linear-gradient(90deg, transparent, #13D8D1, transparent)",
            boxShadow: "0 0 12px #13D8D1",
          }} />
          <div className="mt-3 sm:mt-4 text-volt text-[10px] sm:text-[11px] font-mono uppercase tracking-[0.3em] sm:tracking-[0.4em] text-center px-2">
            // {tagline}
          </div>
        </div>
      )}

      {/* Subtle "tap to pulse" hint — only when no recent pulse */}
      {pulses.length === 0 && (
        <div className="absolute bottom-3 left-1/2 -translate-x-1/2 text-[9px] uppercase tracking-[0.3em] text-zinc-600 font-mono pointer-events-none opacity-60">
          tap to rev
        </div>
      )}

      <style>{`
        @keyframes road-dash-scroll {
          0%   { top: 0%;  transform: translate(-50%, 0) scale(0.12); opacity: 0;   width: 1.2px; height: 4px; background: rgba(217,224,228,0.0); }
          15%  { opacity: 0.4; background: rgba(217,224,228,0.7); }
          70%  { opacity: 1; }
          100% { top: 100%; transform: translate(-50%, 0) scale(2.2); opacity: 0;   width: 4px;   height: 22px; background: #13D8D1; box-shadow: 0 0 18px #13D8D1; }
        }
        .milli-road-dash {
          width: 1.2px; height: 4px;
          background: rgba(217,224,228,0.6);
          border-radius: 2px;
          top: 0%;
          animation: road-dash-scroll 2.4s linear infinite;
          will-change: transform, top, opacity, width, height;
        }

        @keyframes rail-scroll-l {
          0%   { top: 0%;  left: 50%; transform: translate(-50%, 0) scale(0.1); opacity: 0; }
          12%  { opacity: 0.6; }
          100% { top: 100%; left: 5%; transform: translate(-50%, 0) scale(1.6); opacity: 0; }
        }
        @keyframes rail-scroll-r {
          0%   { top: 0%;  left: 50%; transform: translate(-50%, 0) scale(0.1); opacity: 0; }
          12%  { opacity: 0.6; }
          100% { top: 100%; left: 95%; transform: translate(-50%, 0) scale(1.6); opacity: 0; }
        }
        .milli-rail {
          width: 3px; height: 3px;
          background: #13D8D1;
          border-radius: 50%;
          box-shadow: 0 0 8px #13D8D1;
          will-change: top, left, transform, opacity;
        }
        .milli-rail-l { animation: rail-scroll-l 2.0s linear infinite; }
        .milli-rail-r { animation: rail-scroll-r 2.0s linear infinite; }

        @keyframes dust-rise {
          0%   { transform: translateY(0) scale(1); opacity: 0; }
          15%  { opacity: 0.7; }
          100% { transform: translateY(-90vh) scale(0.4); opacity: 0; }
        }

        @keyframes twinkle {
          0%, 100% { opacity: 0.3; }
          50%      { opacity: 1; }
        }

        /* Tap-to-pulse boost */
        @keyframes boost-flash {
          0%   { background: radial-gradient(ellipse 20% 14% at 50% 58%, rgba(19,216,209,0), transparent 70%); }
          15%  { background: radial-gradient(ellipse 70% 50% at 50% 65%, rgba(19,216,209,0.55), transparent 70%); }
          100% { background: radial-gradient(ellipse 220% 220% at 50% 115%, rgba(19,216,209,0), transparent 70%); }
        }
        .milli-boost-flash { animation: boost-flash 850ms cubic-bezier(0.16, 1, 0.3, 1) forwards; }

        @keyframes streak-fire {
          0%   { width: 1px; height: 1px; opacity: 0; box-shadow: 0 0 0 #13D8D1; transform-origin: 0 50%; }
          25%  { opacity: 1; }
          100% { width: 240px; height: 1.5px; opacity: 0; box-shadow: 0 0 16px #13D8D1; }
        }
        .milli-streak {
          background: linear-gradient(90deg, #13D8D1, transparent);
          border-radius: 9999px;
          animation: streak-fire 700ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
          will-change: width, opacity;
        }

        @keyframes burst-ring {
          0%   { width: 0; height: 0; opacity: 0.9; border-width: 2px; }
          50%  { opacity: 0.7; border-width: 1px; }
          100% { width: 360px; height: 360px; opacity: 0; border-width: 0.5px; }
        }
        .milli-burst-ring {
          border-radius: 9999px;
          border: 2px solid #13D8D1;
          box-shadow: 0 0 24px #13D8D1, inset 0 0 24px rgba(19,216,209,0.4);
          animation: burst-ring 850ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
          will-change: width, height, opacity;
        }
      `}</style>
    </div>
  );
}
