"""Best-effort in-process throttling for unauthenticated endpoints.

Credential-exchange and webhook routes accept traffic before any session
exists, so they are the only surfaces an anonymous caller can hammer. This
limiter is per-process and therefore a defence-in-depth measure, not a
substitute for an edge/WAF limit: it bounds abuse from a single caller against
a single instance and never relaxes any cryptographic check.
"""

from __future__ import annotations

import time
from collections import deque
from threading import Lock

RATE_LIMITED_PREFIXES: tuple[str, ...] = ("/auth/", "/plaid/webhook")

DEFAULT_MAX_REQUESTS = 30
DEFAULT_WINDOW_SECONDS = 60.0


class RateLimiter:
    def __init__(
        self,
        max_requests: int = DEFAULT_MAX_REQUESTS,
        window_seconds: float = DEFAULT_WINDOW_SECONDS,
    ) -> None:
        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._hits: dict[str, deque[float]] = {}
        self._next_prune = 0.0
        self._lock = Lock()

    def allow(self, key: str) -> tuple[bool, int]:
        """Return whether the call is allowed and, if not, seconds to retry."""
        now = time.monotonic()
        cutoff = now - self._window_seconds
        with self._lock:
            if now >= self._next_prune:
                self._prune(cutoff)
                self._next_prune = now + self._window_seconds
            hits = self._hits.setdefault(key, deque())
            while hits and hits[0] <= cutoff:
                hits.popleft()
            if len(hits) >= self._max_requests:
                return False, max(1, int(hits[0] + self._window_seconds - now) + 1)
            hits.append(now)
        return True, 0

    def _prune(self, cutoff: float) -> None:
        """Drop keys idle for a full window; O(keys), so at most once per window."""
        for stale in [key for key, hits in self._hits.items() if not hits or hits[-1] <= cutoff]:
            del self._hits[stale]

    def reset(self) -> None:
        with self._lock:
            self._hits.clear()
            self._next_prune = 0.0
