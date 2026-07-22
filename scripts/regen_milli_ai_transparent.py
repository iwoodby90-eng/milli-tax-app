"""Regenerate Milli AI with a transparent background using Gemini Nano Banana.
Reads /app/frontend/public/weebo/milli-ai.png as the reference and asks the model
to isolate the character on a transparent background.
"""
import asyncio, os, base64, sys
from pathlib import Path
from dotenv import load_dotenv
from emergentintegrations.llm.chat import LlmChat, UserMessage, ImageContent

load_dotenv("/app/backend/.env")

SRC = Path("/app/frontend/public/weebo/milli-ai.png")
OUT = Path("/app/frontend/public/weebo/milli-ai-transparent.png")

async def main():
    key = os.getenv("EMERGENT_LLM_KEY")
    if not key:
        print("no EMERGENT_LLM_KEY"); sys.exit(1)
    ref_bytes = SRC.read_bytes()
    ref_b64 = base64.b64encode(ref_bytes).decode("utf-8")

    chat = LlmChat(
        api_key=key,
        session_id="milli-ai-transparent",
        system_message="You are an image-editing assistant.",
    ).with_model("gemini", "gemini-3.1-flash-image-preview").with_params(modalities=["image", "text"])

    prompt = (
        "Take the chibi companion robot mascot in this reference image (the character with the "
        "big glowing cyan cartoon eyes, chrome and black body panels, and the small M emblem on the "
        "side of the head). Isolate ONLY the character on a fully transparent background. "
        "Remove all background elements, particles, grid lines, light streaks, and the portal glow. "
        "Do not add any background. Keep the character exactly as illustrated — same proportions, "
        "same pose, same colors, same details, same lighting on the character. Output a clean "
        "PNG with alpha channel showing only the character floating on transparent."
    )

    msg = UserMessage(text=prompt, file_contents=[ImageContent(ref_b64)])
    text, images = await chat.send_message_multimodal_response(msg)
    print("text reply:", (text or "")[:200])
    if not images:
        print("No images returned"); sys.exit(2)
    img_bytes = base64.b64decode(images[0]["data"])
    OUT.write_bytes(img_bytes)
    print("wrote", OUT, len(img_bytes), "bytes")

if __name__ == "__main__":
    asyncio.run(main())
