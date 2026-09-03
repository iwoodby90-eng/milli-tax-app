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

    @property
    def plaid_configured(self) -> bool:
        return bool(self.plaid_client_id and self.plaid_secret)

    @property
    def db_configured(self) -> bool:
        return bool(self.database_url)


@lru_cache
def get_settings() -> Settings:
    return Settings()
