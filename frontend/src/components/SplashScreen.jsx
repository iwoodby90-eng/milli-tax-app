import { useEffect, useMemo, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";
import MilliLogo from "@/components/MilliLogo";

/**
 * Fast, local, accessibility-aware launch transition.
 *
 * The native LaunchScreen handles the actual cold-start frame. This component
 * provides only a short brand handoff while React initializes; it never loads
 * remote media and never blocks returning users behind a long animation.
 */
export default function SplashScreen({ onDone }) {
  const prefersReducedMotion = useReducedMotion();
  const [visible, setVisible] = useState(true);

  const timings = useMemo(
    () =>
      prefersReducedMotion
        ? { hold: 150, fade: 0.01 }
        : { hold: 650, fade: 0.28 },
    [prefersReducedMotion],
  );

  useEffect(() => {
    let finishTimer;
    const holdTimer = window.setTimeout(() => {
      setVisible(false);
      finishTimer = window.setTimeout(
        () => onDone?.(),
        Math.ceil(timings.fade * 1000),
      );
    }, timings.hold);

    return () => {
      window.clearTimeout(holdTimer);
      window.clearTimeout(finishTimer);
    };
  }, [onDone, timings.fade, timings.hold]);

  return (
    <motion.div
      role="status"
      aria-label="Opening Milli"
      aria-live="polite"
      data-testid="splash-screen"
      initial={{ opacity: 1 }}
      animate={{ opacity: visible ? 1 : 0 }}
      transition={{ duration: timings.fade, ease: "easeOut" }}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 100000,
        display: "grid",
        placeItems: "center",
        background:
          "radial-gradient(circle at 50% 42%, rgba(0,229,255,0.10), transparent 34%), #050607",
        pointerEvents: visible ? "auto" : "none",
      }}
    >
      <motion.div
        initial={prefersReducedMotion ? false : { opacity: 0, scale: 0.94 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: prefersReducedMotion ? 0 : 0.35, ease: [0.16, 1, 0.3, 1] }}
        style={{ display: "flex", flexDirection: "column", alignItems: "center" }}
      >
        <MilliLogo size={88} />
        <div
          style={{
            marginTop: 18,
            color: "#F7FAFC",
            fontSize: 22,
            fontWeight: 700,
            letterSpacing: "0.28em",
            paddingLeft: "0.28em",
          }}
        >
          MILLI
        </div>
        <div
          style={{
            marginTop: 9,
            color: "rgba(255,255,255,0.62)",
            fontSize: 11,
            fontWeight: 600,
            letterSpacing: "0.14em",
            textTransform: "uppercase",
          }}
        >
          Money, made intelligent.
        </div>
      </motion.div>
    </motion.div>
  );
}
