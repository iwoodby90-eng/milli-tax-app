"""MILLI AI Gateway — FastAPI application (Phase 0).

Endpoints:
- GET  /healthz      — liveness
- GET  /readyz       — readiness (reports provider configuration state)
- POST /v1/ai/chat   — authenticated AI chat (the only AI surface)

All AI requests require a Bearer session token with the `ai:chat` scope.
Unauthenticated requests are rejected with 401 before any orchestration.
"""

from __future__ import annotations

import os
import tempfile

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

from .analytics import OperationalAnalytics
from .audit import AuditLog
from .auth import SessionStore
from .model_gateway import ModelGateway
from .observability import Observability
from .orchestrator import AIOrchestrator
from .security_events import SecurityEventEngine
from .tools import ToolRegistry


class ChatRequest(BaseModel):
    message: str
    session_id: str


class ChatResponse(BaseModel):
    response: str
    request_id: str
    provenance: list[dict]
    pending_actions: list[dict]


def create_app(
    sessions: SessionStore | None = None,
    gateway: ModelGateway | None = None,
    audit_log: AuditLog | None = None,
) -> FastAPI:
    app = FastAPI(title="MILLI AI Gateway", version="0.1.0-phase0")

    # Phase 0: audit log to a temp path unless configured; production sets
    # MILLI_AUDIT_LOG_PATH to durable append-only storage.
    if audit_log is None:
        path = os.environ.get("MILLI_AUDIT_LOG_PATH")
        if not path:
            path = os.path.join(tempfile.gettempdir(), "milli_audit_log.jsonl")
        audit_log = AuditLog(path)

    sessions = sessions or SessionStore.from_env()
    gateway = gateway or ModelGateway()
    security = SecurityEventEngine()
    obs = Observability()
    tools = ToolRegistry()  # deny-by-default: no tools registered in Phase 0
    op_analytics = OperationalAnalytics()

    orchestrator = AIOrchestrator(sessions, gateway, audit_log, security, obs, tools)

    @app.get("/healthz")
    def healthz() -> dict:
        return {"status": "ok"}

    @app.get("/readyz")
    def readyz() -> dict:
        provider_ready = gateway.is_configured()
        return {
            "status": "ready" if provider_ready else "degraded",
            "model_provider": gateway.provider,
            "model_provider_configured": provider_ready,
            # Fails safe: the service runs and rejects AI calls with 503
            # rather than crashing when the provider is unconfigured.
        }

    @app.post("/v1/ai/chat", response_model=ChatResponse)
    def chat(
        body: ChatRequest,
        authorization: str = Header(default=""),
    ) -> ChatResponse:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="unauthenticated")
        result = orchestrator.chat(
            bearer_token=authorization[len("Bearer "):],
            session_id=body.session_id,
            user_message=body.message,
        )
        if result.status != 200:
            raise HTTPException(status_code=result.status, detail=result.response)
        op_analytics.track(
            "ai_chat_completed",
            {"status_code": 200},
            correlation_id=result.correlation_id,
        )
        return ChatResponse(
            response=result.response["response"],
            request_id=result.response["request_id"],
            provenance=result.response["provenance"],
            pending_actions=result.response["pending_actions"],
        )

    return app


app = create_app()
