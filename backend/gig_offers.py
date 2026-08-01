"""Milli Cents platform connections and normalized live-offer ingestion."""
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

ALLOWED_SOURCES = {
    "official_api",
    "android_notification",
    "ios_share",
    "ios_ocr",
    "manual",
}

SUPPORTED_DECISION_PLATFORMS = {
    "uber",
    "uber eats",
    "spark",
    "walmart spark",
    "doordash",
    "door dash",
    "instacart",
    "grubhub",
    "shipt",
}

EXCLUDED_BLOCK_PLATFORMS = {"amazon flex", "amazonflex", "flex"}


class GigConnectionIn(BaseModel):
    platform: str
    external_account_id: Optional[str] = None
    display_name: Optional[str] = None
    capabilities: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class GigOfferIn(BaseModel):
    external_offer_id: Optional[str] = None
    platform: str
    offered_pay: float = Field(ge=0)
    pickup_miles: float = Field(default=0, ge=0)
    route_miles: float = Field(default=0, ge=0)
    return_to_base_miles: float = Field(default=0, ge=0)
    estimated_minutes: Optional[float] = Field(default=None, ge=0)
    pickup_label: Optional[str] = None
    dropoff_label: Optional[str] = None
    source: str
    confidence: float = Field(default=0.75, ge=0, le=1)
    raw_fields: Optional[Dict[str, Any]] = None
    expires_at: Optional[str] = None


def _platform_key(value: str) -> str:
    return (value or "").strip().lower()


def _assert_supported_platform(platform: str) -> None:
    key = _platform_key(platform)
    if key in EXCLUDED_BLOCK_PLATFORMS:
        raise HTTPException(status_code=422, detail="Milli Cents is for time-limited selectable offers, not scheduled block platforms")
    if key not in SUPPORTED_DECISION_PLATFORMS:
        raise HTTPException(status_code=422, detail="Platform is not currently supported by Milli Cents")


def build_gig_offer_router(db, get_current_user: Callable):
    router = APIRouter(tags=["gig-offers"])

    @router.get("/gig-platforms/connections")
    async def list_connections(user: dict = Depends(get_current_user)):
        rows = await db.gig_platform_connections.find(
            {"user_id": user["id"]},
            {"_id": 0, "oauth_tokens": 0, "credentials": 0},
        ).to_list(length=50)
        return {"connections": [row for row in rows if _platform_key(row.get("platform")) in SUPPORTED_DECISION_PLATFORMS]}

    @router.post("/gig-platforms/connections")
    async def upsert_connection(body: GigConnectionIn, user: dict = Depends(get_current_user)):
        _assert_supported_platform(body.platform)
        platform_key = _platform_key(body.platform)
        now = datetime.now(timezone.utc).isoformat()
        document = {
            "id": f"{user['id']}:{platform_key}",
            "user_id": user["id"],
            "platform": body.platform.strip(),
            "display_name": body.display_name or body.platform.strip(),
            "external_account_id": body.external_account_id,
            "capabilities": body.capabilities,
            "metadata": body.metadata,
            "connected": True,
            "updated_at": now,
        }
        await db.gig_platform_connections.update_one(
            {"id": document["id"]},
            {"$set": document, "$setOnInsert": {"created_at": now}},
            upsert=True,
        )
        return {k: v for k, v in document.items() if k not in {"oauth_tokens", "credentials"}}

    @router.post("/gig-offers/ingest")
    async def ingest_offer(body: GigOfferIn, user: dict = Depends(get_current_user)):
        _assert_supported_platform(body.platform)
        if body.source not in ALLOWED_SOURCES:
            raise HTTPException(status_code=400, detail="Unsupported offer source")

        now = datetime.now(timezone.utc).isoformat()
        offer_id = body.external_offer_id or f"{_platform_key(body.platform)}:{user['id']}:{int(datetime.now(timezone.utc).timestamp() * 1000)}"
        document = {
            "id": offer_id,
            "external_offer_id": body.external_offer_id,
            "user_id": user["id"],
            "platform": body.platform.strip(),
            "offered_pay": body.offered_pay,
            "pickup_miles": body.pickup_miles,
            "route_miles": body.route_miles,
            "return_to_base_miles": body.return_to_base_miles,
            "estimated_minutes": body.estimated_minutes,
            "pickup_label": body.pickup_label,
            "dropoff_label": body.dropoff_label,
            "source": body.source,
            "confidence": body.confidence,
            "raw_fields": body.raw_fields,
            "detected_at": now,
            "expires_at": body.expires_at,
            "status": "active",
        }
        await db.gig_offers.update_one(
            {"user_id": user["id"], "id": offer_id},
            {"$set": document},
            upsert=True,
        )
        return {"offer": {k: v for k, v in document.items() if k != "user_id"}}

    @router.get("/gig-offers/active")
    async def active_offers(user: dict = Depends(get_current_user)):
        now = datetime.now(timezone.utc)
        rows = await db.gig_offers.find(
            {"user_id": user["id"], "status": "active"},
            {"_id": 0, "user_id": 0},
        ).sort("detected_at", -1).to_list(length=25)

        active = []
        expired_ids = []
        for offer in rows:
            if _platform_key(offer.get("platform")) not in SUPPORTED_DECISION_PLATFORMS:
                continue
            expires_at = offer.get("expires_at")
            if expires_at:
                try:
                    if datetime.fromisoformat(expires_at.replace("Z", "+00:00")) <= now:
                        expired_ids.append(offer["id"])
                        continue
                except ValueError:
                    pass
            active.append(offer)

        if expired_ids:
            await db.gig_offers.update_many(
                {"user_id": user["id"], "id": {"$in": expired_ids}},
                {"$set": {"status": "expired", "expired_at": now.isoformat()}},
            )

        active.sort(key=lambda row: row.get("expires_at") or "9999-12-31T23:59:59+00:00")
        return {"offers": active, "assumptions": _assumptions(user)}

    @router.get("/gig-offers/current")
    async def current_offer(user: dict = Depends(get_current_user)):
        payload = await active_offers(user)
        return {"offer": payload["offers"][0] if payload["offers"] else None, "assumptions": payload["assumptions"]}

    @router.post("/gig-offers/{offer_id}/dismiss")
    async def dismiss_offer(offer_id: str, user: dict = Depends(get_current_user)):
        result = await db.gig_offers.update_one(
            {"user_id": user["id"], "id": offer_id},
            {"$set": {"status": "dismissed", "dismissed_at": datetime.now(timezone.utc).isoformat()}},
        )
        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Offer not found")
        return {"success": True}

    return router


def _assumptions(user: dict) -> dict:
    vehicle = user.get("vehicle_profile") or {}
    cents = user.get("milli_cents_settings") or {}
    tax_rate = user.get("effective_tax_rate")
    return {
        "gasPrice": float(cents.get("gas_price", 3.49)),
        "vehicleMpg": float(vehicle.get("mpg", 24)),
        "taxRate": float(tax_rate * 100 if isinstance(tax_rate, (int, float)) and tax_rate <= 1 else tax_rate or 25),
        "vehicleCostPerMile": float(cents.get("vehicle_cost_per_mile", 0.18)),
        "minimumNetPerMile": float(cents.get("minimum_net_per_mile", 0.75)),
        "minimumNetPerHour": float(cents.get("minimum_net_per_hour", 20)),
    }
