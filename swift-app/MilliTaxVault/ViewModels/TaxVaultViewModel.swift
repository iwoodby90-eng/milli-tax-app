import SwiftUI
import Combine

// MARK: - Tax Vault View Model

@MainActor
final class TaxVaultViewModel: ObservableObject {
    @Published var balance: Double = 1_648.00
    @Published var quarterlyGoal: Double = 2_580.00
    @Published var transactions: [VaultTransaction] = []
    @Published var isLoading = false

    var balanceDisplay: String { milliCurrency(balance) }
    var goalPercent: Double { quarterlyGoal > 0 ? min(balance / quarterlyGoal, 1.0) : 0 }
    var goalPercentDisplay: String { "\(Int(goalPercent * 100))% of quarterly goal" }
    var annualTarget: String { milliCurrency(quarterlyGoal) }

    var displayTransactions: [VaultTransaction] {
        if transactions.isEmpty {
            return [
                VaultTransaction(id: UUID(), title: "Auto-transfer — Spark payout", type: "auto", amount: 78.16, date: "Aug 10, 2026"),
                VaultTransaction(id: UUID(), title: "Auto-transfer — DoorDash", type: "auto", amount: 46.60, date: "Aug 8, 2026"),
                VaultTransaction(id: UUID(), title: "Manual transfer", type: "manual", amount: 200.00, date: "Aug 5, 2026"),
                VaultTransaction(id: UUID(), title: "Interest earned", type: "interest", amount: 2.14, date: "Aug 1, 2026"),
            ]
        }
        return transactions
    }

    func loadVault() async {
        isLoading = false
    }
}
