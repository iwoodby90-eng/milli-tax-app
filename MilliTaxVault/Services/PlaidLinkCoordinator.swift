import SwiftUI
import LinkKit

// MARK: - PlaidLinkCoordinator
// Owns one Plaid LinkKit 7 session at a time and completes the token exchange
// against Milli's Render backend. No Plaid secret or access token is stored on
// the device.

@MainActor
final class PlaidLinkCoordinator: ObservableObject {
    @Published private(set) var linkSession: PlaidLinkSession?
    @Published var isPresentingLink = false
    @Published private(set) var isLoading = false
    @Published private(set) var connectedAccount: MilliPlaidAccount?
    @Published var errorMessage: String?

    private let backend = MilliBackendClient.shared

    var isConnected: Bool { connectedAccount != nil }

    func begin() {
        guard !isLoading, !isPresentingLink else { return }

        errorMessage = nil
        isLoading = true
        linkSession = nil

        Task {
            do {
                let linkToken = try await backend.createPlaidLinkToken()
                createSession(linkToken: linkToken)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func reset() {
        isPresentingLink = false
        isLoading = false
        linkSession = nil
        connectedAccount = nil
        errorMessage = nil
    }

    private func createSession(linkToken: String) {
        let configuration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { [weak self] success in
                let publicToken = success.publicToken
                let institutionID = success.metadata.institution?.id
                let institutionName = success.metadata.institution?.name

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isPresentingLink = false

                    guard let publicToken, !publicToken.isEmpty else {
                        self.errorMessage = "Plaid completed without returning a bank connection token. Please try again."
                        self.linkSession = nil
                        return
                    }

                    await self.completeConnection(
                        publicToken: publicToken,
                        institutionID: institutionID,
                        institutionName: institutionName
                    )
                }
            },
            onExit: { [weak self] exit in
                let exitMessage = exit.error?.displayMessage
                    ?? exit.error?.errorMessage

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isPresentingLink = false
                    self.isLoading = false
                    self.linkSession = nil
                    if let exitMessage, !exitMessage.isEmpty {
                        self.errorMessage = exitMessage
                    }
                }
            },
            onEvent: { _ in
                // Link analytics remain inside Plaid. Milli never logs bank
                // credentials or account secrets from Link events.
            },
            onLoad: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.isPresentingLink = true
                }
            }
        )

        do {
            linkSession = try Plaid.createPlaidLinkSession(configuration: configuration)
        } catch {
            isLoading = false
            linkSession = nil
            errorMessage = "Milli couldn't initialize Plaid Link: \(error.localizedDescription)"
        }
    }

    private func completeConnection(
        publicToken: String,
        institutionID: String?,
        institutionName: String?
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await backend.exchangePlaidPublicToken(
                publicToken,
                institutionID: institutionID,
                institutionName: institutionName
            )

            let accounts = try await backend.fetchPlaidAccounts()
            guard let account = accounts.first else {
                errorMessage = "Plaid connected successfully, but Render did not return a linked account. Check migration 003 and DATABASE_URL on Render."
                linkSession = nil
                return
            }

            connectedAccount = account
            linkSession = nil
            errorMessage = nil
        } catch {
            linkSession = nil
            errorMessage = error.localizedDescription
        }
    }
}
