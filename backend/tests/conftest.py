import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest  # noqa: E402

from app.main import _rate_limiter  # noqa: E402


@pytest.fixture(autouse=True)
def isolate_rate_limiter():
    """Anonymous-endpoint throttling must not leak between tests."""
    _rate_limiter.reset()
    yield
    _rate_limiter.reset()
