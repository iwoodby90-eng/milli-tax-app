import Foundation

// MARK: - Brokerage trading
// The iOS app never talks to a broker with embedded partner credentials. Orders
// are submitted to Milli's authenticated backend, which is responsible for
// customer brokerage-account eligibility, disclosures, buying power, positions,
// idempotency, broker submission, and order-state webhooks.

enum BrokerageOrderSide: String, Codable, CaseIterable {
    case buy
    case sell

    var displayName: String { rawValue.capitalized }
}

enum BrokerageOrderType: String, Codable, CaseIterable {
    case market
    case limit

    var displayName: String { rawValue.capitalized }
}

enum BrokerageQuantityMode: String, Codable, CaseIterable {
    case dollars
    case shares

    var displayName: String {
        switch self {
        case .dollars: return "Dollars"
        case .shares: return "Shares"
        }
    }
}

struct BrokerageOrderRequest: Codable {
    let symbol: String
    let side: BrokerageOrderSide
    let type: BrokerageOrderType
    let quantityMode: BrokerageQuantityMode
    let amount: Double
    let limitPrice: Double?
    let clientOrderID: String
}

struct BrokerageOrderResponse: Codable {
    let id: String
    let clientOrderID: String?
    let symbol: String
    let side: String
    let status: String
    let submittedAt: Date?
}

enum BrokerageAvailability: Equatable {
    case checking
    case available
    case setupRequired
    case unavailable(String)
}

enum BrokerageTradingError: LocalizedError {
    case notConfigured
    case missingSession
    case invalidResponse
    case rejected(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Brokerage trading is not configured for this build."
        case .missingSession:
            return "Sign in again before submitting a trade."
        case .invalidResponse:
            return "Milli could not verify the brokerage response."
        case .rejected(let message):
            return message
        }
    }
}

@MainActor
final class BrokerageTradingService: ObservableObject {
    static let shared = BrokerageTradingService()

    @Published private(set) var availability: BrokerageAvailability = .checking
    @Published private(set) var isSubmitting = false

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        refreshAvailability()
    }

    func refreshAvailability() {
        guard backendBaseURL != nil else {
            availability = .setupRequired
            return
        }
        availability = .available
    }

    func submit(_ order: BrokerageOrderRequest) async throws -> BrokerageOrderResponse {
        guard let baseURL = backendBaseURL else {
            throw BrokerageTradingError.notConfigured
        }
        guard let token = authToken, !token.isEmpty else {
            throw BrokerageTradingError.missingSession
        }

        var request = URLRequest(url: baseURL.appending(path: "api/brokerage/orders"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(order.clientOrderID, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONEncoder.milliBroker.encode(order)

        isSubmitting = true
        defer { isSubmitting = false }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BrokerageTradingError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder.milliBroker.decode(BrokerageErrorEnvelope.self, from: data).message)
                ?? "The brokerage rejected this order."
            throw BrokerageTradingError.rejected(message)
        }

        guard let orderResponse = try? JSONDecoder.milliBroker.decode(BrokerageOrderResponse.self, from: data) else {
            throw BrokerageTradingError.invalidResponse
        }
        return orderResponse
    }

    private var backendBaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return URL(string: raw)
    }

    private var authToken: String? {
        // The production auth layer should expose a short-lived backend token here.
        // No broker secret or API key belongs in the client application.
        UserDefaults.standard.string(forKey: "milli_backend_access_token")
    }
}

private struct BrokerageErrorEnvelope: Codable {
    let message: String
}

private extension JSONEncoder {
    static var milliBroker: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var milliBroker: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
