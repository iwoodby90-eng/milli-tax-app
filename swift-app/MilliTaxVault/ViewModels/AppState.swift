import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Phase { case splash, unauthenticated, authenticated }

    @Published var phase: Phase = .splash
    @Published var user: MilliUser?
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    func bootstrap() {
        phase = api.token != nil ? .authenticated : .unauthenticated
    }

    func authenticate(email: String, password: String) async {
        await run {
            let body: [String: String] = ["email": email, "password": password]
            let res: AuthResponse = try await self.api.request("auth/login", method: "POST", body: body, authorized: false)
            self.api.token = res.token
            self.user = res.user
            self.phase = .authenticated
        }
    }

    func register(fullName: String, email: String, password: String) async {
        await run {
            let body: [String: String] = ["full_name": fullName, "email": email, "password": password]
            let res: AuthResponse = try await self.api.request("auth/register", method: "POST", body: body, authorized: false)
            self.api.token = res.token
            self.user = res.user
            self.phase = .authenticated
        }
    }

    func signOut() {
        api.token = nil
        user = nil
        phase = .unauthenticated
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        do { try await work() }
        catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
        isWorking = false
    }
}
