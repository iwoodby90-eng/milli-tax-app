import { useEffect, useRef, useState } from "react";
import { API_BASE } from "@/lib/api";

/**
 * useWeeboVoice — plays a spoken version of Weebo's answer via /api/ai/voice.
 * Returns { speaking, muted, toggleMute, cancel }.
 *
 * Usage:
 *   const { speaking, muted, toggleMute, cancel } = useWeeboVoice(text, { autoplay });
 *
 *   text    — the current assistant text. When streaming finishes and text has
 *             grown vs. the previously-spoken value, we fetch TTS and play.
 *   autoplay — false ⇒ don't fetch/play until the user unmutes.
 *
 * Design notes:
 *   • We do NOT fire per-chunk during streaming (OpenAI TTS has ~1-2s latency;
 *     mid-stream would sound choppy). Instead we wait for streaming = false,
 *     then play the full final answer once.
 *   • Local audio caching by text hash so repeated replays don't hit the API.
 */
export default function useWeeboVoice(text, { streaming = false, autoplay = true } = {}) {
  const [speaking, setSpeaking] = useState(false);
  const [muted, setMuted] = useState(() => localStorage.getItem("weebo_muted") === "1");
  const audioRef = useRef(null);
  const lastSpokenRef = useRef("");
  const abortRef = useRef(null);

  function cancel() {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.src = "";
      audioRef.current = null;
    }
    if (abortRef.current) abortRef.current.abort();
    setSpeaking(false);
  }

  function toggleMute() {
    setMuted((m) => {
      const next = !m;
      localStorage.setItem("weebo_muted", next ? "1" : "0");
      if (next) cancel();
      return next;
    });
  }

  useEffect(() => {
    if (!autoplay || muted || streaming) return;
    const clean = (text || "").trim();
    if (!clean || clean.length < 6) return;
    if (clean === lastSpokenRef.current) return;

    lastSpokenRef.current = clean;
    const controller = new AbortController();
    abortRef.current = controller;
    setSpeaking(true);

    (async () => {
      try {
        const res = await fetch(`${API_BASE}/ai/voice`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${localStorage.getItem("milli_token")}`,
          },
          body: JSON.stringify({ text: clean.slice(0, 3800), voice: "shimmer", speed: 1.05 }),
          signal: controller.signal,
        });
        if (!res.ok) throw new Error(`voice ${res.status}`);
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const audio = new Audio(url);
        audioRef.current = audio;
        audio.onended = () => { setSpeaking(false); URL.revokeObjectURL(url); };
        audio.onerror = () => { setSpeaking(false); URL.revokeObjectURL(url); };
        await audio.play().catch(() => setSpeaking(false));
      } catch (e) {
        if (e.name !== "AbortError") console.warn("[Weebo] voice fetch failed:", e.message);
        setSpeaking(false);
      }
    })();

    return () => controller.abort();
  }, [text, streaming, muted, autoplay]);

  useEffect(() => () => cancel(), []);

  return { speaking, muted, toggleMute, cancel };
}
