import Foundation

// MARK: - TaxProfile — Onboarding tax profile data model
// Persisted via UserDefaults during the native onboarding setup.

public struct TaxProfile: Codable, Equatable {
    public var filingStatus: FilingStatus = .single
    public var estimatedAnnualIncome: String = ""
    public var isSelfEmployed: Bool = true
    public var hasMultipleVehicles: Bool = false
    public var state: String = ""

    public init(
        filingStatus: FilingStatus = .single,
        estimatedAnnualIncome: String = "",
        isSelfEmployed: Bool = true,
        hasMultipleVehicles: Bool = false,
        state: String = ""
    ) {
        self.filingStatus = filingStatus
        self.estimatedAnnualIncome = estimatedAnnualIncome
        self.isSelfEmployed = isSelfEmployed
        self.hasMultipleVehicles = hasMultipleVehicles
        self.state = state
    }

    public enum FilingStatus: String, Codable, CaseIterable {
        case single = "Single"
        case marriedJoint = "Married Filing Jointly"
        case marriedSeparate = "Married Filing Separately"
        case headOfHousehold = "Head of Household"

        public var shortLabel: String {
            switch self {
            case .single: return "Single"
            case .marriedJoint: return "Married (Joint)"
            case .marriedSeparate: return "Married (Sep)"
            case .headOfHousehold: return "HoH"
            }
        }
    }

    public var annualIncomeAmount: Double? {
        let cleaned = estimatedAnnualIncome
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(cleaned), amount > 0 else { return nil }
        return amount
    }

    public var annualIncomeMoney: Money? {
        annualIncomeAmount.map { Money(double: $0) }
    }

    public var recommendedTaxReserveRate: Decimal {
        TaxEngine.calculateRecommendedTaxReserveRate(profile: self)
    }

    public var recommendedTaxReservePercent: Int {
        Int(NSDecimalNumber(decimal: recommendedTaxReserveRate * 100).doubleValue.rounded())
    }

    public var isValid: Bool {
        annualIncomeAmount != nil
            && !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Milli Subscription Plan
// Every new Milli account receives one three-day trial of the plan selected during
// first-time onboarding. Production App Store billing still needs to bind this
// entitlement state to StoreKit before release.

public enum MilliPlan: String, Codable, CaseIterable {
    case basic = "Basic"
    case pro = "Pro"
    case elite = "Elite"

    public var monthlyPrice: String {
        switch self {
        case .basic: return "$19.99/mo"
        case .pro: return "$29.99/mo"
        case .elite: return "$49.99/mo"
        }
    }

    public var trialLabel: String { "3-day free trial" }

    public var onboardingPriceLine: String {
        "3 days free • then \(monthlyPrice)"
    }

    public var features: [String] {
        switch self {
        case .basic:
            return [
                "Automatic tax reserve guidance",
                "GPS mileage tracking",
                "Quarterly tax estimates",
                "Income, expense, and deduction reports",
                "Prepare your numbers for manual filing"
            ]
        case .pro:
            return [
                "Everything in Basic",
                "Retirement planning and 401(k) access",
                "Investing access",
                "Enhanced tax-document preparation",
                "Milli AI financial planning tools"
            ]
        case .elite:
            return [
                "Everything in Pro",
                "Automated quarterly tax-payment workflow when connected",
                "Annual e-file workflow through a production tax partner",
                "Automated retirement and investing allocations when connected",
                "Priority Elite document workflow"
            ]
        }
    }

    public var isPopular: Bool { self == .pro }
}

// MARK: - Trial persistence

public struct MilliTrialState {
    public static let hasActivatedKey = "milliTrialHasActivated"
    public static let planKey = "milliTrialPlan"
    public static let startedAtKey = "milliTrialStartedAt"
    public static let endsAtKey = "milliTrialEndsAt"

    public let plan: MilliPlan
    public let startedAt: Date
    public let endsAt: Date

    public var isActive: Bool { Date() < endsAt }

    public static func activateIfNeeded(plan: MilliPlan, now: Date = Date()) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: hasActivatedKey) else { return }

        let endsAt = Calendar.current.date(byAdding: .day, value: 3, to: now)
            ?? now.addingTimeInterval(3 * 24 * 60 * 60)

        defaults.set(true, forKey: hasActivatedKey)
        defaults.set(plan.rawValue, forKey: planKey)
        defaults.set(now, forKey: startedAtKey)
        defaults.set(endsAt, forKey: endsAtKey)
    }

    public static func current() -> MilliTrialState? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: hasActivatedKey),
              let rawPlan = defaults.string(forKey: planKey),
              let plan = MilliPlan(rawValue: rawPlan),
              let startedAt = defaults.object(forKey: startedAtKey) as? Date,
              let endsAt = defaults.object(forKey: endsAtKey) as? Date
        else {
            return nil
        }

        return MilliTrialState(plan: plan, startedAt: startedAt, endsAt: endsAt)
    }

    public static func resetForNewLocalAccount() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: hasActivatedKey)
        defaults.removeObject(forKey: planKey)
        defaults.removeObject(forKey: startedAtKey)
        defaults.removeObject(forKey: endsAtKey)
    }
}
