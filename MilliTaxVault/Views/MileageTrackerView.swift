import SwiftUI
import CoreLocation
import MapKit

// MARK: - MileageTrackerView
// Production Apple-native navigation cockpit. This view is kept alive by the
// root ContentView once Mileage is first opened so an active route and mileage
// session survive tab/screen changes. The existing production LocationManager
// remains the single GPS/mileage authority.

struct MileageTrackerView: View {
    @Binding var pendingNavigationRequest: NavigationHandoffRequest?
    var onBack: () -> Void = {}

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
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var navigationSteps: [MilliRouteStep] = []
    @State private var currentStepIndex = 0
    @State private var routeDistanceMeters: CLLocationDistance = 0
    @State private var routeExpectedTravelTime: TimeInterval = 0
    @State private var routeCalculatedAt: Date?
    @State private var routeDistanceBaselineMeters: CLLocationDistance = 0
    @State private var isBuildingRoute = false
    @State private var isNavigating = false
    @State private var deferredHandoff: NavigationHandoffRequest?
    @State private var routeMessage: String?
    @State private var lastRerouteAt = Date.distantPast
    @State private var showMileageTools = false

    private var currentStep: MilliRouteStep? {
        guard navigationSteps.indices.contains(currentStepIndex) else { return nil }
        return navigationSteps[currentStepIndex]
    }

    private var distanceSinceRouteCalculation: CLLocationDistance {
        max(locationManager.distanceMeters - routeDistanceBaselineMeters, 0)
    }

    private var remainingDistanceMeters: CLLocationDistance {
        max(routeDistanceMeters - distanceSinceRouteCalculation, 0)
    }

    private var remainingETA: TimeInterval {
        guard let routeCalculatedAt else { return routeExpectedTravelTime }
        return max(routeExpectedTravelTime - Date().timeIntervalSince(routeCalculatedAt), 0)
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
                telemetryCard
                primaryAction
                todaySummary
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .onAppear {
            prepareLocationIfNeeded()
            consumePendingHandoff()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            consumePendingHandoff()
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.refreshCurrentLocation()
                resumeDeferredHandoffIfPossible()
            }
        }
        .onChange(of: locationManager.lastLocation?.timestamp) { _, _ in
            guard let location = locationManager.lastLocation else { return }

            resumeDeferredHandoffIfPossible()

            if isNavigating {
                updateNavigationProgress(using: location)
                updateNavigationCamera()
            } else if routeCoordinates.isEmpty {
                recenter(on: location.coordinate, animated: true)
            }
        }
        .onChange(of: locationManager.routeCoordinates.count) { _, _ in
            guard isNavigating else { return }
            updateNavigationCamera()
        }
        .sheet(isPresented: $showMileageTools) {
            MileageView(onBack: { showMileageTools = false })
                .presentationDragIndicator(.visible)
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

    // MARK: - Header

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Button {
                    guard !isNavigating else { return }
                    showMileageTools = true
                } label: {
                    Image(systemName: "road.lanes")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isNavigating ? MilliColors.textTertiary : MilliColors.cyanGlow)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .disabled(isNavigating)
                .accessibilityLabel(isNavigating ? "Mileage tools unavailable during navigation" : "Open mileage tools")
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
        .frame(height: 44)
    }

    // MARK: - Route UI

    private var maneuverCard: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.10))
                    .frame(width: 56, height: 56)

                Image(systemName: maneuverSymbol(for: currentStep?.instruction))
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(currentStep?.instruction ?? arrivalInstruction)
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
        .accessibilityElement(children: .combine)
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
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear destination")
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 48)
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
                        Text(routeCoordinates.isEmpty ? "BUILD ROUTE" : "REBUILD ROUTE")
                    }
                    .font(.custom("Sora-SemiBold", size: 11, relativeTo: .caption))
                    .tracking(0.5)
                    .foregroundStyle(canSearchDestination ? MilliColors.cyanGlow : MilliColors.textTertiary)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .disabled(!canSearchDestination || isBuildingRoute)
            }
        }
        .padding(12)
        .background(MilliCardBackground(showGlow: false))
    }

    private var canSearchDestination: Bool {
        !destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navigationMap: some View {
        Map(position: $mapPosition, interactionModes: isNavigating ? [.zoom, .pan] : .all) {
            if routeCoordinates.count >= 2 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 11)
                MapPolyline(coordinates: routeCoordinates)
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
        .frame(height: isNavigating ? 360 : 300)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) {
            gpsBadge
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
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.74)))
            }
            .buttonStyle(.plain)
            .padding(9)
            .accessibilityLabel("Recenter map")
        }
        .accessibilityLabel(mapAccessibilityLabel)
    }

    private var gpsBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(gpsBadgeColor)
                .frame(width: 6, height: 6)
            Text(gpsBadgeText)
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.72)))
    }

    private var gpsBadgeText: String {
        switch locationManager.trackingState {
        case .idle:
            return locationManager.lastLocation == nil ? "GPS READY" : "GPS LOCKED"
        case .acquiringLocation:
            return "GPS ACQUIRING"
        case .tracking:
            return "GPS TRACKING"
        case .degraded:
            return "GPS DEGRADED"
        case .authorizationDenied:
            return "GPS DENIED"
        }
    }

    private var gpsBadgeColor: Color {
        switch locationManager.trackingState {
        case .tracking: return MilliColors.positive
        case .degraded, .acquiringLocation: return MilliColors.warning
        case .authorizationDenied: return MilliColors.negative
        case .idle: return locationManager.lastLocation == nil ? MilliColors.textTertiary : MilliColors.positive
        }
    }

    private var mapAccessibilityLabel: String {
        if isNavigating {
            return "Active navigation map to \(destinationItem?.name ?? destinationText). \(distanceLabel) remaining, ETA \(etaLabel)."
        }
        if routeCoordinates.count >= 2 {
            return "Route preview to \(destinationItem?.name ?? destinationText). Distance \(distanceLabel), ETA \(etaLabel)."
        }
        return "Navigation map. Enter a destination to build a driving route."
    }

    // MARK: - Telemetry

    private var telemetryCard: some View {
        HStack(spacing: 0) {
            metricColumn(value: distanceLabel, label: isNavigating ? "REMAINING" : "ROUTE")
            metricDivider
            metricColumn(value: etaLabel, label: "ETA")
            metricDivider
            metricColumn(
                value: isNavigating ? "\(Int(locationManager.currentSpeedMPH.rounded()))" : "—",
                label: isNavigating ? "MPH" : "SPEED"
            )
            metricDivider
            metricColumn(
                value: locationManager.distanceMiles.formatted(.number.precision(.fractionLength(1))),
                label: "MILES LOGGED"
            )
        }
        .padding(.vertical, 12)
        .background(MilliCardBackground(showGlow: true))
        .accessibilityElement(children: .combine)
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("Sora-SemiBold", size: 15, relativeTo: .headline))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(label)
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(0.4)
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
            .frame(height: 48)
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
        .disabled(!isNavigating && routeCoordinates.isEmpty)
        .opacity(!isNavigating && routeCoordinates.isEmpty ? 0.48 : 1)
    }

    private var todaySummary: some View {
        let rate = NavigationMileageRate.businessRate(for: Date())

        return HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 38, height: 38)
                Image(systemName: "car.side.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Today: \(todayMiles.formatted(.number.precision(.fractionLength(2)))) business mi")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Estimated deduction: \((todayMiles * rate).formatted(.currency(code: "USD")))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.positive)
            }

            Spacer()

            if !isNavigating {
                Button("TOOLS") {
                    showMileageTools = true
                }
                .font(.custom("Sora-SemiBold", size: 9, relativeTo: .caption2))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.plain)
            }
        }
        .padding(11)
        .background(MilliCardBackground(showGlow: false))
    }

    // MARK: - Handoff / route building

    private func prepareLocationIfNeeded() {
        if locationManager.canTrackLocation {
            locationManager.refreshCurrentLocation()
        } else {
            locationManager.requestPermission()
        }
    }

    @MainActor
    private func consumePendingHandoff() {
        guard let handoff = pendingNavigationRequest else { return }

        // Capture the request in persistent view state before clearing the root
        // binding. This prevents an address-only handoff from disappearing while
        // iOS is still resolving location permission/GPS.
        deferredHandoff = handoff
        pendingNavigationRequest = nil

        if let coordinate = handoff.coordinate {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.name = handoff.destinationName ?? handoff.destinationAddress ?? "Destination"
            destinationItem = item
            destinationText = item.name ?? "Destination"
        } else if let address = handoff.destinationAddress ?? handoff.destinationName {
            destinationText = address
            destinationItem = nil
        }

        resumeDeferredHandoffIfPossible()
    }

    @MainActor
    private func resumeDeferredHandoffIfPossible() {
        guard deferredHandoff != nil,
              locationManager.lastLocation != nil,
              !isBuildingRoute,
              routeCoordinates.isEmpty else {
            return
        }

        if let destinationItem {
            Task { await calculateRoute(to: destinationItem, isReroute: false) }
        } else if canSearchDestination {
            Task { await searchAndBuildRoute(fromDeferredHandoff: true) }
        }
    }

    @MainActor
    private func searchAndBuildRoute(fromDeferredHandoff: Bool = false) async {
        let query = destinationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        guard let origin = locationManager.lastLocation?.coordinate else {
            if locationManager.canTrackLocation {
                locationManager.refreshCurrentLocation()
            } else {
                locationManager.requestPermission()
            }
            if !fromDeferredHandoff {
                routeMessage = "Milli is acquiring your current location. The route will build automatically when GPS is ready."
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
                routeMessage = "Milli couldn't find that destination. Try a fuller street address or place name."
                return
            }

            destinationItem = destination
            await calculateRoute(to: destination, isReroute: false)
        } catch {
            routeMessage = "Milli couldn't search that destination right now. Check the address and your connection, then try again."
        }
    }

    @MainActor
    private func calculateRoute(to destination: MKMapItem, isReroute: Bool) async {
        guard let origin = locationManager.lastLocation?.coordinate else {
            return
        }

        if !isBuildingRoute {
            isBuildingRoute = true
        }
        defer { isBuildingRoute = false }

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

            let fullCoordinates = route.polyline.milliNavigationCoordinates
            routeCoordinates = fullCoordinates
            navigationSteps = buildSteps(from: route.steps, routeCoordinates: fullCoordinates)
            currentStepIndex = 0
            routeDistanceMeters = route.distance
            routeExpectedTravelTime = route.expectedTravelTime
            routeCalculatedAt = Date()
            routeDistanceBaselineMeters = locationManager.distanceMeters
            destinationItem = destination
            destinationText = destination.name ?? destinationText
            deferredHandoff = nil

            if isReroute {
                routeMessage = nil
            }

            if isNavigating {
                updateNavigationCamera()
            } else {
                fitRoute(animated: true)
            }
        } catch {
            routeMessage = isReroute
                ? "Milli couldn't refresh the route. Continue safely while Milli retries when GPS and network conditions improve."
                : "Milli couldn't calculate that route right now. Check your connection and try again."
        }
    }

    private func buildSteps(
        from steps: [MKRoute.Step],
        routeCoordinates: [CLLocationCoordinate2D]
    ) -> [MilliRouteStep] {
        steps.compactMap { step in
            let instruction = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !instruction.isEmpty else { return nil }

            let coordinates = step.polyline.milliNavigationCoordinates
            guard let endpoint = coordinates.last else { return nil }
            let endpointIndex = nearestRouteIndex(to: endpoint, in: routeCoordinates) ?? max(routeCoordinates.count - 1, 0)
            let notice = step.notice?.trimmingCharacters(in: .whitespacesAndNewlines)

            return MilliRouteStep(
                instruction: instruction,
                notice: notice?.isEmpty == false ? notice : nil,
                distanceMeters: step.distance,
                endpointRouteIndex: endpointIndex
            )
        }
    }

    // MARK: - Navigation session

    private func startNavigation() {
        guard destinationItem != nil, !routeCoordinates.isEmpty else { return }

        routeDistanceBaselineMeters = locationManager.distanceMeters
        routeCalculatedAt = Date()
        currentStepIndex = 0
        lastRerouteAt = Date.distantPast
        isNavigating = true
        locationManager.startTracking()
        updateNavigationCamera()
    }

    private func endNavigationAndSave() {
        guard isNavigating else { return }

        let endedAt = Date()
        let startedAt = locationManager.tripStartedAt ?? routeCalculatedAt ?? endedAt
        let miles = locationManager.distanceMiles
        let recordedRoute = locationManager.routeCoordinates
        let destination = destinationItem
        let rate = NavigationMileageRate.businessRate(for: startedAt)

        locationManager.stopTracking()
        isNavigating = false

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
                endCoordinate: destination.map { MileageCoordinate($0.placemark.coordinate) } ?? recordedRoute.last.map(MileageCoordinate.init),
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
        guard isNavigating, !routeCoordinates.isEmpty else { return }

        if let currentRouteIndex = nearestRouteIndex(to: location.coordinate, in: routeCoordinates) {
            // Advance when the user's projected route position has reached or
            // passed the maneuver endpoint. This survives sparse GPS callbacks
            // and does not require entering an arbitrary 45 m circle.
            while navigationSteps.indices.contains(currentStepIndex),
                  currentStepIndex < navigationSteps.count - 1,
                  currentRouteIndex + 2 >= navigationSteps[currentStepIndex].endpointRouteIndex {
                currentStepIndex += 1
            }
        }

        if shouldReroute(from: location) {
            lastRerouteAt = Date()
            if let destinationItem {
                Task { await calculateRoute(to: destinationItem, isReroute: true) }
            }
        }
    }

    private func shouldReroute(from location: CLLocation) -> Bool {
        guard routeCoordinates.count > 1,
              Date().timeIntervalSince(lastRerouteAt) > 30 else {
            return false
        }

        let sampleStride = max(routeCoordinates.count / 160, 1)
        var closest = CLLocationDistance.greatestFiniteMagnitude

        for index in stride(from: 0, to: routeCoordinates.count, by: sampleStride) {
            let coordinate = routeCoordinates[index]
            let routeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            closest = min(closest, location.distance(from: routeLocation))
            if closest < 90 { return false }
        }

        return closest > 220
    }

    private func nearestRouteIndex(
        to coordinate: CLLocationCoordinate2D,
        in coordinates: [CLLocationCoordinate2D]
    ) -> Int? {
        guard !coordinates.isEmpty else { return nil }

        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let sampleStride = max(coordinates.count / 400, 1)
        var bestIndex = 0
        var bestDistance = CLLocationDistance.greatestFiniteMagnitude

        for index in stride(from: 0, to: coordinates.count, by: sampleStride) {
            let candidate = coordinates[index]
            let distance = target.distance(
                from: CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
            )
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        // Refine around the best sampled index to avoid skipping a maneuver on
        // long/high-resolution polylines.
        let lower = max(bestIndex - sampleStride, 0)
        let upper = min(bestIndex + sampleStride, coordinates.count - 1)
        if lower <= upper {
            for index in lower...upper {
                let candidate = coordinates[index]
                let distance = target.distance(
                    from: CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
                )
                if distance < bestDistance {
                    bestDistance = distance
                    bestIndex = index
                }
            }
        }

        return bestIndex
    }

    // MARK: - Camera / formatting

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
        guard !routeCoordinates.isEmpty else { return }
        let region = mapRegion(for: routeCoordinates)
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
        routeCoordinates = []
        navigationSteps = []
        currentStepIndex = 0
        routeDistanceMeters = 0
        routeExpectedTravelTime = 0
        routeCalculatedAt = nil
        routeDistanceBaselineMeters = locationManager.distanceMeters
        deferredHandoff = nil

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

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.012),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.012)
            )
        )
    }

    private var distanceLabel: String {
        let meters = isNavigating ? remainingDistanceMeters : routeDistanceMeters
        guard meters > 0 else { return "—" }
        return "\((meters / 1_609.344).formatted(.number.precision(.fractionLength(1)))) mi"
    }

    private var etaLabel: String {
        let interval = remainingETA
        guard interval > 0 else { return "—" }
        return Date().addingTimeInterval(interval).formatted(date: .omitted, time: .shortened)
    }

    private var stepDistanceLabel: String {
        guard let step = currentStep else {
            return arrivalInstruction
        }
        let meters = max(step.distanceMeters, 0)
        if meters >= 1_609.344 {
            return "in \((meters / 1_609.344).formatted(.number.precision(.fractionLength(1)))) mi"
        }
        let feet = max(Int((meters * 3.28084 / 50).rounded()) * 50, 50)
        return "in \(feet) ft"
    }

    private var arrivalInstruction: String {
        guard let destination = destinationItem?.placemark.coordinate,
              let location = locationManager.lastLocation else {
            return "Continue on the highlighted route"
        }
        let distance = location.distance(
            from: CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        )
        return distance < 55 ? "Arriving at destination" : "Continue on the highlighted route"
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

// MARK: - Navigation domain

private struct MilliRouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let notice: String?
    let distanceMeters: CLLocationDistance
    let endpointRouteIndex: Int
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

private enum NavigationMileageRate {
    /// Mirrors the canonical MileageView 2026 schedule until tax-rate constants
    /// are moved into a shared domain service in the release-hardening phase.
    static func businessRate(for date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard components.year == 2026 else {
            // Historical/unknown-year fallback is intentionally conservative and
            // is only used for an estimate label in this navigation surface.
            return 0.725
        }

        let month = components.month ?? 1
        return month <= 6 ? 0.725 : 0.76
    }
}

#Preview {
    MileageTrackerView(pendingNavigationRequest: .constant(nil))
}
