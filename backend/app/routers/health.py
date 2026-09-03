"""Health and readiness.

/health is the liveness probe Render hits: it returns 200 whenever the process
is up. /ready reports the truth about dependencies without ever claiming a
dependency works when it does not.
"""

from fastapi import APIRouter

from ..config import get_settings
from .. import db

router = APIRouter(tags=["health"])


@router.get("/health")
def health() -> dict:
    settings = get_settings()
    return {
        "status": "ok",
        "service": "milli-tax-vault-api",
        "environment": settings.environment,
    }


@router.get("/ready")
def ready() -> dict:
    settings = get_settings()
    database = "unconfigured"
    if settings.db_configured:
        database = "ok" if db.healthy() else "error"
    return {
        "database": database,
        "plaid": "configured" if settings.plaid_configured else "unconfigured",
        "plaid_env": settings.plaid_env,
        "ready": database == "ok" and settings.plaid_configured,
    }
