import SwiftUI

// MARK: - Home Screen Data Models

// MARK: Currency Formatter Extension
extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

struct SpendableBalance {
    let amount: Double
    let lastUpdated: String
    let cashflowData: [Double]
    
    var formattedAmount: String {
        amount.currencyFormatted
    }
    
    static let demo = SpendableBalance(
        amount: 1365.42,
        lastUpdated: "Updated just now",
        cashflowData: [800, 920, 870, 1040, 990, 1180, 1365]
    )
}

struct LatestPayout {
    let amount: Double
    let timestamp: String
    let source: String
    let sourceIcon: String
    
    var formattedAmount: String {
        amount.currencyFormatted
    }
    
    static let demo = LatestPayout(
        amount: 312.64,
        timestamp: "Today, 9:41 AM",
        source: "Spark Driver",
        sourceIcon: "car.fill"
    )
}

struct TaxVaultStatus {
    let balance: Double
    let annualRate: String
    
    var formattedBalance: String {
        balance.currencyFormatted
    }
    
    static let demo = TaxVaultStatus(
        balance: 5284.17,
        annualRate: "23% annual"
    )
}

struct TaxReadyScore {
    let score: Int
    let maxScore: Int
    let label: String
    
    static let demo = TaxReadyScore(
        score: 85,
        maxScore: 100,
        label: "Great"
    )
}

struct QuarterlyTaxEstimate {
    let amount: Double
    let dueDate: String
    
    var formattedAmount: String {
        amount.currencyFormatted
    }
    
    static let demo = QuarterlyTaxEstimate(
        amount: 1247.00,
        dueDate: "Est. due Jun 15"
    )
}

struct MileageStatus {
    let miles: Int
    let period: String
    
    var formattedMiles: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }
    
    static let demo = MileageStatus(
        miles: 2345,
        period: "This quarter"
    )
}

struct AIInsight {
    let text: String
    
    static let demo = AIInsight(
        text: "You're on pace to save $3,421 in taxes this year."
    )
}
