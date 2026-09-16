"""MILLI Tax Vault API.

FastAPI service backing the MilliTaxVault iOS app: bank connections via Plaid,
and the auditable Tax Vault reserve ledger.
"""

from fastapi import FastAPI

from .config import get_settings
from .routers import health, plaid_routes, tax_vault

settings = get_settings()

app = FastAPI(
    title="MILLI Tax Vault API",
    version="0.1.0",
    description="Bank connections (Plaid) and the Tax Vault reserve ledger.",
)

app.include_router(health.router)
app.include_router(plaid_routes.router)
app.include_router(tax_vault.router)


@app.get("/")
def root() -> dict:
    return {
        "service": "milli-tax-vault-api",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
    }
