/**
 * BloomPetals — cyan-cyan-white petal shower that celebrates a fresh bonsai
 * milestone. Petals are teardrop shapes falling with rotation + a soft glow.
 * Auto-clears itself after ~3.2s. Pass a unique `key` when you fire it so
 * the animation restarts on each new milestone.
 */
export default function BloomPetals({ count = 56, testid = "bloom-petals" }) {
  const bits = Array.from({ length: count });
  return (
    <div
      className="pointer-events-none fixed inset-0 z-40 overflow-hidden"
      data-testid={testid}
    >
      {bits.map((_, i) => {
        const left = Math.random() * 100;
        const delay = Math.random() * 0.35;
        const dur = 1.7 + Math.random() * 1.6;
        const rot = Math.random() * 360;
        const drift = (Math.random() - 0.5) * 24; // horizontal wobble in vw
        const size = 8 + Math.random() * 8;
        const color = [
          "linear-gradient(135deg,#7BF3FF 0%,#00E5FF 55%,#00A2C0 100%)",
          "linear-gradient(135deg,#FFFFFF 0%,#B4EBFF 60%,#00E5FF 100%)",
          "linear-gradient(135deg,#00E5FF 0%,#4DE0FF 55%,#005A78 100%)",
        ][i % 3];
        return (
          <span
            key={`petal-${i}-${left.toFixed(2)}-${dur.toFixed(2)}`}
            style={{
              position: "absolute",
              top: "-24px",
              left: `${left}%`,
              width: size,
              height: size * 1.6,
              background: color,
              borderRadius: "50% 50% 50% 0", // teardrop
              boxShadow: "0 0 10px rgba(0,229,255,0.65), 0 0 20px rgba(0,229,255,0.35)",
              transform: `rotate(${rot}deg)`,
              animation: `mv-petal ${dur}s cubic-bezier(0.2,0.7,0.4,1) ${delay}s forwards`,
              // custom prop consumed by keyframes below
              ["--drift"]: `${drift}vw`,
            }}
          />
        );
      })}
      <style>{`
        @keyframes mv-petal {
          0%   { transform: translate(0,0) rotate(0deg);   opacity: 1; }
          70%  { opacity: 0.9; }
          100% { transform: translate(var(--drift,0), 110vh) rotate(680deg); opacity: 0; }
        }
      `}</style>
    </div>
  );
}
