/**
 * ChromeBonsai — high-craft, photoreal-style chrome/silver bonsai tree.
 * Replaces the cartoonish "glowing tree" on the Retirement page.
 *
 * Design notes:
 *   ▸ chrome/silver gradients with subtle cyan under-lighting
 *   ▸ hand-shaped trunk & branches (bezier paths, not blob circles)
 *   ▸ layered leaf clusters rendered as dense specks
 *   ▸ polished chrome pedestal with embossed "M"
 *   ▸ soft neon-cyan floor glow so it sits on the retirement hero
 *
 * Size is fluid — pass `size` (default 220) to scale the whole illustration.
 */
export default function ChromeBonsai({ size = 220 }) {
  return (
    <div
      className="relative flex items-end justify-center"
      style={{
        width: size,
        height: size,
        filter: "drop-shadow(0 0 22px rgba(0,229,255,0.28))",
      }}
    >
      {/* Cyan floor glow */}
      <div
        className="absolute pointer-events-none"
        style={{
          bottom: size * 0.06,
          left: "50%",
          width: size * 0.9,
          height: size * 0.18,
          transform: "translateX(-50%)",
          background:
            "radial-gradient(ellipse at 50% 50%, rgba(0,229,255,0.55) 0%, rgba(0,229,255,0.25) 30%, rgba(0,229,255,0) 70%)",
          filter: "blur(6px)",
        }}
      />

      <svg
        viewBox="0 0 220 220"
        width={size}
        height={size}
        preserveAspectRatio="xMidYMax meet"
      >
        <defs>
          {/* Chrome for trunk / branches */}
          <linearGradient id="cb-trunk" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="#3C4046" />
            <stop offset="18%" stopColor="#9AA0A7" />
            <stop offset="42%" stopColor="#F1F3F5" />
            <stop offset="55%" stopColor="#C4C8CE" />
            <stop offset="78%" stopColor="#5A5E64" />
            <stop offset="100%" stopColor="#1E2126" />
          </linearGradient>
          <linearGradient id="cb-branch" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="#2A2D32" />
            <stop offset="35%" stopColor="#C0C5CB" />
            <stop offset="55%" stopColor="#EEF0F3" />
            <stop offset="75%" stopColor="#7C8087" />
            <stop offset="100%" stopColor="#1E2126" />
          </linearGradient>

          {/* Foliage — chrome speckled with cyan rim-light */}
          <radialGradient id="cb-crown" cx="50%" cy="35%" r="70%">
            <stop offset="0%" stopColor="#F4F7FA" stopOpacity="1" />
            <stop offset="35%" stopColor="#B7BCC3" stopOpacity="0.95" />
            <stop offset="70%" stopColor="#3E4247" stopOpacity="0.9" />
            <stop offset="100%" stopColor="#0D0F13" stopOpacity="0.95" />
          </radialGradient>
          <radialGradient id="cb-crown-rim" cx="50%" cy="50%" r="55%">
            <stop offset="70%" stopColor="rgba(0,229,255,0)" />
            <stop offset="88%" stopColor="rgba(0,229,255,0.35)" />
            <stop offset="100%" stopColor="rgba(0,229,255,0)" />
          </radialGradient>

          {/* Pedestal chrome */}
          <radialGradient id="cb-pedestal" cx="50%" cy="30%" r="70%">
            <stop offset="0%" stopColor="#FAFCFE" />
            <stop offset="30%" stopColor="#C7CBD1" />
            <stop offset="70%" stopColor="#585C62" />
            <stop offset="100%" stopColor="#0E1114" />
          </radialGradient>
          <linearGradient id="cb-pedestal-ring" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#EEF0F3" />
            <stop offset="100%" stopColor="#3A3D42" />
          </linearGradient>
          <linearGradient id="cb-M" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#FFFFFF" />
            <stop offset="55%" stopColor="#C8CBD0" />
            <stop offset="100%" stopColor="#5D6167" />
          </linearGradient>

          {/* Speckle pattern for foliage detail */}
          <filter id="cb-blur" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="0.6" />
          </filter>
        </defs>

        {/* ============================ TREE ============================ */}
        <g style={{ filter: "drop-shadow(0 0 6px rgba(0,229,255,0.18))" }}>
          {/* Twisted main trunk — bezier for organic bonsai curl */}
          <path
            d="M110 178
               C 96 168, 92 152, 100 138
               C 112 122, 96 108, 104 92
               C 112 78, 100 66, 110 54"
            stroke="url(#cb-trunk)"
            strokeWidth="9"
            fill="none"
            strokeLinecap="round"
          />
          {/* trunk highlight */}
          <path
            d="M110 178 C 96 168, 92 152, 100 138 C 112 122, 96 108, 104 92 C 112 78, 100 66, 110 54"
            stroke="rgba(255,255,255,0.55)"
            strokeWidth="1.4"
            fill="none"
            strokeLinecap="round"
          />

          {/* Left mid branch */}
          <path
            d="M100 138 C 84 132, 70 128, 54 122"
            stroke="url(#cb-branch)"
            strokeWidth="4.4"
            fill="none"
            strokeLinecap="round"
          />
          {/* Left mid branch highlight */}
          <path
            d="M100 138 C 84 132, 70 128, 54 122"
            stroke="rgba(255,255,255,0.5)"
            strokeWidth="0.8"
            fill="none"
            strokeLinecap="round"
          />

          {/* Right lower branch */}
          <path
            d="M102 152 C 118 148, 132 148, 148 154"
            stroke="url(#cb-branch)"
            strokeWidth="4.2"
            fill="none"
            strokeLinecap="round"
          />
          <path
            d="M102 152 C 118 148, 132 148, 148 154"
            stroke="rgba(255,255,255,0.45)"
            strokeWidth="0.7"
            fill="none"
            strokeLinecap="round"
          />

          {/* Right upper branch */}
          <path
            d="M104 92 C 122 88, 142 86, 162 84"
            stroke="url(#cb-branch)"
            strokeWidth="3.8"
            fill="none"
            strokeLinecap="round"
          />
          <path
            d="M104 92 C 122 88, 142 86, 162 84"
            stroke="rgba(255,255,255,0.45)"
            strokeWidth="0.7"
            fill="none"
            strokeLinecap="round"
          />

          {/* Left upper branch (short) */}
          <path
            d="M108 68 C 96 66, 84 68, 72 72"
            stroke="url(#cb-branch)"
            strokeWidth="3.2"
            fill="none"
            strokeLinecap="round"
          />
          <path
            d="M108 68 C 96 66, 84 68, 72 72"
            stroke="rgba(255,255,255,0.45)"
            strokeWidth="0.6"
            fill="none"
            strokeLinecap="round"
          />

          {/* Small twig branches for realism */}
          <path d="M54 122 C 48 118, 44 114, 40 110" stroke="url(#cb-branch)" strokeWidth="2" fill="none" strokeLinecap="round" />
          <path d="M148 154 C 156 152, 162 148, 170 144" stroke="url(#cb-branch)" strokeWidth="2" fill="none" strokeLinecap="round" />
          <path d="M162 84  C 172 80, 180 76, 188 74"  stroke="url(#cb-branch)" strokeWidth="1.8" fill="none" strokeLinecap="round" />
          <path d="M72 72   C 66 70, 60 72, 54 76"     stroke="url(#cb-branch)" strokeWidth="1.8" fill="none" strokeLinecap="round" />

          {/* =========== FOLIAGE — layered cloud shapes =========== */}
          {/* Crown top */}
          <g filter="url(#cb-blur)">
            <ellipse cx="110" cy="46"  rx="34" ry="18" fill="url(#cb-crown)" />
            <ellipse cx="110" cy="46"  rx="34" ry="18" fill="url(#cb-crown-rim)" opacity="0.85" />
          </g>
          {/* Left upper cluster */}
          <g filter="url(#cb-blur)">
            <ellipse cx="60"  cy="68"  rx="24" ry="13" fill="url(#cb-crown)" />
            <ellipse cx="60"  cy="68"  rx="24" ry="13" fill="url(#cb-crown-rim)" opacity="0.9" />
          </g>
          {/* Right upper cluster */}
          <g filter="url(#cb-blur)">
            <ellipse cx="170" cy="76"  rx="26" ry="14" fill="url(#cb-crown)" />
            <ellipse cx="170" cy="76"  rx="26" ry="14" fill="url(#cb-crown-rim)" opacity="0.9" />
          </g>
          {/* Left mid cluster */}
          <g filter="url(#cb-blur)">
            <ellipse cx="42"  cy="118" rx="22" ry="11" fill="url(#cb-crown)" />
            <ellipse cx="42"  cy="118" rx="22" ry="11" fill="url(#cb-crown-rim)" opacity="0.9" />
          </g>
          {/* Right lower cluster */}
          <g filter="url(#cb-blur)">
            <ellipse cx="160" cy="148" rx="24" ry="12" fill="url(#cb-crown)" />
            <ellipse cx="160" cy="148" rx="24" ry="12" fill="url(#cb-crown-rim)" opacity="0.9" />
          </g>

          {/* Micro-leaf specks — 40 tiny chrome pips for foliage texture */}
          <g fill="#EAECEF" opacity="0.85">
            {LEAF_SPECKS.map(([x, y, r], i) => (
              <circle key={i} cx={x} cy={y} r={r} />
            ))}
          </g>
          {/* Cyan leaf glints */}
          <g fill="#7BF3FF" opacity="0.9" style={{ filter: "drop-shadow(0 0 3px rgba(0,229,255,0.9))" }}>
            {LEAF_GLINTS.map(([x, y, r], i) => (
              <circle key={i} cx={x} cy={y} r={r} />
            ))}
          </g>
        </g>

        {/* ============================ PEDESTAL ============================ */}
        <g>
          {/* Outer ring shadow */}
          <ellipse cx="110" cy="196" rx="60" ry="10" fill="rgba(0,0,0,0.7)" />
          {/* Chrome disc */}
          <ellipse cx="110" cy="192" rx="58" ry="9" fill="url(#cb-pedestal)" />
          {/* Rim highlight */}
          <ellipse cx="110" cy="188" rx="56" ry="3.2" fill="url(#cb-pedestal-ring)" opacity="0.85" />
          {/* Neon rim glow underneath */}
          <ellipse cx="110" cy="196" rx="46" ry="3" fill="rgba(0,229,255,0.65)" filter="url(#cb-blur)" />
          {/* Embossed M */}
          <g transform="translate(97,182)">
            <path
              d="M0 10 L0 0 L4 0 L7 6 L10 0 L14 0 L14 10 L11 10 L11 4 L9 8 L8 8 L6 4 L6 10 Z"
              fill="url(#cb-M)"
              stroke="rgba(255,255,255,0.6)"
              strokeWidth="0.25"
            />
          </g>
        </g>
      </svg>
    </div>
  );
}

/* Static jitter tables so re-renders don't reshuffle the tree. */
const LEAF_SPECKS = [
  [92, 40, 1.6], [102, 34, 1.4], [118, 32, 1.6], [128, 42, 1.5], [100, 52, 1.4],
  [122, 52, 1.4], [110, 30, 1.4], [96, 46, 1.2], [130, 34, 1.2],
  [48, 62, 1.3], [58, 60, 1.4], [70, 64, 1.4], [80, 72, 1.3], [50, 74, 1.4], [66, 78, 1.2],
  [156, 68, 1.4], [168, 66, 1.5], [180, 72, 1.4], [188, 82, 1.3], [162, 84, 1.4], [178, 88, 1.3],
  [30, 112, 1.4], [40, 108, 1.4], [50, 116, 1.4], [56, 126, 1.3], [34, 124, 1.4],
  [148, 140, 1.4], [160, 142, 1.5], [172, 148, 1.4], [156, 156, 1.3], [168, 158, 1.4], [176, 152, 1.2],
];
const LEAF_GLINTS = [
  [104, 40, 1.1], [124, 44, 1.0], [64, 66, 1.1], [72, 76, 1.0],
  [172, 72, 1.1], [182, 78, 1.0], [40, 116, 1.1], [50, 124, 1.0],
  [156, 146, 1.1], [170, 152, 1.0],
];
