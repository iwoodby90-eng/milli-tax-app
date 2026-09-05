import Foundation

// MARK: - MilliCentsAnalyzer
// Phase D (financial domain remediation): the Milli Cents offer-verdict logic
// extracted from MilliCentsView into a pure, tested domain model.
// The view layer renders; this model decides. No SwiftUI, no UI state.
//
// MONETARY TYPES: all money is Decimal (issue #69 standard). Miles and MPG
// stay Double (physical quantities, not currency). Rounding happens only at
// the presentation boundary via roundToCents.

/// Verdict for a gig offer. Boundaries are inclusive on the GO and MAYBE
/// thresholds (>=), matching the historical MilliCentsView behavior.
enum MilliCentsVerdict: Equatable, Sendable {
    case go
    case maybe
    case no

    var label: String {
        switch self {
        case .go: return "GO"
        case .maybe: return "MAYBE"
        case .no: return "NO"
        }
    }
}

/// Pure offer-economics input. All monetary fields are Decimal.
struct MilliCentsOfferInput: Equatable, Sendable {
    var offerAmount: Decimal
    var estimatedMiles: Double
    var deadMiles: Double
    var returnMiles: Double
    var gasPrice: Decimal
    var vehicleMpg: Double
    var effectiveTaxRate: Decimal

    init(
        offerAmount: Decimal,
        estimatedMiles: Double,
        deadMiles: Double = 0,
        returnMiles: Double = 0,
        gasPrice: Decimal,
        vehicleMpg: Double,
        effectiveTaxRate: Decimal
    ) {
        self.offerAmount = offerAmount
        self.estimatedMiles = estimatedMiles
        self.deadMiles = deadMiles
        self.returnMiles = returnMiles
        self.gasPrice = gasPrice
        self.vehicleMpg = vehicleMpg
        self.effectiveTaxRate = effectiveTaxRate
    }
}

/// Computed offer economics. Monetary outputs are Decimal, unrounded
/// intermediates; the verdict uses exact values.
struct MilliCentsEconomics: Equatable, Sendable {
    let totalMiles: Double
    let fuelCost: Decimal
    let irsStandardDeduction: Decimal
    let taxablePortion: Decimal
    let taxImpact: Decimal
    let netProfit: Decimal
    let profitPerMile: Decimal
    let verdict: MilliCentsVerdict
}

/// The Milli Cents verdict engine. Thresholds are the product's canonical
/// decision boundaries; they are constants here so tests can pin them.
enum MilliCentsAnalyzer {

    /// 2026 IRS standard mileage rate.
    static let standardMileageRate = Decimal(string: "0.67")!

    /// Per-mile standard-cost allowance subtracted before tax
    /// (historical MilliCentsView behavior preserved).
    static let perMileCostAllowance = Decimal(string: "0.35")!

    // Verdict thresholds (inclusive).
    static let goNetProfit: Decimal = 18
    static let goProfitPerMile: Decimal = Decimal(string: "0.50")!
    static let maybeNetProfit: Decimal = 8
    static let maybeProfitPerMile: Decimal = Decimal(string: "0.30")!

    /// Full economics for an offer input.
    static func analyze(_ input: MilliCentsOfferInput) -> MilliCentsEconomics {
        let totalMiles = input.estimatedMiles + input.deadMiles + input.returnMiles

        let fuelCost: Decimal
        if input.vehicleMpg > 0 {
            fuelCost = Decimal(totalMiles / input.vehicleMpg) * input.gasPrice
        } else {
            fuelCost = 0
        }

        let milesDecimal = Decimal(totalMiles)
        let irsStandardDeduction = milesDecimal * standardMileageRate
        let taxablePortion = max(Decimal(0), input.offerAmount - milesDecimal * perMileCostAllowance)
        let taxImpact = taxablePortion * input.effectiveTaxRate
        let netProfit = max(Decimal(0), input.offerAmount - fuelCost - taxImpact)
        let profitPerMile: Decimal = totalMiles > 0 ? netProfit / milesDecimal : 0

        return MilliCentsEconomics(
            totalMiles: totalMiles,
            fuelCost: fuelCost,
            irsStandardDeduction: irsStandardDeduction,
            taxablePortion: taxablePortion,
            taxImpact: taxImpact,
            netProfit: netProfit,
            profitPerMile: profitPerMile,
            verdict: verdict(netProfit: netProfit, profitPerMile: profitPerMile)
        )
    }

    /// Verdict only, from precomputed economics.
    static func verdict(netProfit: Decimal, profitPerMile: Decimal) -> MilliCentsVerdict {
        if netProfit >= goNetProfit && profitPerMile >= goProfitPerMile {
            return .go
        } else if netProfit >= maybeNetProfit && profitPerMile >= maybeProfitPerMile {
            return .maybe
        } else {
            return .no
        }
    }
}
