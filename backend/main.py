"""Production ASGI entrypoint for Milli.

This module wraps the legacy server without duplicating its routes, then mounts
new isolated feature routers that should not be added to the monolithic module.
Deploy with `uvicorn main:app` from the backend directory.
"""
from server import app, db, get_current_user
from gig_offers import build_gig_offer_router

# The legacy server mounts its APIRouter before import completes, so new feature
# routers must be attached directly to the FastAPI application here.
app.include_router(
    build_gig_offer_router(db=db, get_current_user=get_current_user),
    prefix="/api",
)


@app.on_event("startup")
async def _ensure_gig_offer_indexes() -> None:
    """Create the indexes required for fast, expiring multi-offer queries."""
    await db.gig_platform_connections.create_index(
        [("user_id", 1), ("platform", 1)],
        unique=True,
    )
    await db.gig_offers.create_index(
        [("user_id", 1), ("status", 1), ("detected_at", -1)]
    )
    await db.gig_offers.create_index(
        [("user_id", 1), ("expires_at", 1)]
    )
    await db.gig_offers.create_index(
        [("user_id", 1), ("external_offer_id", 1)],
        sparse=True,
    )
