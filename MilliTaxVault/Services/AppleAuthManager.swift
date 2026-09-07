import SwiftUI
import AuthenticationServices
import Security
import CryptoKit

enum MilliSecureSessionStore {
    private static let service = "com.milli.taxvault.session"
    private static let accessAccount = "access-token"
    private static let refreshAccount = "refresh-token"

    static var accessToken: String? { read(accessAccount) }
    static var refreshToken: String? { read(refreshAccount) }

    static func save(accessToken: String, refreshToken: String) throws {
        try write(accessToken, accessAccount)
        try write(refreshToken, refreshAccount)
    }

    static func clear() {
        delete(accessAccount)
        delete(refreshAccount)
    }

    private static func write(_ value: String, _ account: String) throws {
        guard let data = value.data(using: .utf8) else { throw StoreError.encoding }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw StoreError.keychain
        }
    }

    private static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum StoreError: Error { case encoding, keychain }
}

actor MilliAuthenticatedSession {
    static let shared = MilliAuthenticatedSession()

    struct TokenEnvelope: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let userID: UUID
        let email: String?
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case userID = "user_id"
            case email
            case displayName = "display_name"
        }
    }

    private struct AppleRequest: Encodable {
        let identityToken: String
        let rawNonce: String
        let displayName: String?
        enum CodingKeys: String, CodingKey {
            case identityToken = "identity_token"
            case rawNonce = "raw_nonce"
            case displayName = "display_name"
        }
    }

    private struct RefreshRequest: Encodable {
        let refreshToken: String
        enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
    }

    private let urlSession = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var refreshTask: Task<Void, Error>?

    func exchangeApple(identityToken: String, rawNonce: String, displayName: String?) async throws -> TokenEnvelope {
        var request = try makeRequest(path: "auth/apple", method: "POST")
        request.httpBody = try encoder.encode(
            AppleRequest(identityToken: identityToken, rawNonce: rawNonce, displayName: displayName)
        )
        let envelope: TokenEnvelope = try await send(request)
        try MilliSecureSessionStore.save(
            accessToken: envelope.accessToken,
            refreshToken: envelope.refreshToken
        )
        return envelope
    }

    func data(for original: URLRequest) async throws -> (Data, URLResponse) {
        guard let token = MilliSecureSessionStore.accessToken else { throw AuthError.notAuthenticated }
        var request = original
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let first = try await urlSession.data(for: request)
        guard (first.1 as? HTTPURLResponse)?.statusCode == 401 else { return first }

        try await refreshIfNeeded()
        guard let rotated = MilliSecureSessionStore.accessToken else { throw AuthError.notAuthenticated }
        request.setValue("Bearer \(rotated)", forHTTPHeaderField: "Authorization")
        return try await urlSession.data(for: request)
    }

    func logout() async {
        if let access = MilliSecureSessionStore.accessToken,
           var request = try? makeRequest(path: "auth/logout", method: "POST") {
            request.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
            _ = try? await urlSession.data(for: request)
        }
        MilliSecureSessionStore.clear()
    }

    private func refreshIfNeeded() async throws {
        if let task = refreshTask {
            try await task.value
            return
        }
        let task = Task { [self] in
            guard let refresh = MilliSecureSessionStore.refreshToken else {
                throw AuthError.notAuthenticated
            }
            var request = try makeRequest(path: "auth/refresh", method: "POST")
            request.httpBody = try encoder.encode(RefreshRequest(refreshToken: refresh))
            let envelope: TokenEnvelope = try await send(request)
            try MilliSecureSessionStore.save(
                accessToken: envelope.accessToken,
                refreshToken: envelope.refreshToken
            )
        }
        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let base = Self.baseURL(),
              let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw AuthError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String
            throw AuthError.server(detail ?? "Secure account authentication failed.")
        }
        return try decoder.decode(T.self, from: data)
    }

    static func baseURL() -> URL? {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = (configured?.isEmpty == false) ? configured! : "https://milli-tax-vault-api.onrender.com"
        return URL(string: raw.hasSuffix("/") ? raw : raw + "/")
    }

    enum AuthError: LocalizedError {
        case invalidURL, invalidResponse, notAuthenticated, server(String)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "MILLI's secure account service is not configured."
            case .invalidResponse: return "MILLI received an invalid authentication response."
            case .notAuthenticated: return "Your secure MILLI session expired. Sign in again."
            case .server(let message): return message
            }
        }
    }
}

@MainActor
public final class AppleAuthManager: NSObject, ObservableObject {
    public static let shared = AppleAuthManager()

    @Published public private(set) var isSignedInWithApple = false
    @Published public private(set) var currentAppleUserID: String?
    @Published public private(set) var userEmail: String?
    @Published public private(set) var userFullName: String?
    @Published public private(set) var isProcessing = false
    @Published public var authErrorMessage: String?

    private static let keychainService = "com.milli.taxvault.apple-auth"
    private static let keychainAccountKey = "milliAppleUserID"
    private var currentRawNonce: String?

    public override init() {
        super.init()
        if let storedUserID = Self.loadAppleUserIDFromKeychain(),
           MilliSecureSessionStore.refreshToken != nil {
            currentAppleUserID = storedUserID
            isSignedInWithApple = true
            userEmail = UserDefaults.standard.string(forKey: "milliAppleUserEmail")
            userFullName = UserDefaults.standard.string(forKey: "milliAppleUserName")
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCredentialRevokedNotification),
            name: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil
        )
    }

    public func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let rawNonce = Self.randomNonce()
        currentRawNonce = rawNonce
        request.nonce = Self.sha256(rawNonce)
    }

    public func completeAuthorization(
        result: Result<ASAuthorization, Error>,
        isSignUp: Bool
    ) async -> (email: String, name: String)? {
        authErrorMessage = nil
        isProcessing = true
        defer {
            isProcessing = false
            currentRawNonce = nil
        }

        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  let rawNonce = currentRawNonce else {
                authErrorMessage = "Apple did not provide a verifiable identity token."
                return nil
            }

            var name = credential.fullName
                .map { PersonNameComponentsFormatter().string(from: $0) }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
            if name.isEmpty {
                name = UserDefaults.standard.string(forKey: "milliProfileName") ?? "Milli Member"
            }

            let envelope = try await MilliAuthenticatedSession.shared.exchangeApple(
                identityToken: identityToken,
                rawNonce: rawNonce,
                displayName: name
            )

            let email = envelope.email
                ?? credential.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                ?? UserDefaults.standard.string(forKey: "milliAppleUserEmail")
                ?? ""

            currentAppleUserID = credential.user
            Self.saveAppleUserIDToKeychain(userID: credential.user)

            let defaults = UserDefaults.standard
            if !email.isEmpty {
                defaults.set(email, forKey: "milliAppleUserEmail")
                defaults.set(email, forKey: "milliProfileEmail")
            }
            defaults.set(name, forKey: "milliAppleUserName")
            defaults.set(name, forKey: "milliProfileName")
            defaults.set(true, forKey: "milliHasCreatedAccount")
            defaults.set("apple", forKey: "milliAuthProvider")

            userEmail = email
            userFullName = name
            isSignedInWithApple = true
            return (email, name)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            return nil
        } catch {
            authErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func verifyAppleCredentialState() async -> ASAuthorizationAppleIDProvider.CredentialState {
        guard let userID = currentAppleUserID else { return .notFound }
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            switch state {
            case .revoked, .notFound:
                await signOut()
            default:
                break
            }
            return state
        } catch {
            return .notFound
        }
    }

    @objc private func handleCredentialRevokedNotification() {
        Task { @MainActor in await signOut() }
    }

    public func signOut() async {
        await MilliAuthenticatedSession.shared.logout()
        MilliSecureSessionStore.clear()
        Self.deleteAppleUserIDFromKeychain()
        currentAppleUserID = nil
        isSignedInWithApple = false
        userEmail = nil
        userFullName = nil
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        while result.count < length {
            var random: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &random) == errSecSuccess else {
                fatalError("Unable to generate secure nonce.")
            }
            if random < charset.count { result.append(charset[Int(random)]) }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func saveAppleUserIDToKeychain(userID: String) {
        guard let data = userID.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccountKey
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private static func loadAppleUserIDFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func deleteAppleUserIDFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccountKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
