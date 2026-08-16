import SwiftUI

enum AppState {
    case splash
    case onboarding
    case setup
    case login
    case main
}

@main
struct MilliApp: App {
    @State private var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    init() {
        #if DEBUG
        let screenshotMode = ProcessInfo.processInfo.arguments.contains("-milliScreenshotMode")
        _appState = State(initialValue: screenshotMode ? .main : .splash)
        #else
        _appState = State(initialValue: .splash)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .splash:
                    SplashView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if hasCompletedOnboarding && hasCompletedSetup {
                                appState = .login
                            } else if hasCompletedOnboarding {
                                appState = .setup
                            } else {
                                appState = .onboarding
                            }
                        }
                    })
                    .transition(.opacity)

                case .onboarding:
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState = .setup
                        }
                    })
                    .transition(.opacity)

                case .setup:
                    OnboardingFlowView(onComplete: {
                        hasCompletedSetup = true
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
        }
    }
}
