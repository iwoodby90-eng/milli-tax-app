"""Encryption boundary for provider credentials."""
from cryptography.fernet import Fernet, InvalidToken
from .config import get_settings

PREFIX = "enc:v1:"

def _fernet():
    key = get_settings().provider_token_encryption_key
    return Fernet(key.encode()) if key else None

def encrypt_provider_secret(value: str) -> str:
    f = _fernet()
    if f is None:
        if get_settings().environment == "production":
            raise RuntimeError("provider-token encryption required in production")
        return value
    return PREFIX + f.encrypt(value.encode()).decode()

def decrypt_provider_secret(value: str) -> str:
    if value.startswith(PREFIX):
        f = _fernet()
        if f is None:
            raise RuntimeError("provider-token encryption key unavailable")
        try:
            return f.decrypt(value[len(PREFIX):].encode()).decode()
        except InvalidToken as exc:
            raise RuntimeError("provider credential cannot be decrypted") from exc
    if get_settings().environment == "production":
        raise RuntimeError("plaintext provider credential rejected in production")
    return value
