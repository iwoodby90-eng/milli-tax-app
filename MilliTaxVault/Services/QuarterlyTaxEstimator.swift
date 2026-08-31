import Foundation

// MARK: - QuarterlyTaxEstimator
// Estimates federal quarterly estimated tax payments for self-employed gig workers.
// Tax year 2026. Sources for all constants:
//   - IRS Revenue Procedure 2025-32 (2026 inflation adjustments, post-TCJA)
//   - SSA: 2026 contribution & benefit base $184,500
//   - Schedule SE (Form 1040): net earnings = 92.35% of net SE profit; $400 floor
//     applies to net earnings AFTER the 92.35% adjustment.
//
// IMPORTANT — scope of this estimate:
//   The quarterly figure is an "estimated current-year liability installment"
//   (total estimated tax / 4). It is NOT an IRS safe-harbor calculation, which
//   requires prior-year total tax (100%/110% rule) — an input this estimator
//   does not take. No safe-harbor compliance is claimed or implied.
//
// MONETARY TYPES (issue #69, financial accuracy):
//   All monetary values and rates are `Decimal`. Intermediates are NEVER
//   rounded; the single explicit rounding boundary is
//   `Estimate.quarterlyPayment`, rounded to exact cents, half away from zero
//   (see `roundToCents`). Rate constants are built from decimal strings, never
//   from `Double` literals, so no binary-to-decimal conversion error can enter
//   the calculation.

/// Exact `Decimal` from a decimal string. Never construct monetary or rate
/// constants from `Double` literals — that conversion is inexact.
private func d(_ string: String) -> Decimal {
    guard let value = Decimal(string: string) else {
        preconditionFailure("Invalid decimal constant: \(string)")
    }
    return value
}

struct QuarterlyTaxEstimator {

    struct Estimate: Equatable {
        let taxableIncome: Decimal        // taxable income AFTER the QBI deduction
        let federalIncomeTax: Decimal
        let selfEmploymentTax: Decimal
        let qbiDeduction: Decimal
        let totalAnnualTax: Decimal
        let quarterlyPayment: Decimal     // estimated current-year liability / 4, exact cents
        let effectiveRate: Decimal
    }

    // MARK: - 2026 constants (Rev. Proc. 2025-32 / SSA)

    /// Sentinel upper bound for the top (unbounded) bracket.
    private static let unbounded = Decimal.greatestFiniteMagnitude

    /// 2026 ordinary-income bracket upper bounds, per filing status.
    private static let brackets: [TaxProfile.FilingStatus: [(upper: Decimal, rate: Decimal)]] = [
        .single: [
            (12_400, d("0.10")), (50_400, d("0.12")), (105_700, d("0.22")), (201_775, d("0.24")),
            (256_225, d("0.32")), (640_600, d("0.35")), (unbounded, d("0.37"))
        ],
        .marriedJoint: [
            (24_800, d("0.10")), (100_800, d("0.12")), (211_400, d("0.22")), (403_550, d("0.24")),
            (512_450, d("0.32")), (768_700, d("0.35")), (unbounded, d("0.37"))
        ],
        .marriedSeparate: [
            (12_400, d("0.10")), (50_400, d("0.12")), (105_700, d("0.22")), (201_775, d("0.24")),
            (256_225, d("0.32")), (384_350, d("0.35")), (unbounded, d("0.37"))
        ],
        .headOfHousehold: [
            (17_700, d("0.10")), (67_450, d("0.12")), (105_700, d("0.22")), (201_775, d("0.24")),
            (256_200, d("0.32")), (640_600, d("0.35")), (unbounded, d("0.37"))
        ]
    ]

    /// 2026 standard deduction, per filing status.
    private static let standardDeductions: [TaxProfile.FilingStatus: Decimal] = [
        .single: 16_100,
        .marriedJoint: 32_200,
        .marriedSeparate: 16_100,
        .headOfHousehold: 24_150
    ]

    private static let seTaxRate = d("0.153")            // 12.4% SS + 2.9% Medicare
    private static let seNetEarningsFactor = d("0.9235") // Schedule SE line 4a
    private static let seNetEarningsFloor: Decimal = d("400")     // applies to net earnings AFTER 92.35%
    private static let ssWageBase: Decimal = d("184500")          // 2026 SSA contribution & benefit base
    private static let ssRate = d("0.124")               // Social Security portion
    private static let medicareRate = d("0.029")         // Medicare portion (no wage cap)
    private static let qbiRate = d("0.20")

    /// - Parameters:
    ///   - grossIncome: total gig/self-employment income for the year (annualized).
    ///   - businessExpenses: deductible business expenses.
    ///   - filingStatus: affects bracket schedule and standard deduction.
    static func estimate(
        grossIncome: Decimal,
        businessExpenses: Decimal = 0,
        filingStatus: TaxProfile.FilingStatus = .single
    ) -> Estimate {
        let netSEProfit = max(0, grossIncome - businessExpenses)

        // Schedule SE: net earnings = 92.35% of net SE profit; the $400 floor
        // applies to net earnings (after the adjustment), not to raw profit.
        let seTax = seTaxOn(netSEProfit)
        let halfSE = seTax / 2

        // AGI approximation: net SE profit minus half of SE tax (above-the-line).
        let agi = max(0, netSEProfit - halfSE)

        let deduction = standardDeductions[filingStatus] ?? 16_100
        let taxableIncome = max(0, agi - deduction)

        // QBI deduction (simplified): 20% of QBI, capped at 20% of taxable
        // income BEFORE the QBI deduction (§199A).
        let qbi = min(netSEProfit * qbiRate, taxableIncome * qbiRate)
        let taxableAfterQBI = max(0, taxableIncome - qbi)

        let incomeTax = federalTax(on: taxableAfterQBI, filingStatus: filingStatus)

        let total = incomeTax + seTax
        // The ONLY rounding boundary in the estimator: the user-facing quarterly
        // payment is exact cents. Every intermediate above stays exact.
        let quarterly = roundToCents(total / 4)
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

    /// SE tax on net SE *profit* (Schedule line 2/3). Returns 0 unless net
    /// earnings (92.35% of profit) exceed the $400 floor. The Social Security
    /// wage base caps the 12.4% portion; Medicare (2.9%) has no cap.
    static func seTaxOn(_ netSEProfit: Decimal) -> Decimal {
        let netEarnings = max(0, netSEProfit) * seNetEarningsFactor
        guard netEarnings > seNetEarningsFloor else { return 0 }
        let ssPortion = min(netEarnings, ssWageBase) * ssRate
        let medicarePortion = netEarnings * medicareRate
        return ssPortion + medicarePortion
    }

    /// Federal ordinary-income tax using the explicit 2026 schedule for the
    /// given filing status.
    static func federalTax(on taxable: Decimal, filingStatus: TaxProfile.FilingStatus) -> Decimal {
        guard taxable > 0 else { return 0 }
        let schedule = brackets[filingStatus] ?? brackets[.single]!
        var tax = Decimal(0)
        var lower = Decimal(0)
        for bracket in schedule {
            let taxedInBracket = min(taxable, bracket.upper) - lower
            if taxedInBracket > 0 { tax += taxedInBracket * bracket.rate }
            lower = bracket.upper
            if taxable <= bracket.upper { break }
        }
        return tax
    }

    /// Rounds a monetary value to exact cents, half away from zero.
    /// This is the single explicit rounding boundary for user-visible payment
    /// values. Banker's rounding (`.bankers`) is deliberately NOT used: tax
    /// payment amounts round half away from zero.
    static func roundToCents(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .plain)
        return output
    }
}
