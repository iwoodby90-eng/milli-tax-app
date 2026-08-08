/**
 * SplashScreen — cinematic brand intro for Milli Tax Vault.
 * Full-screen deep black with radial teal bloom, animated logo,
 * chrome wordmark, and teal particle bloom.
 */
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import MilliLogo from "./MilliLogo";

const CYAN = "#00E5FF";
const HOLD_MS = 3200;
const FADE_MS = 700;

export default function SplashScreen({ onDone, minDurationMs = HOLD_MS, autoFade = false }) {
  const [visible, setVisible] = useState(true);
  const [readyToDismiss, setReadyToDismiss] = useState(false);

  useEffect(() => {
    const t = setTimeout(() => {
      setReadyToDismiss(true);
      if (autoFade) {
        setTimeout(() => {
          setVisible(false);
          setTimeout(() => onDone && onDone(), FADE_MS + 50);
        }, 600);
      }
    }, minDurationMs);
    return () => clearTimeout(t);
  }, [minDurationMs, autoFade, onDone]);

  const dismiss = () => {
    if (!readyToDismiss || autoFade) return;
    setVisible(false);
    setTimeout(() => onDone && onDone(), FADE_MS + 50);
  };

  useEffect(() => {
    if (!readyToDismiss || !visible || autoFade) return;
    const onKey = (e) => {
      if (e.key === "Enter" || e.key === " " || e.key === "Escape") dismiss();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [readyToDismiss, visible, autoFade]);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key="milli-splash"
          data-testid="splash-screen"
          role="button"
          tabIndex={0}
          onClick={dismiss}
          onTouchEnd={dismiss}
          className={`absolute inset-0 z-[200] overflow-hidden flex items-center justify-center ${readyToDismiss ? "cursor-pointer" : "cursor-default"}`}
          initial={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: FADE_MS / 1000, ease: "easeInOut" } }}
          style={{
            backgroundColor: "#050607",
            fontFamily: '-apple-system, BlinkMacSystemFont, "Outfit", system-ui, sans-serif',
          }}
        >
          {/* Radial teal bloom — growing from center */}
          <motion.div
            aria-hidden
            className="absolute rounded-full"
            style={{
              width: 600, height: 600,
              background: `radial-gradient(circle, rgba(0,229,255,0.15) 0%, rgba(0,229,255,0.05) 40%, transparent 70%)`,
            }}
            initial={{ scale: 0.2, opacity: 0 }}
            animate={{ scale: [0.2, 1.2, 1.5], opacity: [0, 0.8, 0.5] }}
            transition={{ duration: 2.5, ease: "easeOut" }}
          />

          {/* Particle bloom — 6 teal dots pulsing outward */}
          {[0, 60, 120, 180, 240, 300].map((angle, i) => (
            <motion.div
              key={i}
              aria-hidden
              className="absolute w-2 h-2 rounded-full"
              style={{
                background: CYAN,
                boxShadow: `0 0 12px ${CYAN}`,
                "--tx": `${Math.cos((angle * Math.PI) / 180) * 100}px`,
                "--ty": `${Math.sin((angle * Math.PI) / 180) * 100}px`,
              }}
              initial={{ scale: 0, x: 0, y: 0, opacity: 1 }}
              animate={{
                scale: [0, 1.2, 0.8],
                x: Math.cos((angle * Math.PI) / 180) * 120,
                y: Math.sin((angle * Math.PI) / 180) * 120,
                opacity: [0, 1, 0],
              }}
              transition={{ delay: 1.0 + i * 0.08, duration: 1.4, ease: "easeOut" }}
            />
          ))}

          {/* Center content */}
          <div className="relative z-10 flex flex-col items-center gap-5">
            {/* Animated Milli logo */}
            <motion.div
              initial={{ opacity: 0, scale: 0.6 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 1.2, ease: [0.34, 1.56, 0.64, 1] }}
            >
              <MilliLogo size={96} animate={false} />
            </motion.div>

            {/* MILLI wordmark with chrome gradient */}
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5, duration: 0.7, ease: "easeOut" }}
              className="text-[42px] font-bold leading-none"
              style={{
                letterSpacing: "0.18em",
                background: "linear-gradient(180deg, #F4F6F8 0%, #B0B5BA 50%, #6B7075 100%)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                textShadow: "0 0 20px rgba(0,229,255,0.15)",
              }}
              data-testid="splash-wordmark"
            >
              MILLI
            </motion.div>

            {/* Tax Vault subtitle */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.0, duration: 0.6 }}
              className="text-[13px] uppercase tracking-[0.25em] font-medium"
              style={{ color: "#6B7280" }}
            >
              Tax Vault
            </motion.div>

            {/* Loading indicator */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.4, duration: 0.5 }}
              className="mt-6"
            >
              <AnimatePresence mode="wait">
                {(!readyToDismiss || autoFade) ? (
                  <motion.div
                    key="loading"
                    className="text-[11px] tracking-[0.05em]"
                    style={{ color: "#6B7280" }}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    data-testid="splash-status"
                  >
                    Initializing your vault
                    <motion.span
                      className="inline-block ml-0.5"
                      animate={{ opacity: [1, 0.2, 1] }}
                      transition={{ duration: 1.2, repeat: Infinity }}
                    >
                      …
                    </motion.span>
                  </motion.div>
                ) : (
                  <motion.div
                    key="tap"
                    className="text-white text-[11px] uppercase tracking-[0.15em] font-medium"
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: [0.4, 1, 0.4], y: 0 }}
                    transition={{ opacity: { duration: 2, repeat: Infinity }, y: { duration: 0.3 } }}
                    data-testid="splash-tap-prompt"
                  >
                    Tap to continue
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
