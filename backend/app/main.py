"""MILLI Tax Vault API.

FastAPI service backing the native iOS app. User-scoped financial endpoints use
server-issued bearer sessions; no mobile shared secret is an auth boundary.
"""

from fastapi import FastAPI, Request

from .config import get_settings
from .routers import auth_routes, health, plaid_routes, tax_vault

settings = get_settings()

app = FastAPI(
    title="MILLI Tax Vault API",
    version="0.2.0",
    description="Authenticated bank connections and the Tax Vault reserve ledger.",
    docs_url=None if settings.environment == "production" else "/docs",
    redoc_url=None if settings.environment == "production" else "/redoc",
    openapi_url=None if settings.environment == "production" else "/openapi.json",
)

app.include_router(health.router)
app.include_router(auth_routes.router)
app.include_router(plaid_routes.router)
app.include_router(tax_vault.router)


@app.middleware("http")
async def harden_responses(request: Request, call_next):
    response = await call_next(request)
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    if settings.environment == "production":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response


@app.get("/")
def root() -> dict:
    return {
        "service": "milli-tax-vault-api",
        "version": "0.2.0",
        "health": "/health",
    }
