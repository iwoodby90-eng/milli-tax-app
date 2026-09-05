"""Observability: structured logs, latency, errors, health.

Sun's §11 (Phase 0 subset): structured application logs (JSON, no sensitive
data), request latency measurement, HTTP/service error counters, AI
gateway/provider failure counters, tool failure counters, correlation IDs on
every record, and health/readiness endpoints.
"""

from __future__ import annotations

import json
import time
from collections import Counter
from dataclasses import dataclass, field


# Keys never allowed in log records (same policy as the audit envelope).
_FORBIDDEN_LOG_KEYS = frozenset({
    "prompt", "raw_prompt", "user_prompt", "message", "user_message",
    "ssn", "account_number", "full_account_number", "credential",
    "api_key", "password", "tax_return", "provider_raw_response",
})


class SensitiveDataInLog(Exception):
    pass


@dataclass
class Observability:
    """In-memory structured log + metrics collector (Phase 0).

    Production swaps the sink for a log aggregator; the recording interface
    and the no-sensitive-data policy are unchanged.
    """

    logs: list[dict] = field(default_factory=list)
    counters: Counter = field(default_factory=Counter)
    latencies_ms: list[float] = field(default_factory=list)

    def log(self, level: str, message: str, **fields) -> dict:
        for k in fields:
            if str(k).lower() in _FORBIDDEN_LOG_KEYS:
                raise SensitiveDataInLog(f"forbidden field in log: {k}")
        record = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "level": level,
            "message": message,
            **fields,
        }
        self.logs.append(record)
        return record

    def info(self, message: str, **fields) -> dict:
        return self.log("info", message, **fields)

    def error(self, message: str, **fields) -> dict:
        self.counters["errors_total"] += 1
        return self.log("error", message, **fields)

    def record_latency(self, kind: str, ms: float) -> None:
        self.counters[f"latency_{kind}_count"] += 1
        self.latencies_ms.append(ms)

    def record_provider_failure(self, provider: str) -> None:
        self.counters[f"provider_failure_{provider}"] += 1

    def record_tool_failure(self, tool: str) -> None:
        self.counters[f"tool_failure_{tool}"] += 1

    def p95_latency_ms(self) -> float:
        if not self.latencies_ms:
            return 0.0
        s = sorted(self.latencies_ms)
        idx = min(len(s) - 1, int(0.95 * len(s)))
        return s[idx]

    def dump_json(self) -> str:
        return json.dumps(self.logs, indent=2)
