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
// Milli accepts its own deep-link contract everywhere and can also parse Apple's
// geo-navigation payload when iOS launches Milli as an eligible navigation app.
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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let scheme = (components.scheme ?? "").lowercased()
        guard scheme == "milli" || scheme == "geo-navigation" else { return nil }

        let items = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }
        )

        let address = firstNonEmpty(
            items["address"],
            items["destination"],
            items["daddr"],
            items["q"],
            items["query"]
        )

        let name = firstNonEmpty(items["name"], items["label"], items["title"])
        let source = firstNonEmpty(items["source"], items["app"], items["provider"])

        var latitude = double(items["lat"] ?? items["latitude"])
        var longitude = double(items["lon"] ?? items["lng"] ?? items["longitude"])

        if (latitude == nil || longitude == nil),
           let coordinateText = firstNonEmpty(items["ll"], items["coordinate"], items["destination_coordinate"]) {
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
            sourceApp: source
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
}

@main
struct MilliApp: App {
    @State private var appState: AppState
    @State private var pendingNavigationRequest: NavigationHandoffRequest?
    @State private var setupErrorMessage: String?
    @State private var isCompletingSetup = false

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
                        onSignIn: { profileIdentifier in
                            activateLocalBackendProfile(profileIdentifier)
                            handleReturningSignIn()
                        },
                        onCreateAccount: { profileIdentifier in
                            activateLocalBackendProfile(profileIdentifier)
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
                        finishSetupAuthoritatively()
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
            .alert(
                "Setup couldn't finish",
                isPresented: Binding(
                    get: { setupErrorMessage != nil },
                    set: { if !$0 { setupErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    setupErrorMessage = nil
                }
            } message: {
                Text(setupErrorMessage ?? "Milli couldn't save your Autopilot settings yet.")
            }
            .task {
                // Verify Apple ID credential state on app launch.
                _ = await appleAuthManager.verifyAppleCredentialState()
                // Update App Store entitlements on app launch.
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
        defaults.removeObject(forKey: "onboarding_bankAutopilotProfile")
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

    /// The current backend UUID header is an interim row namespace, not
    /// authentication. Keep it scoped per local email/password profile so a
    /// second account on the same device can never inherit another profile's
    /// linked Plaid rows. Sign in with Apple is additionally namespaced by the
    /// Apple subject inside MilliBackendClient.
    private func activateLocalBackendProfile(_ profileIdentifier: String) {
        let normalized = profileIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return }

        let defaults = UserDefaults.standard
        let profileKey = "milliBackendUserID.profile.\(normalized)"

        let profileUUID: UUID
        if let stored = defaults.string(forKey: profileKey),
           let parsed = UUID(uuidString: stored) {
            profileUUID = parsed
        } else {
            profileUUID = UUID()
            defaults.set(profileUUID.uuidString, forKey: profileKey)
        }

        defaults.set(normalized, forKey: "milliBackendActiveProfile")
        defaults.set(profileUUID.uuidString, forKey: "milliBackendUserID")
    }

    /// Do not enter the authenticated financial shell until the backend agrees
    /// that Tax Vault Autopilot is configured. This prevents local onboarding
    /// from claiming automation is enabled while server state remains false.
    private func finishSetupAuthoritatively() {
        guard !isCompletingSetup else { return }
        isCompletingSetup = true

        let reserveRate = configuredTaxReserveRate()

        Task {
            do {
                try await MilliBackendVaultSettingsClient.shared.update(
                    reserveRate: reserveRate,
                    autopilotEnabled: true
                )

                await MainActor.run {
                    hasCompletedSetup = true
                    activateSelectedTrialIfNeeded()
                    isCompletingSetup = false
                    transition(to: .main)
                }
            } catch {
                await MainActor.run {
                    isCompletingSetup = false
                    setupErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func configuredTaxReserveRate() -> Double {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "onboarding_taxProfile"),
              let profile = try? JSONDecoder().decode(TaxProfile.self, from: data)
        else {
            return 0.23
        }

        let income = profile.annualIncomeAmount ?? 55_000
        let percent: Double
        switch income {
        case ..<30_000: percent = 20
        case ..<60_000: percent = 23
        case ..<100_000: percent = 27
        default: percent = 30
        }
        return percent / 100
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
