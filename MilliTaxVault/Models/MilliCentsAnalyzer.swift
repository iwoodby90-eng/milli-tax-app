import Foundation

/// Milli Cents™ offer profitability domain model.
/// Extracted from MilliCentsView so the GO/MAYBE/NO decision logic is
/// testable and versioned independently of presentation. The view renders
/// this; it never re-implements the math.

public struct MilliCentsOfferInput: Equatable, Sendable {
    public var offerAmount: Double
    public var estimatedMiles: Double
    public var deadMiles: Double
    public var returnMiles: Double
    public var gasPricePerGallon: Double
    public var vehicleMpg: Double
    public var effectiveTaxRate: Double

    public init(
        offerAmount: Double,
        estimatedMiles: Double,
        deadMiles: Double,
        returnMiles: Double,
        gasPricePerGallon: Double,
        vehicleMpg: Double,
        effectiveTaxRate: Double
    ) {
        self.offerAmount = offerAmount
        self.estimatedMiles = estimatedMiles
        self.deadMiles = deadMiles
        self.returnMiles = returnMiles
        self.gasPricePerGallon = gasPricePerGallon
        self.vehicleMpg = vehicleMpg
        self.effectiveTaxRate = effectiveTaxRate
    }
}

public enum MilliCentsVerdict: Equatable, Sendable {
    case go
    case maybe
    case skip
}

/// Pure profitability engine. All thresholds are explicit constants so
/// boundary behavior is auditable and test-covered.
public struct MilliCentsAnalyzer: Sendable {

    /// 2026 IRS standard mileage rate (dollars per mile).
    public static let irsMileageRate: Double = 0.67

    /// Portion of the offer treated as taxable after the per-mile expense allowance.
    public static let expenseAllowancePerMile: Double = 0.35

    /// GO requires net profit at or above this floor (dollars).
    public static let goProfitFloor: Double = 18.0
    /// GO requires net profit per mile at or above this floor (dollars/mile).
    public static let goProfitPerMileFloor: Double = 0.50
    /// MAYBE requires net profit at or above this floor (dollars).
    public static let maybeProfitFloor: Double = 8.0
    /// MAYBE requires net profit per mile at or above this floor (dollars/mile).
    public static let maybeProfitPerMileFloor: Double = 0.30

    public let input: MilliCentsOfferInput

    public init(input: MilliCentsOfferInput) {
        self.input = input
    }

    public var totalMiles: Double {
        max(0, input.estimatedMiles) + max(0, input.deadMiles) + max(0, input.returnMiles)
    }

    public var fuelCost: Double {
        guard input.vehicleMpg > 0 else { return 0 }
        return (totalMiles / input.vehicleMpg) * max(0, input.gasPricePerGallon)
    }

    public var irsStandardDeduction: Double {
        totalMiles * Self.irsMileageRate
    }

    public var taxablePortion: Double {
        max(0, input.offerAmount - (totalMiles * Self.expenseAllowancePerMile))
    }

    public var taxImpact: Double {
        taxablePortion * max(0, input.effectiveTaxRate)
    }

    public var netProfit: Double {
        max(0, input.offerAmount - fuelCost - taxImpact)
    }

    public var profitPerMile: Double {
        guard totalMiles > 0 else { return 0 }
        return netProfit / totalMiles
    }

    public var verdict: MilliCentsVerdict {
        if netProfit >= Self.goProfitFloor && profitPerMile >= Self.goProfitPerMileFloor {
            return .go
        } else if netProfit >= Self.maybeProfitFloor && profitPerMile >= Self.maybeProfitPerMileFloor {
            return .maybe
        } else {
            return .skip
        }
    }
}
