import XCTest
@testable import MilliTaxVault

// MARK: - ReceiptTextParserTests
// The parser turns OCR lines into merchant/total/date. Anything it cannot read
// must come back nil so the user is asked rather than given an invented value.

final class ReceiptTextParserTests: XCTestCase {
    private let reference = Date(timeIntervalSince1970: 1_760_000_000)

    func testReadsMerchantTotalAndDateFromLabelledReceipt() {
        let lines = [
            "SHELL STATION #4821",
            "1420 W Lake St",
            "Chicago, IL",
            "09/14/2025  14:32",
            "Unleaded 12.004 gal",
            "Subtotal      44.10",
            "Tax            3.85",
            "TOTAL         47.95"
        ]

        let scan = ReceiptTextParser.parse(lines: lines, referenceDate: reference)

        XCTAssertEqual(scan.merchant, "Shell Station")
        XCTAssertEqual(scan.amount, 47.95)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: try XCTUnwrap(scan.date))
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 14)
    }

    func testPrefersLabelledTotalOverLargerLineItem() {
        let lines = [
            "Auto Parts Depot",
            "Brake kit            120.00",
            "Discount             -30.00",
            "Total                 90.00"
        ]

        XCTAssertEqual(ReceiptTextParser.parse(lines: lines, referenceDate: reference).amount, 90.00)
    }

    func testReadsTotalPrintedOnTheFollowingLine() {
        let lines = ["City Parking", "Amount Due", "24.60"]

        XCTAssertEqual(ReceiptTextParser.parse(lines: lines, referenceDate: reference).amount, 24.60)
    }

    func testFallsBackToLargestAmountWhenNoTotalLabel() {
        let lines = ["Corner Market", "Coffee 4.25", "Sandwich 9.75"]

        XCTAssertEqual(ReceiptTextParser.parse(lines: lines, referenceDate: reference).amount, 9.75)
    }

    func testReturnsNilRatherThanGuessingOnUnreadableText() {
        let scan = ReceiptTextParser.parse(lines: ["", "   ", "#####"], referenceDate: reference)

        XCTAssertNil(scan.merchant)
        XCTAssertNil(scan.amount)
        XCTAssertNil(scan.date)
    }

    func testIgnoresDatesInTheFutureOrLongPast() {
        let lines = ["Fuel Stop", "Printed 01/01/2099", "Total 10.00"]

        XCTAssertNil(ReceiptTextParser.parse(lines: lines, referenceDate: reference).date)
    }

    func testSkipsAmountAndAddressLinesWhenPickingMerchant() {
        let lines = ["47.95", "1420 W Lake St", "Blue Line Diner", "Total 47.95"]

        XCTAssertEqual(ReceiptTextParser.parse(lines: lines, referenceDate: reference).merchant, "Blue Line Diner")
    }

    func testAttachingKeepsParsedValues() {
        let scan = ReceiptTextParser.parse(lines: ["Fuel Stop", "Total 12.00"], referenceDate: reference)
        let attached = ReceiptTextParser.attaching("abc.jpg", to: scan)

        XCTAssertEqual(attached.imageFilename, "abc.jpg")
        XCTAssertEqual(attached.merchant, scan.merchant)
        XCTAssertEqual(attached.amount, scan.amount)
    }
}
