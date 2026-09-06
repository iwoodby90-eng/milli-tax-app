import Foundation
import CryptoKit

// MARK: - MilliBackendClient
// Native iOS client for the FastAPI service deployed on Render.
// Plaid credentials and access tokens never enter the app; the client only
// receives short-lived Link tokens and account snapshots from the backend.

@MainActor
final class MilliBackendClient {
    static let shared = MilliBackendClient()

    struct PlaidLinkTokenResponse: Decodable {
        let linkToken: String
        let expiration: String?

        enum CodingKeys: String, CodingKey {
            case linkToken = "link_token"
            case expiration
        }
    }

    struct PlaidExchangeResponse: Decodable {
        let itemID: String
        let accountsLinked: Int

        enum CodingKeys: String, CodingKey {
            case itemID = "item_id"
            case accountsLinked = "accounts_linked"
        }
    }

    struct PlaidAccountsResponse: Decodable {
        let accounts: [MilliPlaidAccount]
        let count: Int
    }

    struct APIErrorPayload: Decodable {
        let detail: String?
    }

    enum ClientError: LocalizedError {
        case backendUnavailable
        case invalidResponse
        case unauthorized(String)
        case server(status: Int, message: String)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .backendUnavailable:
                return "Milli couldn't reach the Render banking service. Check the backend deployment and MILLI_API_BASE_URL."
            case .invalidResponse:
                return "Milli received an invalid response from the banking service."
            case .unauthorized(let message):
                return message
            case .server(let status, let message):
                return "Banking service error \(status): \(message)"
            case .decoding:
                return "Milli received banking data in an unexpected format."
            }
        }
    }

    private let session: URLSession
    private var resolvedBaseURL: URL?

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
    }

    func createPlaidLinkToken() async throws -> String {
        let response: PlaidLinkTokenResponse = try await request(
            method: "POST",
            path: "/plaid/link-token"
        )
        return response.linkToken
    }

    func exchangePlaidPublicToken(
        _ publicToken: String,
        institutionID: String?,
        institutionName: String?
    ) async throws -> PlaidExchangeResponse {
        var body: [String: Any] = ["public_token": publicToken]
        if let institutionID, !institutionID.isEmpty {
            body["institution_id"] = institutionID
        }
        if let institutionName, !institutionName.isEmpty {
            body["institution_name"] = institutionName
        }

        return try await request(
            method: "POST",
            path: "/plaid/exchange-public-token",
            body: body
        )
    }

    func fetchPlaidAccounts() async throws -> [MilliPlaidAccount] {
        let response: PlaidAccountsResponse = try await request(
            method: "GET",
            path: "/plaid/accounts"
        )
        return response.accounts
    }

    func refreshPlaidBalances() async throws {
        let _: GenericStatusResponse = try await request(
            method: "POST",
            path: "/plaid/refresh-balances"
        )
    }

    // MARK: - Core request

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        let baseURL = try await resolveBaseURL()
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: cleanPath)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(stableBackendUserID().uuidString, forHTTPHeaderField: "X-Milli-User-Id")

        if let clientKey = configuredClientKey, !clientKey.isEmpty {
            request.setValue(clientKey, forHTTPHeaderField: "X-Milli-Client-Key")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // A deployment can be replaced without restarting the app. Forget
            // the cached host so the next attempt can rediscover it.
            resolvedBaseURL = nil
            throw ClientError.backendUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let detail = (try? JSONDecoder().decode(APIErrorPayload.self, from: data).detail)
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown server error"

            if http.statusCode == 401 {
                if detail.localizedCaseInsensitiveContains("client key") {
                    throw ClientError.unauthorized(
                        "Render rejected Milli's client key. Set MILLI_CLIENT_API_KEY in the Xcode scheme to the same CLIENT_API_KEY configured on Render."
                    )
                }
                throw ClientError.unauthorized("The banking service rejected this Milli session: \(detail)")
            }

            throw ClientError.server(status: http.statusCode, message: detail)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ClientError.decoding(error)
        }
    }

    // MARK: - Render host discovery

    private func resolveBaseURL() async throws -> URL {
        if let resolvedBaseURL {
            return resolvedBaseURL
        }

        for candidate in candidateBaseURLs {
            let healthURL = candidate.appending(path: "health")
            var request = URLRequest(url: healthURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 12

            guard let (_, response) = try? await session.data(for: request),
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode)
            else {
                continue
            }

            resolvedBaseURL = candidate
            return candidate
        }

        throw ClientError.backendUnavailable
    }

    private var candidateBaseURLs: [URL] {
        var values: [String] = []

        if let environmentURL = ProcessInfo.processInfo.environment["MILLI_API_BASE_URL"] {
            values.append(environmentURL)
        }

        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String {
            values.append(plistURL)
        }

        // Migration fallbacks only. Production should explicitly set
        // MILLI_API_BASE_URL so a Render rename cannot silently redirect data.
        values.append("https://milli-tax-vault-api.onrender.com")
        values.append("https://milli-tax-app.onrender.com")

        var seen = Set<String>()
        return values.compactMap { rawValue in
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return nil }
            return URL(string: trimmed)
        }
    }

    private var configuredClientKey: String? {
        if let value = ProcessInfo.processInfo.environment["MILLI_CLIENT_API_KEY"], !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "MILLI_CLIENT_API_KEY") as? String, !value.isEmpty {
            return value
        }
        return nil
    }

    // MARK: - Backend identity

    /// The current backend contract scopes rows by UUID. Until the production
    /// authentication service exchanges Apple's identity token for a server
    /// session, derive a stable UUID from the Apple user id. This is an
    /// identity namespace only, not authentication; the backend must not treat
    /// possession of this UUID as proof of identity.
    private func stableBackendUserID() -> UUID {
        let defaults = UserDefaults.standard

        if let appleUserID = AppleAuthManager.shared.currentAppleUserID, !appleUserID.isEmpty {
            let uuid = deterministicUUID(namespace: "milli.apple", value: appleUserID)
            defaults.set(uuid.uuidString, forKey: "milliBackendUserID")
            return uuid
        }

        if let stored = defaults.string(forKey: "milliBackendUserID"),
           let uuid = UUID(uuidString: stored) {
            return uuid
        }

        let uuid = UUID()
        defaults.set(uuid.uuidString, forKey: "milliBackendUserID")
        return uuid
    }

    private func deterministicUUID(namespace: String, value: String) -> UUID {
        let digest = SHA256.hash(data: Data("\(namespace):\(value)".utf8))
        var bytes = Array(digest.prefix(16))

        // RFC 4122-compatible variant + version bits. The value is deterministic
        // but does not reveal the Apple subject string itself.
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

struct MilliPlaidAccount: Decodable, Identifiable, Equatable {
    let accountID: String
    let name: String?
    let mask: String?
    let type: String?
    let subtype: String?
    let availableBalance: Double?
    let currentBalance: Double?
    let isoCurrencyCode: String?
    let balanceAsOf: String?
    let dataState: String
    let institutionName: String?
    let itemStatus: String?

    var id: String { accountID }

    enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case name
        case mask
        case type
        case subtype
        case availableBalance = "available_balance"
        case currentBalance = "current_balance"
        case isoCurrencyCode = "iso_currency_code"
        case balanceAsOf = "balance_as_of"
        case dataState = "data_state"
        case institutionName = "institution_name"
        case itemStatus = "item_status"
    }
}

private struct GenericStatusResponse: Decodable {
    // The refresh endpoint returns integer counters. Keep a permissive contract
    // so adding future counters does not break the iOS client.
    let accountsRefreshed: Int?
    let items: Int?

    enum CodingKeys: String, CodingKey {
        case accountsRefreshed = "accounts_refreshed"
        case items
    }
}
