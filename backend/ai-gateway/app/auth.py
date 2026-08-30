"""Authentication and deny-by-default authorization.

Phase 0 stand-in: session tokens are supplied via environment configuration
(`MILLI_SESSION_TOKENS`). A real identity provider (OAuth 2.0 / OIDC with
short-lived access tokens and refresh rotation) is a later phase and requires
a vendor contract.

Rules enforced here:
- Unauthenticated requests are rejected (401) before any AI orchestration.
- Authorization is deny-by-default: a request is only admitted if the token
  is explicitly known AND the user has the `ai:chat` scope.
"""

from __future__ import annotations

import os


class AuthenticationError(Exception):
    """Raised when a request is not authenticated."""


class AuthorizationError(Exception):
    """Raised when an authenticated user is not permitted to perform an action."""


class SessionStore:
    """Phase 0 in-memory/config session store.

    Maps session tokens to (user_id, scopes). In production this is backed by
    the identity provider with short-lived tokens (TTL <= 15 min) and refresh
    rotation.
    """

    def __init__(self, tokens: dict[str, tuple[str, frozenset[str]]] | None = None) -> None:
        self._tokens: dict[str, tuple[str, frozenset[str]]] = dict(tokens or {})

    @classmethod
    def from_env(cls) -> "SessionStore":
        """Load session tokens from MILLI_SESSION_TOKENS (comma-separated).

        Format per entry: `token:user_id` or `token:user_id:scope1|scope2`.
        """
        raw = os.environ.get("MILLI_SESSION_TOKENS", "")
        tokens: dict[str, tuple[str, frozenset[str]]] = {}
        for entry in raw.split(","):
            entry = entry.strip()
            if not entry:
                continue
            parts = entry.split(":")
            if len(parts) < 2:
                continue
            token, user_id = parts[0], parts[1]
            scopes = frozenset(parts[2].split("|")) if len(parts) > 2 else frozenset()
            tokens[token] = (user_id, scopes)
        return cls(tokens)

    def authenticate(self, bearer_token: str) -> tuple[str, frozenset[str]]:
        """Validate a bearer token. Returns (user_id, scopes).

        Raises AuthenticationError for unknown/missing tokens.
        """
        if not bearer_token:
            raise AuthenticationError("missing bearer token")
        entry = self._tokens.get(bearer_token)
        if entry is None:
            raise AuthenticationError("unknown or revoked session token")
        return entry

    def authorize(self, scopes: frozenset[str], required_scope: str) -> None:
        """Deny-by-default scope check. Raises AuthorizationError."""
        if required_scope not in scopes:
            raise AuthorizationError(
                f"missing required scope: {required_scope}"
            )
