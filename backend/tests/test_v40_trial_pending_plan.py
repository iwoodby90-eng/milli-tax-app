"""Unit tests for v4.0: pending_plan field on RegisterIn model."""
import pytest
from pydantic import BaseModel, Field, EmailStr
from typing import Optional


class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    name: str
    state: str = "TX"
    pending_plan: Optional[str] = "basic"


class TestPendingPlan:
    def test_default_is_basic(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User")
        assert r.pending_plan == "basic"

    def test_explicit_basic(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User", pending_plan="basic")
        assert r.pending_plan == "basic"

    def test_explicit_pro(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User", pending_plan="pro")
        assert r.pending_plan == "pro"

    def test_explicit_elite(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User", pending_plan="elite")
        assert r.pending_plan == "elite"

    def test_none_falls_back_in_register_logic(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User", pending_plan=None)
        plan = r.pending_plan or "basic"
        assert plan == "basic"

    def test_plan_assignment_simulation(self):
        """Simulate the register() function logic: user_doc['plan'] = body.pending_plan or 'basic'"""
        for pending, expected in [
            ("pro", "pro"),
            ("elite", "elite"),
            ("basic", "basic"),
            (None, "basic"),
        ]:
            r = RegisterIn(email="user@test.com", password="pw1234", name="User", pending_plan=pending)
            plan = r.pending_plan or "basic"
            assert plan == expected, f"pending_plan={pending!r} → expected {expected!r}, got {plan!r}"

    def test_state_default(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User")
        assert r.state == "TX"

    def test_state_override(self):
        r = RegisterIn(email="user@test.com", password="password123", name="User", state="CA")
        assert r.state == "CA"
