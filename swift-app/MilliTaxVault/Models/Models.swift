import Foundation

// MARK: - User & Auth

struct MilliUser: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let tier: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case tier
        case createdAt = "created_at"
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
        case goal
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

// MARK: - Transactions

struct VaultTransaction: Codable, Identifiable {
    let id: String
    let title: String
    let date: String
    let amount: Double
    let type: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case date
        case amount
        case type
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        amount = try c.decodeIfPresent(Double.self, forKey: .amount) ?? 0
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "allocation"
    }

    init(id: String = UUID().uuidString, title: String, date: String, amount: Double, type: String = "allocation") {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.type = type
    }

    var formattedAmount: String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00")"
    }

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()
}

// MARK: - Payouts

struct Payout: Codable, Identifiable {
    let id: String
    let source: String
    let date: String
    let grossAmount: Double
    let platformFee: Double
    let adjustments: Double
    let netAmount: Double
    let taxAllocation: Double
    let mileageDeduction: Double
    let availableToSpend: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case source
        case date
        case grossAmount = "gross_amount"
        case platformFee = "platform_fee"
        case adjustments
        case netAmount = "net_amount"
        case taxAllocation = "tax_allocation"
        case mileageDeduction = "mileage_deduction"
        case availableToSpend = "available_to_spend"
        case status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "Spark Driver\u{2122}"
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        grossAmount = try c.decodeIfPresent(Double.self, forKey: .grossAmount) ?? 0
        platformFee = try c.decodeIfPresent(Double.self, forKey: .platformFee) ?? 0
        adjustments = try c.decodeIfPresent(Double.self, forKey: .adjustments) ?? 0
        netAmount = try c.decodeIfPresent(Double.self, forKey: .netAmount) ?? 0
        taxAllocation = try c.decodeIfPresent(Double.self, forKey: .taxAllocation) ?? 0
        mileageDeduction = try c.decodeIfPresent(Double.self, forKey: .mileageDeduction) ?? 0
        availableToSpend = try c.decodeIfPresent(Double.self, forKey: .availableToSpend) ?? 0
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "processed"
    }

    init(id: String = UUID().uuidString, source: String = "Spark Driver\u{2122}", date: String = "", grossAmount: Double = 0, platformFee: Double = 0, adjustments: Double = 0, netAmount: Double = 0, taxAllocation: Double = 0, mileageDeduction: Double = 0, availableToSpend: Double = 0, status: String = "processed") {
        self.id = id
        self.source = source
        self.date = date
        self.grossAmount = grossAmount
        self.platformFee = platformFee
        self.adjustments = adjustments
        self.netAmount = netAmount
        self.taxAllocation = taxAllocation
        self.mileageDeduction = mileageDeduction
        self.availableToSpend = availableToSpend
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
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case miles
        case deduction
        case isActive = "is_active"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        miles = try c.decodeIfPresent(Double.self, forKey: .miles) ?? 0
        deduction = try c.decodeIfPresent(Double.self, forKey: .deduction) ?? 0
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
    }

    init(id: String = UUID().uuidString, startTime: String = "", endTime: String? = nil, miles: Double = 0, deduction: Double = 0, isActive: Bool = false) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.miles = miles
        self.deduction = deduction
        self.isActive = isActive
    }
}

struct MileageSummary: Codable {
    let todayMiles: Double
    let todayDeduction: Double
    let quarterMiles: Double
    let quarterDeduction: Double
    let yearMiles: Double
    let yearDeduction: Double

    enum CodingKeys: String, CodingKey {
        case todayMiles = "today_miles"
        case todayDeduction = "today_deduction"
        case quarterMiles = "quarter_miles"
        case quarterDeduction = "quarter_deduction"
        case yearMiles = "year_miles"
        case yearDeduction = "year_deduction"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        todayMiles = try c.decodeIfPresent(Double.self, forKey: .todayMiles) ?? 0
        todayDeduction = try c.decodeIfPresent(Double.self, forKey: .todayDeduction) ?? 0
        quarterMiles = try c.decodeIfPresent(Double.self, forKey: .quarterMiles) ?? 0
        quarterDeduction = try c.decodeIfPresent(Double.self, forKey: .quarterDeduction) ?? 0
        yearMiles = try c.decodeIfPresent(Double.self, forKey: .yearMiles) ?? 0
        yearDeduction = try c.decodeIfPresent(Double.self, forKey: .yearDeduction) ?? 0
    }

    init(todayMiles: Double = 0, todayDeduction: Double = 0, quarterMiles: Double = 0, quarterDeduction: Double = 0, yearMiles: Double = 0, yearDeduction: Double = 0) {
        self.todayMiles = todayMiles
        self.todayDeduction = todayDeduction
        self.quarterMiles = quarterMiles
        self.quarterDeduction = quarterDeduction
        self.yearMiles = yearMiles
        self.yearDeduction = yearDeduction
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
        case id = "item_id"
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
