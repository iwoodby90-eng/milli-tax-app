"""Security contract for Tax Vault state ownership.

The public mobile API can only create requested ledger movements. No request
payload can claim processing, settled, failed, or reversed status.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from pydantic import ValidationError

from app.routers.tax_vault import LedgerEntryIn


class TestLedgerEntryCreationStatus:
    def test_requested_is_default(self):
        entry = LedgerEntryIn(entry_type="reserve", amount_cents=5000)
        assert entry.status == "requested"

    def test_requested_is_explicitly_accepted(self):
        entry = LedgerEntryIn(entry_type="reserve", amount_cents=5000, status="requested")
        assert entry.status == "requested"

    @pytest.mark.parametrize("forged_status", ["processing", "settled", "failed", "reversed", "hacked", ""])
    def test_non_requested_status_is_rejected(self, forged_status):
        with pytest.raises(ValidationError):
            LedgerEntryIn(
                entry_type="reserve",
                amount_cents=5000,
                status=forged_status,
            )


class TestEntryTypeValidation:
    def test_valid_entry_types(self):
        for entry_type in ("reserve", "withdrawal", "adjustment", "interest"):
            entry = LedgerEntryIn(entry_type=entry_type, amount_cents=100)
            assert entry.entry_type == entry_type

    def test_invalid_entry_type_is_rejected(self):
        with pytest.raises(ValidationError):
            LedgerEntryIn(entry_type="transfer", amount_cents=100)
