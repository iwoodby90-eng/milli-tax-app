import XCTest
@testable import MilliTaxVault

final class FinancialInvariantTests: XCTestCase {
    func testFinancialReceiptInvariantAndTamperProofing() throws {
        let receipt = FinancialReceipt(
            payoutId: "PO-2026-991",
            platform: "DoorDash",
            grossAmount: Money(cents: 312_45),
            taxProtected: Money(cents: 71_86),
            retirementAllocation: Money(cents: 15_62),
            investingAllocation: .zero,
            emergencySavings: Money(cents: 9_37),
            explicitFees: .zero,
            availableToSpend: Money(cents: 215_60),
            calculationVersion: "2026.2.0",
            taxRuleVersion: "2026.2-H2",
            traceId: "TRC-2026-001"
        )

        XCTAssertTrue(receipt.isValidInvariant)
        try FinancialInvariantValidator.validateReceipt(receipt)
    }

    func testTamperDetectionThrowsViolation() {
        let badReceipt = FinancialReceipt(
            payoutId: "PO-2026-BAD",
            platform: "Uber",
            grossAmount: Money(cents: 312_45),
            taxProtected: Money(cents: 71_86),
            retirementAllocation: Money(cents: 15_62),
            investingAllocation: .zero,
            emergencySavings: Money(cents: 9_37),
            explicitFees: .zero,
            availableToSpend: Money(cents: 200_00) // Tampered: missing $15.60
        )

        XCTAssertFalse(badReceipt.isValidInvariant)
        XCTAssertThrowsError(try FinancialInvariantValidator.validateReceipt(badReceipt)) { error in
            guard let invError = error as? FinancialInvariantError else {
                XCTFail("Expected FinancialInvariantError")
                return
            }
            if case .allocationMismatch(let gross, let sum, let diff) = invError {
                XCTAssertEqual(gross, Money(cents: 312_45))
                XCTAssertEqual(sum, Money(cents: 296_85))
                XCTAssertEqual(diff, 15_60)
            } else {
                XCTFail("Expected allocationMismatch case")
            }
        }
    }
}
