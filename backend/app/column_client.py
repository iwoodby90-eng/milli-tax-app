"""Column BaaS API client.

Thin wrapper around the Column REST API. All money is in signed cents.
The client never stores or logs full PANs, account numbers, or card
numbers. Only Column's object IDs and last-four are persisted.
"""

import logging
from typing import Any, Optional

import httpx

from .config import get_settings

logger = logging.getLogger(__name__)


class ColumnClient:
    """HTTP client for the Column BaaS API."""

    def __init__(self):
        settings = get_settings()
        self._base_url = settings.column_base_url
        self._api_key = settings.column_api_key
        self._headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }

    def _url(self, path: str) -> str:
        return f"{self._base_url}{path}"

    # --- Accounts ---

    def create_account(
        self,
        user_id: str,
        account_type: str,
        customer_id: str,
    ) -> dict[str, Any]:
        """Create a deposit account at Column.

        Returns the Column account object (id, routing_number, etc.).
        """
        # Column uses "entities" for customers. The customer_id is the
        # Column entity ID created during KYC/onboarding.
        payload = {
            "entity_id": customer_id,
            "type": "checking" if account_type == "checking" else "savings",
            "name": f"MILLI {account_type.replace('_', ' ').title()}",
        }
        resp = httpx.post(
            self._url("/accounts"),
            json=payload,
            headers=self._headers,
            timeout=30.0,
        )
        resp.raise_for_status()
        return resp.json()

    def get_account(self, column_account_id: str) -> dict[str, Any]:
        """Retrieve account details including balances from Column."""
        resp = httpx.get(
            self._url(f"/accounts/{column_account_id}"),
            headers=self._headers,
            timeout=15.0,
        )
        resp.raise_for_status()
        return resp.json()

    def list_transfers(self, column_account_id: str, limit: int = 50) -> list[dict[str, Any]]:
        """List recent transfers for an account."""
        resp = httpx.get(
            self._url("/transfers"),
            params={"account_id": column_account_id, "limit": limit},
            headers=self._headers,
            timeout=15.0,
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("data", data) if isinstance(data, dict) else data

    # --- Transfers ---

    def create_ach_transfer(
        self,
        from_account_id: str,
        to_routing_number: str,
        to_account_number: str,
        amount_cents: int,
        direction: str = "outbound",
        description: Optional[str] = None,
    ) -> dict[str, Any]:
        """Create an ACH transfer. Amount in cents.

        For outbound: pulls from the MILLI account to an external account.
        For inbound: pushes from an external account to the MILLI account
        (requires the external account to be linked at Column first).
        """
        amount_str = f"{amount_cents / 100:.2f}"
        payload: dict[str, Any] = {
            "amount": amount_str,
            "currency": "USD",
            "description": description or "MILLI transfer",
        }
        if direction == "outbound":
            payload["from_account_id"] = from_account_id
            payload["to"] = {
                "routing_number": to_routing_number,
                "account_number": to_account_number,
            }
            endpoint = "/transfers/ach"
        else:
            payload["to_account_id"] = from_account_id
            payload["from"] = {
                "routing_number": to_routing_number,
                "account_number": to_account_number,
            }
            endpoint = "/transfers/ach"

        resp = httpx.post(
            self._url(endpoint),
            json=payload,
            headers=self._headers,
            timeout=30.0,
        )
        resp.raise_for_status()
        return resp.json()

    # --- Cards ---

    def create_card(
        self,
        column_account_id: str,
        card_type: str = "virtual",
    ) -> dict[str, Any]:
        """Issue a debit card on the Column account.

        Returns the Column card object. The full PAN is never stored
        locally; only the card ID and last four are persisted.
        """
        payload = {
            "account_id": column_account_id,
            "type": card_type,
            "status": "active",
        }
        resp = httpx.post(
            self._url("/cards"),
            json=payload,
            headers=self._headers,
            timeout=30.0,
        )
        resp.raise_for_status()
        return resp.json()

    def freeze_card(self, column_card_id: str) -> dict[str, Any]:
        resp = httpx.post(
            self._url(f"/cards/{column_card_id}/freeze"),
            headers=self._headers,
            timeout=15.0,
        )
        resp.raise_for_status()
        return resp.json()

    def unfreeze_card(self, column_card_id: str) -> dict[str, Any]:
        resp = httpx.post(
            self._url(f"/cards/{column_card_id}/unfreeze"),
            headers=self._headers,
            timeout=15.0,
        )
        resp.raise_for_status()
        return resp.json()

    # --- Webhooks ---

    def verify_webhook_signature(self, signature: str, body: bytes) -> bool:
        """Verify the Column webhook signature.

        Column signs webhooks with the webhook secret. This is a
        placeholder for the actual verification logic, which depends
        on Column's webhook signing scheme.
        """
        import hmac
        import hashlib

        settings = get_settings()
        secret = settings.column_webhook_secret
        if not secret:
            return False

        expected = hmac.new(
            secret.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(signature, expected)