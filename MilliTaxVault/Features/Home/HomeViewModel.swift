import SwiftUI
import Combine

// MARK: - HomeViewModel — Drives the Home dashboard

final class HomeViewModel: ObservableObject {
    @Published var availableToSpend: String = "$1,365.42"
    @Published var sparklineData: [CGFloat] = [0.3, 0.5, 0.4, 0.6, 0.55, 0.7, 0.65, 0.8, 0.75, 0.85]
    @Published var latestPayout: PayoutEntry = .placeholder
    @Published var taxVaultBalance: String = "$5,284.17"
    @Published var taxReadyScore: Int = 85
    @Published var quarterlyTaxes: String = "$1,247.00"
    @Published var mileage: String = "2,345 mi"
    @Published var aiInsight: String = "You're on pace to save $3,421 in taxes this year."
    @Published var isLoading: Bool = false

    init() {
        loadData()
    }

    func loadData() {
        // In production, fetch from API / local store.
        // Placeholder data matching the master reference.
        isLoading = false
    }
}

// MARK: - PayoutEntry

struct PayoutEntry: Identifiable {
    let id = UUID()
    let platformName: String
    let platformInitial: String
    let dateTime: String
    let amount: String

    static let placeholder = PayoutEntry(
        platformName: "Spark Drive",
        platformInitial: "S",
        dateTime: "Today, 9:41 AM",
        amount: "+$312.64"
    )
}
