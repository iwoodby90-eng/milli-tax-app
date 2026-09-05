import SwiftUI
import MapKit
import CoreLocation
import AVFoundation

// MARK: - ContentView
// Native SwiftUI shell: screen router + persistent sculpted Milli navigation + contextual Milli AI companion.

struct ContentView: View {
    @Binding private var pendingNavigationRequest: NavigationHandoffRequest?
    var onLogout: () -> Void = {}

    @State private var selectedTab: MilliTab
    @State private var activeScreen: ActiveScreen

    init(
        pendingNavigationRequest: Binding<NavigationHandoffRequest?> = .constant(nil),
        onLogout: @escaping () -> Void = {}
    ) {
        _pendingNavigationRequest = pendingNavigationRequest
        self.onLogout = onLogout

        let debugScreen = Self.requestedDebugScreen()
        let initialScreen: ActiveScreen = pendingNavigationRequest.wrappedValue != nil
            ? .activity
            : (debugScreen ?? .home)

        _activeScreen = State(initialValue: initialScreen)
        _selectedTab = State(initialValue: initialScreen.debugTab)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MilliColors.background.ignoresSafeArea()

            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            if shouldShowAIOrb {
                HStack {
                    Spacer()
                    MilliAIOrb {
                        navigateTo(.milliAI)
                    }
                    .padding(.trailing, 8)
                    .padding(.bottom, aiBottomClearance)
                }
                .allowsHitTesting(true)
            }

            if pendingNavigationRequest == nil {
                MilliNavBar(selectedTab: $selectedTab) {
                    selectedTab = .home
                    navigateTo(.home)
                }
                .onChange(of: selectedTab) { _, newTab in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        switch newTab {
                        case .home:
                            activeScreen = .home
                        case .vault:
                            activeScreen = .vault
                        case .activity:
                            activeScreen = .activity
                        case .wealth:
                            activeScreen = .wealthOverview
                        case .cockpit:
                            activeScreen = .cockpit
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            routePendingNavigationRequestIfNeeded()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            routePendingNavigationRequestIfNeeded()
        }
    }

    private var shouldShowAIOrb: Bool {
        activeScreen != .milliAI && pendingNavigationRequest == nil
    }

    private var aiBottomClearance: CGFloat {
        switch activeScreen {
        case .expenses, .plans:
            return MilliSpacing.bottomNavHeight + 52
        default:
            return MilliSpacing.bottomNavHeight + 2
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch activeScreen {
        case .home:
            HomeView(navigate: navigateTo)
        case .vault:
            PayoutsView()
        case .activity:
            MileageNavigationHost(
                pendingNavigationRequest: $pendingNavigationRequest,
                onBack: { navigateTo(.home) }
            )
        case .milliCents:
            MilliCentsView(onBack: { navigateTo(.home) })
        case .autopilot:
            AutopilotSettingsView(onBack: { navigateTo(.cockpit) })
        case .expenses:
            ExpensesView(onBack: { navigateTo(.cockpit) })
        case .accounts:
            AccountsView(onBack: { navigateTo(.cockpit) })
        case .savings:
            SavingsView(onBack: { navigateTo(.wealthOverview) })
        case .documents:
            DocumentsView(onBack: { navigateTo(.cockpit) })
        case .plans:
            SubscriptionView(onBack: { navigateTo(.cockpit) })
        case .taxVault:
            TaxVaultView(onBack: { navigateTo(.home) })
        case .taxReadyScore:
            TaxReadyScoreView(onBack: { navigateTo(.home) })
        case .quarterlyTaxes:
            QuarterlyTaxesView(onBack: { navigateTo(.home) })
        case .investing:
            InvestingView(onBack: { navigateTo(.wealthOverview) })
        case .retirement:
            RetirementView(onBack: { navigateTo(.wealthOverview) })
        case .wealthOverview:
            WealthOverviewView(
                onBack: { navigateTo(.home) },
                navigate: navigateTo
            )
        case .treeOfLife:
            TreeOfLifeView(onBack: { navigateTo(.wealthOverview) })
        case .milliAI:
            MilliAIView(
                onBack: { navigateTo(.home) },
                navigate: navigateTo
            )
        case .reports:
            ReportsView(onBack: { navigateTo(.cockpit) })
        case .cockpit:
            MoreMenuView(navigate: navigateTo, onLogout: onLogout)
        }
    }

    private func routePendingNavigationRequestIfNeeded() {
        guard pendingNavigationRequest != nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            activeScreen = .activity
            selectedTab = .activity
        }
    }

    private func navigateTo(_ screen: ActiveScreen) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeScreen = screen
            if let primaryTab = screen.primaryTab {
                selectedTab = primaryTab
            }
        }
    }

    private static func requestedDebugScreen() -> ActiveScreen? {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo

        if let rawValue = processInfo.environment["MILLI_SCREEN"],
           let screen = ActiveScreen(rawValue: rawValue) {
            return screen
        }

        let arguments = processInfo.arguments
        guard arguments.contains("-milliScreenshotMode"),
              let flagIndex = arguments.firstIndex(of: "-milliScreen"),
              arguments.indices.contains(flagIndex + 1)
        else {
            return nil
        }

        return ActiveScreen(rawValue: arguments[flagIndex + 1])
        #else
        return nil
        #endif
    }
}

enum ActiveScreen: String, CaseIterable {
    case home
    case vault
    case activity
    case milliCents
    case autopilot
    case expenses
    case accounts
    case savings
    case documents
    case plans
    case taxVault
    case taxReadyScore
    case quarterlyTaxes
    case investing
    case retirement
    case wealthOverview
    case treeOfLife
    case milliAI
    case reports
    case cockpit

    var primaryTab: MilliTab? {
        switch self {
        case .home:
            return .home
        case .vault:
            return .vault
        case .activity:
            return .activity
        case .wealthOverview:
            return .wealth
        case .cockpit:
            return .cockpit
        default:
            return nil
        }
    }

    var debugTab: MilliTab {
        switch self {
        case .investing, .retirement, .savings, .treeOfLife:
            return .wealth
        default:
            return primaryTab ?? .cockpit
        }
    }
}

// MARK: - Apple-native live navigation host

private struct MileageNavigationHost: View {
    @Binding var pendingNavigationRequest: NavigationHandoffRequest?
    let onBack: () -> Void

    var body: some View {
        if let request = pendingNavigationRequest {
            MilliLiveNavigationView(request: request) {
                pendingNavigationRequest = nil
            }
            .id(request.id)
        } else {
            MileageView(onBack: onBack)
        }
    }
}

private struct MilliNavigationStep: Identifiable, Equatable {
    let id: Int
    let instruction: String
    let distanceMeters: CLLocationDistance
    let coordinate: CLLocationCoordinate2D?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.instruction == rhs.instruction && lhs.distanceMeters == rhs.distanceMeters
    }
}

@MainActor
private final class MilliNavigationVoice: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenInstruction: String?

    func speak(_ instruction: String) {
        let trimmed = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastSpokenInstruction else { return }
        lastSpokenInstruction = trimmed

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        lastSpokenInstruction = nil
    }
}

private struct MilliLiveNavigationView: View {
    let request: NavigationHandoffRequest
    let onExit: () -> Void

    @StateObject private var locationManager = LocationManager()
    @StateObject private var mileageLog = MileageLogStore()
    @StateObject private var voiceGuidance = MilliNavigationVoice()

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var destinationItem: MKMapItem?
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var navigationSteps: [MilliNavigationStep] = []
    @State private var currentStepIndex = 0
    @State private var routeDistanceMeters: CLLocationDistance = 0
    @State private var routeETA: TimeInterval = 0
    @State private var trackedMetersAtLastRoute: CLLocationDistance = 0
    @State private var isCalculatingRoute = false
    @State private var routeError: String?
    @State private var lastRerouteAt: Date = .distantPast
    @State private var hasStartedSession = false

    private var destinationTitle: String {
        destinationItem?.name
            ?? request.destinationName
            ?? request.destinationAddress
            ?? "Destination"
    }

    private var currentInstruction: String {
        guard navigationSteps.indices.contains(currentStepIndex) else {
            return routeCoordinates.isEmpty ? "Building your Apple Maps route…" : "Continue to destination"
        }
        return navigationSteps[currentStepIndex].instruction
    }

    private var distanceSinceLastRoute: CLLocationDistance {
        max(locationManager.distanceMeters - trackedMetersAtLastRoute, 0)
    }

    private var remainingDistanceMeters: CLLocationDistance {
        max(routeDistanceMeters - distanceSinceLastRoute, 0)
    }

    private var remainingETA: TimeInterval {
        guard routeDistanceMeters > 1 else { return 0 }
        return max(routeETA * (remainingDistanceMeters / routeDistanceMeters), 0)
    }

    var body: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            Map(position: $mapPosition, interactionModes: [.pan, .zoom, .rotate, .pitch]) {
                if routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(MilliColors.cyanGlow.opacity(0.22), lineWidth: 11)
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(MilliColors.cyanGlow, lineWidth: 5)
                }

                if let destinationItem {
                    Annotation("Destination", coordinate: destinationItem.placemark.coordinate) {
                        ZStack {
                            Circle()
                                .fill(MilliColors.blackGlass.opacity(0.94))
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(MilliColors.positive, lineWidth: 2))
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(MilliColors.positive)
                        }
                        .shadow(color: MilliColors.positive.opacity(0.35), radius: 8)
                    }
                }

                if let location = locationManager.lastLocation {
                    Annotation("You", coordinate: location.coordinate) {
                        ZStack {
                            Circle()
                                .fill(MilliColors.cyanGlow.opacity(0.16))
                                .frame(width: 46, height: 46)
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(MilliColors.cyanGlow)
                                .rotationEffect(.degrees(location.course >= 0 ? location.course : 0))
                                .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 7)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.46), .clear, Color.black.opacity(0.58)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                navigationInstructionCard
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Spacer()

                navigationStatusCard
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            beginNavigationSession()
        }
        .onDisappear {
            voiceGuidance.stop()
        }
        .onChange(of: locationManager.lastLocation?.timestamp) { _, _ in
            guard let location = locationManager.lastLocation else { return }
            handleLocationUpdate(location)
        }
        .alert("Navigation", isPresented: Binding(
            get: { routeError != nil || locationManager.errorMessage != nil },
            set: { showing in
                if !showing {
                    routeError = nil
                    locationManager.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                routeError = nil
                locationManager.errorMessage = nil
            }
        } message: {
            Text(routeError ?? locationManager.errorMessage ?? "")
        }
    }

    private var navigationInstructionCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: maneuverSymbol)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(currentInstruction)
                    .font(.custom("Sora-SemiBold", size: 17, relativeTo: .headline))
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                HStack(spacing: 6) {
                    if let source = request.sourceApp {
                        Text(source.uppercased())
                            .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                            .tracking(0.7)
                            .foregroundStyle(MilliColors.cyanGlow)
                    } else {
                        Text("APPLE MAPKIT")
                            .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                            .tracking(0.7)
                            .foregroundStyle(MilliColors.cyanGlow)
                    }

                    Text("•")
                        .foregroundStyle(MilliColors.textTertiary)

                    Text(destinationTitle)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if isCalculatingRoute {
                ProgressView()
                    .tint(MilliColors.cyanGlow)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MilliColors.blackGlass.opacity(0.90))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.20), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.42), radius: 18, y: 8)
        )
    }

    private var navigationStatusCard: some View {
        VStack(spacing: 11) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                metric(value: formattedDistance(remainingDistanceMeters), label: "Remaining")
                Divider()
                    .frame(height: 30)
                    .overlay(Color.white.opacity(0.10))
                metric(value: formattedETA(remainingETA), label: "ETA")
                Divider()
                    .frame(height: 30)
                    .overlay(Color.white.opacity(0.10))
                metric(
                    value: locationManager.distanceMiles.formatted(.number.precision(.fractionLength(1))),
                    label: "Miles tracked"
                )
            }

            HStack(spacing: 9) {
                Button {
                    recenterOnDriver()
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 46, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.055))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    finishNavigation(saveTrip: true)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "checkered.flag")
                        Text("END & SAVE TRIP")
                    }
                    .font(.custom("Sora-SemiBold", size: 12, relativeTo: .caption))
                    .foregroundStyle(MilliColors.blackGlass)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MilliColors.cyanGlow)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    finishNavigation(saveTrip: false)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 46, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.055))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel navigation")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MilliColors.blackGlass.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.50), radius: 20, y: 10)
        )
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.custom("Sora-SemiBold", size: 15, relativeTo: .body))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var maneuverSymbol: String {
        let instruction = currentInstruction.lowercased()
        if instruction.contains("left") { return "arrow.turn.up.left" }
        if instruction.contains("right") { return "arrow.turn.up.right" }
        if instruction.contains("u-turn") || instruction.contains("u turn") { return "arrow.uturn.backward" }
        if instruction.contains("merge") { return "arrow.merge" }
        if instruction.contains("exit") { return "arrow.up.right" }
        if instruction.contains("arrive") || instruction.contains("destination") { return "flag.checkered" }
        return "arrow.up"
    }

    private func beginNavigationSession() {
        guard !hasStartedSession else { return }
        hasStartedSession = true

        // Choosing Milli as the navigation target is an explicit navigation
        // action, so starting mileage capture here preserves the same user intent
        // as tapping NAVIGATE inside the app.
        locationManager.startTracking()

        if locationManager.canTrackLocation {
            locationManager.refreshCurrentLocation()
        }
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        if routeCoordinates.isEmpty {
            guard !isCalculatingRoute else { return }
            Task { await calculateRoute(from: location.coordinate, isReroute: false) }
            return
        }

        advanceManeuverIfNeeded(from: location)
        recenterOnDriver()

        if shouldReroute(from: location),
           Date().timeIntervalSince(lastRerouteAt) > 20,
           !isCalculatingRoute {
            lastRerouteAt = Date()
            Task { await calculateRoute(from: location.coordinate, isReroute: true) }
        }
    }

    private func calculateRoute(from origin: CLLocationCoordinate2D, isReroute: Bool) async {
        guard !isCalculatingRoute else { return }
        isCalculatingRoute = true
        defer { isCalculatingRoute = false }

        do {
            let destination = try await resolvedDestination(near: origin)

            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            directionsRequest.destination = destination
            directionsRequest.transportType = .automobile
            directionsRequest.requestsAlternateRoutes = false

            let response = try await MKDirections(request: directionsRequest).calculate()
            guard let route = response.routes.first else {
                routeError = "Apple Maps couldn't produce a driving route to that destination."
                return
            }

            destinationItem = destination
            routeCoordinates = coordinates(from: route.polyline)
            routeDistanceMeters = route.distance
            routeETA = route.expectedTravelTime
            trackedMetersAtLastRoute = locationManager.distanceMeters
            currentStepIndex = 0
            navigationSteps = route.steps.enumerated().compactMap { index, step in
                let instruction = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !instruction.isEmpty else { return nil }
                return MilliNavigationStep(
                    id: index,
                    instruction: instruction,
                    distanceMeters: step.distance,
                    coordinate: coordinates(from: step.polyline).last
                )
            }

            if !isReroute {
                showEntireRoute()
            } else {
                recenterOnDriver()
                voiceGuidance.speak("Route updated. \(currentInstruction)")
            }

            if let first = navigationSteps.first, !isReroute {
                voiceGuidance.speak(first.instruction)
            }
        } catch {
            routeError = "Milli couldn't load the Apple Maps route. Check the destination and your connection, then try again."
        }
    }

    private func resolvedDestination(near origin: CLLocationCoordinate2D) async throws -> MKMapItem {
        if let coordinate = request.coordinate {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.name = request.destinationName ?? request.destinationAddress
            return item
        }

        let query = request.destinationAddress ?? request.destinationName ?? ""
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MilliLiveNavigationError.missingDestination
        }

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = MKCoordinateRegion(
            center: origin,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )

        let response = try await MKLocalSearch(request: searchRequest).start()
        guard let item = response.mapItems.first else {
            throw MilliLiveNavigationError.destinationNotFound
        }
        return item
    }

    private func advanceManeuverIfNeeded(from location: CLLocation) {
        guard navigationSteps.indices.contains(currentStepIndex),
              let coordinate = navigationSteps[currentStepIndex].coordinate else { return }

        let maneuverLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = location.distance(from: maneuverLocation)

        guard distance <= 45 else { return }

        let nextIndex = min(currentStepIndex + 1, navigationSteps.count)
        guard nextIndex != currentStepIndex else { return }
        currentStepIndex = nextIndex

        if navigationSteps.indices.contains(currentStepIndex) {
            voiceGuidance.speak(navigationSteps[currentStepIndex].instruction)
        } else {
            voiceGuidance.speak("You have arrived at your destination.")
        }
    }

    private func shouldReroute(from location: CLLocation) -> Bool {
        guard routeCoordinates.count >= 2 else { return false }

        let driverPoint = MKMapPoint(location.coordinate)
        var nearestDistance = CLLocationDistance.greatestFiniteMagnitude

        for index in 0..<(routeCoordinates.count - 1) {
            let start = MKMapPoint(routeCoordinates[index])
            let end = MKMapPoint(routeCoordinates[index + 1])
            nearestDistance = min(
                nearestDistance,
                distanceFrom(driverPoint, toSegmentStart: start, end: end)
            )

            if nearestDistance <= 160 {
                return false
            }
        }

        return nearestDistance > 160
    }

    private func distanceFrom(
        _ point: MKMapPoint,
        toSegmentStart start: MKMapPoint,
        end: MKMapPoint
    ) -> CLLocationDistance {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else {
            return point.distance(to: start)
        }

        let projection = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        let t = max(0.0, min(1.0, projection))
        let nearestPoint = MKMapPoint(
            x: start.x + t * dx,
            y: start.y + t * dy
        )
        return point.distance(to: nearestPoint)
    }

    private func recenterOnDriver() {
        guard let location = locationManager.lastLocation else { return }
        let heading = location.course >= 0 ? location.course : 0

        withAnimation(.easeInOut(duration: 0.35)) {
            mapPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 850,
                    heading: heading,
                    pitch: 52
                )
            )
        }
    }

    private func showEntireRoute() {
        guard !routeCoordinates.isEmpty else { return }

        let latitudes = routeCoordinates.map(\.latitude)
        let longitudes = routeCoordinates.map(\.longitude)
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.55, 0.012),
            longitudeDelta: max((maxLon - minLon) * 1.55, 0.012)
        )

        withAnimation(.easeInOut(duration: 0.45)) {
            mapPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    private func finishNavigation(saveTrip: Bool) {
        let endedAt = Date()
        let startedAt = locationManager.tripStartedAt ?? endedAt
        let miles = locationManager.distanceMiles
        let recordedRoute = locationManager.routeCoordinates
        let destinationCoordinate = destinationItem?.placemark.coordinate ?? request.coordinate

        locationManager.stopTracking()
        voiceGuidance.stop()

        if saveTrip, miles > 0.001 {
            let record = MileageTripRecord(
                id: UUID(),
                source: .navigation,
                platform: nil,
                businessPurpose: "Navigation to \(destinationTitle)",
                startedAt: startedAt,
                endedAt: endedAt,
                distanceMiles: miles,
                deductionRate: MileageRate.businessRate(for: startedAt),
                startAddress: nil,
                endAddress: request.destinationAddress ?? destinationTitle,
                startCoordinate: recordedRoute.first.map(MileageCoordinate.init),
                endCoordinate: destinationCoordinate.map(MileageCoordinate.init)
                    ?? recordedRoute.last.map(MileageCoordinate.init),
                routePoints: recordedRoute.map(MileageCoordinate.init),
                navigationExternalID: request.sourceApp,
                syncState: .pending
            )
            mileageLog.add(record)
        }

        locationManager.resetCurrentTrip()
        onExit()
    }

    private func coordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        let points = polyline.points()
        return (0..<polyline.pointCount).map { points[$0].coordinate }
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1_609.344
        if miles < 0.1 {
            return "\(max(Int(meters.rounded()), 0)) m"
        }
        return "\(miles.formatted(.number.precision(.fractionLength(miles < 10 ? 1 : 0)))) mi"
    }

    private func formattedETA(_ interval: TimeInterval) -> String {
        let minutes = max(Int((interval / 60).rounded()), 0)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) min"
    }
}

private enum MilliLiveNavigationError: Error {
    case missingDestination
    case destinationNotFound
}
