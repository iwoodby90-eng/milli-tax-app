import SwiftUI
import Combine

// MARK: - Payouts View Model

@MainActor
final class PayoutsViewModel: ObservableObject {
    @Published var payouts: [PayoutEntry] = []
    @Published var isLoading = false
    @Published var weeklyTotal: Double = 0.0

    struct PayoutEntry: Identifiable {
        let id = UUID()
        let source: String
        let amount: Double
        let date: String
        let status: String
    }

    func loadPayouts() async {
        isLoading = false
    }
}
