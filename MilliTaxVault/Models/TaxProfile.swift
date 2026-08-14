import Foundation

// MARK: - TaxProfile — Onboarding tax profile data model
// Persisted via @AppStorage / UserDefaults during onboarding setup.

struct TaxProfile: Codable {
    var filingStatus: FilingStatus = .single
    var estimatedAnnualIncome: String = ""
    var isSelfEmployed: Bool = false
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
        !estimatedAnnualIncome.isEmpty
    }
}

// MARK: - Milli Subscription Plan
enum MilliPlan: String, Codable, CaseIterable {
    case starter = "Starter"
    case pro = "Pro"
    case elite = "Elite"
    
    var monthlyPrice: String {
        switch self {
        case .starter: return "$4.99/mo"
        case .pro: return "$9.99/mo"
        case .elite: return "$19.99/mo"
        }
    }
    
    var annualPrice: String {
        switch self {
        case .starter: return "$49.99/yr"
        case .pro: return "$99.99/yr"
        case .elite: return "$199.99/yr"
        }
    }
    
    var features: [String] {
        switch self {
        case .starter:
            return ["Mileage tracking", "Basic tax estimates", "1 vehicle"]
        case .pro:
            return ["Unlimited vehicles", "AI tax optimization", "Wealth dashboard", "Tree of Life planner"]
        case .elite:
            return ["Everything in Pro", "Priority support", "Retirement planner", "Tax filing assist", "Dedicated advisor"]
        }
    }
    
    var isPopular: Bool { self == .pro }
}
