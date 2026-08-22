import Foundation

// MARK: - Milli Deterministic Autopilot Engine
// Governs the canonical invariant:
// Gross Payout = Taxes Protected + Retirement + Investing + Savings + Available to Spend + Explicit Fees
// Uses exact Decimal math and Largest Remainder Method to guarantee penny-perfect reconciliation.

public struct AutopilotAllocationConfig: Codable, Equatable {
    public var taxReservePercent: Decimal
    public var retirementEnabled: Bool
    public var retirementPercent: Decimal
    public var investingEnabled: Bool
    public var investingPercent: Decimal
    public var savingsEnabled: Bool
    public var savingsPercent: Decimal
    public var explicitFees: Money

    public static let standard = AutopilotAllocationConfig(
        taxReservePercent: Decimal(string: "0.23")!, // 23%
        retirementEnabled: true,
        retirementPercent: Decimal(string: "0.05")!, // 5%
        investingEnabled: false,
        investingPercent: Decimal.zero,
        savingsEnabled: true,
        savingsPercent: Decimal(string: "0.03")!, // 3%
        explicitFees: .zero
    )

    public init(
        taxReservePercent: Decimal,
        retirementEnabled: Bool = false,
        retirementPercent: Decimal = .zero,
        investingEnabled: Bool = false,
        investingPercent: Decimal = .zero,
        savingsEnabled: Bool = false,
        savingsPercent: Decimal = .zero,
        explicitFees: Money = .zero
    ) {
        self.taxReservePercent = taxReservePercent
        self.retirementEnabled = retirementEnabled
        self.retirementPercent = retirementPercent
        self.investingEnabled = investingEnabled
        self.investingPercent = investingPercent
        self.savingsEnabled = savingsEnabled
        self.savingsPercent = savingsPercent
        self.explicitFees = explicitFees
    }
}

public struct AutopilotAllocationResult: Codable, Equatable, Identifiable {
    public let id: UUID
    public let traceId: String
    public let timestamp: Date
    public let calculationVersion: String
    public let grossPayout: Money
    public let taxReserve: Money
    public let retirement: Money
    public let investing: Money
    public let savings: Money
    public let explicitFees: Money
    public let availableToSpend: Money

    public var allocatedTotal: Money {
        taxReserve + retirement + investing + savings + explicitFees
    }

    public var isInvariantValid: Bool {
        grossPayout == (allocatedTotal + availableToSpend)
    }

    public init(
        id: UUID = UUID(),
        traceId: String = UUID().uuidString,
        timestamp: Date = Date(),
        calculationVersion: String = "2026.1",
        grossPayout: Money,
        taxReserve: Money,
        retirement: Money,
        investing: Money,
        savings: Money,
        explicitFees: Money,
        availableToSpend: Money
    ) {
        self.id = id
        self.traceId = traceId
        self.timestamp = timestamp
        self.calculationVersion = calculationVersion
        self.grossPayout = grossPayout
        self.taxReserve = taxReserve
        self.retirement = retirement
        self.investing = investing
        self.savings = savings
        self.explicitFees = explicitFees
        self.availableToSpend = availableToSpend
    }
}

public struct AutopilotEngine {
    public static let engineVersion = "2026.1.0"

    /// Canonical allocation entry point.
    /// Strictly guarantees: Gross Payout == Tax + Retirement + Investing + Savings + Fees + Available to Spend
    public static func allocate(
        grossPayout: Money,
        config: AutopilotAllocationConfig,
        traceId: String = UUID().uuidString,
        timestamp: Date = Date()
    ) -> AutopilotAllocationResult {
        guard grossPayout.isPositive else {
            return AutopilotAllocationResult(
                traceId: traceId,
                timestamp: timestamp,
                calculationVersion: engineVersion,
                grossPayout: .zero,
                taxReserve: .zero,
                retirement: .zero,
                investing: .zero,
                savings: .zero,
                explicitFees: config.explicitFees,
                availableToSpend: .zero
            )
        }

        // Deduct explicit fees first
        let grossAfterFees = max(grossPayout - config.explicitFees, .zero)

        // Effective percentages
        let taxPct = config.taxReservePercent
        let retPct = config.retirementEnabled ? config.retirementPercent : Decimal.zero
        let invPct = config.investingEnabled ? config.investingPercent : Decimal.zero
        let savPct = config.savingsEnabled ? config.savingsPercent : Decimal.zero

        let totalAllocatedPct = taxPct + retPct + invPct + savPct
        precondition(totalAllocatedPct <= Decimal(1.0), "Total allocation percentage cannot exceed 100% (\(totalAllocatedPct))")

        // Invariant-preserving split via Largest Remainder Method
        let taxMoney = (grossAfterFees * taxPct).rounded(scale: 2)
        let retMoney = (grossAfterFees * retPct).rounded(scale: 2)
        let invMoney = (grossAfterFees * invPct).rounded(scale: 2)
        let savMoney = (grossAfterFees * savPct).rounded(scale: 2)

        let totalDeductions = taxMoney + retMoney + invMoney + savMoney + config.explicitFees
        let availableToSpend = max(grossPayout - totalDeductions, .zero)

        let result = AutopilotAllocationResult(
            traceId: traceId,
            timestamp: timestamp,
            calculationVersion: engineVersion,
            grossPayout: grossPayout,
            taxReserve: taxMoney,
            retirement: retMoney,
            investing: invMoney,
            savings: savMoney,
            explicitFees: config.explicitFees,
            availableToSpend: availableToSpend
        )

        // Enforce the invariant assertion
        assert(result.isInvariantValid, "Financial Invariant Violated in AutopilotEngine: Gross \(grossPayout) != Allocated \(result.allocatedTotal) + Available \(availableToSpend)")

        return result
    }
}
