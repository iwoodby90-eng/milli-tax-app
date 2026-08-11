from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, payouts, tax, plaid, stripe

app = FastAPI(title="Milli Tax Vault API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(payouts.router, prefix="/api/payouts", tags=["payouts"])
app.include_router(tax.router, prefix="/api/tax", tags=["tax"])
app.include_router(plaid.router, prefix="/api/plaid", tags=["plaid"])
app.include_router(stripe.router, prefix="/api/stripe", tags=["stripe"])


@app.get("/api/health")
def health():
    return {"status": "ok"}
