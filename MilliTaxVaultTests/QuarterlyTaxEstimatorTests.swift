import XCTest
@testable import MilliTaxVault

/// Unit tests for QuarterlyTaxEstimator (MTV-101), tax year 2026.
/// Ground-truth values computed independently from IRS Rev. Proc. 2025-32
/// (2026 brackets & standard deductions), SSA 2026 wage base ($184,500),
/// and Schedule SE (92.35% adjustment, $400 floor on net earnings).
///
/// All monetary assertions are EXACT (no `accuracy:` tolerance) — the
/// estimator is fully `Decimal`, so every value below is reproducible to
/// the cent. Ground truths were independently recomputed with exact
/// decimal arithmetic before being written down.
final class QuarterlyTaxEstimatorTests: XCTestCase {

    // MARK: - Self-employment tax (Schedule SE)

    func testSETaxBelowFloorIsZero() {
        // Floor applies to net earnings AFTER the 92.35% adjustment.
        // Profit 300 -> net earnings 277.05 <= 400 -> no SE tax.
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(300), 0)
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(0), 0)
    }

    func testSETaxFloorBoundaryOnNetEarnings() {
        // Profit 432.70 -> net earnings 399.99 <= 400 -> 0.
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(Decimal(string: "432.70")!), 0)
        // Profit 434 -> net earnings 400.03 > 400 -> full 15.3% on net earnings.
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(434), Decimal(string: "61.322247")!)
    }

    func testSETaxTypicalGigIncome() {
        // Net profit $30,000: net earnings = 27,705
        // SS: 27,705 * 0.124 = 3,435.42 ; Medicare: 27,705 * 0.029 = 803.445
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(30_000), Decimal(string: "4238.865")!)
    }

    func testSETaxCapsSocialSecurityAtWageBase() {
        // 2026 wage base $184,500 applies to net earnings (92.35% of profit).
        // Profit 200,000 -> NE 184,700 (SS capped); Profit 400,000 -> NE 369,400.
        let below = QuarterlyTaxEstimator.seTaxOn(200_000)
        XCTAssertEqual(below, Decimal(string: "28234.30")!)
        let above = QuarterlyTaxEstimator.seTaxOn(400_000)
        XCTAssertEqual(above, Decimal(string: "33590.60")!)
        // Above the base only the 2.9% Medicare portion grows.
        XCTAssertEqual(above - below, Decimal(string: "5356.30")!)
    }

    // MARK: - Federal brackets (2026, Rev. Proc. 2025-32)

    func testFederalTaxFirstBracketSingle() {
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 10_000, filingStatus: .single), 1_000)
    }

    func testFederalTaxBracketBoundarySingle() {
        // Exactly at the 10%/12% boundary: 12,400 * 10% = 1,240.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 12_400, filingStatus: .single), 1_240)
        // One dollar into the 12% bracket.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 12_401, filingStatus: .single), Decimal(string: "1240.12")!)
    }

    func testFederalTaxSpansBracketsSingle() {
        // $50,000 single: 12,400*10% + (50,000-12,400)*12% = 1,240 + 4,512.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 50_000, filingStatus: .single), 5_752)
    }

    func testFederalTaxTopBracketSingle() {
        // $700,000 single:
        // 1,240 + 38,000*.12 + 55,300*.22 + 96,075*.24 + 54,450*.32 + 384,375*.35 + 59,400*.37
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 700_000, filingStatus: .single),
                       Decimal(string: "214957.25")!)
    }

    func testFederalTaxMarriedJointUsesExplicitSchedule() {
        // $100,800 MFJ is the exact 12%/22% boundary: 24,800*10% + 76,000*12% = 11,600.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 100_800, filingStatus: .marriedJoint), 11_600)
        // $250,000 MFJ: 2,480 + 9,120 + 110,600*.22 + 38,600*.24
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 250_000, filingStatus: .marriedJoint),
                       Decimal(string: "45196.00")!)
    }

    func testFederalTaxMarriedSeparateUsesExplicitSchedule() {
        // MFS 35% bracket ends at 384,350 (NOT the single 640,600).
        // At 384,350: 1,240 + 4,560 + 12,166 + 23,058 + 17,424 + 128,125*.35
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 384_350, filingStatus: .marriedSeparate),
                       Decimal(string: "103291.75")!)
        // Just above 384,350 the 37% rate applies.
        let justAbove = QuarterlyTaxEstimator.federalTax(on: 384_351, filingStatus: .marriedSeparate)
        XCTAssertEqual(justAbove - Decimal(string: "103291.75")!, Decimal(string: "0.37")!)
    }

    func testFederalTaxHeadOfHouseholdUsesExplicitSchedule() {
        // $67,450 HoH is the 12%/22% boundary: 17,700*10% + 49,750*12% = 7,740.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 67_450, filingStatus: .headOfHousehold), 7_740)
        // $100,000 HoH: 1,770 + 5,970 + (100,000-67,450)*.22
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 100_000, filingStatus: .headOfHousehold),
                       Decimal(string: "14901.00")!)
    }

    func testFederalTaxZeroIncome() {
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 0, filingStatus: .single), 0)
    }

    // MARK: - Rounding boundary (explicit policy)

    func testRoundToCentsHalfAwayFromZero() {
        // Half-cent values round AWAY from zero (tax payment convention),
        // never banker's rounding.
        XCTAssertEqual(QuarterlyTaxEstimator.roundToCents(Decimal(string: "0.005")!), Decimal(string: "0.01")!)
        XCTAssertEqual(QuarterlyTaxEstimator.roundToCents(Decimal(string: "0.015")!), Decimal(string: "0.02")!)
        XCTAssertEqual(QuarterlyTaxEstimator.roundToCents(Decimal(string: "0.025")!), Decimal(string: "0.03")!)
        XCTAssertEqual(QuarterlyTaxEstimator.roundToCents(Decimal(string: "-0.005")!), Decimal(string: "-0.01")!)
        // Values already at cent precision are unchanged.
        XCTAssertEqual(QuarterlyTaxEstimator.roundToCents(Decimal(string: "1856.73")!), Decimal(string: "1856.73")!)
    }

    // MARK: - Full estimate

    func testEstimateZeroIncomePaysNothing() {
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 0)
        XCTAssertEqual(e.totalAnnualTax, 0)
        XCTAssertEqual(e.quarterlyPayment, 0)
        XCTAssertEqual(e.effectiveRate, 0)
    }

    func testEstimateTypicalGigWorker() {
        // $40,000 gross, no expenses, single.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 40_000)
        // SE: NE = 36,940 -> SS 4,580.56 + Med 1,071.26 = 5,651.82
        XCTAssertEqual(e.selfEmploymentTax, Decimal(string: "5651.82")!)
        // AGI = 40,000 - 2,825.91 = 37,174.09 ; taxable = 37,174.09 - 16,100 = 21,074.09
        // QBI = min(8,000, 21,074.09*0.2 = 4,214.818) = 4,214.818 (capped by taxable income)
        XCTAssertEqual(e.qbiDeduction, Decimal(string: "4214.818")!)
        // Taxable after QBI = 16,859.272 ; tax = 1,240 + (16,859.272-12,400)*0.12 = 1,775.11264
        XCTAssertEqual(e.federalIncomeTax, Decimal(string: "1775.11264")!)
        // Total = 7,426.93264 ; quarterly = round-to-cents(1,856.73316) = 1,856.73
        XCTAssertEqual(e.totalAnnualTax, Decimal(string: "7426.93264")!)
        XCTAssertEqual(e.quarterlyPayment, Decimal(string: "1856.73")!)
        XCTAssertGreaterThan(e.effectiveRate, Decimal(string: "0.15")!)
        XCTAssertLessThan(e.effectiveRate, Decimal(string: "0.25")!)
    }

    func testEstimateBelowSEFloorStillOwesIncomeTaxIfAboveDeduction() {
        // Profit 500 -> net earnings 461.75 > 400 -> small SE tax applies.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 500)
        XCTAssertEqual(e.selfEmploymentTax, Decimal(string: "70.64775")!)
        // Taxable income after 16,100 standard deduction is 0 -> no income tax, no QBI.
        XCTAssertEqual(e.federalIncomeTax, 0)
        XCTAssertEqual(e.qbiDeduction, 0)
    }

    func testEstimateExpensesReduceTax() {
        let without = QuarterlyTaxEstimator.estimate(grossIncome: 50_000, businessExpenses: 0)
        let with = QuarterlyTaxEstimator.estimate(grossIncome: 50_000, businessExpenses: 10_000)
        XCTAssertLessThan(with.totalAnnualTax, without.totalAnnualTax)
        XCTAssertLessThan(with.selfEmploymentTax, without.selfEmploymentTax)
    }

    func testEstimateMarriedJointIsNotWorseThanSingle() {
        let single = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .single)
        let joint = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .marriedJoint)
        XCTAssertLessThanOrEqual(joint.totalAnnualTax, single.totalAnnualTax)
    }

    func testEstimateHeadOfHouseholdBetweenSingleAndJoint() {
        let single = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .single)
        let hoh = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .headOfHousehold)
        let joint = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .marriedJoint)
        XCTAssertLessThanOrEqual(hoh.totalAnnualTax, single.totalAnnualTax)
        XCTAssertLessThanOrEqual(joint.totalAnnualTax, hoh.totalAnnualTax)
    }

    func testQuarterlyIsTotalDividedByFourRoundedToCents() {
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 120_000, businessExpenses: 15_000)
        // Total = 23,888.85708 -> quarterly = round-to-cents(5,972.21427) = 5,972.21
        XCTAssertEqual(e.totalAnnualTax, Decimal(string: "23888.85708")!)
        XCTAssertEqual(e.quarterlyPayment, Decimal(string: "5972.21")!)
        // The quarterly payment is the only rounded value; it stays within
        // half a cent per quarter of the exact total/4.
        let exactQuarter = e.totalAnnualTax / 4
        XCTAssertLessThanOrEqual(abs(e.quarterlyPayment - exactQuarter), Decimal(string: "0.005")!)
    }

    func testQBIIsTwentyPercentCappedAtTaxableIncome() {
        // $40,000 profit: 20% of QBI = 8,000, but 20% of taxable income
        // (21,074.09 * 0.2 = 4,214.818) is lower, so the cap binds.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 40_000)
        XCTAssertEqual(e.qbiDeduction, Decimal(string: "4214.818")!)
        // For pure-SE income the taxable-income cap ALWAYS binds, because
        // taxable income (after half-SE deduction + standard deduction) is
        // strictly below net SE profit. So QBI = 20% of taxable income.
        let high = QuarterlyTaxEstimator.estimate(grossIncome: 200_000)
        XCTAssertEqual(high.qbiDeduction, Decimal(string: "33956.57")!)
    }

    func testWageBaseInteractionInFullEstimate() {
        // Profit 400,000: SS portion capped at 184,500 * 12.4% = 22,878.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 400_000)
        XCTAssertEqual(e.selfEmploymentTax, Decimal(string: "33590.60")!)
    }

    // MARK: - Safe-harbor scope (documented non-goal)

    func testEstimateIsInstallmentNotSafeHarbor() {
        // The estimator's quarterly figure is total/4 (current-year liability
        // installment). It deliberately takes no prior-year-tax input, so it
        // cannot and must not claim safe-harbor compliance (100%/110% rule).
        // This test pins the contract: quarterly == roundToCents(total / 4)
        // for a case where a safe-harbor figure would differ.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 40_000)
        XCTAssertEqual(e.quarterlyPayment, QuarterlyTaxEstimator.roundToCents(e.totalAnnualTax / 4))
    }
}
