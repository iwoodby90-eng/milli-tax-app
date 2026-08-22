import XCTest
@testable import MilliTaxVault

final class RoundingPolicyTests: XCTestCase {
    func testHalfUpVersusBankersRounding() {
        // 2.5 rounded to nearest integer:
        // Half-Up: 3.0
        // Banker's: 2.0 (nearest even)
        let dec = Decimal(string: "2.5")!
        let halfUp = MilliRounding.round(decimal: dec, scale: 0, policy: .halfUp)
        let bankers = MilliRounding.round(decimal: dec, scale: 0, policy: .bankers)

        XCTAssertEqual(halfUp, Decimal(3))
        XCTAssertEqual(bankers, Decimal(2))
    }

    func testLargestRemainderMethodPreservesTotalSum() {
        let total = Money(cents: 100_00) // $100.00
        // Three equal 1/3 splits: 33.333...% each
        let percentages: [Decimal] = [
            Decimal(1) / Decimal(3),
            Decimal(1) / Decimal(3),
            Decimal(1) / Decimal(3)
        ]

        let allocations = MilliRounding.allocate(total: total, percentages: percentages)
        XCTAssertEqual(allocations.count, 3)

        let sum = allocations.reduce(Money.zero, +)
        XCTAssertEqual(sum, total) // Exactly $100.00, no lost penny ($33.34 + $33.33 + $33.33)
        XCTAssertEqual(allocations[0].cents, 33_34)
        XCTAssertEqual(allocations[1].cents, 33_33)
        XCTAssertEqual(allocations[2].cents, 33_33)
    }

    func testRandomizedLargestRemainderInvariants() {
        // Run 1000 randomized iterations
        for _ in 0..<1000 {
            let randomCents = Int64.random(in: 1...100_000_00)
            let total = Money(cents: randomCents)

            let p1 = Decimal(Double.random(in: 0.1...0.4))
            let p2 = Decimal(Double.random(in: 0.1...0.3))
            let p3 = Decimal(Double.random(in: 0.05...0.2))

            let allocations = MilliRounding.allocate(total: total, percentages: [p1, p2, p3])
            let sum = allocations.reduce(Money.zero, +)
            XCTAssertEqual(sum, total, "Allocation sum must equal total exactly for total: \(total)")
        }
    }
}
