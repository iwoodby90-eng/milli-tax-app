import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";

/**
 * SplashScreen v2.2 — ZERO-SCROLL Cinematic Startup.
 *
 * FLOW (fully automatic, zero-touch):
 *   1. 'Perfect' car take-off video plays full-screen (~10s).
 *   2. Video ends → smooth cross-fade into 'Welcome back, [User Name]' screen.
 *   3. Welcome screen auto-holds for 2 seconds.
 *   4. Auto-advances to Dashboard via onDone callback.
 *
 * NO scroll, NO tap, NO interaction required at any stage.
 * Failsafe: if video fails/blocks, CSS fallback → welcome → exit.
 */

const VIDEO_URL =
  "https://customer-assets-7cd3h4nn.emergentagent.net/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/videos/319e22928c08311a.mp4";

const WELCOME_HOLD_MS = 2000;   // 2-second welcome screen hold
const CROSSFADE_DURATION = 0.8; // video → welcome crossfade
const EXIT_FADE_MS = 600;       // welcome → app fade
const MAX_VIDEO_MS = 12000;     // failsafe if video hangs

export default function SplashScreen({ onDone, userName }) {
  const [videoLoaded, setVideoLoaded] = useState(false);
  const [videoFailed, setVideoFailed] = useState(false);
  const [videoEnded, setVideoEnded] = useState(false);
  const [exiting, setExiting] = useState(false);
  const videoRef = useRef(null);
  const exitScheduled = useRef(false);

  // Once welcome screen shows, hold 2s then fade out
  const triggerExit = () => {
    if (exitScheduled.current) return;
    exitScheduled.current = true;
    setTimeout(() => {
      setExiting(true);
      setTimeout(() => onDone?.(), EXIT_FADE_MS);
    }, WELCOME_HOLD_MS);
  };

  // Failsafe: force-advance if video never ends
  useEffect(() => {
    const t = setTimeout(() => {
      setVideoEnded(true);
      triggerExit();
    }, MAX_VIDEO_MS);
    return () => clearTimeout(t);
  }, []);

  const handleVideoLoaded = () => {
    setVideoLoaded(true);
    videoRef.current?.play().catch(() => {
      setVideoFailed(true);
      setVideoEnded(true);
      triggerExit();
    });
  };

  const handleVideoEnd = () => {
    setVideoEnded(true);
    triggerExit();
  };

  const handleVideoError = () => {
    setVideoFailed(true);
    setVideoEnded(true);
    triggerExit();
  };

  const firstName = (userName || "").trim().split(/\s+/)[0] || "";
  const welcomeLine = firstName ? `Welcome back, ${firstName}.` : "Welcome back.";

  return (
    <AnimatePresence>
      {!exiting && (
        <motion.div
          key="splash-screen"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: EXIT_FADE_MS / 1000, ease: "easeInOut" }}
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 100000,
            background: "#050607",
            overflow: "hidden",
          }}
          data-testid="splash-screen"
        >
          {/* === VIDEO LAYER — fades out when video ends === */}
          {!videoFailed && (
            <motion.video
              ref={videoRef}
              src={VIDEO_URL}
              muted
              playsInline
              preload="auto"
              onLoadedData={handleVideoLoaded}
              onEnded={handleVideoEnd}
              onError={handleVideoError}
              animate={{ opacity: videoEnded ? 0 : videoLoaded ? 1 : 0 }}
              transition={{ duration: CROSSFADE_DURATION, ease: "easeInOut" }}
              style={{
                position: "absolute",
                inset: 0,
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
          )}

          {/* === WELCOME BACK SCREEN — cross-fades in after video === */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: videoEnded ? 1 : 0 }}
            transition={{ duration: CROSSFADE_DURATION, ease: "easeInOut" }}
            style={{
              position: "absolute",
              inset: 0,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              background: "#050607",
            }}
          >
            {/* Ambient glow */}
            <div
              style={{
                position: "absolute",
                inset: 0,
                background: "radial-gradient(ellipse 60% 40% at 50% 50%, rgba(0,229,255,0.12), transparent 65%)",
                pointerEvents: "none",
              }}
            />

            {/* Expanding ring */}
            {videoEnded && (
              <motion.div
                aria-hidden
                style={{
                  position: "absolute",
                  width: 200,
                  height: 200,
                  borderRadius: "50%",
                  border: "1px solid rgba(0,229,255,0.5)",
                  boxShadow: "0 0 30px rgba(0,229,255,0.3)",
                }}
                initial={{ scale: 0.4, opacity: 0 }}
                animate={{ scale: [0.4, 1.8, 2.5], opacity: [0, 0.6, 0] }}
                transition={{ duration: 1.6, ease: "easeOut" }}
              />
            )}

            {/* Chrome M Logo */}
            {videoEnded && (
              <motion.div
                initial={{ opacity: 0, scale: 0.6, filter: "blur(12px)" }}
                animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
                transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
              >
                <svg viewBox="0 0 200 200" width={100} height={100} xmlns="http://www.w3.org/2000/svg"
                  style={{ filter: "drop-shadow(0 0 30px rgba(0,229,255,0.45)) drop-shadow(0 4px 12px rgba(0,0,0,0.7))" }}>
                  <defs>
                    <linearGradient id="splashChrome" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#F4F6F8" />
                      <stop offset="25%" stopColor="#D8DCE1" />
                      <stop offset="50%" stopColor="#7B8085" />
                      <stop offset="75%" stopColor="#C7CDD3" />
                      <stop offset="100%" stopColor="#5B6068" />
                    </linearGradient>
                    <linearGradient id="splashCyan" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#00FFEA" />
                      <stop offset="100%" stopColor="#00ACC1" />
                    </linearGradient>
                  </defs>
                  <path d="M 30 170 L 30 30 L 50 28 L 85 100 L 100 82 L 115 100 L 150 28 L 170 30 L 170 170 L 150 170 L 150 60 L 120 120 L 100 98 L 80 120 L 50 60 L 50 170 Z" fill="url(#splashChrome)" />
                  <rect x="172" y="30" width="14" height="140" rx="2" fill="url(#splashCyan)" />
                </svg>
              </motion.div>
            )}

            {/* Welcome text */}
            {videoEnded && (
              <motion.div
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
                style={{ marginTop: 28, textAlign: "center" }}
              >
                <div
                  style={{
                    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Sora', system-ui, sans-serif",
                    fontSize: 26,
                    fontWeight: 700,
                    background: "linear-gradient(180deg, #F4F6F8 0%, #C7CDD3 50%, #7B8085 100%)",
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    textShadow: "0 0 20px rgba(0,229,255,0.2)",
                  }}
                  data-testid="welcome-line"
                >
                  {welcomeLine}
                </div>
                <motion.div
                  initial={{ opacity: 0, letterSpacing: "0.5em" }}
                  animate={{ opacity: 1, letterSpacing: "0.32em" }}
                  transition={{ delay: 0.6, duration: 0.6 }}
                  style={{
                    marginTop: 10,
                    fontSize: 11,
                    fontWeight: 600,
                    textTransform: "uppercase",
                    letterSpacing: "0.32em",
                    color: "#00E5FF",
                    textShadow: "0 0 12px rgba(0,229,255,0.5)",
                    fontFamily: "monospace",
                  }}
                >
                  Autopilot Engaged
                </motion.div>
              </motion.div>
            )}

            {/* Bottom pulse indicator */}
            {videoEnded && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
                style={{ position: "absolute", bottom: 60, display: "flex", gap: 6, alignItems: "center" }}
              >
                {[0, 1, 2].map((i) => (
                  <motion.div
                    key={i}
                    style={{ width: 4, height: 4, borderRadius: "50%", background: "#00E5FF", boxShadow: "0 0 6px #00E5FF" }}
                    animate={{ opacity: [0.3, 1, 0.3] }}
                    transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.2 }}
                  />
                ))}
              </motion.div>
            )}
          </motion.div>

          {/* === CSS FALLBACK (if video fails) === */}
          {videoFailed && !videoEnded && (
            <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
              {Array.from({ length: 8 }).map((_, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, scaleX: 0 }}
                  animate={{ opacity: [0, 0.6, 0], scaleX: [0, 1.5, 0] }}
                  transition={{ duration: 2, delay: i * 0.15, repeat: 1 }}
                  style={{
                    position: "absolute", left: "20%", top: `${25 + i * 7}%`, width: "60%", height: "1px",
                    background: `linear-gradient(90deg, transparent, rgba(0,229,255,${0.3 + i * 0.05}), transparent)`,
                    transformOrigin: "center",
                  }}
                />
              ))}
            </div>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
