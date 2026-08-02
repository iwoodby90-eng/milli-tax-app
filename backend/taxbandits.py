"""
TaxBandits sandbox integration.

Public sandbox API documented at:
  - Auth:   https://testoauth.expressauth.net/v2/tbsauth  (GET with signed JWS)
  - API:    https://testapi.taxbandits.com/v1.7.3

Milli uses TaxBandits for:
  1. TIN Matching — verify a driver's SSN/EIN matches IRS records
  2. (Future) 1099-NEC receipt import at year-end

Note: TaxBandits does NOT support Form 1040 / Schedule C. Full e-file for
Elite users will route through a 1040-focused partner (e.g. Column Tax).
"""
import os
import time
from typing import Any, Optional

import httpx
import jwt

AUTH_URL     = os.environ.get("TAXBANDITS_AUTH_URL", "https://testoauth.expressauth.net/v2/tbsauth")
API_BASE     = os.environ.get("TAXBANDITS_API_BASE", "https://testapi.taxbandits.com/v1.7.3").rstrip("/")
CLIENT_ID    = os.environ.get("TAXBANDITS_CLIENT_ID")
CLIENT_SECRET = os.environ.get("TAXBANDITS_CLIENT_SECRET")
USER_TOKEN   = os.environ.get("TAXBANDITS_USER_TOKEN")

_token_cache: dict[str, Any] = {"access_token": None, "expires_at": 0}


def _create_jws() -> str:
    if not (CLIENT_ID and CLIENT_SECRET and USER_TOKEN):
        raise RuntimeError("TAXBANDITS_CLIENT_ID / CLIENT_SECRET / USER_TOKEN missing")
    payload = {
        "iss": CLIENT_ID,
        "sub": CLIENT_ID,
        "aud": USER_TOKEN,
        "iat": int(time.time()),
    }
    return jwt.encode(payload, CLIENT_SECRET, algorithm="HS256")


async def get_access_token(force: bool = False) -> str:
    now = int(time.time())
    if (not force
        and _token_cache["access_token"]
        and now < _token_cache["expires_at"] - 60):
        return _token_cache["access_token"]

    jws = _create_jws()
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.get(AUTH_URL, headers={"Authentication": jws})
        r.raise_for_status()
        data = r.json()

    token = data.get("AccessToken") or data.get("access_token")
    if not token:
        raise RuntimeError(f"TaxBandits auth returned no access token: {data}")

    _token_cache["access_token"] = token
    _token_cache["expires_at"] = now + 3600
    return token


async def taxbandits_post(path: str, body: dict[str, Any]) -> dict[str, Any]:
    token = await get_access_token()
    async with httpx.AsyncClient(timeout=60) as client:
        r = await client.post(
            f"{API_BASE}/{path.lstrip('/')}",
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            json=body,
        )
        # Surface useful error body on failure
        if r.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"{r.status_code} {r.text[:400]}", request=r.request, response=r
            )
        return r.json()


async def tin_match(
    tin: str,
    tin_type: str,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None,
    business_name: Optional[str] = None,
) -> dict[str, Any]:
    """
    Verify a TIN (SSN or EIN) matches IRS records.
    tin_type: 'SSN' or 'EIN'
    """
    body: dict[str, Any] = {
        "TINMatchingRequest": [{
            "SequenceID": "milli-1",
            "TINType": tin_type,
            "TIN": tin.replace("-", ""),
        }]
    }
    entry = body["TINMatchingRequest"][0]
    if tin_type == "SSN":
        entry["FirstName"] = first_name or ""
        entry["LastName"]  = last_name or ""
    else:
        entry["BusinessName"] = business_name or ""
    return await taxbandits_post("TINMatching/RequestByForm", body)
