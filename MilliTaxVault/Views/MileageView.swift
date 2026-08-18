import SwiftUI
import CoreLocation
import MapKit

// MARK: - MileageView
// Native mileage instrumentation matching the approved production reference.
// The route panel is a real interactive Apple MapKit map. DEBUG visual-QA uses
// deterministic coordinates on that real map; production uses CLLocationManager.

struct MileageView: View {
    var onBack: () -> Void = {}

    @StateObject private var locationManager = LocationManager()
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
            span: MKCoordinateSpan(latitudeDelta: 42, longitudeDelta: 58)
        )
    )

    private static let demoRouteCoordinates: [CLLocationCoordinate2D] = [
        .init(latitude: 42.33182, longitude: -83.04772),
        .init(latitude: 42.33275, longitude: -83.04492),
        .init(latitude: 42.33402, longitude: -83.04216),
        .init(latitude: 42.33562, longitude: -83.03988),
        .init(latitude: 42.33712, longitude: -83.03748),
        .init(latitude: 42.33872, longitude: -83.03531),
        .init(latitude: 42.34048, longitude: -83.03312),
        .init(latitude: 42.34164, longitude: -83.03031),
        .init(latitude: 42.34274, longitude: -83.02721),
        .init(latitude: 42.34422, longitude: -83.02474),
        .init(latitude: 42.34608, longitude: -83.02318)
    ]

    private var isScreenshotMode: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["MILLI_SCREENSHOT_MODE"] == "1"
            || ProcessInfo.processInfo.arguments.contains("-milliScreenshotMode")
        #else
        false
        #endif
    }

    private var displayedRoute: [CLLocationCoordinate2D] {
        isScreenshotMode ? Self.demoRouteCoordinates : locationManager.routeCoordinates
    }

    private var displayedCurrentCoordinate: CLLocationCoordinate2D? {
        if let last = displayedRoute.last {
            return last
        }
        return locationManager.lastLocation?.coordinate
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                trackingCard
                todaySummary

                if !isScreenshotMode,
                   locationManager.canTrackLocation,
                   !locationManager.hasAlwaysAuthorization {
                    backgroundTrackingCard
                }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .onAppear {
            updateMapCamera(animated: false)
            if !isScreenshotMode {
                locationManager.refreshCurrentLocation()
            }
        }
        .onChange(of: locationManager.routeCoordinates.count) { _, _ in
            updateMapCamera(animated: true)
        }
        .onChange(of: locationManager.lastLocation?.timestamp) { _, _ in
            guard locationManager.routeCoordinates.isEmpty else { return }
            updateMapCamera(animated: true)
        }
        .alert(
            "Mileage Tracking",
            isPresented: Binding(
                get: { locationManager.errorMessage != nil },
                set: { if !$0 { locationManager.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                locationManager.errorMessage = nil
            }
        } message: {
            Text(locationManager.errorMessage ?? "")
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
            }

            Text("Mileage Tracking")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(height: 40)
    }

    private var trackingCard: some View {
        VStack(spacing: 0) {
            trackingStatus
                .padding(.top, 11)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                tripReadout(at: context.date)
            }

            if !isScreenshotMode {
                trackingAction
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }

            routePanel
        }
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "07131A"), Color(hex: "050B10")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 0.75)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous))
    }

    private var trackingStatus: some View {
        let active = isScreenshotMode || locationManager.isTracking

        return HStack(spacing: 6) {
            Circle()
                .fill(active ? MilliColors.positive : MilliColors.textTertiary)
                .frame(width: 7, height: 7)
                .shadow(color: active ? MilliColors.positive.opacity(0.55) : .clear, radius: 4)

            Text(active ? "Tracking Active" : "Ready to Track")
                .font(MilliFont.labelLarge)
                .foregroundStyle(active ? MilliColors.positive : MilliColors.textSecondary)
        }
    }

    private func tripReadout(at date: Date) -> some View {
        let miles = currentTripMiles
        let deduction = miles * MileageRate.businessRate(for: date)

        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(miles.formatted(.number.precision(.fractionLength(2))))
                        .font(.custom("Sora-Regular", size: 38, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .contentTransition(.numericText())
                    Text("mi")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Text(locationManager.isTracking || isScreenshotMode ? "Current Trip" : "Last Trip")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(.top, 12)

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(displayDuration(at: date))
                        .font(MilliFont.numericSmall)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Duration")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 30)

                VStack(spacing: 2) {
                    Text(deduction.formatted(.currency(code: "USD")))
                        .font(MilliFont.numericSmall)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Est. Deduction")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 11)
            .padding(.bottom, 9)
        }
    }

    private var trackingAction: some View {
        Button {
            if locationManager.isTracking {
                locationManager.stopTracking()
            } else {
                locationManager.startTracking()
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: locationManager.isTracking ? "stop.fill" : "location.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(locationManager.isTracking ? "STOP & SAVE TRIP" : "START TRACKING")
                    .font(.custom("Sora-SemiBold", size: 12, relativeTo: .caption))
                    .tracking(0.5)
            }
            .foregroundStyle(locationManager.isTracking ? MilliColors.textPrimary : MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(locationManager.isTracking ? Color.white.opacity(0.055) : MilliColors.cyanGlow)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                locationManager.isTracking ? MilliColors.cyanGlow.opacity(0.25) : MilliColors.cyanGlow,
                                lineWidth: 0.75
                            )
                    }
                    .shadow(
                        color: locationManager.isTracking ? .clear : MilliColors.cyanGlow.opacity(0.20),
                        radius: 7
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locationManager.isTracking ? "Stop and save mileage trip" : "Start mileage tracking")
    }

    private var routePanel: some View {
        Map(position: $mapPosition, interactionModes: .all) {
            if displayedRoute.count >= 2 {
                MapPolyline(coordinates: displayedRoute)
                    .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 10)

                MapPolyline(coordinates: displayedRoute)
                    .stroke(MilliColors.cyanGlow, lineWidth: 4)
            }

            if let start = displayedRoute.first {
                Annotation("Trip start", coordinate: start) {
                    startMapMarker
                }
            }

            if let current = displayedCurrentCoordinate {
                Annotation("Current location", coordinate: current) {
                    currentMapMarker
                }
            }
        }
        .frame(height: 246)
        .overlay {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.20),
                    Color.clear,
                    Color(hex: "001A22").opacity(0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            gpsBadge
                .padding(8)
        }
        .overlay(alignment: .bottomTrailing) {
            if displayedCurrentCoordinate != nil || !displayedRoute.isEmpty {
                Button {
                    updateMapCamera(animated: true)
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.72))
                                .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.6))
                        )
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel("Recenter mileage map")
            }
        }
        .overlay {
            if displayedRoute.isEmpty && displayedCurrentCoordinate == nil {
                VStack(spacing: 6) {
                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(MilliColors.cyanGlow.opacity(0.82))
                    Text(locationManager.isTracking ? "Waiting for GPS route…" : "Start a trip to map your route")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("The map itself is live MapKit data.")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.64))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MilliColors.cyanGlow.opacity(0.14), lineWidth: 0.6)
                        }
                )
                .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(routeAccessibilityLabel)
    }

    private var startMapMarker: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.82))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(MilliColors.silverBright.opacity(0.74), lineWidth: 1))
            Image(systemName: "flag.checkered")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(MilliColors.silverBright)
        }
        .shadow(color: .black.opacity(0.55), radius: 4, y: 2)
    }

    private var currentMapMarker: some View {
        ZStack {
            Circle()
                .fill(MilliColors.cyanGlow.opacity(0.18))
                .frame(width: 34, height: 34)
            Circle()
                .fill(Color.black.opacity(0.86))
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(MilliColors.cyanGlow, lineWidth: 2.5))
            Circle()
                .fill(MilliColors.cyanGlow)
                .frame(width: 7, height: 7)
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.52), radius: 7)
    }

    private var gpsBadge: some View {
        let locked = isScreenshotMode || locationManager.lastLocation != nil

        return HStack(spacing: 5) {
            Circle()
                .fill(locked ? MilliColors.positive : MilliColors.warning)
                .frame(width: 5, height: 5)
            Text(locked ? "GPS LOCKED" : permissionBadgeText)
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.66)))
    }

    private var permissionBadgeText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "GPS READY"
        case .denied, .restricted:
            return "GPS OFF"
        case .authorizedWhenInUse, .authorizedAlways:
            return "ACQUIRING"
        @unknown default:
            return "GPS"
        }
    }

    private var routeAccessibilityLabel: String {
        if isScreenshotMode {
            return "Active trip on an interactive map. GPS locked."
        }
        if locationManager.routeCoordinates.count >= 2 {
            return "Interactive mileage map with \(locationManager.routeCoordinates.count) recorded GPS points."
        }
        if locationManager.lastLocation != nil {
            return "Interactive mileage map centered on the current location."
        }
        return locationManager.isTracking ? "Mileage map is waiting for a GPS route." : "Interactive mileage map ready for a trip."
    }

    private var todaySummary: some View {
        let tripMiles = currentTripMiles
        let todayMiles = isScreenshotMode ? 126.37 : locationManager.todayDistanceMiles
        let rate = MileageRate.businessRate(for: Date())

        return HStack(spacing: 0) {
            summaryColumn(
                title: "THIS TRIP",
                miles: "\(tripMiles.formatted(.number.precision(.fractionLength(2)))) mi",
                value: (tripMiles * rate).formatted(.currency(code: "USD"))
            )

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 1, height: 52)

            summaryColumn(
                title: "TODAY",
                miles: "\(todayMiles.formatted(.number.precision(.fractionLength(2)))) mi",
                value: (todayMiles * rate).formatted(.currency(code: "USD"))
            )
        }
        .padding(.vertical, 11)
        .background(MilliCardBackground(showGlow: true))
    }

    private func summaryColumn(title: String, miles: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(MilliColors.textSecondary)
            Text(miles)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
            Text(value)
                .font(MilliFont.bodySmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private var backgroundTrackingCard: some View {
        Button {
            locationManager.requestBackgroundPermission()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(MilliColors.cyanGlow.opacity(0.08))
                        .frame(width: 34, height: 34)
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Keep active trips recording in the background")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text("Optional • iOS will ask before upgrading location access")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
            .milliCard(padding: 11)
        }
        .buttonStyle(.plain)
    }

    private var currentTripMiles: Double {
        isScreenshotMode ? 18.64 : locationManager.distanceMiles
    }

    private func displayDuration(at date: Date) -> String {
        if isScreenshotMode {
            return "00:48:26"
        }

        guard locationManager.isTracking,
              let startedAt = locationManager.tripStartedAt
        else {
            return "00:00:00"
        }

        return formatDuration(max(date.timeIntervalSince(startedAt), 0))
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded(.down))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func updateMapCamera(animated: Bool) {
        let coordinates = displayedRoute

        let region: MKCoordinateRegion
        if !coordinates.isEmpty {
            region = mapRegion(for: coordinates)
        } else if let current = locationManager.lastLocation?.coordinate {
            region = MKCoordinateRegion(
                center: current,
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            )
        } else {
            return
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.45)) {
                mapPosition = .region(region)
            }
        } else {
            mapPosition = .region(region)
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

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.55, 0.010)
        let lonDelta = max((maxLon - minLon) * 1.55, 0.010)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

// MARK: - Mileage deduction rate

private enum MileageRate {
    /// IRS optional business standard mileage rates for 2026.
    /// Jan 1–Jun 30: $0.725/mi; Jul 1–Dec 31: $0.76/mi.
    static func businessRate(for date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard components.year == 2026 else {
            // The tax engine should ultimately own historical/future rates. For a
            // date outside this native build's 2026 contract, avoid inventing a
            // future rate and fall back to the last verified 2026 rate.
            return 0.76
        }

        if let month = components.month, month >= 7 {
            return 0.76
        }
        return 0.725
    }
}
