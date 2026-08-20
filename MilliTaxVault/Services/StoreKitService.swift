import Foundation
import Combine
import StoreKit

// MARK: - StoreKit 2 In-App Subscription & Payment Service
// Handles Apple App Store subscriptions across Basic, Pro, and Elite tiers.
// Manages transaction updates, verification, entitlements, and restore flow.

@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // MARK: - Product Identifiers
    static let basicSubscriptionID = "com.milli.taxvault.subscription.basic"
    static let proSubscriptionID = "com.milli.taxvault.subscription.pro"
    static let eliteSubscriptionID = "com.milli.taxvault.subscription.elite"

    static let productIdentifiers: Set<String> = [
        basicSubscriptionID,
        proSubscriptionID,
        eliteSubscriptionID
    ]

    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var activePlan: MilliPlan?
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?

    private var transactionListenerTask: Task<Void, Never>?

    init() {
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
    // Explicitly qualify StoreKit.Transaction because SwiftUI also defines a
    // Transaction type. Keeping the listener on the MainActor also avoids
    // crossing actor isolation just to update this observable service.
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }

                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("[StoreKitService] Unverified transaction update: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Request Products
    func requestProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: Self.productIdentifiers)
            products = storeProducts.sorted(by: { $0.price < $1.price })
            isLoading = false
        } catch {
            errorMessage = "Failed to load App Store subscriptions: \(error.localizedDescription)"
            isLoading = false
            print("[StoreKitService] Product request failed: \(error)")
        }
    }

    // MARK: - Purchase Product
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
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
    func purchase(plan: MilliPlan) async throws -> StoreKit.Transaction? {
        let productID = productID(for: plan)
        guard let product = products.first(where: { $0.id == productID }) else {
            // Development fallback only: no App Store transaction is claimed as successful.
            UserDefaults.standard.set(plan.rawValue, forKey: "onboarding_plan")
            MilliTrialState.activateIfNeeded(plan: plan)
            return nil
        }
        return try await purchase(product)
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
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
    func updateCustomerProductStatus() async {
        var purchasedIDs = Set<String>()

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("[StoreKitService] Failed to verify current entitlement: \(error)")
            }
        }

        purchasedProductIDs = purchasedIDs

        if purchasedIDs.contains(Self.eliteSubscriptionID) {
            activePlan = .elite
        } else if purchasedIDs.contains(Self.proSubscriptionID) {
            activePlan = .pro
        } else if purchasedIDs.contains(Self.basicSubscriptionID) {
            activePlan = .basic
        } else {
            // Preserve onboarding/trial selection without representing it as a paid entitlement.
            let savedPlan = UserDefaults.standard.string(forKey: "onboarding_plan") ?? MilliPlan.pro.rawValue
            activePlan = MilliPlan(rawValue: savedPlan) ?? .pro
        }
    }

    // MARK: - Verification Helper
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helpers
    func productID(for plan: MilliPlan) -> String {
        switch plan {
        case .basic: return Self.basicSubscriptionID
        case .pro: return Self.proSubscriptionID
        case .elite: return Self.eliteSubscriptionID
        }
    }

    func product(for plan: MilliPlan) -> Product? {
        let targetID = productID(for: plan)
        return products.first(where: { $0.id == targetID })
    }

    func formattedPrice(for plan: MilliPlan) -> String {
        if let product = product(for: plan) {
            return product.displayPrice + "/mo"
        }
        return plan.monthlyPrice
    }
}
