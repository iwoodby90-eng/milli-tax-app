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
    /// Production builds should provision MILLI_API_BASE_URL through the app's
    /// Info.plist/build configuration. A UserDefaults override remains available
    /// for local QA without baking development hosts into Release builds.
    public static var baseURL: URL? {
        get {
            if let override = UserDefaults.standard.string(forKey: "milli_backend_base_url"),
               let url = URL(string: override),
               !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return url
            }
            guard let configured = Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String,
                  !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return URL(string: configured)
        }
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(T.self, from: data)
    }

    // MARK: Bank link (Stripe Financial Connections hosted flow)

    public func createBankLinkSession() async throws -> BankLinkSessionResponse {
        try await request("api/bank-link/session", method: "POST")
    }

    public func completeBankLink(sessionId: String) async throws -> ConnectedAccountsResponse {
        try await request("api/bank-link/complete", method: "POST", body: ["sessionId": sessionId])
    }

    // MARK: Payout sync + Tax Vault reserve

    /// Synchronize one specific connected account. The account identifier is
    /// required by the backend so a sync can never silently operate on global state.
    public func syncPayouts(accountId: String) async throws -> PayoutSyncResponse {
        try await request(
            "api/payouts/sync",
            method: "POST",
            body: ["accountId": accountId]
        )
    }
}

// MARK: - Backend payload contracts

public struct BankLinkSessionResponse: Decodable {
    public let sessionId: String
    public let hostedUrl: URL
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
    public let taxHoldState: String
}

public struct PayoutSyncResponse: Decodable {
    public let payouts: [PayoutSyncPayload]
    public let taxVaultReserveBalance: Double
    public let syncedAt: Date
}
