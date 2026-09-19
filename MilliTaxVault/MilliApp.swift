import SwiftUI
import CoreLocation
import MapKit
import AuthenticationServices
import StoreKit
import LocalAuthentication

enum AppState: String {
    case splash
    case onboarding
    case setup
    case login
    case main
}

// MARK: - Navigation handoff
// Milli accepts Apple Maps directions-request URLs, Apple's geo-navigation
// contract where available, and Milli's own deep links. The handoff is retained
// through authentication and consumed by the persistent Mileage cockpit.

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
        // Registered routing apps receive a MapKit directions-request URL.
        // Decode it with MapKit rather than reverse engineering private fields.
        if MKDirections.Request.isDirectionsRequest(url) {
            let directionsRequest = MKDirections.Request(contentsOf: url)
            guard let destination = directionsRequest.destination else { return nil }
            let coordinate = destination.placemark.coordinate
            let validCoordinate = CLLocationCoordinate2DIsValid(coordinate)

            return NavigationHandoffRequest(
                destinationAddress: nil,
                destinationName: destination.name,
                latitude: validCoordinate ? coordinate.latitude : nil,
                longitude: validCoordinate ? coordinate.longitude : nil,
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

        let address = firstNonEmpty(
            items["destination"],
            items["address"],
            items["daddr"],
            items["q"],
            items["query"]
        )

        let name = firstNonEmpty(items["name"], items["label"], items["title"])
        let source = scheme == "milli"
            ? firstNonEmpty(items["source_app"], items["app"], items["provider"])
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
            sourceApp: source
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

// MARK: - Device-owner authentication
// App Lock uses Apple's LocalAuthentication framework. The app never receives,
// stores, or compares biometric data; iOS returns only the authentication result.
enum MilliDeviceAuthentication {
    enum AuthenticationError: LocalizedError {
        case unavailable(String)

        var errorDescription: String? {
            switch self {
            case .unavailable(let message):
                return message
            }
        }
    }

    static func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"

        var evaluationError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evaluationError) else {
            throw AuthenticationError.unavailable(
                evaluationError?.localizedDescription
                    ?? "Device authentication is not available on this iPhone."
            )
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
    }
}

private struct MilliPrivacyShield: View {
    let isLocked: Bool
    let isAuthenticating: Bool
    let errorMessage: String?
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 10,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                ChromeEmblemView(size: 72)

                MilliWordmark(fontSize: 30, tracking: 5.8)

                HStack(spacing: 7) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text(isLocked ? "Financial information locked" : "Financial information protected")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                if isLocked {
                    Button(action: onUnlock) {
                        HStack(spacing: 8) {
                            if isAuthenticating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(MilliColors.blackGlass)
                            } else {
                                Image(systemName: "faceid")
                            }
                            Text(isAuthenticating ? "Authenticating…" : "Unlock Milli")
                        }
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.blackGlass)
                        .frame(width: 210, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MilliColors.cyanGlow)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isAuthenticating)

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }
                }
            }
            .padding(28)
        }
        .accessibilityElement(children: .contain)
    }
}

@main
struct MilliApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var appState: AppState
    @State private var pendingNavigationRequest: NavigationHandoffRequest?
    @State private var privacyShieldVisible = false
    @State private var appLocked = false
    @State private var isAuthenticatingDevice = false
    @State private var appLockErrorMessage: String?

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage("milliBiometricUnlock") private var appLockEnabled = false

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

                if privacyShieldVisible || appLocked {
                    MilliPrivacyShield(
                        isLocked: appLocked,
                        isAuthenticating: isAuthenticatingDevice,
                        errorMessage: appLockErrorMessage,
                        onUnlock: {
                            Task { await unlockIfNeeded() }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1000)
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
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhase(newPhase)
            }
            .onChange(of: appLockEnabled) { _, enabled in
                if !enabled {
                    appLocked = false
                    appLockErrorMessage = nil
                    if scenePhase == .active {
                        privacyShieldVisible = false
                    }
                }
            }
        }
    }

    private var isAutomatedScreenshotMode: Bool {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        return processInfo.environment["MILLI_SCREENSHOT_MODE"] == "1"
            || processInfo.environment["MILLI_SCREEN"] != nil
            || processInfo.arguments.contains("-milliScreenshotMode")
        #else
        return false
        #endif
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard !isAutomatedScreenshotMode else {
            privacyShieldVisible = false
            appLocked = false
            return
        }

        switch phase {
        case .background, .inactive:
            // Always protect the app-switcher snapshot, even when optional App
            // Lock is disabled.
            privacyShieldVisible = true
            if appLockEnabled, appState == .main {
                appLocked = true
            }
        case .active:
            if appLocked, appLockEnabled, appState == .main {
                Task { await unlockIfNeeded() }
            } else {
                privacyShieldVisible = false
            }
        @unknown default:
            privacyShieldVisible = true
        }
    }

    @MainActor
    private func unlockIfNeeded() async {
        guard appLocked, appLockEnabled, !isAuthenticatingDevice else {
            if !appLockEnabled {
                appLocked = false
                privacyShieldVisible = false
            }
            return
        }

        isAuthenticatingDevice = true
        appLockErrorMessage = nil
        defer { isAuthenticatingDevice = false }

        do {
            let authenticated = try await MilliDeviceAuthentication.authenticate(
                reason: "Unlock Milli to view your financial information."
            )
            if authenticated {
                appLocked = false
                privacyShieldVisible = false
                appLockErrorMessage = nil
            }
        } catch {
            appLockErrorMessage = error.localizedDescription
            privacyShieldVisible = true
        }
    }

    private func handleIncomingNavigationURL(_ url: URL) {
        guard let request = NavigationHandoffParser.parse(url) else { return }
        pendingNavigationRequest = request

        // Never bypass authentication. If the user is already authenticated,
        // ContentView routes to Mileage immediately. Otherwise the destination
        // remains pending until the user reaches the authenticated shell.
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
        if state == .login {
            appLocked = false
            appLockErrorMessage = nil
        }
        withAnimation(.easeInOut(duration: 0.32)) {
            appState = state
        }
    }
}
