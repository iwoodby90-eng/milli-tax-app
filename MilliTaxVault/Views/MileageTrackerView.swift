import SwiftUI
import CoreLocation
import MapKit

// MARK: - MileageTrackerView
// Navigation handoff host for Milli's Mileage cockpit.
//
// Normal in-app mileage work continues to use MileageView. When iOS or another
// driver app launches Milli with a supported navigation request, this host owns
// the live MapKit route, starts the same production LocationManager used by the
// mileage cockpit, and persists the completed route into the canonical mileage
// log. No Google Maps SDK or external maps handoff is used on iOS.

struct MileageTrackerView: View {
    @Binding private var pendingNavigationRequest: NavigationHandoffRequest?
    var onBack: () -> Void = {}

    @StateObject private var locationManager = LocationManager()
    @StateObject private var mileageLog = MileageLogStore()

    @AppStorage("milliAcceptNavigationRequests") private var acceptNavigationRequests = true

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var destinationItem: MKMapItem?
    @State private var activeRoute: MKRoute?
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var routeDistanceMiles: Double = 0
    @State private var routeETA: TimeInterval = 0
    @State private var isBuildingRoute = false
    @State private var routeError: String?
    @State private var currentStepIndex = 0
    @State private var didAttemptCurrentRequest = false

    init(
        pendingNavigationRequest: Binding<NavigationHandoffRequest?> = .constant(nil),
        onBack: @escaping () -> Void = {}
    ) {
        _pendingNavigationRequest = pendingNavigationRequest
        self.onBack = onBack
    }

    var body: some View {
        Group {
            if let request = pendingNavigationRequest, acceptNavigationRequests {
                navigationHandoffView(request: request)
            } else {
                MileageView(onBack: onBack)
            }
        }
        .onAppear {
            prepareForPendingRequest()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            resetRouteState()
            prepareForPendingRequest()
        }
        .onChange(of: locationManager.lastLocation?.timestamp) { _, _ in
            updateGuidanceProgress()

            guard pendingNavigationRequest != nil,
                  activeRoute == nil,
                  !isBuildingRoute,
                  !didAttemptCurrentRequest else { return }
            prepareForPendingRequest()
        }
        .onChange(of: locationManager.routeCoordinates.count) { _, _ in
            updateNavigationCamera()
            updateGuidanceProgress()
        }
        .alert("Navigation", isPresented: Binding(
            get: { routeError != nil || locationManager.errorMessage != nil },
            set: {
                if !$0 {
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

    @ViewBuilder
    private func navigationHandoffView(request: NavigationHandoffRequest) -> some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationHeader

                Map(position: $mapPosition, interactionModes: .all) {
                    if routeCoordinates.count >= 2 {
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(MilliColors.silverBright.opacity(0.16), lineWidth: 12)
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(MilliColors.cyanGlow, lineWidth: 5)
                    }

                    if locationManager.routeCoordinates.count >= 2 {
                        MapPolyline(coordinates: locationManager.routeCoordinates)
                            .stroke(MilliColors.positive.opacity(0.86), lineWidth: 4)
                    }

                    if let destinationItem {
                        Annotation("Destination", coordinate: destinationItem.placemark.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.88))
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(MilliColors.positive, lineWidth: 2))
                                Image(systemName: "mappin")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(MilliColors.positive)
                            }
                            .shadow(color: MilliColors.positive.opacity(0.38), radius: 8)
                        }
                    }

                    if let current = locationManager.lastLocation?.coordinate {
                        Annotation("Current location", coordinate: current) {
                            ZStack {
                                Circle()
                                    .fill(MilliColors.cyanGlow.opacity(0.18))
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .fill(Color.black.opacity(0.88))
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(MilliColors.cyanGlow, lineWidth: 2.5))
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(MilliColors.cyanGlow)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .overlay(alignment: .top) {
                    guidanceBanner(request: request)
                        .padding(.horizontal, MilliSpacing.screenHorizontal)
                        .padding(.top, 10)
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        updateNavigationCamera()
                    } label: {
                        Image(systemName: "scope")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MilliColors.cyanGlow)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.78))
                                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.7))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                }

                navigationControlPanel(request: request)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var navigationHeader: some View {
        HStack(spacing: 12) {
            Button {
                if locationManager.isTracking {
                    finishNavigationTrip(save: true)
                } else {
                    pendingNavigationRequest = nil
                    onBack()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("MILLI NAVIGATION")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.cyanGlow)
                Text(locationManager.isTracking ? "Live route + mileage tracking" : "Route ready")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(locationManager.lastLocation == nil ? MilliColors.warning : MilliColors.positive)
                    .frame(width: 6, height: 6)
                Text(locationManager.lastLocation == nil ? "GPS" : "LIVE")
                    .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.035)))
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .frame(height: 58)
        .background(MilliColors.background)
    }

    private func guidanceBanner(request: NavigationHandoffRequest) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if isBuildingRoute {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MilliColors.cyanGlow)
                    Text("Building route…")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textPrimary)
                }
            } else if let instruction = currentInstruction {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: guidanceSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(instruction)
                            .font(.custom("Sora-SemiBold", size: 16, relativeTo: .headline))
                            .foregroundStyle(MilliColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let distance = distanceToCurrentStep {
                            Text(distanceText(distance))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.cyanGlow)
                        }
                    }
                }
            } else {
                Text(request.destinationName ?? request.destinationAddress ?? "Destination")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.20), lineWidth: 0.8)
                }
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }

    private func navigationControlPanel(request: NavigationHandoffRequest) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(destinationItem?.name ?? request.destinationName ?? request.destinationAddress ?? "Destination")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)

                    if activeRoute != nil {
                        Text("\(routeDistanceMiles.formatted(.number.precision(.fractionLength(1)))) mi • \(formattedETA(routeETA))")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                    } else {
                        Text("Waiting for route")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                }

                Spacer(minLength: 8)

                if locationManager.isTracking {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(locationManager.distanceMiles.formatted(.number.precision(.fractionLength(2))))
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.cyanGlow)
                        Text("miles tracked")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                }
            }

            Button {
                if locationManager.isTracking {
                    finishNavigationTrip(save: true)
                } else {
                    startNavigation()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: locationManager.isTracking ? "stop.fill" : "location.north.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(locationManager.isTracking ? "END & SAVE TRIP" : "START NAVIGATION")
                        .font(.custom("Sora-SemiBold", size: 12, relativeTo: .caption))
                        .tracking(0.4)
                }
                .foregroundStyle(locationManager.isTracking ? MilliColors.textPrimary : MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(locationManager.isTracking ? Color.white.opacity(0.055) : MilliColors.cyanGlow)
                        .overlay {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(MilliColors.cyanGlow.opacity(locationManager.isTracking ? 0.30 : 1), lineWidth: 0.8)
                        }
                )
            }
            .buttonStyle(.plain)
            .disabled(activeRoute == nil || isBuildingRoute)
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 12)
        .padding(.bottom, MilliSpacing.bottomNavHeight + 18)
        .background(
            LinearGradient(
                colors: [MilliColors.cardBackground, MilliColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var routeSteps: [MKRoute.Step] {
        activeRoute?.steps.filter { !$0.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
    }

    private var currentInstruction: String? {
        guard !routeSteps.isEmpty else { return nil }
        return routeSteps[min(currentStepIndex, routeSteps.count - 1)].instructions
    }

    private var guidanceSymbol: String {
        guard let instruction = currentInstruction?.lowercased() else {
            return "location.north.fill"
        }
        if instruction.contains("left") { return "arrow.turn.up.left" }
        if instruction.contains("right") { return "arrow.turn.up.right" }
        if instruction.contains("u-turn") || instruction.contains("u turn") { return "arrow.uturn.backward" }
        if instruction.contains("arrive") || instruction.contains("destination") { return "mappin.and.ellipse" }
        if instruction.contains("merge") { return "arrow.merge" }
        return "arrow.up"
    }

    private var distanceToCurrentStep: CLLocationDistance? {
        guard let currentLocation = locationManager.lastLocation,
              !routeSteps.isEmpty else { return nil }

        let step = routeSteps[min(currentStepIndex, routeSteps.count - 1)]
        guard let coordinate = step.polyline.lastCoordinate else { return nil }
        return currentLocation.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    private func prepareForPendingRequest() {
        guard let request = pendingNavigationRequest,
              acceptNavigationRequests,
              activeRoute == nil,
              !isBuildingRoute else { return }

        guard locationManager.canTrackLocation else {
            locationManager.requestPermission()
            return
        }

        guard locationManager.lastLocation != nil else {
            locationManager.refreshCurrentLocation()
            return
        }

        didAttemptCurrentRequest = true
        Task { await buildRoute(for: request) }
    }

    @MainActor
    private func buildRoute(for request: NavigationHandoffRequest) async {
        guard let originCoordinate = locationManager.lastLocation?.coordinate else {
            didAttemptCurrentRequest = false
            locationManager.refreshCurrentLocation()
            return
        }

        isBuildingRoute = true
        routeError = nil
        defer { isBuildingRoute = false }

        do {
            let destination = try await resolveDestination(for: request, origin: originCoordinate)

            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
            directionsRequest.destination = destination
            directionsRequest.transportType = .automobile
            directionsRequest.requestsAlternateRoutes = false

            let response = try await MKDirections(request: directionsRequest).calculate()
            guard let route = response.routes.first else {
                routeError = "Milli couldn't find a drivable route to that destination."
                return
            }

            destinationItem = destination
            activeRoute = route
            routeCoordinates = route.polyline.coordinateArrayForNavigation
            routeDistanceMiles = route.distance / 1_609.344
            routeETA = route.expectedTravelTime
            currentStepIndex = 0
            updateNavigationCamera()
        } catch {
            routeError = "Milli couldn't build the incoming route. Check the destination and your connection, then try again."
        }
    }

    @MainActor
    private func resolveDestination(
        for request: NavigationHandoffRequest,
        origin: CLLocationCoordinate2D
    ) async throws -> MKMapItem {
        if let coordinate = request.coordinate {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.name = request.destinationName ?? request.destinationAddress
            return item
        }

        guard let query = request.destinationAddress ?? request.destinationName,
              !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NavigationRouteError.missingDestination
        }

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = MKCoordinateRegion(
            center: origin,
            span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
        )

        let response = try await MKLocalSearch(request: searchRequest).start()
        guard let item = response.mapItems.first else {
            throw NavigationRouteError.destinationNotFound
        }
        return item
    }

    private func startNavigation() {
        guard activeRoute != nil else { return }
        locationManager.startTracking()
        updateNavigationCamera()
    }

    private func finishNavigationTrip(save: Bool) {
        let endedAt = Date()
        let startedAt = locationManager.tripStartedAt ?? endedAt
        let recordedMiles = locationManager.distanceMiles
        let recordedRoute = locationManager.routeCoordinates
        let destinationName = destinationItem?.name
        let destinationCoordinate = destinationItem?.placemark.coordinate

        if locationManager.isTracking {
            locationManager.stopTracking()
        }

        if save, recordedMiles > 0.001 {
            let rate = navigationMileageRate(for: startedAt)
            let record = MileageTripRecord(
                id: UUID(),
                source: .navigation,
                platform: nil,
                businessPurpose: destinationName.map { "Route to \($0)" } ?? "Navigation mileage",
                startedAt: startedAt,
                endedAt: endedAt,
                distanceMiles: recordedMiles,
                deductionRate: rate,
                startAddress: nil,
                endAddress: destinationName,
                startCoordinate: recordedRoute.first.map(MileageCoordinate.init),
                endCoordinate: destinationCoordinate.map(MileageCoordinate.init) ?? recordedRoute.last.map(MileageCoordinate.init),
                routePoints: recordedRoute.map(MileageCoordinate.init),
                navigationExternalID: pendingNavigationRequest?.id.uuidString,
                syncState: .pending
            )
            mileageLog.add(record)
        }

        pendingNavigationRequest = nil
        resetRouteState()
    }

    private func resetRouteState() {
        destinationItem = nil
        activeRoute = nil
        routeCoordinates = []
        routeDistanceMiles = 0
        routeETA = 0
        currentStepIndex = 0
        didAttemptCurrentRequest = false
        routeError = nil
    }

    private func updateGuidanceProgress() {
        guard locationManager.isTracking,
              let distance = distanceToCurrentStep,
              !routeSteps.isEmpty else { return }

        if distance <= 45, currentStepIndex < routeSteps.count - 1 {
            currentStepIndex += 1
        }
    }

    private func updateNavigationCamera() {
        let coordinates: [CLLocationCoordinate2D]
        if locationManager.isTracking,
           let current = locationManager.lastLocation?.coordinate {
            let routeTail = routeCoordinates.prefix(80)
            coordinates = [current] + Array(routeTail)
        } else {
            coordinates = routeCoordinates
        }

        guard !coordinates.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.35)) {
            mapPosition = .region(mapRegion(for: coordinates))
        }
    }

    private func mapRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                span: MKCoordinateSpan(latitudeDelta: 42, longitudeDelta: 58)
            )
        }

        guard coordinates.count > 1 else {
            return MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
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
                latitudeDelta: max((maxLat - minLat) * 1.45, 0.010),
                longitudeDelta: max((maxLon - minLon) * 1.45, 0.010)
            )
        )
    }

    private func formattedETA(_ interval: TimeInterval) -> String {
        let minutes = max(Int((interval / 60).rounded()), 1)
        if minutes >= 60 {
            return "\(minutes / 60) hr \(minutes % 60) min"
        }
        return "\(minutes) min"
    }

    private func distanceText(_ meters: CLLocationDistance) -> String {
        if meters < 305 {
            let feet = max(Int((meters * 3.28084).rounded(toNearest: 25)), 25)
            return "In \(feet) ft"
        }
        let miles = meters / 1_609.344
        return "In \(miles.formatted(.number.precision(.fractionLength(miles < 1 ? 1 : 0)))) mi"
    }

    private func navigationMileageRate(for date: Date) -> Double {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: date)
        guard components.year == 2026 else { return 0.76 }
        return (components.month ?? 12) >= 7 ? 0.76 : 0.725
    }
}

private enum NavigationRouteError: Error {
    case missingDestination
    case destinationNotFound
}

private extension MKPolyline {
    var coordinateArrayForNavigation: [CLLocationCoordinate2D] {
        guard pointCount > 0 else { return [] }
        var coordinates = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: pointCount
        )
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }

    var lastCoordinate: CLLocationCoordinate2D? {
        coordinateArrayForNavigation.last
    }
}

private extension Double {
    func rounded(toNearest increment: Double) -> Double {
        guard increment > 0 else { return self }
        return (self / increment).rounded() * increment
    }
}

#Preview {
    MileageTrackerView()
}
