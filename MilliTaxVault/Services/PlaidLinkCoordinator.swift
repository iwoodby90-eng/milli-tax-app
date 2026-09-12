import SwiftUI
import LinkKit

// MARK: - PlaidLinkCoordinator
// Owns one Plaid LinkKit 7 session at a time and completes the token exchange
// against Milli's backend. No Plaid secret or access token is stored on device.

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
                // A fresh server-generated Link token is required for every Link session.
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
                let institutionID = success.metadata.institution.id
                let institutionName = success.metadata.institution.name

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isPresentingLink = false

                    guard !publicToken.isEmpty else {
                        self.isLoading = false
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
                // Link analytics remain inside Plaid. Never log credentials,
                // public tokens, account identifiers, or institution secrets.
            },
            onLoad: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.isPresentingLink = true
                }
            }
        )

        linkSession = Plaid.createPlaidLinkSession(configuration: configuration)
    }

    private func completeConnection(
        publicToken: String,
        institutionID: String?,
        institutionName: String?
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Public token exchange occurs server-side. The Plaid access token
            // is persisted by Milli's backend and is never returned to iOS.
            _ = try await backend.exchangePlaidPublicToken(
                publicToken,
                institutionID: institutionID,
                institutionName: institutionName
            )

            let accounts = try await backend.fetchPlaidAccounts()
            guard let account = accounts.first(where: {
                ($0.subtype ?? "").localizedCaseInsensitiveContains("checking")
            }) ?? accounts.first else {
                errorMessage = "Plaid connected successfully, but Milli did not receive a linked account."
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
