from fastapi import APIRouter, Depends, Request, HTTPException

from app.auth import current_user
from app.config import settings

router = APIRouter()


@router.post("/checkout")
def checkout(user: str = Depends(current_user)):
    if not settings.STRIPE_SECRET_KEY or not settings.STRIPE_PRICE_ID:
        raise HTTPException(status_code=503, detail="Stripe not configured")
    # TODO: stripe.checkout.Session.create(...) and return session.url
    return {"url": None, "client_secret": None}


@router.get("/subscription")
def subscription(user: str = Depends(current_user)):
    return {"active": False, "tier": "Milli Pro", "renews_at": None}


@router.post("/webhook")
async def webhook(request: Request):
    payload = await request.body()
    sig = request.headers.get("stripe-signature", "")
    # TODO: stripe.Webhook.construct_event(payload, sig, settings.STRIPE_WEBHOOK_SECRET)
    _ = (payload, sig)
    return {"received": True}
