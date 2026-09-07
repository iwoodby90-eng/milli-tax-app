"""Runtime configuration. Production security fails closed."""
from functools import lru_cache
from typing import Literal, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    environment: Literal["sandbox", "production"] = "sandbox"
    database_url: Optional[str] = None

    apple_client_id: Optional[str] = None
    auth_jwt_secret: Optional[str] = None
    auth_access_token_minutes: int = 15
    auth_refresh_token_days: int = 30
    auth_issuer: str = "milli-tax-vault-api"
    auth_audience: str = "milli-ios"
    provider_token_encryption_key: Optional[str] = None

    plaid_client_id: Optional[str] = None
    plaid_secret: Optional[str] = None
    plaid_env: Literal["sandbox", "production"] = "sandbox"
    plaid_webhook_url: Optional[str] = None
    plaid_redirect_uri: Optional[str] = None

    # Optional app-client anti-abuse signal only; never user identity.
    client_api_key: Optional[str] = None

    @property
    def plaid_configured(self): return bool(self.plaid_client_id and self.plaid_secret)

    @property
    def db_configured(self): return bool(self.database_url)

    @property
    def auth_configured(self):
        return bool(self.database_url and self.apple_client_id and self.auth_jwt_secret)

    def assert_production_security(self):
        if self.environment != "production":
            return
        missing = []
        if not self.database_url: missing.append("DATABASE_URL")
        if not self.apple_client_id: missing.append("APPLE_CLIENT_ID")
        if not self.auth_jwt_secret or len(self.auth_jwt_secret) < 32:
            missing.append("AUTH_JWT_SECRET(>=32 chars)")
        if not self.provider_token_encryption_key:
            missing.append("PROVIDER_TOKEN_ENCRYPTION_KEY")
        if missing:
            raise RuntimeError("production security configuration missing: " + ", ".join(missing))

@lru_cache
def get_settings():
    settings = Settings()
    settings.assert_production_security()
    return settings
