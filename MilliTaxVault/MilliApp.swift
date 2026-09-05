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
// Milli accepts its own deep-link contract everywhere, Apple's routing-app
// directions request payloads, and geo-navigation URLs on platforms/regions
// where Apple exposes the default-navigation handoff.
// A handoff is retained through sign-in so the destination is already loaded
// when the authenticated user reaches Mileage.

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
        // Native Maps routing-app requests use Apple's MKDirectionsRequest
        // payload. Decode those first instead of attempting to reverse engineer
        // the URL query contract.
        if MKDirections.Request.isDirectionsRequest(url) {
            let directionsRequest = MKDirections.Request(contentsOf: url)
            if let destination = directionsRequest.destination {
                let coordinate = destination.placemark.coordinate
                let placemarkAddress = [
                    destination.placemark.subThoroughfare,
                    destination.placemark.thoroughfare,
                    destination.placemark.locality,
                    destination.placemark.administrativeArea,
                    destination.placemark.postalCode
                ]
                .compactMap { $0 }
                .joined(separator: " ")

                return NavigationHandoffRequest(
                    destinationAddress: placemarkAddress.isEmpty ? nil : placemarkAddress,
                    destinationName: destination.name,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    sourceApp: "Apple Maps"
                )
            }
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let scheme = (components.scheme ?? "").lowercased()
        guard scheme == "milli" || scheme == "geo-navigation" else { return nil }

        let items = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }
        )

        // Apple's geo-navigation /directions contract passes destination as an
        // address, place-name, or a comma-separated coordinate pair.
        let rawDestination = firstNonEmpty(
            items["destination"],
            items["address"],
            items["daddr"],
            items["q"],
            items["query"]
        )

        let name = firstNonEmpty(items["name"], items["label"], items["title"])
        let source = firstNonEmpty(items["source"], items["app"], items["provider"])

        var latitude = double(items["lat"] ?? items["latitude"])
        var longitude = double(items["lon"] ?? items["lng"] ?? items["longitude"])

        if latitude == nil || longitude == nil {
            if let coordinateText = firstNonEmpty(
                items["coordinate"],
                items["ll"],
                items["destination_coordinate"],
                coordinatePairIfPresent(rawDestination)
            ) {
                let parts = coordinateText
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if parts.count >= 2 {
                    latitude = Double(parts[0])
                    longitude = Double(parts[1])
                }
            }
        }

        let address: String? = coordinatePairIfPresent(rawDestination) == nil
            ? rawDestination
            : nil

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
            sourceApp: source ?? (scheme == "geo-navigation" ? "Default Navigation" : nil)
        )
    }

    private static func coordinatePairIfPresent(_ value: String?) -> String? {
        guard let value else { return nil }
        let parts = value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2,
              let latitude = Double(parts[0]),
              let longitude = Double(parts[1]),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude)
        else {
            return nil
        }
        return "\(latitude),\(longitude)"
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
        // ContentView immediately routes to Mileage/live navigation. Otherwise
        // the request waits through sign-in/onboarding and is consumed once the
        // main shell appears.
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
