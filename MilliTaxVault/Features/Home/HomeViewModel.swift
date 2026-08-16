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
    @Published var quarterlyDueLabel: String = "Next estimated payment"
    @Published var mileage: String = "2,345 mi"
    @Published var aiInsight: String = "You're on pace to save $3,421 in taxes this year."
    @Published var isLoading: Bool = false

    init() {
        loadData()
    }

    func loadData() {
        // Production integration point: replace seeded preview values with the
        // authenticated dashboard snapshot/local store without changing HomeView.
        isLoading = false
    }
}

// MARK: - PayoutEntry

struct PayoutEntry: Identifiable {
    let id = UUID()
    let platformName: String
    let platformAssetName: String
    let dateTime: String
    let amount: String

    static let placeholder = PayoutEntry(
        platformName: "Spark Driver",
        platformAssetName: "spark-driver-icon",
        dateTime: "Today, 9:41 AM",
        amount: "$312.64"
    )
}
