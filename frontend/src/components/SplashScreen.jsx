import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import MilliLogo from "./MilliLogo";

/**
 * SplashScreen v1.9.3 — Bespoke Cinematic Animation
 *
 * Narrative sequence (pure CSS/SVG, no external video dependency):
 * 1. Dark void → headlights appear (0-1s)
 * 2. Car silhouette rockets forward, motion blur streaks (1-2.5s)
 * 3. Car launches upward (takeoff), trail becomes engine glow (2.5-3.5s)
 * 4. Engine glow expands, fills screen in cyan bloom (3.5-4.2s)
 * 5. Bloom clears → Chrome M logo reveal + "MILLI" wordmark (4.2-5s)
 * 6. Auto-transition after 5s total (zero-touch)
 */

const TOTAL_DURATION = 5000; // 5 seconds, zero-touch auto-proceed

export default function SplashScreen({ onDone }) {
  const [phase, setPhase] = useState(0); // 0=dark, 1=headlights, 2=launch, 3=glow, 4=reveal
  const [exiting, setExiting] = useState(false);
  const timerRef = useRef(null);

  useEffect(() => {
    // Phase progression
    const timings = [
      [1, 800],    // headlights after 800ms
      [2, 2000],   // car forward at 2s
      [3, 3200],   // takeoff/glow at 3.2s
      [4, 4000],   // logo reveal at 4s
    ];

    const timers = timings.map(([p, ms]) => setTimeout(() => setPhase(p), ms));

    // Auto-proceed after total duration
    timerRef.current = setTimeout(() => {
      setExiting(true);
      setTimeout(() => onDone?.(), 500);
    }, TOTAL_DURATION);

    return () => {
      timers.forEach(clearTimeout);
      clearTimeout(timerRef.current);
    };
  }, [onDone]);

  return (
    <AnimatePresence>
      {!exiting && (
        <motion.div
          key="splash"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.5 }}
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 100000,
            background: "#050607",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            overflow: "hidden",
            fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Sora", system-ui, sans-serif',
          }}
        >
          {/* === Phase 0-1: Road streaks background === */}
          <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
            {/* Perspective road lines (always visible, intensify with phase) */}
            {Array.from({ length: 12 }).map((_, i) => (
              <motion.div
                key={`streak-${i}`}
                initial={{ scaleX: 0, opacity: 0 }}
                animate={{
                  scaleX: phase >= 1 ? 1 : 0,
                  opacity: phase >= 1 ? (phase >= 3 ? 0 : 0.3 + Math.random() * 0.4) : 0,
                }}
                transition={{ duration: 0.6, delay: i * 0.05 }}
                style={{
                  position: "absolute",
                  left: "50%",
                  top: `${30 + i * 4}%`,
                  width: `${60 + i * 8}%`,
                  height: "1px",
                  background: `linear-gradient(90deg, transparent, rgba(0,229,255,${0.2 + i * 0.03}), transparent)`,
                  transformOrigin: "center",
                  transform: `translateX(-50%) rotate(${(i - 6) * 2}deg)`,
                }}
              />
            ))}
          </div>

          {/* === Phase 1-2: Headlights / Car silhouette === */}
          <motion.div
            animate={{
              opacity: phase >= 1 && phase < 3 ? 1 : 0,
              scale: phase >= 2 ? 0.3 : 1,
              y: phase >= 2 ? -200 : 0,
            }}
            transition={{ duration: phase >= 2 ? 0.8 : 0.5, ease: "easeInOut" }}
            style={{
              position: "absolute",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 8,
            }}
          >
            {/* Headlight beams */}
            <div style={{ display: "flex", gap: 24 }}>
              <motion.div
                animate={{ boxShadow: phase >= 1 ? "0 0 30px 10px rgba(255,255,255,0.8)" : "none" }}
                style={{
                  width: 8, height: 4, borderRadius: 4,
                  background: "#FFFFFF",
                }}
              />
              <motion.div
                animate={{ boxShadow: phase >= 1 ? "0 0 30px 10px rgba(255,255,255,0.8)" : "none" }}
                style={{
                  width: 8, height: 4, borderRadius: 4,
                  background: "#FFFFFF",
                }}
              />
            </div>
            {/* Car body silhouette */}
            <div style={{
              width: 80, height: 24, borderRadius: "8px 8px 2px 2px",
              background: "linear-gradient(180deg, #1a1a2e, #0a0a0f)",
              border: "1px solid rgba(255,255,255,0.1)",
            }} />
          </motion.div>

          {/* === Phase 2-3: Engine trail / Launch trail === */}
          <motion.div
            animate={{
              opacity: phase >= 2 && phase < 4 ? 1 : 0,
              scaleY: phase >= 3 ? 3 : 1,
              scaleX: phase >= 3 ? 8 : 1,
            }}
            transition={{ duration: 0.8, ease: "easeOut" }}
            style={{
              position: "absolute",
              width: 4, height: 120,
              background: "linear-gradient(180deg, #00E5FF, rgba(0,229,255,0.3), transparent)",
              borderRadius: 2,
              filter: "blur(2px)",
            }}
          />

          {/* === Phase 3: Cyan bloom (engine glow fills screen) === */}
          <motion.div
            animate={{
              opacity: phase >= 3 ? 1 : 0,
              scale: phase >= 3 ? (phase >= 4 ? 0 : 4) : 0,
            }}
            transition={{ duration: phase >= 4 ? 0.6 : 0.8, ease: "easeInOut" }}
            style={{
              position: "absolute",
              width: 200, height: 200,
              borderRadius: "50%",
              background: "radial-gradient(circle, rgba(0,229,255,0.6) 0%, rgba(0,229,255,0.2) 40%, transparent 70%)",
              filter: "blur(30px)",
            }}
          />

          {/* === Phase 4: Logo Reveal === */}
          <motion.div
            initial={{ opacity: 0, scale: 0.5, filter: "blur(20px)" }}
            animate={{
              opacity: phase >= 4 ? 1 : 0,
              scale: phase >= 4 ? 1 : 0.5,
              filter: phase >= 4 ? "blur(0px)" : "blur(20px)",
            }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 16,
              zIndex: 10,
            }}
          >
            <MilliLogo size={100} glow={true} motion={true} />

            {/* MILLI wordmark */}
            <motion.h1
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: phase >= 4 ? 1 : 0, y: phase >= 4 ? 0 : 10 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              style={{
                fontSize: 32,
                fontWeight: 700,
                letterSpacing: "0.2em",
                background: "linear-gradient(135deg, #9CA3AF, #F9FAFB, #D1D5DB)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                backgroundClip: "text",
                margin: 0,
              }}
            >
              MILLI
            </motion.h1>

            {/* Tagline */}
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: phase >= 4 ? 0.7 : 0 }}
              transition={{ duration: 0.5, delay: 0.5 }}
              style={{
                fontSize: 13,
                color: "#8B9DAF",
                letterSpacing: "0.05em",
                margin: 0,
              }}
            >
              TAX AUTOPILOT
            </motion.p>
          </motion.div>

          {/* === Ambient particles === */}
          <div style={{ position: "absolute", inset: 0, pointerEvents: "none", overflow: "hidden" }}>
            {Array.from({ length: 20 }).map((_, i) => (
              <motion.div
                key={`particle-${i}`}
                initial={{ opacity: 0 }}
                animate={{
                  opacity: phase >= 2 ? [0, 0.5, 0] : 0,
                  y: phase >= 2 ? [0, -300] : 0,
                }}
                transition={{
                  duration: 2 + Math.random() * 2,
                  delay: Math.random() * 1.5,
                  repeat: Infinity,
                }}
                style={{
                  position: "absolute",
                  left: `${10 + Math.random() * 80}%`,
                  bottom: "10%",
                  width: 2, height: 2,
                  borderRadius: "50%",
                  background: "#00E5FF",
                }}
              />
            ))}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
