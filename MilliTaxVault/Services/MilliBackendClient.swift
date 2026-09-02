import Foundation

// MARK: - MilliBackendClient
// Minimal HTTP client for the Milli backend. The backend is the ONLY holder of
// provider credentials (Stripe secret key); the app never sees them.
// All responses are authoritative backend payloads — the app renders them as LIVE.

public enum MilliBackendError: LocalizedError {
    case notConfigured
    case badResponse
    case http(Int)

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "Milli backend URL is not configured."
        case .badResponse: return "Unexpected response from Milli backend."
        case .http(let code): return "Milli backend error (HTTP \(code))."
        }
    }
}

public struct MilliBackendConfig {
    /// Base URL of the Milli backend, e.g. https://api.drivemilli.com
    /// Left nil in dev builds so the app stays honest (UNAVAILABLE) instead of
    /// pointing at a fake server.
    public static var baseURL: URL? {
        get { UserDefaults.standard.string(forKey: "milli_backend_base_url").flatMap(URL.init(string:)) }
        set { UserDefaults.standard.set(newValue?.absoluteString, forKey: "milli_backend_base_url") }
    }
}

@MainActor
public final class MilliBackendClient {
    public static let shared = MilliBackendClient()
    private init() {}

    public var isConfigured: Bool { MilliBackendConfig.baseURL != nil }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        guard let base = MilliBackendConfig.baseURL else { throw MilliBackendError.notConfigured }
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw MilliBackendError.badResponse }
        guard (200..<300).contains(http.statusCode) else { throw MilliBackendError.http(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: Bank link (Stripe Financial Connections hosted flow)

    /// Step 1: ask the backend to create a Stripe Financial Connections session.
    /// Returns the hosted URL where the user searches their bank, logs in
    /// securely, and consents to sharing account data with Milli.
    public func createBankLinkSession() async throws -> BankLinkSessionResponse {
        try await request("api/bank-link/session", method: "POST")
    }

    /// Step 2: after the hosted flow redirects back, finalize the link.
    /// The backend retrieves the connected accounts and their live balances.
    public func completeBankLink(sessionId: String) async throws -> ConnectedAccountsResponse {
        try await request("api/bank-link/complete", method: "POST", body: ["sessionId": sessionId])
    }

    // MARK: Payout sync + Tax Vault reserve

    /// Pull gig-platform payouts the backend detected from the connected
    /// account's transactions, each with the tax amount the backend moved
    /// (or recommends moving) into the Milli Tax Vault reserve.
    public func syncPayouts() async throws -> PayoutSyncResponse {
        try await request("api/payouts/sync", method: "POST")
    }
}

// MARK: - Backend payload contracts

public struct BankLinkSessionResponse: Decodable {
    public let sessionId: String
    /// Hosted Stripe page: bank search, secure login, data-sharing consent.
    public let hostedUrl: URL
    /// Where ASWebAuthenticationSession should expect the redirect back.
    public let returnUrl: URL
}

public struct ConnectedAccountPayload: Decodable {
    public let id: String
    public let institutionName: String
    public let accountName: String
    public let accountMask: String
    public let accountType: String
    public let balance: Double
    public let lastSyncedAt: Date
}

public struct ConnectedAccountsResponse: Decodable {
    public let accounts: [ConnectedAccountPayload]
}

public struct PayoutSyncPayload: Decodable {
    public let id: String
    public let platform: String
    public let grossAmount: Double
    public let detectedAt: Date
    public let taxHoldAmount: Double
    /// Whether the backend confirmed the reserve transfer (Tax Vault) or it is still processing.
    public let taxHoldState: String
}

public struct PayoutSyncResponse: Decodable {
    public let payouts: [PayoutSyncPayload]
    public let taxVaultReserveBalance: Double
    public let syncedAt: Date
}