"""Runtime configuration.

Every secret is read from the environment. Nothing is hardcoded, and no
credential is ever committed to the repository or shipped in the iOS app.
"""

from functools import lru_cache
from typing import Literal, Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: Literal["sandbox", "production"] = "sandbox"

    # Postgres. When absent, data endpoints answer 503 UNAVAILABLE rather than
    # inventing a balance (MILLI data-truth rule).
    database_url: Optional[str] = None

    # Plaid
    plaid_client_id: Optional[str] = None
    plaid_secret: Optional[str] = None
    plaid_env: Literal["sandbox", "production"] = "sandbox"
    plaid_webhook_url: Optional[str] = None
    plaid_redirect_uri: Optional[str] = None

    # Shared secret the iOS client sends as X-Milli-Client-Key.
    client_api_key: Optional[str] = None

    # Column BaaS
    column_api_key: Optional[str] = None
    column_base_url: str = "https://api.column.com"
    column_webhook_secret: Optional[str] = None

    # Apple IAP (App Store Server API)
    apple_iap_bundle_id: Optional[str] = None
    apple_iap_environment: Literal["sandbox", "production"] = "sandbox"
    apple_iap_issuer_id: Optional[str] = None
    apple_iap_key_id: Optional[str] = None
    apple_iap_private_key: Optional[str] = None  # PEM-encoded, from environment

    # Apple Identity (Verify with Wallet API)
    apple_identity_merchant_id: Optional[str] = None
    apple_identity_private_key: Optional[str] = None  # PEM-encoded

    # Audit log retention (days)
    audit_retention_days: int = 365

    # Rate limiting (requests per minute per user)
    rate_limit_per_minute: int = 60

    @property
    def plaid_configured(self) -> bool:
        return bool(self.plaid_client_id and self.plaid_secret)

    @property
    def db_configured(self) -> bool:
        return bool(self.database_url)

    @property
    def column_configured(self) -> bool:
        return bool(self.column_api_key)

    @property
    def apple_iap_configured(self) -> bool:
        return bool(
            self.apple_iap_bundle_id
            and self.apple_iap_issuer_id
            and self.apple_iap_key_id
            and self.apple_iap_private_key
        )

    @property
    def apple_identity_configured(self) -> bool:
        return bool(
            self.apple_identity_merchant_id and self.apple_identity_private_key
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()