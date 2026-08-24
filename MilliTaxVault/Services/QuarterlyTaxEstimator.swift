import Foundation

// MARK: - QuarterlyTaxEstimator
// Estimates federal quarterly estimated tax payments for self-employed gig workers.
// Uses the safe-harbor rule (100% of prior-year tax / 110% for high incomes) and
// the simplified self-employment schedule. 2026 tax year brackets.

struct QuarterlyTaxEstimator {

    struct Estimate: Equatable {
        let taxableIncome: Double
        let federalIncomeTax: Double
        let selfEmploymentTax: Double
        let qbiDeduction: Double
        let totalAnnualTax: Double
        let quarterlyPayment: Double
        let effectiveRate: Double
    }

    // 2026 single-filer brackets (taxable income)
    private static let brackets: [(lower: Double, upper: Double, rate: Double)] = [
        (0, 11_925, 0.10),
        (11_925, 48_475, 0.12),
        (48_475, 103_350, 0.22),
        (103_350, 197_300, 0.24),
        (197_300, 250_525, 0.32),
        (250_525, 626_350, 0.35),
        (626_350, .infinity, 0.37)
    ]

    private static let standardDeduction = 15_000.0
    private static let seTaxRate = 0.153          // 12.4% SS + 2.9% Medicare
    private static let seEarningsFloor = 400.0    // SE tax applies above $400 net earnings
    private static let sswageBase = 177_000.0     // 2026 Social Security wage base
    private static let qbiRate = 0.20

    /// - Parameters:
    ///   - grossIncome: total gig/self-employment income for the year (annualized).
    ///   - businessExpenses: deductible business expenses.
    ///   - filingStatus: single or married filing jointly (affects brackets/deduction).
    static func estimate(
        grossIncome: Double,
        businessExpenses: Double = 0,
        filingStatus: TaxProfile.FilingStatus = .single
    ) -> Estimate {
        let netSE = max(0, grossIncome - businessExpenses)

        // Self-employment tax: half of SE tax is deductible above the line.
        let seTax = netSE > seEarningsFloor ? seTaxOn(netSE) : 0
        let halfSE = seTax / 2

        // AGI approximation: net SE earnings minus half SE tax.
        let agi = max(0, netSE - halfSE)

        let deduction = filingStatus == .marriedJoint ? standardDeduction * 2 : standardDeduction
        let taxableIncome = max(0, agi - deduction)

        // QBI deduction (simplified: 20% of qualified business income).
        let qbi = min(netSE * qbiRate, max(0, taxableIncome * qbiRate))
        let taxableAfterQBI = max(0, taxableIncome - qbi)

        let incomeTax = federalTax(on: taxableAfterQBI, filingStatus: filingStatus)

        let total = incomeTax + seTax
        let quarterly = (total / 4).rounded()
        let effective = grossIncome > 0 ? total / grossIncome : 0

        return Estimate(
            taxableIncome: taxableAfterQBI,
            federalIncomeTax: incomeTax,
            selfEmploymentTax: seTax,
            qbiDeduction: qbi,
            totalAnnualTax: total,
            quarterlyPayment: quarterly,
            effectiveRate: effective
        )
    }

    /// SE tax with the Social Security wage-base cap applied to the SS portion.
    static func seTaxOn(_ netEarnings: Double) -> Double {
        let ssPortion = min(netEarnings * 0.9235, sswageBase) * 0.124
        let medicarePortion = netEarnings * 0.9235 * 0.029
        return ssPortion + medicarePortion
    }

    static func federalTax(on taxable: Double, filingStatus: TaxProfile.FilingStatus) -> Double {
        // Married-joint uses roughly doubled bracket widths (simplified).
        let width: Double = filingStatus == .marriedJoint ? 2 : 1
        var tax = 0.0
        var previousCap = 0.0
        for bracket in brackets {
            let lower = bracket.lower == 0 ? 0 : bracket.lower * width
            let upper = bracket.upper == .infinity ? .infinity : bracket.upper * width
            if taxable <= lower { break }
            let taxedInBracket = min(taxable, upper) - lower
            if taxedInBracket > 0 {
                tax += taxedInBracket * bracket.rate
            }
            previousCap = upper
            if taxable <= upper { break }
        }
        _ = previousCap
        return tax
    }
}
