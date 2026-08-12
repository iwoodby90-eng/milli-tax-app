import SwiftUI
import Combine

// MARK: - Tax Vault View Model
// VaultTransaction is defined in Models.swift — no duplicate here.

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
                VaultTransaction(id: UUID().uuidString, title: "Auto-transfer — Spark payout", date: "Aug 10, 2026", amount: 78.16, type: "auto"),
                VaultTransaction(id: UUID().uuidString, title: "Auto-transfer — DoorDash", date: "Aug 8, 2026", amount: 46.60, type: "auto"),
                VaultTransaction(id: UUID().uuidString, title: "Manual transfer", date: "Aug 5, 2026", amount: 200.00, type: "manual"),
                VaultTransaction(id: UUID().uuidString, title: "Interest earned", date: "Aug 1, 2026", amount: 2.14, type: "interest"),
            ]
        }
        return transactions
    }

    func loadVault() async {
        isLoading = false
    }
}
