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
            "Everything in Pro", "Auto tax-savings bucket per deposit",
            "Auto-generated Schedule C + SE forms ready to file",
            "Priority AI assistant", "Year-end CPA review checklist",
            "Audit-ready mileage log",
        ]},
    ]

# -------------------- HEALTH --------------------
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

@app.on_event("shutdown")
async def _shutdown():
    client.close()
