import Foundation

// MARK: - MilliMoney
// Canonical currency-safe money type for MILLI (issue #69 closeout).
//
// Rules (mirrors QuarterlyTaxEstimator's Decimal policy):
//   - All monetary values are stored as exact integer cents (Int64).
//   - Conversion from user/provider input goes through `Decimal` string parsing,
//     never through `Double`, so no binary-to-decimal error can enter.
//   - The single rounding boundary is `rounded(toCents:)`: half away from zero,
//     matching Decimal behavior of QuarterlyTaxEstimator.roundToCents.
//   - Pro-rata allocation distributes a total exactly across weights with a
//     largest-remainder rule: the sum of parts ALWAYS equals the total.

/// Exact `Decimal` from a decimal string. Never construct monetary or rate
/// constants from `Double` literals — that conversion is inexact.
public func milliDecimal(_ string: String) -> Decimal {
    guard let value = Decimal(string: string) else {
        preconditionFailure("Invalid decimal constant: \(string)")
    }
    return value
}

public struct MilliMoney: Equatable, Hashable, Sendable {
    /// Exact value in integer cents. Negative allowed (debits).
    public let cents: Int64

    public init(cents: Int64) { self.cents = cents }

    /// Parse from a decimal string such as "5284.17". Returns nil on malformed input.
    public init?(string: String) {
        guard let value = Decimal(string: string) else { return nil }
        self.init(decimal: value)
    }

    /// Convert an exact `Decimal` amount to cents, rounding half away from zero.
    public init(decimal: Decimal) {
        var value = decimal * 100
        var rounded = Decimal()
        _ = NSDecimalRound(&rounded, &value, 0, .plain)
        // half-away-from-zero for negatives:
        if rounded < 0 && (value < rounded) { rounded -= 1 }
        self.cents = Int64(rounded as NSDecimalNumber).int64Value
    }

    public static let zero = MilliMoney(cents: 0)

    public var decimal: Decimal { Decimal(cents) / 100 }

    public var isZero: Bool { cents == 0 }

    // MARK: Arithmetic (exact, no rounding — already integer cents)

    public static func + (lhs: MilliMoney, rhs: MilliMoney) -> MilliMoney {
        MilliMoney(cents: lhs.cents + rhs.cents)
    }
    public static func - (lhs: MilliMoney, rhs: MilliMoney) -> MilliMoney {
        MilliMoney(cents: lhs.cents - rhs.cents)
    }
    public prefix static func - (value: MilliMoney) -> MilliMoney {
        MilliMoney(cents: -value.cents)
    }

    /// Exact multiplication by a Decimal factor, rounded once to cents.
    public func multiplied(by factor: Decimal) -> MilliMoney {
        MilliMoney(decimal: decimal * factor)
    }

    /// Sum of a collection. Exact.
    public static func sum(_ values: some Sequence<MilliMoney>) -> MilliMoney {
        values.reduce(.zero, +)
    }

    // MARK: Formatting

    /// "1,234.56" style plain formatting (no currency symbol).
    public var plain: String {
        let negative = cents < 0
        let magnitude = cents < 0 ? -cents : cents
        let units = magnitude / 100
        let rem = magnitude % 100
        let grouped = NumberFormatter()
        grouped.groupingSeparator = ","
        grouped.usesGroupingSeparator = true
        let unitsText = grouped.string(from: NSNumber(value: units)) ?? "\(units)"
        return "\(negative ? "-" : "")\(unitsText).\(String(format: "%02d", rem))"
    }

    /// USD display string, e.g. "$1,234.56".
    public var usd: String { "$\(plain)" }
}

// MARK: - Rounding boundary

extension Decimal {
    /// Round to exact cents, half away from zero. The single rounding boundary.
    public static func milliRoundedToCents(_ value: Decimal) -> Decimal {
        var scaled = value * 100
        var rounded = Decimal()
        _ = NSDecimalRound(&rounded, &scaled, 0, .plain)
        if rounded > 0 && scaled > rounded { rounded += 1 }
        if rounded < 0 && scaled < rounded { rounded -= 1 }
        return rounded / 100
    }
}

// MARK: - Pro-rata allocation

public enum MilliAllocation {

    /// Split `total` across `weights` proportionally, in exact cents.
    /// Largest-remainder rule guarantees `parts.sum() == total` exactly.
    /// Weights must be non-negative and not all zero.
    public static func split(total: MilliMoney, weights: [Decimal]) -> [MilliMoney] {
        precondition(!weights.isEmpty, "weights must not be empty")
        precondition(weights.allSatisfy { $0 >= 0 }, "weights must be non-negative")
        let weightSum = weights.reduce(Decimal.zero, +)
        precondition(weightSum > 0, "weights must not all be zero")

        if weights.count == 1 { return [total] }

        // Floor each share, then distribute the remainder to the largest fractional parts.
        var floors: [Int64] = []
        var remainders: [(index: Int, fraction: Decimal)] = []
        for weight in weights {
            let exact = total.decimal * (weight / weightSum)
            var scaled = exact * 100
            var floored = Decimal()
            _ = NSDecimalRound(&floored, &scaled, 0, .down)
            floors.append(Int64(floored as NSDecimalNumber).int64Value)
            remainders.append((floors.count - 1, scaled - floored))
        }
        var remainderCents = total.cents - floors.reduce(0, +)
        // Largest remainder first; ties break toward the earlier index.
        remainders.sort { $0.fraction > $1.fraction }
        var i = 0
        while remainderCents > 0 && i < remainders.count {
            floors[remainders[i].index] += remainderCents > 0 ? 1 : -1
            remainderCents -= 1
            i += 1
        }
        i = 0
        while remainderCents < 0 && i < remainders.count {
            floors[remainders[i].index] -= 1
            remainderCents += 1
            i += 1
        }
        return floors.map { MilliMoney(cents: $0) }
    }
}

// MARK: - Mileage deduction (currency output)

public enum MilliMileageMath {
    /// Business mileage deduction: miles (Double, GPS-sourced) × rate (Decimal).
    /// Rounded once, half away from zero, to exact cents.
    public static func deduction(miles: Double, ratePerMile: Decimal) -> MilliMoney {
        let milesDecimal = Decimal(string: String(format: "%.4f", miles)) ?? Decimal(miles)
        return MilliMoney(decimal: milesDecimal * ratePerMile)
    }
}
