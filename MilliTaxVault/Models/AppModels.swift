import SwiftUI

// MARK: - Tab Model

enum MilliTab: Int, CaseIterable {
    case vault = 0
    case wealth = 1
    case activity = 2
    case cockpit = 3
    
    var icon: String {
        switch self {
        case .vault: return "shield.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"
        case .activity: return "bolt.fill"
        case .cockpit: return "dial.high.fill"
        }
    }
    
    var title: String {
        switch self {
        case .vault: return "Vault"
        case .wealth: return "Wealth"
        case .activity: return "Activity"
        case .cockpit: return "Cockpit"
        }
    }
}

// MARK: - Transaction Model

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: String
    let icon: String
    let isPositive: Bool
    let date: String
}

// MARK: - Income Source Model

struct IncomeSource: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let earnings: Double
    let percentage: Double
    let color: Color
}

// MARK: - Payout Model

struct Payout: Identifiable {
    let id = UUID()
    let platform: String
    let date: String
    let amount: Double
    let taxWithheld: Double
    let icon: String
}

// MARK: - Breakdown Item Model

struct BreakdownItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let color: Color
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let value: Double
}

// MARK: - Settings Row Model

struct SettingsRow: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let iconColor: Color
}

// MARK: - Sample Data

enum SampleData {
    static let transactions: [Transaction] = [
        Transaction(title: "Auto-Transfer", subtitle: "From Spark Driver", amount: "+$48.20", icon: "arrow.triangle.2.circlepath", isPositive: true, date: "Today"),
        Transaction(title: "Manual Deposit", subtitle: "Weekly top-up", amount: "+$125.00", icon: "plus.circle.fill", isPositive: true, date: "Aug 10"),
        Transaction(title: "Auto-Transfer", subtitle: "From DoorDash", amount: "+$31.75", icon: "arrow.triangle.2.circlepath", isPositive: true, date: "Aug 9"),
        Transaction(title: "Interest Earned", subtitle: "Monthly yield", amount: "+$2.14", icon: "sparkles", isPositive: true, date: "Aug 8"),
        Transaction(title: "Auto-Transfer", subtitle: "From Instacart", amount: "+$22.60", icon: "arrow.triangle.2.circlepath", isPositive: true, date: "Aug 7")
    ]
    
    static let incomeSources: [IncomeSource] = [
        IncomeSource(name: "Spark Driver", icon: "car.fill", earnings: 396.45, percentage: 0.45, color: MilliColors.cyan),
        IncomeSource(name: "DoorDash", icon: "bag.fill", earnings: 264.30, percentage: 0.30, color: MilliColors.green),
        IncomeSource(name: "Instacart", icon: "cart.fill", earnings: 220.25, percentage: 0.25, color: MilliColors.amber)
    ]
    
    static let payouts: [Payout] = [
        Payout(platform: "Spark Driver", date: "Aug 11", amount: 142.80, taxWithheld: 35.70, icon: "car.fill"),
        Payout(platform: "DoorDash", date: "Aug 10", amount: 98.50, taxWithheld: 24.63, icon: "bag.fill"),
        Payout(platform: "Instacart", date: "Aug 9", amount: 76.20, taxWithheld: 19.05, icon: "cart.fill"),
        Payout(platform: "Spark Driver", date: "Aug 8", amount: 118.40, taxWithheld: 29.60, icon: "car.fill"),
        Payout(platform: "DoorDash", date: "Aug 7", amount: 91.30, taxWithheld: 22.83, icon: "bag.fill")
    ]
    
    static let breakdownItems: [BreakdownItem] = [
        BreakdownItem(label: "Tax Vault", amount: 1648, color: MilliColors.cyan),
        BreakdownItem(label: "Checking", amount: 2145.80, color: MilliColors.green),
        BreakdownItem(label: "Savings", amount: 4320.50, color: MilliColors.amber)
    ]
    
    static let chartData: [ChartDataPoint] = [
        ChartDataPoint(day: 1, value: 6200),
        ChartDataPoint(day: 5, value: 6350),
        ChartDataPoint(day: 10, value: 6580),
        ChartDataPoint(day: 15, value: 6420),
        ChartDataPoint(day: 20, value: 6900),
        ChartDataPoint(day: 25, value: 7200),
        ChartDataPoint(day: 30, value: 7450),
        ChartDataPoint(day: 35, value: 7680),
        ChartDataPoint(day: 40, value: 7890),
        ChartDataPoint(day: 45, value: 8114)
    ]
    
    static let sparklineData: [ChartDataPoint] = [
        ChartDataPoint(day: 1, value: 1050),
        ChartDataPoint(day: 2, value: 1080),
        ChartDataPoint(day: 3, value: 1040),
        ChartDataPoint(day: 4, value: 1120),
        ChartDataPoint(day: 5, value: 1200),
        ChartDataPoint(day: 6, value: 1180),
        ChartDataPoint(day: 7, value: 1365)
    ]
}
