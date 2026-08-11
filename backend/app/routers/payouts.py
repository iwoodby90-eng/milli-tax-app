from datetime import datetime, timedelta
from fastapi import APIRouter, Depends

from app.auth import current_user

router = APIRouter()


@router.get("")
def list_payouts(user: str = Depends(current_user)):
    now = datetime.utcnow()
    return [
        {"id": "1", "source": "Uber", "amount": 284.50, "date": (now - timedelta(days=1)).isoformat(), "status": "paid"},
        {"id": "2", "source": "DoorDash", "amount": 156.20, "date": (now - timedelta(days=2)).isoformat(), "status": "paid"},
        {"id": "3", "source": "Upwork", "amount": 640.00, "date": (now - timedelta(days=4)).isoformat(), "status": "pending"},
    ]
