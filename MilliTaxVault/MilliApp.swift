import SwiftUI
import CoreLocation
import AuthenticationServices
import StoreKit

enum AppState: String {
    case splash
    case onboarding
    case setup
    case login
    case main
}

// MARK: - Navigation handoff
// Milli accepts its own deep-link contract everywhere and Apple's geo-navigation
// contract when iOS launches Milli as an eligible/default navigation app. A
// handoff is retained through sign-in so the destination is ready when the
// authenticated user reaches Mileage.

struct NavigationHandoffRequest: Identifiable, Equatable {
    let id = UUID()
    let destinationAddress: String?
    let destinationName: String?
    let latitude: Double?
    let longitude: Double?
    let sourceApp: String?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum NavigationHandoffParser {
    static func parse(_ url: URL) -> NavigationHandoffRequest? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let scheme = (components.scheme ?? "").lowercased()
        guard scheme == "milli" || scheme == "geo-navigation" else { return nil }

        let items = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }
        )

        // Apple's geo-navigation contract uses `destination` for directions and
        // `address` / `coordinate` for place requests. Milli also keeps aliases
        // for direct partner deep links.
        let destinationValue = firstNonEmpty(
            items["destination"],
            items["address"],
            items["daddr"],
            items["q"],
            items["query"]
        )

        let name = firstNonEmpty(items["name"], items["label"], items["title"])

        var latitude = double(items["lat"] ?? items["latitude"])
        var longitude = double(items["lon"] ?? items["lng"] ?? items["longitude"])

        // geo-navigation://place?coordinate=LAT,LON and Milli aliases.
        if latitude == nil || longitude == nil {
            let coordinateCandidates = [
                items["coordinate"],
                items["ll"],
                items["destination_coordinate"],
                destinationValue
            ]

            for candidate in coordinateCandidates {
                guard let parsed = coordinatePair(candidate) else { continue }
                latitude = parsed.latitude
                longitude = parsed.longitude
                break
            }
        }

        // For coordinate destinations, don't pass the raw "lat,lon" string back
        // through local search. The coordinate itself is authoritative.
        let destinationAddress: String? = {
            guard let destinationValue else { return nil }
            return coordinatePair(destinationValue) == nil ? destinationValue : nil
        }()

        // milli://navigate/123-main-st also works without a query string.
        let pathAddress: String? = {
            guard scheme == "milli" else { return nil }
            let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !path.isEmpty else { return nil }
            return path.removingPercentEncoding ?? path
        }()

        guard destinationAddress != nil || pathAddress != nil || (latitude != nil && longitude != nil) else {
            return nil
        }

        let sourceApp: String? = {
            if scheme == "geo-navigation" {
                return "iOS Navigation Handoff"
            }
            return firstNonEmpty(items["app"], items["provider"], items["source_app"])
        }()

        return NavigationHandoffRequest(
            destinationAddress: destinationAddress ?? pathAddress,
            destinationName: name,
            latitude: latitude,
            longitude: longitude,
            sourceApp: sourceApp
        )
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func double(_ value: String?) -> Double? {
        guard let value, !value.isEmpty else { return nil }
        return Double(value)
    }

    private static func coordinatePair(_ value: String?) -> (latitude: Double, longitude: Double)? {
        guard let value else { return nil }
        let parts = value
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 2,
              let latitude = Double(parts[0]),
              let longitude = Double(parts[1]),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude)
        else {
            return nil
        }

        return (latitude, longitude)
    }
}

@main
struct MilliApp: App {
    @State private var appState: AppState
    @State private var pendingNavigationRequest: NavigationHandoffRequest?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    @StateObject private var appleAuthManager = AppleAuthManager.shared
    @StateObject private var storeKitService = StoreKitService.shared

    init() {
        _pendingNavigationRequest = State(initialValue: nil)

        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        let environment = processInfo.environment
        let arguments = processInfo.arguments

        if let requestedState = environment["MILLI_APP_STATE"].flatMap(AppState.init(rawValue:)) {
            _appState = State(initialValue: requestedState)
        } else if let stateFlag = arguments.firstIndex(of: "-milliAppState"),
                  arguments.indices.contains(stateFlag + 1),
                  let requestedState = AppState(rawValue: arguments[stateFlag + 1]) {
            _appState = State(initialValue: requestedState)
        } else {
            let screenshotMode = environment["MILLI_SCREENSHOT_MODE"] == "1"
                || environment["MILLI_SCREEN"] != nil
                || arguments.contains("-milliScreenshotMode")

            _appState = State(initialValue: screenshotMode ? .main : .login)
        }
        #else
        _appState = State(initialValue: .login)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .splash:
                    SplashView(onComplete: {
                        transition(to: .login)
                    })
                    .transition(.opacity)

                case .login:
                    LoginView(
                        onSignIn: { _ in
                            handleReturningSignIn()
                        },
                        onCreateAccount: { _ in
                            beginNewAccountSetup()
                        }
                    )
                    .transition(.opacity)

                case .onboarding:
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                        transition(to: .setup)
                    })
                    .transition(.opacity)

                case .setup:
                    OnboardingFlowView(onComplete: {
                        hasCompletedSetup = true
                        activateSelectedTrialIfNeeded()
                        transition(to: .main)
                    })
                    .transition(.opacity)

                case .main:
                    ContentView(
                        pendingNavigationRequest: $pendingNavigationRequest,
                        onLogout: {
                            transition(to: .login)
                        }
                    )
                    .transition(.opacity)
                }
            }
            .environmentObject(appleAuthManager)
            .environmentObject(storeKitService)
            .animation(.easeInOut(duration: 0.32), value: appState)
            .preferredColorScheme(.dark)
            .onOpenURL(perform: handleIncomingNavigationURL)
            .task {
                // Verify Apple ID credential state on app launch
                _ = await appleAuthManager.verifyAppleCredentialState()
                // Update App Store entitlements on app launch
                await storeKitService.updateCustomerProductStatus()
            }
        }
    }

    private func handleIncomingNavigationURL(_ url: URL) {
        guard let request = NavigationHandoffParser.parse(url) else { return }
        pendingNavigationRequest = request

        // Never bypass authentication. If the user is already authenticated,
        // ContentView immediately routes to Mileage. Otherwise the request waits
        // through sign-in/onboarding and is consumed once the main shell appears.
        if appState == .main {
            return
        }

        if hasCompletedSetup, appState != .login {
            transition(to: .login)
        }
    }

    private func handleReturningSignIn() {
        if hasCompletedSetup {
            transition(to: .main)
        } else if hasCompletedOnboarding {
            transition(to: .setup)
        } else {
            transition(to: .onboarding)
        }
    }

    private func beginNewAccountSetup() {
        let defaults = UserDefaults.standard

        hasCompletedOnboarding = false
        hasCompletedSetup = false
        defaults.removeObject(forKey: "onboarding_vehicle")
        defaults.removeObject(forKey: "onboarding_taxProfile")
        defaults.removeObject(forKey: "onboarding_plan")
        defaults.removeObject(forKey: "milliAutopilotRetirementEnabled")
        defaults.removeObject(forKey: "milliAutopilotInvestingEnabled")
        defaults.removeObject(forKey: "milliAutopilotSavingsEnabled")
        defaults.removeObject(forKey: "milliAutopilotRetirementPercent")
        defaults.removeObject(forKey: "milliAutopilotInvestingPercent")
        defaults.removeObject(forKey: "milliAutopilotSavingsPercent")
        MilliTrialState.resetForNewLocalAccount()

        transition(to: .onboarding)
    }

    private func activateSelectedTrialIfNeeded() {
        let defaults = UserDefaults.standard
        let rawPlan = defaults.string(forKey: "onboarding_plan") ?? MilliPlan.pro.rawValue
        let plan = MilliPlan(rawValue: rawPlan) ?? .pro
        MilliTrialState.activateIfNeeded(plan: plan)
    }

    private func transition(to state: AppState) {
        withAnimation(.easeInOut(duration: 0.32)) {
            appState = state
        }
    }
}
