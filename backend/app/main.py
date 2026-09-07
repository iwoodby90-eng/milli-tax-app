"""MILLI Tax Vault API."""
import logging, uuid
from fastapi import FastAPI, Request
from .config import get_settings
from .routers import auth, health, plaid_routes, tax_vault

settings=get_settings()
logging.basicConfig(level=logging.INFO,format="%(asctime)s %(levelname)s %(name)s %(message)s")
logger=logging.getLogger("milli.api")

app=FastAPI(title="MILLI Tax Vault API",version="0.2.0",
            description="Secure MILLI identity, bank connections, and Tax Vault ledger.")

@app.middleware("http")
async def request_security_context(request: Request, call_next):
    request_id=request.headers.get("x-request-id") or str(uuid.uuid4())
    response=await call_next(request)
    response.headers["X-Request-ID"]=request_id
    response.headers["Cache-Control"]="no-store"
    response.headers["X-Content-Type-Options"]="nosniff"
    response.headers["Referrer-Policy"]="no-referrer"
    logger.info("request method=%s path=%s status=%s request_id=%s",
                request.method,request.url.path,response.status_code,request_id)
    return response

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(plaid_routes.router)
app.include_router(tax_vault.router)

@app.get("/")
def root():
    return {"service":"milli-tax-vault-api","version":"0.2.0","docs":"/docs","health":"/health"}
