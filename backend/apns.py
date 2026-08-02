"""
Milli — APNs sender.

Uses an Apple Push Notification service token-based auth (.p8 key + Key ID).
Once these env vars are set, real pushes are sent; until then, `send_push`
returns {'ok': False, 'reason': 'apns-not-configured'} so callers can no-op
in dev without exploding.

Required env:
  APNS_KEY_ID          e.g. "ABCD123456"
  APNS_TEAM_ID         e.g. "W5Q42XNM9V"           (already known)
  APNS_BUNDLE_ID       e.g. "app.milli.tax"        (default matches Capacitor bundle)
  APNS_KEY_P8          contents of AuthKey_XXXX.p8 (multi-line PEM, quote-newlines OK)
  APNS_ENV             "sandbox" or "production"   (default sandbox)

Docs: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server
"""
import os
import time
import json
from typing import Any, Optional

import httpx
import jwt

APNS_KEY_ID     = os.environ.get("APNS_KEY_ID")
APNS_TEAM_ID    = os.environ.get("APNS_TEAM_ID", "W5Q42XNM9V")
APNS_BUNDLE_ID  = os.environ.get("APNS_BUNDLE_ID", "app.milli.tax")
APNS_KEY_P8     = os.environ.get("APNS_KEY_P8")   # multi-line PEM
APNS_ENV        = os.environ.get("APNS_ENV", "sandbox")

APNS_HOST = (
    "https://api.push.apple.com"
    if APNS_ENV == "production"
    else "https://api.sandbox.push.apple.com"
)

_jwt_cache: dict[str, Any] = {"token": None, "expires_at": 0}


def _configured() -> bool:
    return bool(APNS_KEY_ID and APNS_TEAM_ID and APNS_BUNDLE_ID and APNS_KEY_P8)


def _sign_jwt() -> str:
    """
    Cached provider JWT — Apple accepts it for ~1 hour, we refresh at 50 min.
    """
    now = int(time.time())
    if _jwt_cache["token"] and now < _jwt_cache["expires_at"] - 60:
        return _jwt_cache["token"]

    # Normalize newlines: env vars may store \n as literal "\n"
    key_pem = (APNS_KEY_P8 or "").replace("\\n", "\n")
    token = jwt.encode(
        payload={"iss": APNS_TEAM_ID, "iat": now},
        key=key_pem,
        algorithm="ES256",
        headers={"kid": APNS_KEY_ID, "alg": "ES256"},
    )
    _jwt_cache["token"] = token
    _jwt_cache["expires_at"] = now + 50 * 60
    return token


async def send_push(
    device_token: str,
    title: str,
    body: str,
    *,
    thread_id: Optional[str] = None,
    category: Optional[str] = None,
    badge: Optional[int] = None,
    custom: Optional[dict] = None,
) -> dict[str, Any]:
    """Send a single push. Returns {'ok': bool, ...}."""
    if not _configured():
        return {"ok": False, "reason": "apns-not-configured"}

    aps: dict[str, Any] = {
        "alert": {"title": title, "body": body},
        "sound": "default",
    }
    if badge is not None: aps["badge"] = badge
    if thread_id:         aps["thread-id"] = thread_id
    if category:          aps["category"] = category

    payload: dict[str, Any] = {"aps": aps}
    if custom:
        payload.update(custom)

    headers = {
        "authorization": f"bearer {_sign_jwt()}",
        "apns-topic": APNS_BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
    }
    url = f"{APNS_HOST}/3/device/{device_token}"

    async with httpx.AsyncClient(http2=True, timeout=15) as c:
        r = await c.post(url, headers=headers, content=json.dumps(payload))
    if r.status_code == 200:
        return {"ok": True}
    return {"ok": False, "status": r.status_code, "body": r.text[:200]}


async def broadcast(users_col, title: str, body: str, **kwargs) -> dict[str, Any]:
    """Send to every user with a registered iOS device_token."""
    sent = failed = 0
    async for u in users_col.find({"push.device_token": {"$exists": True, "$ne": None}}):
        tok = u.get("push", {}).get("device_token")
        if not tok:
            continue
        try:
            res = await send_push(tok, title, body, **kwargs)
            if res.get("ok"):
                sent += 1
            else:
                failed += 1
        except Exception:
            failed += 1
    return {"sent": sent, "failed": failed}
