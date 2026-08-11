from fastapi import APIRouter, Depends
from app.auth import current_user

router = APIRouter()


@router.get("/summary")
def summary(user: str = Depends(current_user)):
    return {
        "balance": 3240.0,
        "setAsidePct": 0.25,
        "ytdIncome": 48200.0,
        "estimatedTax": 9100.0,
    }
