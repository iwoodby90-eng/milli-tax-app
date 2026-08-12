import SwiftUI

enum AppState {
    case splash
    case onboarding
    case login
    case main
}

@main
struct MilliApp: App {
    @State private var appState: AppState = .splash
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .splash:
                    SplashView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState = .onboarding
                        }
                    })
                    .transition(.opacity)
                    
                case .onboarding:
                    OnboardingView(onComplete: {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState = .login
                        }
                    })
                    .transition(.opacity)
                    
                case .login:
                    LoginView(onSignIn: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState = .main
                        }
                    })
                    .transition(.opacity)
                    
                case .main:
                    ContentView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: appState)
            .preferredColorScheme(.dark)
            .onAppear {
                if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    appState = .login
                }
            }
        }
    }
}
