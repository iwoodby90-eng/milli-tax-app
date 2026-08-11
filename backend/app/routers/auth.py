import uuid
from typing import Dict

from fastapi import APIRouter, HTTPException

from app.models import RegisterRequest, LoginRequest, AuthResponse, UserOut
from app.auth import hash_password, verify_password, create_token

router = APIRouter()

# In-memory store for the reference build. Swap for a real database
# (SQLModel / Postgres) before production.
_USERS: Dict[str, dict] = {}


@router.post("/register", response_model=AuthResponse)
def register(body: RegisterRequest):
    if body.email.lower() in _USERS:
        raise HTTPException(status_code=400, detail="An account with that email already exists")
    uid = str(uuid.uuid4())
    _USERS[body.email.lower()] = {
        "id": uid,
        "full_name": body.full_name,
        "email": body.email,
        "password": hash_password(body.password),
        "tier": "Milli Pro",
    }
    user = UserOut(id=uid, full_name=body.full_name, email=body.email)
    return AuthResponse(token=create_token(uid), user=user)


@router.post("/login", response_model=AuthResponse)
def login(body: LoginRequest):
    record = _USERS.get(body.email.lower())
    if not record or not verify_password(body.password, record["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    user = UserOut(id=record["id"], full_name=record["full_name"], email=record["email"], tier=record["tier"])
    return AuthResponse(token=create_token(record["id"]), user=user)
