import XCTest
@testable import MilliTaxVault

final class MilliMoneyTests: XCTestCase {

    // MARK: Parsing / conversion boundaries

    func testParseExactCents() {
        XCTAssertEqual(MilliMoney(string: "5284.17")?.cents, 528_417)
        XCTAssertEqual(MilliMoney(string: "0.01")?.cents, 1)
        XCTAssertEqual(MilliMoney(string: "-1.00")?.cents, -100) // signed debits are valid
        XCTAssertEqual(MilliMoney(string: "-1,247.00" as String), nil) // grouping/partial parse rejected
    }

    func testRoundingHalfAwayFromZero() {
        XCTAssertEqual(MilliMoney(decimal: milliDecimal("0.005")).cents, 1)   // 0.5c rounds up
        XCTAssertEqual(MilliMoney(decimal: milliDecimal("-0.005")).cents, -1) // away from zero
        XCTAssertEqual(MilliMoney(decimal: milliDecimal("0.004")).cents, 0)
        XCTAssertEqual(MilliMoney(decimal: milliDecimal("0.015")).cents, 2)   // 1.5c up
        XCTAssertEqual(MilliMoney(decimal: milliDecimal("1.005")).cents, 101)
    }

    func testNoDoubleLiteralContamination() {
        // 0.1 + 0.2 must be exactly 0.30, not 0.30000000000000004
        let a = MilliMoney(string: "0.10")!
        let b = MilliMoney(string: "0.20")!
        XCTAssertEqual((a + b).plain, "0.30")
    }

    // MARK: Arithmetic

    func testSumExact() {
        let values = (0..<1000).map { MilliMoney(cents: Int64($0)) }
        XCTAssertEqual(MilliMoney.sum(values).cents, 499_500)
    }

    func testMultiplicationRoundsOnce() {
        let m = MilliMoney(string: "10.05")!
        let result = m.multiplied(by: milliDecimal("0.23"))
        XCTAssertEqual(result.cents, 231) // 2.3115 → 2.31 (half away from zero on 2.3115*100=231.15 → 231)
    }

    // MARK: Formatting

    func testPlainFormatting() {
        XCTAssertEqual(MilliMoney(cents: 123_456).plain, "1,234.56")
        XCTAssertEqual(MilliMoney(cents: -5).plain, "-0.05")
        XCTAssertEqual(MilliMoney(cents: 0).usd, "$0.00")
        XCTAssertEqual(MilliMoney(cents: 100).usd, "$1.00")
    }

    // MARK: Pro-rata allocation — sum(parts) == total, always

    func testAllocationSumsExactly() {
        let cases: [(Int64, [Decimal])] = [
            (100, [milliDecimal("0.23"), milliDecimal("0.77")]),
            (100, [milliDecimal("0.333333"), milliDecimal("0.333333"), milliDecimal("0.333334")]),
            (7, [milliDecimal("1"), milliDecimal("1"), milliDecimal("1")]),
            (-33, [milliDecimal("0.5"), milliDecimal("0.5")]),
            (99, [milliDecimal("0.1"), milliDecimal("0.2"), milliDecimal("0.7")]),
            (1, [milliDecimal("0.5"), milliDecimal("0.5")]),
        ]
        for (total, weights) in cases {
            let parts = MilliAllocation.split(total: MilliMoney(cents: total), weights: weights)
            XCTAssertEqual(MilliMoney.sum(parts).cents, total, "weights \(weights)")
        }
    }

    func testAllocationBoundary23Percent() {
        // Autopilot 23% tax reserve on a $43.11 payout, largest-remainder split:
        // 43.11*0.23 = 9.9153 → floor 9.91 (fraction .53), 43.11*0.77 = 33.2147 → floor 33.21.
        // Floors sum to 43.12, one cent over; the largest fraction (tax leg) takes it.
        let payout = MilliMoney(string: "43.11")!
        let parts = MilliAllocation.split(total: payout, weights: [milliDecimal("0.23"), milliDecimal("0.77")])
        XCTAssertEqual(parts[0].cents, 992)
        XCTAssertEqual(parts[1].cents, 3_319)
        XCTAssertEqual(MilliMoney.sum(parts).cents, 4_311)
    }

    func testAllocationSingleWeight() {
        let parts = MilliAllocation.split(total: MilliMoney(cents: 555), weights: [milliDecimal("1")])
        XCTAssertEqual(parts, [MilliMoney(cents: 555)])
    }

    // MARK: Mileage deduction

    func testMileageDeduction() {
        // 4,112 business miles × $0.72 (2026 illustrative rate) = 2,960.64
        let d = MilliMileageMath.deduction(miles: 4112, ratePerMile: milliDecimal("0.72"))
        XCTAssertEqual(d.cents, 296_064)
    }

    func testMileageDeductionFractionalMiles() {
        // 24.8 miles × 0.70 = 17.36
        let d = MilliMileageMath.deduction(miles: 24.8, ratePerMile: milliDecimal("0.70"))
        XCTAssertEqual(d.cents, 1_736)
    }

    func testMileageDeductionRoundsHalfAway() {
        // 0.715 miles × 1.00 = 0.715 → 0.72 (half away from zero)
        let d = MilliMileageMath.deduction(miles: 0.715, ratePerMile: milliDecimal("1.00"))
        XCTAssertEqual(d.cents, 72)
    }
}
