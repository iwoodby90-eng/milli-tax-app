import Foundation
import Combine
import SwiftUI

// MARK: - ExpenseStore
// Persistent expense and receipt store for MILLI (D5 sprint feature).
//
// Follows the same UserDefaults persistence pattern as BankConnectionService:
//   - Codable models (ExpenseItem, ReceiptItem) are encoded/decoded to UserDefaults.
//   - The store is @MainActor ObservableObject so SwiftUI views can observe it.
//   - Seeded demo data is used ONLY on first launch; once the user adds or
//     removes an item, the persisted state is authoritative.
//   - All amounts are Double (display-layer currency). The store does not
//     fabricate financial truth — it persists user-entered data only.
//
// Data-truth rule: seeded data carries no provenance label because the
// ExpensesView is a local tracking tool, not a live financial feed. The
// seeded items are clearly demo content that the user can delete.

@MainActor
final class ExpenseStore: ObservableObject {

    @Published private(set) var expenses: [ExpenseItem] = []
    @Published private(set) var receipts: [ReceiptItem] = []

    private let storageKeyExpenses = "milli_expenses_v1"
    private let storageKeyReceipts = "milli_receipts_v1"
    private let storageKeySeeded = "milli_expenses_seeded_v1"

    init() {
        loadFromStorage()
    }

    // MARK: - Public API

    func addExpense(_ item: ExpenseItem) {
        expenses.insert(item, at: 0)
        persist()
    }

    func addReceipt(_ item: ReceiptItem) {
        receipts.insert(item, at: 0)
        persist()
    }

    func deleteExpense(at index: Int) {
        guard expenses.indices.contains(index) else { return }
        expenses.remove(at: index)
        persist()
    }

    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
        persist()
    }

    func deleteReceipt(id: UUID) {
        receipts.removeAll { $0.id == id }
        persist()
    }

    var totalDeductions: Double {
        expenses.filter(\.isDeductible).reduce(0) { $0 + $1.amount }
    }

    var linkedReceiptCount: Int {
        receipts.filter(\.isLinked).count
    }

    /// Clears all data and re-seeds with demo content. For testing / reset.
    func resetToSeed() {
        expenses = ExpenseItem.seeded
        receipts = ReceiptItem.seeded
        persist()
    }

    /// Clears all data completely.
    func clearAll() {
        expenses = []
        receipts = []
        persist()
    }

    // MARK: - Persistence

    private func loadFromStorage() {
        let defaults = UserDefaults.standard
        let hasSeeded = defaults.bool(forKey: storageKeySeeded)

        if !hasSeeded {
            // First launch: seed with demo content.
            expenses = ExpenseItem.seeded
            receipts = ReceiptItem.seeded
            persist()
            defaults.set(true, forKey: storageKeySeeded)
            return
        }

        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: storageKeyExpenses),
           let saved = try? decoder.decode([ExpenseItem].self, from: data) {
            expenses = saved
        }
        if let data = defaults.data(forKey: storageKeyReceipts),
           let saved = try? decoder.decode([ReceiptItem].self, from: data) {
            receipts = saved
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(expenses) {
            UserDefaults.standard.set(data, forKey: storageKeyExpenses)
        }
        if let data = try? encoder.encode(receipts) {
            UserDefaults.standard.set(data, forKey: storageKeyReceipts)
        }
    }
}
