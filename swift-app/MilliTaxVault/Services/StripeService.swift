import Foundation

// MARK: - Stripe Service

/// Handles Stripe billing/subscription integration.
/// Communicates with the backend's Stripe-powered endpoints.
final class StripeService {
    static let shared = StripeService()
    private let api = APIService.shared

    private init() {}

    struct SubscriptionStatus: Decodable {
        let tier: String
        let active: Bool
        let currentPeriodEnd: String?

        enum CodingKeys: String, CodingKey {
            case tier
            case active
            case currentPeriodEnd = "current_period_end"
        }
    }

    struct CheckoutSession: Decodable {
        let url: String
        let sessionId: String

        enum CodingKeys: String, CodingKey {
            case url
            case sessionId = "session_id"
        }
    }

    /// Get current subscription status.
    func getSubscriptionStatus() async throws -> SubscriptionStatus {
        return try await api.request(path: "/billing/status")
    }

    /// Create a Stripe checkout session for subscription upgrade.
    func createCheckoutSession(tier: String) async throws -> CheckoutSession {
        return try await api.request(
            method: "POST",
            path: "/billing/checkout",
            body: ["tier": tier]
        )
    }

    /// Open the Stripe customer portal for managing billing.
    func getPortalURL() async throws -> String {
        struct PortalResponse: Decodable { let url: String }
        let response: PortalResponse = try await api.request(
            method: "POST",
            path: "/billing/portal"
        )
        return response.url
    }
}
