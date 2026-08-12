import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    enum Phase { case splash, unauthenticated, authenticated }

    @Published var phase: Phase = .splash
    @Published var user: MilliUser?
    @Published var isWorking = false
    @Published var errorMessage: String?

    // Compatibility computed properties
    var isLoading: Bool { isWorking }
    var isAuthenticated: Bool { phase == .authenticated }
    var currentUser: MilliUser? { user }

    private let api = APIService.shared

    func bootstrap() {
        phase = api.authToken != nil ? .authenticated : .unauthenticated
    }

    func login(email: String, password: String) async {
        await run {
            let body: [String: Any] = ["email": email, "password": password]
            let res: AuthResponse = try await self.api.request(method: "POST", path: "/auth/login", body: body)
            self.api.authToken = res.token
            self.user = res.user
            self.phase = .authenticated
        }
    }

    func register(fullName: String, email: String, password: String) async {
        await run {
            let body: [String: Any] = ["full_name": fullName, "email": email, "password": password]
            let res: AuthResponse = try await self.api.request(method: "POST", path: "/auth/register", body: body)
            self.api.authToken = res.token
            self.user = res.user
            self.phase = .authenticated
        }
    }

    func logout() {
        api.clearAuth()
        user = nil
        phase = .unauthenticated
    }

    func signOut() { logout() }

    private func run(_ work: @escaping () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        do { try await work() }
        catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
        isWorking = false
    }
}
