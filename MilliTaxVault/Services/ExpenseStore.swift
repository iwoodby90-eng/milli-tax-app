import Foundation
import Combine
import SwiftUI

// MARK: - ExpenseStore
// App-private persistence for user-entered expenses and receipts.
//
// Security rules:
// - production never seeds plausible financial records;
// - expense/receipt data is never stored in UserDefaults;
// - the on-device snapshot uses complete file protection;
// - deterministic demo content exists only in explicit DEBUG screenshot mode.

private struct ExpenseStoreSnapshot: Codable {
    let expenses: [ExpenseItem]
    let receipts: [ReceiptItem]
}

@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var expenses: [ExpenseItem] = []
    @Published private(set) var receipts: [ReceiptItem] = []

    private let storageURL: URL
    private let demoSeedEnabled: Bool

    init(storageURL: URL? = nil, demoSeed: Bool? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        self.demoSeedEnabled = demoSeed ?? Self.defaultDemoSeedEnabled()
        load()
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

    /// Explicit demo helper for DEBUG/test surfaces. Production initialization
    /// never calls this automatically.
    func resetToSeed() {
        expenses = ExpenseItem.seeded
        receipts = ReceiptItem.seeded
        if !demoSeedEnabled {
            persist()
        }
    }

    func clearAll() {
        expenses = []
        receipts = []
        persist()
    }

    // MARK: - Protected persistence

    private func load() {
        if demoSeedEnabled {
            expenses = ExpenseItem.seeded
            receipts = ReceiptItem.seeded
            return
        }

        guard let data = try? Data(contentsOf: storageURL),
              let snapshot = try? JSONDecoder().decode(ExpenseStoreSnapshot.self, from: data)
        else {
            expenses = []
            receipts = []
            return
        }

        expenses = snapshot.expenses
        receipts = snapshot.receipts
    }

    private func persist() {
        // Screenshot/demo data must never be written into a customer's store.
        guard !demoSeedEnabled else { return }

        let snapshot = ExpenseStoreSnapshot(
            expenses: expenses,
            receipts: receipts
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        do {
            let directory = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try data.write(
                to: storageURL,
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            // Fail closed: keep the in-memory edits for this session but never
            // downgrade protected financial data into UserDefaults/plaintext.
        }
    }

    private static func defaultStorageURL() -> URL {
        let root = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return root
            .appendingPathComponent("Milli", isDirectory: true)
            .appendingPathComponent("expense-store-v2.json", isDirectory: false)
    }

    private static func defaultDemoSeedEnabled() -> Bool {
        #if DEBUG
        let info = ProcessInfo.processInfo
        return info.environment["MILLI_SCREENSHOT_MODE"] == "1"
            || info.environment["MILLI_SCREEN"] != nil
            || info.arguments.contains("-milliScreenshotMode")
        #else
        return false
        #endif
    }
}
