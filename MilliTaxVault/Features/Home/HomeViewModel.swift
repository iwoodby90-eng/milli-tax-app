import SwiftUI
import Combine

// MARK: - HomeViewModel — Drives the Home dashboard

final class HomeViewModel: ObservableObject {
    // Seeded presentation values mirror the approved Milli visual reference.
    // Production data should replace these through the authenticated dashboard snapshot.
    @Published var availableToSpend: String = "$3,428.65"
    @Published var sparklineData: [CGFloat] = [0.28, 0.42, 0.36, 0.51, 0.47, 0.63, 0.58, 0.72, 0.67, 0.82]
    @Published var latestPayout: PayoutEntry = .placeholder
    @Published var taxVaultBalance: String = "$5,284.17"
    @Published var taxReadyScore: Int = 85
    @Published var quarterlyTaxes: String = "$1,247.00"
    @Published var quarterlyDueLabel: String = "Due Sep 16"
    @Published var mileage: String = "2,847.6 mi"
    @Published var aiInsight: String = "$621 potential deduction increase if you drive 200 more business miles this month."
    // Seeded values are presentation placeholders — they must read as DEMO until
    // the authenticated dashboard snapshot replaces them (data truth, Section 07).
    @Published var availableToSpendProvenance: ProvenanceState = .demo
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
        platformName: "Amazon Flex",
        platformAssetName: "amazon-flex-icon",
        dateTime: "Today, 2:34 PM",
        amount: "$187.42"
    )
}
