import SwiftUI

@main
struct MilliTaxVaultApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.phase {
                case .splash:
                    SplashView()
                case .unauthenticated:
                    LoginView()
                case .authenticated:
                    ContentView()
                }
            }
            .environmentObject(appState)
            .preferredColorScheme(.dark)
        }
    }
}
