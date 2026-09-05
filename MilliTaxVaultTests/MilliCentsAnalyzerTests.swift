import XCTest
@testable import MilliTaxVault

// MARK: - MilliCentsAnalyzerTests
// Phase D: GO/MAYBE/NO boundary and edge-case tests for the extracted
// Milli Cents verdict domain model.

final class MilliCentsAnalyzerTests: XCTestCase {

    private func d(_ s: String) -> Decimal { Decimal(string: s)! }

    // Canonical default input (mirrors the MilliCentsView defaults).
    private var defaultInput: MilliCentsOfferInput {
        MilliCentsOfferInput(
            offerAmount: d("32.64"),
            estimatedMiles: 24.8,
            deadMiles: 6.4,
            returnMiles: 7.2,
            gasPrice: d("3.85"),
            vehicleMpg: 26.0,
            effectiveTaxRate: d("0.25")
        )
    }

    // MARK: - Economics math

    func testDefaultOfferEconomics() {
        let e = MilliCentsAnalyzer.analyze(defaultInput)
        XCTAssertEqual(e.totalMiles, 38.4, accuracy: 0.0001)
        // fuel = (38.4 / 26) * 3.85 (miles are Double; sum carries float epsilon)
        XCTAssertEqual(e.fuelCost, d("5.686154"), accuracy: d("0.0001"))
        // taxable = 32.64 - 38.4*0.35 = 19.20
        XCTAssertEqual(e.taxablePortion, d("19.20"), accuracy: d("0.0001"))
        // tax = 19.20 * 0.25 = 4.80
        XCTAssertEqual(e.taxImpact, d("4.80"), accuracy: d("0.0001"))
        // net = 32.64 - 5.686154 - 4.80 = 22.153846
        XCTAssertEqual(e.netProfit, d("22.153846"), accuracy: d("0.0001"))
        // per mile = 22.153846 / 38.4 = 0.576923
        XCTAssertEqual(e.profitPerMile, d("0.576923"), accuracy: d("0.000001"))
        // GO: net >= 18 and per-mile >= 0.50
        XCTAssertEqual(e.verdict, .go)
    }

    func testIRSStandardDeductionUses2026Rate() {
        let e = MilliCentsAnalyzer.analyze(defaultInput)
        XCTAssertEqual(e.irsStandardDeduction, d("25.728"), accuracy: d("0.0001"))
    }

    // MARK: - GO / MAYBE / NO boundaries (inclusive)

    func testExactGoBoundaryIsGo() {
        // net exactly 18, per-mile exactly 0.50 -> GO (>= is inclusive)
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("18"), profitPerMile: d("0.50")), .go)
    }

    func testJustBelowGoNetProfitIsMaybe() {
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("17.99"), profitPerMile: d("0.50")), .maybe)
    }

    func testJustBelowGoPerMileIsMaybe() {
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("18"), profitPerMile: d("0.499999")), .maybe)
    }

    func testExactMaybeBoundaryIsMaybe() {
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("8"), profitPerMile: d("0.30")), .maybe)
    }

    func testJustBelowMaybeNetProfitIsNo() {
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("7.99"), profitPerMile: d("0.30")), .no)
    }

    func testJustBelowMaybePerMileIsNo() {
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("8"), profitPerMile: d("0.299999")), .no)
    }

    func testHighNetLowPerMileIsNo() {
        // net above GO but per-mile below MAYBE floor: long low-value trip
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("25"), profitPerMile: d("0.10")), .no)
    }

    func testHighPerMileLowNetIsNo() {
        // short trip, great per-mile but tiny absolute profit
        XCTAssertEqual(MilliCentsAnalyzer.verdict(netProfit: d("5"), profitPerMile: d("0.90")), .no)
    }

    // MARK: - Edge cases

    func testZeroMpgYieldsZeroFuelCost() {
        var input = defaultInput
        input.vehicleMpg = 0
        let e = MilliCentsAnalyzer.analyze(input)
        XCTAssertEqual(e.fuelCost, 0)
        // net = 32.64 - 0 - 4.80 = 27.84 -> GO
        XCTAssertEqual(e.verdict, .go)
    }

    func testZeroMilesYieldsZeroProfitPerMileAndNoCrash() {
        let input = MilliCentsOfferInput(
            offerAmount: d("10"),
            estimatedMiles: 0,
            deadMiles: 0,
            returnMiles: 0,
            gasPrice: d("3.85"),
            vehicleMpg: 26,
            effectiveTaxRate: d("0.25")
        )
        let e = MilliCentsAnalyzer.analyze(input)
        XCTAssertEqual(e.totalMiles, 0)
        XCTAssertEqual(e.profitPerMile, 0)
        // net = 10 - 0 - 2.50 = 7.50 -> below MAYBE net floor -> NO
        XCTAssertEqual(e.verdict, .no)
    }

    func testNegativeNetProfitClampsToZero() {
        // huge fuel cost: offer cannot cover it
        var input = defaultInput
        input.gasPrice = d("50")
        let e = MilliCentsAnalyzer.analyze(input)
        XCTAssertEqual(e.netProfit, 0)
        XCTAssertEqual(e.verdict, .no)
    }

    func testTaxablePortionNeverNegative() {
        // tiny offer, many miles: allowance exceeds offer
        let input = MilliCentsOfferInput(
            offerAmount: d("5"),
            estimatedMiles: 40,
            gasPrice: d("3.85"),
            vehicleMpg: 26,
            effectiveTaxRate: d("0.25")
        )
        let e = MilliCentsAnalyzer.analyze(input)
        XCTAssertEqual(e.taxablePortion, 0)
        XCTAssertEqual(e.taxImpact, 0)
    }

    func testZeroTaxRate() {
        var input = defaultInput
        input.effectiveTaxRate = 0
        let e = MilliCentsAnalyzer.analyze(input)
        XCTAssertEqual(e.taxImpact, 0)
        XCTAssertEqual(e.netProfit, d("26.953846"), accuracy: d("0.0001"))
        XCTAssertEqual(e.verdict, .go)
    }

    // MARK: - Verdict labels

    func testVerdictLabels() {
        XCTAssertEqual(MilliCentsVerdict.go.label, "GO")
        XCTAssertEqual(MilliCentsVerdict.maybe.label, "MAYBE")
        XCTAssertEqual(MilliCentsVerdict.no.label, "NO")
    }
}
