import SwiftUI
import CoreLocation
import MapKit
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
// Milli accepts Apple Maps routing requests, Apple's geo-navigation contract in
// eligible regions, and Milli's own deep links. The handoff is retained through
// authentication and consumed by the native navigation cockpit.

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
        // Registered iOS routing apps receive a MapKit directions-request URL.
        // Decode this first instead of attempting to reverse-engineer its query.
        if MKDirections.Request.isDirectionsRequest(url) {
            let directionsRequest = MKDirections.Request(contentsOf: url)
            guard let destination = directionsRequest.destination else { return nil }
            let coordinate = destination.placemark.coordinate
            let hasValidCoordinate = CLLocationCoordinate2DIsValid(coordinate)

            return NavigationHandoffRequest(
                destinationAddress: nil,
                destinationName: destination.name,
                latitude: hasValidCoordinate ? coordinate.latitude : nil,
                longitude: hasValidCoordinate ? coordinate.longitude : nil,
                sourceApp: "Apple Maps"
            )
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let scheme = (components.scheme ?? "").lowercased()
        guard scheme == "milli" || scheme == "geo-navigation" else { return nil }

        let items = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }
        )

        // geo-navigation://directions uses `destination`; Milli deep links also
        // accept address/daddr/q/query for compatibility with existing handoffs.
        let address = firstNonEmpty(
            items["destination"],
            items["address"],
            items["daddr"],
            items["q"],
            items["query"]
        )

        let name = firstNonEmpty(items["name"], items["label"], items["title"])
        let sourceApp = scheme == "milli"
            ? firstNonEmpty(items["app"], items["provider"], items["source_app"])
            : "System Navigation"

        var latitude = double(items["lat"] ?? items["latitude"])
        var longitude = double(items["lon"] ?? items["lng"] ?? items["longitude"])

        if (latitude == nil || longitude == nil),
           let coordinateText = firstNonEmpty(
                items["coordinate"],
                items["destination_coordinate"],
                items["ll"],
                coordinateCandidate(from: items["destination"])
           ) {
            let parts = coordinateText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count >= 2 {
                latitude = Double(parts[0])
                longitude = Double(parts[1])
            }
        }

        // milli://navigate/123-main-st also works without a query string.
        let pathAddress: String? = {
            guard scheme == "milli" else { return nil }
            let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !path.isEmpty else { return nil }
            return path.removingPercentEncoding ?? path
        }()

        guard address != nil || pathAddress != nil || (latitude != nil && longitude != nil) else {
            return nil
        }

        return NavigationHandoffRequest(
            destinationAddress: address ?? pathAddress,
            destinationName: name,
            latitude: latitude,
            longitude: longitude,
            sourceApp: sourceApp
        )
    }

    private static func coordinateCandidate(from value: String?) -> String? {
        guard let value else { return nil }
        let parts = value.split(separator: ",")
        guard parts.count == 2,
              Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)) != nil,
              Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) != nil else {
            return nil
        }
        return value
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
                    LaunchOnboardingFlowView(onComplete: {
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
                _ = await appleAuthManager.verifyAppleCredentialState()
                await storeKitService.updateCustomerProductStatus()
            }
        }
    }

    private func handleIncomingNavigationURL(_ url: URL) {
        guard let request = NavigationHandoffParser.parse(url) else { return }
        pendingNavigationRequest = request

        // Never bypass authentication. If already authenticated, ContentView
        // immediately routes to the native navigation cockpit. Otherwise the
        // handoff survives sign-in/onboarding and is consumed afterward.
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
