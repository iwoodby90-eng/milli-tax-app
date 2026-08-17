import Foundation

// MARK: - TaxProfile — Onboarding tax profile data model
// Persisted via UserDefaults during the native onboarding setup.

struct TaxProfile: Codable {
    var filingStatus: FilingStatus = .single
    var estimatedAnnualIncome: String = ""
    var isSelfEmployed: Bool = true
    var hasMultipleVehicles: Bool = false
    var state: String = ""

    enum FilingStatus: String, Codable, CaseIterable {
        case single = "Single"
        case marriedJoint = "Married Filing Jointly"
        case marriedSeparate = "Married Filing Separately"
        case headOfHousehold = "Head of Household"

        var shortLabel: String {
            switch self {
            case .single: return "Single"
            case .marriedJoint: return "Married (Joint)"
            case .marriedSeparate: return "Married (Sep)"
            case .headOfHousehold: return "HoH"
            }
        }
    }

    var isValid: Bool {
        !estimatedAnnualIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Milli Subscription Plan
// These tiers match the approved product model. Selecting a tier in onboarding
// does not charge the user; production billing remains a separate checkout action.

enum MilliPlan: String, Codable, CaseIterable {
    case basic = "Basic"
    case pro = "Pro"
    case elite = "Elite"

    var monthlyPrice: String {
        switch self {
        case .basic: return "$19.99/mo"
        case .pro: return "$29.99/mo"
        case .elite: return "$49.99/mo"
        }
    }

    var trialLabel: String? {
        switch self {
        case .basic: return "3-day trial"
        case .pro, .elite: return nil
        }
    }

    var features: [String] {
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

    var isPopular: Bool { self == .pro }
}
