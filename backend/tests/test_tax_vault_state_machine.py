"""Tests for issue #103: tax_vault.py state machine bypass.

These tests prove that:
1. A client CANNOT POST status=settled directly to /entries (422 validation error)
2. A client CAN create entries with status=requested or status=processing
3. The settled state is only reachable through the authoritative /entries/{id}/status endpoint

These are contract tests that don't need a database — they validate the Pydantic
model's pattern constraint, which is the first line of defense.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pytest
from pydantic import ValidationError

# Import the model directly — we don't need the full app or database
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.routers.tax_vault import LedgerEntryIn, SettleRequest


class TestLedgerEntryInStatusPattern:
    """Issue #103: LedgerEntryIn.status must NOT accept 'settled'."""

    def test_requested_is_accepted(self):
        """status=requested is the default and must be accepted."""
        entry = LedgerEntryIn(entry_type="reserve", amount_cents=5000)
        assert entry.status == "requested"

    def test_processing_is_accepted(self):
        """status=processing is a valid initial state."""
        entry = LedgerEntryIn(
            entry_type="reserve", amount_cents=5000, status="processing"
        )
        assert entry.status == "processing"

    def test_settled_is_rejected(self):
        """status=settled must be REJECTED on entry creation.

        This is the core fix for issue #103: a client must not be able to
        fabricate settled reserve funds by POSTing status=settled directly.
        The settled state is only reachable through the authoritative
        update_status state machine endpoint.
        """
        with pytest.raises(ValidationError) as exc_info:
            LedgerEntryIn(
                entry_type="reserve", amount_cents=5000, status="settled"
            )
        # Pydantic v2 raises ValidationError with details about the pattern mismatch
        assert "settled" in str(exc_info.value) or "pattern" in str(exc_info.value).lower()

    def test_failed_is_rejected(self):
        """status=failed must also be rejected on creation."""
        with pytest.raises(ValidationError):
            LedgerEntryIn(
                entry_type="reserve", amount_cents=5000, status="failed"
            )

    def test_reversed_is_rejected(self):
        """status=reversed must also be rejected on creation."""
        with pytest.raises(ValidationError):
            LedgerEntryIn(
                entry_type="reserve", amount_cents=5000, status="reversed"
            )

    def test_arbitrary_status_is_rejected(self):
        """Any arbitrary string must be rejected."""
        with pytest.raises(ValidationError):
            LedgerEntryIn(
                entry_type="reserve", amount_cents=5000, status="hacked"
            )

    def test_empty_status_is_rejected(self):
        """Empty string must be rejected (defaults to 'requested' only if omitted)."""
        with pytest.raises(ValidationError):
            LedgerEntryIn(entry_type="reserve", amount_cents=5000, status="")

    def test_omitted_status_defaults_to_requested(self):
        """When status is omitted entirely, it must default to 'requested'."""
        entry = LedgerEntryIn(entry_type="reserve", amount_cents=5000)
        assert entry.status == "requested"


class TestSettleRequestStatusPattern:
    """The update_status endpoint correctly accepts settled/failed/reversed.

    These states are only reachable through the authoritative state machine.
    """

    def test_settled_is_accepted_on_transition(self):
        """status=settled IS valid when going through the state machine."""
        req = SettleRequest(status="settled")
        assert req.status == "settled"

    def test_processing_is_accepted_on_transition(self):
        req = SettleRequest(status="processing")
        assert req.status == "processing"

    def test_failed_is_accepted_on_transition(self):
        req = SettleRequest(status="failed")
        assert req.status == "failed"

    def test_reversed_is_accepted_on_transition(self):
        req = SettleRequest(status="reversed")
        assert req.status == "reversed"

    def test_requested_is_rejected_on_transition(self):
        """requested is not a valid transition target — entries start as requested."""
        with pytest.raises(ValidationError):
            SettleRequest(status="requested")

    def test_arbitrary_status_is_rejected_on_transition(self):
        with pytest.raises(ValidationError):
            SettleRequest(status="hacked")


class TestEntryTypeValidation:
    """Ensure entry_type validation still works alongside the status fix."""

    def test_valid_entry_types(self):
        for entry_type in ("reserve", "withdrawal", "adjustment", "interest"):
            entry = LedgerEntryIn(entry_type=entry_type, amount_cents=100)
            assert entry.entry_type == entry_type

    def test_invalid_entry_type_is_rejected(self):
        with pytest.raises(ValidationError):
            LedgerEntryIn(entry_type="transfer", amount_cents=100)

    def test_reserve_must_be_positive(self):
        """This validation is in the route handler, not the model.
        The model itself accepts any integer; the handler enforces sign rules.
        We test the model accepts the value; the handler test would need
        the full app with database mocking.
        """
        entry = LedgerEntryIn(entry_type="reserve", amount_cents=-100)
        # Model accepts it; handler rejects it at runtime
        assert entry.amount_cents == -100