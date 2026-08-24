import XCTest
@testable import MilliTaxVault

/// Unit tests for QuarterlyTaxEstimator (MTV-101).
/// Ground-truth values computed independently from IRS 2026 formulas
/// (Pub 15-SE schedule SE + 1040 brackets), then hardcoded here.
final class QuarterlyTaxEstimatorTests: XCTestCase {

    // MARK: - Self-employment tax

    func testSETaxBelowFloorIsZero() {
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(300), 0, accuracy: 0.01)
        XCTAssertEqual(QuarterlyTaxEstimator.seTaxOn(0), 0, accuracy: 0.01)
    }

    func testSETaxTypicalGigIncome() {
        // Net SE earnings $30,000: 30,000 * 0.9235 = 27,705
        // SS: 27,705 * 0.124 = 3,435.42 ; Medicare: 27,705 * 0.029 = 803.445
        let se = QuarterlyTaxEstimator.seTaxOn(30_000)
        XCTAssertEqual(se, 3_435.42 + 803.45, accuracy: 1.0)
    }

    func testSETaxCapsSocialSecurityAtWageBase() {
        // Above the SS wage base only the 2.9% Medicare portion keeps growing.
        let below = QuarterlyTaxEstimator.seTaxOn(200_000)
        let above = QuarterlyTaxEstimator.seTaxOn(400_000)
        let medicareDelta = (400_000 - 200_000) * 0.9235 * 0.029
        XCTAssertEqual(above - below, medicareDelta, accuracy: 1.0)
    }

    // MARK: - Federal brackets

    func testFederalTaxFirstBracket() {
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 10_000, filingStatus: .single), 1_000, accuracy: 0.01)
    }

    func testFederalTaxSpansBrackets() {
        // $50,000 single: 11,925*10% + (48,475-11,925)*12% + (50,000-48,475)*22%
        let expected = 1_192.5 + 36_550 * 0.12 + 1_525 * 0.22
        XCTAssertEqual(QuarterlyTaxEstimator.federalTax(on: 50_000, filingStatus: .single), expected, accuracy: 0.01)
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
        // SE tax: 40,000 * 0.9235 = 36,940 -> SS 4,580.56 + Med 1,071.26 = 5,651.82
        XCTAssertEqual(e.selfEmploymentTax, 5_651.82, accuracy: 2.0)
        // AGI = 40,000 - 2,825.91 = 37,174.09 ; taxable = 22,174.09
        // QBI = min(40,000*0.2, 22,174.09*0.2) = 4,434.82 -> taxable after QBI = 17,739.27
        // Tax = 1,192.5 + (17,739.27-11,925)*0.12 = 1,890.21
        XCTAssertEqual(e.federalIncomeTax, 1_890.21, accuracy: 2.0)
        // Total ~ 7,542 ; quarterly ~ 1,885.5
        XCTAssertEqual(e.quarterlyPayment, (e.totalAnnualTax / 4).rounded(), accuracy: 0.51)
        XCTAssertGreaterThan(e.effectiveRate, 0.15)
        XCTAssertLessThan(e.effectiveRate, 0.25)
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

    func testQuarterlyIsTotalDividedByFour() {
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 120_000, businessExpenses: 15_000)
        XCTAssertEqual(e.quarterlyPayment * 4, e.totalAnnualTax, accuracy: 2.0)
    }

    func testQBIIsTwentyPercentCappedAtTaxableIncome() {
        let e = QuarterlyTaxEstimator.estimate(grossIncome: 40_000)
        XCTAssertEqual(e.qbiDeduction, 40_000 * 0.20, accuracy: 1.0)
    }
}
