import time
import json
import hmac
import base64
import hashlib

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.config import settings

bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    salt = settings.JWT_SECRET.encode()
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 100_000).hex()


def verify_password(password: str, hashed: str) -> bool:
    return hmac.compare_digest(hash_password(password), hashed)


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def create_token(user_id: str) -> str:
    header = _b64(json.dumps({"alg": settings.JWT_ALG, "typ": "JWT"}).encode())
    payload = _b64(json.dumps({
        "sub": user_id,
        "exp": int(time.time()) + settings.JWT_EXPIRE_HOURS * 3600,
    }).encode())
    signing_input = (header + "." + payload).encode()
    sig = hmac.new(settings.JWT_SECRET.encode(), signing_input, hashlib.sha256).digest()
    return header + "." + payload + "." + _b64(sig)


def decode_token(token: str) -> str:
    try:
        header, payload, sig = token.split(".")
        signing_input = (header + "." + payload).encode()
        expected = hmac.new(settings.JWT_SECRET.encode(), signing_input, hashlib.sha256).digest()
        if not hmac.compare_digest(_b64(expected), sig):
            raise ValueError("bad signature")
        data = json.loads(base64.urlsafe_b64decode(payload + "=="))
        if data.get("exp", 0) < time.time():
            raise ValueError("expired")
        return data["sub"]
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")


def current_user(creds: HTTPAuthorizationCredentials = Depends(bearer)) -> str:
    if creds is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    return decode_token(creds.credentials)
