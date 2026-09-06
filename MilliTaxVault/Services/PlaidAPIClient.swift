import Foundation

// MARK: - Plaid API Client
// Talks only to MILLI's backend. Plaid client_id/secret and Plaid access tokens
// never ship in the iOS binary.

@MainActor
final class PlaidAPIClient: ObservableObject {
    static let shared = PlaidAPIClient()

    struct LinkTokenPayload: Decodable {
        let linkToken: String
        let expiration: String?

        enum CodingKeys: String, CodingKey {
            case linkToken = "link_token"
            case expiration
        }
    }

    struct ExchangePayload: Decodable {
        let itemID: String
        let accountsLinked: Int

        enum CodingKeys: String, CodingKey {
            case itemID = "item_id"
            case accountsLinked = "accounts_linked"
        }
    }

    struct AccountsEnvelope: Decodable {
        let accounts: [PlaidAccountSnapshot]
        let count: Int
    }

    struct PlaidAccountSnapshot: Decodable, Identifiable {
        let accountID: String
        let name: String?
        let mask: String?
        let type: String?
        let subtype: String?
        let availableBalance: Double?
        let currentBalance: Double?
        let institutionName: String?
        let itemStatus: String?

        var id: String { accountID }

        enum CodingKeys: String, CodingKey {
            case accountID = "account_id"
            case name
            case mask
            case type
            case subtype
            case availableBalance = "available_balance"
            case currentBalance = "current_balance"
            case institutionName = "institution_name"
            case itemStatus = "item_status"
        }
    }

    private struct ExchangeRequestBody: Encodable {
        let publicToken: String
        let institutionID: String?
        let institutionName: String?

        enum CodingKeys: String, CodingKey {
            case publicToken = "public_token"
            case institutionID = "institution_id"
            case institutionName = "institution_name"
        }
    }

    enum ClientError: LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case server(status: Int, message: String)
        case noLinkedAccounts

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "MILLI's bank connection service URL is not configured."
            case .invalidResponse:
                return "MILLI received an invalid response from the bank connection service."
            case let .server(status, message):
                return "Bank connection failed (\(status)): \(message)"
            case .noLinkedAccounts:
                return "Plaid connected successfully, but no eligible bank account was returned."
            }
        }
    }

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func createLinkToken() async throws -> String {
        let request = try makeRequest(path: "plaid/link-token", method: "POST")
        let payload: LinkTokenPayload = try await send(request)
        return payload.linkToken
    }

    @discardableResult
    func exchangePublicToken(
        _ publicToken: String,
        institutionID: String?,
        institutionName: String?
    ) async throws -> ExchangePayload {
        var request = try makeRequest(path: "plaid/exchange-public-token", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(
            ExchangeRequestBody(
                publicToken: publicToken,
                institutionID: institutionID,
                institutionName: institutionName
            )
        )
        return try await send(request)
    }

    func fetchAccounts() async throws -> [PlaidAccountSnapshot] {
        let request = try makeRequest(path: "plaid/accounts", method: "GET")
        let envelope: AccountsEnvelope = try await send(request)
        guard !envelope.accounts.isEmpty else { throw ClientError.noLinkedAccounts }
        return envelope.accounts
    }

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let baseURL = configuredBaseURL(),
              let url = URL(string: path, relativeTo: baseURL)?.absoluteURL
        else {
            throw ClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(persistentUserID().uuidString, forHTTPHeaderField: "X-Milli-User-Id")

        if let clientKey = configuredClientKey(), !clientKey.isEmpty {
            request.setValue(clientKey, forHTTPHeaderField: "X-Milli-Client-Key")
        }
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.server(
                status: http.statusCode,
                message: Self.extractServerMessage(from: data)
            )
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ClientError.invalidResponse
        }
    }

    private func configuredBaseURL() -> URL? {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = (configured?.isEmpty == false)
            ? configured!
            : "https://milli-tax-app-1.onrender.com"
        return URL(string: raw.hasSuffix("/") ? raw : raw + "/")
    }

    private func configuredClientKey() -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "MILLI_CLIENT_API_KEY") as? String else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains("$(") else { return nil }
        return value
    }

    private func persistentUserID() -> UUID {
        let key = "milliBackendUserUUID"
        if let raw = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: raw) {
            return uuid
        }
        let uuid = UUID()
        UserDefaults.standard.set(uuid.uuidString, forKey: key)
        return uuid
    }

    private static func extractServerMessage(from data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Unknown server error"
        }
        if let detail = object["detail"] as? String { return detail }
        if let message = object["message"] as? String { return message }
        return "Unknown server error"
    }
}
