import SwiftUI

// MARK: - Home Screen Data Models
// Typed model layer for the Home cockpit. All instances carry an explicit
// provenance flag so the UI never presents preview data as authoritative.

enum HomeDataProvenance {
    case preview
    case live
    case cachedLive
    case unavailable
}

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
    let provenance: HomeDataProvenance

    var formattedAmount: String {
        amount.currencyFormatted
    }

    static let preview = SpendableBalance(
        amount: 3428.65,
        lastUpdated: "Updated just now",
        cashflowData: [800, 920, 870, 1040, 990, 1180, 1365],
        provenance: .preview
    )
}

struct LatestPayout {
    let amount: Double
    let timestamp: String
    let source: String
    let sourceIcon: String
    let provenance: HomeDataProvenance

    var formattedAmount: String {
        amount.currencyFormatted
    }

    static let preview = LatestPayout(
        amount: 312.64,
        timestamp: "Today, 9:41 AM",
        source: "Spark Driver",
        sourceIcon: "car.fill",
        provenance: .preview
    )
}

struct TaxVaultStatus {
    let balance: Double
    let annualRate: String
    let provenance: HomeDataProvenance

    var formattedBalance: String {
        balance.currencyFormatted
    }

    static let preview = TaxVaultStatus(
        balance: 5284.17,
        annualRate: "23% annual",
        provenance: .preview
    )
}

struct TaxReadyScore {
    let score: Int
    let maxScore: Int

    static let preview = TaxReadyScore(
        score: 85,
        maxScore: 100
    )
}

struct QuarterlyTaxEstimate {
    let amount: Double
    let dueDate: String
    let provenance: HomeDataProvenance

    var formattedAmount: String {
        amount.currencyFormatted
    }

    static let preview = QuarterlyTaxEstimate(
        amount: 1247.00,
        dueDate: "Est. due Jun 15",
        provenance: .preview
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

    static let preview = MileageStatus(
        miles: 2345,
        period: "This quarter"
    )
}

struct AIInsight {
    let text: String

    static let preview = AIInsight(
        text: "You're on pace to save $3,421 in taxes this year."
    )
}
