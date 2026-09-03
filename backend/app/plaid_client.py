"""Plaid client factory.

Returns None when credentials are absent so the API can answer 503 with a
truthful "bank connection unavailable" instead of pretending to work.
"""

from typing import Optional

import plaid
from plaid.api import plaid_api

from .config import get_settings

_HOSTS = {
    "sandbox": plaid.Environment.Sandbox,
    "production": plaid.Environment.Production,
}


def get_client() -> Optional[plaid_api.PlaidApi]:
    settings = get_settings()
    if not settings.plaid_configured:
        return None
    configuration = plaid.Configuration(
        host=_HOSTS[settings.plaid_env],
        api_key={
            "clientId": settings.plaid_client_id,
            "secret": settings.plaid_secret,
        },
    )
    return plaid_api.PlaidApi(plaid.ApiClient(configuration))
