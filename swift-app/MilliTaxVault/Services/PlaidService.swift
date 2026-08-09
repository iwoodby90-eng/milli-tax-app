import Foundation

// MARK: - Plaid Service

/// Handles Plaid Link integration for bank connections.
/// Communicates with the backend's /plaid/* endpoints.
final class PlaidService {
    static let shared = PlaidService()
    private let api = APIService.shared

    private init() {}

    /// Request a Plaid Link token from the backend.
    /// The token is used to initialize Plaid Link in a WebView.
    func getLinkToken() async throws -> String {
        struct LinkTokenResponse: Decodable {
            let link_token: String
        }
        let response: LinkTokenResponse = try await api.request(
            method: "POST",
            path: "/plaid/link-token"
        )
        return response.link_token
    }

    /// Exchange a Plaid public token (from Link success) for permanent access.
    func exchangePublicToken(_ publicToken: String) async throws {
        try await api.requestVoid(
            method: "POST",
            path: "/plaid/exchange",
            body: ["public_token": publicToken]
        )
    }

    /// Get all connected Plaid items (bank accounts).
    func getConnectedItems() async throws -> [PlaidItem] {
        let items: [PlaidItem] = try await api.request(path: "/plaid/items")
        return items
    }

    /// Sync transactions for all connected items.
    func syncTransactions() async throws -> [VaultTransaction] {
        let transactions: [VaultTransaction] = try await api.request(
            method: "POST",
            path: "/plaid/sync"
        )
        return transactions
    }

    /// Disconnect a Plaid item.
    func disconnectItem(itemId: String) async throws {
        try await api.requestVoid(
            method: "DELETE",
            path: "/plaid/items/\(itemId)"
        )
    }
}
