import { useRef, useState } from "react";
import { API_BASE } from "@/lib/api";
import { Robot, ArrowRight, Lightning } from "@phosphor-icons/react";

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
    const userMsg = { role: "user", content: q };
    setMessages((m) => [...m, userMsg, { role: "assistant", content: "" }]);
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

  return (
    <div className="p-6 lg:p-10 max-w-4xl">
      <div className="mb-8">
        <div className="text-volt font-mono text-xs uppercase tracking-[0.3em]">// AI Assistant</div>
        <h1 className="font-display font-black text-4xl tracking-tighter mt-1">MILLI AI</h1>
        <p className="text-zinc-400 mt-1">Ask anything about driver taxes — Schedule C, deductions, quarterlies.</p>
      </div>

      <div className="milli-card flex flex-col" style={{ minHeight: "60vh" }}>
        <div className="flex-1 p-6 space-y-5 overflow-y-auto">
          {messages.length === 0 && (
            <div className="text-center py-10">
              <div className="w-16 h-16 bg-volt text-obsidian flex items-center justify-center mx-auto">
                <Robot size={32} weight="fill" />
              </div>
              <div className="font-display font-bold mt-4 text-xl">What do you want to know?</div>
              <div className="text-sm text-zinc-500 mt-2">Try one of these:</div>
              <div className="mt-6 grid sm:grid-cols-2 gap-2 max-w-lg mx-auto">
                {SUGGESTIONS.map((s, i) => (
                  <button
                    key={i}
                    data-testid={`ai-suggestion-${i}`}
                    onClick={() => send(s)}
                    className="text-left text-sm border border-hairline p-3 hover:border-volt transition-colors"
                  >{s}</button>
                ))}
              </div>
            </div>
          )}
          {messages.map((m, i) => (
            <div key={i} className={`flex gap-3 ${m.role === "user" ? "justify-end" : ""}`}>
              {m.role === "assistant" && (
                <div className="w-8 h-8 bg-volt text-obsidian flex items-center justify-center flex-shrink-0">
                  <Robot size={16} weight="bold" />
                </div>
              )}
              <div
                data-testid={`ai-message-${m.role}-${i}`}
                className={`max-w-[80%] px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap ${
                  m.role === "user"
                    ? "bg-volt text-obsidian font-medium"
                    : "border border-hairline bg-white/[0.02]"
                }`}
              >
                {m.content || (streaming && i === messages.length - 1 ? <Lightning className="animate-pulse" /> : "...")}
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
            className="flex-1 bg-transparent border border-hairline px-4 py-3 font-mono text-sm focus:outline-none focus:border-volt"
          />
          <button
            data-testid="ai-send"
            type="submit"
            disabled={streaming || !input.trim()}
            className="btn-volt px-5 py-3 font-bold uppercase tracking-wider text-sm inline-flex items-center gap-2 disabled:opacity-50"
          >
            {streaming ? "..." : <>Send <ArrowRight weight="bold" /></>}
          </button>
        </form>
      </div>

      <div className="text-xs text-zinc-500 mt-3 font-mono">
        MILLI AI is informational only — not a substitute for a CPA.
      </div>
    </div>
  );
}
