import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";

/**
 * SplashScreen v1.9.6 — Definitive Cinematic Splash.
 *
 * Plays the 'Perfect' baked video (~10s) full-screen, zero touch.
 * On video end: seamless cross-fade to static cyan-gradient wordmark hold frame.
 * Holds wordmark for 2.5s, then auto-fades into Login. Zero touch required.
 * Fallback: if video fails, CSS streaks + wordmark hold, then same exit flow.
 */

const VIDEO_URL =
  "https://customer-assets-7cd3h4nn.emergentagent.net/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/videos/319e22928c08311a.mp4";

const WORDMARK_URL =
  "https://static.prod-images.emergentagent.com/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/images/61ceebd0bc76de271d00f038dea4e525bf651e63f42c027195dfa419dbfc3dc9.jpeg";

const WORDMARK_HOLD_MS = 2500;  // hold the wordmark frame before exiting
const CROSSFADE_DURATION = 0.8; // video→wordmark crossfade in seconds
const MAX_DURATION = 14000;     // failsafe: force-advance after 14s

export default function SplashScreen({ onDone }) {
  const [videoLoaded, setVideoLoaded] = useState(false);
  const [videoFailed, setVideoFailed] = useState(false);
  const [videoEnded, setVideoEnded] = useState(false);
  const [exiting, setExiting] = useState(false);
  const videoRef = useRef(null);
  const exitScheduled = useRef(false);

  // Schedules the full-screen fade-out → onDone, called once only.
  const triggerExit = () => {
    if (exitScheduled.current) return;
    exitScheduled.current = true;
    setTimeout(() => {
      setExiting(true);
      setTimeout(() => onDone?.(), 700);
    }, WORDMARK_HOLD_MS);
  };

  // Failsafe: force-advance if the video never ends
  useEffect(() => {
    const t = setTimeout(() => {
      setVideoEnded(true);
      triggerExit();
    }, MAX_DURATION);
    return () => clearTimeout(t);
  }, []);

  const handleVideoLoaded = () => {
    setVideoLoaded(true);
    videoRef.current?.play().catch(() => {
      // Autoplay blocked — show fallback immediately
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

  return (
    <AnimatePresence>
      {!exiting && (
        <motion.div
          key="splash-screen"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.7, ease: "easeInOut" }}
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 100000,
            background: "#050607",
            overflow: "hidden",
          }}
        >
          {/* === VIDEO LAYER — fades out as video ends === */}
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

          {/* === WORDMARK HOLD FRAME — cross-fades in as video fades out === */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: videoEnded ? 1 : 0 }}
            transition={{ duration: CROSSFADE_DURATION, ease: "easeInOut" }}
            style={{
              position: "absolute",
              inset: 0,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              background: "#050607",
            }}
          >
            <img
              src={WORDMARK_URL}
              alt="Milli"
              draggable={false}
              style={{
                maxWidth: "72%",
                maxHeight: "38%",
                objectFit: "contain",
                userSelect: "none",
                WebkitUserSelect: "none",
                pointerEvents: "none",
              }}
            />
          </motion.div>

          {/* === FALLBACK CSS ANIMATION (if video fails to load) === */}
          {videoFailed && (
            <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
              {Array.from({ length: 8 }).map((_, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, scaleX: 0 }}
                  animate={{ opacity: [0, 0.6, 0], scaleX: [0, 1.5, 0] }}
                  transition={{ duration: 2, delay: i * 0.15, repeat: 1 }}
                  style={{
                    position: "absolute",
                    left: "20%",
                    top: `${25 + i * 7}%`,
                    width: "60%",
                    height: "1px",
                    background: `linear-gradient(90deg, transparent, rgba(0,229,255,${0.3 + i * 0.05}), transparent)`,
                    transformOrigin: "center",
                  }}
                />
              ))}
              <motion.div
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: [0, 0.8, 0], scale: [0, 3, 4] }}
                transition={{ duration: 2, delay: 2.5 }}
                style={{
                  position: "absolute",
                  top: "50%",
                  left: "50%",
                  width: 100,
                  height: 100,
                  marginLeft: -50,
                  marginTop: -50,
                  borderRadius: "50%",
                  background:
                    "radial-gradient(circle, rgba(0,229,255,0.5), transparent 70%)",
                }}
              />
            </div>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
