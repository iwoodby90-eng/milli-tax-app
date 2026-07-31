import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import MilliLogo from "./MilliLogo";

/**
 * SplashScreen v1.9.5 — Cinematic Video Splash.
 *
 * Plays the "White Flash Take-off" video full-screen on launch.
 * Zero-touch: auto-transitions when video ends or after 5s (whichever first).
 * Fallback: if video fails to load, shows a CSS animation instead.
 */

const VIDEO_URL = "https://customer-assets-7cd3h4nn.emergentagent.net/jobs/390f651f-e7a4-4197-9ea8-79b7db44303a/videos/4e47ac04c33127f9.mp4";
const MAX_DURATION = 5500; // failsafe: auto-dismiss after 5.5s even if video stalls

export default function SplashScreen({ onDone }) {
  const [exiting, setExiting] = useState(false);
  const [videoLoaded, setVideoLoaded] = useState(false);
  const [videoFailed, setVideoFailed] = useState(false);
  const [showLogo, setShowLogo] = useState(false);
  const videoRef = useRef(null);
  const timerRef = useRef(null);

  // Failsafe timer: always dismiss after MAX_DURATION
  useEffect(() => {
    timerRef.current = setTimeout(() => dismiss(), MAX_DURATION);
    return () => clearTimeout(timerRef.current);
  }, []);

  // Show logo near end of video or on fallback
  useEffect(() => {
    const logoTimer = setTimeout(() => setShowLogo(true), 3800);
    return () => clearTimeout(logoTimer);
  }, []);

  const dismiss = () => {
    if (exiting) return;
    setExiting(true);
    setTimeout(() => onDone?.(), 600);
  };

  const handleVideoEnd = () => dismiss();
  
  const handleVideoLoaded = () => {
    setVideoLoaded(true);
    // Attempt autoplay
    videoRef.current?.play().catch(() => {
      // Autoplay blocked — use fallback
      setVideoFailed(true);
    });
  };

  const handleVideoError = () => setVideoFailed(true);

  return (
    <AnimatePresence>
      {!exiting ? (
        <motion.div
          key="splash-screen"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.6, ease: "easeInOut" }}
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 100000,
            background: "#050607",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            overflow: "hidden",
          }}
        >
          {/* === VIDEO LAYER === */}
          {!videoFailed && (
            <video
              ref={videoRef}
              src={VIDEO_URL}
              muted
              playsInline
              preload="auto"
              onLoadedData={handleVideoLoaded}
              onEnded={handleVideoEnd}
              onError={handleVideoError}
              style={{
                position: "absolute",
                inset: 0,
                width: "100%",
                height: "100%",
                objectFit: "cover",
                opacity: videoLoaded ? 1 : 0,
                transition: "opacity 0.3s",
              }}
            />
          )}

          {/* === FALLBACK: CSS Animation (if video fails) === */}
          {videoFailed && (
            <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
              {/* Streaking light lines */}
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
              {/* Central bloom */}
              <motion.div
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: [0, 0.8, 0], scale: [0, 3, 4] }}
                transition={{ duration: 2, delay: 2.5 }}
                style={{
                  position: "absolute",
                  top: "50%", left: "50%",
                  width: 100, height: 100,
                  marginLeft: -50, marginTop: -50,
                  borderRadius: "50%",
                  background: "radial-gradient(circle, rgba(0,229,255,0.5), transparent 70%)",
                }}
              />
            </div>
          )}

          {/* === LOGO REVEAL (appears at 3.8s, overlaid on video ending) === */}
          <motion.div
            initial={{ opacity: 0, scale: 0.7, filter: "blur(12px)" }}
            animate={{
              opacity: showLogo ? 1 : 0,
              scale: showLogo ? 1 : 0.7,
              filter: showLogo ? "blur(0px)" : "blur(12px)",
            }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            style={{
              position: "relative",
              zIndex: 10,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 14,
            }}
          >
            <MilliLogo size={90} />
            <motion.h1
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: showLogo ? 1 : 0, y: showLogo ? 0 : 8 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              style={{
                fontSize: 28,
                fontWeight: 700,
                letterSpacing: "0.2em",
                background: "linear-gradient(135deg, #9CA3AF, #F9FAFB, #D1D5DB)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                backgroundClip: "text",
                margin: 0,
                fontFamily: '-apple-system, "SF Pro Display", "Sora", system-ui, sans-serif',
              }}
            >
              MILLI
            </motion.h1>
          </motion.div>
        </motion.div>
      ) : (
        /* Exit: brief black frame to clean transition */
        <motion.div
          key="splash-exit"
          initial={{ opacity: 1 }}
          animate={{ opacity: 0 }}
          transition={{ duration: 0.5 }}
          style={{
            position: "fixed", inset: 0, zIndex: 99999,
            background: "#050607",
          }}
        />
      )}
    </AnimatePresence>
  );
}
