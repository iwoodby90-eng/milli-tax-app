"""Server-only Unit money-rail client.

The native app never receives the Unit organization API token. Money movement
calls require a stable UUID idempotency key, and ACH debits require a recorded
authorization reference before a provider request may be constructed.
"""

from dataclasses import dataclass
from typing import Literal
from uuid import UUID

import httpx

from .config import get_settings


Direction = Literal["Credit", "Debit"]


@dataclass(frozen=True)
class UnitPaymentResult:
    payment_id: str
    status: str
    amount_cents: int
    direction: str


class UnitConfigurationError(RuntimeError):
    pass


class UnitMoneyMovementError(RuntimeError):
    pass


class UnitClient:
    def __init__(self, *, base_url: str, api_token: str) -> None:
        self._base_url = base_url.rstrip("/")
        self._api_token = api_token

    async def create_ach_payment_to_linked_account(
        self,
        *,
        source_account_id: str,
        linked_account_id: str,
        amount_cents: int,
        direction: Direction,
        description: str,
        idempotency_key: UUID,
        debit_authorization_id: UUID | None = None,
    ) -> UnitPaymentResult:
        if amount_cents <= 0:
            raise ValueError("amount_cents must be positive")
        if direction == "Debit" and debit_authorization_id is None:
            raise ValueError("ACH debit requires a recorded authorization")
        if not source_account_id.strip() or not linked_account_id.strip():
            raise ValueError("source and linked account ids are required")

        normalized_description = description.strip()
        if not normalized_description or len(normalized_description) > 10:
            raise ValueError("Unit ACH description must be 1-10 characters")

        tags = {"milliIdempotencyKey": str(idempotency_key)}
        if debit_authorization_id is not None:
            tags["milliDebitAuthorizationId"] = str(debit_authorization_id)

        payload = {
            "data": {
                "type": "achPayment",
                "attributes": {
                    "amount": amount_cents,
                    "direction": direction,
                    "description": normalized_description,
                    "idempotencyKey": str(idempotency_key),
                    "tags": tags,
                },
                "relationships": {
                    "account": {
                        "data": {"type": "account", "id": source_account_id}
                    },
                    "linkedAccount": {
                        "data": {"type": "linkedAccount", "id": linked_account_id}
                    },
                },
            }
        }

        headers = {
            "Authorization": f"Bearer {self._api_token}",
            "Content-Type": "application/vnd.api+json",
            "Accept": "application/vnd.api+json",
        }
        timeout = httpx.Timeout(5.0, connect=5.0)

        async with httpx.AsyncClient(
            base_url=self._base_url,
            headers=headers,
            timeout=timeout,
            follow_redirects=False,
        ) as client:
            response = await client.post("/payments", json=payload)

        try:
            response.raise_for_status()
            document = response.json()
            data = document["data"]
            attributes = data["attributes"]
            payment_id = str(data["id"])
            status_value = str(attributes["status"])
            amount_value = int(attributes["amount"])
            direction_value = str(attributes["direction"])
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as exc:
            raise UnitMoneyMovementError("Unit payment request failed or returned an invalid payload") from exc

        return UnitPaymentResult(
            payment_id=payment_id,
            status=status_value,
            amount_cents=amount_value,
            direction=direction_value,
        )


def get_unit_client() -> UnitClient | None:
    settings = get_settings()
    if not settings.unit_api_token or not settings.unit_base_url:
        return None
    return UnitClient(
        base_url=settings.unit_base_url,
        api_token=settings.unit_api_token,
    )
