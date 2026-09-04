import XCTest
@testable import MilliTaxVault

/// Boundary and edge-case coverage for the Milli Cents profitability model.
final class MilliCentsAnalyzerTests: XCTestCase {

    private func input(
        amount: Double = 32.64,
        estimated: Double = 24.8,
        dead: Double = 6.4,
        ret: Double = 7.2,
        gas: Double = 3.85,
        mpg: Double = 26.0,
        taxRate: Double = 0.25
    ) -> MilliCentsOfferInput {
        MilliCentsOfferInput(
            offerAmount: amount,
            estimatedMiles: estimated,
            deadMiles: dead,
            returnMiles: ret,
            gasPricePerGallon: gas,
            vehicleMpg: mpg,
            effectiveTaxRate: taxRate
        )
    }

    // MARK: - Reference case parity

    func testReferenceCaseMatchesLegacyViewMath() {
        let analyzer = MilliCentsAnalyzer(input: input())
        // Legacy view values for the default inputs.
        XCTAssertEqual(analyzer.totalMiles, 38.4, accuracy: 0.0001)
        XCTAssertEqual(analyzer.fuelCost, 38.4 / 26.0 * 3.85, accuracy: 0.0001)
        XCTAssertEqual(analyzer.irsStandardDeduction, 38.4 * 0.67, accuracy: 0.0001)
        XCTAssertEqual(analyzer.taxablePortion, max(0, 32.64 - 38.4 * 0.35), accuracy: 0.0001)
        XCTAssertEqual(analyzer.netProfit, max(0, 32.64 - (38.4 / 26.0 * 3.85) - max(0, 32.64 - 38.4 * 0.35) * 0.25), accuracy: 0.0001)
    }

    // MARK: - Verdict boundaries

    private func verdictAt(netProfitTarget: Double, perMileTarget: Double) -> MilliCentsVerdict {
        // Construct an input whose netProfit and profitPerMile land exactly on
        // the given targets: zero fuel (huge mpg), zero tax, miles chosen so
        // profitPerMile = netProfit / totalMiles hits the target.
        let miles = netProfitTarget / perMileTarget
        let a = MilliCentsAnalyzer(input: input(amount: netProfitTarget, estimated: miles, dead: 0, ret: 0, gas: 0, mpg: 1000, taxRate: 0))
        XCTAssertEqual(a.netProfit, netProfitTarget, accuracy: 0.0001)
        XCTAssertEqual(a.profitPerMile, perMileTarget, accuracy: 0.0001)
        return a.verdict
    }

    func testGOBoundaryExactlyAtThresholdsIsGO() {
        XCTAssertEqual(verdictAt(netProfitTarget: 18.0, perMileTarget: 0.50), .go)
    }

    func testGOBoundaryJustBelowProfitFloorIsNotGO() {
        XCTAssertEqual(verdictAt(netProfitTarget: 17.999, perMileTarget: 0.50), .maybe)
    }

    func testGOBoundaryJustBelowPerMileFloorIsNotGO() {
        XCTAssertEqual(verdictAt(netProfitTarget: 18.0, perMileTarget: 0.4999), .maybe)
    }

    func testMAYBEBoundaryExactlyAtThresholdsIsMAYBE() {
        XCTAssertEqual(verdictAt(netProfitTarget: 8.0, perMileTarget: 0.30), .maybe)
    }

    func testMAYBEBoundaryJustBelowProfitFloorIsSKIP() {
        XCTAssertEqual(verdictAt(netProfitTarget: 7.999, perMileTarget: 0.30), .skip)
    }

    func testMAYBEBoundaryJustBelowPerMileFloorIsSKIP() {
        XCTAssertEqual(verdictAt(netProfitTarget: 8.0, perMileTarget: 0.2999), .skip)
    }

    func testHighProfitLowPerMileIsNotGO() {
        // Long block: plenty of profit, poor $/mi.
        // 92 net over 200 total miles = $0.46/mi: plenty of profit, poor $/mi.
        let a = MilliCentsAnalyzer(input: input(amount: 92.0, estimated: 180.0, dead: 10.0, ret: 10.0, gas: 0, mpg: 1000, taxRate: 0))
        XCTAssertGreaterThanOrEqual(a.netProfit, 18.0)
        XCTAssertLessThan(a.profitPerMile, 0.50)
        XCTAssertEqual(a.verdict, .maybe)
    }

    // MARK: - Edge cases

    func testZeroMilesYieldsZeroPerMileAndSKIP() {
        let a = MilliCentsAnalyzer(input: input(amount: 50, estimated: 0, dead: 0, ret: 0))
        XCTAssertEqual(a.totalMiles, 0)
        XCTAssertEqual(a.profitPerMile, 0)
        XCTAssertEqual(a.verdict, .skip)
    }

    func testZeroOfferIsSKIP() {
        XCTAssertEqual(MilliCentsAnalyzer(input: input(amount: 0)).verdict, .skip)
    }

    func testNegativeMilesAreClamped() {
        let a = MilliCentsAnalyzer(input: input(amount: 30, estimated: -10, dead: -5, ret: -2))
        XCTAssertEqual(a.totalMiles, 0)
    }

    func testZeroMpgMeansZeroFuelCost() {
        let a = MilliCentsAnalyzer(input: input(amount: 30, mpg: 0))
        XCTAssertEqual(a.fuelCost, 0)
    }

    func testNegativeGasPriceIsClamped() {
        let a = MilliCentsAnalyzer(input: input(amount: 30, gas: -2))
        XCTAssertEqual(a.fuelCost, 0)
    }

    func testNegativeTaxRateIsClamped() {
        let a = MilliCentsAnalyzer(input: input(amount: 30, taxRate: -0.5))
        XCTAssertEqual(a.taxImpact, 0)
    }

    func testTaxablePortionNeverNegative() {
        // Offer smaller than the per-mile expense allowance.
        let a = MilliCentsAnalyzer(input: input(amount: 5, estimated: 40, dead: 0, ret: 0))
        XCTAssertEqual(a.taxablePortion, 0)
        XCTAssertEqual(a.taxImpact, 0)
    }

    func testNetProfitNeverNegative() {
        // Fuel + tax exceed the offer.
        let a = MilliCentsAnalyzer(input: input(amount: 1, estimated: 100, dead: 100, ret: 100, gas: 6, mpg: 5, taxRate: 0.9))
        XCTAssertEqual(a.netProfit, 0)
        XCTAssertEqual(a.verdict, .skip)
    }

    func testIRSRateConstant() {
        XCTAssertEqual(MilliCentsAnalyzer.irsMileageRate, 0.67)
    }
}
