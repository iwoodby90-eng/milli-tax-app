"""AI audit envelope — append-only, hash-chained, no sensitive data.

Implements Sun's §13. The envelope records every AI request with full
provenance metadata and NONE of the following, ever:

- raw user prompts
- SSNs, full account numbers, credentials
- tax-return contents
- model provider raw responses

Integrity: each envelope embeds the SHA-256 of the previous envelope,
forming a tamper-evident chain. Storage is an append-only JSONL file in
Phase 0 (a write-once table in production).
"""

from __future__ import annotations

import hashlib
import json
import os
import threading
import time
from dataclasses import dataclass, field
from typing import Any

GENESIS_HASH = "0" * 64

# Fields that must never appear in an envelope (defense in depth — the
# pipeline never puts them there in the first place).
FORBIDDEN_KEYS = {
    "prompt", "raw_prompt", "user_prompt", "message", "user_message",
    "ssn", "account_number", "full_account_number", "credential",
    "api_key", "password", "tax_return", "provider_raw_response",
}


class SensitiveDataInEnvelope(Exception):
    """Raised if a forbidden field would be written to an envelope."""


@dataclass
class AuditEnvelope:
    request_id: str
    user_id: str
    session_id: str
    correlation_id: str
    model: str
    prompt_version: str
    context_sources: list[str] = field(default_factory=list)
    data_classifications: list[str] = field(default_factory=list)
    tool_permissions: list[str] = field(default_factory=list)
    tools_requested: list[dict] = field(default_factory=list)
    tools_executed: list[dict] = field(default_factory=list)
    authoritative_results: list[dict] = field(default_factory=list)
    policy_outcome: dict = field(default_factory=dict)
    response_status: str = "pending"
    latency: dict = field(default_factory=dict)
    timestamp: str = ""
    previous_hash: str = GENESIS_HASH
    envelope_hash: str = ""

    def to_dict(self) -> dict[str, Any]:
        d = self.__dict__.copy()
        d.pop("envelope_hash", None)
        return d


def _scan_forbidden(value: Any, path: str = "") -> None:
    if isinstance(value, dict):
        for k, v in value.items():
            if str(k).lower() in FORBIDDEN_KEYS:
                raise SensitiveDataInEnvelope(f"forbidden field in envelope: {path}/{k}")
            _scan_forbidden(v, f"{path}/{k}")
    elif isinstance(value, list):
        for i, v in enumerate(value):
            _scan_forbidden(v, f"{path}[{i}]")


class AuditLog:
    """Append-only, hash-chained audit log (JSONL file)."""

    def __init__(self, path: str | None = None) -> None:
        self._path = path or os.environ.get("MILLI_AUDIT_LOG_PATH", "audit/audit_log.jsonl")
        self._lock = threading.Lock()
        self._last_hash = GENESIS_HASH
        self._records: list[dict] = []
        self._load_existing()

    def _load_existing(self) -> None:
        if not os.path.exists(self._path):
            return
        with open(self._path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                rec = json.loads(line)
                self._records.append(rec)
                self._last_hash = rec.get("envelope_hash", GENESIS_HASH)

    @property
    def last_hash(self) -> str:
        return self._last_hash

    def append(self, envelope: AuditEnvelope) -> dict:
        """Append an envelope. Returns the stored record.

        Raises SensitiveDataInEnvelope if any forbidden field is present.
        """
        record = envelope.to_dict()
        _scan_forbidden(record)
        envelope.previous_hash = self._last_hash
        record["previous_hash"] = self._last_hash
        envelope.timestamp = envelope.timestamp or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        record["timestamp"] = envelope.timestamp
        payload = json.dumps(record, sort_keys=True, separators=(",", ":"))
        envelope.envelope_hash = hashlib.sha256(payload.encode("utf-8")).hexdigest()
        record["envelope_hash"] = envelope.envelope_hash
        with self._lock:
            os.makedirs(os.path.dirname(self._path) or ".", exist_ok=True)
            with open(self._path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, sort_keys=True) + "\n")
            self._records.append(record)
            self._last_hash = envelope.envelope_hash
        return record

    def verify_chain(self) -> bool:
        """Verify the hash chain of all loaded records."""
        prev = GENESIS_HASH
        for rec in self._records:
            if rec.get("previous_hash") != prev:
                return False
            body = {k: v for k, v in rec.items() if k != "envelope_hash"}
            payload = json.dumps(body, sort_keys=True, separators=(",", ":"))
            if hashlib.sha256(payload.encode("utf-8")).hexdigest() != rec.get("envelope_hash"):
                return False
            prev = rec["envelope_hash"]
        return True

    def records(self) -> list[dict]:
        return list(self._records)
