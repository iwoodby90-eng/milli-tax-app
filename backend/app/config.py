"""Runtime configuration.

Secrets are environment-only. Production financial endpoints fail closed when
identity, database, or provider configuration is unavailable.
"""

from functools import lru_cache
from typing import Literal, Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: Literal["sandbox", "production"] = "sandbox"

    database_url: Optional[str] = None

    # Plaid: account connectivity and transaction data.
    plaid_client_id: Optional[str] = None
    plaid_secret: Optional[str] = None
    plaid_env: Literal["sandbox", "production"] = "sandbox"
    plaid_webhook_url: Optional[str] = None
    plaid_redirect_uri: Optional[str] = None

    # Column: banking / ACH money movement. The API key is server-only.
    column_api_key: Optional[str] = None
    column_env: Literal["sandbox", "production"] = "sandbox"
    column_base_url: str = "https://api.column.com"

    # Sign in with Apple. For the native app this is normally the App ID /
    # bundle identifier. It is intentionally required rather than guessed.
    apple_sign_in_audience: Optional[str] = None

    # Opaque server sessions. Access tokens are deliberately short lived and
    # refresh tokens rotate whenever they are used.
    auth_access_ttl_minutes: int = 15
    auth_refresh_ttl_days: int = 30
    auth_challenge_ttl_minutes: int = 10

    @property
    def plaid_configured(self) -> bool:
        return bool(self.plaid_client_id and self.plaid_secret)

    @property
    def db_configured(self) -> bool:
        return bool(self.database_url)

    @property
    def apple_auth_configured(self) -> bool:
        return bool(self.apple_sign_in_audience)

    @property
    def column_configured(self) -> bool:
        if not self.column_api_key or not self.column_base_url.startswith("https://"):
            return False
        expected_prefix = "live_" if self.column_env == "production" else "test_"
        return self.column_api_key.startswith(expected_prefix)


@lru_cache
def get_settings() -> Settings:
    return Settings()
