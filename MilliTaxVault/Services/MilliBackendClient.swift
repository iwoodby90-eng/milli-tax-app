import Foundation
import Security

// MARK: - MilliBackendClient
// Native iOS client for Milli's FastAPI service on Render.
// Production authentication is bearer-session based. Sign in with Apple stages
// an identity token + raw nonce in AppleAuthManager; this client exchanges that
// credential for access/refresh tokens before any protected request.

@MainActor
final class MilliBackendClient {
    static let shared = MilliBackendClient()

    struct AuthTokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let tokenType: String?
        let expiresIn: Int
        let userID: String
        let email: String?
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case userID = "user_id"
            case email
            case displayName = "display_name"
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

    struct APIErrorPayload: Decodable {
        let detail: String?
    }

    enum ClientError: LocalizedError {
        case backendUnavailable
        case invalidResponse
        case authenticationRequired(String)
        case server(status: Int, message: String)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .backendUnavailable:
                return "Milli couldn't reach the banking service. Please check your connection and try again."
            case .invalidResponse:
                return "Milli received an invalid response from the banking service."
            case .authenticationRequired(let message):
                return message
            case .server(let status, let message):
                return "Banking service error \(status): \(message)"
            case .decoding:
                return "Milli received banking data in an unexpected format."
            }
        }
    }

    private static let sessionKeychainService = "com.milli.taxvault.backend-session"
    private static let accessTokenKey = "milliBackendAccessToken"
    private static let refreshTokenKey = "milliBackendRefreshToken"

    private let session: URLSession
    private var resolvedBaseURL: URL?

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
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

    func refreshPlaidBalances() async throws {
        let _: GenericStatusResponse = try await request(
            method: "POST",
            path: "/plaid/refresh-balances"
        )
    }

    // MARK: - Session lifecycle

    var hasStoredSession: Bool {
        Self.loadSecret(account: Self.accessTokenKey) != nil
            || Self.loadSecret(account: Self.refreshTokenKey) != nil
    }

    func clearSession() {
        Self.deleteSecret(account: Self.accessTokenKey)
        Self.deleteSecret(account: Self.refreshTokenKey)
    }

    private func ensureAccessToken() async throws -> String {
        if let accessToken = Self.loadSecret(account: Self.accessTokenKey), !accessToken.isEmpty {
            return accessToken
        }

        if let refreshToken = Self.loadSecret(account: Self.refreshTokenKey), !refreshToken.isEmpty {
            do {
                let refreshed = try await refreshSession(using: refreshToken)
                return refreshed.accessToken
            } catch {
                clearSession()
            }
        }

        if let pending = AppleAuthManager.shared.pendingBackendCredential() {
            let response = try await exchangeAppleCredential(pending)
            return response.accessToken
        }

        throw ClientError.authenticationRequired(
            "Milli needs a secure backend session before connecting your bank. Sign in with Apple again, then retry the bank connection."
        )
    }

    private func recoverSessionAfterUnauthorized() async -> Bool {
        Self.deleteSecret(account: Self.accessTokenKey)

        if let refreshToken = Self.loadSecret(account: Self.refreshTokenKey), !refreshToken.isEmpty {
            do {
                _ = try await refreshSession(using: refreshToken)
                return true
            } catch {
                clearSession()
            }
        }

        if let pending = AppleAuthManager.shared.pendingBackendCredential() {
            do {
                _ = try await exchangeAppleCredential(pending)
                return true
            } catch {
                clearSession()
            }
        }

        return false
    }

    private func exchangeAppleCredential(
        _ credential: AppleAuthManager.PendingBackendCredential
    ) async throws -> AuthTokenResponse {
        var body: [String: Any] = [
            "identity_token": credential.identityToken,
            "raw_nonce": credential.rawNonce
        ]
        if let displayName = credential.displayName, !displayName.isEmpty {
            body["display_name"] = displayName
        }

        let response: AuthTokenResponse = try await request(
            method: "POST",
            path: "/auth/apple",
            body: body,
            authenticated: false,
            retryOnUnauthorized: false
        )

        guard storeSession(response) else {
            throw ClientError.authenticationRequired(
                "Milli authenticated with Apple but couldn't securely store the backend session. Please try again."
            )
        }

        AppleAuthManager.shared.clearPendingBackendCredential()
        return response
    }

    private func refreshSession(using refreshToken: String) async throws -> AuthTokenResponse {
        let response: AuthTokenResponse = try await request(
            method: "POST",
            path: "/auth/refresh",
            body: ["refresh_token": refreshToken],
            authenticated: false,
            retryOnUnauthorized: false
        )

        guard storeSession(response) else {
            throw ClientError.authenticationRequired(
                "Milli refreshed your session but couldn't securely store it. Please sign in again."
            )
        }
        return response
    }

    @discardableResult
    private func storeSession(_ response: AuthTokenResponse) -> Bool {
        guard !response.accessToken.isEmpty, !response.refreshToken.isEmpty else { return false }

        let accessStored = Self.storeSecret(response.accessToken, account: Self.accessTokenKey)
        let refreshStored = Self.storeSecret(response.refreshToken, account: Self.refreshTokenKey)

        if !accessStored || !refreshStored {
            clearSession()
            return false
        }

        let defaults = UserDefaults.standard
        defaults.set(response.userID, forKey: "milliBackendUserID")
        if let email = response.email, !email.isEmpty {
            defaults.set(email, forKey: "milliProfileEmail")
            defaults.set(email, forKey: "milliAppleUserEmail")
        }
        if let displayName = response.displayName, !displayName.isEmpty {
            defaults.set(displayName, forKey: "milliProfileName")
            defaults.set(displayName, forKey: "milliAppleUserName")
        }

        return true
    }

    // MARK: - Core request

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]? = nil,
        authenticated: Bool = true,
        retryOnUnauthorized: Bool = true
    ) async throws -> T {
        let baseURL = try await resolveBaseURL()
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: cleanPath)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated {
            let accessToken = try await ensureAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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

        if http.statusCode == 401, authenticated, retryOnUnauthorized {
            if await recoverSessionAfterUnauthorized() {
                return try await self.request(
                    method: method,
                    path: path,
                    body: body,
                    authenticated: true,
                    retryOnUnauthorized: false
                )
            }

            throw ClientError.authenticationRequired(
                "Your Milli session expired. Sign in with Apple again, then retry the bank connection."
            )
        }

        guard (200...299).contains(http.statusCode) else {
            let detail = (try? JSONDecoder().decode(APIErrorPayload.self, from: data).detail)
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown server error"

            if http.statusCode == 401 {
                throw ClientError.authenticationRequired(
                    detail.isEmpty ? "Milli authentication was rejected. Please sign in again." : detail
                )
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
                  (200...299).contains(http.statusCode) else {
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

        // Known Milli deployments. Info.plist should normally resolve first.
        values.append("https://milli-tax-app-1.onrender.com")
        values.append("https://milli-tax-vault-api.onrender.com")

        var seen = Set<String>()
        return values.compactMap { rawValue in
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return nil }
            return URL(string: trimmed)
        }
    }

    // MARK: - Keychain

    @discardableResult
    private static func storeSecret(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: sessionKeychainService,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }

    private static func loadSecret(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: sessionKeychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private static func deleteSecret(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: sessionKeychainService,
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
    let accountsRefreshed: Int?
    let items: Int?

    enum CodingKeys: String, CodingKey {
        case accountsRefreshed = "accounts_refreshed"
        case items
    }
}
