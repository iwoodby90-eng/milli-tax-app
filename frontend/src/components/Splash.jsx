/**
 * MILLI cinematic splash — ~5 seconds, multi-stage:
 *  0.0–0.6s   Void + scan-line sweep
 *  0.6–1.6s   Logo materializes with multi-burst glow
 *  1.6–3.0s   Letter-by-letter wordmark + reflection
 *  3.0–4.2s   Tagline + precision loading bar fills
 *  4.2–4.8s   Fade to app
 */
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import MilliLogo from "@/components/MilliLogo";

const LETTERS = ["M", "I", "L", "L", "I"];
const TOTAL_MS = 4800;

export default function Splash({ onDone }) {
  const [show, setShow] = useState(true);

  useEffect(() => {
    const t = setTimeout(() => setShow(false), TOTAL_MS);
    const t2 = setTimeout(() => onDone && onDone(), TOTAL_MS + 350);
    return () => { clearTimeout(t); clearTimeout(t2); };
  }, [onDone]);

  // Generate floating particles
  const particles = Array.from({ length: 22 }, (_, i) => ({
    id: i,
    x: Math.random() * 100,
    delay: Math.random() * 2,
    duration: 4 + Math.random() * 3,
    size: 1 + Math.random() * 2,
  }));

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          key="splash"
          className="fixed inset-0 z-[100] overflow-hidden carbon-bg"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: 0.35, ease: "easeInOut" } }}
          data-testid="splash-screen"
        >
          {/* Layer 0 — deep ambient gradient */}
          <motion.div
            className="absolute inset-0"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.2 }}
            style={{
              background:
                "radial-gradient(ellipse 70% 50% at 50% 50%, rgba(19, 216, 209, 0.16) 0%, transparent 60%), radial-gradient(ellipse 50% 30% at 50% 110%, rgba(8, 127, 130, 0.20), transparent 65%)",
            }}
          />

          {/* Layer 1 — vertical grid lines (futuristic road perspective) */}
          <motion.svg
            className="absolute inset-0 w-full h-full opacity-25"
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.25 }}
            transition={{ delay: 0.4, duration: 1.5 }}
          >
            {[20, 35, 50, 65, 80].map((x, i) => (
              <motion.line
                key={`splash-line-${x}`}
                x1={`${x}%`}
                y1="0%"
                x2={`${50}%`}
                y2="100%"
                stroke="rgba(19, 216, 209, 0.18)"
                strokeWidth="0.6"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ delay: 0.6 + i * 0.06, duration: 1.0, ease: "easeOut" }}
              />
            ))}
            {[20, 35, 50, 65, 80].map((x, i) => (
              <motion.line
                key={"r" + i}
                x1={`${100 - x}%`}
                y1="0%"
                x2={`${50}%`}
                y2="100%"
                stroke="rgba(19, 216, 209, 0.18)"
                strokeWidth="0.6"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ delay: 0.6 + i * 0.06, duration: 1.0, ease: "easeOut" }}
              />
            ))}
          </motion.svg>

          {/* Layer 2 — floating particles rising */}
          {particles.map((p) => (
            <motion.div
              key={p.id}
              className="absolute rounded-full"
              style={{
                left: `${p.x}%`,
                width: p.size,
                height: p.size,
                background: "rgba(19, 216, 209, 0.7)",
                boxShadow: "0 0 8px rgba(19,216,209,0.8)",
              }}
              initial={{ y: "110vh", opacity: 0 }}
              animate={{ y: "-10vh", opacity: [0, 0.9, 0.9, 0] }}
              transition={{
                delay: p.delay,
                duration: p.duration,
                times: [0, 0.2, 0.8, 1],
                ease: "linear",
              }}
            />
          ))}

          {/* Layer 3 — diagonal scan-line sweep */}
          <motion.div
            className="absolute inset-0"
            initial={{ x: "-120%" }}
            animate={{ x: "120%" }}
            transition={{ duration: 1.6, delay: 0.2, ease: [0.4, 0, 0.2, 1] }}
            style={{
              background:
                "linear-gradient(115deg, transparent 35%, rgba(19,216,209,0.4) 50%, transparent 65%)",
              filter: "blur(2px)",
            }}
          />

          {/* Layer 4 — secondary slow sweep */}
          <motion.div
            className="absolute inset-0 opacity-50"
            initial={{ x: "120%" }}
            animate={{ x: "-120%" }}
            transition={{ duration: 2.4, delay: 1.6, ease: [0.4, 0, 0.2, 1] }}
            style={{
              background:
                "linear-gradient(65deg, transparent 40%, rgba(19,216,209,0.18) 50%, transparent 60%)",
              filter: "blur(3px)",
            }}
          />

          {/* Center stage */}
          <div className="relative z-10 flex flex-col items-center justify-center min-h-screen px-6">
            {/* Logo block */}
            <div className="relative">
              {/* Outer pulsing ring */}
              <motion.div
                className="absolute inset-0 rounded-full"
                initial={{ scale: 0.4, opacity: 0 }}
                animate={{ scale: [0.4, 1.6, 2.2], opacity: [0, 0.6, 0] }}
                transition={{ duration: 1.8, delay: 0.7, times: [0, 0.5, 1] }}
                style={{
                  background: "radial-gradient(circle, rgba(19,216,209,0.45), transparent 70%)",
                }}
              />
              {/* Second pulse layer */}
              <motion.div
                className="absolute inset-0 rounded-full"
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: [0.5, 1.9, 2.6], opacity: [0, 0.4, 0] }}
                transition={{ duration: 2.2, delay: 1.2, times: [0, 0.5, 1] }}
                style={{
                  background: "radial-gradient(circle, rgba(19,216,209,0.3), transparent 70%)",
                }}
              />

              {/* M logo — assemble & rotate slightly */}
              <motion.div
                initial={{ scale: 0.4, opacity: 0, filter: "blur(14px)", rotateY: 30 }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)", rotateY: 0 }}
                transition={{ duration: 1.4, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
              >
                <MilliLogo size={144} />
              </motion.div>

              {/* Bright burst at logo reveal */}
              <motion.div
                className="absolute inset-0 flex items-center justify-center pointer-events-none"
                initial={{ opacity: 0 }}
                animate={{ opacity: [0, 1, 0] }}
                transition={{ duration: 0.5, delay: 1.4 }}
              >
                <div
                  className="w-44 h-44 rounded-full"
                  style={{
                    background:
                      "radial-gradient(circle, rgba(255,255,255,0.95) 0%, rgba(19,216,209,0.55) 30%, transparent 70%)",
                  }}
                />
              </motion.div>
            </div>

            {/* Wordmark — letter by letter */}
            <div className="mt-12 flex items-center gap-1.5 sm:gap-2">
              {LETTERS.map((ch, i) => (
                <motion.span
                  key={`letter-${ch}-${i}`}
                  className="chrome-text font-display text-5xl sm:text-6xl tracking-tight"
                  style={{ display: "inline-block", textShadow: "0 0 24px rgba(19,216,209,0.35)" }}
                  initial={{ opacity: 0, y: 28, scale: 0.7, filter: "blur(8px)" }}
                  animate={{ opacity: 1, y: 0, scale: 1, filter: "blur(0px)" }}
                  transition={{ delay: 1.6 + i * 0.12, duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
                >
                  {ch}
                </motion.span>
              ))}
            </div>

            {/* Cyan reflection line under wordmark */}
            <motion.div
              className="mt-3 h-px"
              initial={{ width: 0, opacity: 0 }}
              animate={{ width: 160, opacity: [0, 1, 0.4] }}
              transition={{ delay: 2.4, duration: 1.0 }}
              style={{
                background: "linear-gradient(90deg, transparent, #13D8D1, transparent)",
                boxShadow: "0 0 16px #13D8D1",
              }}
            />

            {/* Tagline */}
            <motion.div
              className="mt-6 text-xs uppercase tracking-[0.4em] text-zinc-400 font-mono"
              initial={{ opacity: 0, letterSpacing: "0.6em" }}
              animate={{ opacity: 1, letterSpacing: "0.4em" }}
              transition={{ delay: 2.8, duration: 0.8 }}
            >
              Tax Autopilot
            </motion.div>

            {/* Precision loading bar */}
            <div className="mt-12 w-56 relative">
              <div className="flex justify-between text-[9px] uppercase tracking-[0.3em] text-zinc-600 mb-2 font-mono">
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 3.0 }}
                >
                  initializing
                </motion.span>
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 3.0 }}
                  className="text-volt"
                >
                  secure
                </motion.span>
              </div>
              <div className="h-px bg-zinc-800 relative overflow-hidden">
                <motion.div
                  className="absolute top-0 left-0 h-full"
                  initial={{ width: 0 }}
                  animate={{ width: "100%" }}
                  transition={{ delay: 3.0, duration: 1.4, ease: "easeInOut" }}
                  style={{
                    background: "linear-gradient(90deg, transparent, #13D8D1)",
                    boxShadow: "0 0 12px #13D8D1",
                  }}
                />
              </div>

              {/* Spec rivets at endpoints */}
              <motion.div
                className="absolute -top-0.5 -left-1 w-1.5 h-1.5 rounded-full bg-volt"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 3.1 }}
                style={{ boxShadow: "0 0 8px #13D8D1" }}
              />
              <motion.div
                className="absolute -top-0.5 -right-1 w-1.5 h-1.5 rounded-full bg-volt"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 4.3 }}
                style={{ boxShadow: "0 0 8px #13D8D1" }}
              />
            </div>

            {/* Equalizer animation under bar */}
            <motion.div
              className="mt-10 flex items-end gap-1.5 h-6"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 3.4 }}
            >
              {[0, 1, 2, 3, 4].map((i) => (
                <motion.div
                  key={i}
                  className="w-0.5 bg-volt rounded-full"
                  animate={{ height: ["20%", "100%", "40%", "80%", "20%"] }}
                  transition={{
                    duration: 1.4,
                    repeat: Infinity,
                    ease: "easeInOut",
                    delay: i * 0.08,
                  }}
                  style={{ boxShadow: "0 0 6px #13D8D1" }}
                />
              ))}
            </motion.div>
          </div>

          {/* Top-corner brackets */}
          <motion.div
            className="absolute top-6 left-6 w-8 h-8 border-l border-t border-volt/60"
            initial={{ opacity: 0, x: -12, y: -12 }}
            animate={{ opacity: 1, x: 0, y: 0 }}
            transition={{ delay: 0.5, duration: 0.6 }}
          />
          <motion.div
            className="absolute top-6 right-6 w-8 h-8 border-r border-t border-volt/60"
            initial={{ opacity: 0, x: 12, y: -12 }}
            animate={{ opacity: 1, x: 0, y: 0 }}
            transition={{ delay: 0.5, duration: 0.6 }}
          />
          <motion.div
            className="absolute bottom-6 left-6 w-8 h-8 border-l border-b border-volt/60"
            initial={{ opacity: 0, x: -12, y: 12 }}
            animate={{ opacity: 1, x: 0, y: 0 }}
            transition={{ delay: 0.7, duration: 0.6 }}
          />
          <motion.div
            className="absolute bottom-6 right-6 w-8 h-8 border-r border-b border-volt/60"
            initial={{ opacity: 0, x: 12, y: 12 }}
            animate={{ opacity: 1, x: 0, y: 0 }}
            transition={{ delay: 0.7, duration: 0.6 }}
          />

          {/* Top centered build-id */}
          <motion.div
            className="absolute top-7 left-1/2 -translate-x-1/2 text-[9px] uppercase tracking-[0.5em] text-zinc-600 font-mono"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.9 }}
          >
            milli // tax autopilot · v1.0
          </motion.div>

          {/* Bottom legal-mono */}
          <motion.div
            className="absolute bottom-7 left-1/2 -translate-x-1/2 text-[9px] uppercase tracking-[0.4em] text-zinc-700 font-mono"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 3.6 }}
          >
            Earn freely · Milli handles the tax side
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
