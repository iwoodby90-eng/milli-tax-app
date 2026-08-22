import XCTest
@testable import MilliTaxVault

final class AutopilotEngineTests: XCTestCase {
    func testCanonicalFinancialInvariantPreservation() {
        let gross = Money(cents: 312_45) // $312.45
        let config = AutopilotConfiguration(
            isEnabled: true,
            taxReserveRate: Decimal(string: "0.23")!,      // 23%
            retirementRate: Decimal(string: "0.05")!,      // 5%
            investingRate: Decimal.zero,                   // 0%
            emergencySavingsRate: Decimal(string: "0.03")! // 3%
        )

        let result = AutopilotEngine.allocate(grossPayout: gross, config: config, explicitFees: .zero)

        // Strict invariant check: Gross == Deductions + Available
        let sum = result.taxReserve + result.retirement + result.investing + result.savings + result.explicitFees + result.availableToSpend
        XCTAssertEqual(sum, gross)

        // Exact penny verification
        XCTAssertEqual(result.taxReserve, Money(cents: 71_86))
        XCTAssertEqual(result.retirement, Money(cents: 15_62))
        XCTAssertEqual(result.savings, Money(cents: 9_37))
        XCTAssertEqual(result.investing, Money.zero)
        XCTAssertEqual(result.availableToSpend, Money(cents: 215_60))
    }

    func testAllocationWithExplicitFees() {
        let gross = Money(cents: 500_00) // $500.00
        let instantFee = Money(cents: 1_50) // $1.50 Stripe instant deposit fee
        let config = AutopilotConfiguration(
            isEnabled: true,
            taxReserveRate: Decimal(string: "0.20")!,
            retirementRate: Decimal(string: "0.05")!,
            investingRate: Decimal(string: "0.05")!,
            emergencySavingsRate: Decimal(string: "0.05")!
        )

        let result = AutopilotEngine.allocate(grossPayout: gross, config: config, explicitFees: instantFee)
        let sum = result.taxReserve + result.retirement + result.investing + result.savings + result.explicitFees + result.availableToSpend
        XCTAssertEqual(sum, gross)
        XCTAssertEqual(result.explicitFees, instantFee)
    }

    func testDisabledAutopilotPreservesAvailableToSpend() {
        let gross = Money(cents: 250_00)
        let config = AutopilotConfiguration(
            isEnabled: false,
            taxReserveRate: Decimal(string: "0.25")!,
            retirementRate: Decimal(string: "0.10")!,
            investingRate: Decimal.zero,
            emergencySavingsRate: Decimal.zero
        )

        let result = AutopilotEngine.allocate(grossPayout: gross, config: config)
        XCTAssertEqual(result.allocatedTotal, .zero)
        XCTAssertEqual(result.availableToSpend, gross)
    }
}
