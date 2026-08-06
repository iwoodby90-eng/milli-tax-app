"""TaxHaul backend — Tax & mileage tracker for gig delivery drivers."""
import os
import io
import csv
import uuid
import logging
import hmac
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Milli Autopilot™ engine (pure logic, no HTTP coupling).
from autopilot import (
    run_autopilot as _run_autopilot,
    get_or_init_settings as _get_autopilot_settings,
    update_settings as _update_autopilot_settings,
    get_snapshot as _autopilot_snapshot,
    migrate_all_users as _autopilot_migrate,
)

from datetime import datetime, timezone, timedelta, date
from typing import Optional, List, Dict, Any

import bcrypt
import jwt
from fastapi import FastAPI, APIRouter, Depends, HTTPException, Request, UploadFile, File, Form
from fastapi.responses import StreamingResponse, JSONResponse
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel, Field, EmailStr

# Plaid
import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_sync_request import TransactionsSyncRequest
from plaid.model.sandbox_item_fire_webhook_request import SandboxItemFireWebhookRequest

# Stripe via emergentintegrations
from emergentintegrations.payments.stripe.checkout import (
    StripeCheckout, CheckoutSessionRequest, CheckoutSessionResponse
)

# LLM (Gemini 3 Flash)
from emergentintegrations.llm.chat import LlmChat, UserMessage, ImageContent

# PDF
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas as pdfcanvas

# -------------------- ENV / CLIENTS --------------------
MONGO_URL = os.environ['MONGO_URL']
DB_NAME = os.environ['DB_NAME']
JWT_SECRET = os.environ['JWT_SECRET']
JWT_ALGORITHM = "HS256"
PLAID_CLIENT_ID = os.environ.get('PLAID_CLIENT_ID', 'not-configured')
PLAID_SECRET = os.environ.get('PLAID_SECRET', 'not-configured')
PLAID_ENV = os.environ.get('PLAID_ENV', 'sandbox')
EMERGENT_LLM_KEY = os.environ.get('EMERGENT_LLM_KEY', 'not-configured')
STRIPE_API_KEY = os.environ.get('STRIPE_API_KEY', 'not-configured')
APP_ENV = os.environ.get('APP_ENV', 'development').strip().lower()
DEMO_MODE_ENABLED = os.environ.get('DEMO_MODE_ENABLED', 'false').strip().lower() == 'true'
ALLOW_UNVERIFIED_STOREKIT = (
    os.environ.get('ALLOW_UNVERIFIED_STOREKIT', 'false').strip().lower() == 'true'
)

client = AsyncIOMotorClient(MONGO_URL)
db = client[DB_NAME]

_plaid_host = {
    'sandbox': plaid.Environment.Sandbox,
    'production': plaid.Environment.Production,
}.get(PLAID_ENV, plaid.Environment.Sandbox)

plaid_config = plaid.Configuration(
    host=_plaid_host,
    api_key={'clientId': PLAID_CLIENT_ID, 'secret': PLAID_SECRET},
)
plaid_client = plaid_api.PlaidApi(plaid.ApiClient(plaid_config))

def _plaid_configured() -> bool:
    invalid = {'', 'not-configured', 'your-plaid-client-id', 'your-plaid-secret'}
    return PLAID_CLIENT_ID not in invalid and PLAID_SECRET not in invalid

# -------------------- CONSTANTS --------------------
GIG_PLATFORMS = {
    "uber": "Uber",
    "uber eats": "Uber Eats",
    "lyft": "Lyft",
    "doordash": "DoorDash",
    "door dash": "DoorDash",
    "grubhub": "Grubhub",
    "instacart": "Instacart",
    "spark": "Spark",
    "walmart spark": "Spark",
    "amazon flex": "Amazon Flex",
    "amzn flex": "Amazon Flex",
    "shipt": "Shipt",
    "postmates": "Postmates",
    "favor": "Favor",
    "gopuff": "GoPuff",
}

# IRS 2026 standard mileage rate (approx, configurable)
IRS_MILEAGE_RATE = 0.70
SE_TAX_RATE = 0.153  # Self-employment tax

# State income tax rates (simplified flat estimate for top brackets — informational only)
STATE_TAX_RATES = {
    "CA": 0.093, "NY": 0.0685, "TX": 0.0, "FL": 0.0, "WA": 0.0, "NV": 0.0,
    "IL": 0.0495, "PA": 0.0307, "OH": 0.0399, "GA": 0.0575, "NC": 0.045,
    "MI": 0.0425, "AZ": 0.025, "MA": 0.05, "VA": 0.0575, "NJ": 0.0637,
    "CO": 0.044, "OR": 0.099, "MN": 0.0985, "WI": 0.0765, "TN": 0.0,
    "MO": 0.054, "MD": 0.0575, "IN": 0.0323, "AL": 0.05, "KY": 0.05,
    "LA": 0.045, "SC": 0.07, "OK": 0.0475, "CT": 0.0699, "UT": 0.0485,
    "IA": 0.06, "AR": 0.049, "KS": 0.057, "MS": 0.05, "NE": 0.0684,
    "NM": 0.059, "WV": 0.065, "HI": 0.11, "NH": 0.0, "ME": 0.0715,
    "MT": 0.0675, "RI": 0.0599, "DE": 0.066, "SD": 0.0, "AK": 0.0,
    "ND": 0.0290, "VT": 0.0875, "WY": 0.0, "ID": 0.058, "DC": 0.0895,
}

# Tax savings ratio per deposit (per tier)
TIER_SAVINGS_RATIO = {
    "trial": 0.25,
    "basic": 0.25,
    "pro": 0.27,
    "elite": 0.30,
}

# Subscription packages (server-side fixed pricing)
PRICING_PACKAGES = {
    "basic":  {"name": "Basic",  "amount": 19.99, "currency": "usd"},
    "pro":    {"name": "Pro",    "amount": 29.99, "currency": "usd"},
    "elite":  {"name": "Elite",  "amount": 49.99, "currency": "usd"},
}

# -------------------- AUTH HELPERS --------------------
def hash_password(pw: str) -> str:
    return bcrypt.hashpw(pw.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def verify_password(pw: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(pw.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False

def create_token(user_id: str, email: str) -> str:
    payload = {
        "sub": user_id,
        "email": email,
        "exp": datetime.now(timezone.utc) + timedelta(days=7),
        "type": "access",
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

async def get_current_user(request: Request) -> dict:
    auth = request.headers.get("Authorization", "")
    token = auth[7:] if auth.startswith("Bearer ") else None
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = await db.users.find_one({"id": payload["sub"]}, {"password_hash": 0})
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    user.pop("_id", None)
    return user

# -------------------- MODELS --------------------
class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12)
    name: str
    state: str = "TX"

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class ProfileUpdateIn(BaseModel):
    name: Optional[str] = None
    state: Optional[str] = None
    filing_status: Optional[str] = None
    retirement_year: Optional[int] = None
    retirement_target_income: Optional[float] = None
    retirement_goal_notes: Optional[str] = None
    retirement_account_type: Optional[str] = None   # roth_ira, traditional_ira, sep_ira, solo_401k, hsa
    retirement_contribution_pct: Optional[float] = None

class PublicTokenIn(BaseModel):
    public_token: str
    institution_name: Optional[str] = None

class TripStartIn(BaseModel):
    purpose: Optional[str] = "delivery"
    platform: Optional[str] = None
    start_lat: Optional[float] = None
    start_lng: Optional[float] = None
    start_address: Optional[str] = None

class TripPointIn(BaseModel):
    lat: float
    lng: float
    timestamp: Optional[str] = None

class TripEndIn(BaseModel):
    end_lat: Optional[float] = None
    end_lng: Optional[float] = None
    end_address: Optional[str] = None
    miles: Optional[float] = None  # client-computed (Haversine) miles, server validates
    points: Optional[List[TripPointIn]] = None

class ManualTripIn(BaseModel):
    date: str  # YYYY-MM-DD
    miles: float
    purpose: Optional[str] = "delivery"
    platform: Optional[str] = None
    notes: Optional[str] = None

class ExpenseIn(BaseModel):
    date: str
    amount: float
    category: str  # gas, maintenance, supplies, food, insurance, phone, other
    merchant: Optional[str] = None
    notes: Optional[str] = None

class ChatIn(BaseModel):
    message: str
    session_id: Optional[str] = None

class CheckoutIn(BaseModel):
    tier: str  # basic, pro, elite
    origin_url: str

# -------------------- APP --------------------
app = FastAPI(title="Milli API")
api = APIRouter(prefix="/api")

# -------------------- AUTH ROUTES --------------------
@api.post("/auth/register")
async def register(body: RegisterIn):
    email = body.email.lower().strip()
    existing = await db.users.find_one({"email": email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    trial_end = now + timedelta(days=3)
    user_doc = {
        "id": user_id,
        "email": email,
        "name": body.name,
        "state": body.state.upper(),
        "filing_status": "single",
        "password_hash": hash_password(body.password),
        "plan": "trial",
        "trial_end": trial_end.isoformat(),
        "stripe_active_until": None,
        "plaid_items": [],
        "tax_savings_balance": 0.0,
        "retirement_balance": 0.0,
        "investing_balance": 0.0,
        "savings_balance": 0.0,
        "available_to_spend": 0.0,
        "autopilot_settings": {
            "tax_enabled": True,
            "retirement_pct": 0.05,
            "investing_pct": 0.05,
            "savings_pct": 0.0,
            "version": 1,
            "updated_at": now.isoformat(),
        },
        "onboarding_complete": False,
        "created_at": now.isoformat(),
    }
    await db.users.insert_one(user_doc)
    user_doc.pop("password_hash", None)
    user_doc.pop("_id", None)
    return {"token": create_token(user_id, email), "user": user_doc}

@api.post("/auth/login")
async def login(body: LoginIn):
    email = body.email.lower().strip()
    user = await db.users.find_one({"email": email})
    if not user or not verify_password(body.password, user.get("password_hash", "")):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    user.pop("password_hash", None)
    user.pop("_id", None)
    return {"token": create_token(user["id"], email), "user": user}

@api.get("/auth/me")
async def me(user: dict = Depends(get_current_user)):
    return user

@api.put("/auth/profile")
async def update_profile(body: ProfileUpdateIn, user: dict = Depends(get_current_user)):
    update = {}
    if body.name: update["name"] = body.name
    if body.state: update["state"] = body.state.upper()
    if body.filing_status: update["filing_status"] = body.filing_status
    if body.retirement_year is not None: update["retirement_year"] = int(body.retirement_year)
    if body.retirement_target_income is not None: update["retirement_target_income"] = float(body.retirement_target_income)
    if body.retirement_goal_notes is not None: update["retirement_goal_notes"] = body.retirement_goal_notes
    if body.retirement_account_type is not None: update["retirement_account_type"] = body.retirement_account_type
    if body.retirement_contribution_pct is not None: update["retirement_contribution_pct"] = float(body.retirement_contribution_pct)
    if update:
        await db.users.update_one({"id": user["id"]}, {"$set": update})
    out = await db.users.find_one({"id": user["id"]}, {"password_hash": 0, "_id": 0})
    return out

class OnboardingIn(BaseModel):
    employment_types: List[str] = []
    income_sources: List[str] = []
    expected_income: Optional[float] = 0
    dependents: Optional[int] = 0
    reserve_strategy: Optional[str] = "balanced"
    tax_goal: Optional[float] = 20000
    mileage_mode: Optional[str] = "auto"

@api.post("/onboarding/complete")
async def onboarding_complete(body: OnboardingIn, user: dict = Depends(get_current_user)):
    await db.users.update_one(
        {"id": user["id"]},
        {"$set": {
            "onboarding_complete": True,
            "employment_types": body.employment_types,
            "income_sources": body.income_sources,
            "expected_income": float(body.expected_income or 0),
            "dependents": int(body.dependents or 0),
            "reserve_strategy": body.reserve_strategy,
            "tax_goal": float(body.tax_goal or 20000),
            "mileage_mode": body.mileage_mode,
        }},
    )
    # Seed the tax_vault with this goal so the Progress Story hero has a real target on day 1
    await db.tax_vaults.update_one(
        {"user_id": user["id"]},
        {"$set": {"tax_goal": float(body.tax_goal or 20000)}, "$setOnInsert": {"balance": 0, "user_id": user["id"]}},
        upsert=True,
    )
    out = await db.users.find_one({"id": user["id"]}, {"password_hash": 0, "_id": 0})
    return out

# -------------------- PLAID ROUTES --------------------
@api.post("/plaid/link-token")
async def plaid_link_token(user: dict = Depends(get_current_user)):
    if not _plaid_configured():
        raise HTTPException(status_code=503, detail='Plaid is not configured')
    req = LinkTokenCreateRequest(
        products=[Products("transactions")],
        client_name="Milli",
        country_codes=[CountryCode("US")],
        language="en",
        user=LinkTokenCreateRequestUser(client_user_id=user["id"]),
    )
    try:
        resp = plaid_client.link_token_create(req)
        return {"link_token": resp["link_token"]}
    except plaid.ApiException as e:
        logging.exception("Plaid link token failed")
        raise HTTPException(status_code=500, detail=f"Plaid error: {e.body}")

@api.post("/plaid/exchange")
async def plaid_exchange(body: PublicTokenIn, user: dict = Depends(get_current_user)):
    if not _plaid_configured():
        raise HTTPException(status_code=503, detail='Plaid is not configured')
    try:
        exch = plaid_client.item_public_token_exchange(
            ItemPublicTokenExchangeRequest(public_token=body.public_token)
        )
    except plaid.ApiException as e:
        logging.exception("Plaid exchange failed")
        raise HTTPException(status_code=400, detail="Could not link this account. Please try again.")
    access_token = exch["access_token"]
    item_id = exch["item_id"]
    item_doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "access_token": access_token,
        "item_id": item_id,
        "institution_name": body.institution_name or "Connected Bank",
        "cursor": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.plaid_items.insert_one(item_doc)
    # Auto-sync once after link
    synced = await _sync_item(item_doc, user)
    return {"item_id": item_doc["id"], "institution_name": item_doc["institution_name"], "synced_deposits": synced}

@api.get("/plaid/items")
async def list_plaid_items(user: dict = Depends(get_current_user)):
    items = await db.plaid_items.find({"user_id": user["id"]}, {"_id": 0, "access_token": 0}).to_list(50)
    return items

@api.delete("/plaid/items/{item_id}")
async def remove_plaid_item(item_id: str, user: dict = Depends(get_current_user)):
    await db.plaid_items.delete_one({"id": item_id, "user_id": user["id"]})
    return {"ok": True}

@api.post("/plaid/sync")
async def plaid_sync(user: dict = Depends(get_current_user)):
    items = await db.plaid_items.find({"user_id": user["id"]}).to_list(50)
    total = 0
    for it in items:
        total += await _sync_item(it, user)
    return {"synced": total}

async def _sync_item(item: dict, user: dict) -> int:
    """Pull transactions for one plaid item and classify gig deposits."""
    cursor = item.get("cursor")
    access_token = item["access_token"]
    added: List[Any] = []
    has_more = True
    while has_more:
        try:
            req = TransactionsSyncRequest(access_token=access_token, cursor=cursor) if cursor \
                  else TransactionsSyncRequest(access_token=access_token)
            resp = plaid_client.transactions_sync(req)
        except plaid.ApiException as e:
            logging.exception("Plaid sync error")
            raise HTTPException(status_code=500, detail=f"Plaid sync error: {e.body}")
        added.extend(resp["added"])
        has_more = resp["has_more"]
        cursor = resp["next_cursor"]
    await db.plaid_items.update_one({"id": item["id"]}, {"$set": {"cursor": cursor}})

    new_deposits = 0
    savings_ratio = TIER_SAVINGS_RATIO.get(user.get("plan", "trial"), 0.25)
    extra_savings = 0.0
    for tx in added:
        # In Plaid, negative amount = inflow / deposit
        amount = float(tx["amount"]) if tx["amount"] is not None else 0.0
        if amount >= 0:
            continue
        name = str(tx.get("merchant_name") or tx.get("name") or "").lower()
        platform = None
        for key, label in GIG_PLATFORMS.items():
            if key in name:
                platform = label
                break
        if not platform:
            continue
        deposit_amount = abs(amount)
        tx_date = str(tx.get("date"))
        existing = await db.deposits.find_one({"transaction_id": tx["transaction_id"]})
        if existing:
            continue
        savings_set_aside = round(deposit_amount * savings_ratio, 2)
        doc = {
            "id": str(uuid.uuid4()),
            "user_id": user["id"],
            "transaction_id": tx["transaction_id"],
            "plaid_item_id": item["id"],
            "date": tx_date,
            "merchant": tx.get("merchant_name") or tx.get("name"),
            "platform": platform,
            "amount": deposit_amount,
            "savings_set_aside": savings_set_aside,
            "auto_allocated": user.get("plan") == "elite",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        await db.deposits.insert_one(doc)
        new_deposits += 1
        # Run Milli Autopilot™ pipeline on the new payout (immutable receipt).
        try:
            fresh_user = await db.users.find_one({"id": user["id"]}) or user
            await _run_autopilot(db, fresh_user, doc)
        except Exception as ap_err:
            logging.warning("Autopilot failed for deposit %s: %s", doc["id"], ap_err)
        # Fire a push notification for the new payout (no-op if APNs not configured).
        try:
            import apns as _apns
            tok = (user.get("push") or {}).get("device_token")
            if tok:
                await _apns.send_push(
                    tok,
                    f"New {platform} payout · +${deposit_amount:,.2f}",
                    f"${savings_set_aside:,.2f} auto-routed to your Milli Tax Vault™.",
                    thread_id="payout", category="PAYOUT",
                )
        except Exception:
            pass
    return new_deposits

@api.post("/plaid/sandbox/fire-webhook")
async def plaid_sandbox_fire(user: dict = Depends(get_current_user)):
    """Sandbox helper for testing — just runs sync again."""
    return await plaid_sync(user)

# -------------------- DEPOSITS / INCOME --------------------
@api.get("/deposits")
async def list_deposits(user: dict = Depends(get_current_user), year: Optional[int] = None):
    q = {"user_id": user["id"]}
    deposits = await db.deposits.find(q, {"_id": 0}).sort("date", -1).to_list(500)
    if year:
        deposits = [d for d in deposits if d["date"].startswith(str(year))]
    return deposits

@api.post("/deposits/manual")
async def add_manual_deposit(
    body: dict, user: dict = Depends(get_current_user)
):
    amount = float(body.get("amount", 0))
    if amount <= 0:
        raise HTTPException(400, "Amount must be > 0")
    savings_ratio = TIER_SAVINGS_RATIO.get(user.get("plan", "trial"), 0.25)
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "transaction_id": f"manual_{uuid.uuid4()}",
        "plaid_item_id": None,
        "date": body.get("date") or datetime.now(timezone.utc).date().isoformat(),
        "merchant": body.get("merchant") or body.get("platform") or "Manual",
        "platform": body.get("platform") or "Manual",
        "amount": amount,
        "savings_set_aside": round(amount * savings_ratio, 2),
        "auto_allocated": user.get("plan") == "elite",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.deposits.insert_one(doc)
    if user.get("plan") == "elite":
        await db.users.update_one({"id": user["id"]}, {"$inc": {"tax_savings_balance": doc["savings_set_aside"]}})
    doc.pop("_id", None)
    return doc

# -------------------- TRIPS / MILEAGE --------------------
def _haversine_miles(p1, p2) -> float:
    from math import radians, sin, cos, asin, sqrt
    lat1, lon1 = radians(p1[0]), radians(p1[1])
    lat2, lon2 = radians(p2[0]), radians(p2[1])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * 3958.7613 * asin(sqrt(a))

@api.post("/trips/start")
async def start_trip(body: TripStartIn, user: dict = Depends(get_current_user)):
    # End any in-progress trip first
    await db.trips.update_many(
        {"user_id": user["id"], "status": "active"},
        {"$set": {"status": "abandoned"}},
    )
    trip_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    doc = {
        "id": trip_id,
        "user_id": user["id"],
        "status": "active",
        "purpose": body.purpose,
        "platform": body.platform,
        "start_lat": body.start_lat,
        "start_lng": body.start_lng,
        "start_address": body.start_address,
        "start_time": now,
        "end_time": None,
        "miles": 0.0,
        "deductible_value": 0.0,
        "points": [],
        "manual": False,
        "created_at": now,
    }
    await db.trips.insert_one(doc)
    doc.pop("_id", None)
    return doc

@api.get("/trips/active")
async def active_trip(user: dict = Depends(get_current_user)):
    trip = await db.trips.find_one({"user_id": user["id"], "status": "active"}, {"_id": 0})
    return trip

@api.post("/trips/{trip_id}/end")
async def end_trip(trip_id: str, body: TripEndIn, user: dict = Depends(get_current_user)):
    trip = await db.trips.find_one({"id": trip_id, "user_id": user["id"]})
    if not trip:
        raise HTTPException(404, "Trip not found")
    miles = 0.0
    if body.points and len(body.points) >= 2:
        pts = [(p.lat, p.lng) for p in body.points]
        for i in range(1, len(pts)):
            miles += _haversine_miles(pts[i-1], pts[i])
    elif body.miles is not None:
        miles = max(0.0, float(body.miles))
    miles = round(miles, 2)
    deductible = round(miles * IRS_MILEAGE_RATE, 2)
    await db.trips.update_one(
        {"id": trip_id},
        {"$set": {
            "status": "completed",
            "end_time": datetime.now(timezone.utc).isoformat(),
            "end_lat": body.end_lat,
            "end_lng": body.end_lng,
            "end_address": body.end_address,
            "miles": miles,
            "deductible_value": deductible,
            "points": [p.dict() for p in (body.points or [])],
        }},
    )
    out = await db.trips.find_one({"id": trip_id}, {"_id": 0})
    return out

@api.post("/trips/manual")
async def manual_trip(body: ManualTripIn, user: dict = Depends(get_current_user)):
    miles = round(max(0.0, body.miles), 2)
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "status": "completed",
        "purpose": body.purpose,
        "platform": body.platform,
        "start_address": None,
        "end_address": None,
        "start_time": f"{body.date}T00:00:00Z",
        "end_time": f"{body.date}T00:00:00Z",
        "miles": miles,
        "deductible_value": round(miles * IRS_MILEAGE_RATE, 2),
        "manual": True,
        "notes": body.notes,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.trips.insert_one(doc)
    doc.pop("_id", None)
    return doc

@api.get("/trips")
async def list_trips(user: dict = Depends(get_current_user), year: Optional[int] = None):
    q = {"user_id": user["id"], "status": "completed"}
    trips = await db.trips.find(q, {"_id": 0, "points": 0}).sort("start_time", -1).to_list(500)
    if year:
        trips = [t for t in trips if (t.get("start_time") or "").startswith(str(year))]
    return trips

@api.delete("/trips/{trip_id}")
async def delete_trip(trip_id: str, user: dict = Depends(get_current_user)):
    await db.trips.delete_one({"id": trip_id, "user_id": user["id"]})
    return {"ok": True}


# -------------------- TRIP CLASSIFICATION --------------------
TRIP_CATEGORIES = {"business", "personal", "medical", "charitable",
                   "commuting", "needs_review"}


class TripClassifyIn(BaseModel):
    classification: str
    vehicle_id: Optional[str] = None
    business_purpose: Optional[str] = None


@api.put("/trips/{trip_id}/classify")
async def classify_trip(trip_id: str, body: TripClassifyIn,
                        user: dict = Depends(get_current_user)):
    if body.classification not in TRIP_CATEGORIES:
        raise HTTPException(400, f"classification must be one of {sorted(TRIP_CATEGORIES)}")
    from tax_engine import (
        IRS_MILEAGE_RATE_BUSINESS,
        IRS_MILEAGE_RATE_MEDICAL,
        IRS_MILEAGE_RATE_CHARITABLE,
    )
    trip = await db.trips.find_one({"id": trip_id, "user_id": user["id"]})
    if not trip:
        raise HTTPException(404, "Trip not found")
    miles = float(trip.get("miles") or 0.0)
    rate = {
        "business": IRS_MILEAGE_RATE_BUSINESS,
        "medical": IRS_MILEAGE_RATE_MEDICAL,
        "charitable": IRS_MILEAGE_RATE_CHARITABLE,
    }.get(body.classification, 0.0)
    deductible = round(miles * rate, 2)
    patch = {
        "classification": body.classification,
        "deductible_value": deductible,
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
    }
    if body.vehicle_id:
        patch["vehicle_id"] = body.vehicle_id
    if body.business_purpose:
        patch["business_purpose"] = body.business_purpose
    await db.trips.update_one({"id": trip_id}, {"$set": patch})
    updated = await db.trips.find_one({"id": trip_id}, {"_id": 0, "points": 0})
    return updated


@api.get("/trips/needs-review")
async def trips_needing_review(user: dict = Depends(get_current_user)):
    trips = await db.trips.find(
        {"user_id": user["id"], "status": "completed",
         "$or": [{"classification": {"$exists": False}},
                 {"classification": "needs_review"}]},
        {"_id": 0, "points": 0},
    ).sort("start_time", -1).to_list(200)
    return {"count": len(trips), "trips": trips}


# -------------------- VEHICLES --------------------
class VehicleIn(BaseModel):
    nickname: str
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    default: bool = False


@api.get("/vehicles")
async def list_vehicles(user: dict = Depends(get_current_user)):
    v = await db.vehicles.find({"user_id": user["id"]}, {"_id": 0}).to_list(50)
    return v


@api.post("/vehicles")
async def add_vehicle(body: VehicleIn, user: dict = Depends(get_current_user)):
    if body.default:
        await db.vehicles.update_many({"user_id": user["id"]},
                                       {"$set": {"default": False}})
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        **body.dict(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.vehicles.insert_one(doc)
    doc.pop("_id", None)
    return doc


@api.delete("/vehicles/{vehicle_id}")
async def delete_vehicle(vehicle_id: str, user: dict = Depends(get_current_user)):
    await db.vehicles.delete_one({"id": vehicle_id, "user_id": user["id"]})
    return {"ok": True}


# -------------------- MILEAGE SUMMARY (uses tax_engine) --------------------
@api.get("/mileage/summary")
async def mileage_summary(user: dict = Depends(get_current_user),
                           year: Optional[int] = None):
    from tax_engine import mileage_deduction
    year = year or datetime.now(timezone.utc).year
    trips = await db.trips.find(
        {"user_id": user["id"], "status": "completed"},
        {"_id": 0, "points": 0},
    ).to_list(5000)
    trips = [t for t in trips if (t.get("start_time") or "").startswith(str(year))]

    def _bucket(t):
        c = t.get("classification")
        if c:
            return c
        # Legacy trips without classification: infer from purpose.
        return {
            "delivery": "business", "rideshare": "business",
            "client_meeting": "business", "medical": "medical",
            "charitable": "charitable", "commute": "commuting",
        }.get(t.get("purpose"), "needs_review")

    biz = sum(t["miles"] for t in trips if _bucket(t) == "business")
    med = sum(t["miles"] for t in trips if _bucket(t) == "medical")
    cha = sum(t["miles"] for t in trips if _bucket(t) == "charitable")
    review_count = sum(1 for t in trips if _bucket(t) == "needs_review")

    return {
        "year": year,
        **mileage_deduction(biz, med, cha),
        "trips_count": len(trips),
        "trips_needing_review": review_count,
    }


# -------------------- SUBSCRIPTION FEATURE GATING --------------------
FEATURE_MATRIX = {
    "core": {"tax_vault", "mileage", "expenses", "reports", "milli_ai",
             "quarterly_estimates"},
    "pro": {"retirement", "investing", "auto_contributions",
             "guided_tax_prep"},
    "elite": {"quarterly_payments_auto", "tax_filing", "priority_support"},
}
PLAN_INCLUDES = {
    "trial": FEATURE_MATRIX["core"] | FEATURE_MATRIX["pro"] | FEATURE_MATRIX["elite"],  # trial has all
    "basic": FEATURE_MATRIX["core"],
    "core": FEATURE_MATRIX["core"],
    "pro": FEATURE_MATRIX["core"] | FEATURE_MATRIX["pro"],
    "elite": FEATURE_MATRIX["core"] | FEATURE_MATRIX["pro"] | FEATURE_MATRIX["elite"],
}


def require_feature(feature: str):
    """FastAPI dependency: reject requests whose plan doesn't include ``feature``."""
    async def _dep(user: dict = Depends(get_current_user)):
        plan = (user.get("plan") or "trial").lower()
        allowed = PLAN_INCLUDES.get(plan, FEATURE_MATRIX["core"])
        if feature not in allowed:
            raise HTTPException(
                status_code=402,
                detail={
                    "error": "plan_upgrade_required",
                    "feature": feature,
                    "current_plan": plan,
                    "upgrade_to": _min_plan_for(feature),
                },
            )
        return user
    return _dep


def _min_plan_for(feature: str) -> str:
    if feature in FEATURE_MATRIX["elite"]:
        return "elite"
    if feature in FEATURE_MATRIX["pro"]:
        return "pro"
    return "core"


@api.get("/plan/features")
async def get_plan_features(user: dict = Depends(get_current_user)):
    plan = (user.get("plan") or "trial").lower()
    allowed = PLAN_INCLUDES.get(plan, FEATURE_MATRIX["core"])
    return {
        "current_plan": plan,
        "allowed_features": sorted(list(allowed)),
        "matrix": {k: sorted(list(v)) for k, v in FEATURE_MATRIX.items()},
    }


# -------------------- NOTIFICATIONS / MILLI AI INSIGHTS --------------------
@api.get("/notifications")
async def list_notifications(user: dict = Depends(get_current_user),
                              limit: int = 50, unread_only: bool = False):
    q: dict = {"user_id": user["id"]}
    if unread_only:
        q["read"] = False
    docs = await db.notifications.find(q, {"_id": 0}).sort(
        "created_at", -1
    ).limit(max(1, min(int(limit), 200))).to_list(200)
    return docs


@api.post("/notifications/{note_id}/read")
async def mark_notification_read(note_id: str,
                                  user: dict = Depends(get_current_user)):
    await db.notifications.update_one(
        {"id": note_id, "user_id": user["id"]}, {"$set": {"read": True}},
    )
    return {"ok": True}


@api.get("/ai/insights")
async def milli_ai_insights(user: dict = Depends(get_current_user)):
    """Deterministic proactive insights the UI can surface anywhere.

    Combines Autopilot receipt highlights, missing-info flags, and quarterly
    readiness. Does NOT call an LLM — cheap, cacheable, deterministic.
    """
    insights = []
    # 1) Latest Autopilot receipt
    latest = await db.autopilot_receipts.find_one(
        {"user_id": user["id"]}, {"_id": 0}, sort=[("created_at", -1)],
    )
    if latest:
        insights.append({
            "kind": "autopilot_recap",
            "priority": "info",
            "title": "Your latest payout was handled by Milli Autopilot™",
            "body": latest["insight"],
            "cta": {"label": "View receipt", "route": f"/app/autopilot/{latest['id']}"},
        })

    # 2) Unclassified trips
    unclassified = await db.trips.count_documents({
        "user_id": user["id"], "status": "completed",
        "$or": [{"classification": {"$exists": False}},
                {"classification": "needs_review"}],
    })
    if unclassified > 0:
        insights.append({
            "kind": "trips_need_review",
            "priority": "action",
            "title": f"{unclassified} mileage trip{'s' if unclassified != 1 else ''} need review",
            "body": "Classify them so we can lock in your deduction before quarter end.",
            "cta": {"label": "Review trips", "route": "/app/mileage?filter=review"},
        })

    # 3) Quarterly readiness
    try:
        from autopilot import _refresh_quarterly_projection
        proj = await _refresh_quarterly_projection(db, user["id"])
        vault = await db.tax_vaults.find_one({"user_id": user["id"]}) or {}
        vault_bal = float(vault.get("balance") or 0.0)
        target = proj["next_quarterly_amount"]
        if target > 0:
            ready = min(100, round(vault_bal / target * 100))
            if ready >= 100:
                insights.append({
                    "kind": "quarterly_ready",
                    "priority": "good",
                    "title": f"You're fully funded for {proj['next_period']}",
                    "body": f"Your Milli Tax Vault™ covers ${target:,.2f} due in "
                            f"{proj['days_until']} days.",
                    "cta": {"label": "Open Milli Tax Vault™", "route": "/app/vault"},
                })
            elif proj["days_until"] < 30 and ready < 80:
                insights.append({
                    "kind": "quarterly_gap",
                    "priority": "warn",
                    "title": f"{proj['next_period']} estimate due in {proj['days_until']} days",
                    "body": f"You're {ready}% funded (${vault_bal:,.2f} of ${target:,.2f}). "
                            f"Milli will keep protecting from every payout.",
                    "cta": {"label": "See quarterly", "route": "/app/quarterly"},
                })
    except Exception:
        pass

    # 4) Missing tax profile
    if not user.get("filing_status") or user.get("filing_status") == "single":
        if not user.get("_seen_profile_prompt"):
            insights.append({
                "kind": "profile_incomplete",
                "priority": "info",
                "title": "Confirm your tax profile for even more accurate reserves",
                "body": "Filing status, dependents, and business type let Milli fine-tune every reserve.",
                "cta": {"label": "Complete profile", "route": "/app/settings#tax-profile"},
            })

    return {"insights": insights, "generated_at": datetime.now(timezone.utc).isoformat()}


# -------------------- TAX PROFILE --------------------
class TaxProfileIn(BaseModel):
    filing_status: Optional[str] = None
    business_type: Optional[str] = None
    additional_states: Optional[List[str]] = None
    dependents: Optional[int] = None
    additional_income: Optional[float] = None
    additional_withholding: Optional[float] = None
    take_qbi: Optional[bool] = None


@api.get("/tax/profile")
async def get_tax_profile(user: dict = Depends(get_current_user)):
    from tax_engine import profile_from_user
    return profile_from_user(user).__dict__


@api.put("/tax/profile")
async def put_tax_profile(body: TaxProfileIn,
                           user: dict = Depends(get_current_user)):
    patch = {k: v for k, v in body.dict(exclude_none=True).items()}
    if patch:
        await db.users.update_one({"id": user["id"]}, {"$set": patch})
    updated = await db.users.find_one({"id": user["id"]}) or {}
    from tax_engine import profile_from_user
    return profile_from_user(updated).__dict__


# -------------------- EXPENSES --------------------
@api.get("/expenses")
async def list_expenses(user: dict = Depends(get_current_user), year: Optional[int] = None):
    expenses = await db.expenses.find({"user_id": user["id"]}, {"_id": 0}).sort("date", -1).to_list(500)
    if year:
        expenses = [e for e in expenses if e["date"].startswith(str(year))]
    return expenses

@api.post("/expenses")
async def add_expense(body: ExpenseIn, user: dict = Depends(get_current_user)):
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "date": body.date,
        "amount": float(body.amount),
        "category": body.category,
        "merchant": body.merchant,
        "notes": body.notes,
        "receipt_url": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.expenses.insert_one(doc)
    doc.pop("_id", None)
    return doc

@api.delete("/expenses/{expense_id}")
async def delete_expense(expense_id: str, user: dict = Depends(get_current_user)):
    await db.expenses.delete_one({"id": expense_id, "user_id": user["id"]})
    return {"ok": True}

@api.post("/expenses/scan")
async def scan_receipt(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    """OCR a receipt image with Gemini, return parsed expense (does NOT save)."""
    import base64
    contents = await file.read()
    b64 = base64.b64encode(contents).decode("utf-8")
    chat = LlmChat(
        api_key=EMERGENT_LLM_KEY,
        session_id=f"ocr-{user['id']}-{uuid.uuid4()}",
        system_message=(
            "You are a receipt OCR engine for a gig driver expense tracker. "
            "Read the receipt and return a STRICT JSON object with keys: "
            "amount (number, total paid), date (YYYY-MM-DD), merchant (string), "
            "category (one of: gas, maintenance, supplies, food, insurance, phone, parking, tolls, other). "
            "Output ONLY the JSON, no markdown."
        ),
    ).with_model("gemini", "gemini-3-flash-preview")
    img = ImageContent(image_base64=b64)
    msg = UserMessage(text="Parse this receipt. Return JSON only.", file_contents=[img])
    text = ""
    try:
        from emergentintegrations.llm.chat import TextDelta, StreamDone
        async for ev in chat.stream_message(msg):
            if isinstance(ev, TextDelta):
                text += ev.content
            elif isinstance(ev, StreamDone):
                break
    except Exception as e:
        logging.exception("OCR failed")
        raise HTTPException(500, f"OCR failed: {e}")
    import json, re
    # Find JSON in response
    m = re.search(r"\{.*\}", text, re.DOTALL)
    if not m:
        raise HTTPException(422, f"Could not parse receipt. Raw: {text[:200]}")
    try:
        parsed = json.loads(m.group(0))
    except Exception:
        raise HTTPException(422, "Receipt OCR returned invalid JSON")
    return parsed

# -------------------- TAX / DASHBOARD --------------------
def _quarter_due_dates(year: int):
    # IRS estimated tax due dates
    return [
        (date(year, 4, 15), "Q1"),
        (date(year, 6, 15), "Q2"),
        (date(year, 9, 15), "Q3"),
        (date(year + 1, 1, 15), "Q4"),
    ]

@api.get("/tax/summary")
async def tax_summary(user: dict = Depends(get_current_user), year: Optional[int] = None):
    year = year or datetime.now(timezone.utc).year
    deposits = await db.deposits.find({"user_id": user["id"]}, {"_id": 0}).to_list(2000)
    trips = await db.trips.find({"user_id": user["id"], "status": "completed"}, {"_id": 0, "points": 0}).to_list(2000)
    expenses = await db.expenses.find({"user_id": user["id"]}, {"_id": 0}).to_list(2000)

    deposits = [d for d in deposits if d["date"].startswith(str(year))]
    trips = [t for t in trips if (t.get("start_time") or "").startswith(str(year))]
    expenses = [e for e in expenses if e["date"].startswith(str(year))]

    gross = sum(d["amount"] for d in deposits)
    miles = sum(t.get("miles", 0) for t in trips)
    mileage_deduction = round(miles * IRS_MILEAGE_RATE, 2)
    expense_total = sum(e["amount"] for e in expenses)
    net_income = max(0.0, gross - mileage_deduction - expense_total)

    se_tax = round(net_income * SE_TAX_RATE, 2)
    state_rate = STATE_TAX_RATES.get(user.get("state", "TX"), 0.0)
    # Approximate fed income tax on top of SE @ a simple 12% bracket
    fed_income_tax = round(max(0.0, net_income - se_tax/2) * 0.12, 2)
    state_tax = round(net_income * state_rate, 2)
    estimated_tax = round(se_tax + fed_income_tax + state_tax, 2)

    today = date.today()
    due_dates = _quarter_due_dates(year)
    next_due = next((q for q in due_dates if q[0] >= today), due_dates[-1])
    next_quarterly_amount = round(estimated_tax / 4, 2)
    days_until = (next_due[0] - today).days

    deposits_savings = sum(d.get("savings_set_aside", 0) for d in deposits)

    return {
        "year": year,
        "gross_income": round(gross, 2),
        "total_miles": round(miles, 2),
        "mileage_deduction": mileage_deduction,
        "expense_total": round(expense_total, 2),
        "net_income": round(net_income, 2),
        "se_tax": se_tax,
        "fed_income_tax": fed_income_tax,
        "state_tax": state_tax,
        "state_rate": state_rate,
        "estimated_tax": estimated_tax,
        "next_quarterly": {
            "label": next_due[1],
            "due_date": next_due[0].isoformat(),
            "amount": next_quarterly_amount,
            "days_until": days_until,
        },
        "savings_recommended": round(deposits_savings, 2),
        "savings_balance": round(user.get("tax_savings_balance", 0.0), 2),
        "irs_mileage_rate": IRS_MILEAGE_RATE,
        "deposits_count": len(deposits),
        "trips_count": len(trips),
    }

# -------------------- AI CHAT --------------------
@api.post("/ai/chat")
async def ai_chat(body: ChatIn, user: dict = Depends(get_current_user)):
    sid = body.session_id or str(uuid.uuid4())
    chat = LlmChat(
        api_key=EMERGENT_LLM_KEY,
        session_id=sid,
        system_message=(
            "You are Milli AI, a tax assistant for gig delivery drivers (Uber, DoorDash, Spark, "
            "Lyft, Instacart, Amazon Flex). Give clear, practical answers about Schedule C, "
            "Schedule SE, quarterly estimated taxes, the standard mileage deduction, and common "
            "gig driver deductions. Be concise and confident. Always include the disclaimer that "
            "you are not a CPA and the user should verify with a tax professional for complex "
            f"situations. The current IRS standard mileage rate is ${IRS_MILEAGE_RATE}/mi."
        ),
    ).with_model("gemini", "gemini-3-flash-preview")

    async def gen():
        from emergentintegrations.llm.chat import TextDelta, StreamDone
        try:
            async for ev in chat.stream_message(UserMessage(text=body.message)):
                if isinstance(ev, TextDelta):
                    yield f"data: {ev.content}\n\n"
                elif isinstance(ev, StreamDone):
                    yield "data: [DONE]\n\n"
                    break
        except Exception as e:
            yield f"data: [ERROR] {str(e)}\n\n"

    return StreamingResponse(
        gen(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


# -------------------- WEEBO TTS (OpenAI) --------------------
class WeeboVoiceIn(BaseModel):
    text: str
    voice: Optional[str] = "shimmer"   # bright, cheerful — matches Weebo
    speed: Optional[float] = 1.0

@api.post("/ai/voice")
async def weebo_voice(body: WeeboVoiceIn, user: dict = Depends(get_current_user)):
    """Convert a chunk of Weebo's answer to MP3 for lip-sync playback.
    Keeps chunks small (<= 4096 chars per OpenAI limit) so the client can start
    playing as text streams in."""
    from emergentintegrations.llm.openai import OpenAITextToSpeech
    from fastapi.responses import Response
    txt = (body.text or "").strip()
    if not txt:
        raise HTTPException(status_code=400, detail="Empty text")
    if len(txt) > 4000:
        txt = txt[:4000]
    tts = OpenAITextToSpeech(api_key=EMERGENT_LLM_KEY)
    audio = await tts.generate_speech(
        text=txt,
        model="tts-1",             # fast — chosen for real-time chat
        voice=body.voice or "shimmer",
        speed=body.speed or 1.0,
    )
    return Response(
        content=audio,
        media_type="audio/mpeg",
        headers={"Cache-Control": "no-store", "X-Weebo-Voice": body.voice or "shimmer"},
    )


# -------------------- REFERRALS --------------------
class ReferralApplyIn(BaseModel):
    code: str

def _gen_referral_code(user_id: str) -> str:
    import hashlib
    h = hashlib.sha256(user_id.encode()).hexdigest()[:6].upper()
    return f"MILLI-{h}"

@api.get("/referral/me")
async def referral_me(user: dict = Depends(get_current_user)):
    """Return the user's own referral code + tally."""
    code = user.get("referral_code") or _gen_referral_code(str(user["id"]))
    if not user.get("referral_code"):
        await db.users.update_one({"id": user["id"]}, {"$set": {"referral_code": code}})
    invited = await db.users.count_documents({"referred_by_code": code})
    credit_cents = int(user.get("vault_credit_cents", 0))
    return {
        "code": code,
        "share_url": f"https://drivemilli.com/r/{code}",
        "invited_count": invited,
        "reward_cents": 1000,          # $10 both sides
        "credit_cents": credit_cents,
    }

@api.post("/referral/apply")
async def referral_apply(body: ReferralApplyIn, user: dict = Depends(get_current_user)):
    """Redeem a referral code. Both referrer + referred each earn $10 vault credit."""
    code = (body.code or "").strip().upper()
    if not code.startswith("MILLI-"):
        raise HTTPException(status_code=400, detail="Invalid code")
    if user.get("referred_by_code"):
        raise HTTPException(status_code=400, detail="You've already used a referral code")
    if user.get("referral_code") == code:
        raise HTTPException(status_code=400, detail="You can't refer yourself")
    referrer = await db.users.find_one({"referral_code": code})
    if not referrer:
        raise HTTPException(status_code=404, detail="Referral code not found")

    reward = 1000  # cents, $10
    await db.users.update_one(
        {"id": user["id"]},
        {"$set": {"referred_by_code": code}, "$inc": {"vault_credit_cents": reward}},
    )
    await db.users.update_one(
        {"id": referrer["id"]},
        {"$inc": {"vault_credit_cents": reward}},
    )
    return {"ok": True, "reward_cents": reward}


# -------------------- REPORTS / PDF --------------------
def _pdf_schedule_c(user: dict, summary: dict, deposits: list, trips: list, expenses: list) -> bytes:
    buf = io.BytesIO()
    c = pdfcanvas.Canvas(buf, pagesize=letter)
    w, h = letter
    y = h - 50
    c.setFillColor(colors.black)
    c.setFont("Helvetica-Bold", 18)
    c.drawString(50, y, "Schedule C — Profit or Loss From Business (Worksheet)")
    y -= 25
    c.setFont("Helvetica", 10)
    c.drawString(50, y, f"Prepared by Milli  |  Tax Year: {summary['year']}")
    y -= 18
    c.drawString(50, y, f"Taxpayer: {user.get('name')}  |  Email: {user.get('email')}  |  State: {user.get('state')}")
    y -= 28
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Part I — Income"); y -= 16
    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"1. Gross receipts (gig deposits): ${summary['gross_income']:,.2f}"); y -= 14
    c.drawString(70, y, f"7. Gross income: ${summary['gross_income']:,.2f}"); y -= 24

    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Part II — Expenses"); y -= 16
    c.setFont("Helvetica", 11)
    cat_totals = {}
    for e in expenses:
        cat_totals[e["category"]] = cat_totals.get(e["category"], 0) + e["amount"]
    for cat, amt in cat_totals.items():
        c.drawString(70, y, f"{cat.title()}: ${amt:,.2f}"); y -= 14
    c.drawString(70, y, f"9. Car & truck (standard mileage {summary['total_miles']:.1f} mi @ ${IRS_MILEAGE_RATE}/mi): ${summary['mileage_deduction']:,.2f}"); y -= 14
    c.drawString(70, y, f"28. Total expenses: ${(summary['expense_total'] + summary['mileage_deduction']):,.2f}"); y -= 24

    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, f"31. Net profit (loss):  ${summary['net_income']:,.2f}"); y -= 30

    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Estimated Federal Self-Employment Tax (Schedule SE)"); y -= 16
    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"Net SE earnings: ${summary['net_income']:,.2f}"); y -= 14
    c.drawString(70, y, f"SE Tax (15.3%): ${summary['se_tax']:,.2f}"); y -= 14
    c.drawString(70, y, f"Estimated Federal Income Tax (12% bracket est.): ${summary['fed_income_tax']:,.2f}"); y -= 14
    c.drawString(70, y, f"Estimated State Tax ({user.get('state')} {summary['state_rate']*100:.2f}%): ${summary['state_tax']:,.2f}"); y -= 20
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, f"TOTAL Estimated Tax Owed: ${summary['estimated_tax']:,.2f}"); y -= 30

    c.setFont("Helvetica-Oblique", 9)
    c.drawString(50, 40, "This is a worksheet generated by Milli. It is not an official IRS form. Consult a tax professional before filing.")
    c.showPage()
    c.save()
    return buf.getvalue()

@api.get("/reports/schedule-c.pdf")
async def report_schedule_c(user: dict = Depends(get_current_user), year: Optional[int] = None):
    # Plan gate — Schedule C PDF is a Pro+/Elite feature.
    plan = (user.get("plan") or "trial").lower()
    if plan in ("trial", "basic"):
        raise HTTPException(
            status_code=402,
            detail={
                "error": "plan_upgrade_required",
                "feature": "schedule_c_pdf",
                "required_plan": "pro",
                "message": "Schedule C PDF export is a Pro feature. Upgrade to download.",
            },
        )
    summary = await tax_summary(user, year)
    deposits = await db.deposits.find({"user_id": user["id"]}, {"_id": 0}).to_list(5000)
    trips = await db.trips.find({"user_id": user["id"], "status": "completed"}, {"_id": 0, "points": 0}).to_list(5000)
    expenses = await db.expenses.find({"user_id": user["id"]}, {"_id": 0}).to_list(5000)
    if year:
        deposits = [d for d in deposits if d["date"].startswith(str(year))]
        trips = [t for t in trips if (t.get("start_time") or "").startswith(str(year))]
        expenses = [e for e in expenses if e["date"].startswith(str(year))]
    pdf = _pdf_schedule_c(user, summary, deposits, trips, expenses)
    return StreamingResponse(
        io.BytesIO(pdf),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="schedule-c-{summary["year"]}.pdf"'},
    )

@api.get("/reports/mileage.csv")
async def mileage_csv(user: dict = Depends(get_current_user), year: Optional[int] = None):
    trips = await db.trips.find({"user_id": user["id"], "status": "completed"}, {"_id": 0, "points": 0}).to_list(5000)
    if year:
        trips = [t for t in trips if (t.get("start_time") or "").startswith(str(year))]
    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(["Date", "Platform", "Purpose", "Miles", "Deductible Value", "Start", "End", "Notes"])
    for t in sorted(trips, key=lambda x: x.get("start_time") or ""):
        w.writerow([
            (t.get("start_time") or "")[:10], t.get("platform") or "", t.get("purpose") or "",
            t.get("miles") or 0, t.get("deductible_value") or 0,
            t.get("start_address") or "", t.get("end_address") or "", t.get("notes") or "",
        ])
    return StreamingResponse(
        io.BytesIO(out.getvalue().encode("utf-8")),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="mileage-log-{year or datetime.now().year}.csv"'},
    )

# -------------------- STRIPE / SUBSCRIPTION --------------------
@api.post("/stripe/checkout")
async def stripe_checkout(body: CheckoutIn, request: Request, user: dict = Depends(get_current_user)):
    if body.tier not in PRICING_PACKAGES:
        raise HTTPException(400, "Invalid tier")
    pkg = PRICING_PACKAGES[body.tier]
    host_url = str(request.base_url).rstrip('/')
    webhook_url = f"{host_url}/api/webhook/stripe"
    sc = StripeCheckout(api_key=STRIPE_API_KEY, webhook_url=webhook_url)
    origin = body.origin_url.rstrip('/')
    success_url = f"{origin}/billing/success?session_id={{CHECKOUT_SESSION_ID}}"
    cancel_url = f"{origin}/pricing"
    metadata = {"user_id": user["id"], "tier": body.tier, "email": user["email"]}
    ckreq = CheckoutSessionRequest(
        amount=float(pkg["amount"]),
        currency=pkg["currency"],
        success_url=success_url,
        cancel_url=cancel_url,
        metadata=metadata,
    )
    session: CheckoutSessionResponse = await sc.create_checkout_session(ckreq)
    await db.payment_transactions.insert_one({
        "id": str(uuid.uuid4()),
        "session_id": session.session_id,
        "user_id": user["id"],
        "tier": body.tier,
        "amount": float(pkg["amount"]),
        "currency": pkg["currency"],
        "metadata": metadata,
        "payment_status": "initiated",
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    return {"url": session.url, "session_id": session.session_id}

@api.post("/stripe/portal")
async def stripe_billing_portal(request: Request, user: dict = Depends(get_current_user)):
    """
    Creates a Stripe Billing Portal session so the user can manage their
    subscription: update card, view invoices, cancel or upgrade.
    Returns a short-lived URL to redirect / open in an in-app browser.
    """
    import requests as _req
    body = await request.json() if await request.body() else {}
    return_url = body.get("return_url") or f"{str(request.base_url).rstrip('/')}/app/settings"

    # Resolve (or lazily create) the Stripe Customer for this user
    customer_id = (user.get("stripe") or {}).get("customer_id")
    if not customer_id:
        r = _req.post(
            "https://api.stripe.com/v1/customers",
            data={"email": user.get("email"), "name": user.get("name") or user.get("email")},
            auth=(STRIPE_API_KEY, ""), timeout=15,
        )
        if r.status_code >= 400:
            raise HTTPException(502, f"Stripe customer create failed: {r.text[:200]}")
        customer_id = r.json()["id"]
        await db.users.update_one({"id": user["id"]}, {"$set": {"stripe.customer_id": customer_id}})

    r = _req.post(
        "https://api.stripe.com/v1/billing_portal/sessions",
        data={"customer": customer_id, "return_url": return_url},
        auth=(STRIPE_API_KEY, ""), timeout=15,
    )
    if r.status_code >= 400:
        # Stripe requires the portal be configured once in Test Mode:
        # https://dashboard.stripe.com/test/settings/billing/portal
        raise HTTPException(
            502,
            f"Stripe portal not available: {r.json().get('error', {}).get('message', r.text[:200])}. "
            "Configure the Customer Portal once at dashboard.stripe.com/test/settings/billing/portal."
        )
    return {"url": r.json()["url"]}


@api.get("/stripe/status/{session_id}")
async def stripe_status(session_id: str, request: Request, user: dict = Depends(get_current_user)):
    host_url = str(request.base_url).rstrip('/')
    webhook_url = f"{host_url}/api/webhook/stripe"
    sc = StripeCheckout(api_key=STRIPE_API_KEY, webhook_url=webhook_url)
    status = await sc.get_checkout_status(session_id)
    tx = await db.payment_transactions.find_one({"session_id": session_id, "user_id": user["id"]})
    if not tx:
        raise HTTPException(404, "Transaction not found")
    if tx.get("payment_status") != "paid" and status.payment_status == "paid":
        await db.payment_transactions.update_one(
            {"session_id": session_id},
            {"$set": {"payment_status": "paid", "status": status.status}},
        )
        tier = tx["tier"]
        until = datetime.now(timezone.utc) + timedelta(days=30)
        await db.users.update_one(
            {"id": user["id"]},
            {"$set": {"plan": tier, "stripe_active_until": until.isoformat()}},
        )
    return {
        "status": status.status,
        "payment_status": status.payment_status,
        "amount_total": status.amount_total,
        "currency": status.currency,
    }

@app.post("/api/webhook/stripe")
async def stripe_webhook(request: Request):
    sc = StripeCheckout(api_key=STRIPE_API_KEY, webhook_url="")
    body = await request.body()
    signature = request.headers.get("Stripe-Signature", "")
    try:
        evt = await sc.handle_webhook(body, signature)
    except Exception as e:
        logging.exception("Stripe webhook error")
        return JSONResponse({"ok": False}, status_code=400)
    if evt.payment_status == "paid":
        tx = await db.payment_transactions.find_one({"session_id": evt.session_id})
        if tx and tx.get("payment_status") != "paid":
            await db.payment_transactions.update_one(
                {"session_id": evt.session_id},
                {"$set": {"payment_status": "paid"}},
            )
            user_id = (evt.metadata or {}).get("user_id")
            tier = (evt.metadata or {}).get("tier")
            if user_id and tier:
                until = datetime.now(timezone.utc) + timedelta(days=30)
                await db.users.update_one(
                    {"id": user_id},
                    {"$set": {"plan": tier, "stripe_active_until": until.isoformat()}},
                )
    return {"ok": True}

@api.get("/pricing/tiers")
async def get_tiers():
    return [
        {"id": "basic", "name": "Basic", "price": 19.99, "trial_days": 3, "features": [
            "Unlimited live mileage tracking", "Plaid bank deposits sync", "Year-end mileage CSV",
            "Quarterly tax estimates", "Email reminders",
        ]},
        {"id": "pro", "name": "Pro", "price": 29.99, "trial_days": 3, "features": [
            "Everything in Basic", "Receipt OCR scanner (AI)", "AI tax assistant chat",
            "Schedule C worksheet PDF", "27% smart tax savings allocation",
        ], "popular": True},
        {"id": "elite", "name": "Elite", "price": 49.99, "trial_days": 3, "features": [
            "Everything in Pro",
            "Auto 401(k) + Brokerage contributions per deposit",
            "Auto Federal + State tax filing (via licensed partner)",
            "Auto-generated Schedule C + SE forms",
            "Auto tax-savings bucket per deposit",
            "Priority Milli AI assistant",
            "Year-end CPA review checklist",
            "Audit-ready mileage log",
        ]},
    ]

# -------------------- TAX VAULT --------------------
class VaultSetupIn(BaseModel):
    institution_name: Optional[str] = "Milli Reserve (Demo Partner)"
    account_nickname: Optional[str] = "Tax Vault"

class VaultPlaidConnectIn(BaseModel):
    public_token: str
    institution_name: Optional[str] = None
    account_id: Optional[str] = None
    account_name: Optional[str] = None
    account_mask: Optional[str] = None
    account_subtype: Optional[str] = None

class VaultRuleIn(BaseModel):
    mode: Optional[str] = None  # auto | approval | manual
    strategy: Optional[str] = None  # conservative | balanced | minimum
    fixed_percentage: Optional[float] = None  # if None → use Milli-calculated
    min_checking_balance: Optional[float] = None
    max_daily_transfer: Optional[float] = None
    paused: Optional[bool] = None

class VaultTransferIn(BaseModel):
    amount: float
    direction: str  # in | out
    note: Optional[str] = None

class QuarterlyPaymentIn(BaseModel):
    period: str  # Q1 / Q2 / Q3 / Q4
    year: int
    amount: float
    paid_on: Optional[str] = None
    confirmation: Optional[str] = None
    method: Optional[str] = "IRS Direct Pay"

STRATEGY_RATIOS = {"conservative": 0.30, "balanced": 0.25, "minimum": 0.20}

async def _get_vault(user_id: str):
    return await db.tax_vaults.find_one({"user_id": user_id}, {"_id": 0})

@api.post("/vault/setup")
async def vault_setup(body: VaultSetupIn, user: dict = Depends(get_current_user)):
    existing = await _get_vault(user["id"])
    if existing:
        return existing
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "institution_name": body.institution_name,
        "account_nickname": body.account_nickname,
        "account_number_masked": "****" + str(uuid.uuid4().int)[-4:],
        "routing_number_masked": "****" + str(uuid.uuid4().int)[-4:],
        "provider_type": "milli_reserve",
        "balance": 0.0,
        "interest_earned_ytd": 0.0,
        "rule": {
            "mode": "auto",
            "strategy": "balanced",
            "fixed_percentage": None,
            "min_checking_balance": 200.0,
            "max_daily_transfer": 1000.0,
            "paused": False,
        },
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.tax_vaults.insert_one(doc)
    doc.pop("_id", None)
    return doc

@api.get("/vault")
async def vault_get(user: dict = Depends(get_current_user)):
    v = await _get_vault(user["id"])
    if not v:
        return None
    transfers = await db.vault_transfers.find({"user_id": user["id"]}, {"_id": 0}).sort("created_at", -1).to_list(100)
    v["transfers"] = transfers
    return v

@api.put("/vault/rule")
async def vault_rule(body: VaultRuleIn, user: dict = Depends(get_current_user)):
    v = await _get_vault(user["id"])
    if not v:
        raise HTTPException(404, "Vault not set up")
    rule = v.get("rule", {})
    payload = body.dict()
    # Allow explicit clearing of fixed_percentage by passing null
    if payload.get("fixed_percentage") is None and "fixed_percentage" in body.__fields_set__:
        rule["fixed_percentage"] = None
    for k, val in body.dict(exclude_none=True).items():
        rule[k] = val
    await db.tax_vaults.update_one({"user_id": user["id"]}, {"$set": {"rule": rule}})
    return rule

@api.post("/vault/transfer")
async def vault_transfer(body: VaultTransferIn, user: dict = Depends(get_current_user)):
    v = await _get_vault(user["id"])
    if not v:
        raise HTTPException(400, "Set up the Tax Vault first")
    amt = round(float(body.amount), 2)
    if amt <= 0:
        raise HTTPException(400, "Amount must be > 0")
    delta = amt if body.direction == "in" else -amt
    new_balance = round(v.get("balance", 0) + delta, 2)
    if new_balance < 0:
        raise HTTPException(400, "Insufficient Vault balance")
    tx = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "direction": body.direction,
        "amount": amt,
        "balance_after": new_balance,
        "note": body.note or ("Auto reserve" if body.direction == "in" else "Withdrawal"),
        "source": "manual",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.vault_transfers.insert_one(tx)
    await db.tax_vaults.update_one({"user_id": user["id"]}, {"$set": {"balance": new_balance}})
    await db.users.update_one({"id": user["id"]}, {"$set": {"tax_savings_balance": new_balance}})
    tx.pop("_id", None)
    return tx

# Modified manual deposit to auto-reserve if vault + auto mode
@api.post("/deposits/manual-v2")
async def add_manual_deposit_v2(body: dict, user: dict = Depends(get_current_user)):
    amount = float(body.get("amount", 0))
    if amount <= 0:
        raise HTTPException(400, "Amount must be > 0")
    # Milli Autopilot™ owns the allocation math — the payout row itself is a
    # simple record of the inbound money, without pre-computed savings.
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "transaction_id": f"manual_{uuid.uuid4()}",
        "plaid_item_id": None,
        "date": body.get("date") or datetime.now(timezone.utc).date().isoformat(),
        "merchant": body.get("merchant") or body.get("platform") or "Manual",
        "platform": body.get("platform") or "Manual",
        "amount": amount,
        "savings_set_aside": 0.0,
        "auto_allocated": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.deposits.insert_one(doc)
    receipt = await _run_autopilot(db, user, doc)
    doc["autopilot_receipt"] = receipt
    doc.pop("_id", None)
    return doc

# -------------------- SMART ACCOUNTS: 401K & INVESTING --------------------
# Both follow the same pattern as the Tax Vault — a user-owned account with auto-allocation
# rules that skim a % of each detected deposit.

SMART_ACCOUNT_CONFIG = {
    "retirement": {
        "collection": "retirement_accounts",
        "transfers": "retirement_transfers",
        "default_pct": 0.08,
        "default_partner": "Milli Retirement (Demo Custodian)",
        "default_nickname": "Solo 401(k)",
        "user_balance_field": "retirement_balance",
    },
    "investing": {
        "collection": "investment_accounts",
        "transfers": "investment_transfers",
        "default_pct": 0.05,
        "default_partner": "Milli Invest (Demo Brokerage)",
        "default_nickname": "Brokerage Account",
        "user_balance_field": "investing_balance",
    },
}

class SmartSetupIn(BaseModel):
    institution_name: Optional[str] = None
    account_nickname: Optional[str] = None

class SmartRuleIn(BaseModel):
    mode: Optional[str] = None  # auto | manual
    fixed_percentage: Optional[float] = None
    max_daily_transfer: Optional[float] = None
    paused: Optional[bool] = None

class SmartTransferIn(BaseModel):
    amount: float
    direction: str  # in | out
    note: Optional[str] = None

def _smart_cfg(kind: str):
    if kind not in SMART_ACCOUNT_CONFIG:
        raise HTTPException(404, "Unknown account type")
    return SMART_ACCOUNT_CONFIG[kind]

async def _smart_get(kind: str, user_id: str):
    cfg = _smart_cfg(kind)
    return await db[cfg["collection"]].find_one({"user_id": user_id}, {"_id": 0})

@api.post("/smart/{kind}/setup")
async def smart_setup(kind: str, body: SmartSetupIn, user: dict = Depends(get_current_user)):
    # Gate retirement + investing to Pro / Elite plans.
    plan = (user.get("plan") or "trial").lower()
    if kind == "retirement" and plan not in ("trial", "pro", "elite"):
        raise HTTPException(402, {
            "error": "plan_upgrade_required", "feature": "retirement",
            "current_plan": plan, "upgrade_to": "pro",
        })
    if kind == "investing" and plan not in ("trial", "pro", "elite"):
        raise HTTPException(402, {
            "error": "plan_upgrade_required", "feature": "investing",
            "current_plan": plan, "upgrade_to": "pro",
        })
    cfg = _smart_cfg(kind)
    existing = await _smart_get(kind, user["id"])
    if existing:
        return existing
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "kind": kind,
        "institution_name": body.institution_name or cfg["default_partner"],
        "account_nickname": body.account_nickname or cfg["default_nickname"],
        "account_number_masked": "****" + str(uuid.uuid4().int)[-4:],
        "balance": 0.0,
        "ytd_growth": 0.0,
        "rule": {
            "mode": "auto",
            "fixed_percentage": cfg["default_pct"],
            "max_daily_transfer": 500.0,
            "paused": False,
        },
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db[cfg["collection"]].insert_one(doc)
    doc.pop("_id", None)
    return doc

@api.get("/smart/{kind}")
async def smart_get(kind: str, user: dict = Depends(get_current_user)):
    cfg = _smart_cfg(kind)
    a = await _smart_get(kind, user["id"])
    if not a:
        return None
    transfers = await db[cfg["transfers"]].find({"user_id": user["id"]}, {"_id": 0}).sort("created_at", -1).to_list(100)
    a["transfers"] = transfers
    return a

@api.put("/smart/{kind}/rule")
async def smart_rule(kind: str, body: SmartRuleIn, user: dict = Depends(get_current_user)):
    cfg = _smart_cfg(kind)
    a = await _smart_get(kind, user["id"])
    if not a:
        raise HTTPException(404, "Account not set up")
    rule = a.get("rule", {})
    # Allow explicit clearing of fixed_percentage
    if body.fixed_percentage is None and "fixed_percentage" in body.__fields_set__:
        rule["fixed_percentage"] = None
    for k, v in body.dict(exclude_none=True).items():
        rule[k] = v
    await db[cfg["collection"]].update_one({"user_id": user["id"]}, {"$set": {"rule": rule}})
    return rule

@api.post("/smart/{kind}/transfer")
async def smart_transfer(kind: str, body: SmartTransferIn, user: dict = Depends(get_current_user)):
    cfg = _smart_cfg(kind)
    a = await _smart_get(kind, user["id"])
    if not a:
        raise HTTPException(400, "Set up the account first")
    amt = round(float(body.amount), 2)
    if amt <= 0:
        raise HTTPException(400, "Amount must be > 0")
    delta = amt if body.direction == "in" else -amt
    new_balance = round(a.get("balance", 0) + delta, 2)
    if new_balance < 0:
        raise HTTPException(400, "Insufficient balance")
    tx = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "direction": body.direction,
        "amount": amt,
        "balance_after": new_balance,
        "note": body.note or ("Auto contribution" if body.direction == "in" else "Withdrawal"),
        "source": "manual",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db[cfg["transfers"]].insert_one(tx)
    await db[cfg["collection"]].update_one({"user_id": user["id"]}, {"$set": {"balance": new_balance}})
    await db.users.update_one({"id": user["id"]}, {"$set": {cfg["user_balance_field"]: new_balance}})
    tx.pop("_id", None)
    return tx

async def _smart_auto_allocate(user: dict, deposit: dict):
    """Run auto-allocation for both retirement + investing accounts when a deposit lands."""
    for kind, cfg in SMART_ACCOUNT_CONFIG.items():
        a = await _smart_get(kind, user["id"])
        if not a:
            continue
        rule = a.get("rule", {})
        if rule.get("paused") or rule.get("mode") != "auto":
            continue
        pct = rule.get("fixed_percentage") or cfg["default_pct"]
        amt = round(deposit["amount"] * pct, 2)
        if amt <= 0:
            continue
        new_balance = round(a.get("balance", 0) + amt, 2)
        await db[cfg["transfers"]].insert_one({
            "id": str(uuid.uuid4()),
            "user_id": user["id"],
            "direction": "in",
            "amount": amt,
            "balance_after": new_balance,
            "note": f"Auto from {deposit.get('platform', 'deposit')} (${deposit['amount']:.2f})",
            "source": "auto",
            "deposit_id": deposit["id"],
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        await db[cfg["collection"]].update_one({"user_id": user["id"]}, {"$set": {"balance": new_balance}})
        await db.users.update_one({"id": user["id"]}, {"$set": {cfg["user_balance_field"]: new_balance}})


@api.get("/quarterly")
async def quarterly_overview(user: dict = Depends(get_current_user), year: Optional[int] = None):
    year = year or datetime.now(timezone.utc).year
    summary = await tax_summary(user, year)
    payments = await db.quarterly_payments.find({"user_id": user["id"], "year": year}, {"_id": 0}).to_list(100)
    paid_by_q = {p["period"]: p for p in payments}
    quarters = []
    today = date.today()
    for d, label in _quarter_due_dates(year):
        q_amount = round(summary["estimated_tax"] / 4, 2)
        paid = paid_by_q.get(label)
        vault = await _get_vault(user["id"])
        reserved = round(min((vault or {}).get("balance", 0), q_amount), 2)
        readiness = 100 if paid else (round(reserved / q_amount * 100) if q_amount else 0)
        quarters.append({
            "period": label,
            "due_date": d.isoformat(),
            "amount": q_amount,
            "reserved": reserved,
            "readiness": min(100, readiness),
            "days_until": (d - today).days,
            "status": "paid" if paid else ("overdue" if d < today else "upcoming"),
            "payment": paid,
        })
    return {"year": year, "quarters": quarters, "annual_estimate": summary["estimated_tax"]}

@api.post("/quarterly/payment")
async def record_quarterly_payment(body: QuarterlyPaymentIn, user: dict = Depends(get_current_user)):
    if body.period not in ("Q1", "Q2", "Q3", "Q4"):
        raise HTTPException(400, "Invalid period")
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "period": body.period,
        "year": int(body.year),
        "amount": float(body.amount),
        "paid_on": body.paid_on or datetime.now(timezone.utc).date().isoformat(),
        "confirmation": body.confirmation,
        "method": body.method or "IRS Direct Pay",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.quarterly_payments.insert_one(doc)
    doc.pop("_id", None)
    return doc

# -------------------- DEMO MODE --------------------
@api.post("/demo/seed")
async def demo_seed(request: Request):
    """Create or refresh the demo account in explicitly enabled local environments."""
    if APP_ENV == "production" or not DEMO_MODE_ENABLED:
        raise HTTPException(status_code=404, detail="Not found")
    expected_secret = os.environ.get("DEMO_SEED_SECRET", "")
    supplied_secret = request.headers.get("X-Demo-Seed-Secret", "")
    if not expected_secret or not hmac.compare_digest(supplied_secret, expected_secret):
        raise HTTPException(status_code=403, detail="Invalid demo seed secret")
    email = "demo@milli.app"
    user = await db.users.find_one({"email": email})
    if user:
        # Wipe existing demo data to keep it fresh
        uid = user["id"]
        await db.deposits.delete_many({"user_id": uid})
        await db.trips.delete_many({"user_id": uid})
        await db.expenses.delete_many({"user_id": uid})
        await db.vault_transfers.delete_many({"user_id": uid})
        await db.tax_vaults.delete_many({"user_id": uid})
        await db.quarterly_payments.delete_many({"user_id": uid})
        await db.retirement_accounts.delete_many({"user_id": uid})
        await db.investment_accounts.delete_many({"user_id": uid})
        await db.retirement_transfers.delete_many({"user_id": uid})
        await db.investment_transfers.delete_many({"user_id": uid})
        await db.autopilot_receipts.delete_many({"user_id": uid})
        await db.savings_transfers.delete_many({"user_id": uid})
    else:
        uid = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        await db.users.insert_one({
            "id": uid,
            "email": email,
            "name": "Jordan Taylor",
            "state": "CA",
            "filing_status": "single",
            "password_hash": hash_password("milli-demo-2026"),
            "plan": "elite",
            "trial_end": (now + timedelta(days=30)).isoformat(),
            "stripe_active_until": (now + timedelta(days=30)).isoformat(),
            "plaid_items": [],
            "tax_savings_balance": 0.0,
            "created_at": now.isoformat(),
        })

    # Seed deposits across 6 months
    import random
    random.seed(42)
    today = date.today()
    platforms = ["DoorDash", "Uber", "Spark", "Lyft", "Instacart", "Upwork"]
    total_gross = 0.0

    # Delete any prior Autopilot receipts + savings transfers for demo before seeding
    await db.autopilot_receipts.delete_many({"user_id": uid})
    await db.savings_transfers.delete_many({"user_id": uid})

    # Ensure demo user has Autopilot settings and cleared balances before we run
    # the pipeline, so the seeded deposits produce clean, well-ordered receipts.
    await db.users.update_one({"id": uid}, {"$set": {
        "autopilot_settings": {
            "tax_enabled": True,
            "retirement_pct": 0.08,   # demo user is aggressive
            "investing_pct": 0.05,
            "savings_pct": 0.02,
            "version": 1,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
        "available_to_spend": 0.0,
        "savings_balance": 0.0,
        "tax_savings_balance": 0.0,
        "retirement_balance": 0.0,
        "investing_balance": 0.0,
    }})

    demo_deposits = []
    for i in range(40):
        plat = random.choice(platforms)
        amt = round(random.uniform(45, 285), 2)
        d_date = (today - timedelta(days=random.randint(0, 180))).isoformat()
        doc = {
            "id": str(uuid.uuid4()),
            "user_id": uid,
            "transaction_id": f"demo_{uuid.uuid4()}",
            "plaid_item_id": None,
            "date": d_date,
            "merchant": plat,
            "platform": plat,
            "amount": amt,
            "savings_set_aside": 0.0,
            "auto_allocated": True,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        await db.deposits.insert_one(doc)
        demo_deposits.append(doc)
        total_gross += amt

    # Run Autopilot on every seeded deposit so the demo shows real receipts.
    demo_user_doc = await db.users.find_one({"id": uid})
    for dep in sorted(demo_deposits, key=lambda d: d["date"]):
        try:
            await _run_autopilot(db, demo_user_doc, dep)
            # Refresh user doc so subsequent runs see updated balances
            demo_user_doc = await db.users.find_one({"id": uid})
        except Exception as ap_err:
            logging.warning("Autopilot seed run failed for %s: %s", dep["id"], ap_err)

    # Seed mileage trips
    total_miles = 0.0
    for i in range(28):
        miles = round(random.uniform(8, 95), 2)
        plat = random.choice(platforms[:5])
        d_date = (today - timedelta(days=random.randint(0, 120)))
        await db.trips.insert_one({
            "id": str(uuid.uuid4()),
            "user_id": uid,
            "status": "completed",
            "purpose": "delivery" if plat != "Upwork" else "client_meeting",
            "platform": plat,
            "start_address": None,
            "end_address": None,
            "start_time": f"{d_date.isoformat()}T09:00:00Z",
            "end_time": f"{d_date.isoformat()}T17:00:00Z",
            "miles": miles,
            "deductible_value": round(miles * IRS_MILEAGE_RATE, 2),
            "manual": True,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        total_miles += miles

    # Seed expenses
    cats = [("gas", "Shell"), ("gas", "Chevron"), ("maintenance", "Jiffy Lube"),
            ("phone", "Verizon"), ("supplies", "Amazon"), ("food", "Chipotle"),
            ("software", "Adobe"), ("insurance", "Geico")]
    for i in range(18):
        cat, merch = random.choice(cats)
        amt = round(random.uniform(12, 180), 2)
        await db.expenses.insert_one({
            "id": str(uuid.uuid4()),
            "user_id": uid,
            "date": (today - timedelta(days=random.randint(0, 150))).isoformat(),
            "amount": amt,
            "category": cat if cat != "software" else "other",
            "merchant": merch,
            "notes": None,
            "receipt_url": None,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })

    # Autopilot already created the Tax Vault, Retirement, and Investing accounts
    # with correct running balances via the per-deposit pipeline runs above.
    # We only need to update the vault's institution name for demo display.
    await db.tax_vaults.update_one({"user_id": uid}, {"$set": {
        "institution_name": "Milli Reserve (Demo Partner)",
        "account_nickname": "Milli Tax Vault™",
        "account_number_masked": "****4821",
    }})
    await db.retirement_accounts.update_one({"user_id": uid}, {"$set": {
        "institution_name": "Milli Retirement (Demo Custodian)",
        "account_nickname": "Solo 401(k)",
        "account_number_masked": "****7245",
    }})
    await db.investment_accounts.update_one({"user_id": uid}, {"$set": {
        "institution_name": "Milli Invest (Demo Brokerage)",
        "account_nickname": "Brokerage Account",
        "account_number_masked": "****3318",
    }})

    # Refresh totals used by the rest of the seed script
    demo_vault = await db.tax_vaults.find_one({"user_id": uid}) or {}
    demo_ret = await db.retirement_accounts.find_one({"user_id": uid}) or {}
    demo_inv = await db.investment_accounts.find_one({"user_id": uid}) or {}
    vault_balance = round(demo_vault.get("balance", 0.0), 2)
    ret_balance = round(demo_ret.get("balance", 0.0), 2)
    inv_balance = round(demo_inv.get("balance", 0.0), 2)

    # Autopilot has already created ~40 real vault_transfers linked to receipts,
    # so we don't seed synthetic ones. Move on to the Q1 payment record.

    # Record Q1 payment
    await db.quarterly_payments.insert_one({
        "id": str(uuid.uuid4()),
        "user_id": uid,
        "period": "Q1",
        "year": today.year,
        "amount": 2860.0,
        "paid_on": f"{today.year}-04-15",
        "confirmation": "IRS-DP-2026-04812",
        "method": "IRS Direct Pay",
        "created_at": datetime.now(timezone.utc).isoformat(),
    })

    return {"token": create_token(uid, email), "user": {"id": uid, "email": email, "name": "Jordan Taylor", "plan": "elite"}}


@api.get("/")
async def root():
    return {"name": "Milli", "ok": True}


@api.get("/health")
async def health():
    """Public health check — used by the iOS app on boot to catch stale bundles."""
    return {
        "ok": True,
        "service": "milli-api",
        "version": os.environ.get("MILLI_API_VERSION", "1.0.0"),
        "time": datetime.now(timezone.utc).isoformat(),
    }


# -------------------- MILLI AUTOPILOT™ --------------------
class AutopilotSettingsIn(BaseModel):
    tax_enabled: Optional[bool] = None
    retirement_pct: Optional[float] = None
    investing_pct: Optional[float] = None
    savings_pct: Optional[float] = None


@api.get("/autopilot/settings")
async def get_autopilot_settings(user: dict = Depends(get_current_user)):
    return await _get_autopilot_settings(db, user["id"])


@api.put("/autopilot/settings")
async def put_autopilot_settings(body: AutopilotSettingsIn,
                                 user: dict = Depends(get_current_user)):
    return await _update_autopilot_settings(db, user["id"], body.dict(exclude_none=True))


@api.get("/autopilot/receipts")
async def list_autopilot_receipts(
    user: dict = Depends(get_current_user),
    limit: int = 50,
):
    cursor = db.autopilot_receipts.find(
        {"user_id": user["id"]}, {"_id": 0}
    ).sort("created_at", -1).limit(max(1, min(int(limit), 200)))
    return await cursor.to_list(length=200)


@api.get("/autopilot/receipts/{receipt_id}")
async def get_autopilot_receipt(receipt_id: str,
                                 user: dict = Depends(get_current_user)):
    receipt = await db.autopilot_receipts.find_one(
        {"id": receipt_id, "user_id": user["id"]}, {"_id": 0}
    )
    if not receipt:
        raise HTTPException(404, "Receipt not found")
    return receipt


@api.get("/dashboard/snapshot")
async def dashboard_snapshot(user: dict = Depends(get_current_user)):
    """Aggregated hero-card snapshot for the Home dashboard (Autopilot-aware)."""
    return await _autopilot_snapshot(db, user["id"])


# -------------------- MARKETING ASSETS --------------------
MARKETING_DIR = Path("/app/marketing_videos")


@api.get("/marketing/videos")
async def list_marketing_videos(user: dict = Depends(get_current_user)):
    """List generated marketing clips. PRIVATE — auth required, owner-only view."""
    import json as _json
    log_path = MARKETING_DIR / "generation_log.json"
    if not log_path.exists():
        return {"clips": []}
    log = _json.loads(log_path.read_text())

    titles = {
        "01_cinematic_luxury": "Cinematic Luxury — Skyline",
        "02_driver_pov_hud": "Driver POV — Night HUD",
        "03_lifestyle_gigworker": "Lifestyle — Gig Worker Smile",
        "04_product_kinetic_type": "Product — Kinetic Typography",
        "05_hero_montage": "Hero Brand Montage",
    }
    clips = []
    for cid, meta in log.items():
        ready = meta.get("status") == "done"
        clips.append({
            "id": cid,
            "title": titles.get(cid, meta.get("title", cid)),
            "size": meta.get("size"),
            "orientation": "vertical" if meta.get("size", "").startswith("720") else "landscape",
            "duration": meta.get("duration"),
            "ready": ready,
            "status": meta.get("status"),
            "url": f"/api/marketing/videos/{cid}.mp4" if ready else None,
        })
    # Stable order by id
    clips.sort(key=lambda c: c["id"])
    return {"clips": clips}


@api.get("/marketing/videos/{filename}")
async def get_marketing_video(filename: str, user: dict = Depends(get_current_user)):
    """Stream a generated MP4. PRIVATE — auth required."""
    from fastapi.responses import FileResponse
    if not filename.endswith(".mp4") or "/" in filename or ".." in filename:
        raise HTTPException(status_code=400, detail="Invalid filename")
    path = MARKETING_DIR / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail="Video not found")
    return FileResponse(path, media_type="video/mp4", filename=filename)


# =====================================================================
# Apple In-App Purchase (StoreKit 2) — subscription verification
# =====================================================================
# Env vars required for full production validation against the App Store
# Server API (leave unset in development — endpoint degrades gracefully):
#   APPLE_ISSUER_ID       — from App Store Connect > Users and Access > IAP
#   APPLE_KEY_ID          — 10-char key id shown next to the .p8
#   APPLE_PRIVATE_KEY     — contents of AuthKey_XXXX.p8 (raw ES256)
#   APPLE_IAP_ENVIRONMENT — "Sandbox" or "Production" (default: Sandbox)
# =====================================================================

APPLE_BUNDLE_ID = "app.milli.tax"
APPLE_ISSUER_ID = os.environ.get("APPLE_ISSUER_ID", "")
APPLE_KEY_ID = os.environ.get("APPLE_KEY_ID", "")
APPLE_PRIVATE_KEY = os.environ.get("APPLE_PRIVATE_KEY", "")
APPLE_IAP_ENV = os.environ.get("APPLE_IAP_ENVIRONMENT", "Sandbox")

# Product-ID → plan mapping (must match Products.storekit + App Store Connect)
IAP_PRODUCT_TO_PLAN = {
    "milli.basic.monthly": "basic",
    "milli.pro.monthly":   "pro",
    "milli.elite.monthly": "elite",
}


def _generate_apple_iap_token() -> str:
    """ES256-signed JWT for the App Store Server API. Raises if unconfigured."""
    if not (APPLE_ISSUER_ID and APPLE_KEY_ID and APPLE_PRIVATE_KEY):
        raise HTTPException(
            status_code=503,
            detail="Apple IAP not configured on server (missing ISSUER_ID/KEY_ID/PRIVATE_KEY)."
        )
    import time as _t
    now = int(_t.time())
    return jwt.encode(
        {
            "iss": APPLE_ISSUER_ID,
            "iat": now,
            "exp": now + 1800,
            "aud": "appstoreconnect-v1",
            "bid": APPLE_BUNDLE_ID,
        },
        APPLE_PRIVATE_KEY,
        algorithm="ES256",
        headers={"alg": "ES256", "kid": APPLE_KEY_ID, "typ": "JWT"},
    )


class IAPValidateIn(BaseModel):
    transactionId: str
    productId: Optional[str] = None  # optional client hint for logging


@api.post("/subscriptions/verify-receipt")
async def verify_apple_receipt(body: IAPValidateIn, user: dict = Depends(get_current_user)):
    if not body.transactionId or not body.transactionId.strip():
        raise HTTPException(status_code=400, detail="Missing transactionId")
    if body.productId and body.productId not in IAP_PRODUCT_TO_PLAN:
        raise HTTPException(status_code=400, detail="Unknown StoreKit product")
    """
    Verify a StoreKit 2 transaction with Apple and upgrade the user's plan.

    On success, returns:
      { "status": "active", "plan": "elite", "productId": "milli.elite.monthly",
        "expiresAt": <epoch ms> }
    """
    # Best-effort call: if Apple creds aren't wired yet we still record the
    # attempt so the mobile client can proceed in dev/TestFlight.
    try:
        token = _generate_apple_iap_token()
    except HTTPException:
        # Unverified StoreKit is never allowed in production and must be
        # explicitly enabled for local/TestFlight development.
        if APP_ENV != "production" and ALLOW_UNVERIFIED_STOREKIT:
            plan = IAP_PRODUCT_TO_PLAN.get(body.productId or "")
            if not plan:
                raise HTTPException(status_code=400, detail="Unknown StoreKit product")
            logging.warning("Accepting explicitly enabled unverified sandbox txn %s", body.transactionId)
            await db.users.update_one(
                {"id": user["id"]},
                {"$set": {
                    "plan": plan,
                    "subscription": {
                        "status": "active",
                        "product_id": body.productId,
                        "transaction_id": body.transactionId,
                        "environment": "Sandbox",
                        "verified_at": datetime.now(timezone.utc).isoformat(),
                        "expires_at": None,
                    },
                }},
            )
            return {"status": "active", "plan": plan, "productId": body.productId, "expiresAt": None, "sandbox": True}
        raise

    import requests as _requests
    base = ("https://api.storekit.itunes.apple.com" if APPLE_IAP_ENV == "Production"
            else "https://api.storekit-sandbox.itunes.apple.com")
    url = f"{base}/inApps/v1/transactions/{body.transactionId}"
    resp = _requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=15)
    if resp.status_code != 200:
        raise HTTPException(status_code=400, detail=f"Apple validation failed: {resp.status_code} {resp.text[:200]}")

    payload = resp.json()
    jws = payload.get("signedTransactionInfo", "")
    # StoreKit 2 payloads are JWS-signed. Apple guarantees integrity over TLS,
    # so we decode without local verification (matches Apple's official flow).
    decoded = jwt.decode(jws, options={"verify_signature": False})
    product_id = decoded.get("productId")
    expires_ms = decoded.get("expiresDate")
    plan = IAP_PRODUCT_TO_PLAN.get(product_id)
    if not plan:
        raise HTTPException(status_code=400, detail="Apple returned an unknown StoreKit product")

    await db.users.update_one(
        {"id": user["id"]},
        {"$set": {
            "plan": plan,
            "subscription": {
                "status": "active",
                "product_id": product_id,
                "transaction_id": body.transactionId,
                "environment": APPLE_IAP_ENV,
                "verified_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": expires_ms,
            },
        }},
    )
    return {"status": "active", "plan": plan, "productId": product_id, "expiresAt": expires_ms}


@api.post("/subscriptions/webhook")
async def apple_iap_webhook(request: Request):
    if APP_ENV == "production":
        # The current implementation does not yet validate Apple's x5c JWS
        # certificate chain. Reject production webhooks rather than trust
        # attacker-controlled unsigned claims.
        raise HTTPException(status_code=503, detail="Verified Apple webhook handling is not configured")
    """
    App Store Server Notifications V2 endpoint. Configure this URL in
    App Store Connect > App Information > App Store Server Notifications.
    Handles renewals, cancellations, refunds while the app is closed.
    """
    payload = await request.json()
    signed = payload.get("signedPayload", "")
    try:
        outer = jwt.decode(signed, options={"verify_signature": False})
        notif_type = outer.get("notificationType")
        data = outer.get("data", {})
        signed_tx = data.get("signedTransactionInfo", "")
        tx = jwt.decode(signed_tx, options={"verify_signature": False}) if signed_tx else {}
        product_id = tx.get("productId")
        transaction_id = tx.get("transactionId")
        expires_ms = tx.get("expiresDate")

        if not transaction_id:
            return {"received": True, "ignored": True}

        # Find the user by transaction id (recorded during initial verify)
        user_doc = await db.users.find_one({"subscription.transaction_id": transaction_id})
        if not user_doc:
            logging.warning("Apple webhook %s: no user with transaction_id=%s", notif_type, transaction_id)
            return {"received": True, "unknown_user": True}

        new_status = "active"
        if notif_type in ("EXPIRED", "REFUND", "REVOKE"):
            new_status = "expired"
        elif notif_type in ("DID_FAIL_TO_RENEW",):
            new_status = "grace"

        await db.users.update_one(
            {"_id": user_doc["_id"]},
            {"$set": {
                "subscription.status": new_status,
                "subscription.expires_at": expires_ms,
                "subscription.last_notification": notif_type,
                "subscription.last_updated": datetime.now(timezone.utc).isoformat(),
                **({"plan": "trial"} if new_status == "expired" else {}),
            }},
        )
        return {"received": True, "status": new_status, "type": notif_type}
    except Exception as e:
        logging.exception("Apple webhook parse failed")
        raise HTTPException(status_code=400, detail=f"Bad payload: {e}")


@api.get("/subscriptions/status")
async def subscription_status(user: dict = Depends(get_current_user)):
    """Returns the current user's plan + subscription record."""
    return {
        "plan": user.get("plan", "trial"),
        "subscription": user.get("subscription", {"status": "trial"}),
    }


# -------------------- MILLI CENTS — Offer Profitability Engine --------------------
class OfferIn(BaseModel):
    platform: str                      # "uber", "doordash", "spark", "lyft", ...
    kind: Optional[str] = "delivery"   # ride | delivery
    payout: float                      # dollars offered
    trip_miles: float                  # customer-with-you miles
    pickup_miles: float = 0.0          # miles to get to pickup
    deadhead_miles: float = 0.0        # empty miles between offer and pickup
    return_miles: float = 0.0          # miles back to base after drop-off
    duration_min: Optional[float] = None
    mpg: float = 26.0
    gas_price: float = 3.85            # $/gal
    per_mile_wear: float = 0.09        # depreciation + tires + maintenance
    tax_rate: float = 0.23             # SE + income tax combined
    goal_per_hour: float = 25.0        # driver's target hourly

def _score_offer(o: OfferIn) -> dict:
    total_miles = (o.trip_miles or 0) + (o.pickup_miles or 0) + (o.deadhead_miles or 0) + (o.return_miles or 0)
    gas_cost      = (total_miles / max(o.mpg, 1)) * o.gas_price
    wear_cost     = total_miles * o.per_mile_wear
    tax_cost      = o.payout * o.tax_rate
    total_cost    = gas_cost + wear_cost + tax_cost
    net_profit    = o.payout - total_cost
    # profit per mile & per hour drive the score
    per_mile      = net_profit / total_miles if total_miles > 0 else 0
    per_hour      = (net_profit / (o.duration_min / 60)) if o.duration_min and o.duration_min > 0 else 0
    # Calibrated so a solid ride ($0.80/mi + $22/hr) scores ~80
    ppm_score  = min(1.0, per_mile / 0.75) if per_mile > 0 else 0
    hourly_ratio = min(1.2, per_hour / max(o.goal_per_hour * 0.85, 1)) if per_hour else ppm_score
    raw = 0.55 * ppm_score + 0.45 * (hourly_ratio / 1.2)
    score = max(0, min(100, round(raw * 100)))
    if score >= 75:    verdict, label = "accept",  "Very Good"
    elif score >= 55:  verdict, label = "marginal", "Fair"
    else:              verdict, label = "decline", "Poor"
    return {
        "platform": o.platform,
        "kind": o.kind,
        "payout": round(o.payout, 2),
        "trip_miles": round(o.trip_miles, 1),
        "pickup_miles": round(o.pickup_miles, 1),
        "deadhead_miles": round(o.deadhead_miles, 1),
        "return_miles": round(o.return_miles, 1),
        "total_miles": round(total_miles, 1),
        "gas_used_gal": round(total_miles / max(o.mpg, 1), 2),
        "gas_cost": round(gas_cost, 2),
        "wear_cost": round(wear_cost, 2),
        "tax_cost": round(tax_cost, 2),
        "total_cost": round(total_cost, 2),
        "net_profit": round(net_profit, 2),
        "per_mile": round(per_mile, 2),
        "per_hour": round(per_hour, 2),
        "score": score,
        "label": label,
        "verdict": verdict,
    }

@api.post("/milli-cents/score")
async def milli_cents_score(offer: OfferIn, user: dict = Depends(get_current_user)):
    return _score_offer(offer)

class CompareIn(BaseModel):
    offers: List[OfferIn]

@api.post("/milli-cents/compare")
async def milli_cents_compare(body: CompareIn, user: dict = Depends(get_current_user)):
    scored = [_score_offer(o) for o in body.offers]
    scored.sort(key=lambda x: x["net_profit"], reverse=True)
    return {"offers": scored, "count": len(scored)}


# -------------------- TaxBandits (TIN Matching) --------------------
try:
    from taxbandits import tin_match, get_access_token as tb_token
except Exception as _e:
    tin_match = None
    tb_token = None

class TinMatchIn(BaseModel):
    tin: str
    tin_type: str = "SSN"          # SSN or EIN
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    business_name: Optional[str] = None

@api.get("/taxbandits/health")
async def taxbandits_health(user: dict = Depends(get_current_user)):
    if not tb_token:
        raise HTTPException(status_code=503, detail="TaxBandits module not loaded")
    try:
        tok = await tb_token()
        return {"authenticated": True, "token_prefix": tok[:12] + "..."}
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"TaxBandits auth failed: {e!s}")

@api.post("/taxbandits/tin-match")
async def taxbandits_tin_match(body: TinMatchIn, user: dict = Depends(get_current_user)):
    if not tin_match:
        raise HTTPException(status_code=503, detail="TaxBandits module not loaded")
    if user.get("plan") != "elite":
        raise HTTPException(status_code=402, detail="TIN Matching is an Elite feature")
    try:
        result = await tin_match(
            tin=body.tin, tin_type=body.tin_type,
            first_name=body.first_name, last_name=body.last_name,
            business_name=body.business_name,
        )
        return {"ok": True, "provider": "taxbandits", "result": result}
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"TaxBandits TIN match failed: {e!s}")


# -------------------- Push Notifications (device registration) --------------------
class Nec1099In(BaseModel):
    tax_year: int
    forms: List[Dict[str, Any]]        # [{ payer_name, gross_amount, tin? }]

@api.post("/tax/import-1099-nec")
async def import_1099_nec(body: Nec1099In, user: dict = Depends(get_current_user)):
    """
    Import 1099-NEC forms (from TaxBandits webhook or manual entry).
    Reconciles reported gross against Milli's tracked deposits so the
    Schedule C line 1 is accurate at year-end.
    """
    saved = 0
    for f in body.forms:
        doc = {
            "id": str(uuid.uuid4()),
            "user_id": user["id"],
            "tax_year": int(body.tax_year),
            "payer_name": f.get("payer_name") or "Unknown",
            "gross_amount": float(f.get("gross_amount") or 0),
            "payer_tin": f.get("tin"),
            "source": f.get("source", "manual"),
            "imported_at": datetime.now(timezone.utc).isoformat(),
        }
        await db.tax_forms_1099.update_one(
            {"user_id": user["id"], "tax_year": doc["tax_year"], "payer_name": doc["payer_name"]},
            {"$set": doc},
            upsert=True,
        )
        saved += 1

    # Sum totals and compare to tracked deposits for the year
    forms = await db.tax_forms_1099.find(
        {"user_id": user["id"], "tax_year": int(body.tax_year)}, {"_id": 0}
    ).to_list(200)
    reported = round(sum(float(f.get("gross_amount", 0)) for f in forms), 2)

    deposits = await db.deposits.find({"user_id": user["id"]}, {"_id": 0}).to_list(5000)
    tracked = round(sum(
        float(d.get("amount", 0)) for d in deposits
        if str(d.get("date", "")).startswith(str(body.tax_year))
    ), 2)

    return {
        "saved": saved,
        "tax_year": int(body.tax_year),
        "reported_gross": reported,
        "tracked_gross": tracked,
        "delta": round(reported - tracked, 2),
        "reconciled": abs(reported - tracked) < 25,
    }

@api.get("/tax/forms-1099")
async def list_1099s(user: dict = Depends(get_current_user), year: Optional[int] = None):
    q = {"user_id": user["id"]}
    if year: q["tax_year"] = int(year)
    return await db.tax_forms_1099.find(q, {"_id": 0}).to_list(500)


class PushRegisterIn(BaseModel):
    device_token: str
    platform: str = "ios"          # ios | android
    app_version: Optional[str] = None

@api.post("/push/register")
async def push_register(body: PushRegisterIn, user: dict = Depends(get_current_user)):
    """Store the APNs / FCM device token for this user so we can send
    quarterly reminders, payout confirmations, and vault milestones."""
    await db.users.update_one(
        {"id": user["id"]},
        {"$set": {
            "push": {
                "device_token": body.device_token,
                "platform": body.platform,
                "app_version": body.app_version,
                "registered_at": datetime.now(timezone.utc).isoformat(),
            }
        }}
    )
    return {"ok": True}

@api.delete("/push/register")
async def push_unregister(user: dict = Depends(get_current_user)):
    await db.users.update_one({"id": user["id"]}, {"$unset": {"push": ""}})
    return {"ok": True}

@api.post("/push/test")
async def push_test(user: dict = Depends(get_current_user)):
    """Send a test push to the caller's device — useful for setup verification."""
    try:
        import apns as _apns
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"apns module unavailable: {e!s}")
    tok = (user.get("push") or {}).get("device_token")
    if not tok:
        raise HTTPException(status_code=404, detail="No device_token registered")
    res = await _apns.send_push(
        tok, "Milli test push",
        "If you see this on your lock screen, APNs is wired ✅",
        thread_id="test",
    )
    return res


# -------------------- Schedule C / SE PDF (Elite Filing) --------------------
from fastapi.responses import Response
from schedule_c_pdf import build_schedule_c_pdf

@api.get("/reports/schedule-c-pdf")
async def schedule_c_pdf(user: dict = Depends(get_current_user), year: Optional[int] = None):
    """
    Preparer-ready Schedule C + Schedule SE PDF, filled from Milli data.
    Elite users can download this and attach to any e-file provider
    (FreeTaxUSA, TurboTax, H&R Block) or hand it to their CPA.
    """
    if user.get("plan") != "elite":
        raise HTTPException(status_code=402, detail="IRS-Ready PDF is an Elite feature")
    y = int(year or datetime.now(timezone.utc).year)
    q = {"user_id": user["id"]}
    deposits = await db.deposits.find(q, {"_id": 0}).to_list(2000)
    deposits = [d for d in deposits if str(d.get("date", "")).startswith(str(y))]
    gross_receipts = round(sum(float(d.get("amount", 0)) for d in deposits), 2)

    expenses = await db.expenses.find(q, {"_id": 0}).to_list(2000)
    expenses = [e for e in expenses if str(e.get("date", "")).startswith(str(y))]
    exp_by_cat: dict[str, float] = {}
    for e in expenses:
        cat = e.get("category", "other")
        exp_by_cat[cat] = exp_by_cat.get(cat, 0) + float(e.get("amount", 0))

    trips = await db.trips.find(q, {"_id": 0}).to_list(5000)
    trips = [t for t in trips if str(t.get("date", "")).startswith(str(y))]
    business_miles = round(sum(float(t.get("miles", 0)) for t in trips), 1)
    mileage_deduction = round(business_miles * 0.70, 2)

    total_expenses = round(sum(exp_by_cat.values()) + mileage_deduction, 2)
    net_profit = round(gross_receipts - total_expenses, 2)
    se_taxable = round(max(0, net_profit) * 0.9235, 2)
    se_tax     = round(se_taxable * 0.153, 2)

    summary = {
        "year": y,
        "gross_receipts": gross_receipts,
        "other_income": 0, "returns_allowances": 0, "cogs": 0,
        "expenses_by_category": exp_by_cat,
        "mileage_business_miles": business_miles,
        "mileage_deduction": mileage_deduction,
        "total_expenses": total_expenses,
        "net_profit": net_profit,
        "se_taxable_earnings": se_taxable,
        "se_tax": se_tax,
    }
    pdf_bytes = build_schedule_c_pdf(user, summary)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="milli-schedule-c-{y}.pdf"'},
    )


# -------------------- MOUNT --------------------
# Market data (live)
try:
    from market import get_market_overview, get_movers, get_quote_batch

    @api.get("/market/overview")
    async def market_overview(range_: str = "1d", user: dict = Depends(get_current_user)):
        try:
            return await get_market_overview(range_)
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Market data unavailable: {e!s}")

    @api.get("/market/movers")
    async def market_movers(user: dict = Depends(get_current_user)):
        try:
            return await get_movers()
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Movers unavailable: {e!s}")

    @api.get("/market/quotes")
    async def market_quotes(tickers: str, user: dict = Depends(get_current_user)):
        return await get_quote_batch([t.strip() for t in tickers.split(",") if t.strip()])
except Exception as _me:
    logging.warning("Market module not mounted: %s", _me)

app.include_router(api)

_cors_origins = [
    origin.strip()
    for origin in os.environ.get('CORS_ORIGINS', 'http://localhost:3000').split(',')
    if origin.strip()
]
if APP_ENV == 'production' and '*' in _cors_origins:
    raise RuntimeError('Wildcard CORS is forbidden in production')

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=_cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# -------------------- MARKETING SITE (public) --------------------
# Serves the /app/marketing_site static bundle at /api/site/* — every route
# routes through the pod's ingress so we get a live public URL for the
# App Review privacy/terms links until drivemilli.com DNS is switched.
try:
    from fastapi.staticfiles import StaticFiles
    _site_dir = Path("/app/marketing_site")
    if _site_dir.exists():
        app.mount("/api/site", StaticFiles(directory=str(_site_dir), html=True),
                   name="marketing_site")

    @app.get("/api/privacy")
    async def _privacy_redirect():
        from fastapi.responses import FileResponse
        return FileResponse(_site_dir / "privacy.html", media_type="text/html")

    @app.get("/api/terms")
    async def _terms_redirect():
        from fastapi.responses import FileResponse
        return FileResponse(_site_dir / "terms.html", media_type="text/html")
except Exception as _site_err:
    logging.warning("Could not mount marketing site: %s", _site_err)


@app.on_event("startup")
async def _startup():
    await db.users.create_index("email", unique=True)
    await db.users.create_index("id", unique=True)
    await db.deposits.create_index("user_id")
    await db.deposits.create_index("transaction_id", unique=True)
    await db.trips.create_index([("user_id", 1), ("status", 1)])
    await db.expenses.create_index("user_id")
    await db.plaid_items.create_index("user_id")
    await db.payment_transactions.create_index("session_id", unique=True)
    await db.tax_vaults.create_index("user_id", unique=True)
    await db.vault_transfers.create_index("user_id")
    await db.quarterly_payments.create_index([("user_id", 1), ("year", 1), ("period", 1)])
    await db.retirement_accounts.create_index("user_id", unique=True)
    await db.investment_accounts.create_index("user_id", unique=True)
    await db.retirement_transfers.create_index("user_id")
    await db.investment_transfers.create_index("user_id")
    # Milli Autopilot™
    await db.autopilot_receipts.create_index("user_id")
    await db.autopilot_receipts.create_index([("user_id", 1), ("created_at", -1)])
    await db.autopilot_receipts.create_index("payout_id")
    await db.savings_transfers.create_index("user_id")
    await db.notifications.create_index([("user_id", 1), ("created_at", -1)])
    await db.vehicles.create_index("user_id")
    # Idempotent migration: apply Autopilot defaults to any user missing them.
    try:
        report = await _autopilot_migrate(db)
        logging.info("Autopilot migration: %s", report)
    except Exception as e:
        logging.warning("Autopilot migration skipped: %s", e)

    # ----- APScheduler: quarterly reminders + light housekeeping -----
    try:
        from apscheduler.schedulers.asyncio import AsyncIOScheduler
        import apns as _apns
        from notifications import run_quarterly_reminders
        sched = AsyncIOScheduler(timezone="America/Los_Angeles")
        # Every day at 09:00 local — hits the T-14/7/3/1/0 windows automatically.
        sched.add_job(lambda: run_quarterly_reminders(db, _apns),
                      "cron", hour=9, minute=0, id="milli-quarterly-reminders")
        sched.start()
        app.state.scheduler = sched
        logging.info("APScheduler started (quarterly reminders 09:00 America/Los_Angeles).")
    except Exception as e:
        logging.warning("Scheduler not started: %s", e)

@app.on_event("shutdown")
async def _shutdown():
    try:
        sched = getattr(app.state, "scheduler", None)
        if sched: sched.shutdown(wait=False)
    except Exception:
        pass
    client.close()
