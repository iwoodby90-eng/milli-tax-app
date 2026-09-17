"""MILLI Tax Vault API.

FastAPI service backing the MILLITaxVault iOS app:
- Bank connections via Plaid
- Tax Vault reserve ledger (auditable, state-machine enforced)
- Column BaaS: accounts, cards, ACH transfers
- Apple IAP: server-side StoreKit 2 transaction verification
- Apple Identity: Wallet API verification + Column KYC fallback
- Audit logging on every financial operation
"""

from fastapi import FastAPI

from .config import get_settings
from .rate_limit import RateLimitMiddleware
from .routers import (
    column_routes,
    health,
    iap_routes,
    identity_routes,
    plaid_routes,
    tax_vault,
)

settings = get_settings()

app = FastAPI(
    title="MILLI Tax Vault API",
    version="0.2.0",
    description=(
        "Bank connections (Plaid), Tax Vault ledger, Column BaaS "
        "(accounts, cards, transfers), Apple IAP verification, "
        "and Apple Identity verification."
    ),
)

# Rate limiting
app.add_middleware(RateLimitMiddleware)

# Routers
app.include_router(health.router)
app.include_router(plaid_routes.router)
app.include_router(tax_vault.router)
app.include_router(column_routes.router)
app.include_router(iap_routes.router)
app.include_router(identity_routes.router)


@app.get("/")
def root() -> dict:
    return {
        "service": "milli-tax-vault-api",
        "version": "0.2.0",
        "docs": "/docs",
        "health": "/health",
        "endpoints": {
            "plaid": "/plaid",
            "tax_vault": "/tax-vault",
            "column": "/column",
            "iap": "/iap",
            "identity": "/identity",
        },
    }