"""Small async Stripe Checkout adapter used by ``backend/server.py``.

This intentionally mirrors the interface the former private dependency
provided while using Stripe's public Python SDK underneath.
"""
from __future__ import annotations

import asyncio
import os
from dataclasses import dataclass, field
from typing import Any

import stripe


@dataclass(slots=True)
class CheckoutSessionRequest:
    amount: float
    currency: str
    success_url: str
    cancel_url: str
    metadata: dict[str, str] = field(default_factory=dict)


@dataclass(slots=True)
class CheckoutSessionResponse:
    session_id: str
    url: str


@dataclass(slots=True)
class CheckoutStatusResponse:
    status: str | None
    payment_status: str | None
    amount_total: int | None
    currency: str | None


@dataclass(slots=True)
class CheckoutWebhookEvent:
    session_id: str | None
    payment_status: str | None
    metadata: dict[str, Any]


class StripeCheckout:
    def __init__(self, api_key: str, webhook_url: str = "") -> None:
        if not api_key or api_key == "not-configured":
            raise RuntimeError("Stripe is not configured")
        self.api_key = api_key
        self.webhook_url = webhook_url

    def _configure(self) -> None:
        stripe.api_key = self.api_key

    async def create_checkout_session(
        self, request: CheckoutSessionRequest
    ) -> CheckoutSessionResponse:
        self._configure()
        amount_cents = int(round(float(request.amount) * 100))
        if amount_cents <= 0:
            raise ValueError("Checkout amount must be greater than zero")

        tier = request.metadata.get("tier", "Milli")

        def _create():
            return stripe.checkout.Session.create(
                mode="subscription",
                payment_method_types=["card"],
                line_items=[
                    {
                        "price_data": {
                            "currency": request.currency.lower(),
                            "unit_amount": amount_cents,
                            "recurring": {"interval": "month"},
                            "product_data": {
                                "name": f"Milli {tier.title()}",
                                "description": "Monthly Milli subscription",
                            },
                        },
                        "quantity": 1,
                    }
                ],
                success_url=request.success_url,
                cancel_url=request.cancel_url,
                customer_email=request.metadata.get("email"),
                metadata=request.metadata,
                subscription_data={"metadata": request.metadata},
            )

        session = await asyncio.to_thread(_create)
        return CheckoutSessionResponse(session_id=session.id, url=session.url)

    async def get_checkout_status(self, session_id: str) -> CheckoutStatusResponse:
        self._configure()
        session = await asyncio.to_thread(stripe.checkout.Session.retrieve, session_id)
        return CheckoutStatusResponse(
            status=getattr(session, "status", None),
            payment_status=getattr(session, "payment_status", None),
            amount_total=getattr(session, "amount_total", None),
            currency=getattr(session, "currency", None),
        )

    async def handle_webhook(self, body: bytes, signature: str) -> CheckoutWebhookEvent:
        self._configure()
        webhook_secret = os.environ.get("STRIPE_WEBHOOK_SECRET", "")
        if not webhook_secret:
            raise RuntimeError("STRIPE_WEBHOOK_SECRET is not configured")
        if not signature:
            raise ValueError("Missing Stripe-Signature header")

        event = stripe.Webhook.construct_event(body, signature, webhook_secret)
        event_type = event.get("type", "")
        obj = event.get("data", {}).get("object", {})

        if event_type.startswith("checkout.session."):
            return CheckoutWebhookEvent(
                session_id=obj.get("id"),
                payment_status=obj.get("payment_status"),
                metadata=dict(obj.get("metadata") or {}),
            )

        return CheckoutWebhookEvent(
            session_id=obj.get("id"),
            payment_status=obj.get("payment_status"),
            metadata=dict(obj.get("metadata") or {}),
        )
