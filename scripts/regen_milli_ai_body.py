"""Generate a small-body version of the Milli AI mascot using Gemini Nano Banana
with the existing cutout as reference. Saves to /app/frontend/public/weebo/.
"""
import asyncio, os, base64, sys
from pathlib import Path
from dotenv import load_dotenv
from emergentintegrations.llm.chat import LlmChat, UserMessage, ImageContent

load_dotenv("/app/backend/.env")

SRC = Path("/app/frontend/public/weebo/milli-ai-cutout.png")
OUT = Path("/app/frontend/public/weebo/milli-ai-body.png")

async def main():
    key = os.getenv("EMERGENT_LLM_KEY")
    if not key:
        print("no EMERGENT_LLM_KEY"); sys.exit(1)
    ref_b64 = base64.b64encode(SRC.read_bytes()).decode("utf-8")
    chat = LlmChat(
        api_key=key,
        session_id="milli-ai-body",
        system_message="You are a professional character illustrator.",
    ).with_model("gemini", "gemini-3.1-flash-image-preview").with_params(modalities=["image", "text"])

    prompt = (
        "Take the exact chibi companion-robot character shown (cyan glowing "
        "eyes, chrome/silver body panels, small M emblem on temple, cyan V "
        "chest accent, floating pauldrons). Add a SMALL cute lower body: "
        "two short chrome legs and small round feet, matching the same "
        "materials and colors. Keep the head, face, and torso proportions "
        "IDENTICAL. Small body only — think chibi/kawaii, not tall. "
        "Preserve the same lighting, chrome reflections, cyan accents, "
        "and cinematic feel. Fully TRANSPARENT background (alpha PNG). "
        "The character should stand naturally, tiny hover glow under the feet."
    )
    msg = UserMessage(text=prompt, file_contents=[ImageContent(ref_b64)])
    _text, images = await chat.send_message_multimodal_response(msg)
    if not images:
        print("No image returned"); sys.exit(2)
    OUT.write_bytes(base64.b64decode(images[0]["data"]))
    print("wrote", OUT, OUT.stat().st_size, "bytes")

if __name__ == "__main__":
    asyncio.run(main())
