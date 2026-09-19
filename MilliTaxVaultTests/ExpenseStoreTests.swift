import XCTest
@testable import MilliTaxVault

// MARK: - ExpenseStoreTests
// Financial records persist in an app-private file, never UserDefaults.
// Tests inject a temporary URL so they cannot touch real app state.

@MainActor
final class ExpenseStoreTests: XCTestCase {
    private var directoryURL: URL!
    private var storageURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("milli-expense-test-\(UUID().uuidString)", isDirectory: true)
        storageURL = directoryURL.appendingPathComponent("expense-store.json")
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() async throws {
        if let directoryURL {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        directoryURL = nil
        storageURL = nil
        try await super.tearDown()
    }

    private func makeStore(demoSeed: Bool = false) -> ExpenseStore {
        ExpenseStore(storageURL: storageURL, demoSeed: demoSeed)
    }

    // MARK: - Model tests

    func testExpenseItemCodableRoundTrip() throws {
        let original = ExpenseItem(
            merchant: "Shell Gas",
            category: .fuel,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            amount: 52.30,
            isDeductible: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ExpenseItem.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.category, .fuel)
        XCTAssertEqual(decoded.merchant, "Shell Gas")
        XCTAssertEqual(decoded.amount, 52.30, accuracy: 0.001)
        XCTAssertTrue(decoded.isDeductible)
    }

    func testReceiptItemCodableRoundTrip() throws {
        let original = ReceiptItem(
            merchant: "Jiffy Lube",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            amount: 89.75,
            isLinked: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReceiptItem.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.merchant, "Jiffy Lube")
        XCTAssertEqual(decoded.amount, 89.75, accuracy: 0.001)
        XCTAssertFalse(decoded.isLinked)
    }

    func testExpenseCategoryAllCasesCovered() {
        let categories = ExpenseCategory.allCases
        XCTAssertEqual(categories.count, 7)
        let rawValues = Set(categories.map(\.rawValue))
        XCTAssertTrue(rawValues.contains("fuel"))
        XCTAssertTrue(rawValues.contains("maintenance"))
        XCTAssertTrue(rawValues.contains("parking"))
        XCTAssertTrue(rawValues.contains("supplies"))
        XCTAssertTrue(rawValues.contains("insurance"))
        XCTAssertTrue(rawValues.contains("professional"))
        XCTAssertTrue(rawValues.contains("other"))
    }

    // MARK: - Data truth

    func testProductionStoreStartsEmptyWithoutProtectedSnapshot() {
        let store = makeStore()
        XCTAssertTrue(store.expenses.isEmpty)
        XCTAssertTrue(store.receipts.isEmpty)
    }

    func testExplicitDemoStoreCanLoadReferenceDataWithoutWritingIt() {
        let store = makeStore(demoSeed: true)
        XCTAssertEqual(store.expenses.count, ExpenseItem.seeded.count)
        XCTAssertEqual(store.receipts.count, ReceiptItem.seeded.count)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storageURL.path))
    }

    // MARK: - Store CRUD

    func testAddExpenseInsertsAtFront() {
        let store = makeStore()
        let newItem = ExpenseItem(
            merchant: "Test Expense",
            category: .supplies,
            date: Date(),
            amount: 15.00,
            isDeductible: true
        )
        store.addExpense(newItem)
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertEqual(store.expenses.first?.merchant, "Test Expense")
    }

    func testAddReceiptInsertsAtFront() {
        let store = makeStore()
        let newItem = ReceiptItem(
            merchant: "Test Receipt",
            date: Date(),
            amount: 25.00,
            isLinked: false
        )
        store.addReceipt(newItem)
        XCTAssertEqual(store.receipts.count, 1)
        XCTAssertEqual(store.receipts.first?.merchant, "Test Receipt")
    }

    func testDeleteExpenseByID() {
        let store = makeStore()
        let item = ExpenseItem(
            merchant: "Delete Me",
            category: .other,
            date: Date(),
            amount: 10.00,
            isDeductible: false
        )
        store.addExpense(item)
        store.deleteExpense(id: item.id)
        XCTAssertFalse(store.expenses.contains { $0.id == item.id })
    }

    func testDeleteReceiptByID() {
        let store = makeStore()
        let item = ReceiptItem(
            merchant: "Delete Me",
            date: Date(),
            amount: 10.00,
            isLinked: true
        )
        store.addReceipt(item)
        store.deleteReceipt(id: item.id)
        XCTAssertFalse(store.receipts.contains { $0.id == item.id })
    }

    // MARK: - Derived values

    func testTotalDeductionsOnlyCountsDeductible() {
        let store = makeStore()
        store.addExpense(ExpenseItem(merchant: "A", category: .fuel, date: Date(), amount: 100, isDeductible: true))
        store.addExpense(ExpenseItem(merchant: "B", category: .other, date: Date(), amount: 50, isDeductible: false))
        store.addExpense(ExpenseItem(merchant: "C", category: .supplies, date: Date(), amount: 25, isDeductible: true))
        XCTAssertEqual(store.totalDeductions, 125, accuracy: 0.001)
    }

    func testLinkedReceiptCount() {
        let store = makeStore()
        store.addReceipt(ReceiptItem(merchant: "A", date: Date(), amount: 10, isLinked: true))
        store.addReceipt(ReceiptItem(merchant: "B", date: Date(), amount: 20, isLinked: false))
        store.addReceipt(ReceiptItem(merchant: "C", date: Date(), amount: 30, isLinked: true))
        XCTAssertEqual(store.linkedReceiptCount, 2)
    }

    // MARK: - Persistence

    func testClearAllEmptiesBothArrays() {
        let store = makeStore()
        store.addExpense(ExpenseItem(merchant: "A", category: .fuel, date: Date(), amount: 10, isDeductible: true))
        store.addReceipt(ReceiptItem(merchant: "A", date: Date(), amount: 10, isLinked: true))
        store.clearAll()
        XCTAssertTrue(store.expenses.isEmpty)
        XCTAssertTrue(store.receipts.isEmpty)
    }

    func testResetToSeedIsExplicitOnly() {
        let store = makeStore()
        XCTAssertTrue(store.expenses.isEmpty)
        store.resetToSeed()
        XCTAssertEqual(store.expenses.count, ExpenseItem.seeded.count)
        XCTAssertEqual(store.receipts.count, ReceiptItem.seeded.count)
    }

    func testProtectedFilePersistenceSurvivesNewInstance() {
        let store1 = makeStore()
        let item = ExpenseItem(
            merchant: "Persistent",
            category: .fuel,
            date: Date(),
            amount: 42.00,
            isDeductible: true
        )
        store1.addExpense(item)

        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))

        let store2 = makeStore()
        XCTAssertTrue(store2.expenses.contains { $0.merchant == "Persistent" })
    }

    // MARK: - Edge cases

    func testDeleteNonExistentIDIsNoOp() {
        let store = makeStore()
        let countBefore = store.expenses.count
        store.deleteExpense(id: UUID())
        XCTAssertEqual(store.expenses.count, countBefore)
    }

    func testDeleteReceiptNonExistentIDIsNoOp() {
        let store = makeStore()
        let countBefore = store.receipts.count
        store.deleteReceipt(id: UUID())
        XCTAssertEqual(store.receipts.count, countBefore)
    }

    func testDeleteExpenseAtInvalidIndexIsNoOp() {
        let store = makeStore()
        let countBefore = store.expenses.count
        store.deleteExpense(at: 999)
        XCTAssertEqual(store.expenses.count, countBefore)
    }
}
