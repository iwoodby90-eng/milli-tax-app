import SwiftUI
import StoreKit

// MARK: - StoreKit 2 In-App Subscription & Payment Service
// Handles Apple App Store Pay (StoreKit 2) subscriptions across Basic, Pro, and Elite tiers.
// Manages real-time transaction updates, verification, entitlements, and restore flow.

@MainActor
public final class StoreKitService: ObservableObject {
    public static let shared = StoreKitService()

    // MARK: - Product Identifiers
    public static let basicSubscriptionID = "com.milli.taxvault.subscription.basic"
    public static let proSubscriptionID = "com.milli.taxvault.subscription.pro"
    public static let eliteSubscriptionID = "com.milli.taxvault.subscription.elite"

    public static let productIdentifiers: Set<String> = [
        basicSubscriptionID,
        proSubscriptionID,
        eliteSubscriptionID
    ]

    // MARK: - Published Properties
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedProductIDs = Set<String>()
    @Published public private(set) var activePlan: MilliPlan?
    @Published public private(set) var isLoading = false
    @Published public private(set) var isPurchasing = false
    @Published public var errorMessage: String?

    private var transactionListenerTask: Task<Void, Never>?

    public init() {
        // Start listening to background App Store transactions and renewals
        transactionListenerTask = listenForTransactions()

        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction {
                        await self?.updateCustomerProductStatus()
                        await transaction.finish()
                    }
                } catch {
                    print("[StoreKitService] Unverified transaction update: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Request Products
    public func requestProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: Self.productIdentifiers)
            // Sort by price ascending: Basic -> Pro -> Elite
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load App Store subscriptions: \(error.localizedDescription)"
            self.isLoading = false
            print("[StoreKitService] Product request failed: \(error)")
        }
    }

    // MARK: - Purchase Product
    public func purchase(_ product: Product) async throws -> Transaction? {
        isPurchasing = true
        errorMessage = nil

        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            errorMessage = "Purchase is pending approval (e.g. Ask to Buy)."
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Purchase by MilliPlan
    public func purchase(plan: MilliPlan) async throws -> Transaction? {
        let productID = productID(for: plan)
        guard let product = products.first(where: { $0.id == productID }) else {
            // If running in simulator or offline without storekit file, persist local selection
            UserDefaults.standard.set(plan.rawValue, forKey: "onboarding_plan")
            MilliTrialState.activateIfNeeded(plan: plan)
            return nil
        }
        return try await purchase(product)
    }

    // MARK: - Restore Purchases
    public func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            isLoading = false
        } catch {
            errorMessage = "Failed to restore App Store purchases: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Update Entitlements
    public func updateCustomerProductStatus() async {
        var purchasedIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("[StoreKitService] Failed to verify current entitlement: \(error)")
            }
        }

        self.purchasedProductIDs = purchasedIDs

        // Determine active plan based on active entitlement
        if purchasedIDs.contains(Self.eliteSubscriptionID) {
            self.activePlan = .elite
        } else if purchasedIDs.contains(Self.proSubscriptionID) {
            self.activePlan = .pro
        } else if purchasedIDs.contains(Self.basicSubscriptionID) {
            self.activePlan = .basic
        } else {
            // Check if local trial or onboarding plan is active
            let savedPlan = UserDefaults.standard.string(forKey: "onboarding_plan") ?? MilliPlan.pro.rawValue
            self.activePlan = MilliPlan(rawValue: savedPlan) ?? .pro
        }
    }

    // MARK: - Verification Helper
    public func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helpers
    public func productID(for plan: MilliPlan) -> String {
        switch plan {
        case .basic: return Self.basicSubscriptionID
        case .pro: return Self.proSubscriptionID
        case .elite: return Self.eliteSubscriptionID
        }
    }

    public func product(for plan: MilliPlan) -> Product? {
        let targetID = productID(for: plan)
        return products.first(where: { $0.id == targetID })
    }

    public func formattedPrice(for plan: MilliPlan) -> String {
        if let product = product(for: plan) {
            return product.displayPrice + "/mo"
        }
        return plan.monthlyPrice
    }
}
