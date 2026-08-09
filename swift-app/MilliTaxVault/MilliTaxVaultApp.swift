import SwiftUI

@main
struct MilliTaxVaultApp: App {
    @StateObject private var appState = AppState()
    @State private var appReady = false

    var body: some Scene {
        WindowGroup {
            if appReady {
                ContentView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)
            } else {
                SplashView(onComplete: { appReady = true })
                    .preferredColorScheme(.dark)
            }
        }
    }
}
