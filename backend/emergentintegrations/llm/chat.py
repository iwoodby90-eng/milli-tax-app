"""Gemini streaming adapter matching Milli's legacy chat interface."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from typing import AsyncIterator

import httpx


@dataclass(slots=True)
class ImageContent:
    image_base64: str
    mime_type: str = "image/jpeg"


@dataclass(slots=True)
class UserMessage:
    text: str
    file_contents: list[ImageContent] = field(default_factory=list)


@dataclass(slots=True)
class TextDelta:
    content: str


@dataclass(slots=True)
class StreamDone:
    reason: str = "complete"


class LlmChat:
    def __init__(self, api_key: str, session_id: str, system_message: str = "") -> None:
        self.api_key = os.environ.get("GEMINI_API_KEY") or api_key
        self.session_id = session_id
        self.system_message = system_message
        self.provider = "gemini"
        self.model = os.environ.get("GEMINI_MODEL", "gemini-3-flash-preview")

    def with_model(self, provider: str, model: str) -> "LlmChat":
        self.provider = provider
        self.model = os.environ.get("GEMINI_MODEL") or model
        return self

    async def stream_message(self, message: UserMessage) -> AsyncIterator[TextDelta | StreamDone]:
        if self.provider != "gemini":
            raise RuntimeError(f"Unsupported LLM provider: {self.provider}")
        if not self.api_key or self.api_key == "not-configured":
            raise RuntimeError("Gemini is not configured; set GEMINI_API_KEY")

        parts: list[dict] = [{"text": message.text}]
        for item in message.file_contents:
            parts.append(
                {
                    "inline_data": {
                        "mime_type": item.mime_type,
                        "data": item.image_base64,
                    }
                }
            )

        payload: dict = {
            "contents": [{"role": "user", "parts": parts}],
            "generationConfig": {"temperature": 0.3},
        }
        if self.system_message:
            payload["system_instruction"] = {"parts": [{"text": self.system_message}]}

        url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self.model}:streamGenerateContent"
        )

        async with httpx.AsyncClient(timeout=90) as client:
            async with client.stream(
                "POST",
                url,
                params={"alt": "sse", "key": self.api_key},
                json=payload,
                headers={"Content-Type": "application/json"},
            ) as response:
                if response.status_code >= 400:
                    error_body = (await response.aread()).decode("utf-8", errors="replace")
                    raise RuntimeError(
                        f"Gemini request failed ({response.status_code}): {error_body[:500]}"
                    )

                async for line in response.aiter_lines():
                    if not line.startswith("data:"):
                        continue
                    raw = line[5:].strip()
                    if not raw or raw == "[DONE]":
                        continue
                    try:
                        event = json.loads(raw)
                    except json.JSONDecodeError:
                        continue
                    candidates = event.get("candidates") or []
                    if not candidates:
                        continue
                    content = candidates[0].get("content") or {}
                    for part in content.get("parts") or []:
                        text = part.get("text")
                        if text:
                            yield TextDelta(content=text)

        yield StreamDone()
