/**
 * Animated perspective road — pure CSS, no framer-motion.
 * Lane dashes scroll from the vanishing point toward the viewer,
 * scaling up + brightening to create the illusion of driving forward.
 * Used on Login + Register right panels.
 */
import MilliLogo from "@/components/MilliLogo";

const DASH_COUNT = 18;

export default function RoadScene({ tagline = "Every mile is a deduction" }) {
  return (
    <div className="absolute inset-0 overflow-hidden" data-testid="road-scene">
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

      {/* Distant city lights (small twinkling dots near horizon) */}
      {Array.from({ length: 20 }).map((_, i) => (
        <span
          key={`city-${i}`}
          className="absolute rounded-full"
          style={{
            top: `${55 + Math.random() * 3}%`,
            left: `${10 + Math.random() * 80}%`,
            width: 1.5,
            height: 1.5,
            background: i % 3 === 0 ? "#13D8D1" : "#D9E0E4",
            boxShadow: "0 0 4px currentColor",
            opacity: 0.4 + Math.random() * 0.6,
            animation: `twinkle ${1.4 + Math.random() * 2}s ease-in-out ${Math.random() * 2}s infinite`,
          }}
        />
      ))}

      {/* Road plane — trapezoid */}
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
        {/* Road surface */}
        <polygon points="48,58 52,58 95,100 5,100" fill="url(#road-grad)" />
        {/* Left edge line */}
        <line x1="48" y1="58" x2="5" y2="100" stroke="url(#edge-grad)" strokeWidth="0.3" />
        {/* Right edge line */}
        <line x1="52" y1="58" x2="95" y2="100" stroke="url(#edge-grad)" strokeWidth="0.3" />
        {/* Center line (faint) */}
        <line x1="50" y1="58" x2="50" y2="100" stroke="rgba(217,224,228,0.06)" strokeWidth="0.15" strokeDasharray="0.6 1" />
      </svg>

      {/* Animated lane dashes scrolling toward viewer */}
      <div className="absolute left-1/2 top-[58%] bottom-0 -translate-x-1/2" style={{ width: "60%" }}>
        {Array.from({ length: DASH_COUNT }).map((_, i) => (
          <div
            key={`dash-${i}`}
            className="absolute left-1/2 -translate-x-1/2 milli-road-dash"
            style={{ animationDelay: `${(i * 2.4) / DASH_COUNT}s` }}
          />
        ))}
      </div>

      {/* Guard rail dots */}
      <div className="absolute left-0 right-0 top-[58%] bottom-0">
        {Array.from({ length: 14 }).map((_, i) => (
          <div
            key={`rail-l-${i}`}
            className="absolute milli-rail milli-rail-l"
            style={{ animationDelay: `${(i * 2.0) / 14}s` }}
          />
        ))}
        {Array.from({ length: 14 }).map((_, i) => (
          <div
            key={`rail-r-${i}`}
            className="absolute milli-rail milli-rail-r"
            style={{ animationDelay: `${(i * 2.0) / 14}s` }}
          />
        ))}
      </div>

      {/* Floating dust motes (drift up) */}
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

      {/* Foreground content (MILLI mark + tagline) */}
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

      {/* All animations */}
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
      `}</style>
    </div>
  );
}
