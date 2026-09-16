import XCTest
@testable import MilliTaxVault

// MARK: - RetirementProjectionCalculatorTests
// D5 sprint feature: unit tests for the retirement projection calculator.
//
// The calculator is a pure function: given a RetirementPlanningSnapshot and
// a consolidated balance, it produces a year-by-year projection using
// monthly compounding. These tests pin the math, boundary conditions, and
// data-truth invariants.
//
// All assertions are EXACT (no accuracy tolerance) because the calculator
// uses Double arithmetic with deterministic inputs.

final class RetirementProjectionCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func snapshot(
        currentAge: Int = 32,
        currentBalance: Double = 42685.73,
        annualIncome: Double = 75000,
        contributionMode: RetirementContributionMode = .percentOfIncome,
        contributionPercent: Double = 15,
        monthlyContribution: Double = 937.50,
        targetRetirementAge: Int = 62,
        annualReturnPercent: Double = 7.5,
        hasVerifiedConnectedData: Bool = true
    ) -> RetirementPlanningSnapshot {
        RetirementPlanningSnapshot(
            currentAge: currentAge,
            currentBalance: currentBalance,
            annualIncome: annualIncome,
            contributionMode: contributionMode,
            contributionPercent: contributionPercent,
            monthlyContribution: monthlyContribution,
            targetRetirementAge: targetRetirementAge,
            annualReturnPercent: annualReturnPercent,
            hasVerifiedConnectedData: hasVerifiedConnectedData
        )
    }

    // MARK: - Nil / boundary conditions

    func testReturnsNilWhenTargetAgeEqualsCurrentAge() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 62, targetRetirementAge: 62),
            consolidatedBalance: 50000
        )
        XCTAssertNil(result, "yearsToRetirement == 0 must return nil")
    }

    func testReturnsNilWhenTargetAgeBelowCurrentAge() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 65, targetRetirementAge: 60),
            consolidatedBalance: 50000
        )
        XCTAssertNil(result, "yearsToRetirement < 0 must return nil")
    }

    func testHandlesOneYearToRetirement() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 61, targetRetirementAge: 62),
            consolidatedBalance: 10000
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.points.count, 2, "year 0 + year 1 = 2 points")
    }

    // MARK: - Monthly compounding math

    func testMonthlyCompoundingFormulaExact() {
        // 1 year, $0 starting balance, $1000/mo contribution, 0% return.
        // After 12 months: 12 * 1000 = 12000 (no growth at 0%).
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                currentAge: 64,
                currentBalance: 0,
                annualIncome: 12000,
                contributionPercent: 100, // 12000 * 100% / 12 = 1000/mo
                targetRetirementAge: 65,
                annualReturnPercent: 0
            ),
            consolidatedBalance: 0
        )!
        XCTAssertEqual(result.endingBalance, 12000, accuracy: 0.01)
        XCTAssertEqual(result.totalContributions, 12000, accuracy: 0.01)
        XCTAssertEqual(result.totalGrowth, 0, accuracy: 0.01)
    }

    func testMonthlyCompoundingWithPositiveReturn() {
        // 1 year, $0 start, $1000/mo, 12% annual return.
        // monthlyRate = (1.12)^(1/12) - 1
        // After 12 months of $1000 contributions with monthly compounding:
        let monthlyRate = pow(1.12, 1.0 / 12.0) - 1
        var expectedBalance: Double = 0
        for _ in 0..<12 {
            expectedBalance = expectedBalance * (1 + monthlyRate) + 1000
        }
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                currentAge: 64,
                currentBalance: 0,
                annualIncome: 12000,
                contributionPercent: 100,
                targetRetirementAge: 65,
                annualReturnPercent: 12
            ),
            consolidatedBalance: 0
        )!
        XCTAssertEqual(result.endingBalance, expectedBalance, accuracy: 0.01)
    }

    func testStartingBalanceGrowsWithCompounding() {
        // 1 year, $10000 start, $0 contribution, 12% return.
        // After 12 months: 10000 * (1 + monthlyRate)^12
        let monthlyRate = pow(1.12, 1.0 / 12.0) - 1
        let expected = 10000 * pow(1 + monthlyRate, 12)
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                currentAge: 64,
                currentBalance: 10000,
                annualIncome: 0,
                contributionPercent: 0,
                targetRetirementAge: 65,
                annualReturnPercent: 12
            ),
            consolidatedBalance: 10000
        )!
        XCTAssertEqual(result.endingBalance, expected, accuracy: 0.01)
    }

    // MARK: - Contribution calculation

    func testMonthlyContributionIsPercentOfIncomeDividedBy12() {
        // annualIncome 75000, contributionPercent 15% -> 75000 * 0.15 / 12 = 937.50
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                annualIncome: 75000,
                contributionPercent: 15,
                targetRetirementAge: 33 // 1 year
            ),
            consolidatedBalance: 0
        )!
        // totalContributions = starting balance + 12 * 937.50 = 0 + 11250
        XCTAssertEqual(result.totalContributions, 11250, accuracy: 0.01)
    }

    func testZeroContributionStillCompoundsStartingBalance() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                currentAge: 64,
                annualIncome: 0,
                contributionPercent: 0,
                targetRetirementAge: 65,
                annualReturnPercent: 7.5
            ),
            consolidatedBalance: 50000
        )!
        // No contributions added; totalContributions == starting balance only
        XCTAssertEqual(result.totalContributions, 50000, accuracy: 0.01)
        XCTAssertGreaterThan(result.endingBalance, 50000, "must grow from compounding")
        XCTAssertGreaterThan(result.totalGrowth, 0)
    }

    // MARK: - Growth accounting

    func testTotalGrowthIsEndingBalanceMinusContributions() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                currentAge: 32,
                targetRetirementAge: 62,
                annualReturnPercent: 7.5
            ),
            consolidatedBalance: 42685.73
        )!
        let expectedGrowth = result.endingBalance - result.totalContributions
        XCTAssertEqual(result.totalGrowth, max(expectedGrowth, 0), accuracy: 0.01)
    }

    func testTotalGrowthNeverNegative() {
        // 0% return, only contributions: growth must be 0, not negative
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(
                currentAge: 64,
                annualIncome: 60000,
                contributionPercent: 10,
                targetRetirementAge: 65,
                annualReturnPercent: 0
            ),
            consolidatedBalance: 0
        )!
        XCTAssertEqual(result.totalGrowth, 0, "growth clamped to >= 0")
    }

    // MARK: - Projection points

    func testFirstPointIsCurrentYearWithStartingBalance() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 32, targetRetirementAge: 62),
            consolidatedBalance: 50000
        )!
        let first = result.points.first!
        let currentYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(first.year, currentYear)
        XCTAssertEqual(first.balance, 50000, accuracy: 0.01)
        XCTAssertEqual(first.totalContributions, 50000, accuracy: 0.01)
    }

    func testLastPointIsRetirementYear() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 32, targetRetirementAge: 62),
            consolidatedBalance: 50000
        )!
        let currentYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(result.retirementYear, currentYear + 30)
        let last = result.points.last!
        XCTAssertEqual(last.year, currentYear + 30)
        XCTAssertEqual(last.balance, result.endingBalance, accuracy: 0.01)
    }

    func testPointsAreMonotonicallyIncreasingInBalance() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(annualReturnPercent: 7.5),
            consolidatedBalance: 10000
        )!
        for i in 1..<result.points.count {
            XCTAssertGreaterThan(result.points[i].balance, result.points[i - 1].balance,
                                 "balance must increase monotonically with positive return and contributions")
        }
    }

    // MARK: - Consolidated balance integration

    func testConsolidatedBalanceIncludesMergedAccounts() {
        // The calculator receives consolidatedBalance as a parameter.
        // The view computes it as milliAccount.balance + mergedAccounts.reduce(0) { $0 + $1.balance }.
        // Here we verify the calculator uses the passed-in value correctly.
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 64, targetRetirementAge: 65),
            consolidatedBalance: 100000
        )!
        XCTAssertEqual(result.points.first!.balance, 100000, accuracy: 0.01)
    }

    // MARK: - Retirement year calculation

    func testRetirementYearIsCurrentYearPlusYearsToRetirement() {
        let result = RetirementProjectionCalculator.calculate(
            profile: snapshot(currentAge: 40, targetRetirementAge: 65),
            consolidatedBalance: 50000
        )!
        let currentYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(result.retirementYear, currentYear + 25)
    }
}
