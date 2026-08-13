import SwiftUI
import Combine

// MARK: - HomeViewModel — Drives the Home screen data
// Connects to existing data sources. Uses demo data for seeding.

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var spendableBalance: SpendableBalance = .demo
    @Published var latestPayout: LatestPayout = .demo
    @Published var taxVault: TaxVaultStatus = .demo
    @Published var taxReadyScore: TaxReadyScore = .demo
    @Published var quarterlyTax: QuarterlyTaxEstimate = .demo
    @Published var mileage: MileageStatus = .demo
    @Published var aiInsight: AIInsight = .demo
    @Published var isLoading: Bool = false
    
    init() {
        // In production, wire to real data sources / API calls here
        loadData()
    }
    
    func loadData() {
        // Placeholder for async data fetch
        // When real APIs are connected, this will populate from network
        isLoading = false
    }
    
    func refreshData() {
        isLoading = true
        // Simulate refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.isLoading = false
        }
    }
}
