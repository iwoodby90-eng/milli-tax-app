import Foundation

// MARK: - API Service

/// Central network layer for all Milli backend communication.
/// Points to the production Render backend (same as the React/Capacitor frontend).
final class APIService {
    static let shared = APIService()

    private let baseURL = "https://milli-tax-app.onrender.com/api"
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - Token Management

    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "milli_token") }
        set { UserDefaults.standard.set(newValue, forKey: "milli_token") }
    }

    var isAuthenticated: Bool { authToken != nil }

    func clearAuth() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "milli_user_id")
    }

    var userId: String? {
        get { UserDefaults.standard.string(forKey: "milli_user_id") }
        set { UserDefaults.standard.set(newValue, forKey: "milli_user_id") }
    }

    // MARK: - Core Request

    enum APIError: Error, LocalizedError {
        case invalidURL
        case unauthorized
        case serverError(Int, String)
        case decodingFailed(Error)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .unauthorized: return "Session expired. Please log in again."
            case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
            case .decodingFailed(let e): return "Data error: \(e.localizedDescription)"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            }
        }
    }

    func request<T: Decodable>(
        method: String = "GET",
        path: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        case 401:
            clearAuth()
            throw APIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, msg)
        }
    }

    // Convenience for requests that return no meaningful data
    func requestVoid(
        method: String = "POST",
        path: String,
        body: [String: Any]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(method: method, path: path, body: body)
    }
}

struct EmptyResponse: Decodable {}
