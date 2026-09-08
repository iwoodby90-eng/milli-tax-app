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

// MARK: - Tax Vault onboarding settings
// The onboarding flow must not claim Autopilot is enabled until the authoritative
// backend configuration has been persisted. This tiny client intentionally
// shares the same Render URL/header contract as MilliBackendClient while keeping
// the Plaid secret, Plaid access token, and bank credentials server-side.

actor MilliBackendVaultSettingsClient {
    static let shared = MilliBackendVaultSettingsClient()

    enum SettingsError: LocalizedError {
        case backendUnavailable
        case missingUserIdentity
        case rejected(status: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .backendUnavailable:
                return "Milli couldn't reach the banking service to save Autopilot. Check your connection and try again."
            case .missingUserIdentity:
                return "Milli couldn't identify this local profile for the banking service. Sign in again and retry setup."
            case .rejected(let status, let message):
                return "Milli couldn't save Autopilot settings (\(status)): \(message)"
            }
        }
    }

    private let session: URLSession
    private var resolvedBaseURL: URL?

    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
    }

    func update(reserveRate: Double, autopilotEnabled: Bool) async throws {
        guard let userID = UserDefaults.standard.string(forKey: "milliBackendUserID"),
              UUID(uuidString: userID) != nil
        else {
            throw SettingsError.missingUserIdentity
        }

        let baseURL = try await resolveBaseURL()
        let url = baseURL.appending(path: "tax-vault/settings")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userID, forHTTPHeaderField: "X-Milli-User-Id")

        if let clientKey = configuredClientKey, !clientKey.isEmpty {
            request.setValue(clientKey, forHTTPHeaderField: "X-Milli-Client-Key")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "reserve_rate": min(max(reserveRate, 0), 1),
            "autopilot_enabled": autopilotEnabled
        ])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            resolvedBaseURL = nil
            throw SettingsError.backendUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw SettingsError.backendUnavailable
        }

        guard (200...299).contains(http.statusCode) else {
            let message: String
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = object["detail"] as? String {
                message = detail
            } else {
                message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            }
            throw SettingsError.rejected(status: http.statusCode, message: message)
        }
    }

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
                  (200...299).contains(http.statusCode)
            else {
                continue
            }

            resolvedBaseURL = candidate
            return candidate
        }

        throw SettingsError.backendUnavailable
    }

    private var candidateBaseURLs: [URL] {
        var values: [String] = []

        if let value = ProcessInfo.processInfo.environment["MILLI_API_BASE_URL"] {
            values.append(value)
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String {
            values.append(value)
        }

        // Migration fallbacks only. Production should set MILLI_API_BASE_URL.
        values.append("https://milli-tax-vault-api.onrender.com")
        values.append("https://milli-tax-app.onrender.com")

        var seen = Set<String>()
        return values.compactMap { raw in
            let value = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !value.isEmpty, seen.insert(value).inserted else { return nil }
            return URL(string: value)
        }
    }

    private var configuredClientKey: String? {
        if let value = ProcessInfo.processInfo.environment["MILLI_CLIENT_API_KEY"], !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "MILLI_CLIENT_API_KEY") as? String, !value.isEmpty {
            return value
        }
        return nil
    }
}
