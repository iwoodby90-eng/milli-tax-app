import Foundation

// MARK: - Centralized Rounding Policy & Invariant Preserving Allocator
// Strict financial rounding standards:
// - Half-Up (.halfUp / .toNearestOrAwayFromZero): Standard IRS consumer display.
// - Banker's (.bankers / .toNearestOrEven): Standard financial ledger and banking math (IEEE 754-2008).
// - Largest Remainder Method (Hamilton-Hare): Guarantees Sum(Allocations) == Total exactly to the cent.

public enum RoundingPolicy: String, Codable, CaseIterable {
    case halfUp
    case bankers
    case floor
    case ceiling

    public var decimalRoundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .halfUp: return .plain
        case .bankers: return .bankers
        case .floor: return .down
        case .ceiling: return .up
        }
    }
}

public struct MilliRounding {
    // MARK: - Decimal Rounding
    public static func round(decimal: Decimal, scale: Int = 2, policy: RoundingPolicy = .halfUp) -> Decimal {
        var mutableDec = decimal
        var result = Decimal()
        NSDecimalRound(&result, &mutableDec, scale, policy.decimalRoundingMode)
        return result
    }

    // MARK: - Money Rounding
    public static func round(money: Money, scale: Int = 2, policy: RoundingPolicy = .halfUp) -> Money {
        let roundedDec = round(decimal: money.decimalValue, scale: scale, policy: policy)
        return Money(decimal: roundedDec, currency: money.currency)
    }

    // MARK: - Invariant-Preserving Proportional Allocation (Largest Remainder Method)
    /// Allocates a total Money amount across an array of percentage weights (e.g., [0.23, 0.05, 0.03]).
    /// Guarantees that the sum of the returned allocations EQUALS `total` down to the exact cent.
    public static func allocate(
        total: Money,
        percentages: [Decimal],
        policy: RoundingPolicy = .halfUp
    ) -> [Money] {
        guard !percentages.isEmpty else { return [] }
        guard total.cents > 0 else {
            return Array(repeating: Money.zero, count: percentages.count)
        }

        let totalCents = total.cents
        let totalPercent = percentages.reduce(Decimal.zero, +)
        guard totalPercent > Decimal.zero else {
            return Array(repeating: Money.zero, count: percentages.count)
        }

        // Step 1: Calculate raw exact cents and integer floors
        var rawAllocations: [(index: Int, floorCents: Int64, remainder: Decimal)] = []
        var sumFloorCents: Int64 = 0

        for (index, pct) in percentages.enumerated() {
            let normalizedWeight = pct / totalPercent
            let rawCentsDecimal = Decimal(totalCents) * normalizedWeight
            let floorCents = NSDecimalNumber(decimal: round(decimal: rawCentsDecimal, scale: 0, policy: .floor)).int64Value
            let remainder = rawCentsDecimal - Decimal(floorCents)

            rawAllocations.append((index: index, floorCents: floorCents, remainder: remainder))
            sumFloorCents += floorCents
        }

        // Step 2: Distribute leftover cents to largest remainders
        var leftoverCents = totalCents - sumFloorCents
        // Sort by remainder descending
        let sortedByRemainder = rawAllocations.sorted { $0.remainder > $1.remainder }

        var finalCents = Array(repeating: Int64(0), count: percentages.count)
        for item in sortedByRemainder {
            var assigned = item.floorCents
            if leftoverCents > 0 {
                assigned += 1
                leftoverCents -= 1
            }
            finalCents[item.index] = assigned
        }

        return finalCents.map { Money(cents: $0, currency: total.currency) }
    }
}
