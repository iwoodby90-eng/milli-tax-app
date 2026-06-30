import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { Play, DownloadSimple, ArrowLeft, Sparkle, FilmReel } from "@phosphor-icons/react";
import { api } from "@/lib/api";
import { toast } from "sonner";

const BACKEND = process.env.REACT_APP_BACKEND_URL;

export default function MarketingStudio() {
  const [clips, setClips] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);

  async function load() {
    try {
      const { data } = await api.get("/marketing/videos");
      setClips(data.clips || []);
    } catch (e) {
      toast.error("Could not load marketing videos");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // Auto-refresh while any clip is still rendering.
    const id = setInterval(() => {
      setClips((current) => {
        if (current.some((c) => c.status === "running" || c.status === "queued")) {
          load();
        }
        return current;
      });
    }, 8000);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="min-h-screen bg-obsidian text-white">
      {/* Header */}
      <header className="border-b border-hairline">
        <div className="max-w-7xl mx-auto px-6 lg:px-10 py-6 flex items-center justify-between">
          <Link to="/" className="inline-flex items-center gap-2 text-sm font-mono uppercase tracking-widest text-zinc-400 hover:text-white">
            <ArrowLeft size={14} weight="bold" /> Back
          </Link>
          <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// Marketing Studio</div>
          <div className="w-20" />
        </div>
      </header>

      {/* Hero */}
      <section className="max-w-7xl mx-auto px-6 lg:px-10 pt-16 pb-12">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
        >
          <div className="inline-flex items-center gap-2 text-volt font-mono text-xs uppercase tracking-[0.3em] mb-4">
            <FilmReel size={14} weight="bold" /> Generated with Sora 2
          </div>
          <h1 className="font-display font-black text-5xl lg:text-7xl tracking-tighter leading-none">
            Milli, in motion.
          </h1>
          <p className="text-zinc-400 mt-4 max-w-2xl text-lg">
            Five cinematic spots — vertical for TikTok &amp; Reels, landscape for YouTube &amp; the website hero.
            Stream, download, drop into your edit.
          </p>
        </motion.div>
      </section>

      {/* Clip grid */}
      <section className="max-w-7xl mx-auto px-6 lg:px-10 pb-24">
        {loading ? (
          <div className="text-zinc-500 font-mono text-sm">Loading clips…</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {clips.map((c, i) => (
              <ClipCard
                key={c.id}
                clip={c}
                index={i}
                onPlay={() => setSelected(c)}
              />
            ))}
          </div>
        )}

        <div className="mt-12 flex items-center gap-3 text-xs font-mono text-zinc-500">
          <Sparkle size={14} weight="fill" className="text-volt" />
          Generated locally on this server — no third-party hosting. Right-click any clip to save.
        </div>
      </section>

      {/* Player modal */}
      {selected && (
        <Player clip={selected} onClose={() => setSelected(null)} />
      )}
    </div>
  );
}

function ClipCard({ clip, index, onPlay }) {
  const isVertical = clip.orientation === "vertical";
  const aspect = isVertical ? "aspect-[9/16]" : "aspect-video";
  const fullUrl = clip.url ? `${BACKEND}${clip.url}` : null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: index * 0.08, ease: [0.16, 1, 0.3, 1] }}
      className="milli-card overflow-hidden group"
      data-testid={`marketing-clip-${clip.id}`}
    >
      <div className={`relative bg-black ${aspect} overflow-hidden`}>
        {clip.ready && fullUrl ? (
          <>
            <video
              src={fullUrl}
              muted
              loop
              playsInline
              autoPlay
              className="absolute inset-0 w-full h-full object-cover opacity-90 group-hover:opacity-100 transition-opacity"
              data-testid={`marketing-clip-preview-${clip.id}`}
            />
            <button
              onClick={onPlay}
              data-testid={`marketing-clip-play-${clip.id}`}
              className="absolute inset-0 flex items-center justify-center bg-black/30 group-hover:bg-black/10 transition-colors"
            >
              <span className="w-16 h-16 rounded-full bg-volt text-obsidian flex items-center justify-center shadow-[0_0_40px_rgba(19,216,209,0.5)]">
                <Play size={26} weight="fill" />
              </span>
            </button>
          </>
        ) : (
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center px-6">
            <div className="w-10 h-10 border-2 border-volt border-t-transparent rounded-full animate-spin mb-3" />
            <div className="font-mono text-xs uppercase tracking-[0.2em] text-zinc-400">
              Rendering with Sora 2…
            </div>
            <div className="text-[10px] font-mono text-zinc-600 mt-1">
              Typically 1–3 min · auto-refreshing
            </div>
          </div>
        )}

        {/* Orientation tag */}
        <div className="absolute top-3 left-3 px-2 py-1 bg-black/70 backdrop-blur text-[10px] font-mono uppercase tracking-widest border border-hairline">
          {isVertical ? "9:16 · Reels / TikTok" : "16:9 · YouTube / Web"}
        </div>
      </div>

      <div className="p-5 flex items-center justify-between gap-3">
        <div className="min-w-0">
          <div className="font-display font-bold text-base truncate">{clip.title}</div>
          <div className="text-[10px] font-mono uppercase tracking-[0.2em] text-zinc-500 mt-1">
            {clip.duration ? `${clip.duration}s` : "—"} · {clip.size || "—"}
          </div>
        </div>
        {clip.ready && fullUrl && (
          <a
            href={fullUrl}
            download={`milli-${clip.id}.mp4`}
            data-testid={`marketing-clip-download-${clip.id}`}
            className="px-3 py-2 border border-hairline text-[10px] font-bold uppercase tracking-wider inline-flex items-center gap-2 hover:border-volt hover:text-volt"
          >
            <DownloadSimple size={12} weight="bold" /> MP4
          </a>
        )}
      </div>
    </motion.div>
  );
}

function Player({ clip, onClose }) {
  const isVertical = clip.orientation === "vertical";
  const fullUrl = `${BACKEND}${clip.url}`;
  return (
    <div
      className="fixed inset-0 z-50 bg-black/95 backdrop-blur flex items-center justify-center p-4"
      onClick={onClose}
      data-testid="marketing-player"
    >
      <div
        className={`relative ${isVertical ? "h-[90vh] aspect-[9/16]" : "w-full max-w-5xl aspect-video"}`}
        onClick={(e) => e.stopPropagation()}
      >
        <video
          src={fullUrl}
          controls
          autoPlay
          className="w-full h-full object-contain"
        />
        <button
          onClick={onClose}
          data-testid="marketing-player-close"
          className="absolute -top-12 right-0 text-xs font-mono uppercase tracking-widest text-zinc-400 hover:text-white"
        >
          Close ✕
        </button>
      </div>
    </div>
  );
}
