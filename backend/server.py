"""TaxHaul backend — Tax & mileage tracker for gig delivery drivers."""
import os
import io
import csv
import uuid
import logging
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

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
PLAID_CLIENT_ID = os.environ['PLAID_CLIENT_ID']
PLAID_SECRET = os.environ['PLAID_SECRET']
PLAID_ENV = os.environ.get('PLAID_ENV', 'sandbox')
EMERGENT_LLM_KEY = os.environ['EMERGENT_LLM_KEY']
STRIPE_API_KEY = os.environ['STRIPE_API_KEY']

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
    password: str = Field(min_length=6)
    name: str
    state: str = "TX"

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class ProfileUpdateIn(BaseModel):
    name: Optional[str] = None
    state: Optional[str] = None
    filing_status: Optional[str] = None  # single, married_joint, etc.

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
app = FastAPI(title="TaxHaul API")
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
    if update:
        await db.users.update_one({"id": user["id"]}, {"$set": update})
    out = await db.users.find_one({"id": user["id"]}, {"password_hash": 0, "_id": 0})
    return out

# -------------------- PLAID ROUTES --------------------
@api.post("/plaid/link-token")
async def plaid_link_token(user: dict = Depends(get_current_user)):
    req = LinkTokenCreateRequest(
        products=[Products("transactions")],
        client_name="TaxHaul",
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
    try:
        exch = plaid_client.item_public_token_exchange(
            ItemPublicTokenExchangeRequest(public_token=body.public_token)
        )
    except plaid.ApiException as e:
        raise HTTPException(status_code=500, detail=f"Plaid exchange error: {e.body}")
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
        if user.get("plan") == "elite":
            extra_savings += savings_set_aside
    if extra_savings:
        await db.users.update_one({"id": user["id"]}, {"$inc": {"tax_savings_balance": extra_savings}})
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
            "You are TaxHaul AI, a tax assistant for gig delivery drivers (Uber, DoorDash, Spark, "
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
    c.drawString(50, y, f"Prepared by TaxHaul  |  Tax Year: {summary['year']}")
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
    c.drawString(50, 40, "This is a worksheet generated by TaxHaul. It is not an official IRS form. Consult a tax professional before filing.")
    c.showPage()
    c.save()
    return buf.getvalue()

@api.get("/reports/schedule-c.pdf")
async def report_schedule_c(user: dict = Depends(get_current_user), year: Optional[int] = None):
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
    vault = await _get_vault(user["id"])
    rule = (vault or {}).get("rule", {}) if vault else {}
    strategy = rule.get("strategy", "balanced")
    pct = rule.get("fixed_percentage")
    if pct is None:
        pct = STRATEGY_RATIOS.get(strategy, 0.25)
    savings = round(amount * pct, 2)
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "transaction_id": f"manual_{uuid.uuid4()}",
        "plaid_item_id": None,
        "date": body.get("date") or datetime.now(timezone.utc).date().isoformat(),
        "merchant": body.get("merchant") or body.get("platform") or "Manual",
        "platform": body.get("platform") or "Manual",
        "amount": amount,
        "savings_set_aside": savings,
        "auto_allocated": vault is not None and not rule.get("paused") and rule.get("mode") == "auto",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.deposits.insert_one(doc)
    # If auto-reserve + vault exists, transfer
    if doc["auto_allocated"]:
        new_balance = round(vault.get("balance", 0) + savings, 2)
        await db.vault_transfers.insert_one({
            "id": str(uuid.uuid4()),
            "user_id": user["id"],
            "direction": "in",
            "amount": savings,
            "balance_after": new_balance,
            "note": f"Auto reserve from {doc['platform']} (${amount:.2f})",
            "source": "auto",
            "deposit_id": doc["id"],
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        await db.tax_vaults.update_one({"user_id": user["id"]}, {"$set": {"balance": new_balance}})
        await db.users.update_one({"id": user["id"]}, {"$set": {"tax_savings_balance": new_balance}})
    # Smart allocations for 401k + investing accounts
    await _smart_auto_allocate(user, doc)
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
async def demo_seed():
    """Create or refresh demo user 'Jordan Taylor' and return a token."""
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
    for i in range(40):
        plat = random.choice(platforms)
        amt = round(random.uniform(45, 285), 2)
        d_date = (today - timedelta(days=random.randint(0, 180))).isoformat()
        savings = round(amt * 0.27, 2)
        await db.deposits.insert_one({
            "id": str(uuid.uuid4()),
            "user_id": uid,
            "transaction_id": f"demo_{uuid.uuid4()}",
            "plaid_item_id": None,
            "date": d_date,
            "merchant": plat,
            "platform": plat,
            "amount": amt,
            "savings_set_aside": savings,
            "auto_allocated": True,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        total_gross += amt

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

    # Seed Vault with ~80% of recommended reserve
    vault_balance = round(total_gross * 0.27 * 0.80, 2)
    await db.tax_vaults.insert_one({
        "id": str(uuid.uuid4()),
        "user_id": uid,
        "institution_name": "Milli Reserve (Demo Partner)",
        "account_nickname": "Tax Vault",
        "account_number_masked": "****4821",
        "routing_number_masked": "****0397",
        "balance": vault_balance,
        "interest_earned_ytd": round(vault_balance * 0.042 * 0.5, 2),
        "rule": {"mode": "auto", "strategy": "balanced", "fixed_percentage": 0.27,
                 "min_checking_balance": 200.0, "max_daily_transfer": 1000.0, "paused": False},
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    # Seed 401(k) retirement at 8%
    ret_balance = round(total_gross * 0.08, 2)
    await db.retirement_accounts.insert_one({
        "id": str(uuid.uuid4()), "user_id": uid, "kind": "retirement",
        "institution_name": "Milli Retirement (Demo Custodian)",
        "account_nickname": "Solo 401(k)",
        "account_number_masked": "****7245",
        "balance": ret_balance,
        "ytd_growth": round(ret_balance * 0.07, 2),
        "rule": {"mode": "auto", "fixed_percentage": 0.08, "max_daily_transfer": 500.0, "paused": False},
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    # Seed Investing at 5%
    inv_balance = round(total_gross * 0.05, 2)
    await db.investment_accounts.insert_one({
        "id": str(uuid.uuid4()), "user_id": uid, "kind": "investing",
        "institution_name": "Milli Invest (Demo Brokerage)",
        "account_nickname": "Brokerage Account",
        "account_number_masked": "****3318",
        "balance": inv_balance,
        "ytd_growth": round(inv_balance * 0.092, 2),
        "rule": {"mode": "auto", "fixed_percentage": 0.05, "max_daily_transfer": 300.0, "paused": False},
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    await db.users.update_one({"id": uid}, {"$set": {
        "tax_savings_balance": vault_balance,
        "retirement_balance": ret_balance,
        "investing_balance": inv_balance,
    }})

    # Seed retirement + investing contribution histories
    for i in range(8):
        ret_amt = round(random.uniform(15, 65), 2)
        inv_amt = round(random.uniform(8, 40), 2)
        ts = (datetime.now(timezone.utc) - timedelta(days=i*3)).isoformat()
        plat = random.choice(platforms[:5])
        await db.retirement_transfers.insert_one({
            "id": str(uuid.uuid4()), "user_id": uid, "direction": "in", "amount": ret_amt,
            "balance_after": ret_balance, "note": f"Auto from {plat} (8%)", "source": "auto", "created_at": ts,
        })
        await db.investment_transfers.insert_one({
            "id": str(uuid.uuid4()), "user_id": uid, "direction": "in", "amount": inv_amt,
            "balance_after": inv_balance, "note": f"Auto invest from {plat} (5%)", "source": "auto", "created_at": ts,
        })

    # Seed last 10 transfers
    for i in range(10):
        amt = round(random.uniform(35, 220), 2)
        await db.vault_transfers.insert_one({
            "id": str(uuid.uuid4()),
            "user_id": uid,
            "direction": "in",
            "amount": amt,
            "balance_after": vault_balance,
            "note": f"Auto reserve from {random.choice(platforms[:5])}",
            "source": "auto",
            "created_at": (datetime.now(timezone.utc) - timedelta(days=i*2)).isoformat(),
        })

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
    return {"name": "TaxHaul", "ok": True}

# -------------------- MOUNT --------------------
app.include_router(api)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

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

@app.on_event("shutdown")
async def _shutdown():
    client.close()
