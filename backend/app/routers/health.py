"""Health and readiness.

Liveness never leaks secrets. Readiness stays false until the dependencies
required for authenticated financial data are actually configured.
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

    apple_auth = "configured" if settings.apple_auth_configured else "unconfigured"
    plaid = "configured" if settings.plaid_configured else "unconfigured"
    return {
        "database": database,
        "apple_auth": apple_auth,
        "plaid": plaid,
        "plaid_env": settings.plaid_env,
        "ready": database == "ok" and apple_auth == "configured" and plaid == "configured",
    }
