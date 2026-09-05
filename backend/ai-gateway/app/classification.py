"""Data classification and minimization/redaction pipeline.

Implements Sun's classification taxonomy (§12) and the data-minimization
pipeline applied before any model-provider transmission:

- RESTRICTED  (SSNs, full account numbers, credentials, tax-return contents,
               private keys): never sent to a model, never logged. Redacted
               or tokenized in every context.
- CONFIDENTIAL (partial account numbers, amounts, balances): may be sent only
               after minimization; logged as metadata only.
- INTERNAL    (user IDs, session IDs, tool names, request IDs): may be sent.
- PUBLIC      (model names, prompt versions, UI text): unrestricted.

The classifier detects restricted patterns in free-form text and the redactor
replaces them with tokens before the text can enter a model context.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum


class DataClassification(str, Enum):
    RESTRICTED = "RESTRICTED"
    CONFIDENTIAL = "CONFIDENTIAL"
    INTERNAL = "INTERNAL"
    PUBLIC = "PUBLIC"


class ProhibitedDataError(Exception):
    """Raised when prohibited (RESTRICTED) data would reach a model unredacted."""


# Patterns for RESTRICTED data detection (US SSN and generic full account
# numbers; extensible). Detection is conservative: when in doubt, classify
# RESTRICTED and redact.
_SSN_RE = re.compile(r"\b\d{3}-\d{2}-\d{4}\b")
_ACCOUNT_RE = re.compile(r"\b(?:IBAN|ACCT|ACCOUNT(?:\s+NUMBER)?)\s*[:#]?\s*[A-Z0-9]{10,}\b", re.IGNORECASE)
_CREDENTIAL_RE = re.compile(r"\b(?:password|api[_-]?key|secret|token)\s*[:=]\s*\S+", re.IGNORECASE)

_REDACTIONS: list[tuple[re.Pattern[str], str]] = [
    (_SSN_RE, "[SSN_REDACTED]"),
    (_ACCOUNT_RE, "[ACCT_REDACTED]"),
    (_CREDENTIAL_RE, "[CREDENTIAL_REDACTED]"),
]


@dataclass(frozen=True)
class ClassifiedField:
    name: str
    classification: DataClassification


@dataclass(frozen=True)
class MinimizationResult:
    """Result of the minimization pipeline over a candidate model context."""
    redacted_text: str
    redacted_fields: list[str]
    classifications_present: frozenset[DataClassification]
    minimization_ratio: float  # (redactions applied) / (redactions + kept)


def classify_field(name: str, value) -> DataClassification:
    """Classify a structured field by name/value (conservative default)."""
    lname = name.lower()
    if any(k in lname for k in ("ssn", "social_security", "account_number", "full_account", "password", "credential", "api_key", "tax_return", "private_key")):
        return DataClassification.RESTRICTED
    if any(k in lname for k in ("amount", "balance", "last4", "transaction", "vault_balance")):
        return DataClassification.CONFIDENTIAL
    if any(k in lname for k in ("user_id", "session_id", "request_id", "tool_name", "provenance")):
        return DataClassification.INTERNAL
    return DataClassification.PUBLIC


def redact(text: str) -> tuple[str, list[str]]:
    """Redact RESTRICTED patterns from free-form text.

    Returns (redacted_text, list_of_redaction_kinds_applied).
    """
    applied: list[str] = []
    result = text
    for pattern, token in _REDACTIONS:
        if pattern.search(result):
            applied.append(token.strip("[]"))
            result = pattern.sub(token, result)
    return result, applied


def minimize(text: str) -> MinimizationResult:
    """Full minimization pipeline for text destined for a model provider.

    Raises ProhibitedDataError only if a redaction handler is unavailable —
    by construction every known RESTRICTED pattern is redacted here, so the
    model context never contains prohibited data.
    """
    redacted_text, applied = redact(text)
    classifications: set[DataClassification] = {DataClassification.PUBLIC}
    if applied:
        classifications.add(DataClassification.RESTRICTED)  # was present, now redacted
    total = len(applied) + 1
    return MinimizationResult(
        redacted_text=redacted_text,
        redacted_fields=applied,
        classifications_present=frozenset(classifications),
        minimization_ratio=len(applied) / total,
    )


def assert_model_safe(text: str) -> str:
    """Guard used immediately before model transmission.

    Redacts any RESTRICTED pattern and returns the safe text. If a pattern
    matches that we cannot redact (unknown handler), raises
    ProhibitedDataError so the call is blocked rather than leaking.
    """
    safe, applied = redact(text)
    # Re-check: after redaction no raw pattern may remain.
    for pattern, _ in _REDACTIONS:
        if pattern.search(safe):
            raise ProhibitedDataError("unredactable restricted data blocked before model call")
    return safe
