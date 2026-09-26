"""MILLI Tax Vault API.

Plaid is the account-data layer. Column is the banking and ACH money-movement
layer. Every user-scoped financial endpoint is authorized by a server-issued
session; the mobile app is never a financial authority.
"""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .body_limit import MAX_REQUEST_BYTES, BodySizeLimitMiddleware
from .config import get_settings
from .rate_limit import RATE_LIMITED_PREFIXES, RateLimiter
from .routers import (
    auth_routes,
    column_routes,
    column_sandbox_routes,
    health,
    payout_source,
    plaid_routes,
    tax_vault,
)

settings = get_settings()

app = FastAPI(
    title="MILLI Tax Vault API",
    version="0.3.0",
    description="Authenticated Plaid connectivity, Column money movement, and Tax Vault ledger.",
    docs_url=None if settings.environment == "production" else "/docs",
    redoc_url=None if settings.environment == "production" else "/redoc",
    openapi_url=None if settings.environment == "production" else "/openapi.json",
)

app.include_router(health.router)
app.include_router(auth_routes.router)
app.include_router(plaid_routes.router)
app.include_router(payout_source.router)
app.include_router(column_routes.router)
app.include_router(column_sandbox_routes.router)
app.include_router(tax_vault.router)


_rate_limiter = RateLimiter()

# Added before the header middleware so it stays inside it: a 413 raised here
# still leaves through the same hardened response headers as every other reply.
app.add_middleware(BodySizeLimitMiddleware, max_bytes=MAX_REQUEST_BYTES)


@app.middleware("http")
async def harden_responses(request: Request, call_next):
    rejection = _reject_oversized_body(request) or _reject_rate_limited(request)
    response = rejection or await call_next(request)
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
    if settings.environment == "production":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response


def _reject_oversized_body(request: Request) -> JSONResponse | None:
    """Refuse bodies no legitimate Milli request produces, before parsing them."""
    declared = request.headers.get("content-length")
    if declared is None:
        return None
    try:
        length = int(declared)
    except ValueError:
        return JSONResponse({"detail": "invalid Content-Length"}, status_code=400)
    if length > MAX_REQUEST_BYTES:
        return JSONResponse({"detail": "request body too large"}, status_code=413)
    return None


def _reject_rate_limited(request: Request) -> JSONResponse | None:
    path = request.url.path
    if not any(path.startswith(prefix) for prefix in RATE_LIMITED_PREFIXES):
        return None
    client = request.client.host if request.client else "unknown"
    allowed, retry_after = _rate_limiter.allow(f"{client}:{path}")
    if allowed:
        return None
    return JSONResponse(
        {"detail": "too many requests"},
        status_code=429,
        headers={"Retry-After": str(retry_after)},
    )


@app.get("/")
def root() -> dict:
    return {
        "service": "milli-tax-vault-api",
        "version": "0.3.0",
        "health": "/health",
    }
