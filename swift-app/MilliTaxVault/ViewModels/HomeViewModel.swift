import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var totalEarnings: Double = 2_847.40
    @Published var vaultBalanceValue: Double = 1_648.00
    @Published var quarterlyGoalValue: Double = 2_580.00
    @Published var latestPayoutValue: Double = 312.64
    @Published var isLoading = false

    var availableToSpend: String { milliCurrency(totalEarnings - vaultBalanceValue) }
    var vaultBalance: String { milliCurrency(vaultBalanceValue) }
    var quarterlyEstimate: String { milliCurrency(quarterlyGoalValue) }
    var latestPayoutAmount: String { milliCurrency(latestPayoutValue, fraction: 2) }
    var latestPayoutDate: String { "Aug 10" }
    var vaultGoalPercent: Int { Int(min(vaultBalanceValue / quarterlyGoalValue, 1.0) * 100) }

    func loadDashboard() async {
        isLoading = false
    }
}
