"""AI Orchestrator — the Phase 0 request lifecycle.

Lifecycle (Sun's §4, Phase 0 subset):
  1. identity (request_id / user_id / session_id / correlation_id)
  2. authentication + authorization (deny-by-default, scope `ai:chat`)
  3. data classification + minimization/redaction of the user message
  4. model gateway call (fails safe when provider unconfigured)
  5. audit envelope written (hash-chained, no sensitive data)
  6. security events + operational analytics emitted

The user's raw prompt is NEVER persisted: it exists only in memory during
request processing. The audit envelope records metadata only.
"""

from __future__ import annotations

import time
from dataclasses import dataclass

from .audit import AuditEnvelope, AuditLog
from .auth import AuthenticationError, AuthorizationError, SessionStore
from .classification import DataClassification, assert_model_safe, minimize
from .identity import RequestIdentity, build_identity
from .model_gateway import ModelGateway, ModelCallResult
from .observability import Observability
from .security_events import SecurityEventEngine
from .tools import ToolRegistry


AI_CHAT_SCOPE = "ai:chat"


@dataclass(frozen=True)
class OrchestratorResult:
    status: int
    request_id: str
    correlation_id: str
    response: dict


class AIOrchestrator:
    def __init__(
        self,
        sessions: SessionStore,
        gateway: ModelGateway,
        audit_log: AuditLog,
        security: SecurityEventEngine,
        observability: Observability,
        tools: ToolRegistry | None = None,
    ) -> None:
        self.sessions = sessions
        self.gateway = gateway
        self.audit_log = audit_log
        self.security = security
        self.obs = observability
        self.tools = tools or ToolRegistry()

    def chat(
        self,
        bearer_token: str,
        session_id: str,
        user_message: str,
        correlation_id: str | None = None,
    ) -> OrchestratorResult:
        started = time.monotonic()

        # 1-2. Authentication + authorization (deny-by-default).
        try:
            user_id, scopes = self.sessions.authenticate(bearer_token)
            self.sessions.authorize(scopes, AI_CHAT_SCOPE)
        except AuthenticationError:
            self.security.raise_event("unauthenticated_ai_request", correlation_id=correlation_id)
            return OrchestratorResult(401, "", correlation_id or "", {
                "error": "unauthenticated"
            })
        except AuthorizationError:
            self.security.raise_event(
                "ai_tool_permission_denied",
                user_id=user_id,
                session_id=session_id,
                correlation_id=correlation_id,
            )
            return OrchestratorResult(403, "", correlation_id or "", {
                "error": "forbidden"
            })

        identity: RequestIdentity = build_identity(user_id, session_id, correlation_id)

        # 3. Classification + minimization BEFORE any model transmission.
        mini = minimize(user_message)
        safe_context = assert_model_safe(mini.redacted_text)

        # 4. Model gateway (fails safe).
        result: ModelCallResult = self.gateway.complete(safe_context)
        if not result.ok:
            self.obs.record_provider_failure(result.provider)
            self.security.raise_event(
                "provider_unavailable",
                user_id=user_id,
                session_id=session_id,
                correlation_id=identity.correlation_id,
            )

        latency_ms = int((time.monotonic() - started) * 1000)
        self.obs.record_latency("ai_chat", latency_ms)

        # 5. Audit envelope — metadata only, never the raw prompt.
        envelope = AuditEnvelope(
            request_id=identity.request_id,
            user_id=identity.user_id,
            session_id=identity.session_id,
            correlation_id=identity.correlation_id,
            model=result.model or "unavailable",
            prompt_version=result.prompt_version,
            context_sources=["user_message"],
            data_classifications=sorted(c.value for c in mini.classifications_present),
            tool_permissions=sorted(self.tools.permitted_tools(scopes)),
            tools_requested=[],
            tools_executed=[],
            authoritative_results=[],
            policy_outcome={
                "risk_score": 0,
                "action": "permit",
                "step_up_triggered_for": [],
            },
            response_status="success" if result.ok else "provider_unavailable",
            latency={"total_ms": latency_ms},
        )
        self.audit_log.append(envelope)

        self.obs.info(
            "ai_chat_completed",
            request_id=identity.request_id,
            correlation_id=identity.correlation_id,
            response_status=envelope.response_status,
            latency_ms=latency_ms,
        )

        if not result.ok:
            return OrchestratorResult(503, identity.request_id, identity.correlation_id, {
                "error": "ai_temporarily_unavailable",
                "request_id": identity.request_id,
            })

        return OrchestratorResult(200, identity.request_id, identity.correlation_id, {
            "response": result.completion_text,
            "request_id": identity.request_id,
            "provenance": [],
            "pending_actions": [],
        })
