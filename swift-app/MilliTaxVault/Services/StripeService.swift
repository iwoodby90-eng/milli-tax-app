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
            case tier = "plan"
            case active
            case currentPeriodEnd = "stripe_active_until"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            tier = try c.decodeIfPresent(String.self, forKey: .tier) ?? "trial"
            active = try c.decodeIfPresent(Bool.self, forKey: .active) ?? false
            currentPeriodEnd = try c.decodeIfPresent(String.self, forKey: .currentPeriodEnd)
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

    /// Get current subscription status from user profile.
    func getSubscriptionStatus() async throws -> SubscriptionStatus {
        return try await api.request(path: "/auth/me")
    }

    /// Create a Stripe checkout session for subscription upgrade.
    func createCheckoutSession(tier: String, originURL: String) async throws -> CheckoutSession {
        return try await api.request(
            method: "POST",
            path: "/stripe/checkout",
            body: ["tier": tier, "origin_url": originURL]
        )
    }

    /// Open the Stripe customer portal for managing billing.
    func getPortalURL() async throws -> String {
        struct PortalResponse: Decodable { let url: String }
        let response: PortalResponse = try await api.request(
            method: "POST",
            path: "/stripe/portal"
        )
        return response.url
    }
}
