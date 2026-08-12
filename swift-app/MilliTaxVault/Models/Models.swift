import Foundation

// MARK: - User & Auth

struct MilliUser: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let tier: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case tier = "plan"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        tier = try c.decodeIfPresent(String.self, forKey: .tier)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }

    init(id: String, email: String, name: String, tier: String? = nil, createdAt: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.tier = tier
        self.createdAt = createdAt
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: MilliUser
}

// MARK: - Vault

struct VaultBalance: Codable {
    let balance: Double
    let goal: Double
    let thisMonth: Double
    let streak: Int
    let percentOfGoal: Double

    enum CodingKeys: String, CodingKey {
        case balance
        case goal = "tax_goal"
        case thisMonth = "this_month"
        case streak
        case percentOfGoal = "percent_of_goal"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        balance = try c.decodeIfPresent(Double.self, forKey: .balance) ?? 0
        goal = try c.decodeIfPresent(Double.self, forKey: .goal) ?? 22500
        thisMonth = try c.decodeIfPresent(Double.self, forKey: .thisMonth) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        percentOfGoal = try c.decodeIfPresent(Double.self, forKey: .percentOfGoal) ?? 0
    }

    init(balance: Double = 0, goal: Double = 22500, thisMonth: Double = 0, streak: Int = 0, percentOfGoal: Double = 0) {
        self.balance = balance
        self.goal = goal
        self.thisMonth = thisMonth
        self.streak = streak
        self.percentOfGoal = percentOfGoal
    }
}

// MARK: - Payouts

struct Payout: Codable, Identifiable {
    let id: String
    let source: String
    let date: String
    let amount: Double
    let savingsSetAside: Double
    let platform: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case source = "merchant"
        case date
        case amount
        case savingsSetAside = "savings_set_aside"
        case platform
        case status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "Spark Driver\u{2122}"
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        amount = try c.decodeIfPresent(Double.self, forKey: .amount) ?? 0
        savingsSetAside = try c.decodeIfPresent(Double.self, forKey: .savingsSetAside) ?? 0
        platform = try c.decodeIfPresent(String.self, forKey: .platform) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "processed"
    }

    init(id: String = UUID().uuidString, source: String = "Spark Driver\u{2122}", date: String = "", amount: Double = 0, savingsSetAside: Double = 0, platform: String = "", status: String = "processed") {
        self.id = id
        self.source = source
        self.date = date
        self.amount = amount
        self.savingsSetAside = savingsSetAside
        self.platform = platform
        self.status = status
    }
}

// MARK: - Mileage

struct MileageTrip: Codable, Identifiable {
    let id: String
    let startTime: String
    let endTime: String?
    let miles: Double
    let deduction: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case miles
        case deduction = "deductible_value"
        case status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        miles = try c.decodeIfPresent(Double.self, forKey: .miles) ?? 0
        deduction = try c.decodeIfPresent(Double.self, forKey: .deduction) ?? 0
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "completed"
    }

    init(id: String = UUID().uuidString, startTime: String = "", endTime: String? = nil, miles: Double = 0, deduction: Double = 0, status: String = "completed") {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.miles = miles
        self.deduction = deduction
        self.status = status
    }

    var isActive: Bool { status == "active" }
}

struct MileageSummary: Codable {
    let totalMiles: Double
    let totalDeduction: Double
    let businessMiles: Double
    let tripsCount: Int
    let year: Int

    enum CodingKeys: String, CodingKey {
        case totalMiles = "total_miles"
        case totalDeduction = "total_deduction"
        case businessMiles = "business_miles"
        case tripsCount = "trips_count"
        case year
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalMiles = try c.decodeIfPresent(Double.self, forKey: .totalMiles) ?? 0
        totalDeduction = try c.decodeIfPresent(Double.self, forKey: .totalDeduction) ?? 0
        businessMiles = try c.decodeIfPresent(Double.self, forKey: .businessMiles) ?? 0
        tripsCount = try c.decodeIfPresent(Int.self, forKey: .tripsCount) ?? 0
        year = try c.decodeIfPresent(Int.self, forKey: .year) ?? 2026
    }

    init(totalMiles: Double = 0, totalDeduction: Double = 0, businessMiles: Double = 0, tripsCount: Int = 0, year: Int = 2026) {
        self.totalMiles = totalMiles
        self.totalDeduction = totalDeduction
        self.businessMiles = businessMiles
        self.tripsCount = tripsCount
        self.year = year
    }
}

// MARK: - Plaid

struct PlaidLinkToken: Codable {
    let linkToken: String

    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
    }
}

struct PlaidItem: Codable, Identifiable {
    let id: String
    let institutionName: String
    let lastSynced: String?

    enum CodingKeys: String, CodingKey {
        case id
        case institutionName = "institution_name"
        case lastSynced = "last_synced"
    }
}

// MARK: - Dashboard Summary

struct DashboardSummary: Codable {
    let availableToSpend: Double
    let vaultBalance: Double
    let vaultGoalPercent: Double
    let latestPayoutAmount: Double
    let latestPayoutDate: String
    let taxReadyScore: Int
    let quarterlyEstimate: Double
    let quarterMiles: Double

    enum CodingKeys: String, CodingKey {
        case availableToSpend = "available_to_spend"
        case vaultBalance = "vault_balance"
        case vaultGoalPercent = "vault_goal_percent"
        case latestPayoutAmount = "latest_payout_amount"
        case latestPayoutDate = "latest_payout_date"
        case taxReadyScore = "tax_ready_score"
        case quarterlyEstimate = "quarterly_estimate"
        case quarterMiles = "quarter_miles"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        availableToSpend = try c.decodeIfPresent(Double.self, forKey: .availableToSpend) ?? 0
        vaultBalance = try c.decodeIfPresent(Double.self, forKey: .vaultBalance) ?? 0
        vaultGoalPercent = try c.decodeIfPresent(Double.self, forKey: .vaultGoalPercent) ?? 0
        latestPayoutAmount = try c.decodeIfPresent(Double.self, forKey: .latestPayoutAmount) ?? 0
        latestPayoutDate = try c.decodeIfPresent(String.self, forKey: .latestPayoutDate) ?? ""
        taxReadyScore = try c.decodeIfPresent(Int.self, forKey: .taxReadyScore) ?? 0
        quarterlyEstimate = try c.decodeIfPresent(Double.self, forKey: .quarterlyEstimate) ?? 0
        quarterMiles = try c.decodeIfPresent(Double.self, forKey: .quarterMiles) ?? 0
    }

    init(availableToSpend: Double = 0, vaultBalance: Double = 0, vaultGoalPercent: Double = 0, latestPayoutAmount: Double = 0, latestPayoutDate: String = "", taxReadyScore: Int = 0, quarterlyEstimate: Double = 0, quarterMiles: Double = 0) {
        self.availableToSpend = availableToSpend
        self.vaultBalance = vaultBalance
        self.vaultGoalPercent = vaultGoalPercent
        self.latestPayoutAmount = latestPayoutAmount
        self.latestPayoutDate = latestPayoutDate
        self.taxReadyScore = taxReadyScore
        self.quarterlyEstimate = quarterlyEstimate
        self.quarterMiles = quarterMiles
    }
}
