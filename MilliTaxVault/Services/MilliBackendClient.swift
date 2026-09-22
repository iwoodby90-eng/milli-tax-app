import Foundation
import Security

// MARK: - MilliBackendClient
// Native client for Milli's FastAPI backend. The app is never an identity
// authority: user-scoped requests require an opaque server session minted only
// after the backend verifies a signed Apple identity token or an email and
// password credential it stores as a salted digest.

@MainActor
final class MilliBackendClient {
    static let shared = MilliBackendClient()

    struct AppleAuthChallenge: Decodable, Equatable {
        let challengeID: UUID
        let nonce: String
        let expiresAt: String

        enum CodingKeys: String, CodingKey {
            case challengeID = "challenge_id"
            case nonce
            case expiresAt = "expires_at"
        }
    }

    private struct BackendSession: Decodable {
        let userID: UUID
        let accessToken: String
        let refreshToken: String
        let tokenType: String
        let accessExpiresAt: String
        let refreshExpiresAt: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
            case accessExpiresAt = "access_expires_at"
            case refreshExpiresAt = "refresh_expires_at"
        }
    }

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

    struct PayoutSourceResponse: Decodable {
        let accountID: String
        let isPayoutSource: Bool

        enum CodingKeys: String, CodingKey {
            case accountID = "account_id"
            case isPayoutSource = "is_payout_source"
        }
    }

    struct APIErrorPayload: Decodable {
        let detail: String?
    }

    enum ClientError: LocalizedError {
        case backendUnavailable
        case invalidResponse
        case financialSignInRequired
        case unauthorized(String)
        case server(status: Int, message: String)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .backendUnavailable:
                return "Milli couldn't reach the secure banking service."
            case .invalidResponse:
                return "Milli received an invalid response from the secure banking service."
            case .financialSignInRequired:
                return "Sign in with Apple is required before Milli can access banking or money features."
            case .unauthorized(let message):
                return message
            case .server(let status, let message):
                return "Secure banking service error \(status): \(message)"
            case .decoding:
                return "Milli received secure banking data in an unexpected format."
            }
        }
    }

    private let session: URLSession
    private var resolvedBaseURL: URL?

    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    var hasFinancialSession: Bool {
        MilliBackendSessionStore.refreshToken != nil
    }

    // MARK: - Authentication

    func createAppleAuthChallenge() async throws -> AppleAuthChallenge {
        try await publicRequest(method: "POST", path: "/auth/apple/challenge")
    }

    func exchangeAppleIdentity(challengeID: UUID, identityToken: String) async throws {
        let response: BackendSession = try await publicRequest(
            method: "POST",
            path: "/auth/apple/exchange",
            body: [
                "challenge_id": challengeID.uuidString.lowercased(),
                "identity_token": identityToken
            ]
        )
        guard response.tokenType.caseInsensitiveCompare("Bearer") == .orderedSame else {
            throw ClientError.invalidResponse
        }
        MilliBackendSessionStore.save(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    /// Creates an email/password account. The password is sent once over TLS
    /// and never stored on the device; only the returned session is kept.
    func signUpWithEmail(email: String, password: String) async throws {
        try await openEmailSession(path: "/auth/email/signup", email: email, password: password)
    }

    func signInWithEmail(email: String, password: String) async throws {
        try await openEmailSession(path: "/auth/email/login", email: email, password: password)
    }

    private func openEmailSession(path: String, email: String, password: String) async throws {
        let response: BackendSession = try await publicRequest(
            method: "POST",
            path: path,
            body: [
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                "password": password
            ]
        )
        guard response.tokenType.caseInsensitiveCompare("Bearer") == .orderedSame else {
            throw ClientError.invalidResponse
        }
        MilliBackendSessionStore.save(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    func logout() async {
        if let accessToken = MilliBackendSessionStore.accessToken {
            _ = try? await executeRaw(
                method: "POST",
                path: "/auth/logout",
                body: nil,
                bearerToken: accessToken
            )
        }
        MilliBackendSessionStore.clear()
    }

    func clearFinancialSession() {
        MilliBackendSessionStore.clear()
    }

    private func refreshFinancialSession() async throws {
        guard let refreshToken = MilliBackendSessionStore.refreshToken else {
            MilliBackendSessionStore.clear()
            throw ClientError.financialSignInRequired
        }

        do {
            let response: BackendSession = try await publicRequest(
                method: "POST",
                path: "/auth/refresh",
                body: ["refresh_token": refreshToken]
            )
            MilliBackendSessionStore.save(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        } catch {
            MilliBackendSessionStore.clear()
            throw error
        }
    }

    // MARK: - Plaid

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

    func selectPlaidPayoutSource(accountID: String) async throws {
        let _: PayoutSourceResponse = try await request(
            method: "PUT",
            path: "/plaid/payout-source",
            body: ["account_id": accountID]
        )
    }

    func refreshPlaidBalances() async throws {
        let _: GenericStatusResponse = try await request(
            method: "POST",
            path: "/plaid/refresh-balances"
        )
    }

    func updateVaultSettings(reserveRate: Double, autopilotEnabled: Bool) async throws {
        let _: VaultSettingsResponse = try await request(
            method: "PUT",
            path: "/tax-vault/settings",
            body: [
                "reserve_rate": min(max(reserveRate, 0), 1),
                "autopilot_enabled": autopilotEnabled
            ]
        )
    }

    // MARK: - Authenticated requests

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]? = nil,
        allowRefresh: Bool = true
    ) async throws -> T {
        guard let accessToken = MilliBackendSessionStore.accessToken else {
            throw ClientError.financialSignInRequired
        }

        do {
            return try await execute(
                method: method,
                path: path,
                body: body,
                bearerToken: accessToken
            )
        } catch ClientError.unauthorized(_) where allowRefresh {
            try await refreshFinancialSession()
            return try await request(
                method: method,
                path: path,
                body: body,
                allowRefresh: false
            )
        }
    }

    private func publicRequest<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        try await execute(method: method, path: path, body: body, bearerToken: nil)
    }

    private func execute<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]?,
        bearerToken: String?
    ) async throws -> T {
        let (data, _) = try await executeRaw(
            method: method,
            path: path,
            body: body,
            bearerToken: bearerToken
        )
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ClientError.decoding(error)
        }
    }

    private func executeRaw(
        method: String,
        path: String,
        body: [String: Any]?,
        bearerToken: String?
    ) async throws -> (Data, HTTPURLResponse) {
        let baseURL = try await resolveBaseURL()
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: cleanPath)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
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
                throw ClientError.unauthorized("Milli's secure session was rejected: \(detail)")
            }
            throw ClientError.server(status: http.statusCode, message: detail)
        }

        return (data, http)
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
            request.cachePolicy = .reloadIgnoringLocalCacheData

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

        #if DEBUG
        if let environmentURL = ProcessInfo.processInfo.environment["MILLI_API_BASE_URL"] {
            values.append(environmentURL)
        }
        #endif

        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String {
            values.append(plistURL)
        }

        values.append("https://milli-tax-vault-api.onrender.com")
        values.append("https://milli-tax-app.onrender.com")

        var seen = Set<String>()
        return values.compactMap { rawValue in
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return nil }
            // Banking traffic is HTTPS-only: a cleartext or non-web override is
            // never a usable Milli backend.
            guard let url = URL(string: trimmed),
                  url.scheme?.lowercased() == "https",
                  let host = url.host, !host.isEmpty
            else { return nil }
            return url
        }
    }
}

private enum MilliBackendSessionStore {
    private static let service = "com.milli.taxvault.backend-session"
    private static let accessAccount = "access-token"
    private static let refreshAccount = "refresh-token"

    static var accessToken: String? { read(account: accessAccount) }
    static var refreshToken: String? { read(account: refreshAccount) }

    static func save(accessToken: String, refreshToken: String) {
        write(accessToken, account: accessAccount)
        write(refreshToken, account: refreshAccount)
    }

    static func clear() {
        delete(account: accessAccount)
        delete(account: refreshAccount)
    }

    private static func write(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(insert as CFDictionary, nil)
    }

    private static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
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
    let isPayoutSource: Bool?

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
        case isPayoutSource = "is_payout_source"
    }
}

private struct GenericStatusResponse: Decodable {
    let accountsRefreshed: Int?
    let items: Int?

    enum CodingKeys: String, CodingKey {
        case accountsRefreshed = "accounts_refreshed"
        case items
    }
}

private struct VaultSettingsResponse: Decodable {
    let reserveRate: Double
    let autopilotEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case reserveRate = "reserve_rate"
        case autopilotEnabled = "autopilot_enabled"
    }
}
