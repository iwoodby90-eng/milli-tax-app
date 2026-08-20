import AuthenticationServices
import Foundation
import UIKit

/// Native Sign in with Apple coordinator for Milli.
///
/// This class returns only credentials actually supplied by Apple. It does not
/// create a fake local session or claim backend authentication succeeded. The
/// identity token / authorization code should be sent to Milli's authenticated
/// backend and verified there before establishing a production user session.
@MainActor
final class AppleAuthManager: NSObject, ObservableObject {
    enum AuthState: Equatable {
        case idle
        case authorizing
        case authorized
        case cancelled
        case failed(String)
    }

    @Published private(set) var state: AuthState = .idle
    @Published private(set) var appleUserIdentifier: String?
    @Published private(set) var email: String?
    @Published private(set) var fullName: PersonNameComponents?
    @Published private(set) var identityToken: Data?
    @Published private(set) var authorizationCode: Data?

    func signIn() {
        state = .authorizing

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func checkCredentialState(for userIdentifier: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userIdentifier) { credentialState, _ in
                continuation.resume(returning: credentialState)
            }
        }
    }

    func clearLocalCredentialMaterial() {
        appleUserIdentifier = nil
        email = nil
        fullName = nil
        identityToken = nil
        authorizationCode = nil
        state = .idle
    }
}

extension AppleAuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in
                state = .failed("Apple returned an unsupported credential type.")
            }
            return
        }

        Task { @MainActor in
            appleUserIdentifier = credential.user
            email = credential.email
            fullName = credential.fullName
            identityToken = credential.identityToken
            authorizationCode = credential.authorizationCode
            state = .authorized
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError = error as? ASAuthorizationError

        Task { @MainActor in
            if authError?.code == .canceled {
                state = .cancelled
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}

extension AppleAuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        if let anyWindow = scenes.flatMap({ $0.windows }).first {
            return anyWindow
        }

        return UIWindow(frame: UIScreen.main.bounds)
    }
}
