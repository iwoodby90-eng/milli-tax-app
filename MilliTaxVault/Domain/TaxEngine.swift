import Foundation

// MARK: - Milli Deterministic Tax Engine
// Versioned and Effective-Dated Tax Calculation Engine for IRS Tax Year 2026.
// Covers:
// - Standard Deductions (Single/MFS $16,100, MFJ $32,200, HOH $24,150)
// - OASDI Social Security Wage Base Cap ($184,500 @ 12.4%)
// - Medicare (2.9%) and Additional Medicare (0.9% varying by filing status: MFJ $250k, MFS $125k, Single/HOH $200k)
// - Schedule SE Net Earnings Factor (92.35%) and Above-the-Line SE Tax Deduction (50%)
// - Effective-Dated 2026 Business Mileage Rates (Jan-Jun 2026: $0.725/mi; Jul-Dec 2026: $0.760/mi)
// - Form 1040-ES Quarterly Estimated Tax Schedules
// - Deterministic Gig-Offer Telemetry (Milli Cents)
//
// Never relies on LLMs for calculations — strictly deterministic, versioned, and auditable.

public struct TaxRuleVersion: Codable, Equatable, Hashable {
    public let versionId: String
    public let taxYear: Int
    public let effectiveDate: String
    public let authoritySource: String

    public static let v2026_H1 = TaxRuleVersion(
        versionId: "2026.1-H1",
        taxYear: 2026,
        effectiveDate: "2026-01-01",
        authoritySource: "IRS Rev. Proc. 2025-XX / Notice 2025-XX (H1 Standard Mileage 72.5¢)"
    )

    public static let v2026_H2 = TaxRuleVersion(
        versionId: "2026.2-H2",
        taxYear: 2026,
        effectiveDate: "2026-07-01",
        authoritySource: "IRS Rev. Proc. 2025-XX / Mid-Year Adjustment (H2 Standard Mileage 76.0¢)"
    )

    public static let current = v2026_H2
}

public struct TaxEngine {
    public static let currentTaxYear: Int = 2026
    public static let defaultRuleVersion: String = TaxRuleVersion.current.versionId

    // MARK: - Rule Version Resolution by Date
    public static func ruleVersion(for date: Date = Date()) -> TaxRuleVersion {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? currentTaxYear
        guard year == currentTaxYear else {
            return TaxRuleVersion.v2026_H2
        }
        if let month = components.month, month >= 7 {
            return TaxRuleVersion.v2026_H2
        } else {
            return TaxRuleVersion.v2026_H1
        }
    }

    // MARK: - Standard Deductions (2026 IRS Rules)
    // IRS Rev. Proc. 2025-XX / IRC § 63(c)(2)
    // Single: $16,100; MFS: $16,100; MFJ: $32,200; HOH: $24,150
    public static func standardDeduction(for status: TaxProfile.FilingStatus, year: Int = currentTaxYear) -> Money {
        switch status {
        case .single, .marriedSeparate:
            return Money(cents: 16_100_00) // $16,100
        case .marriedJoint:
            return Money(cents: 32_200_00) // $32,200
        case .headOfHousehold:
            return Money(cents: 24_150_00) // $24,150
        }
    }

    // MARK: - Social Security Taxable Maximum (OASDI Cap 2026)
    // Social Security Administration 2026 Wage Base Announcement: $184,500
    public static func socialSecurityTaxableMaximum(year: Int = currentTaxYear) -> Money {
        Money(cents: 184_500_00) // $184,500
    }

    // MARK: - Additional Medicare Tax Thresholds (Form 8959 / IRC § 3101(b)(2))
    // Varies strictly by filing status:
    // MFJ: $250,000; MFS: $125,000; Single: $200,000; HOH: $200,000
    public static func additionalMedicareThreshold(for status: TaxProfile.FilingStatus, year: Int = currentTaxYear) -> Money {
        switch status {
        case .marriedJoint:
            return Money(cents: 250_000_00) // $250,000
        case .marriedSeparate:
            return Money(cents: 125_000_00) // $125,000
        case .single, .headOfHousehold:
            return Money(cents: 200_000_00) // $200,000
        }
    }

    // MARK: - Effective-Dated Business Mileage Rates (2026)
    // Jan 1, 2026 – Jun 30, 2026: 72.5¢/mile ($0.725)
    // Jul 1, 2026 – Dec 31, 2026: 76.0¢/mile ($0.760)
    public static func businessMileageRate(for date: Date = Date()) -> Decimal {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? currentTaxYear
        guard year == currentTaxYear else {
            return Decimal(string: "0.760")!
        }
        if let month = components.month, month >= 7 {
            return Decimal(string: "0.760")!
        } else {
            return Decimal(string: "0.725")!
        }
    }

    public static func mileageRateDouble(for date: Date = Date()) -> Double {
        NSDecimalNumber(decimal: businessMileageRate(for: date)).doubleValue
    }

    public static func formattedMileageRate(for date: Date = Date()) -> String {
        let rate = businessMileageRate(for: date)
        return String(format: "$%.3f", NSDecimalNumber(decimal: rate).doubleValue)
    }

    // MARK: - Federal Tax Bracket Struct
    public struct TaxBracket: Codable, Equatable {
        public let rate: Decimal
        public let minThreshold: Money
        public let maxThreshold: Money?
    }

    // MARK: - Federal Income Tax Brackets (2026)
    public static func federalBrackets(for status: TaxProfile.FilingStatus, year: Int = currentTaxYear) -> [TaxBracket] {
        switch status {
        case .single, .marriedSeparate:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 11_925_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 11_925_00), maxThreshold: Money(cents: 48_475_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 48_475_00), maxThreshold: Money(cents: 103_350_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 103_350_00), maxThreshold: Money(cents: 197_300_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 197_300_00), maxThreshold: Money(cents: 250_525_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 250_525_00), maxThreshold: Money(cents: 626_350_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 626_350_00), maxThreshold: nil)
            ]
        case .marriedJoint:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 23_850_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 23_850_00), maxThreshold: Money(cents: 96_950_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 96_950_00), maxThreshold: Money(cents: 206_700_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 206_700_00), maxThreshold: Money(cents: 394_600_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 394_600_00), maxThreshold: Money(cents: 501_050_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 501_050_00), maxThreshold: Money(cents: 751_600_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 751_600_00), maxThreshold: nil)
            ]
        case .headOfHousehold:
            return [
                TaxBracket(rate: Decimal(string: "0.10")!, minThreshold: Money(cents: 0), maxThreshold: Money(cents: 17_000_00)),
                TaxBracket(rate: Decimal(string: "0.12")!, minThreshold: Money(cents: 17_000_00), maxThreshold: Money(cents: 64_850_00)),
                TaxBracket(rate: Decimal(string: "0.22")!, minThreshold: Money(cents: 64_850_00), maxThreshold: Money(cents: 103_350_00)),
                TaxBracket(rate: Decimal(string: "0.24")!, minThreshold: Money(cents: 103_350_00), maxThreshold: Money(cents: 197_300_00)),
                TaxBracket(rate: Decimal(string: "0.32")!, minThreshold: Money(cents: 197_300_00), maxThreshold: Money(cents: 250_500_00)),
                TaxBracket(rate: Decimal(string: "0.35")!, minThreshold: Money(cents: 250_500_00), maxThreshold: Money(cents: 626_350_00)),
                TaxBracket(rate: Decimal(string: "0.37")!, minThreshold: Money(cents: 626_350_00), maxThreshold: nil)
            ]
        }
    }

    // MARK: - Self-Employment Tax (SECA / Schedule SE)
    public struct SelfEmploymentTaxResult: Codable, Equatable {
        public let netEarnings: Money
        public let socialSecurityTax: Money
        public let medicareTax: Money
        public let additionalMedicareTax: Money
        public let totalSelfEmploymentTax: Money
        public let deductiblePortion: Money // 50% of SE tax deductible above-the-line (IRC § 164(f))
        public let ruleVersion: String
    }

    public static func calculateSelfEmploymentTax(
        netGigIncome: Money,
        filingStatus: TaxProfile.FilingStatus = .single,
        date: Date = Date(),
        year: Int = currentTaxYear
    ) -> SelfEmploymentTaxResult {
        guard netGigIncome.isPositive else {
            return SelfEmploymentTaxResult(
                netEarnings: .zero,
                socialSecurityTax: .zero,
                medicareTax: .zero,
                additionalMedicareTax: .zero,
                totalSelfEmploymentTax: .zero,
                deductiblePortion: .zero,
                ruleVersion: ruleVersion(for: date).versionId
            )
        }

        // Net earnings subject to SE tax = 92.35% of net profit (IRC § 1402(a)(12))
        let netEarningsFactor = Decimal(string: "0.9235")!
        let netEarnings = (netGigIncome * netEarningsFactor).rounded(scale: 2)

        // 2026 OASDI Social Security wage base cap = $184,500
        let oasdiCap = socialSecurityTaxableMaximum(year: year)
        let ssTaxableEarnings = min(netEarnings, oasdiCap)
        let ssRate = Decimal(string: "0.124")! // 12.4%
        let ssTax = (ssTaxableEarnings * ssRate).rounded(scale: 2)

        // Medicare tax = 2.9% (no wage cap)
        let medicareRate = Decimal(string: "0.029")! // 2.9%
        let medicareTax = (netEarnings * medicareRate).rounded(scale: 2)

        // Additional Medicare tax = 0.9% above filing-status threshold (IRC § 3101(b)(2))
        let addMedThreshold = additionalMedicareThreshold(for: filingStatus, year: year)
        let addMedTax: Money
        if netEarnings > addMedThreshold {
            let excess = netEarnings - addMedThreshold
            let addMedRate = Decimal(string: "0.009")! // 0.9%
            addMedTax = (excess * addMedRate).rounded(scale: 2)
        } else {
            addMedTax = .zero
        }

        let totalSE = ssTax + medicareTax + addMedTax
        let deductible = (totalSE * Decimal(string: "0.50")!).rounded(scale: 2) // 50% deduction

        return SelfEmploymentTaxResult(
            netEarnings: netEarnings,
            socialSecurityTax: ssTax,
            medicareTax: medicareTax,
            additionalMedicareTax: addMedTax,
            totalSelfEmploymentTax: totalSE,
            deductiblePortion: deductible,
            ruleVersion: ruleVersion(for: date).versionId
        )
    }

    // MARK: - Federal Income Tax Calculation
    public static func calculateFederalIncomeTax(
        taxableIncome: Money,
        filingStatus: TaxProfile.FilingStatus,
        year: Int = currentTaxYear
    ) -> Money {
        guard taxableIncome.isPositive else { return .zero }

        let brackets = federalBrackets(for: filingStatus, year: year)
        var totalTax = Money.zero

        for bracket in brackets {
            if taxableIncome > bracket.minThreshold {
                let upper = bracket.maxThreshold != nil ? min(taxableIncome, bracket.maxThreshold!) : taxableIncome
                let chunk = upper - bracket.minThreshold
                let bracketTax = (chunk * bracket.rate).rounded(scale: 2)
                totalTax = totalTax + bracketTax
            }
        }

        return totalTax
    }

    // MARK: - State Income Tax Calculation (Baseline Model)
    public static func calculateStateTax(
        taxableIncome: Money,
        stateCode: String,
        filingStatus: TaxProfile.FilingStatus,
        year: Int = currentTaxYear
    ) -> Money {
        guard taxableIncome.isPositive else { return .zero }

        let state = stateCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let rate: Decimal

        switch state {
        case "TX", "FL", "NV", "WA", "WY", "SD", "TN", "NH", "AK":
            rate = Decimal.zero
        case "IL":
            rate = Decimal(string: "0.0495")! // Flat 4.95%
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
    ) -> Money {
        guard miles > 0 else { return .zero }
        let rate = businessMileageRate(for: date)
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
        calculationDate: Date = Date(),
        year: Int = currentTaxYear
    ) -> ComprehensiveTaxCalculation {
        let mileageDeduction = calculateMileageDeduction(miles: annualBusinessMiles, date: calculationDate, year: year)
        let totalDeductions = mileageDeduction + annualExpenses
        let netScheduleC = max(grossAnnualGigIncome - totalDeductions, .zero)

        let seResult = calculateSelfEmploymentTax(netGigIncome: netScheduleC, filingStatus: profile.filingStatus, date: calculationDate, year: year)
        let agi = max(netScheduleC - seResult.deductiblePortion, .zero)
        let stdDeduction = standardDeduction(for: profile.filingStatus, year: year)
        let taxableIncome = max(agi - stdDeduction, .zero)

        let fedTax = calculateFederalIncomeTax(taxableIncome: taxableIncome, filingStatus: profile.filingStatus, year: year)
        let stateTax = calculateStateTax(taxableIncome: taxableIncome, stateCode: profile.state, filingStatus: profile.filingStatus, year: year)
        let totalTax = seResult.totalSelfEmploymentTax + fedTax + stateTax

        let effectiveRate: Decimal
        if grossAnnualGigIncome.isPositive {
            effectiveRate = MilliRounding.round(decimal: totalTax.decimalValue / grossAnnualGigIncome.decimalValue, scale: 4)
        } else {
            effectiveRate = Decimal.zero
        }

        let recommendedRate = calculateRecommendedTaxReserveRate(profile: profile, year: year)
        let version = ruleVersion(for: calculationDate).versionId

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
        public let fuelCost: Money
        public let mileageTaxDeduction: Money
        public let effectiveMileageRate: Decimal
        public let estimatedTaxImpact: Money
        public let netProfit: Money
        public let profitPerMile: Money
        public let profitPerHour: Money
        public let recommendation: Recommendation
        public let calculationVersion: String

        public enum Recommendation: String, Codable {
            case go = "GO"
            case maybe = "BORDERLINE"
            case decline = "DECLINE"
        }
    }

    public static func calculateMilliCentsProfitability(
        offerGross: Money,
        totalMiles: Double,
        estimatedTimeMinutes: Double,
        tripDate: Date = Date(),
        gasPricePerGallon: Money = Money(cents: 385), // $3.85
        vehicleMpg: Double = 26.0,
        effectiveTaxRate: Decimal = Decimal(string: "0.23")!
    ) -> MilliCentsAnalysis {
        let decMiles = Decimal(string: String(format: "%.4f", totalMiles)) ?? Decimal(totalMiles)
        
        // Fuel cost = (miles / mpg) * gasPrice
        let gallons = decMiles / Decimal(string: String(format: "%.4f", max(vehicleMpg, 1.0)))!
        let fuel = Money(decimal: gallons * gasPricePerGallon.decimalValue).rounded(scale: 2)

        // Mileage deduction selects by trip date (72.5¢ or 76.0¢)
        let rate = businessMileageRate(for: tripDate)
        let mileageDeduction = calculateMileageDeduction(miles: totalMiles, date: tripDate)

        // Taxable portion = max(0, offerGross - mileageDeduction)
        let taxablePortion = max(offerGross - mileageDeduction, .zero)
        let taxImpact = (taxablePortion * effectiveTaxRate).rounded(scale: 2)

        // Net profit = offerGross - fuel - taxImpact
        let netProfit = max(offerGross - fuel - taxImpact, .zero)

        // Profit per mile
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
        } else if netProfit.cents >= 8_00 && profitPerMile.cents >= 30 {
            recommendation = .maybe
        } else {
            recommendation = .decline
        }

        let version = ruleVersion(for: tripDate).versionId

        return MilliCentsAnalysis(
            offerGross: offerGross,
            totalMiles: totalMiles,
            fuelCost: fuel,
            mileageTaxDeduction: mileageDeduction,
            effectiveMileageRate: rate,
            estimatedTaxImpact: taxImpact,
            netProfit: netProfit,
            profitPerMile: profitPerMile,
            profitPerHour: profitPerHour,
            recommendation: recommendation,
            calculationVersion: version
        )
    }
}
