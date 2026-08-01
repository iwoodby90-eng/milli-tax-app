"""
compat.py — Drop-in replacements for emergentintegrations.
Uses standard openai + stripe SDKs pointed at Emergent's LLM proxy.
"""
import os
import json
import asyncio
from typing import Optional, List, Any
from dataclasses import dataclass, field

import stripe
from openai import AsyncOpenAI


# ──────────────────────────────────────────────────────────────────────────────
# LLM CHAT (replaces emergentintegrations.llm.chat)
# ──────────────────────────────────────────────────────────────────────────────

EMERGENT_LLM_BASE_URL = "https://integrations.emergentagent.com/llm"

# Map "gemini" model names to the OpenAI-compatible model IDs accepted by the proxy
MODEL_MAP = {
    ("gemini", "gemini-3-flash-preview"): "gemini-2.0-flash",
    ("gemini", "gemini-2.0-flash"): "gemini-2.0-flash",
    ("gemini", "gemini-1.5-flash"): "gemini-1.5-flash",
}


@dataclass
class TextDelta:
    content: str


@dataclass
class StreamDone:
    pass


@dataclass
class ImageContent:
    image_base64: str


@dataclass
class UserMessage:
    text: str
    file_contents: List[Any] = field(default_factory=list)


class LlmChat:
    def __init__(self, api_key: str, session_id: str = "", system_message: str = ""):
        self.api_key = api_key
        self.session_id = session_id
        self.system_message = system_message
        self._model = "gemini-2.0-flash"
        self._client = AsyncOpenAI(
            api_key=api_key,
            base_url=EMERGENT_LLM_BASE_URL,
        )

    def with_model(self, provider: str, model: str) -> "LlmChat":
        self._model = MODEL_MAP.get((provider, model), model)
        return self

    async def stream_message(self, msg: UserMessage):
        messages = []
        if self.system_message:
            messages.append({"role": "system", "content": self.system_message})

        # Build user content (text + optional images)
        content_parts = []
        if msg.file_contents:
            for fc in msg.file_contents:
                if isinstance(fc, ImageContent):
                    content_parts.append({
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{fc.image_base64}"}
                    })
            content_parts.append({"type": "text", "text": msg.text})
            messages.append({"role": "user", "content": content_parts})
        else:
            messages.append({"role": "user", "content": msg.text})

        stream = await self._client.chat.completions.create(
            model=self._model,
            messages=messages,
            stream=True,
            max_tokens=2048,
        )
        async for chunk in stream:
            delta = chunk.choices[0].delta if chunk.choices else None
            if delta and delta.content:
                yield TextDelta(content=delta.content)
        yield StreamDone()


# ──────────────────────────────────────────────────────────────────────────────
# TTS (replaces emergentintegrations.llm.openai.OpenAITextToSpeech)
# ──────────────────────────────────────────────────────────────────────────────

class OpenAITextToSpeech:
    def __init__(self, api_key: str):
        self._client = AsyncOpenAI(
            api_key=api_key,
            base_url=EMERGENT_LLM_BASE_URL,
        )

    async def generate_speech(self, text: str, model: str = "tts-1",
                              voice: str = "shimmer", speed: float = 1.0) -> bytes:
        response = await self._client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            speed=speed,
        )
        return response.content


# ──────────────────────────────────────────────────────────────────────────────
# STRIPE CHECKOUT (replaces emergentintegrations.payments.stripe.checkout)
# ──────────────────────────────────────────────────────────────────────────────

@dataclass
class CheckoutSessionRequest:
    amount: float
    currency: str = "usd"
    success_url: str = ""
    cancel_url: str = ""
    metadata: dict = field(default_factory=dict)


@dataclass
class CheckoutSessionResponse:
    session_id: str
    url: str
    status: str = ""
    payment_status: str = ""
    amount_total: Optional[float] = None
    currency: str = ""


@dataclass
class WebhookEvent:
    session_id: str
    payment_status: str
    status: str = ""
    metadata: dict = field(default_factory=dict)
    amount_total: Optional[float] = None
    currency: str = ""


class StripeCheckout:
    def __init__(self, api_key: str, webhook_url: str = ""):
        self.api_key = api_key
        self.webhook_url = webhook_url
        stripe.api_key = api_key

    async def create_checkout_session(self, req: CheckoutSessionRequest) -> CheckoutSessionResponse:
        # Convert amount to cents
        amount_cents = int(req.amount * 100)
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[{
                "price_data": {
                    "currency": req.currency,
                    "unit_amount": amount_cents,
                    "product_data": {"name": f"Milli {req.metadata.get('tier', 'Plan')} Subscription"},
                },
                "quantity": 1,
            }],
            mode="payment",
            success_url=req.success_url,
            cancel_url=req.cancel_url,
            metadata=req.metadata,
        )
        return CheckoutSessionResponse(
            session_id=session.id,
            url=session.url,
            status=session.status,
            payment_status=session.payment_status or "",
        )

    async def get_checkout_status(self, session_id: str) -> CheckoutSessionResponse:
        session = stripe.checkout.Session.retrieve(session_id)
        return CheckoutSessionResponse(
            session_id=session.id,
            url=session.url or "",
            status=session.status or "",
            payment_status=session.payment_status or "",
            amount_total=(session.amount_total or 0) / 100.0,
            currency=session.currency or "usd",
        )

    async def handle_webhook(self, body: bytes, signature: str) -> WebhookEvent:
        # For production, verify signature with webhook secret
        # For now, parse the event directly
        payload = json.loads(body)
        event_type = payload.get("type", "")
        data_obj = payload.get("data", {}).get("object", {})

        session_id = data_obj.get("id", "")
        payment_status = data_obj.get("payment_status", "")
        metadata = data_obj.get("metadata", {})
        amount_total = (data_obj.get("amount_total") or 0) / 100.0

        return WebhookEvent(
            session_id=session_id,
            payment_status=payment_status,
            status=data_obj.get("status", ""),
            metadata=metadata,
            amount_total=amount_total,
            currency=data_obj.get("currency", "usd"),
        )
