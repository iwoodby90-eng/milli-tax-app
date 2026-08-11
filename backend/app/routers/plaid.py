from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user
from app.config import settings
from app.models import PublicTokenRequest

router = APIRouter()


@router.post("/link-token")
def link_token(user: str = Depends(current_user)):
    if not settings.PLAID_CLIENT_ID or not settings.PLAID_SECRET:
        raise HTTPException(status_code=503, detail="Plaid credentials not configured")
    # TODO: call Plaid /link/token/create with the plaid-python client and
    # return the real link_token. Products: auth, transactions, investments.
    return {"link_token": "link-not-configured"}


@router.post("/exchange")
def exchange(body: PublicTokenRequest, user: str = Depends(current_user)):
    if not settings.PLAID_CLIENT_ID or not settings.PLAID_SECRET:
        raise HTTPException(status_code=503, detail="Plaid credentials not configured")
    # TODO: client.item_public_token_exchange(body.public_token) -> access_token.
    # Persist the access_token per user; never return it to the client.
    return {"success": True, "item_id": None}
