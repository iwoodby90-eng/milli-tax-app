"""
Milli Tax Vault Backend
FastAPI application with PostgreSQL, Redis caching, and JWT auth.
"""
import os
from datetime import datetime, timedelta
from typing import Optional, List
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, Field
import jwt
import asyncpg
import redis.asyncio as redis

# Environment
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://localhost:5432/milli_tax")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
JWT_SECRET = os.getenv("JWT_SECRET", "change-me-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_HOURS = 24

app = FastAPI(title="Milli Tax Vault API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Redis pool (lazy init)
_redis: Optional[redis.Redis] = None


async def get_redis():
    global _redis
    if _redis is None:
        _redis = redis.from_url(REDIS_URL, decode_responses=True)
    return _redis


# Database pool (lazy init)
_db_pool: Optional[asyncpg.Pool] = None


async def get_db():
    global _db_pool
    if _db_pool is None:
        _db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
    return _db_pool


# Auth
def create_jwt(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "exp": datetime.utcnow() + timedelta(hours=JWT_EXPIRY_HOURS),
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


async def get_current_user(token: str = Depends(oauth2_scheme)) -> str:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload["sub"]
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


# === Models ===

class User(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    email: str
    first_name: str
    last_name: str
    plan: str = "basic"
    created_at: datetime = Field(default_factory=datetime.utcnow)


class TaxPayment(BaseModel):
    user_id: str
    amount: float
    tax_year: str
    payment_type: str
    quarter: Optional[str] = None
    bank_account: Optional[dict] = None


class EFilingSubmission(BaseModel):
    user_id: str
    tax_year: str
    return_data: dict
    taxpayer: dict
    refund_deposit: Optional[dict] = None


class BrokerageLink(BaseModel):
    user_id: str
    api_key: str
    secret_key: str


# === Auth endpoints ===

@app.post("/auth/register")
async def register(user: User):
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO users (id, email, first_name, last_name, plan, created_at) VALUES ($1, $2, $3, $4, $5, $6)",
            user.id, user.email, user.first_name, user.last_name, user.plan, user.created_at,
        )
    token = create_jwt(user.id)
    return {"access_token": token, "token_type": "bearer", "user": user.dict()}


@app.post("/auth/login")
async def login(email: str, password: str):
    # In production: verify password hash from DB
    pool = await get_db()
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT id FROM users WHERE email = $1", email)
        if not row:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_jwt(row["id"])
    return {"access_token": token, "token_type": "bearer"}


@app.post("/auth/refresh")
async def refresh_token(refresh_token: str):
    try:
        payload = jwt.decode(refresh_token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        new_token = create_jwt(payload["sub"])
        return {"access_token": new_token, "token_type": "bearer"}
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")


# === Tax Payment endpoints ===

@app.post("/api/tax-payments/irs-direct")
async def irs_direct_pay(payment: TaxPayment, user_id: str = Depends(get_current_user)):
    payment_id = str(uuid4())
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO tax_payments (id, user_id, amount, tax_year, payment_type, quarter, status, created_at) VALUES ($1, $2, $3, $4, $5, $6, 'pending', NOW())",
            payment_id, user_id, payment.amount, payment.tax_year, payment.payment_type, payment.quarter,
        )
    return {"payment_id": payment_id, "status": "submitted", "confirmation": f"IRS-{payment_id[:8].upper()}"}


@app.post("/api/tax-payments/card")
async def card_payment(payment: TaxPayment, user_id: str = Depends(get_current_user)):
    payment_id = str(uuid4())
    # In production: integrate with Stripe/processor
    return {"payment_id": payment_id, "status": "processed", "confirmation": f"CARD-{payment_id[:8].upper()}"}


@app.get("/api/tax-payments/history")
async def payment_history(user_id: str, tax_year: Optional[str] = None, current_user: str = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        if tax_year:
            rows = await conn.fetch("SELECT * FROM tax_payments WHERE user_id = $1 AND tax_year = $2 ORDER BY created_at DESC", user_id, tax_year)
        else:
            rows = await conn.fetch("SELECT * FROM tax_payments WHERE user_id = $1 ORDER BY created_at DESC", user_id)
    return [dict(row) for row in rows]


# === E-Filing endpoints ===

@app.post("/api/efile/federal")
async def efile_federal(submission: EFilingSubmission, user_id: str = Depends(get_current_user)):
    submission_id = str(uuid4())
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO efile_submissions (id, user_id, tax_year, status, created_at) VALUES ($1, $2, $3, 'submitted', NOW())",
            submission_id, user_id, submission.tax_year,
        )
    return {"submission_id": submission_id, "status": "submitted"}


@app.get("/api/efile/status/{submission_id}")
async def efile_status(submission_id: str, user_id: str = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT status FROM efile_submissions WHERE id = $1 AND user_id = $2", submission_id, user_id)
        if not row:
            raise HTTPException(status_code=404, detail="Submission not found")
    return {"submission_id": submission_id, "status": row["status"]}


# === Brokerage endpoints ===

@app.post("/api/brokerage/link")
async def link_brokerage(link: BrokerageLink, user_id: str = Depends(get_current_user)):
    # In production: securely store keys, create Alpaca session
    return {"status": "linked", "account_id": f"ALP-{str(uuid4())[:8].upper()}"}


@app.get("/api/brokerage/portfolio")
async def get_portfolio(user_id: str, current_user: str = Depends(get_current_user)):
    # In production: fetch from Alpaca API
    return {"buying_power": 0, "equity": 0, "positions": []}


# === Banking endpoints ===

@app.post("/api/banking/accounts")
async def create_bank_account(user_id: str, type: str, nickname: str, current_user: str = Depends(get_current_user)):
    account_id = str(uuid4())
    # In production: create via SynapseFi/Unit.co
    return {"account_id": account_id, "type": type, "nickname": nickname, "status": "pending"}


# === KYC endpoints ===

@app.post("/api/kyc/start")
async def start_kyc(user_id: str, first_name: str, last_name: str, dob: str, ssn: str, address: dict, current_user: str = Depends(get_current_user)):
    inquiry_id = str(uuid4())
    # In production: create Persona inquiry
    return {"inquiry_id": inquiry_id, "status": "pending", "redirect_url": f"https://withpersona.com/verify/{inquiry_id}"}


@app.get("/api/kyc/status")
async def kyc_status(user_id: str, current_user: str = Depends(get_current_user)):
    # In production: check Persona inquiry status
    return {"status": "pending"}


# === OCR endpoints ===

@app.post("/api/ocr/receipt")
async def process_receipt(user_id: str, image_data: str, mime_type: str, current_user: str = Depends(get_current_user)):
    receipt_id = str(uuid4())
    # In production: send to Google Vision/Textract
    return {
        "receipt_id": receipt_id,
        "merchant": "Detected Merchant",
        "date": datetime.utcnow().isoformat(),
        "total": 0.00,
        "items": [],
        "raw_text": "",
    }


# === Admin endpoints ===

@app.get("/api/admin/stats")
async def admin_stats(current_user: str = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        total_users = await conn.fetchval("SELECT COUNT(*) FROM users")
        active_subs = await conn.fetchval("SELECT COUNT(*) FROM users WHERE plan != 'basic'")
        mrr = await conn.fetchval("SELECT COALESCE(SUM(CASE WHEN plan = 'pro' THEN 29.99 WHEN plan = 'elite' THEN 49.99 ELSE 0 END), 0) FROM users WHERE plan != 'basic'")
    return {
        "total_users": total_users,
        "active_subscriptions": active_subs,
        "mrr": float(mrr),
    }


# === Health check ===

@app.get("/health")
async def health():
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)