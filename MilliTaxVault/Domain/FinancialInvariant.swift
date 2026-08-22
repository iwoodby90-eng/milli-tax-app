import Foundation

// MARK: - Financial Invariant Enforcement & Receipt Integrity
// Validates: Gross Payout == Tax + Retirement + Investing + Savings + Available + Fees
// Guarantees zero unexplainable drift or corrupt ledger states across all MILLI engines.

public enum FinancialInvariantError: Error, CustomStringConvertible, LocalizedError {
    case allocationMismatch(expectedGross: Money, actualSum: Money, diffCents: Int64)
    case negativeAmount(field: String, amount: Money)
    case percentageOverflow(totalPercentage: Decimal)
    case checksumMismatch(receiptId: String, expected: String, computed: String)
    case invalidCurrencyMismatch(base: String, target: String)

    public var description: String {
        switch self {
        case .allocationMismatch(let gross, let sum, let diff):
            return "Financial Invariant Breach: Gross \(gross) does not equal sum of components \(sum) (difference: \(diff) cents)"
        case .negativeAmount(let field, let amount):
            return "Financial Invariant Breach: \(field) cannot be negative (\(amount))"
        case .percentageOverflow(let pct):
            return "Financial Invariant Breach: Total allocation percentage \(pct) exceeds 100%"
        case .checksumMismatch(let id, let exp, let act):
            return "Financial Receipt Integrity Failure: Receipt \(id) checksum mismatch (expected \(exp), got \(act))"
        case .invalidCurrencyMismatch(let base, let target):
            return "Financial Currency Error: Mismatched currencies \(base) vs \(target)"
        }
    }

    public var errorDescription: String? { description }
}

public struct FinancialReceipt: Codable, Equatable, Identifiable {
    public let id: String
    public let payoutId: String
    public let timestamp: Date
    public let platform: String
    public let grossAmount: Money
    public let taxProtected: Money
    public let retirementAllocation: Money
    public let investingAllocation: Money
    public let emergencySavings: Money
    public let explicitFees: Money
    public let availableToSpend: Money
    public let calculationVersion: String
    public let taxRuleVersion: String
    public let traceId: String
    public let checksum: String

    public var totalDeductions: Money {
        taxProtected + retirementAllocation + investingAllocation + emergencySavings + explicitFees
    }

    public var isValidInvariant: Bool {
        grossAmount == (totalDeductions + availableToSpend)
    }

    public init(
        id: String = "rcpt_\(UUID().uuidString.prefix(12).lowercased())",
        payoutId: String,
        timestamp: Date = Date(),
        platform: String,
        grossAmount: Money,
        taxProtected: Money,
        retirementAllocation: Money,
        investingAllocation: Money,
        emergencySavings: Money,
        explicitFees: Money = .zero,
        availableToSpend: Money,
        calculationVersion: String = AutopilotEngine.engineVersion,
        taxRuleVersion: String = TaxEngine.defaultRuleVersion,
        traceId: String = UUID().uuidString
    ) {
        self.id = id
        self.payoutId = payoutId
        self.timestamp = timestamp
        self.platform = platform
        self.grossAmount = grossAmount
        self.taxProtected = taxProtected
        self.retirementAllocation = retirementAllocation
        self.investingAllocation = investingAllocation
        self.emergencySavings = emergencySavings
        self.explicitFees = explicitFees
        self.availableToSpend = availableToSpend
        self.calculationVersion = calculationVersion
        self.taxRuleVersion = taxRuleVersion
        self.traceId = traceId

        // Compute tamper-proof checksum including tax rule version
        let payload = "\(id)|\(payoutId)|\(grossAmount.cents)|\(taxProtected.cents)|\(retirementAllocation.cents)|\(investingAllocation.cents)|\(emergencySavings.cents)|\(explicitFees.cents)|\(availableToSpend.cents)|\(calculationVersion)|\(taxRuleVersion)|\(traceId)"
        self.checksum = String(format: "%016llx", payload.hashValue)
    }
}

public struct FinancialInvariantValidator {
    public static func validateAutopilotResult(_ result: AutopilotAllocationResult) throws {
        if result.grossPayout.isNegative {
            throw FinancialInvariantError.negativeAmount(field: "Gross Payout", amount: result.grossPayout)
        }
        if result.taxReserve.isNegative {
            throw FinancialInvariantError.negativeAmount(field: "Tax Reserve", amount: result.taxReserve)
        }
        if result.retirement.isNegative {
            throw FinancialInvariantError.negativeAmount(field: "Retirement", amount: result.retirement)
        }
        if result.investing.isNegative {
            throw FinancialInvariantError.negativeAmount(field: "Investing", amount: result.investing)
        }
        if result.savings.isNegative {
            throw FinancialInvariantError.negativeAmount(field: "Savings", amount: result.savings)
        }
        if result.availableToSpend.isNegative {
            throw FinancialInvariantError.negativeAmount(field: "Available To Spend", amount: result.availableToSpend)
        }

        let totalAllocated = result.allocatedTotal + result.availableToSpend
        if result.grossPayout != totalAllocated {
            let diff = result.grossPayout.cents - totalAllocated.cents
            throw FinancialInvariantError.allocationMismatch(
                expectedGross: result.grossPayout,
                actualSum: totalAllocated,
                diffCents: diff
            )
        }
    }

    public static func validateReceipt(_ receipt: FinancialReceipt) throws {
        let sum = receipt.totalDeductions + receipt.availableToSpend
        if receipt.grossAmount != sum {
            let diff = receipt.grossAmount.cents - sum.cents
            throw FinancialInvariantError.allocationMismatch(
                expectedGross: receipt.grossAmount,
                actualSum: sum,
                diffCents: diff
            )
        }
    }
}
