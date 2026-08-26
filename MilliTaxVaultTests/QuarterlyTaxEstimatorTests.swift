import XCTest
@testable import MilliTaxVault

/// Unit tests for QuarterlyTaxEstimator (MTV-101), tax year 2026.
/// Ground-truth values computed independently from IRS Rev. Proc. 2025-32
/// (2026 brackets & standard deductions), SSA 2026 wage base ($184,500),
/// and Schedule SE (92.35% adjustment, $400 floor on net earnings).
final class QuarterlyTaxEstimatorTests: XCTestCase {

    // MARK: - Self-employment tax (Schedule SE)

    func testSETaxBelowFloorIsZero() {
        // Floor applies to net earnings AFTER the 92.35% adjustment.
        // Profit 300 -> net earnings 277.05 <= 400 -> no SE tax.
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(300), 0, accuracy: 0.01)
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(0), 0, accuracy: 0.01)
    }

    func testSETaxFloorBoundaryOnNetEarnings() {
        // Profit 432.70 -> net earnings 399.99 <= 400 -> 0.
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(432.70), 0, accuracy: 0.01)
        // Profit 434 -> net earnings 400.03 > 400 -> full 15.3% on net earnings.
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(434), 434 * 0.9235 * 0.153, accuracy: 0.01)
    }

    func testSETaxTypicalGigIncome() {
        // Net profit $30,000: net earnings = 27,705
        // SS: 27,705 * 0.124 = 3,435.42 ; Medicare: 27,705 * 0.029 = 803.445
        let se = QuarterlyTaxEstimator.seTaxOn(30_000)
        XCTAssertEqual(se, 3_435.42 + 803.445, accuracy: 0.01)
    }

    func testSETaxCapsSocialSecurityAtWageBase() {
        // 2026 wage base $184,500 applies to net earnings (92.35% of profit).
        // Profit 200,000 -> NE 184,700 (SS capped); Profit 400,000 -> NE 369,400.
        let below = QuarterlyTaxEstimator.seTaxOn(200_000)
        XCTAssertEqual(below, 184_500 * 0.124 + 184_700 * 0.029, accuracy: 0.01)
        let above = QuarterlyTaxEstimator.seTaxOn(400_000)
        XCTAssertEqual(above, 184_500 * 0.124 + 369_400 * 0.029, accuracy: 0.01)
        // Above the base only the 2.9% Medicare portion grows.
        XCTAssertEqual(above - below, (369_400 - 184_700) * 0.029, accuracy: 0.01)
    }

    // MARK: - Federal brackets (2026, Rev. Proc. 2025-32)

    func testFederalTaxFirstBracketSingle() {
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 10_000, filingStatus: .single), 1_000, accuracy: 0.01)
    }

    func testFederalTaxBracketBoundarySingle() {
        // Exactly at the 10%/12% boundary: 12,400 * 10% = 1,240.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 12_400, filingStatus: .single), 1_240, accuracy: 0.01)
        // One dollar into the 12% bracket.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 12_401, filingStatus: .single), 1_240.12, accuracy: 0.01)
    }

    func testFederalTaxSpansBracketsSingle() {
        // $50,000 single: 12,400*10% + (50,000-12,400)*12% = 1,240 + 4,512.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 50_000, filingStatus: .single), 5_752, accuracy: 0.01)
    }

    func testFederalTaxTopBracketSingle() {
        // $700,000 single:
        // 1,240 + 38,000*.12 + 55,300*.22 + 96,075*.24 + 54,450*.32 + 384,375*.35 + 59,400*.37
        var expected: Double = 1_240
        expected += 38_000 * 0.12
        expected += 55_300 * 0.22
        expected += 96_075 * 0.24
        expected += 54_450 * 0.32
        expected += 384_375 * 0.35
        expected += 59_400 * 0.37

        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 700_000, filingStatus: .single), expected, accuracy: 0.01)
    }

    func testFederalTaxMarriedJointUsesExplicitSchedule() {
        // $100,800 MFJ is the exact 12%/22% boundary: 24,800*10% + 76,000*12% = 11,600.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 100_800, filingStatus: .marriedJoint), 11_600, accuracy: 0.01)
        // $250,000 MFJ: 2,480 + 9,120 + 110,600*.22 + 38,600*.24
        var expected: Double = 2_480
        expected += 9_120
        expected += 110_600 * 0.22
        expected += 38_600 * 0.24
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 250_000, filingStatus: .marriedJoint), expected, accuracy: 0.01)
    }

    func testFederalTaxMarriedSeparateUsesExplicitSchedule() {
        // MFS 35% bracket ends at 384,350 (NOT the single 640,600).
        // At 384,350: 1,240 + 4,560 + 12,166 + 23,058 + 17,424 + 128,125*.35
        var expected: Double = 1_240
        expected += 4_560
        expected += 55_300 * 0.22
        expected += 96_075 * 0.24
        expected += 54_450 * 0.32
        expected += 128_125 * 0.35
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 384_350, filingStatus: .marriedSeparate), expected, accuracy: 0.01)
        // Just above 384,350 the 37% rate applies.
        let justAbove = QuarterlyTaxEstimator.federalTax(on: 384_351, filingStatus: .marriedSeparate)
        XCTAssertEqual(justAbove - expected, 0.37, accuracy: 0.01)
    }

    func testFederalTaxHeadOfHouseholdUsesExplicitSchedule() {
        // $67,450 HoH is the 12%/22% boundary: 17,700*10% + 49,750*12% = 7,740.
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 67_450, filingStatus: .headOfHousehold), 7_740, accuracy: 0.01)
        // $100,000 HoH: 1,770 + 5,970 + (100,000-67,450)*.22
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 100_000, filingStatus: .headOfHousehold),
                       1_770 + 5_970 + 32_550 * 0.22, accuracy: 0.01)
    }

    func testFederalTaxZeroIncome() {
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 0, filingStatus: .single), 0, accuracy: 0.01)
    }

    // MARK: - Full estimate

    func testEstimateZeroIncomePaysNothing() {
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 0)
        XCTAssertEqual(e.totalAnnualTax, 0, accuracy: 0.01)
        XCTAssertEqual(e.quarterlyPayment, 0, accuracy: 0.01)
        XCTAssertEqual(e.effectiveRate, 0, accuracy: 0.0001)
    }

    func testEstimateTypicalGigWorker() {
        // $40,000 gross, no expenses, single.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 40_000)
        // SE: NE = 36,940 -> SS 4,580.56 + Med 1,071.26 = 5,651.82
        XCTAssertEqual(e.selfEmploymentTax, 5_651.82, accuracy: 0.01)
        // AGI = 40,000 - 2,825.91 = 37,174.09 ; taxable = 37,174.09 - 16,100 = 21,074.09
        // QBI = min(8,000, 21,074.09*0.2 = 4,214.82) = 4,214.82 (capped by taxable income)
        XCTAssertEqual(e.qbiDeduction, 4_214.82, accuracy: 0.01)
        // Taxable after QBI = 16,859.27 ; tax = 1,240 + (16,859.27-12,400)*0.12 = 1,775.11
        XCTAssertEqual(e.federalIncomeTax, 1_775.11, accuracy: 0.01)
        // Total = 7,426.93 ; quarterly = round(1,856.73) = 1,857
        XCTAssertEqual(e.totalAnnualTax, 7_426.93, accuracy: 0.01)
        XCTAssertEqual(e.quarterlyPayment, 1_857, accuracy: 0.01)
        XCTAssertGreaterThan(e.effectiveRate, 0.15)
        XCTAssertLessThan(e.effectiveRate, 0.25)
    }

    func testEstimateBelowSEFloorStillOwesIncomeTaxIfAboveDeduction() {
        // Profit 500 -> net earnings 461.75 > 400 -> small SE tax applies.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 500)
        XCTAssertEqual(e.selfEmploymentTax, 500 * 0.9235 * 0.153, accuracy: 0.01)
        // Taxable income after 16,100 standard deduction is 0 -> no income tax, no QBI.
        XCTAssertEqual(e.federalIncomeTax, 0, accuracy: 0.01)
        XCTAssertEqual(e.qbiDeduction, 0, accuracy: 0.01)
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
        XCTAssertLessThanOrEqual(joint.totalAnnualTax, single.totalAnnualTax + 0.01)
    }

    func testEstimateHeadOfHouseholdBetweenSingleAndJoint() {
        let single = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .single)
        let hoh = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .headOfHousehold)
        let joint = QuarterlyTaxEstimator.estimate(grossIncome: 80_000, filingStatus: .marriedJoint)
        XCTAssertLessThanOrEqual(hoh.totalAnnualTax, single.totalAnnualTax + 0.01)
        XCTAssertLessThanOrEqual(joint.totalAnnualTax, hoh.totalAnnualTax + 0.01)
    }

    func testQuarterlyIsTotalDividedByFour() {
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 120_000, businessExpenses: 15_000)
        XCTAssertEqual(e.quarterlyPayment, (e.totalAnnualTax / 4).rounded(), accuracy: 0.01)
        XCTAssertEqual(e.quarterlyPayment * 4, e.totalAnnualTax, accuracy: 2.0)
    }

    func testQBIIsTwentyPercentCappedAtTaxableIncome() {
        // $40,000 profit: 20% of QBI = 8,000, but 20% of taxable income
        // (21,074.09 * 0.2 = 4,214.82) is lower, so the cap binds.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 40_000)
        XCTAssertEqual(e.qbiDeduction, 4_214.82, accuracy: 0.01)
        // For pure-SE income the taxable-income cap ALWAYS binds, because
        // taxable income (after half-SE deduction + standard deduction) is
        // strictly below net SE profit. So QBI = 20% of taxable income.
        let high = QuarterlyTaxEstimator.estimate(grossIncome: 200_000)
        XCTAssertEqual(high.qbiDeduction, 33_956.57, accuracy: 0.01)
    }

    func testWageBaseInteractionInFullEstimate() {
        // Profit 400,000: SS portion capped at 184,500 * 12.4% = 22,878.
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 400_000)
        XCTAssertEqual(e.selfEmploymentTax, 22_878 + 369_400 * 0.029, accuracy: 0.01)
    }
}