"""Simple per-user rate limiting.

Tracks request counts in an in-memory dict keyed by user_id with a
sliding window. This is intentionally simple for a single-instance
Render deployment. For multi-instance, swap to Redis.
"""

import time
from collections import defaultdict
from typing import Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from .config import get_settings


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Per-user rate limit: N requests per minute."""

    def __init__(self, app, exempt_paths: Optional[set[str]] = None):
        super().__init__(app)
        self._counts: dict[str, list[float]] = defaultdict(list)
        self._exempt = exempt_paths or {"/health", "/ready", "/"}

    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        if path in self._exempt:
            return await call_next(request)

        user_id = request.headers.get("x-milli-user-id", "")
        if not user_id:
            return await call_next(request)

        settings = get_settings()
        limit = settings.rate_limit_per_minute
        now = time.time()
        window = 60.0

        # Prune old entries
        self._counts[user_id] = [t for t in self._counts[user_id] if now - t < window]

        if len(self._counts[user_id]) >= limit:
            return Response(
                content='{"detail":"Rate limit exceeded"}',
                status_code=429,
                media_type="application/json",
                headers={"Retry-After": "60"},
            )

        self._counts[user_id].append(now)
        return await call_next(request)