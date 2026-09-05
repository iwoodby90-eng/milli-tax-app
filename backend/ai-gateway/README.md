# MILLI AI Gateway — Phase 0 (Foundation & Trust Boundaries)

Implements Phase 0 of the "MILLI AI — Backend, Security & Analytics Architecture
(Production Requirements)" document (Sun's approved package). That document is
the architectural source of truth; this service is its Phase 0 scaffold.

## Architectural invariants enforced here

- No model-provider calls from the iOS client; all AI traffic routes through
  this authenticated API. Provider credentials live server-side only.
- The LLM never becomes financial truth. No tool in Phase 0 can mutate
  financial state; the tool registry is deny-by-default and ships with zero
  enabled tools.
- No raw prompts, SSNs, full account numbers, credentials, or tax-return
  contents in ordinary logs or in the audit envelope.
- Consequential actions are not implemented in Phase 0.

## Components

| Module | Responsibility |
| --- | --- |
| `app/main.py` | FastAPI app, middleware (request identity, correlation ID, structured logging), health/readiness |
| `app/auth.py` | Bearer session-token validation, deny-by-default authorization |
| `app/identity.py` | request_id / user_id / session_id / correlation ID propagation |
| `app/classification.py` | Data classification taxonomy (RESTRICTED / CONFIDENTIAL / INTERNAL / PUBLIC) + redaction/minimization pipeline |
| `app/model_gateway.py` | Provider abstraction; credentials from environment only; fails safe when configuration is missing |
| `app/tools.py` | Typed tool contract registry, deny-by-default permissions, read-only vs consequential classes |
| `app/audit.py` | Append-only, hash-chained AI audit envelope (JSONL) |
| `app/security_events.py` | Canonical security-event model + emitters |
| `app/analytics.py` | Separated product / operational / financial analytics interfaces |
| `app/observability.py` | Structured application logs, latency metrics, error counters |
| `app/orchestrator.py` | Request lifecycle: identity → authz → classification → model gateway → audit |

## Environment variables

| Variable | Purpose | Required |
| --- | --- | --- |
| `MILLI_SESSION_TOKENS` | Comma-separated valid session tokens (Phase 0 stand-in for a real identity provider) | Yes in production; tests inject their own |
| `MILLI_MODEL_PROVIDER` | Provider name (`openai`, `anthropic`, ...) | No — absent means AI is unavailable and the service fails safe (503) |
| `MILLI_MODEL_API_KEY` | Provider credential, server-side only | No — absent means AI is unavailable (503) |
| `MILLI_MODEL_NAME` | Model identifier | No |
| `MILLI_SYSTEM_PROMPT_VERSION` | Version tag of the server-side system prompt | No (defaults to `unversioned`) |
| `MILLI_AUDIT_LOG_PATH` | Path of the append-only audit JSONL file | No (defaults to `./audit/audit_log.jsonl`) |

No hard-coded secrets. Production/staging/development separation is via
environment; the service fails safely (503, no crash, no fallback to unsafe
behavior) when required configuration is absent.

## Running

```bash
cd backend/ai-gateway
pip install -r requirements.txt
uvicorn app.main:app --port 8080
```

## Tests

```bash
cd backend/ai-gateway
python -m pytest tests/ -v
```

## Known gaps (Phase 0 by design)

- Session tokens are a configuration stand-in; real OAuth/OIDC identity
  provider integration is a later phase (⚠ requires vendor contract).
- No real model-provider calls are made; the Model Gateway returns a
  structured "provider unavailable" response unless a provider is fully
  configured, and even then only a stub completion is used in Phase 0.
- Persistence is in-memory/JSONL; PostgreSQL migrations for audit and
  security events come with the production deployment phase.
- No consequential tools, no banking/tax/investment/identity integrations
  (⚠ all require vendor contracts).
- The iOS client is not yet wired to this API (later phase; the client
  currently contains no AI credentials or provider calls).
