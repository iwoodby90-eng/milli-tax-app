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

    # Plaid
    plaid_client_id: Optional[str] = None
    plaid_secret: Optional[str] = None
    plaid_env: Literal["sandbox", "production"] = "sandbox"
    plaid_webhook_url: Optional[str] = None
    plaid_redirect_uri: Optional[str] = None

    # Unit BaaS. The organization token remains server-only. The base URL is
    # explicit so sandbox/production cannot be selected accidentally.
    unit_api_token: Optional[str] = None
    unit_base_url: Optional[str] = None
    unit_webhook_secret: Optional[str] = None

    # Sign in with Apple. For the native app this is normally the App ID /
    # bundle identifier. It is intentionally required rather than guessed.
    apple_sign_in_audience: Optional[str] = None

    # Opaque server sessions. Access tokens are deliberately short lived and
    # refresh tokens rotate whenever they are used.
    auth_access_ttl_minutes: int = 15
    auth_refresh_ttl_days: int = 30
    auth_challenge_ttl_minutes: int = 10

    # Legacy client key is retained only so stale Render configuration can be
    # identified and removed. It is never accepted as user authentication.
    client_api_key: Optional[str] = None

    @property
    def plaid_configured(self) -> bool:
        return bool(self.plaid_client_id and self.plaid_secret)

    @property
    def db_configured(self) -> bool:
        return bool(self.database_url)

    @property
    def unit_configured(self) -> bool:
        return bool(self.unit_api_token and self.unit_base_url and self.unit_webhook_secret)

    @property
    def apple_auth_configured(self) -> bool:
        return bool(self.apple_sign_in_audience)


@lru_cache
def get_settings() -> Settings:
    return Settings()
