"""Model Gateway: provider abstraction with server-side-only credentials.

Phase 0 rules:
- Provider credentials are read from environment variables only. They are
  never hard-coded, never logged, never returned to clients.
- If the provider is not fully configured, the gateway FAILS SAFE: it
  returns a structured "provider unavailable" outcome. It never falls back
  to an unsafe path (e.g., calling without credentials).
- No real provider HTTP calls are made in Phase 0; `complete()` returns a
  stub completion so the pipeline can be exercised end-to-end. Real
  inference requires a vendor contract (⚠) and lands in a later phase.
- Prompt versioning: the server-side system prompt version is recorded in
  every audit envelope.
"""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class ModelCallResult:
    ok: bool
    provider: str
    model: str
    prompt_version: str
    completion_text: str
    error_type: str | None = None
    latency_ms: int = 0


class ModelGateway:
    """Server-side provider gateway (single provider in Phase 0)."""

    def __init__(
        self,
        provider: str | None = None,
        api_key: str | None = None,
        model: str | None = None,
        prompt_version: str | None = None,
    ) -> None:
        self._provider = provider if provider is not None else os.environ.get("MILLI_MODEL_PROVIDER")
        self._api_key = api_key if api_key is not None else os.environ.get("MILLI_MODEL_API_KEY")
        self._model = model if model is not None else os.environ.get("MILLI_MODEL_NAME", "")
        self._prompt_version = (
            prompt_version if prompt_version is not None else os.environ.get("MILLI_SYSTEM_PROMPT_VERSION", "unversioned")
        )

    @property
    def prompt_version(self) -> str:
        return self._prompt_version

    @property
    def provider(self) -> str | None:
        return self._provider

    def is_configured(self) -> bool:
        """A provider is usable only when name AND credential are present."""
        return bool(self._provider) and bool(self._api_key)

    def complete(self, minimized_context: str) -> ModelCallResult:
        """Execute a model call over already-minimized context.

        Fails safe: unconfigured provider -> ok=False with a structured
        error, never an exception, never a credential leak.
        """
        if not self.is_configured():
            return ModelCallResult(
                ok=False,
                provider=self._provider or "none",
                model="",
                prompt_version=self._prompt_version,
                completion_text="",
                error_type="provider_unavailable",
            )
        # Phase 0 stub completion. Real provider HTTP calls (with server-side
        # credential injection, response validation, fallback) come in a
        # later phase once the AI vendor contract is in place.
        return ModelCallResult(
            ok=True,
            provider=self._provider or "none",
            model=self._model,
            prompt_version=self._prompt_version,
            completion_text="[milli-ai phase-0 stub completion]",
        )
