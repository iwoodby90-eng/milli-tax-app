import SwiftUI
import Combine

// MARK: - HomeViewModel — Drives the Home dashboard

final class HomeViewModel: ObservableObject {
    // Production-safe defaults. The previous implementation seeded attractive
    // presentation numbers into the authenticated Home surface. Keep the visual
    // hierarchy, but never imply live financial truth until an authoritative
    // dashboard snapshot is connected.
    @Published var availableToSpend: String = "Unavailable"
    @Published var sparklineData: [CGFloat] = []
    @Published var latestPayout: PayoutEntry? = nil
    @Published var taxVaultBalance: String = "Unavailable"
    @Published var taxVaultProgress: CGFloat? = nil
    @Published var taxReadyScore: Int? = nil
    @Published var quarterlyTaxes: String = "Unavailable"
    @Published var quarterlyDueLabel: String = "Awaiting tax profile"
    @Published var mileage: String = "Unavailable"
    @Published var aiInsight: String = "Connect verified financial data to unlock grounded Milli AI insights."
    @Published var provenance: ProvenanceLabel = .unavailable
    @Published var isLoading: Bool = false

    init() {
        loadData()
    }

    func loadData() {
        // Production integration point: hydrate this model from the authenticated
        // dashboard snapshot / repositories. Until then, values intentionally
        // remain UNAVAILABLE rather than using reference numbers as if live.
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
    let provenance: ProvenanceLabel

    static let demo = PayoutEntry(
        platformName: "Amazon Flex",
        platformAssetName: "amazon-flex-icon",
        dateTime: "Demo payout",
        amount: "$187.42",
        provenance: .demo
    )
}
