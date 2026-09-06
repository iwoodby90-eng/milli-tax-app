import SwiftUI
import MapKit
import CoreLocation

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
        .preferredColorScheme(.dark)
        .onAppear {
            routePendingNavigationRequestIfNeeded()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            routePendingNavigationRequestIfNeeded()
        }
    }

    private var shouldShowAIOrb: Bool {
        activeScreen != .milliAI && activeScreen != .activity
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
            MilliActivityCockpit(
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

// MARK: - Activity / navigation cockpit

private struct MilliActivityCockpit: View {
    @Binding var pendingNavigationRequest: NavigationHandoffRequest?
    let onBack: () -> Void

    @State private var showMileageTools = false

    var body: some View {
        if showMileageTools {
            MileageView(onBack: { showMileageTools = false })
        } else {
            MilliNativeNavigationView(
                pendingNavigationRequest: $pendingNavigationRequest,
                onBack: onBack,
                openMileageTools: { showMileageTools = true }
            )
        }
    }
}

private struct MilliNavigationStep: Identifiable, Equatable {
    let id = UUID()
    let instruction: String
    let notice: String?
    let distanceMeters: CLLocationDistance
    let coordinates: [CLLocationCoordinate2D]

    static func == (lhs: MilliNavigationStep, rhs: MilliNavigationStep) -> Bool {
        lhs.id == rhs.id
    }

    var endpoint: CLLocationCoordinate2D? {
        coordinates.last
    }
}

private struct MilliNativeNavigationView: View {
    @Binding var pendingNavigationRequest: NavigationHandoffRequest?
    let onBack: () -> Void
    let openMileageTools: () -> Void

    @StateObject private var locationManager = LocationManager()
    @StateObject private var mileageLog = MileageLogStore()

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
            span: MKCoordinateSpan(latitudeDelta: 42, longitudeDelta: 58)
        )
    )

    @State private var destinationText = ""
    @State private var destinationItem: MKMapItem?
    @State private var plannedRouteCoordinates: [CLLocationCoordinate2D] = []
    @State private var navigationSteps: [MilliNavigationStep] = []
    @State private var currentStepIndex = 0
    @State private var plannedDistanceMeters: CLLocationDistance = 0
    @State private var plannedETA: TimeInterval = 0
    @State private var navigationStartedAt: Date?
    @State private var isBuildingRoute = false
    @State private var isNavigating = false
    @State private var routeMessage: String?
    @State private var awaitingHandoffRoute = false
    @State private var lastRerouteAt = Date.distantPast

    private var currentStep: MilliNavigationStep? {
        guard navigationSteps.indices.contains(currentStepIndex) else { return nil }
        return navigationSteps[currentStepIndex]
    }

    private var remainingDistanceMeters: CLLocationDistance {
        max(plannedDistanceMeters - locationManager.distanceMeters, 0)
    }

    private var remainingETA: TimeInterval {
        guard isNavigating, let navigationStartedAt else { return plannedETA }
        return max(plannedETA - Date().timeIntervalSince(navigationStartedAt), 0)
    }

    private var todayMiles: Double {
        mileageLog.totalMiles(on: Date()) + (locationManager.isTracking ? locationManager.distanceMiles : 0)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header

                if isNavigating {
                    maneuverCard
                }

                destinationCard
                navigationMap
                metricsCard
                primaryAction
                mileageSummary
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .onAppear {
            if locationManager.canTrackLocation {
                locationManager.refreshCurrentLocation()
            } else {
                locationManager.requestPermission()
            }
            consumePendingNavigationRequest()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            consumePendingNavigationRequest()
        }
        .onChange(of: locationManager.lastLocation?.timestamp) { _, _ in
            guard let location = locationManager.lastLocation else { return }

            if awaitingHandoffRoute, destinationItem != nil, plannedRouteCoordinates.isEmpty {
                Task { await calculateRoute(to: destinationItem!) }
            }

            if isNavigating {
                updateNavigationProgress(using: location)
            } else if plannedRouteCoordinates.isEmpty {
                recenter(on: location.coordinate, animated: true)
            }
        }
        .onChange(of: locationManager.routeCoordinates.count) { _, _ in
            guard isNavigating else { return }
            updateNavigationCamera()
        }
        .alert(
            "Milli Navigation",
            isPresented: Binding(
                get: { routeMessage != nil || locationManager.errorMessage != nil },
                set: { presented in
                    if !presented {
                        routeMessage = nil
                        locationManager.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                routeMessage = nil
                locationManager.errorMessage = nil
            }
        } message: {
            Text(routeMessage ?? locationManager.errorMessage ?? "")
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: openMileageTools) {
                    Image(systemName: "road.lanes")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open mileage tools")
            }

            VStack(spacing: 1) {
                Text("MILLI")
                    .font(.custom("Sora-Bold", size: 17, relativeTo: .headline))
                    .tracking(1.3)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(isNavigating ? "LIVE NAVIGATION" : "NAVIGATION + MILEAGE")
                    .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                    .tracking(1.2)
                    .foregroundStyle(isNavigating ? MilliColors.positive : MilliColors.cyanGlow)
            }
        }
        .frame(height: 42)
    }

    private var maneuverCard: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.10))
                    .frame(width: 54, height: 54)
                Image(systemName: maneuverSymbol(for: currentStep?.instruction))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(currentStep?.instruction ?? "Continue on route")
                    .font(.custom("Sora-SemiBold", size: 17, relativeTo: .headline))
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(2)
                if let notice = currentStep?.notice, !notice.isEmpty {
                    Text(notice)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.warning)
                        .lineLimit(1)
                } else {
                    Text(stepDistanceLabel)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }

            Spacer(minLength: 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.32), lineWidth: 0.9)
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.12), radius: 14)
        )
    }

    private var destinationCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(isNavigating ? "DESTINATION" : "WHERE TO?")
                    .sectionHeaderStyle()
                Spacer()
                if isBuildingRoute {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MilliColors.cyanGlow)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)

                TextField("Delivery address or place", text: $destinationText)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .disabled(isNavigating)
                    .onSubmit {
                        Task { await searchAndBuildRoute() }
                    }

                if !destinationText.isEmpty && !isNavigating {
                    Button {
                        clearRoute()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.035))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                    }
            )

            if !isNavigating {
                Button {
                    Task { await searchAndBuildRoute() }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text(plannedRouteCoordinates.isEmpty ? "BUILD ROUTE" : "REBUILD ROUTE")
                    }
                    .font(.custom("Sora-SemiBold", size: 11, relativeTo: .caption))
                    .tracking(0.5)
                    .foregroundStyle(destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MilliColors.textTertiary : MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
                .disabled(destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBuildingRoute)
            }
        }
        .padding(12)
        .background(MilliCardBackground(showGlow: false))
    }

    private var navigationMap: some View {
        Map(position: $mapPosition, interactionModes: isNavigating ? [.zoom, .pan] : .all) {
            if plannedRouteCoordinates.count >= 2 {
                MapPolyline(coordinates: plannedRouteCoordinates)
                    .stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 11)
                MapPolyline(coordinates: plannedRouteCoordinates)
                    .stroke(MilliColors.cyanGlow, lineWidth: 4.5)
            }

            if locationManager.routeCoordinates.count >= 2 {
                MapPolyline(coordinates: locationManager.routeCoordinates)
                    .stroke(MilliColors.positive.opacity(0.86), lineWidth: 3)
            }

            if let destinationItem {
                Annotation("Destination", coordinate: destinationItem.placemark.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.88))
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(MilliColors.positive, lineWidth: 2))
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MilliColors.positive)
                    }
                    .shadow(color: MilliColors.positive.opacity(0.34), radius: 7)
                }
            }

            if let current = locationManager.lastLocation?.coordinate {
                Annotation("Current location", coordinate: current) {
                    ZStack {
                        Circle()
                            .fill(MilliColors.cyanGlow.opacity(0.16))
                            .frame(width: 40, height: 40)
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MilliColors.cyanGlow)
                            .rotationEffect(.degrees(locationManager.lastLocation?.course ?? 0))
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.45), radius: 8)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .frame(height: isNavigating ? 365 : 300)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 5) {
                Circle()
                    .fill(locationManager.lastLocation == nil ? MilliColors.warning : MilliColors.positive)
                    .frame(width: 6, height: 6)
                Text(locationManager.lastLocation == nil ? "GPS ACQUIRING" : "GPS LOCKED")
                    .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                    .tracking(0.6)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.70)))
            .padding(9)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                if isNavigating {
                    updateNavigationCamera()
                } else if let coordinate = locationManager.lastLocation?.coordinate {
                    recenter(on: coordinate, animated: true)
                }
            } label: {
                Image(systemName: "scope")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.black.opacity(0.74)))
            }
            .buttonStyle(.plain)
            .padding(9)
        }
    }

    private var metricsCard: some View {
        HStack(spacing: 0) {
            metricColumn(
                value: distanceLabel,
                label: isNavigating ? "REMAINING" : "ROUTE"
            )
            metricDivider
            metricColumn(value: etaLabel, label: "ETA")
            metricDivider
            metricColumn(
                value: locationManager.distanceMiles.formatted(.number.precision(.fractionLength(1))),
                label: "MILES LOGGED"
            )
        }
        .padding(.vertical, 12)
        .background(MilliCardBackground(showGlow: true))
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("Sora-SemiBold", size: 16, relativeTo: .headline))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(width: 1, height: 34)
    }

    private var primaryAction: some View {
        Button {
            if isNavigating {
                endNavigationAndSave()
            } else {
                startNavigation()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isNavigating ? "stop.fill" : "location.north.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(isNavigating ? "END TRIP + SAVE MILEAGE" : "START MILLI NAVIGATION")
                    .font(.custom("Sora-SemiBold", size: 12, relativeTo: .caption))
                    .tracking(0.55)
            }
            .foregroundStyle(isNavigating ? MilliColors.textPrimary : MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isNavigating ? Color.white.opacity(0.055) : MilliColors.cyanGlow)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isNavigating ? MilliColors.cyanGlow.opacity(0.28) : MilliColors.cyanGlow,
                                lineWidth: 0.8
                            )
                    }
                    .shadow(color: isNavigating ? .clear : MilliColors.cyanGlow.opacity(0.20), radius: 8)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isNavigating && plannedRouteCoordinates.isEmpty)
        .opacity(!isNavigating && plannedRouteCoordinates.isEmpty ? 0.48 : 1)
    }

    private var mileageSummary: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: "car.side.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Today: \(todayMiles.formatted(.number.precision(.fractionLength(2)))) business mi")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Estimated deduction: \((todayMiles * MileageRate.businessRate(for: Date())).formatted(.currency(code: "USD")))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.positive)
            }

            Spacer()

            Button("TOOLS", action: openMileageTools)
                .font(.custom("Sora-SemiBold", size: 9, relativeTo: .caption2))
                .foregroundStyle(MilliColors.cyanGlow)
                .buttonStyle(.plain)
        }
        .padding(11)
        .background(MilliCardBackground(showGlow: false))
    }

    private var distanceLabel: String {
        let meters = isNavigating ? remainingDistanceMeters : plannedDistanceMeters
        guard meters > 0 else { return "—" }
        return "\((meters / 1_609.344).formatted(.number.precision(.fractionLength(1)))) mi"
    }

    private var etaLabel: String {
        let interval = remainingETA
        guard interval > 0 else { return "—" }
        let arrival = Date().addingTimeInterval(interval)
        return arrival.formatted(date: .omitted, time: .shortened)
    }

    private var stepDistanceLabel: String {
        guard let distance = currentStep?.distanceMeters, distance > 0 else { return "Follow the highlighted route" }
        if distance >= 1_609.344 {
            return "in \((distance / 1_609.344).formatted(.number.precision(.fractionLength(1)))) mi"
        }
        if distance >= 304.8 {
            return "in \(Int((distance / 160.9344).rounded()) * 528) ft"
        }
        return "in \(Int((distance * 3.28084 / 50).rounded()) * 50) ft"
    }

    @MainActor
    private func consumePendingNavigationRequest() {
        guard let handoff = pendingNavigationRequest else { return }
        pendingNavigationRequest = nil
        awaitingHandoffRoute = true

        if let coordinate = handoff.coordinate {
            let placemark = MKPlacemark(coordinate: coordinate)
            let item = MKMapItem(placemark: placemark)
            item.name = handoff.destinationName ?? handoff.destinationAddress ?? "Destination"
            destinationItem = item
            destinationText = item.name ?? "Destination"

            if locationManager.lastLocation != nil {
                Task { await calculateRoute(to: item) }
            } else {
                locationManager.requestPermission()
                locationManager.refreshCurrentLocation()
            }
        } else if let address = handoff.destinationAddress ?? handoff.destinationName {
            destinationText = address
            if locationManager.lastLocation != nil {
                Task { await searchAndBuildRoute() }
            } else {
                locationManager.requestPermission()
                locationManager.refreshCurrentLocation()
            }
        }
    }

    @MainActor
    private func searchAndBuildRoute() async {
        let query = destinationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard let origin = locationManager.lastLocation?.coordinate else {
            if locationManager.canTrackLocation {
                locationManager.refreshCurrentLocation()
                routeMessage = "Milli is acquiring your current location. Try again once GPS locks."
            } else {
                locationManager.requestPermission()
                routeMessage = "Allow location access so Milli can build a route from your current position."
            }
            return
        }

        isBuildingRoute = true
        defer { isBuildingRoute = false }

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: origin,
                span: MKCoordinateSpan(latitudeDelta: 1.2, longitudeDelta: 1.2)
            )
            let response = try await MKLocalSearch(request: request).start()
            guard let destination = response.mapItems.first else {
                routeMessage = "Milli couldn't find that destination. Try a fuller address or place name."
                return
            }

            destinationItem = destination
            await calculateRoute(to: destination)
        } catch {
            routeMessage = "Milli couldn't search that destination right now. Check the address and connection, then try again."
        }
    }

    @MainActor
    private func calculateRoute(to destination: MKMapItem) async {
        guard let origin = locationManager.lastLocation?.coordinate else {
            awaitingHandoffRoute = true
            return
        }

        isBuildingRoute = true
        defer {
            isBuildingRoute = false
            awaitingHandoffRoute = false
        }

        do {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            request.destination = destination
            request.transportType = .automobile
            request.requestsAlternateRoutes = false
            request.departureDate = Date()

            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else {
                routeMessage = "No driving route was available for that destination."
                return
            }

            plannedRouteCoordinates = route.polyline.milliNavigationCoordinates
            navigationSteps = route.steps.compactMap { step in
                let instruction = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !instruction.isEmpty else { return nil }
                let notice = step.notice?.trimmingCharacters(in: .whitespacesAndNewlines)
                return MilliNavigationStep(
                    instruction: instruction,
                    notice: notice?.isEmpty == false ? notice : nil,
                    distanceMeters: step.distance,
                    coordinates: step.polyline.milliNavigationCoordinates
                )
            }
            currentStepIndex = 0
            plannedDistanceMeters = route.distance
            plannedETA = route.expectedTravelTime
            destinationItem = destination
            destinationText = destination.name ?? destinationText
            fitRoute(animated: true)
        } catch {
            routeMessage = "Milli couldn't calculate that route right now. Check your connection and try again."
        }
    }

    private func startNavigation() {
        guard destinationItem != nil, !plannedRouteCoordinates.isEmpty else { return }
        locationManager.startTracking()
        navigationStartedAt = Date()
        currentStepIndex = 0
        isNavigating = true
        updateNavigationCamera()
    }

    private func endNavigationAndSave() {
        guard isNavigating else { return }

        let endedAt = Date()
        let startedAt = locationManager.tripStartedAt ?? navigationStartedAt ?? endedAt
        let miles = locationManager.distanceMiles
        let recordedRoute = locationManager.routeCoordinates
        let destination = destinationItem
        let rate = MileageRate.businessRate(for: startedAt)

        locationManager.stopTracking()
        isNavigating = false
        navigationStartedAt = nil

        if miles > 0.001 {
            let record = MileageTripRecord(
                id: UUID(),
                source: .navigation,
                platform: nil,
                businessPurpose: destination?.name.map { "Route to \($0)" } ?? "Milli navigation",
                startedAt: startedAt,
                endedAt: endedAt,
                distanceMiles: miles,
                deductionRate: rate,
                startAddress: nil,
                endAddress: destination?.name,
                startCoordinate: recordedRoute.first.map(MileageCoordinate.init),
                endCoordinate: destination?.placemark.coordinate.map(MileageCoordinate.init) ?? recordedRoute.last.map(MileageCoordinate.init),
                routePoints: recordedRoute.map(MileageCoordinate.init),
                navigationExternalID: nil,
                syncState: .pending
            )
            mileageLog.add(record)
        }

        locationManager.resetCurrentTrip()
        clearRoute()
    }

    private func updateNavigationProgress(using location: CLLocation) {
        guard isNavigating else { return }

        while navigationSteps.indices.contains(currentStepIndex),
              let endpoint = navigationSteps[currentStepIndex].endpoint,
              location.distance(from: CLLocation(latitude: endpoint.latitude, longitude: endpoint.longitude)) < 45,
              currentStepIndex < navigationSteps.count - 1 {
            currentStepIndex += 1
        }

        if shouldReroute(from: location) {
            lastRerouteAt = Date()
            if let destinationItem {
                Task { await calculateRoute(to: destinationItem) }
            }
        }
    }

    private func shouldReroute(from location: CLLocation) -> Bool {
        guard plannedRouteCoordinates.count > 1,
              Date().timeIntervalSince(lastRerouteAt) > 30 else {
            return false
        }

        let sampleStride = max(plannedRouteCoordinates.count / 140, 1)
        var closest = CLLocationDistance.greatestFiniteMagnitude

        for index in stride(from: 0, to: plannedRouteCoordinates.count, by: sampleStride) {
            let coordinate = plannedRouteCoordinates[index]
            let routeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            closest = min(closest, location.distance(from: routeLocation))
            if closest < 90 { return false }
        }

        return closest > 220
    }

    private func updateNavigationCamera() {
        guard let location = locationManager.lastLocation else { return }
        let course = location.course >= 0 ? location.course : 0
        let camera = MapCamera(
            centerCoordinate: location.coordinate,
            distance: 760,
            heading: course,
            pitch: 58
        )
        withAnimation(.easeInOut(duration: 0.38)) {
            mapPosition = .camera(camera)
        }
    }

    private func fitRoute(animated: Bool) {
        guard !plannedRouteCoordinates.isEmpty else { return }
        let region = mapRegion(for: plannedRouteCoordinates)
        if animated {
            withAnimation(.easeInOut(duration: 0.42)) {
                mapPosition = .region(region)
            }
        } else {
            mapPosition = .region(region)
        }
    }

    private func recenter(on coordinate: CLLocationCoordinate2D, animated: Bool) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.38)) {
                mapPosition = .region(region)
            }
        } else {
            mapPosition = .region(region)
        }
    }

    private func clearRoute() {
        guard !isNavigating else { return }
        destinationText = ""
        destinationItem = nil
        plannedRouteCoordinates = []
        navigationSteps = []
        currentStepIndex = 0
        plannedDistanceMeters = 0
        plannedETA = 0
        awaitingHandoffRoute = false

        if let coordinate = locationManager.lastLocation?.coordinate {
            recenter(on: coordinate, animated: true)
        }
    }

    private func mapRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                span: MKCoordinateSpan(latitudeDelta: 42, longitudeDelta: 58)
            )
        }

        let minLat = coordinates.map(\.latitude).min() ?? first.latitude
        let maxLat = coordinates.map(\.latitude).max() ?? first.latitude
        let minLon = coordinates.map(\.longitude).min() ?? first.longitude
        let maxLon = coordinates.map(\.longitude).max() ?? first.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.012),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.012)
            )
        )
    }

    private func maneuverSymbol(for instruction: String?) -> String {
        let lower = (instruction ?? "").lowercased()
        if lower.contains("left") { return "arrow.turn.up.left" }
        if lower.contains("right") { return "arrow.turn.up.right" }
        if lower.contains("u-turn") || lower.contains("u turn") { return "arrow.uturn.backward" }
        if lower.contains("merge") { return "arrow.merge" }
        if lower.contains("exit") { return "arrow.up.right" }
        if lower.contains("arrive") || lower.contains("destination") { return "flag.checkered" }
        return "arrow.up"
    }
}

private extension MKPolyline {
    var milliNavigationCoordinates: [CLLocationCoordinate2D] {
        guard pointCount > 0 else { return [] }
        var coordinates = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: pointCount
        )
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
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
