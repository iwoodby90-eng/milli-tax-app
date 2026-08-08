import SwiftUI

@main
struct MilliTaxVaultApp: App {
    @State private var appReady = false
    
    var body: some Scene {
        WindowGroup {
            if appReady {
                ContentView()
                    .preferredColorScheme(.dark)
            } else {
                SplashView(onComplete: { appReady = true })
                    .preferredColorScheme(.dark)
            }
        }
    }
}
