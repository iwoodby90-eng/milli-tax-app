import SwiftUI
import AuthenticationServices
import Security

// MARK: - Sign in with Apple Authentication Manager
// Apple's device credential establishes identity only after Milli's backend
// verifies the signed identity token against a one-time server nonce.

@MainActor
public final class AppleAuthManager: NSObject, ObservableObject {
    public static let shared = AppleAuthManager()

    public struct CredentialEnvelope {
        public let email: String
        public let name: String
        public let identityToken: String
    }

    @Published public private(set) var isSignedInWithApple = false
    @Published public private(set) var isFinancialSessionAuthenticated = false
    @Published public private(set) var isBackendChallengeReady = false
    @Published public private(set) var currentAppleUserID: String?
    @Published public private(set) var userEmail: String?
    @Published public private(set) var userFullName: String?
    @Published public private(set) var isProcessing = false
    @Published public var authErrorMessage: String?

    private static let keychainService = "com.milli.taxvault.apple-auth"
    private static let keychainAccountKey = "milliAppleUserID"
    private var backendChallenge: MilliBackendClient.AppleAuthChallenge?

    public override init() {
        super.init()

        if let storedUserID = Self.loadAppleUserIDFromKeychain() {
            currentAppleUserID = storedUserID
            isSignedInWithApple = true
            userEmail = UserDefaults.standard.string(forKey: "milliAppleUserEmail")
            userFullName = UserDefaults.standard.string(forKey: "milliAppleUserName")
        }
        isFinancialSessionAuthenticated = MilliBackendClient.shared.hasFinancialSession

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCredentialRevokedNotification),
            name: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil
        )
    }

    public func prepareBackendChallenge(force: Bool = false) async {
        if isBackendChallengeReady && !force { return }
        authErrorMessage = nil
        isBackendChallengeReady = false
        backendChallenge = nil

        do {
            backendChallenge = try await MilliBackendClient.shared.createAppleAuthChallenge()
            isBackendChallengeReady = true
        } catch {
            authErrorMessage = "Secure sign-in is temporarily unavailable: \(error.localizedDescription)"
        }
    }

    public func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        request.nonce = backendChallenge?.nonce
    }

    public func handleAuthorizationCompletion(
        result: Result<ASAuthorization, Error>
    ) -> CredentialEnvelope? {
        authErrorMessage = nil

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authErrorMessage = "Received invalid credential from Apple."
                return nil
            }
            guard let identityData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityData, encoding: .utf8),
                  !identityToken.isEmpty
            else {
                authErrorMessage = "Apple did not return the identity proof required for secure sign-in."
                return nil
            }

            let userID = appleIDCredential.user
            currentAppleUserID = userID

            var resolvedName = ""
            if let fullName = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                resolvedName = formatter.string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
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

            Self.saveAppleUserIDToKeychain(userID: userID)
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

            return CredentialEnvelope(
                email: resolvedEmail,
                name: resolvedName,
                identityToken: identityToken
            )

        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                return nil
            }
            authErrorMessage = "Sign in with Apple encountered an issue: \(error.localizedDescription)"
            return nil
        }
    }

    public func establishFinancialSession(identityToken: String) async throws -> Bool {
        guard let backendChallenge else {
            throw MilliBackendClient.ClientError.financialSignInRequired
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let isNewUser = try await MilliBackendClient.shared.exchangeAppleIdentity(
                challengeID: backendChallenge.challengeID,
                identityToken: identityToken
            )
            self.backendChallenge = nil
            isBackendChallengeReady = false
            isFinancialSessionAuthenticated = true
            return isNewUser
        } catch {
            MilliBackendClient.shared.clearFinancialSession()
            isFinancialSessionAuthenticated = false
            await prepareBackendChallenge(force: true)
            throw error
        }
    }

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
            return .notFound
        }
    }

    @objc private func handleCredentialRevokedNotification() {
        Task { @MainActor in
            self.signOut()
        }
    }

    public func signOut() {
        Task { @MainActor in
            await MilliBackendClient.shared.logout()
        }
        Self.deleteAppleUserIDFromKeychain()
        currentAppleUserID = nil
        isSignedInWithApple = false
        isFinancialSessionAuthenticated = false
        isBackendChallengeReady = false
        backendChallenge = nil
        userEmail = nil
        userFullName = nil
    }

    private static func saveAppleUserIDToKeychain(userID: String) {
        guard let data = userID.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccountKey
        ]

        SecItemDelete(query as CFDictionary)

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(insert as CFDictionary, nil)
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
              let data = result as? Data,
              let userID = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return userID
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
