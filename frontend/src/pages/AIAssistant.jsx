import { useRef, useState } from "react";
import { API_BASE } from "@/lib/api";
import { ArrowRight, Lightning, SpeakerHigh, SpeakerSlash } from "@phosphor-icons/react";
import WeeboAvatar from "@/components/WeeboAvatar";
import useWeeboVoice from "@/hooks/useWeeboVoice";

const SUGGESTIONS = [
  "Can I deduct my phone bill if I use it for delivery?",
  "How do quarterly estimated taxes work?",
  "What records do I need to keep for IRS audits?",
  "Standard mileage vs. actual expense — which is better?",
];

export default function AIAssistant() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [streaming, setStreaming] = useState(false);
  const [sessionId] = useState(() => `s-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`);
  const endRef = useRef(null);

  async function send(text) {
    const q = text ?? input;
    if (!q.trim() || streaming) return;
    setInput("");
    const userMsg = { id: `u-${Date.now()}`, role: "user", content: q };
    setMessages((m) => [...m, userMsg, { id: `a-${Date.now()}`, role: "assistant", content: "" }]);
    setStreaming(true);

    try {
      const res = await fetch(`${API_BASE}/ai/chat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("milli_token")}`,
        },
        body: JSON.stringify({ message: q, session_id: sessionId }),
      });
      if (!res.ok || !res.body) throw new Error("Failed to start stream");
      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";
        for (const line of lines) {
          if (!line.startsWith("data: ")) continue;
          const chunk = line.slice(6);
          if (chunk === "[DONE]") continue;
          if (chunk.startsWith("[ERROR]")) {
            setMessages((m) => {
              const copy = [...m];
              copy[copy.length - 1] = { role: "assistant", content: chunk };
              return copy;
            });
            break;
          }
          setMessages((m) => {
            const copy = [...m];
            copy[copy.length - 1] = {
              role: "assistant",
              content: (copy[copy.length - 1].content || "") + chunk,
            };
            return copy;
          });
          endRef.current?.scrollIntoView({ behavior: "smooth" });
        }
      }
    } catch (e) {
      setMessages((m) => {
        const copy = [...m];
        copy[copy.length - 1] = { role: "assistant", content: `Error: ${e.message}` };
        return copy;
      });
    } finally {
      setStreaming(false);
    }
  }

  // Weebo state — reacts to streaming + last assistant content
  const lastAssistant = [...messages].reverse().find((m) => m.role === "assistant");
  const lastAssistantText = (lastAssistant && lastAssistant.content) || "";

  // Voice — plays TTS of the final answer once streaming ends.
  const { speaking, muted, toggleMute } = useWeeboVoice(lastAssistantText, {
    streaming,
    autoplay: true,
  });

  const weeboState = streaming
    ? (lastAssistantText ? "speaking" : "thinking")
    : (speaking ? "speaking" : "idle");

  return (
    <div className="p-4 sm:p-6 max-w-4xl mx-auto">
      {/* ============ Weebo hero — large animated character at top ============ */}
      <div
        className="relative rounded-3xl overflow-hidden mb-4 border border-white/[0.08]"
        style={{
          background:
            "radial-gradient(120% 80% at 50% 0%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 40%, rgba(0,0,0,0) 70%), #05070A",
        }}
        data-testid="weebo-hero"
      >
        {/* Grid backdrop like Weebo's lab */}
        <div
          aria-hidden
          className="absolute inset-0 opacity-[0.18] pointer-events-none"
          style={{
            backgroundImage:
              "linear-gradient(rgba(0,229,255,0.35) 1px, transparent 1px), linear-gradient(90deg, rgba(0,229,255,0.35) 1px, transparent 1px)",
            backgroundSize: "28px 28px",
            maskImage: "radial-gradient(ellipse at center, black 40%, transparent 75%)",
            WebkitMaskImage: "radial-gradient(ellipse at center, black 40%, transparent 75%)",
          }}
        />
        {/* Scan-line sweep */}
        <div aria-hidden className="absolute inset-0 pointer-events-none overflow-hidden">
          <div
            className="absolute inset-x-0 h-[2px] animate-[weebo-sweep_3.2s_linear_infinite]"
            style={{
              background:
                "linear-gradient(90deg, transparent, rgba(0,229,255,0.65) 50%, transparent)",
            }}
          />
        </div>
        <div className="relative flex flex-col items-center pt-6 pb-6 px-4">
          {/* Mute toggle — top-right corner */}
          <button
            data-testid="weebo-mute-toggle"
            onClick={toggleMute}
            aria-label={muted ? "Unmute Weebo" : "Mute Weebo"}
            className="absolute top-3 right-3 p-2 rounded-full border border-white/10 bg-black/40 backdrop-blur-md text-zinc-300 hover:text-volt active:scale-95 transition z-10"
          >
            {muted ? <SpeakerSlash size={14} weight="bold" /> : <SpeakerHigh size={14} weight="bold" />}
          </button>

          {/* Roaming stage — she wanders across this area */}
          <div className="w-full flex justify-center">
            <WeeboAvatar size={180} state={weeboState} />
          </div>

          <div className="h-4 mt-2 text-volt font-mono text-[10px] uppercase tracking-[0.34em]">
            {weeboState === "thinking" ? "// analyzing..." :
             weeboState === "speaking" ? "// responding" :
             ""}
          </div>
          <h1 className="font-display chrome-text text-2xl tracking-tight mt-1">
            Ask me anything, driver.
          </h1>
          <p className="text-zinc-400 text-[13px] text-center mt-2 max-w-xs leading-relaxed">
            Schedule C. Quarterlies. Deductions. Mileage tricks. I speak fluent IRS.
          </p>
        </div>
      </div>

      <div className="milli-card flex flex-col" style={{ minHeight: "50vh" }}>
        <div className="flex-1 p-4 sm:p-6 space-y-5 overflow-y-auto">
          {messages.length === 0 && (
            <div className="text-center py-6">
              <div className="font-display font-bold text-lg">Try one of these</div>
              <div className="mt-4 grid gap-2 max-w-lg mx-auto">
                {SUGGESTIONS.map((s, i) => (
                  <button
                    key={i}
                    data-testid={`ai-suggestion-${i}`}
                    onClick={() => send(s)}
                    className="text-left text-sm border border-hairline rounded-xl p-3 hover:border-volt transition-colors bg-white/[0.02]"
                  >{s}</button>
                ))}
              </div>
            </div>
          )}
          {messages.map((m, i) => (
            <div key={m.id || `msg-${i}`} className={`flex gap-3 ${m.role === "user" ? "justify-end" : ""}`}>
              {m.role === "assistant" && (
                <div className="flex-shrink-0"><WeeboAvatar size={28} state="idle" /></div>
              )}
              <div
                data-testid={`ai-message-${m.role}-${i}`}
                className={`max-w-[82%] px-4 py-3 text-[14px] leading-relaxed whitespace-pre-wrap rounded-2xl ${
                  m.role === "user"
                    ? "bg-volt text-obsidian font-medium"
                    : "border border-hairline bg-white/[0.02]"
                }`}
              >
                {m.content || (streaming && i === messages.length - 1 ? <Lightning className="animate-pulse text-volt" /> : "...")}
              </div>
            </div>
          ))}
          <div ref={endRef} />
        </div>
        <form
          onSubmit={(e) => { e.preventDefault(); send(); }}
          className="border-t border-hairline p-4 flex gap-2"
        >
          <input
            data-testid="ai-input"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            disabled={streaming}
            placeholder="Ask about deductions, quarterlies, mileage..."
            className="flex-1 bg-transparent border border-hairline px-4 py-3 font-mono text-sm focus:outline-none focus:border-volt rounded-xl"
          />
          <button
            data-testid="ai-send"
            type="submit"
            disabled={streaming || !input.trim()}
            className="btn-volt px-5 py-3 font-bold uppercase tracking-wider text-sm inline-flex items-center gap-2 disabled:opacity-50 rounded-xl"
          >
            {streaming ? "..." : <>Send <ArrowRight weight="bold" /></>}
          </button>
        </form>
      </div>

      <div className="text-xs text-zinc-500 mt-3 font-mono text-center">
        MILLI AI is informational only — not a substitute for a CPA.
      </div>
    </div>
  );
}
