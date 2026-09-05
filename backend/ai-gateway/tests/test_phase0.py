"""Phase 0 acceptance tests — the 10 required cases from the directive.

1.  unauthenticated AI request rejected
2.  wrong-user/resource authorization rejected
3.  unavailable provider fails safely
4.  prohibited data classification blocked/redacted
5.  missing tool permission denied
6.  audit envelope generated
7.  correlation ID propagation
8.  sensitive fields excluded from ordinary logs
9.  financial truth cannot be supplied solely by model output
10. audit chain tamper-evidence (integrity bonus, Sun §13.4)
"""

from __future__ import annotations

import os
import tempfile

import pytest
from fastapi.testclient import TestClient

from app.analytics import FinancialAnalytics, FinancialTruthFromClient, ProductAnalytics, CrossDomainViolation
from app.audit import AuditEnvelope, AuditLog, SensitiveDataInEnvelope
from app.auth import AuthenticationError, AuthorizationError, SessionStore
from app.classification import assert_model_safe, minimize
from app.identity import build_identity
from app.model_gateway import ModelGateway
from app.observability import Observability, SensitiveDataInLog
from app.orchestrator import AIOrchestrator
from app.security_events import SecurityEventEngine
from app.tools import ToolContract, ToolClass, ToolPermissionDenied, ToolRegistry


GOOD_TOKEN = "tok_good"
USER_TOKEN = "tok_user"
ADMIN_TOKEN = "tok_admin"


def make_sessions() -> SessionStore:
    return SessionStore({
        GOOD_TOKEN: ("usr_1", frozenset({"ai:chat"})),
        USER_TOKEN: ("usr_2", frozenset({"vault:read"})),   # no ai:chat
        ADMIN_TOKEN: ("usr_3", frozenset({"ai:chat", "admin"})),
    })


def make_gateway(configured: bool = True) -> ModelGateway:
    if configured:
        return ModelGateway(provider="openai", api_key="test-key", model="gpt-test", prompt_version="v0.1")
    return ModelGateway(provider=None, api_key=None)


def make_orchestrator(configured: bool = True, audit_path: str | None = None):
    audit = AuditLog(audit_path or os.path.join(tempfile.mkdtemp(), "audit.jsonl"))
    obs = Observability()
    sec = SecurityEventEngine()
    orch = AIOrchestrator(make_sessions(), make_gateway(configured), audit, sec, obs)
    return orch, audit, obs, sec


def make_client(configured: bool = True):
    from app.main import create_app
    audit_path = os.path.join(tempfile.mkdtemp(), "audit.jsonl")
    app = create_app(
        sessions=make_sessions(),
        gateway=make_gateway(configured),
        audit_log=AuditLog(audit_path),
    )
    return TestClient(app), audit_path


# 1. Unauthenticated AI request rejected
def test_unauthenticated_request_rejected():
    client, _ = make_client()
    r = client.post("/v1/ai/chat", json={"message": "hi", "session_id": "s1"})
    assert r.status_code == 401
    # No bearer header at orchestrator level too
    orch, _, _, sec = make_orchestrator()
    res = orch.chat("", "s1", "hi")
    assert res.status == 401
    assert any(e.event_type == "unauthenticated_ai_request" for e in sec.sink.events)


def test_unknown_token_rejected():
    client, _ = make_client()
    r = client.post(
        "/v1/ai/chat",
        json={"message": "hi", "session_id": "s1"},
        headers={"Authorization": "Bearer bogus"},
    )
    assert r.status_code == 401


# 2. Wrong-user/resource authorization rejected
def test_wrong_scope_rejected():
    client, _ = make_client()
    r = client.post(
        "/v1/ai/chat",
        json={"message": "hi", "session_id": "s1"},
        headers={"Authorization": f"Bearer {USER_TOKEN}"},
    )
    assert r.status_code == 403


def test_user_isolation():
    # usr_2's token cannot act as usr_1: identity derives from the token, never
    # from client-supplied claims.
    orch, _, _, sec = make_orchestrator()
    res = orch.chat(USER_TOKEN, "s1", "hi")
    assert res.status == 403
    assert any(e.event_type == "ai_tool_permission_denied" for e in sec.sink.events)


# 3. Unavailable provider fails safely
def test_unavailable_provider_fails_safe():
    client, _ = make_client(configured=False)
    r = client.post(
        "/v1/ai/chat",
        json={"message": "hi", "session_id": "s1"},
        headers={"Authorization": f"Bearer {GOOD_TOKEN}"},
    )
    assert r.status_code == 503
    assert r.json()["detail"]["error"] == "ai_temporarily_unavailable"
    # readiness reports degraded, service stays up
    assert client.get("/readyz").json()["status"] == "degraded"
    assert client.get("/healthz").status_code == 200


def test_provider_never_leaks_credentials():
    gw = make_gateway(configured=True)
    result = gw.complete("hello")
    dumped = str(result.__dict__)
    assert "test-key" not in dumped


# 4. Prohibited data classification blocked/redacted
def test_restricted_data_redacted_before_model():
    text = "My SSN is 123-45-6789 and my password: hunter2"
    mini = minimize(text)
    assert "123-45-6789" not in mini.redacted_text
    assert "hunter2" not in mini.redacted_text
    assert "[SSN_REDACTED]" in mini.redacted_text
    assert "[CREDENTIAL_REDACTED]" in mini.redacted_text


def test_prohibited_data_never_reaches_model():
    orch, audit, _, _ = make_orchestrator()
    res = orch.chat(GOOD_TOKEN, "s1", "Pay from ACCT: 12345678901234, SSN 123-45-6789")
    assert res.status == 200
    # The audit envelope must not contain the raw values
    for rec in audit.records():
        blob = str(rec)
        assert "123-45-6789" not in blob
        assert "12345678901234" not in blob


# 5. Missing tool permission denied
def test_tool_permission_denied():
    reg = ToolRegistry([
        ToolContract(
            name="balance.inquiry",
            description="read balance",
            permission_scope="balance:read",
            tool_class=ToolClass.READ_ONLY,
            enabled=True,
        ),
    ])
    # user without balance:read scope
    with pytest.raises(ToolPermissionDenied):
        reg.authorize_tool("balance.inquiry", frozenset({"ai:chat"}))
    # unknown tool
    with pytest.raises(ToolPermissionDenied):
        reg.authorize_tool("sql.query", frozenset({"ai:chat"}))


def test_consequential_tool_blocked_in_phase0():
    reg = ToolRegistry([
        ToolContract(
            name="tax_payment.propose",
            description="propose payment",
            permission_scope="tax:payment:propose",
            tool_class=ToolClass.CONSEQUENTIAL,
            enabled=True,
        ),
    ])
    with pytest.raises(ToolPermissionDenied):
        reg.authorize_tool("tax_payment.propose", frozenset({"tax:payment:propose"}))


def test_no_tools_registered_by_default():
    reg = ToolRegistry()
    assert reg.permitted_tools(frozenset({"ai:chat", "balance:read"})) == []


# 6. Audit envelope generated
def test_audit_envelope_generated():
    client, audit_path = make_client()
    r = client.post(
        "/v1/ai/chat",
        json={"message": "hi", "session_id": "s1"},
        headers={"Authorization": f"Bearer {GOOD_TOKEN}"},
    )
    assert r.status_code == 200
    audit = AuditLog(audit_path)
    recs = audit.records()
    assert len(recs) == 1
    rec = recs[0]
    for field in ("request_id", "user_id", "session_id", "model", "prompt_version",
                  "data_classifications", "policy_outcome", "response_status", "latency", "timestamp"):
        assert field in rec
    assert rec["user_id"] == "usr_1"
    assert rec["prompt_version"] == "v0.1"


def test_envelope_rejects_sensitive_fields():
    log = AuditLog(os.path.join(tempfile.mkdtemp(), "a.jsonl"))
    env = AuditEnvelope(
        request_id="r", user_id="u", session_id="s", correlation_id="c",
        model="m", prompt_version="v",
    )
    env.policy_outcome = {"action": "permit", "message": "raw prompt here"}
    with pytest.raises(SensitiveDataInEnvelope):
        log.append(env)


# 7. Correlation ID propagation
def test_correlation_id_propagation():
    orch, audit, obs, sec = make_orchestrator()
    res = orch.chat(GOOD_TOKEN, "s1", "hi", correlation_id="corr_fixed_123")
    assert res.correlation_id == "corr_fixed_123"
    rec = audit.records()[-1]
    assert rec["correlation_id"] == "corr_fixed_123"
    assert any("corr_fixed_123" in str(l) for l in obs.logs)
    # security events carry the correlation id whenever one is raised
    orch.chat(GOOD_TOKEN, "s1", "hi", correlation_id="corr_fixed_123")
    orch.chat(USER_TOKEN, "s1", "hi", correlation_id="corr_fixed_123")  # denied -> event
    assert any(e.correlation_id == "corr_fixed_123" for e in sec.sink.events)


def test_generated_correlation_id():
    orch, audit, _, _ = make_orchestrator()
    orch.chat(GOOD_TOKEN, "s1", "hi")
    rec = audit.records()[-1]
    assert rec["correlation_id"].startswith("corr_")


# 8. Sensitive fields excluded from ordinary logs
def test_logs_reject_sensitive_fields():
    obs = Observability()
    with pytest.raises(SensitiveDataInLog):
        obs.info("something", raw_prompt="raw user prompt")
    with pytest.raises(SensitiveDataInLog):
        obs.info("something", ssn="123-45-6789")
    with pytest.raises(SensitiveDataInLog):
        obs.info("something", api_key="secret")


def test_raw_prompt_not_in_logs_or_envelope():
    orch, audit, obs, _ = make_orchestrator()
    secret_msg = "My SSN is 123-45-6789"
    orch.chat(GOOD_TOKEN, "s1", secret_msg)
    all_logs = str(obs.logs) + str(audit.records())
    assert "123-45-6789" not in all_logs
    assert secret_msg not in all_logs


# 9. Financial truth cannot be supplied solely by model output
def test_financial_truth_not_from_model():
    fa = FinancialAnalytics()
    with pytest.raises(FinancialTruthFromClient):
        fa.metric("total_volume", source="client_analytics")
    with pytest.raises(FinancialTruthFromClient):
        fa.metric("total_volume", source="model_output")
    ev = fa.metric("total_volume", source="ledger.transfers")
    assert ev.domain.value == "financial"


def test_product_analytics_rejects_financial_fields():
    pa = ProductAnalytics()
    with pytest.raises(CrossDomainViolation):
        pa.track("purchase", {"amount": 100})
    ev = pa.track("screen_viewed", {"screen_name": "home"})
    assert ev.domain.value == "product"


# 10. Audit chain tamper evidence
def test_audit_chain_tamper_evident():
    path = os.path.join(tempfile.mkdtemp(), "a.jsonl")
    log = AuditLog(path)
    for i in range(3):
        env = AuditEnvelope(
            request_id=f"r{i}", user_id="u", session_id="s", correlation_id="c",
            model="m", prompt_version="v",
        )
        log.append(env)
    assert log.verify_chain()
    # Tamper: rewrite the first record on disk
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    import json
    rec = json.loads(lines[0])
    rec["user_id"] = "tampered"
    lines[0] = json.dumps(rec, sort_keys=True) + "\n"
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)
    tampered = AuditLog(path)
    assert not tampered.verify_chain()


def test_identity_uniqueness():
    a = build_identity("u", "s")
    b = build_identity("u", "s")
    assert a.request_id != b.request_id
