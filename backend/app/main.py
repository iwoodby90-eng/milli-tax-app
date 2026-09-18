"""MILLI Tax Vault API.

Plaid is the account-data layer. Column is the banking and ACH money-movement
layer. Every user-scoped financial endpoint is authorized by a server-issued
session; the mobile app is never a financial authority.
"""

from fastapi import FastAPI, Request

from .config import get_settings
from .routers import auth_routes, column_routes, health, plaid_routes, tax_vault

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
app.include_router(column_routes.router)
app.include_router(tax_vault.router)


@app.middleware("http")
async def harden_responses(request: Request, call_next):
    response = await call_next(request)
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


@app.get("/")
def root() -> dict:
    return {
        "service": "milli-tax-vault-api",
        "version": "0.3.0",
        "health": "/health",
    }
