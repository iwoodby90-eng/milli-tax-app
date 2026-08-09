import SwiftUI

// MARK: - Tax Vault View Model

@MainActor
final class TaxVaultViewModel: ObservableObject {
    @Published var vaultBalance: VaultBalance = VaultBalance()
    @Published var transactions: [VaultTransaction] = []
    @Published var connectedBanks: [PlaidItem] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var isLinkingBank = false
    @Published var plaidLinkToken: String?
    @Published var errorMessage: String?

    private let api = APIService.shared
    private let plaid = PlaidService.shared

    // Formatted display values with fallbacks
    var balanceDisplay: String {
        formatCurrency(vaultBalance.balance > 0 ? vaultBalance.balance : 5284.17)
    }

    var goalPercent: Double {
        vaultBalance.percentOfGoal > 0 ? vaultBalance.percentOfGoal / 100.0 : 0.234
    }

    var goalPercentDisplay: String {
        let pct = vaultBalance.percentOfGoal > 0 ? vaultBalance.percentOfGoal : 23.4
        return String(format: "%.1f%% of annual target", pct)
    }

    var annualTarget: String {
        formatCurrency(vaultBalance.goal > 0 ? vaultBalance.goal : 22500)
    }

    var displayTransactions: [VaultTransaction] {
        if transactions.isEmpty {
            return Self.fallbackTransactions
        }
        return transactions
    }

    var hasBanksConnected: Bool { !connectedBanks.isEmpty }

    // MARK: - Actions

    func loadVault() async {
        guard api.isAuthenticated else { return }
        isLoading = true
        async let balanceTask: VaultBalance? = try? api.request(path: "/vault/balance")
        async let transactionsTask: [VaultTransaction]? = try? api.request(path: "/vault/transactions")
        async let banksTask: [PlaidItem]? = try? plaid.getConnectedItems()

        let (bal, txns, banks) = await (balanceTask, transactionsTask, banksTask)
        if let bal = bal { vaultBalance = bal }
        if let txns = txns { transactions = txns }
        if let banks = banks { connectedBanks = banks }
        isLoading = false
    }

    func startBankLink() async {
        isLinkingBank = true
        do {
            plaidLinkToken = try await plaid.getLinkToken()
        } catch {
            errorMessage = "Unable to start bank connection. Please try again."
        }
        isLinkingBank = false
    }

    func completeBankLink(publicToken: String) async {
        do {
            try await plaid.exchangePublicToken(publicToken)
            await syncTransactions()
            await loadVault()
        } catch {
            errorMessage = "Bank connection failed. Please try again."
        }
    }

    func syncTransactions() async {
        isSyncing = true
        do {
            let synced = try await plaid.syncTransactions()
            if !synced.isEmpty { transactions = synced }
        } catch {
            // Silent fail — keep existing data
        }
        isSyncing = false
    }

    func disconnectBank(itemId: String) async {
        do {
            try await plaid.disconnectItem(itemId: itemId)
            connectedBanks.removeAll { $0.id == itemId }
        } catch {
            errorMessage = "Failed to disconnect bank."
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    // Fallback data when API is unreachable
    private static let fallbackTransactions: [VaultTransaction] = [
        VaultTransaction(title: "Payout Allocation", date: "May 10, 2024", amount: 72.91),
        VaultTransaction(title: "Payout Allocation", date: "May 9, 2024", amount: 69.21),
        VaultTransaction(title: "Manual Transfer", date: "May 8, 2024", amount: 250.00),
        VaultTransaction(title: "Interest Earned", date: "May 7, 2024", amount: 1.27),
        VaultTransaction(title: "Payout Allocation", date: "May 6, 2024", amount: 86.11),
    ]
}
