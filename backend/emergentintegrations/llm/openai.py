"""OpenAI text-to-speech adapter matching Milli's legacy interface."""
from __future__ import annotations

import os

import httpx


class OpenAITextToSpeech:
    def __init__(self, api_key: str) -> None:
        self.api_key = os.environ.get("OPENAI_API_KEY") or api_key

    async def generate_speech(
        self,
        *,
        text: str,
        model: str = "tts-1",
        voice: str = "shimmer",
        speed: float = 1.0,
    ) -> bytes:
        if not self.api_key or self.api_key == "not-configured":
            raise RuntimeError("OpenAI TTS is not configured; set OPENAI_API_KEY")

        async with httpx.AsyncClient(timeout=90) as client:
            response = await client.post(
                "https://api.openai.com/v1/audio/speech",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model,
                    "voice": voice,
                    "input": text,
                    "speed": max(0.25, min(float(speed), 4.0)),
                    "response_format": "mp3",
                },
            )
        if response.status_code >= 400:
            raise RuntimeError(
                f"OpenAI TTS failed ({response.status_code}): {response.text[:500]}"
            )
        return response.content
