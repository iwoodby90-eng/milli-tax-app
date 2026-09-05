"""Request identity: request_id / user_id / session_id / correlation ID.

Every AI request carries a unique request_id, an authenticated user_id, a
session identifier, and a correlation ID that is propagated through every
service hop (audit envelope, security events, analytics, logs).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass


@dataclass(frozen=True)
class RequestIdentity:
    request_id: str
    user_id: str
    session_id: str
    correlation_id: str

    def as_dict(self) -> dict:
        return {
            "request_id": self.request_id,
            "user_id": self.user_id,
            "session_id": self.session_id,
            "correlation_id": self.correlation_id,
        }


def new_request_id() -> str:
    return f"req_{uuid.uuid4().hex}"


def build_identity(user_id: str, session_id: str, correlation_id: str | None = None) -> RequestIdentity:
    """Build a request identity.

    The correlation ID is either supplied by the caller (propagated from an
    upstream hop) or generated fresh for the originating request.
    """
    return RequestIdentity(
        request_id=new_request_id(),
        user_id=user_id,
        session_id=session_id,
        correlation_id=correlation_id or f"corr_{uuid.uuid4().hex}",
    )
