"""Security Event Engine — canonical model + emitters (Phase 0 foundation).

Implements the canonical security-event schema from Sun's §8.1: structured
events with event_id, event_type, user/session ids, severity/risk metadata,
and a persistence/transport abstraction. Phase 0 ships the model, the
ingestion pipeline, and initial emitters where safely possible
(authentication failures, authorization denials, prohibited-data blocks).

Risk scoring / correlation / policy actions arrive in Phase 1.
"""

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from enum import Enum


class Severity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


# Default severities per Sun's §8.2 (subset relevant to Phase 0 emitters).
DEFAULT_SEVERITIES: dict[str, Severity] = {
    "failed_login": Severity.MEDIUM,
    "failed_login_spike": Severity.HIGH,
    "ai_tool_permission_denied": Severity.MEDIUM,
    "prohibited_data_blocked": Severity.HIGH,
    "unauthenticated_ai_request": Severity.MEDIUM,
    "provider_unavailable": Severity.LOW,
}


@dataclass(frozen=True)
class SecurityEvent:
    event_id: str
    event_type: str
    user_id: str | None
    session_id: str | None
    correlation_id: str | None
    severity: Severity
    risk_score: int
    risk_signals: tuple[str, ...]
    timestamp: str
    event_data: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "event_id": self.event_id,
            "event_type": self.event_type,
            "user_id": self.user_id,
            "session_id": self.session_id,
            "correlation_id": self.correlation_id,
            "severity": self.severity.value,
            "risk_score": self.risk_score,
            "risk_signals": list(self.risk_signals),
            "timestamp": self.timestamp,
            "event_data": self.event_data,
        }


class SecurityEventSink:
    """Persistence/transport abstraction for security events.

    Phase 0: in-memory list (tests inspect it directly). Production swaps in
    an append-only encrypted store; the interface is unchanged.
    """

    def __init__(self) -> None:
        self.events: list[SecurityEvent] = []

    def emit(self, event: SecurityEvent) -> SecurityEvent:
        self.events.append(event)
        return event


class SecurityEventEngine:
    """Ingestion + emission of canonical security events."""

    def __init__(self, sink: SecurityEventSink | None = None) -> None:
        self.sink = sink or SecurityEventSink()

    def raise_event(
        self,
        event_type: str,
        *,
        user_id: str | None = None,
        session_id: str | None = None,
        correlation_id: str | None = None,
        risk_score: int = 0,
        risk_signals: tuple[str, ...] = (),
        event_data: dict | None = None,
    ) -> SecurityEvent:
        severity = DEFAULT_SEVERITIES.get(event_type, Severity.LOW)
        event = SecurityEvent(
            event_id=f"se_{uuid.uuid4().hex[:16]}",
            event_type=event_type,
            user_id=user_id,
            session_id=session_id,
            correlation_id=correlation_id,
            severity=severity,
            risk_score=risk_score,
            risk_signals=risk_signals,
            timestamp=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            event_data=event_data or {},
        )
        return self.sink.emit(event)
