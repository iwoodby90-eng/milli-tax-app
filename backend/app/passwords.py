"""Password hashing and policy.

Digests are salted scrypt values from the standard library, stored as
``scrypt$n$r$p$salt$digest`` with base64 fields. Verification is constant time
and never reveals whether the email or the password was wrong.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import secrets

SCRYPT_N = 2**15
SCRYPT_R = 8
SCRYPT_P = 1
SALT_BYTES = 16
DIGEST_BYTES = 32

MIN_PASSWORD_LENGTH = 12
MAX_PASSWORD_LENGTH = 128

BANNED_FRAGMENTS = (
    "password",
    "qwerty",
    "123456",
    "letmein",
    "welcome",
    "iloveyou",
    "admin",
    "milli",
)

_DUMMY_HASH: str | None = None


def _b64(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def _unb64(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(value + padding)


def _derive(password: str, salt: bytes, n: int, r: int, p: int) -> bytes:
    return hashlib.scrypt(
        password.encode("utf-8"),
        salt=salt,
        n=n,
        r=r,
        p=p,
        dklen=DIGEST_BYTES,
        maxmem=256 * n * r,
    )


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(SALT_BYTES)
    digest = _derive(password, salt, SCRYPT_N, SCRYPT_R, SCRYPT_P)
    return f"scrypt${SCRYPT_N}${SCRYPT_R}${SCRYPT_P}${_b64(salt)}${_b64(digest)}"


def verify_password(password: str, stored: str) -> bool:
    try:
        scheme, n, r, p, salt, digest = stored.split("$")
        if scheme != "scrypt":
            return False
        candidate = _derive(password, _unb64(salt), int(n), int(r), int(p))
    except (ValueError, TypeError):
        return False
    return hmac.compare_digest(candidate, _unb64(digest))


def waste_verification_time() -> None:
    """Spend the same work as a real verification for unknown accounts."""
    global _DUMMY_HASH
    if _DUMMY_HASH is None:
        _DUMMY_HASH = hash_password(secrets.token_urlsafe(32))
    verify_password(secrets.token_urlsafe(32), _DUMMY_HASH)


def password_policy_error(password: str) -> str | None:
    if len(password) < MIN_PASSWORD_LENGTH:
        return f"password must be at least {MIN_PASSWORD_LENGTH} characters"
    if len(password) > MAX_PASSWORD_LENGTH:
        return f"password must be at most {MAX_PASSWORD_LENGTH} characters"
    if not any(character.isalpha() for character in password):
        return "password must contain a letter"
    if not any(character.isdigit() for character in password):
        return "password must contain a number"
    if len(set(password)) < 5:
        return "password is too repetitive"
    lowered = password.lower()
    if any(fragment in lowered for fragment in BANNED_FRAGMENTS):
        return "password contains a commonly guessed phrase"
    return None


def normalize_email(email: str) -> str:
    return email.strip().lower()
