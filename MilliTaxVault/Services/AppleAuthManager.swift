import SwiftUI
import AuthenticationServices
import Security
import CryptoKit

// MARK: - Sign in with Apple Authentication Manager
// Owns the Apple credential flow, including the nonce required by Milli's
// production backend. Apple identity tokens are held only long enough to
// exchange them for Milli bearer-session tokens and are stored in Keychain
// while that exchange is pending.

@MainActor
public final class AppleAuthManager: NSObject, ObservableObject {
    public static let shared = AppleAuthManager()

    struct PendingBackendCredential {
        let identityToken: String
        let rawNonce: String
        let displayName: String?
    }

    // MARK: - Published State
    @Published public private(set) var isSignedInWithApple = false
    @Published public private(set) var currentAppleUserID: String?
    @Published public private(set) var userEmail: String?
    @Published public private(set) var userFullName: String?
    @Published public private(set) var isProcessing = false
    @Published public var authErrorMessage: String?

    private static let keychainService = "com.milli.taxvault.apple-auth"
    private static let keychainAccountKey = "milliAppleUserID"
    private static let pendingIdentityTokenKey = "milliPendingAppleIdentityToken"
    private static let pendingRawNonceKey = "milliPendingAppleRawNonce"

    private var currentRawNonce: String?

    public override init() {
        super.init()

        if let storedUserID = Self.loadSecret(account: Self.keychainAccountKey) {
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

    // MARK: - Configure Apple ID Request

    public func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        authErrorMessage = nil
        request.requestedScopes = [.fullName, .email]

        guard let rawNonce = Self.randomNonce() else {
            currentRawNonce = nil
            authErrorMessage = "Milli couldn't create a secure Apple sign-in request. Please try again."
            return
        }

        currentRawNonce = rawNonce
        request.nonce = Self.sha256(rawNonce)
    }

    // MARK: - Handle Authorization Result

    /// Parses Apple's credential and stages its identity token + raw nonce in
    /// Keychain. MilliBackendClient exchanges this pair with POST /auth/apple
    /// before the first protected backend request (including Plaid Link).
    public func handleAuthorizationCompletion(
        result: Result<ASAuthorization, Error>,
        isSignUp: Bool
    ) -> (email: String, name: String)? {
        authErrorMessage = nil
        isProcessing = true
        defer { isProcessing = false }

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                currentRawNonce = nil
                authErrorMessage = "Received an invalid credential from Apple."
                return nil
            }

            guard let rawNonce = currentRawNonce, !rawNonce.isEmpty else {
                authErrorMessage = "Apple sign-in completed without Milli's secure nonce. Please try again."
                return nil
            }
            currentRawNonce = nil

            guard let tokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  identityToken.count >= 20 else {
                authErrorMessage = "Apple did not return a usable identity token. Please try signing in again."
                return nil
            }

            let userID = appleIDCredential.user
            currentAppleUserID = userID

            var resolvedName = ""
            if let fullName = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                resolvedName = formatter.string(from: fullName)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if resolvedName.isEmpty {
                resolvedName = UserDefaults.standard.string(forKey: "milliProfileName") ?? "Milli Member"
            }

            var resolvedEmail = ""
            if let email = appleIDCredential.email {
                resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            } else if let storedEmail = UserDefaults.standard.string(forKey: "milliAppleUserEmail") {
                resolvedEmail = storedEmail
            } else if let profileEmail = UserDefaults.standard.string(forKey: "milliProfileEmail") {
                resolvedEmail = profileEmail
            } else {
                resolvedEmail = "\(userID.prefix(8).lowercased())@privaterelay.appleid.com"
            }

            guard Self.storeSecret(identityToken, account: Self.pendingIdentityTokenKey),
                  Self.storeSecret(rawNonce, account: Self.pendingRawNonceKey),
                  Self.storeSecret(userID, account: Self.keychainAccountKey) else {
                clearPendingBackendCredential()
                authErrorMessage = "Milli couldn't securely store the Apple sign-in credential. Please try again."
                return nil
            }

            let defaults = UserDefaults.standard
            defaults.set(resolvedEmail, forKey: "milliAppleUserEmail")
            defaults.set(resolvedName, forKey: "milliAppleUserName")
            defaults.set(resolvedEmail, forKey: "milliProfileEmail")
            defaults.set(resolvedName, forKey: "milliProfileName")
            defaults.set(true, forKey: "milliHasCreatedAccount")
            defaults.set("apple", forKey: "milliAuthProvider")

            userEmail = resolvedEmail
            userFullName = resolvedName
            isSignedInWithApple = true

            return (email: resolvedEmail, name: resolvedName)

        case .failure(let error):
            currentRawNonce = nil
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                return nil
            }
            authErrorMessage = "Sign in with Apple encountered an issue: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Backend handoff

    func pendingBackendCredential() -> PendingBackendCredential? {
        guard let identityToken = Self.loadSecret(account: Self.pendingIdentityTokenKey),
              let rawNonce = Self.loadSecret(account: Self.pendingRawNonceKey),
              !identityToken.isEmpty,
              !rawNonce.isEmpty else {
            return nil
        }

        return PendingBackendCredential(
            identityToken: identityToken,
            rawNonce: rawNonce,
            displayName: userFullName ?? UserDefaults.standard.string(forKey: "milliProfileName")
        )
    }

    func clearPendingBackendCredential() {
        Self.deleteSecret(account: Self.pendingIdentityTokenKey)
        Self.deleteSecret(account: Self.pendingRawNonceKey)
    }

    // MARK: - Credential State Check

    public func verifyAppleCredentialState() async -> ASAuthorizationAppleIDProvider.CredentialState {
        guard let userID = currentAppleUserID else {
            return .notFound
        }

        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: userID)
            switch state {
            case .authorized:
                isSignedInWithApple = true
            case .revoked, .notFound:
                isSignedInWithApple = false
                signOut()
            case .transferred:
                break
            @unknown default:
                break
            }
            return state
        } catch {
            print("[AppleAuthManager] Credential state check failed: \(error)")
            return .notFound
        }
    }

    @objc private func handleCredentialRevokedNotification() {
        Task { @MainActor in
            self.signOut()
        }
    }

    // MARK: - Sign Out

    public func signOut() {
        Self.deleteSecret(account: Self.keychainAccountKey)
        clearPendingBackendCredential()
        MilliBackendClient.shared.clearSession()
        currentAppleUserID = nil
        isSignedInWithApple = false
        userEmail = nil
        userFullName = nil
    }

    // MARK: - Nonce

    private static func randomNonce(length: Int = 32) -> String? {
        guard length > 0 else { return nil }

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        while result.count < length {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = bytes.withUnsafeMutableBytes { buffer in
                SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
            }
            guard status == errSecSuccess else { return nil }

            for byte in bytes where result.count < length {
                if Int(byte) < charset.count * (256 / charset.count) {
                    result.append(charset[Int(byte) % charset.count])
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain

    @discardableResult
    private static func storeSecret(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
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
            kSecAttrService as String: keychainService,
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
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
