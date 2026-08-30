"""Analytics domain separation (Phase 0 foundation).

Sun's §10: three strictly separated analytics domains. Data never crosses
domains. Financial/business analytics derives exclusively from authoritative
ledger records — it must never accept client-reported balances or transaction
truth.

Phase 0 ships the separated interfaces and the isolation guard; pipelines and
stores arrive in Phase 3.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class AnalyticsDomain(str, Enum):
    PRODUCT = "product"            # Domain 1: client SDK behavioral events, no financial values
    OPERATIONAL = "operational"    # Domain 2: server logs, latency, errors, provider health
    FINANCIAL = "financial"        # Domain 3: authoritative ledger only


# Fields that must never appear in product analytics (no financial values).
_PRODUCT_FORBIDDEN_FIELDS = frozenset({
    "amount", "balance", "transaction", "transaction_amount", "vault_balance",
    "revenue", "payment", "tax_amount",
})


class CrossDomainViolation(Exception):
    """Raised when data would cross an analytics domain boundary."""


class FinancialTruthFromClient(Exception):
    """Raised when financial analytics would accept client-reported truth."""


@dataclass(frozen=True)
class AnalyticsEvent:
    domain: AnalyticsDomain
    event_name: str
    properties: dict
    correlation_id: str | None = None


class ProductAnalytics:
    """Domain 1: behavioral events only. Rejects financial fields."""

    def track(self, event_name: str, properties: dict, correlation_id: str | None = None) -> AnalyticsEvent:
        bad = _PRODUCT_FORBIDDEN_FIELDS.intersection(properties.keys())
        if bad:
            raise CrossDomainViolation(
                f"financial fields forbidden in product analytics: {sorted(bad)}"
            )
        return AnalyticsEvent(AnalyticsDomain.PRODUCT, event_name, dict(properties), correlation_id)


class OperationalAnalytics:
    """Domain 2: system health. May reference request/correlation ids but
    carries no financial values."""

    def track(self, event_name: str, properties: dict, correlation_id: str | None = None) -> AnalyticsEvent:
        bad = _PRODUCT_FORBIDDEN_FIELDS.intersection(properties.keys())
        if bad:
            raise CrossDomainViolation(
                f"financial values forbidden in operational analytics: {sorted(bad)}"
            )
        return AnalyticsEvent(AnalyticsDomain.OPERATIONAL, event_name, dict(properties), correlation_id)


class FinancialAnalytics:
    """Domain 3: authoritative records only.

    Every query must declare an authoritative source (ledger table / domain
    service). Client-reported values are rejected outright.
    """

    AUTHORITATIVE_SOURCES = frozenset({
        "ledger", "ledger.transfers", "ledger.tax_payments", "ledger.vault_deposits",
        "ledger.vault_withdrawals", "user_store.subscriptions", "domain_service",
    })

    def metric(self, metric_name: str, source: str, properties: dict | None = None) -> AnalyticsEvent:
        if source not in self.AUTHORITATIVE_SOURCES:
            raise FinancialTruthFromClient(
                f"financial metric '{metric_name}' must derive from an authoritative "
                f"source; client-reported truth is not accepted (got source: {source!r})"
            )
        return AnalyticsEvent(AnalyticsDomain.FINANCIAL, metric_name, dict(properties or {}))
