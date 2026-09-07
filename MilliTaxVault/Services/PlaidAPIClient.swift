import Foundation

@MainActor
final class PlaidAPIClient: ObservableObject {
    static let shared = PlaidAPIClient()

    struct LinkTokenPayload: Decodable {
        let linkToken: String
        let expiration: String?
        enum CodingKeys: String, CodingKey { case linkToken = "link_token"; case expiration }
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
            case name, mask, type, subtype
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
        case invalidBaseURL, invalidResponse, noLinkedAccounts
        case server(status: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL: return "MILLI's bank connection service URL is not configured."
            case .invalidResponse: return "MILLI received an invalid response from the bank connection service."
            case let .server(status, message): return "Bank connection failed (\(status)): \(message)"
            case .noLinkedAccounts: return "Plaid connected successfully, but no eligible bank account was returned."
            }
        }
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func createLinkToken() async throws -> String {
        let request = try makeRequest(path: "plaid/link-token", method: "POST")
        let payload: LinkTokenPayload = try await send(request)
        return payload.linkToken
    }

    @discardableResult
    func exchangePublicToken(_ publicToken: String, institutionID: String?, institutionName: String?) async throws -> ExchangePayload {
        var request = try makeRequest(path: "plaid/exchange-public-token", method: "POST")
        request.httpBody = try encoder.encode(
            ExchangeRequestBody(publicToken: publicToken, institutionID: institutionID, institutionName: institutionName)
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
        guard let base = MilliAuthenticatedSession.baseURL(),
              let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw ClientError.invalidBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await MilliAuthenticatedSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.server(status: http.statusCode, message: Self.serverMessage(data))
        }
        return try decoder.decode(T.self, from: data)
    }

    private static func serverMessage(_ data: Data) -> String {
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["detail"] as? String) ?? (json?["message"] as? String) ?? "Unknown server error"
    }
}
