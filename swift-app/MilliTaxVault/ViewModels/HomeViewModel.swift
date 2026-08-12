import SwiftUI
import Combine

// MARK: - Home View Model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var availableToSpend: String = "$2,847.65"
    @Published var latestPayoutAmount: String = "$312.64"
    @Published var latestPayoutDate: String = "Aug 10"
    @Published var vaultBalance: String = "$1,648.00"
    @Published var vaultGoalPercent: Int = 64
    @Published var quarterlyEstimate: String = "$2,580.00"
    @Published var isLoading = false

    func loadDashboard() async {
        // In production, fetch from API
        isLoading = false
    }
}
