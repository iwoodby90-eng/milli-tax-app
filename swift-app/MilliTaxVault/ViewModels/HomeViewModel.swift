import SwiftUI

// MARK: - Home View Model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    // Fallback static values (shown when API is unreachable or user is unauthenticated)
    var availableToSpend: String {
        formatCurrency(summary?.availableToSpend ?? 1365.42)
    }

    var latestPayoutAmount: String {
        formatCurrency(summary?.latestPayoutAmount ?? 312.64)
    }

    var latestPayoutDate: String {
        summary?.latestPayoutDate ?? "Today, 9:41 AM"
    }

    var vaultBalance: String {
        formatCurrency(summary?.vaultBalance ?? 5284.17)
    }

    var vaultGoalPercent: Int {
        Int(summary?.vaultGoalPercent ?? 23)
    }

    var taxReadyScore: Int {
        summary?.taxReadyScore ?? 85
    }

    var quarterlyEstimate: String {
        formatCurrency(summary?.quarterlyEstimate ?? 1247.00)
    }

    var quarterMiles: String {
        let miles = summary?.quarterMiles ?? 2345
        return "\(Int(miles).formatted()) mi"
    }

    func loadDashboard() async {
        guard api.isAuthenticated else { return }
        isLoading = true
        do {
            summary = try await api.request(path: "/dashboard/summary")
        } catch {
            // Use fallback static data — no error shown to user
            errorMessage = nil
        }
        isLoading = false
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
