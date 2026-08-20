import SwiftUI
import AuthenticationServices
import Security

// MARK: - Sign in with Apple Authentication Manager
// Handles Sign in with Apple & Sign up with Apple via AuthenticationServices.
// Manages ASAuthorizationAppleIDCredential lifecycle, secure Keychain storage of Apple User ID,
// credential status verification, and token revocation listeners.

@MainActor
public final class AppleAuthManager: NSObject, ObservableObject {
    public static let shared = AppleAuthManager()

    // MARK: - Published State
    @Published public private(set) var isSignedInWithApple = false
    @Published public private(set) var currentAppleUserID: String?
    @Published public private(set) var userEmail: String?
    @Published public private(set) var userFullName: String?
    @Published public private(set) var isProcessing = false
    @Published public var authErrorMessage: String?

    private static let keychainService = "com.milli.taxvault.apple-auth"
    private static let keychainAccountKey = "milliAppleUserID"

    public override init() {
        super.init()

        // Load existing Apple User ID from Keychain
        if let storedUserID = Self.loadAppleUserIDFromKeychain() {
            self.currentAppleUserID = storedUserID
            self.isSignedInWithApple = true
            self.userEmail = UserDefaults.standard.string(forKey: "milliAppleUserEmail")
            self.userFullName = UserDefaults.standard.string(forKey: "milliAppleUserName")
        }

        // Listen for Apple ID credential revocation from Settings or other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCredentialRevokedNotification),
            name: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil
        )
    }

    // MARK: - Configure Apple ID Request
    public func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    // MARK: - Handle Authorization Result
    /// Processes completion of ASAuthorization (Sign In or Sign Up)
    /// Returns a tuple of (email, name) on successful authorization, or nil on failure/cancellation.
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
                authErrorMessage = "Received invalid credential from Apple."
                return nil
            }

            let userID = appleIDCredential.user
            self.currentAppleUserID = userID

            // Extract Name components if provided (Apple only sends name/email on FIRST authorization)
            var resolvedName: String = ""
            if let fullName = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                resolvedName = formatter.string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if resolvedName.isEmpty {
                resolvedName = UserDefaults.standard.string(forKey: "milliProfileName") ?? "Milli Member"
            }

            // Extract Email if provided
            var resolvedEmail: String = ""
            if let email = appleIDCredential.email {
                resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            } else if let storedEmail = UserDefaults.standard.string(forKey: "milliAppleUserEmail") {
                resolvedEmail = storedEmail
            } else if let profileEmail = UserDefaults.standard.string(forKey: "milliProfileEmail") {
                resolvedEmail = profileEmail
            } else {
                resolvedEmail = "\(userID.prefix(8).lowercased())@privaterelay.appleid.com"
            }

            // Save to Keychain and local store
            Self.saveAppleUserIDToKeychain(userID: userID)
            let defaults = UserDefaults.standard
            defaults.set(resolvedEmail, forKey: "milliAppleUserEmail")
            defaults.set(resolvedName, forKey: "milliAppleUserName")
            defaults.set(resolvedEmail, forKey: "milliProfileEmail")
            defaults.set(resolvedName, forKey: "milliProfileName")
            defaults.set(true, forKey: "milliHasCreatedAccount")
            defaults.set("apple", forKey: "milliAuthProvider")

            self.userEmail = resolvedEmail
            self.userFullName = resolvedName
            self.isSignedInWithApple = true

            return (email: resolvedEmail, name: resolvedName)

        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                // User intentionally dismissed Apple sheet
                return nil
            }
            authErrorMessage = "Sign in with Apple encountered an issue: \(error.localizedDescription)"
            return nil
        }
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
                self.isSignedInWithApple = true
            case .revoked, .notFound:
                self.isSignedInWithApple = false
                self.signOut()
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
        Self.deleteAppleUserIDFromKeychain()
        currentAppleUserID = nil
        isSignedInWithApple = false
        userEmail = nil
        userFullName = nil
    }

    // MARK: - Keychain Security Utilities
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
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

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
