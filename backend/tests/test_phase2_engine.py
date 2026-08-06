"""
Comprehensive Phase 2 tests for the Milli financial engine.

Covers:
    • Tax Engine (pure math): SE, federal, state, QBI, quarterly plan, mileage
    • Autopilot Engine: full 9-step pipeline, immutable receipts, feature gating
    • Dashboard snapshot: Available to Spend, Tax Ready Score, balance sync
    • Trip classification + mileage summary
    • Milli AI insights
    • Notifications
    • Plan / feature gating (retirement + investing locked on basic/core)

Run with: pytest /app/backend/tests/test_phase2_engine.py -v
"""
import os
import sys
import pytest
import asyncio
from datetime import date, datetime, timezone

sys.path.insert(0, "/app/backend")

from tax_engine import (
    TaxProfile, calc_se_tax, calc_federal_income_tax, calc_total_tax,
    calc_qbi_deduction, calc_additional_medicare, state_rate,
    quarterly_plan, mileage_deduction, per_payout_reserve_rate,
    profile_from_user, SE_TAX_RATE, IRS_MILEAGE_RATE_BUSINESS,
)


# ============================================================
# Tax Engine — pure functions, no DB needed
# ============================================================

class TestTaxEngine:

    def test_se_tax_zero_when_no_income(self):
        se, half = calc_se_tax(0, TaxProfile())
        assert se == 0.0 and half == 0.0

    def test_se_tax_at_typical_gig_income(self):
        se, half = calc_se_tax(40_000, TaxProfile())
        assert 5_000 < se < 6_500       # ~15.3% × 92.35% × 40k ≈ 5,652
        assert abs(half - se / 2) < 0.01

    def test_se_tax_caps_ss_at_wage_base(self):
        # Above SS wage base ($176,100 in 2025), SS portion caps.
        se_low, _ = calc_se_tax(100_000, TaxProfile())
        se_high, _ = calc_se_tax(300_000, TaxProfile())
        # Ratio should be well below 3x due to SS cap.
        assert se_high / se_low < 3

    def test_federal_marginal_brackets_single(self):
        # Taxable $50,000 single: first 11,600 @ 10% = 1,160
        # + next 35,550 @ 12% = 4,266 = 5,426, plus 2,850 @ 22% = 627 = 6,053
        tax = calc_federal_income_tax(50_000, "single")
        assert 5_800 < tax < 6_100

    def test_federal_income_tax_married_joint_wider_brackets(self):
        tax_single = calc_federal_income_tax(80_000, "single")
        tax_joint = calc_federal_income_tax(80_000, "married_joint")
        # Married Joint pays less at the same income due to wider brackets.
        assert tax_joint < tax_single

    def test_state_rate_no_income_tax_states(self):
        for st in ("TX", "FL", "WA", "NV", "TN", "AK", "SD", "WY", "NH"):
            assert state_rate(st) == 0.0

    def test_state_rate_progressive_states(self):
        assert state_rate("CA") > 0.07
        assert state_rate("NY") > 0.05
        assert state_rate("OR") > 0.07

    def test_state_rate_unknown_state_falls_back(self):
        assert state_rate("XX") == 0.05  # DEFAULT_STATE_RATE

    def test_qbi_deduction_applies_to_sole_prop(self):
        profile = TaxProfile(business_type="sole_prop", take_qbi=True)
        qbi = calc_qbi_deduction(50_000, 3_500, profile)
        assert qbi > 0
        # 20% of (50,000 − 3,500) = 9,300
        assert 9_000 < qbi < 9_500

    def test_qbi_zero_when_disabled(self):
        profile = TaxProfile(take_qbi=False)
        assert calc_qbi_deduction(50_000, 3_500, profile) == 0.0

    def test_additional_medicare_kicks_in_at_threshold(self):
        # Single filer, $250k SE income — will exceed $200k threshold.
        profile = TaxProfile(filing_status="single")
        addl = calc_additional_medicare(250_000, profile)
        assert addl > 0
        # calc_additional_medicare applies NET_EARNINGS_FACTOR (0.9235)
        # to the input before comparing to the threshold.
        # Expected: (250_000 * 0.9235 - 200_000) * 0.009 = 277.88
        assert addl == pytest.approx(
            (250_000 * 0.9235 - 200_000) * 0.009, abs=1.0)

    def test_calc_total_tax_low_income_no_tax_state(self):
        profile = TaxProfile(home_state="TX")
        result = calc_total_tax(20_000, 3_000, profile)
        # SE tax always applies
        assert result.se_tax > 0
        # State tax is zero in TX
        assert result.state_income_tax == 0.0
        # Effective rate is reasonable (< 25%)
        assert result.effective_rate < 0.25

    def test_calc_total_tax_high_income_high_tax_state(self):
        profile = TaxProfile(home_state="CA")
        result = calc_total_tax(300_000, 20_000, profile)
        # All three tax types apply
        assert result.se_tax > 0
        assert result.federal_income_tax > 0
        assert result.state_income_tax > 0
        # Additional Medicare kicks in above $200k for single filers
        # ($280k net × 0.9235 factor = $258,580, well above threshold)
        assert result.additional_medicare_tax > 0

    def test_per_payout_rate_cold_start(self):
        profile = TaxProfile(home_state="CA")
        rate = per_payout_reserve_rate(profile)
        assert rate["source"] == "cold_start"
        assert 0 < rate["total"] < 0.5

    def test_per_payout_rate_projected(self):
        profile = TaxProfile(home_state="CA")
        rate = per_payout_reserve_rate(profile, 60_000, 8_000)
        assert rate["source"] == "projected_annual"
        assert 0 < rate["total"] < 0.45

    def test_quarterly_plan_produces_four_quarters(self):
        profile = TaxProfile(home_state="TX")
        plan = quarterly_plan(2026, profile, 30_000, 4_500, [],
                              today=date(2026, 5, 1))
        assert len(plan.quarters) == 4
        assert plan.annual_estimated_tax > 0
        assert plan.quarterly_amount == pytest.approx(
            plan.annual_estimated_tax / 4, abs=0.5,
        )

    def test_quarterly_plan_marks_paid_periods(self):
        profile = TaxProfile()
        plan = quarterly_plan(2026, profile, 30_000, 4_500,
                              [{"period": "Q1", "year": 2026, "amount": 500}],
                              today=date(2026, 7, 1))
        q1 = next(q for q in plan.quarters if q["period"] == "Q1")
        assert q1["paid"] is True

    def test_mileage_deduction_uses_2025_rates(self):
        result = mileage_deduction(1000, 100, 50)
        assert result["business_deduction"] == 700.0    # 1000 × $0.70
        assert result["medical_deduction"] == 21.0      # 100 × $0.21
        assert result["charitable_deduction"] == 7.0    # 50 × $0.14
        assert result["total_deduction"] == 728.0

    def test_profile_from_user_defaults_are_safe(self):
        p = profile_from_user({})
        assert p.filing_status == "single"
        assert p.home_state == "TX"
        assert p.take_qbi is True

    def test_profile_from_user_reads_fields(self):
        p = profile_from_user({
            "filing_status": "married_joint",
            "business_type": "llc",
            "state": "CA",
            "dependents": 2,
        })
        assert p.filing_status == "married_joint"
        assert p.business_type == "llc"
        assert p.home_state == "CA"
        assert p.dependents == 2


# ============================================================
# Autopilot Engine — integration with in-memory Mongo
# ============================================================

@pytest.fixture
async def db():
    """Provide a clean Mongo db (isolated collection prefix per test)."""
    from motor.motor_asyncio import AsyncIOMotorClient
    import uuid
    from dotenv import load_dotenv
    load_dotenv("/app/backend/.env")
    client = AsyncIOMotorClient(os.environ["MONGO_URL"])
    db_name = f"milli_test_{uuid.uuid4().hex[:8]}"
    yield client[db_name]
    await client.drop_database(db_name)
    client.close()


@pytest.fixture
async def user(db):
    """A stock Elite-plan test user, already migrated."""
    import uuid
    uid = str(uuid.uuid4())
    doc = {
        "id": uid,
        "email": f"{uid}@test.com",
        "name": "Test User",
        "state": "TX",
        "filing_status": "single",
        "plan": "elite",
        "tax_savings_balance": 0.0,
        "retirement_balance": 0.0,
        "investing_balance": 0.0,
        "savings_balance": 0.0,
        "available_to_spend": 0.0,
        "autopilot_settings": {
            "tax_enabled": True,
            "retirement_pct": 0.05,
            "investing_pct": 0.05,
            "savings_pct": 0.02,
            "version": 1,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    }
    await db.users.insert_one(doc)
    return doc


class TestAutopilotEngine:

    @pytest.mark.asyncio
    async def test_run_creates_receipt_with_all_steps(self, db, user):
        from autopilot import run_autopilot
        payout = {
            "id": "p1", "amount": 200.0, "platform": "DoorDash",
            "date": "2026-07-10",
        }
        receipt = await run_autopilot(db, user, payout)
        assert receipt["immutable"] is True
        assert receipt["hash"].startswith("sha256:")
        # Steps: tax, retirement, investing, savings, ATS, quarterly, ai_insight
        step_names = [s["step"] for s in receipt["steps"]]
        assert "tax_protection" in step_names
        assert "retirement" in step_names
        assert "investing" in step_names
        assert "savings" in step_names
        assert "available_to_spend" in step_names
        assert "quarterly_projection" in step_names
        assert "ai_insight" in step_names

    @pytest.mark.asyncio
    async def test_balances_update_atomically(self, db, user):
        from autopilot import run_autopilot
        payout = {"id": "p2", "amount": 100.0, "platform": "Uber",
                  "date": "2026-07-10"}
        receipt = await run_autopilot(db, user, payout)
        # Sum of all allocations + ATS should equal payout amount (within cents).
        total_out = (
            receipt["tax_reserve"] + receipt["retirement_amount"]
            + receipt["investing_amount"] + receipt["savings_amount"]
            + receipt["available_to_spend"]
        )
        assert abs(total_out - payout["amount"]) < 0.05

        # User doc should reflect the new balances.
        u = await db.users.find_one({"id": user["id"]})
        assert u["tax_savings_balance"] == receipt["tax_reserve"]
        assert u["retirement_balance"] == receipt["retirement_amount"]
        assert u["investing_balance"] == receipt["investing_amount"]
        assert u["savings_balance"] == receipt["savings_amount"]
        assert u["available_to_spend"] == receipt["available_to_spend"]

    @pytest.mark.asyncio
    async def test_receipt_hash_is_deterministic_and_tamper_evident(self, db, user):
        from autopilot import run_autopilot, _receipt_hash
        payout = {"id": "p3", "amount": 150.0, "platform": "Lyft",
                  "date": "2026-07-10"}
        receipt = await run_autopilot(db, user, payout)
        # Recompute hash from stored fields — must match.
        stored = await db.autopilot_receipts.find_one({"id": receipt["id"]},
                                                       {"_id": 0})
        original_hash = stored.pop("hash")
        recomputed = _receipt_hash(stored)
        assert recomputed == original_hash
        # Mutate a field and verify the hash no longer matches.
        stored["tax_reserve"] = 9999.99
        assert _receipt_hash(stored) != original_hash

    @pytest.mark.asyncio
    async def test_tax_disabled_skips_vault_credit(self, db, user):
        from autopilot import run_autopilot, update_settings
        await update_settings(db, user["id"], {"tax_enabled": False})
        payout = {"id": "p4", "amount": 100.0, "platform": "Manual",
                  "date": "2026-07-10"}
        u = await db.users.find_one({"id": user["id"]})
        receipt = await run_autopilot(db, u, payout)
        assert receipt["tax_reserve"] == 0.0
        # Vault must not have been credited.
        u2 = await db.users.find_one({"id": user["id"]})
        assert (u2.get("tax_savings_balance") or 0.0) == 0.0

    @pytest.mark.asyncio
    async def test_basic_plan_skips_retirement_and_investing(self, db, user):
        from autopilot import run_autopilot
        await db.users.update_one({"id": user["id"]}, {"$set": {"plan": "basic"}})
        u = await db.users.find_one({"id": user["id"]})
        payout = {"id": "p5", "amount": 100.0, "platform": "DoorDash",
                  "date": "2026-07-10"}
        receipt = await run_autopilot(db, u, payout)
        assert receipt["retirement_amount"] == 0.0
        assert receipt["investing_amount"] == 0.0
        # Tax + savings still run
        assert receipt["tax_reserve"] > 0
        # Available to Spend should be larger since less was diverted.
        assert receipt["available_to_spend"] > payout["amount"] * 0.5

    @pytest.mark.asyncio
    async def test_notification_written_for_receipt(self, db, user):
        from autopilot import run_autopilot
        payout = {"id": "p6", "amount": 100.0, "platform": "Grubhub",
                  "date": "2026-07-10"}
        await run_autopilot(db, user, payout)
        notes = await db.notifications.find({"user_id": user["id"]}).to_list(10)
        assert len(notes) >= 1
        assert notes[0]["kind"] == "autopilot_receipt"

    @pytest.mark.asyncio
    async def test_multiple_runs_accumulate_balances(self, db, user):
        from autopilot import run_autopilot
        for i in range(3):
            u = await db.users.find_one({"id": user["id"]})
            await run_autopilot(db, u, {
                "id": f"pm{i}", "amount": 100.0, "platform": "DoorDash",
                "date": "2026-07-10",
            })
        u = await db.users.find_one({"id": user["id"]})
        # Total of 3×$100 spread across buckets
        total = (
            u["tax_savings_balance"] + u["retirement_balance"]
            + u["investing_balance"] + u["savings_balance"]
            + u["available_to_spend"]
        )
        assert abs(total - 300.0) < 0.1

    @pytest.mark.asyncio
    async def test_snapshot_returns_all_hero_fields(self, db, user):
        from autopilot import run_autopilot, get_snapshot
        await run_autopilot(db, user, {
            "id": "ps1", "amount": 500.0, "platform": "Uber",
            "date": "2026-07-10",
        })
        u = await db.users.find_one({"id": user["id"]})
        snap = await get_snapshot(db, u["id"])
        assert "available_to_spend" in snap
        assert "vault_balance" in snap
        assert "retirement_balance" in snap
        assert "investing_balance" in snap
        assert "tax_ready_score" in snap
        assert "next_quarterly" in snap
        assert 0 <= snap["tax_ready_score"] <= 100
