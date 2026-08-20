import Foundation
import StoreKit

/// StoreKit 2 subscription service for Milli.
///
/// Product identifiers are intentionally read from configuration instead of
/// being fabricated in code. Add the App Store Connect product identifiers to
/// Info.plist using these keys:
/// - MILLI_STOREKIT_BASIC_PRODUCT_ID
/// - MILLI_STOREKIT_PRO_PRODUCT_ID
/// - MILLI_STOREKIT_ELITE_PRODUCT_ID
@MainActor
final class StoreKitService: ObservableObject {
    enum StoreError: LocalizedError {
        case productIdentifiersNotConfigured
        case productUnavailable
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .productIdentifiersNotConfigured:
                return "StoreKit product identifiers are not configured for this build."
            case .productUnavailable:
                return "The selected subscription is not currently available from the App Store."
            case .failedVerification:
                return "The App Store transaction could not be verified."
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private var configuredProductIDs: [String] {
        let keys = [
            "MILLI_STOREKIT_BASIC_PRODUCT_ID",
            "MILLI_STOREKIT_PRO_PRODUCT_ID",
            "MILLI_STOREKIT_ELITE_PRODUCT_ID"
        ]

        return keys.compactMap { key in
            guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
                return nil
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    var isConfigured: Bool {
        !configuredProductIDs.isEmpty
    }

    func loadProducts() async {
        lastError = nil

        let identifiers = configuredProductIDs
        guard !identifiers.isEmpty else {
            products = []
            lastError = StoreError.productIdentifiersNotConfigured.localizedDescription
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: identifiers)
                .sorted { lhs, rhs in
                    lhs.price < rhs.price
                }
            await refreshPurchasedProducts()
        } catch {
            products = []
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        lastError = nil

        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
                await refreshPurchasedProducts()
                return transaction
            case .unverified:
                lastError = StoreError.failedVerification.localizedDescription
                throw StoreError.failedVerification
            }

        case .pending:
            // The App Store is waiting for an external approval or action.
            return nil

        case .userCancelled:
            return nil

        @unknown default:
            return nil
        }
    }

    func restorePurchases() async {
        lastError = nil

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshPurchasedProducts() async {
        var verifiedIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            verifiedIDs.insert(transaction.productID)
        }

        purchasedProductIDs = verifiedIDs
    }

    func product(forIdentifier identifier: String) -> Product? {
        products.first { $0.id == identifier }
    }

    func hasActiveEntitlement(forProductID productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }
}
