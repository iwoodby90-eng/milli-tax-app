import Foundation
import SwiftUI
import LinkKit

// MARK: - PlaidLinkCoordinator
// Owns one Plaid LinkKit 7 session at a time and completes the token exchange
// against Milli's Render backend. No Plaid secret or access token is stored on
// the device.

@MainActor
final class PlaidLinkCoordinator: ObservableObject {
    @Published private(set) var linkSession: LinkKit.PlaidLinkSession?
    @Published var isPresentingLink = false
    @Published private(set) var isLoading = false
    @Published private(set) var availableAccounts: [MilliPlaidAccount] = []
    @Published private(set) var connectedAccount: MilliPlaidAccount?
    @Published var errorMessage: String?

    private let backend = MilliBackendClient.shared

    var isConnected: Bool { connectedAccount != nil }
    var requiresPayoutAccountSelection: Bool {
        connectedAccount == nil && availableAccounts.count > 1
    }

    func begin() {
        guard !isLoading, !isPresentingLink else { return }

        errorMessage = nil
        availableAccounts = []
        connectedAccount = nil
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
        availableAccounts = []
        connectedAccount = nil
        errorMessage = nil
    }

    func selectPayoutAccount(_ account: MilliPlaidAccount) async {
        guard availableAccounts.contains(where: { $0.id == account.id }) else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await backend.selectPlaidPayoutSource(accountID: account.accountID)
            connectedAccount = account
            errorMessage = nil
        } catch {
            connectedAccount = nil
            errorMessage = error.localizedDescription
        }
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
            guard !accounts.isEmpty else {
                errorMessage = "Plaid connected successfully, but Render did not return a linked account. Check migration 003 and DATABASE_URL on Render."
                linkSession = nil
                return
            }

            availableAccounts = accounts
            linkSession = nil

            // If Plaid returned exactly one account, there is no ambiguity and
            // the user has effectively selected it through Link. Persist it as
            // the payout source. With multiple accounts, stop here and require
            // an explicit choice in onboarding rather than guessing.
            if accounts.count == 1, let onlyAccount = accounts.first {
                try await backend.selectPlaidPayoutSource(accountID: onlyAccount.accountID)
                connectedAccount = onlyAccount
            } else {
                connectedAccount = nil
            }

            errorMessage = nil
        } catch {
            linkSession = nil
            connectedAccount = nil
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Tax Vault onboarding settings
// Uses the same authenticated bearer-session client as every other financial
// endpoint. No duplicated client UUID/shared-secret path is allowed.

@MainActor
final class MilliBackendVaultSettingsClient {
    static let shared = MilliBackendVaultSettingsClient()

    private init() {}

    func update(reserveRate: Double, autopilotEnabled: Bool) async throws {
        try await MilliBackendClient.shared.updateVaultSettings(
            reserveRate: reserveRate,
            autopilotEnabled: autopilotEnabled
        )
    }
}
