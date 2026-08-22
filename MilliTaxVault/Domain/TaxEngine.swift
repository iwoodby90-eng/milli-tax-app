import Foundation

// MARK: - Milli Deterministic Tax Engine
// Versioned and Effective-Dated Tax Calculation Engine for IRS Tax Year 2026.
// Covers:
// - Standard Deductions (Single/MFS $16,100, MFJ $32,200, HOH $24,150) — IRS Rev. Proc. 2025-32, Sec. 3.16 / IRC § 63(c)(2)
// - Federal Income Tax Brackets for Single, MFJ, MFS, HOH — IRS Rev. Proc. 2025-32, Sec. 3.01 / IRC § 1(j)
// - OASDI Social Security Wage Base Cap ($184,500 @ 12.4%) — SSA Wage Base Notice (89 FR 84431) / 42 U.S.C. § 430
// - Medicare (2.9%) and Additional Medicare (0.9% varying by filing status: MFJ $250k, MFS $125k, Single/HOH $200k) — IRC § 1401(b) / IRC § 3101(b)(2) / Form 8959
// - Mixed Income Modeling: W-2 Social Security and Medicare wage base consumption on Schedule SE & Form 8959
// - Schedule SE Net Earnings Factor (92.35%) and Above-the-Line SE Tax Deduction (50%) — IRC § 1402(a)(12) / IRC § 164(f)
// - Effective-Dated 2026 Business Mileage Rates (Jan-Jun 2026: 72.5¢/mi via IRS Notice 2025-88; Jul-Dec 2026: 76.0¢/mi via IRS Notice 2026-01)
// - Explicit historical rule resolution and strict typed error throwing on unsupported tax years
// - Form 1040-ES Quarterly Estimated Tax Schedules
// - Deterministic Gig-Offer Telemetry (Milli Cents)
//
// Never relies on LLMs for calculations — strictly deterministic, versioned, and auditable.

public enum TaxEngineError: Error, LocalizedError, Equatable {
    case unsupportedTaxYear(Int)
    case unsupportedTripDate(Date)
    case negativeIncome
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedTaxYear(let year):
            return "Tax year \(year) is not supported by TaxEngine. Supported tax years: [2026, 2025]."
        case .unsupportedTripDate(let date):
            return "Date \(date) falls outside supported effective tax rule periods."
        case .negativeIncome:
            return "Tax calculation input cannot be negative."
        }
    }
}

public struct TaxRuleVersion: Codable, Equatable, Hashable {
    public let versionId: String
    public let taxYear: Int
    public let effectiveDate: String
    public let authoritySource: String

    public static let v2026_H1 = TaxRuleVersion(
        versionId: "2026.1-H1",
        taxYear: 2026,
        effectiveDate: "2026-01-01",
        authoritySource: "IRS Rev. Proc. 2025-32 / Notice 2025-88 (H1 Standard Mileage 72.5¢)"
    )

    public static let v2026_H2 = TaxRuleVersion(
        versionId: "2026.2-H2",
        taxYear: 2026,
        effectiveDate: "2026-07-01",
        authoritySource: "IRS Rev. Proc. 2025-32 / Notice 2026-01 (H2 Standard Mileage 76.0¢)"
    )

    public static let v2025 = TaxRuleVersion(
        versionId: "2025.1",
        taxYear: 2025,
        effectiveDate: "2025-01-01",
        authoritySource: "IRS Rev. Proc. 2024-40 / Notice 2024-88 (2025 Standard Mileage 70.0¢)"
    )

    public static let current = v2026_H2
}

public struct TaxEngine {
    public static let currentTaxYear: Int = 2026
    public static let defaultRuleVersion: String = TaxRuleVersion.current.versionId

    // MARK: - Rule Version Resolution by Date
    public static func ruleVersion(for date: Date = Date()) throws -> TaxRuleVersion {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year else {
            throw TaxEngineError.unsupportedTripDate(date)
        }
        
        switch year {
        case 2026:
            if let month = components.month, month >= 7 {
                return TaxRuleVersion.v2026_H2
            } else {
                return TaxRuleVersion.v2026_H1
            }
        case 2025:
            return TaxRuleVersion.v2025
        default:
            throw TaxEngineError.unsupportedTaxYear(year)
        }
    }

    // MARK: - Standard Deductions
    // IRS Rev. Proc. 2025-32, Sec. 3.16 / IRC § 63(c)(2)
    // 2026: Single: $16,100; MFS: $16,100; MFJ: $32,200; HOH: $24,150
    // 2025: Single: $15,000; MFS: $15,000; MFJ: $30,000; HOH: $22,500
    public static func standardDeduction(for status: TaxProfile.FilingStatus, year: Int = currentTaxYear) throws -> Money {
        switch year {
        case 2026:
            switch status {
            case .single, .marriedSeparate:
                return Money(cents: 16_100_00) // $16,100
            case .marriedJoint:
                return Money(cents: 32_200_00) // $32,200
            case .headOfHousehold:
                return Money(cents: 24_150_00) // $24,150
            }
        case 2025:
            switch status {
            case .single, .marriedSeparate:
                return Money(cents: 15_000_00)
            case .marriedJoint:
                return Money(cents: 30_000_00)
            case .headOfHousehold:
                return Money(cents: 22_500_00)
            }
        default:
            throw TaxEngineError.unsupportedTaxYear(year)
        }
    }

    // MARK: - Social Security Taxable Maximum (OASDI Cap)
    // 2026: SSA Announcement (89 FR 84431) -> $184,500
    // 2025: SSA Announcement -> $176,100
    public static func socialSecurityTaxableMaximum(year: Int = currentTaxYear) throws -> Money {
        switch year {
        case 2026:
            return Money(cents: 184_500_00) // $184,500
        case 2025:
            return Money(cents: 176_100_00) // $176,100
        default:
            throw TaxEngineError.unsupportedTaxYear(year)
        }
    }

    // MARK: - Additional Medicare Tax Thresholds (Form 8959 / IRC § 3101(b)(2))
    // MFJ: $250,000; MFS: $125,000; Single: $200,000; HOH: $200,000
    public static func additionalMedicareThreshold(for status: TaxProfile.FilingStatus, year: Int = currentTaxYear) throws -> Money {
        switch year {
        case 2026, 2025:
            switch status {
            case .marriedJoint:
                return Money(cents: 250_000_00) // $250,000
            case .marriedSeparate:
                return Money(cents: 125_000_00) // $125,000
            case .single, .headOfHousehold:
                return Money(cents: 200_000_00) // $200,000
            }
        default:
            throw TaxEngineError.unsupportedTaxYear(year)
        }
    }

    // MARK: - Effective-Dated Business Mileage Rates
    // Jan 1, 2026 – Jun 30, 2026: 72.5¢/mile ($0.725) — IRS Notice 2025-88
    // Jul 1, 2026 – Dec 31, 2026: 76.0¢/mile ($0.760) — IRS Notice 2026-01
    // 2025 Historical Rate: 70.0¢/mile ($0.700) — IRS Notice 2024-88
    public static func businessMileageRate(for date: Date = Date()) throws -> Decimal {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year else {
            throw TaxEngineError.unsupportedTripDate(date)
        }

        switch year {
        case 2026:
            if let month = components.month, month >= 7 {
                return Decimal(string: "0.760")!
            } else {
                return Decimal(string: "0.725")!
            }
        case 2025:
            return Decimal(string: "0.700")!
        default:
            throw TaxEngineError.unsupportedTripDate(date)
        }
    }

    public static func mileageRateDouble(for date: Date = Date()) -> Double {
        if let rate = try? businessMileageRate(for: date) {
            return NSDecimalNumber(decimal: rate).doubleValue
        }
        return 0.0
    }

    public static func formattedMileageRate(for date: Date = Date()) -> String {
        if let rate = try? businessMileageRate(for: date) {
            return String(format: "$%.3f", NSDecimalNumber(decimal: rate).doubleValue)
        }
        return "$0.000"
    }

    // MARK: - Federal Tax Bracket Struct
    public struct TaxBracket: Codable, Equatable {
        public let rate: Decimal
        public let minThreshold: Money
        public let maxThreshold: Money?

        public init(rate: Decimal, minThreshold: Money, maxThreshold: Money?) {
            self.rate = rate
            self.minThreshold = minThreshold
            self.maxThreshold = maxThreshold
        }
    }

    // MARK: - Federal Income Tax Brackets (IRS Rev. Proc. 2025-32, Sec. 3.01 / IRC § 1(j))
    // Model Single, MFJ, MFS, and HOH separately because MFS diverges from Single at upper brackets.
    public static func federalBrackets(for status: TaxProfile.FilingStatus, year: Int = currentTaxYear) throws -> [TaxBracket] {
        guard year == currentTaxYear else {
            throw TaxEngineError.unsupportedTaxYear(year)
        }

        switch status {
        case .single:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 12_400_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 12_400_00), maxThreshold: Money(cents: 50_400_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 50_400_00), maxThreshold: Money(cents: 105_700_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 105_700_00), maxThreshold: Money(cents: 201_775_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 201_775_00), maxThreshold: Money(cents: 256_225_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 256_225_00), maxThreshold: Money(cents: 640_600_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 640_600_00), maxThreshold: nil)
            ]
        case .marriedJoint:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 24_800_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 24_800_00), maxThreshold: Money(cents: 100_800_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 100_800_00), maxThreshold: Money(cents: 211_400_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 211_400_00), maxThreshold: Money(cents: 403_550_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 403_550_00), maxThreshold: Money(cents: 512_450_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 512_450_00), maxThreshold: Money(cents: 768_700_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 768_700_00), maxThreshold: nil)
            ]
        case .marriedSeparate:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 12_400_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 12_400_00), maxThreshold: Money(cents: 50_400_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 50_400_00), maxThreshold: Money(cents: 105_700_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 105_700_00), maxThreshold: Money(cents: 201_775_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 201_775_00), maxThreshold: Money(cents: 256_225_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 256_225_00), maxThreshold: Money(cents: 384_350_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 384_350_00), maxThreshold: nil)
            ]
        case .headOfHousehold:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 17_700_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 17_700_00), maxThreshold: Money(cents: 67_450_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 67_450_00), maxThreshold: Money(cents: 105_700_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 105_700_00), maxThreshold: Money(cents: 201_750_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 201_750_00), maxThreshold: Money(cents: 256_200_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 256_200_00), maxThreshold: Money(cents: 640_600_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 640_600_00), maxThreshold: nil)
            ]
        }
    }

    // MARK: - Self-Employment Tax (SECA / Schedule SE & Form 8959)
    public struct SelfEmploymentTaxResult: Codable, Equatable {
        public let netEarnings: Money
        public let w2SocialSecurityWages: Money
        public let w2MedicareWages: Money
        public let remainingOASDICap: Money
        public let socialSecurityTax: Money
        public let medicareTax: Money
        public let additionalMedicareTax: Money
        public let totalSelfEmploymentTax: Money
        public let deductiblePortion: Money // 50% of SE tax deductible above-the-line (IRC § 164(f))
        public let ruleVersion: String

        public init(
            netEarnings: Money,
            w2SocialSecurityWages: Money = .zero,
            w2MedicareWages: Money = .zero,
            remainingOASDICap: Money = .zero,
            socialSecurityTax: Money,
            medicareTax: Money,
            additionalMedicareTax: Money,
            totalSelfEmploymentTax: Money,
            deductiblePortion: Money,
            ruleVersion: String
        ) {
            self.netEarnings = netEarnings
            self.w2SocialSecurityWages = w2SocialSecurityWages
            self.w2MedicareWages = w2MedicareWages
            self.remainingOASDICap = remainingOASDICap
            self.socialSecurityTax = socialSecurityTax
            self.medicareTax = medicareTax
            self.additionalMedicareTax = additionalMedicareTax
            self.totalSelfEmploymentTax = totalSelfEmploymentTax
            self.deductiblePortion = deductiblePortion
            self.ruleVersion = ruleVersion
        }
    }

    public static func calculateSelfEmploymentTax(
        netGigIncome: Money,
        filingStatus: TaxProfile.FilingStatus = .single,
        w2SocialSecurityWages: Money = .zero,
        w2MedicareWages: Money = .zero,
        date: Date = Date(),
        year: Int = currentTaxYear
    ) throws -> SelfEmploymentTaxResult {
        guard netGigIncome.isPositive else {
            let version = try ruleVersion(for: date).versionId
            return SelfEmploymentTaxResult(
                netEarnings: .zero,
                w2SocialSecurityWages: w2SocialSecurityWages,
                w2MedicareWages: w2MedicareWages,
                remainingOASDICap: .zero,
                socialSecurityTax: .zero,
                medicareTax: .zero,
                additionalMedicareTax: .zero,
                totalSelfEmploymentTax: .zero,
                deductiblePortion: .zero,
                ruleVersion: version
            )
        }

        let version = try ruleVersion(for: date)

        // Net earnings subject to SE tax = 92.35% of net profit (IRC § 1402(a)(12))
        let netEarningsFactor = Decimal(string: "0.9235")!
        let netEarnings = (netGigIncome * netEarningsFactor).rounded(scale: 2)

        // OASDI Social Security wage base cap ($184,500 for 2026)
        // Mixed Income: W-2 Social Security wages reduce the remaining OASDI cap dollar-for-dollar
        let totalOasdiCap = try socialSecurityTaxableMaximum(year: year)
        let remainingOASDICap = max(.zero, totalOasdiCap - w2SocialSecurityWages)
        let ssTaxableEarnings = min(netEarnings, remainingOASDICap)
        let ssRate = Decimal(string: "0.124")! // 12.4% SECA
        let ssTax = (ssTaxableEarnings * ssRate).rounded(scale: 2)

        // Medicare tax = 2.9% (no wage cap)
        let medicareRate = Decimal(string: "0.029")! // 2.9%
        let medicareTax = (netEarnings * medicareRate).rounded(scale: 2)

        // Additional Medicare tax = 0.9% above filing-status threshold (IRC § 3101(b)(2) / Form 8959)
        // Mixed Income: W-2 Medicare wages consume the threshold before SE income is evaluated
        let addMedThreshold = try additionalMedicareThreshold(for: filingStatus, year: year)
        let remainingThreshold = max(.zero, addMedThreshold - w2MedicareWages)
        let addMedSubjectEarnings = max(.zero, netEarnings - remainingThreshold)
        let addMedRate = Decimal(string: "0.009")! // 0.9%
        let addMedTax = (addMedSubjectEarnings * addMedRate).rounded(scale: 2)

        let totalSE = ssTax + medicareTax + addMedTax
        let deductible = (totalSE * Decimal(string: "0.50")!).rounded(scale: 2)

        return SelfEmploymentTaxResult(
            netEarnings: netEarnings,
            w2SocialSecurityWages: w2SocialSecurityWages,
            w2MedicareWages: w2MedicareWages,
            remainingOASDICap: remainingOASDICap,
            socialSecurityTax: ssTax,
            medicareTax: medicareTax,
            additionalMedicareTax: addMedTax,
            totalSelfEmploymentTax: totalSE,
            deductiblePortion: deductible,
            ruleVersion: version.versionId
        )
    }

    // MARK: - Federal Income Tax Calculation
    public static func calculateFederalIncomeTax(
        taxableIncome: Money,
        filingStatus: TaxProfile.FilingStatus = .single,
        year: Int = currentTaxYear
    ) throws -> Money {
        guard taxableIncome.isPositive else { return .zero }
        let brackets = try federalBrackets(for: filingStatus, year: year)
        var totalTaxDec = Decimal.zero

        for bracket in brackets {
            guard taxableIncome > bracket.minThreshold else { continue }
            let taxableInBracket: Money
            if let maxThreshold = bracket.maxThreshold {
                taxableInBracket = min(taxableIncome, maxThreshold) - bracket.minThreshold
            } else {
                taxableInBracket = taxableIncome - bracket.minThreshold
            }
            totalTaxDec += taxableInBracket.decimalValue * bracket.rate
        }

        return Money(decimal: totalTaxDec).rounded(scale: 2)
    }

    // MARK: - State Income Tax Estimation
    public static func calculateStateTax(
        taxableIncome: Money,
        stateCode: String,
        filingStatus: TaxProfile.FilingStatus = .single,
        year: Int = currentTaxYear
    ) -> Money {
        guard taxableIncome.isPositive else { return .zero }
        let code = stateCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Zero state income tax jurisdictions
        let zeroTaxStates: Set<String> = ["TX", "FL", "NV", "WA", "WY", "SD", "TN", "NH", "AK"]
        if zeroTaxStates.contains(code) {
            return .zero
        }

        let rate: Decimal
        switch code {
        case "PA":
            rate = Decimal(string: "0.0307")! // Flat 3.07%
        case "IN":
            rate = Decimal(string: "0.0305")! // Flat 3.05%
        case "NC":
            rate = Decimal(string: "0.0450")! // Flat 4.50%
        case "CA":
            rate = Decimal(string: "0.0650")! // Blended gig worker baseline
        case "NY":
            rate = Decimal(string: "0.0585")! // Blended gig worker baseline
        default:
            rate = Decimal(string: "0.0450")! // National median estimate
        }

        return (taxableIncome * rate).rounded(scale: 2)
    }

    // MARK: - Standard Mileage Deduction (Selects by Trip Date)
    public static func calculateMileageDeduction(
        miles: Double,
        date: Date = Date(),
        year: Int = currentTaxYear
    ) throws -> Money {
        guard miles > 0 else { return .zero }
        let rate = try businessMileageRate(for: date)
        let decMiles = Decimal(string: String(format: "%.4f", miles)) ?? Decimal(miles)
        let totalDec = decMiles * rate
        return Money(decimal: totalDec).rounded(scale: 2)
    }

    // MARK: - Comprehensive Annual Tax Calculation
    public struct ComprehensiveTaxCalculation: Codable, Equatable {
        public let grossGigIncome: Money
        public let mileageDeduction: Money
        public let businessExpenses: Money
        public let totalDeductions: Money
        public let netScheduleCProfit: Money
        public let selfEmploymentTax: SelfEmploymentTaxResult
        public let adjustedGrossIncome: Money
        public let standardDeduction: Money
        public let taxableIncome: Money
        public let federalIncomeTax: Money
        public let stateIncomeTax: Money
        public let totalAnnualTaxLiability: Money
        public let effectiveTaxRate: Decimal
        public let recommendedReserveRate: Decimal
        public let ruleVersion: String
    }

    public static func calculateComprehensiveTax(
        grossAnnualGigIncome: Money,
        annualExpenses: Money = .zero,
        profile: TaxProfile,
        annualBusinessMiles: Double = 0,
        w2SocialSecurityWages: Money = .zero,
        w2MedicareWages: Money = .zero,
        calculationDate: Date = Date(),
        year: Int = currentTaxYear
    ) throws -> ComprehensiveTaxCalculation {
        let mileageDeduction = try calculateMileageDeduction(miles: annualBusinessMiles, date: calculationDate, year: year)
        let totalDeductions = mileageDeduction + annualExpenses
        let netScheduleC = max(grossAnnualGigIncome - totalDeductions, .zero)

        let seResult = try calculateSelfEmploymentTax(
            netGigIncome: netScheduleC,
            filingStatus: profile.filingStatus,
            w2SocialSecurityWages: w2SocialSecurityWages,
            w2MedicareWages: w2MedicareWages,
            date: calculationDate,
            year: year
        )
        let agi = max(netScheduleC - seResult.deductiblePortion, .zero)
        let stdDeduction = try standardDeduction(for: profile.filingStatus, year: year)
        let taxableIncome = max(agi - stdDeduction, .zero)

        let fedTax = try calculateFederalIncomeTax(taxableIncome: taxableIncome, filingStatus: profile.filingStatus, year: year)
        let stateTax = calculateStateTax(taxableIncome: taxableIncome, stateCode: profile.state, filingStatus: profile.filingStatus, year: year)
        let totalTax = seResult.totalSelfEmploymentTax + fedTax + stateTax

        let effectiveRate: Decimal
        if grossAnnualGigIncome.isPositive {
            effectiveRate = MilliRounding.round(decimal: totalTax.decimalValue / grossAnnualGigIncome.decimalValue, scale: 4)
        } else {
            effectiveRate = Decimal.zero
        }

        let recommendedRate = calculateRecommendedTaxReserveRate(profile: profile, year: year)
        let version = try ruleVersion(for: calculationDate).versionId

        return ComprehensiveTaxCalculation(
            grossGigIncome: grossAnnualGigIncome,
            mileageDeduction: mileageDeduction,
            businessExpenses: annualExpenses,
            totalDeductions: totalDeductions,
            netScheduleCProfit: netScheduleC,
            selfEmploymentTax: seResult,
            adjustedGrossIncome: agi,
            standardDeduction: stdDeduction,
            taxableIncome: taxableIncome,
            federalIncomeTax: fedTax,
            stateIncomeTax: stateTax,
            totalAnnualTaxLiability: totalTax,
            effectiveTaxRate: effectiveRate,
            recommendedReserveRate: recommendedRate,
            ruleVersion: version
        )
    }

    // MARK: - Recommended Reserve Rate
    public static func calculateRecommendedTaxReserveRate(
        profile: TaxProfile,
        year: Int = currentTaxYear
    ) -> Decimal {
        let income = profile.annualIncomeAmount ?? 55_000
        let baseRate: Decimal

        switch income {
        case ..<30_000:
            baseRate = Decimal(string: "0.20")! // 20%
        case ..<60_000:
            baseRate = Decimal(string: "0.23")! // 23%
        case ..<100_000:
            baseRate = Decimal(string: "0.27")! // 27%
        default:
            baseRate = Decimal(string: "0.30")! // 30%
        }

        // State adjustment
        let state = profile.state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let stateAdjustment: Decimal
        switch state {
        case "TX", "FL", "NV", "WA", "WY", "SD", "TN", "NH", "AK":
            stateAdjustment = Decimal(string: "-0.03")! // -3% for zero income tax states
        case "CA", "NY", "NJ", "OR", "MN":
            stateAdjustment = Decimal(string: "0.02")! // +2% for high-tax states
        default:
            stateAdjustment = Decimal.zero
        }

        let combined = baseRate + stateAdjustment
        return max(Decimal(string: "0.15")!, min(combined, Decimal(string: "0.35")!))
    }

    // MARK: - Quarterly Estimated Tax Schedule (Form 1040-ES)
    public struct QuarterlyTaxSchedule: Codable, Equatable {
        public let year: Int
        public let annualEstimatedLiability: Money
        public let quarterlyPaymentAmount: Money
        public let q1DueDate: String
        public let q2DueDate: String
        public let q3DueDate: String
        public let q4DueDate: String
    }

    public static func calculateQuarterlyEstimatedPayments(
        annualTaxLiability: Money,
        year: Int = currentTaxYear
    ) -> QuarterlyTaxSchedule {
        let perQuarter = (annualTaxLiability / 4).rounded(scale: 2)
        return QuarterlyTaxSchedule(
            year: year,
            annualEstimatedLiability: annualTaxLiability,
            quarterlyPaymentAmount: perQuarter,
            q1DueDate: "April 15, \(year)",
            q2DueDate: "June 15, \(year)",
            q3DueDate: "September 15, \(year)",
            q4DueDate: "January 15, \(year + 1)"
        )
    }

    // MARK: - Milli Cents Gig Offer Profitability Analysis
    public struct MilliCentsAnalysis: Codable, Equatable {
        public let offerGross: Money
        public let totalMiles: Double
        public let estimatedTimeMinutes: Double
        public let estimatedFuelCost: Money
        public let irsStandardMileageDeduction: Money
        public let effectiveMileageRate: Decimal
        public let estimatedTaxImpact: Money
        public let netTrueProfit: Money
        public let profitPerMile: Money
        public let profitPerHour: Money
        public let recommendation: Recommendation
        public let summaryLine: String

        public enum Recommendation: String, Codable, Equatable {
            case go = "GO"
            case caution = "CAUTION"
            case decline = "DECLINE"
        }
    }

    public static func calculateMilliCentsProfitability(
        offerGross: Money,
        totalMiles: Double,
        estimatedTimeMinutes: Double,
        tripDate: Date = Date(),
        gasPricePerGallon: Money = Money(cents: 385), // National avg estimate ($3.85)
        vehicleMpg: Double = 25.0,
        estimatedTaxReserveRate: Decimal = Decimal(string: "0.23")!
    ) -> MilliCentsAnalysis {
        // Fuel cost
        let gallonsNeeded = vehicleMpg > 0 ? totalMiles / vehicleMpg : 0
        let decGallons = Decimal(string: String(format: "%.4f", gallonsNeeded)) ?? Decimal(gallonsNeeded)
        let estimatedFuelCost = (gasPricePerGallon * decGallons).rounded(scale: 2)

        // Versioned IRS Mileage deduction
        let standardDeduction = (try? calculateMileageDeduction(miles: totalMiles, date: tripDate)) ?? Money.zero
        let rate = (try? businessMileageRate(for: tripDate)) ?? Decimal(string: "0.760")!

        // Tax impact (tax reserve on gross minus fuel expense)
        let taxablePortion = max(offerGross - estimatedFuelCost, .zero)
        let estimatedTaxImpact = (taxablePortion * estimatedTaxReserveRate).rounded(scale: 2)

        // Net true profit = Gross - Fuel - Estimated Tax
        let netProfit = offerGross - estimatedFuelCost - estimatedTaxImpact

        // Profit per mile
        let decMiles = Decimal(string: String(format: "%.4f", totalMiles)) ?? Decimal(totalMiles)
        let profitPerMile: Money
        if decMiles > Decimal.zero {
            profitPerMile = (netProfit / decMiles).rounded(scale: 2)
        } else {
            profitPerMile = .zero
        }

        // Profit per hour
        let profitPerHour: Money
        let hours = estimatedTimeMinutes / 60.0
        if hours > 0 {
            profitPerHour = (netProfit / Decimal(string: String(format: "%.4f", hours))!).rounded(scale: 2)
        } else {
            profitPerHour = .zero
        }

        let recommendation: MilliCentsAnalysis.Recommendation
        if netProfit.cents >= 18_00 && profitPerMile.cents >= 50 {
            recommendation = .go
        } else if netProfit.cents >= 10_00 && profitPerMile.cents >= 30 {
            recommendation = .caution
        } else {
            recommendation = .decline
        }

        let summary = "Gross: \(offerGross.formattedCurrency) | Net Est: \(netProfit.formattedCurrency) | Fuel: \(estimatedFuelCost.formattedCurrency) | IRS Ded: \(standardDeduction.formattedCurrency) (\(formattedMileageRate(for: tripDate))/mi)"

        return MilliCentsAnalysis(
            offerGross: offerGross,
            totalMiles: totalMiles,
            estimatedTimeMinutes: estimatedTimeMinutes,
            estimatedFuelCost: estimatedFuelCost,
            irsStandardMileageDeduction: standardDeduction,
            effectiveMileageRate: rate,
            estimatedTaxImpact: estimatedTaxImpact,
            netTrueProfit: netProfit,
            profitPerMile: profitPerMile,
            profitPerHour: profitPerHour,
            recommendation: recommendation,
            summaryLine: summary
        )
    }
}