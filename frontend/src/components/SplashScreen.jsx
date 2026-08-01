import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";

/**
 * SplashScreen v2.3 — ARCHITECTURAL LOCK Cinematic Startup.
 *
 * FLOW (fully automatic, zero-touch):
 *   1. 'Perfect' car take-off video plays full-screen (~10s).
 *   2. Video ends → white flash → smooth cross-fade into 4K architectural wordmark.
 *   3. Wordmark holds for 3 seconds (the "Milli-Glow Fade").
 *   4. Auto-fades into Login screen via onDone callback.
 *
 * NO scroll, NO tap, NO interaction required at any stage.
 * Failsafe: if video fails/blocks, CSS fallback → wordmark → exit.
 */

const VIDEO_URL =
  "https://customer-assets-7cd3h4nn.emergentagent.net/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/videos/319e22928c08311a.mp4";

const WORDMARK_URL =
  "https://static.prod-images.emergentagent.com/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/images/ffb506321e2ecff2d2a3c57207bd7e866e1fd1bd9bb21f8bc721b10b3d36c742.jpeg";

const WORDMARK_HOLD_MS = 3000;  // 3-second architectural wordmark hold
const CROSSFADE_DURATION = 0.9; // video → wordmark crossfade
const WHITE_FLASH_MS = 200;     // brief white flash between video & wordmark
const EXIT_FADE_MS = 700;       // wordmark → login fade
const MAX_VIDEO_MS = 12000;     // failsafe if video hangs

export default function SplashScreen({ onDone, userName }) {
  const [videoLoaded, setVideoLoaded] = useState(false);
  const [videoFailed, setVideoFailed] = useState(false);
  const [videoEnded, setVideoEnded] = useState(false);
  const [whiteFlash, setWhiteFlash] = useState(false);
  const [showWordmark, setShowWordmark] = useState(false);
  const [exiting, setExiting] = useState(false);
  const videoRef = useRef(null);
  const exitScheduled = useRef(false);

  // Once wordmark shows, hold 3s then fade out
  const triggerWordmarkHold = () => {
    if (exitScheduled.current) return;
    exitScheduled.current = true;
    setTimeout(() => {
      setExiting(true);
      setTimeout(() => onDone?.(), EXIT_FADE_MS);
    }, WORDMARK_HOLD_MS);
  };

  // Sequence: video ends → white flash → wordmark reveal → hold → exit
  const handleVideoComplete = () => {
    setVideoEnded(true);
    // Brief white flash
    setWhiteFlash(true);
    setTimeout(() => {
      setWhiteFlash(false);
      setShowWordmark(true);
      triggerWordmarkHold();
    }, WHITE_FLASH_MS);
  };

  // Failsafe: force-advance if video never ends
  useEffect(() => {
    const t = setTimeout(() => {
      if (!videoEnded) handleVideoComplete();
    }, MAX_VIDEO_MS);
    return () => clearTimeout(t);
  }, []);

  const handleVideoLoaded = () => {
    setVideoLoaded(true);
    videoRef.current?.play().catch(() => {
      setVideoFailed(true);
      handleVideoComplete();
    });
  };

  const handleVideoEnd = () => {
    handleVideoComplete();
  };

  const handleVideoError = () => {
    setVideoFailed(true);
    handleVideoComplete();
  };

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

          {/* === WHITE FLASH — brief transition between video and wordmark === */}
          <motion.div
            animate={{ opacity: whiteFlash ? 1 : 0 }}
            transition={{ duration: 0.15, ease: "easeOut" }}
            style={{
              position: "absolute",
              inset: 0,
              background: "white",
              pointerEvents: "none",
            }}
          />

          {/* === 4K ARCHITECTURAL WORDMARK — the "Milli-Glow Fade" === */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: showWordmark ? 1 : 0 }}
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
            {/* Ambient cinematic glow behind wordmark */}
            <div
              style={{
                position: "absolute",
                inset: 0,
                background: "radial-gradient(ellipse 70% 50% at 50% 50%, rgba(0,229,255,0.08), transparent 65%)",
                pointerEvents: "none",
              }}
            />

            {/* Expanding ring on reveal */}
            {showWordmark && (
              <motion.div
                aria-hidden
                style={{
                  position: "absolute",
                  width: 240,
                  height: 240,
                  borderRadius: "50%",
                  border: "1px solid rgba(0,229,255,0.4)",
                  boxShadow: "0 0 40px rgba(0,229,255,0.2)",
                }}
                initial={{ scale: 0.3, opacity: 0 }}
                animate={{ scale: [0.3, 2.0, 3.0], opacity: [0, 0.5, 0] }}
                transition={{ duration: 2.0, ease: "easeOut" }}
              />
            )}

            {/* THE DEFINITIVE 4K WORDMARK ASSET */}
            {showWordmark && (
              <motion.img
                src={WORDMARK_URL}
                alt="MILLI"
                initial={{ opacity: 0, scale: 0.85, filter: "blur(8px) brightness(1.3)" }}
                animate={{ opacity: 1, scale: 1, filter: "blur(0px) brightness(1)" }}
                transition={{ duration: 1.0, ease: [0.16, 1, 0.3, 1] }}
                style={{
                  width: "72%",
                  maxWidth: 380,
                  height: "auto",
                  objectFit: "contain",
                  filter: "drop-shadow(0 0 40px rgba(0,229,255,0.35)) drop-shadow(0 4px 16px rgba(0,0,0,0.7))",
                  zIndex: 1,
                }}
                data-testid="splash-wordmark"
              />
            )}

            {/* Subtle tagline below wordmark */}
            {showWordmark && (
              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
                style={{
                  marginTop: 24,
                  fontSize: 11,
                  fontWeight: 600,
                  textTransform: "uppercase",
                  letterSpacing: "0.32em",
                  color: "#00E5FF",
                  textShadow: "0 0 12px rgba(0,229,255,0.5)",
                  fontFamily: "monospace",
                  zIndex: 1,
                }}
              >
                Money, Made Intelligent.
              </motion.div>
            )}

            {/* Bottom pulse indicator */}
            {showWordmark && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.6 }}
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
