import SwiftUI

// MARK: - App State

/// Root-level observable state shared across the app via @EnvironmentObject.
/// Manages authentication, user profile, and global loading states.
@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: MilliUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    init() {
        // Restore session from stored token
        if api.isAuthenticated {
            isAuthenticated = true
            Task { await loadUserProfile() }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: AuthResponse = try await api.request(
                method: "POST",
                path: "/auth/login",
                body: ["email": email, "password": password]
            )
            api.authToken = response.token
            api.userId = response.user.id
            currentUser = response.user
            isAuthenticated = true
        } catch let error as APIService.APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        api.clearAuth()
        currentUser = nil
        isAuthenticated = false
    }

    func loadUserProfile() async {
        guard api.isAuthenticated else { return }
        do {
            let user: MilliUser = try await api.request(path: "/auth/me")
            currentUser = user
        } catch {
            // Silent fail — user can still use cached data
        }
    }
}
