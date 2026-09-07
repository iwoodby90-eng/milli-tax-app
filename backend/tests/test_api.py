import os,sys
sys.path.insert(0,os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from fastapi.testclient import TestClient
from app.config import get_settings
from app.main import app
client=TestClient(app)

def setup_module(_): get_settings.cache_clear()
def test_health(): assert client.get("/health").status_code==200
def test_missing_bearer_rejected(): assert client.get("/tax-vault/balance").status_code==401
def test_legacy_uuid_header_rejected():
    r=client.get("/tax-vault/balance",headers={"X-Milli-User-Id":"11111111-1111-1111-1111-111111111111"})
    assert r.status_code==401
def test_plaid_requires_session(): assert client.post("/plaid/link-token").status_code==401
