"""Contract tests for the edge protections applied to every request."""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient  # noqa: E402

from app.main import MAX_REQUEST_BYTES, app  # noqa: E402

client = TestClient(app)


def test_payout_source_routes_are_mounted():
    paths = {route.path for route in app.routes}
    assert "/plaid/payout-source" in paths


def test_payout_source_requires_a_server_session():
    assert client.get("/plaid/payout-source").status_code in (401, 503)
    assert client.put(
        "/plaid/payout-source", json={"account_id": "acc-1"}
    ).status_code in (401, 503)


def test_oversized_body_is_rejected_before_routing():
    response = client.post(
        "/auth/refresh",
        content=b"x" * (MAX_REQUEST_BYTES + 1),
        headers={"Content-Type": "application/json"},
    )
    assert response.status_code == 413
    assert response.headers["cache-control"] == "no-store"


def test_unauthenticated_auth_endpoint_is_rate_limited():
    body = {"refresh_token": "x" * 64}
    statuses = {client.post("/auth/refresh", json=body).status_code for _ in range(40)}
    assert 429 in statuses


def test_authenticated_routes_are_not_rate_limited_by_the_anonymous_window():
    for _ in range(40):
        response = client.get("/tax-vault/balance")
    assert response.status_code != 429
