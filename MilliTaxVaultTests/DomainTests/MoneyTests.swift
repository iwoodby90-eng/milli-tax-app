import XCTest
@testable import MilliTaxVault

final class MoneyTests: XCTestCase {
    func testDecimalMathEliminatesBinaryFloatingPointArtifact() {
        // In IEEE-754 double precision: 0.1 + 0.2 != 0.3
        let floatSum = 0.1 + 0.2
        XCTAssertNotEqual(floatSum, 0.3)

        // With Milli Money (Foundation.Decimal backing):
        let m1 = Money(double: 0.10)
        let m2 = Money(double: 0.20)
        let mSum = m1 + m2
        XCTAssertEqual(mSum, Money(double: 0.30))
        XCTAssertEqual(mSum.cents, 30)
    }

    func testExactIntegerCentsArithmetic() {
        let m1 = Money(cents: 1500) // $15.00
        let m2 = Money(cents: 245)  // $2.45
        XCTAssertEqual((m1 + m2).cents, 1745)
        XCTAssertEqual((m1 - m2).cents, 1255)
        XCTAssertEqual((m1 * Decimal(2)).cents, 3000)
        XCTAssertEqual((m1 / Decimal(2)).cents, 750)
    }

    func testHalfUpRoundingPolicy() {
        let gross = Money(cents: 312_45) // $312.45
        let taxRate = Decimal(string: "0.23")!
        let tax = (gross * taxRate).rounded(scale: 2, policy: .halfUp)
        XCTAssertEqual(tax.cents, 71_86) // $71.86
    }

    func testFormatting() {
        let m = Money(cents: 1234_56)
        XCTAssertEqual(m.formattedCurrency(), "$1,234.56")
        XCTAssertEqual(m.formattedPlain(scale: 2), "1234.56")
    }

    func testComparableAndCodable() throws {
        let m1 = Money(cents: 100)
        let m2 = Money(cents: 200)
        XCTAssertTrue(m1 < m2)
        XCTAssertTrue(m2 > m1)

        let encoder = JSONEncoder()
        let data = try encoder.encode(m1)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Money.self, from: data)
        XCTAssertEqual(m1, decoded)
    }
}
