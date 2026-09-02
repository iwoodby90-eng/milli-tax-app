import SwiftUI
import AuthenticationServices

// MARK: - BankLinkCoordinator
// Runs the Stripe Financial Connections hosted link flow:
// 1. Backend creates a link session (holds the Stripe secret key — never in the app).
// 2. ASWebAuthenticationSession opens the hosted page where the user searches
//    their bank, selects it, logs in securely on the bank's own page, and
//    consents to sharing account data with Milli.
// 3. Stripe redirects back with the session result; the app finalizes with the
//    backend, which retrieves the connected accounts and live balances.
//
// Financial truth: nothing is marked connected or LIVE until the backend
// confirms the session completed. Cancelled/failed flows leave the previous
// state untouched.

@MainActor
public final class BankLinkCoordinator: NSObject, ObservableObject {
    public static let shared = BankLinkCoordinator()

    @Published public private(set) var isLinking = false
    @Published public var linkError: String?

    private var webSession: ASWebAuthenticationSession?

    private override init() { super.init() }

    /// Launches the full hosted bank-link flow. Completion is called with the
    /// connected accounts on success, nil on cancel/failure.
    public func startLink(
        presentationContext: ASPresentationAnchor,
        completion: @escaping (ConnectedAccountsResponse?) -> Void
    ) {
        guard !isLinking else { return }
        isLinking = true
        linkError = nil

        Task { @MainActor in
            do {
                let session = try await MilliBackendClient.shared.createBankLinkSession()

                let result = await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
                    let web = ASWebAuthenticationSession(
                        url: session.hostedUrl,
                        callbackURLScheme: session.returnUrl.scheme ?? "milli"
                    ) { url, error in
                        if let error as? ASWebAuthenticationSessionError,
                           error.code == .canceledLogin {
                            continuation.resume(returning: nil)
                        } else {
                            continuation.resume(returning: url)
                        }
                    }
                    web.presentationContextProvider = self
                    web.prefersEphemeralWebBrowserSession = false
                    self.webSession = web
                    _ = web.start()
                }

                guard let callbackURL = result else {
                    self.isLinking = false
                    completion(nil)
                    return
                }

                // Extract sessionId from the callback (query param or path tail).
                let sessionId = Self.sessionId(from: callbackURL, expected: session.sessionId)

                let accounts = try await MilliBackendClient.shared.completeBankLink(sessionId: sessionId)
                self.isLinking = false
                completion(accounts)
            } catch {
                self.linkError = error.localizedDescription
                self.isLinking = false
                completion(nil)
            }
        }
    }

    private static func sessionId(from url: URL, expected fallback: String) -> String {
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let value = comps.queryItems?.first(where: { $0.name == "session_id" || $0.name == "sessionId" })?.value {
            return value
        }
        return fallback
    }
}

extension BankLinkCoordinator: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}