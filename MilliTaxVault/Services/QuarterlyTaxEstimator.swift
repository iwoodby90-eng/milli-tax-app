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

struct QuarterlyTaxEstimator {

    struct Estimate: Equatable {
        let taxableIncome: Double        // taxable income AFTER the QBI deduction
        let federalIncomeTax: Double
        let selfEmploymentTax: Double
        let qbiDeduction: Double
        let totalAnnualTax: Double
        let quarterlyPayment: Double     // estimated current-year liability / 4
        let effectiveRate: Double
    }

    // MARK: - 2026 constants (Rev. Proc. 2025-32 / SSA)

    /// 2026 ordinary-income bracket upper bounds, per filing status.
    private static let brackets: [TaxProfile.FilingStatus: [(upper: Double, rate: Double)]] = [
        .single: [
            (12_400, 0.10), (50_400, 0.12), (105_700, 0.22), (201_775, 0.24),
            (256_225, 0.32), (640_600, 0.35), (.infinity, 0.37)
        ],
        .marriedJoint: [
            (24_800, 0.10), (100_800, 0.12), (211_400, 0.22), (403_550, 0.24),
            (512_450, 0.32), (768_700, 0.35), (.infinity, 0.37)
        ],
        .marriedSeparate: [
            (12_400, 0.10), (50_400, 0.12), (105_700, 0.22), (201_775, 0.24),
            (256_225, 0.32), (384_350, 0.35), (.infinity, 0.37)
        ],
        .headOfHousehold: [
            (17_700, 0.10), (67_450, 0.12), (105_700, 0.22), (201_775, 0.24),
            (256_200, 0.32), (640_600, 0.35), (.infinity, 0.37)
        ]
    ]

    /// 2026 standard deduction, per filing status.
    private static let standardDeductions: [TaxProfile.FilingStatus: Double] = [
        .single: 16_100,
        .marriedJoint: 32_200,
        .marriedSeparate: 16_100,
        .headOfHousehold: 24_150
    ]

    private static let seTaxRate = 0.153            // 12.4% SS + 2.9% Medicare
    private static let seNetEarningsFactor = 0.9235 // Schedule SE line 4a
    private static let seNetEarningsFloor = 400.0   // applies to net earnings AFTER 92.35%
    private static let ssWageBase = 184_500.0       // 2026 SSA contribution & benefit base
    private static let qbiRate = 0.20

    /// - Parameters:
    ///   - grossIncome: total gig/self-employment income for the year (annualized).
    ///   - businessExpenses: deductible business expenses.
    ///   - filingStatus: affects bracket schedule and standard deduction.
    static func estimate(
        grossIncome: Double,
        businessExpenses: Double = 0,
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

    /// SE tax on net SE *profit* (Schedule line 2/3). Returns 0 unless net
    /// earnings (92.35% of profit) exceed the $400 floor. The Social Security
    /// wage base caps the 12.4% portion; Medicare (2.9%) has no cap.
    static func seTaxOn(_ netSEProfit: Double) -> Double {
        let netEarnings = max(0, netSEProfit) * seNetEarningsFactor
        guard netEarnings > seNetEarningsFloor else { return 0 }
        let ssPortion = min(netEarnings, ssWageBase) * 0.124
        let medicarePortion = netEarnings * 0.029
        return ssPortion + medicarePortion
    }

    /// Federal ordinary-income tax using the explicit 2026 schedule for the
    /// given filing status.
    static func federalTax(on taxable: Double, filingStatus: TaxProfile.FilingStatus) -> Double {
        guard taxable > 0 else { return 0 }
        let schedule = brackets[filingStatus] ?? brackets[.single]!
        var tax = 0.0
        var lower = 0.0
        for bracket in schedule {
            let taxedInBracket = min(taxable, bracket.upper) - lower
            if taxedInBracket > 0 { tax += taxedInBracket * bracket.rate }
            lower = bracket.upper
            if taxable <= bracket.upper { break }
        }
        return tax
    }
}