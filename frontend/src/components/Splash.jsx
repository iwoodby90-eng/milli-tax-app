/**
 * Cinematic splash screen — the "M" lights up, light travels through it,
 * MILLI wordmark + tagline fade in. Auto-dismisses after ~2.4s.
 */
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import MilliLogo from "@/components/MilliLogo";

export default function Splash({ onDone }) {
  const [show, setShow] = useState(true);

  useEffect(() => {
    const t = setTimeout(() => setShow(false), 2400);
    const t2 = setTimeout(() => onDone && onDone(), 2700);
    return () => { clearTimeout(t); clearTimeout(t2); };
  }, [onDone]);

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          key="splash"
          className="fixed inset-0 z-[100] flex items-center justify-center carbon-bg overflow-hidden"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: 0.3 } }}
          data-testid="splash-screen"
        >
          {/* Background light rays */}
          <motion.div
            className="absolute inset-0"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1 }}
            style={{
              background:
                "radial-gradient(ellipse 60% 40% at 50% 50%, rgba(19, 216, 209, 0.18), transparent 70%)",
            }}
          />
          {/* Diagonal scan lines */}
          <motion.div
            className="absolute inset-0 opacity-20"
            initial={{ x: "-100%" }}
            animate={{ x: "100%" }}
            transition={{ duration: 2.2, ease: "easeInOut" }}
            style={{
              background:
                "linear-gradient(120deg, transparent 30%, rgba(19,216,209,0.35) 50%, transparent 70%)",
            }}
          />

          <div className="relative flex flex-col items-center">
            {/* Logo with grow + glow */}
            <motion.div
              initial={{ scale: 0.7, opacity: 0, filter: "blur(8px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
            >
              <MilliLogo size={128} />
            </motion.div>

            {/* Cyan light line traveling through */}
            <motion.div
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-32 h-32 rounded-full"
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: [0, 1.4, 1.4], opacity: [0, 0.6, 0] }}
              transition={{ duration: 1.6, delay: 0.4, times: [0, 0.6, 1] }}
              style={{
                background:
                  "radial-gradient(circle, rgba(19,216,209,0.55) 0%, transparent 60%)",
              }}
            />

            {/* Wordmark */}
            <motion.div
              className="mt-10 chrome-text font-display text-5xl tracking-[0.4em]"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.9, duration: 0.6 }}
            >
              MILLI
            </motion.div>

            {/* Cyan reflection underline */}
            <motion.div
              className="mt-2 h-px bg-volt"
              initial={{ width: 0, opacity: 0 }}
              animate={{ width: 100, opacity: [0, 1, 0.3] }}
              transition={{ delay: 1.3, duration: 0.9 }}
              style={{ boxShadow: "0 0 12px #13D8D1" }}
            />

            {/* Tagline */}
            <motion.div
              className="mt-4 text-xs uppercase tracking-[0.4em] text-zinc-500 font-mono"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.5, duration: 0.5 }}
            >
              Tax Autopilot
            </motion.div>

            {/* Loading dots */}
            <motion.div
              className="mt-8 flex gap-1.5"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.7 }}
            >
              {[0, 1, 2].map((i) => (
                <motion.div
                  key={i}
                  className="w-1 h-1 rounded-full bg-volt"
                  animate={{ opacity: [0.2, 1, 0.2] }}
                  transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.2 }}
                />
              ))}
            </motion.div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
