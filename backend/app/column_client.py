"""Fail-closed Column API client for Milli's server-side money rail.

The iOS app never receives Column credentials and never calls Column directly.
Sensitive external-account numbers exist only transiently in backend memory.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx

from .config import get_settings


class ColumnUnavailable(RuntimeError):
    pass


class ColumnRequestFailed(RuntimeError):
    pass


@dataclass(frozen=True)
class ColumnClient:
    base_url: str
    api_key: str

    @classmethod
    def configured(cls) -> "ColumnClient":
        settings = get_settings()
        if not settings.column_configured:
            raise ColumnUnavailable("Column is not configured")
        return cls(
            base_url=settings.column_base_url.rstrip("/"),
            api_key=settings.column_api_key or "",
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        data: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> dict[str, Any]:
        headers = {"Accept": "application/json"}
        if idempotency_key:
            headers["Idempotency-Key"] = idempotency_key

        try:
            response = httpx.request(
                method,
                f"{self.base_url}{path}",
                data=data,
                headers=headers,
                auth=("", self.api_key),
                timeout=20.0,
                follow_redirects=False,
            )
        except httpx.HTTPError as exc:
            raise ColumnRequestFailed("Column network request failed") from exc

        if response.status_code < 200 or response.status_code >= 300:
            # Never reflect provider response bodies. They may contain sensitive
            # financial or compliance information.
            raise ColumnRequestFailed(
                f"Column request failed with HTTP {response.status_code}"
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise ColumnRequestFailed("Column returned invalid JSON") from exc

        if not isinstance(payload, dict):
            raise ColumnRequestFailed("Column returned an unexpected response shape")
        return payload

    def create_bank_account(
        self,
        *,
        entity_id: str,
        description: str,
        idempotency_key: str,
    ) -> dict[str, Any]:
        return self._request(
            "POST",
            "/bank-accounts",
            data={"entity_id": entity_id, "description": description},
            idempotency_key=idempotency_key,
        )

    def get_bank_account(self, bank_account_id: str) -> dict[str, Any]:
        return self._request("GET", f"/bank-accounts/{bank_account_id}")

    def create_counterparty(
        self,
        *,
        account_number: str,
        routing_number: str,
        account_type: str,
        name: str | None,
        description: str,
    ) -> dict[str, Any]:
        data: dict[str, Any] = {
            "account_number": account_number,
            "routing_number": routing_number,
            "account_type": account_type,
            "description": description,
        }
        if name:
            data["name"] = name
        return self._request("POST", "/counterparties", data=data)

    def get_counterparty(self, counterparty_id: str) -> dict[str, Any]:
        return self._request("GET", f"/counterparties/{counterparty_id}")

    def create_ach_transfer(
        self,
        *,
        bank_account_id: str,
        counterparty_id: str,
        transfer_type: str,
        amount_cents: int,
        description: str,
        entry_class_code: str,
        idempotency_key: str,
    ) -> dict[str, Any]:
        return self._request(
            "POST",
            "/transfers/ach",
            data={
                "bank_account_id": bank_account_id,
                "counterparty_id": counterparty_id,
                "type": transfer_type,
                "amount": amount_cents,
                "currency_code": "USD",
                "description": description,
                "entry_class_code": entry_class_code,
            },
            idempotency_key=idempotency_key,
        )

    def get_ach_transfer(self, ach_transfer_id: str) -> dict[str, Any]:
        return self._request("GET", f"/transfers/ach/{ach_transfer_id}")
