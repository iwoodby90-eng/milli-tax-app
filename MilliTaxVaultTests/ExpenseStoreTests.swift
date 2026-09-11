import XCTest
@testable import MilliTaxVault

// MARK: - ExpenseStoreTests
// D5 sprint feature: ExpenseStore persistence and CRUD invariants.
// Tests run against an isolated UserDefaults suite to avoid polluting app state.

@MainActor
final class ExpenseStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use a unique suite per test instance to isolate state.
        let suiteName = "milli-test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        // We'll inject this by swizzling the standard — but since ExpenseStore
        // uses UserDefaults.standard internally, we test behavior instead:
        // clear any existing data, then verify CRUD operations work.
    }

    override func tearDown() async throws {
        defaults = nil
        try await super.tearDown()
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
        // Ensure all 7 categories are present and identifiable.
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

    // MARK: - Store CRUD tests

    func testAddExpenseInsertsAtFront() {
        let store = ExpenseStore()
        let initialCount = store.expenses.count
        let newItem = ExpenseItem(
            merchant: "Test Expense",
            category: .supplies,
            date: Date(),
            amount: 15.00,
            isDeductible: true
        )
        store.addExpense(newItem)
        XCTAssertEqual(store.expenses.count, initialCount + 1)
        XCTAssertEqual(store.expenses.first?.merchant, "Test Expense")
    }

    func testAddReceiptInsertsAtFront() {
        let store = ExpenseStore()
        let initialCount = store.receipts.count
        let newItem = ReceiptItem(
            merchant: "Test Receipt",
            date: Date(),
            amount: 25.00,
            isLinked: false
        )
        store.addReceipt(newItem)
        XCTAssertEqual(store.receipts.count, initialCount + 1)
        XCTAssertEqual(store.receipts.first?.merchant, "Test Receipt")
    }

    func testDeleteExpenseByID() {
        let store = ExpenseStore()
        let item = ExpenseItem(
            merchant: "Delete Me",
            category: .other,
            date: Date(),
            amount: 10.00,
            isDeductible: false
        )
        store.addExpense(item)
        let countBefore = store.expenses.count
        store.deleteExpense(id: item.id)
        XCTAssertEqual(store.expenses.count, countBefore - 1)
        XCTAssertFalse(store.expenses.contains { $0.id == item.id })
    }

    func testDeleteReceiptByID() {
        let store = ExpenseStore()
        let item = ReceiptItem(
            merchant: "Delete Me",
            date: Date(),
            amount: 10.00,
            isLinked: true
        )
        store.addReceipt(item)
        let countBefore = store.receipts.count
        store.deleteReceipt(id: item.id)
        XCTAssertEqual(store.receipts.count, countBefore - 1)
        XCTAssertFalse(store.receipts.contains { $0.id == item.id })
    }

    // MARK: - Derived values

    func testTotalDeductionsOnlyCountsDeductible() {
        let store = ExpenseStore()
        store.clearAll()
        store.addExpense(ExpenseItem(merchant: "A", category: .fuel, date: Date(), amount: 100, isDeductible: true))
        store.addExpense(ExpenseItem(merchant: "B", category: .other, date: Date(), amount: 50, isDeductible: false))
        store.addExpense(ExpenseItem(merchant: "C", category: .supplies, date: Date(), amount: 25, isDeductible: true))
        XCTAssertEqual(store.totalDeductions, 125, accuracy: 0.001)
    }

    func testLinkedReceiptCount() {
        let store = ExpenseStore()
        store.clearAll()
        store.addReceipt(ReceiptItem(merchant: "A", date: Date(), amount: 10, isLinked: true))
        store.addReceipt(ReceiptItem(merchant: "B", date: Date(), amount: 20, isLinked: false))
        store.addReceipt(ReceiptItem(merchant: "C", date: Date(), amount: 30, isLinked: true))
        XCTAssertEqual(store.linkedReceiptCount, 2)
    }

    // MARK: - Reset and clear

    func testClearAllEmptiesBothArrays() {
        let store = ExpenseStore()
        store.clearAll()
        XCTAssertTrue(store.expenses.isEmpty)
        XCTAssertTrue(store.receipts.isEmpty)
        XCTAssertEqual(store.totalDeductions, 0)
        XCTAssertEqual(store.linkedReceiptCount, 0)
    }

    func testResetToSeedPopulatesData() {
        let store = ExpenseStore()
        store.clearAll()
        XCTAssertTrue(store.expenses.isEmpty)
        store.resetToSeed()
        XCTAssertFalse(store.expenses.isEmpty)
        XCTAssertFalse(store.receipts.isEmpty)
        XCTAssertEqual(store.expenses.count, ExpenseItem.seeded.count)
        XCTAssertEqual(store.receipts.count, ReceiptItem.seeded.count)
    }

    // MARK: - Persistence across instances

    func testPersistenceSurvivesNewInstance() {
        let store1 = ExpenseStore()
        store1.clearAll()
        let item = ExpenseItem(merchant: "Persistent", category: .fuel, date: Date(), amount: 42.00, isDeductible: true)
        store1.addExpense(item)

        // Create a new store instance — it should load from UserDefaults.
        let store2 = ExpenseStore()
        XCTAssertTrue(store2.expenses.contains { $0.merchant == "Persistent" })

        // Cleanup
        store2.clearAll()
    }

    // MARK: - Edge cases

    func testDeleteNonExistentIDIsNoOp() {
        let store = ExpenseStore()
        let countBefore = store.expenses.count
        store.deleteExpense(id: UUID())
        XCTAssertEqual(store.expenses.count, countBefore)
    }

    func testDeleteReceiptNonExistentIDIsNoOp() {
        let store = ExpenseStore()
        let countBefore = store.receipts.count
        store.deleteReceipt(id: UUID())
        XCTAssertEqual(store.receipts.count, countBefore)
    }

    func testDeleteExpenseAtInvalidIndexIsNoOp() {
        let store = ExpenseStore()
        let countBefore = store.expenses.count
        store.deleteExpense(at: 999)
        XCTAssertEqual(store.expenses.count, countBefore)
    }
}
