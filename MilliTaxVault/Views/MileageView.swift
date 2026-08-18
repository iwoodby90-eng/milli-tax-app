import SwiftUI
import CoreLocation
import MapKit

// MARK: - MileageView
// Native mileage cockpit with three entry paths:
// 1) explicit GPS Start/Stop tracking,
// 2) address-driven navigation that starts mileage tracking with the route,
// 3) manual trip entry for trips that were missed.
//
// Completed trips persist to an offline-first mileage log immediately. The
// production backend migration mirrors this record shape for authenticated sync.

struct MileageView: View {
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
    @State private var plannedRouteCoordinates: [CLLocationCoordinate2D] = []
    @State private var plannedRouteDistanceMiles: Double = 0
    @State private var plannedRouteETA: TimeInterval = 0
    @State private var isSearchingRoute = false
    @State private var routeMessage: String?
    @State private var showManualTrip = false
    @State private var showMileageLog = false
    @State private var showNavigationSettings = false

    @AppStorage("milliAcceptNavigationRequests") private var acceptNavigationRequests = true

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

    private var displayedRecordedRoute: [CLLocationCoordinate2D] {
        isScreenshotMode ? Self.demoRouteCoordinates : locationManager.routeCoordinates
    }

    private var displayedCurrentCoordinate: CLLocationCoordinate2D? {
        if let last = displayedRecordedRoute.last {
            return last
        }
        return locationManager.lastLocation?.coordinate
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                quickActions
                destinationPlanner
                trackingCard
                todaySummary
                recentMileageLog

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
            guard locationManager.routeCoordinates.isEmpty,
                  plannedRouteCoordinates.isEmpty else { return }
            updateMapCamera(animated: true)
        }
        .sheet(isPresented: $showManualTrip) {
            ManualMileageTripSheet { record in
                mileageLog.add(record)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMileageLog) {
            MileageLogSheet(store: mileageLog)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNavigationSettings) {
            NavigationCaptureSettingsView(acceptNavigationRequests: $acceptNavigationRequests)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(
            "Mileage Tracking",
            isPresented: Binding(
                get: { locationManager.errorMessage != nil || routeMessage != nil },
                set: {
                    if !$0 {
                        locationManager.errorMessage = nil
                        routeMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                locationManager.errorMessage = nil
                routeMessage = nil
            }
        } message: {
            Text(locationManager.errorMessage ?? routeMessage ?? "")
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

                Button {
                    showMileageLog = true
                } label: {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open mileage log")
            }

            Text("Mileage Tracking")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(height: 40)
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            quickActionButton(
                title: "Add Trip",
                icon: "plus.circle.fill",
                color: MilliColors.cyanGlow
            ) {
                showManualTrip = true
            }

            quickActionButton(
                title: "Mileage Log",
                icon: "list.bullet",
                color: MilliColors.silverBright
            ) {
                showMileageLog = true
            }

            quickActionButton(
                title: "Navigation",
                icon: "location.north.circle.fill",
                color: MilliColors.deepCyan
            ) {
                showNavigationSettings = true
            }
        }
    }

    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(MilliCardBackground(showGlow: false))
        }
        .buttonStyle(.plain)
    }

    private var destinationPlanner: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("PLAN + TRACK A ROUTE")
                    .sectionHeaderStyle()
                Spacer()
                if isSearchingRoute {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MilliColors.cyanGlow)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)

                TextField("Enter delivery or destination address", text: $destinationText)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await planRoute() }
                    }

                if !destinationText.isEmpty {
                    Button {
                        clearPlannedRoute()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
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

            if let destinationItem, !plannedRouteCoordinates.isEmpty {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(destinationItem.name ?? destinationText)
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(MilliColors.textPrimary)
                            .lineLimit(1)
                        Text("\(plannedRouteDistanceMiles.formatted(.number.precision(.fractionLength(1)))) mi • \(formattedETA(plannedRouteETA))")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                    }

                    Spacer(minLength: 6)

                    Button {
                        startNavigationTrip()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "location.north.fill")
                            Text("NAVIGATE")
                        }
                        .font(.custom("Sora-SemiBold", size: 10, relativeTo: .caption))
                        .foregroundStyle(MilliColors.blackGlass)
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(Capsule().fill(MilliColors.cyanGlow))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    Task { await planRoute() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Build Route")
                    }
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MilliColors.textTertiary : MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
                .disabled(destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearchingRoute)
            }
        }
        .milliCard(padding: 12)
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
                saveAndStopCurrentTrip()
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
            if plannedRouteCoordinates.count >= 2 {
                MapPolyline(coordinates: plannedRouteCoordinates)
                    .stroke(MilliColors.silverBright.opacity(0.18), lineWidth: 10)
                MapPolyline(coordinates: plannedRouteCoordinates)
                    .stroke(MilliColors.deepCyan.opacity(0.92), style: StrokeStyle(lineWidth: 4, dash: [8, 5]))
            }

            if displayedRecordedRoute.count >= 2 {
                MapPolyline(coordinates: displayedRecordedRoute)
                    .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 10)
                MapPolyline(coordinates: displayedRecordedRoute)
                    .stroke(MilliColors.cyanGlow, lineWidth: 4)
            }

            if let start = displayedRecordedRoute.first {
                Annotation("Trip start", coordinate: start) {
                    startMapMarker
                }
            }

            if let destinationItem {
                Annotation("Destination", coordinate: destinationItem.placemark.coordinate) {
                    destinationMapMarker
                }
            }

            if let current = displayedCurrentCoordinate {
                Annotation("Current location", coordinate: current) {
                    currentMapMarker
                }
            }
        }
        .frame(height: 260)
        .mapStyle(.standard(elevation: .realistic))
        .overlay {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.16),
                    Color.clear,
                    Color(hex: "001A22").opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            gpsBadge.padding(8)
        }
        .overlay(alignment: .bottomTrailing) {
            if displayedCurrentCoordinate != nil || !displayedRecordedRoute.isEmpty || !plannedRouteCoordinates.isEmpty {
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
            if displayedRecordedRoute.isEmpty,
               displayedCurrentCoordinate == nil,
               plannedRouteCoordinates.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(MilliColors.cyanGlow.opacity(0.82))
                    Text(locationManager.isTracking ? "Waiting for GPS route…" : "Enter a destination or start tracking")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
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

    private var destinationMapMarker: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.86))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(MilliColors.positive, lineWidth: 2))
            Image(systemName: "mappin")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MilliColors.positive)
        }
        .shadow(color: MilliColors.positive.opacity(0.35), radius: 6)
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
        case .notDetermined: return "GPS READY"
        case .denied, .restricted: return "GPS OFF"
        case .authorizedWhenInUse, .authorizedAlways: return "ACQUIRING"
        @unknown default: return "GPS"
        }
    }

    private var routeAccessibilityLabel: String {
        if isScreenshotMode {
            return "Active trip on an interactive map. GPS locked."
        }
        if locationManager.routeCoordinates.count >= 2 {
            return "Interactive mileage map with \(locationManager.routeCoordinates.count) recorded GPS points."
        }
        if !plannedRouteCoordinates.isEmpty {
            return "Interactive mileage map showing a planned route to \(destinationItem?.name ?? destinationText)."
        }
        if locationManager.lastLocation != nil {
            return "Interactive mileage map centered on the current location."
        }
        return locationManager.isTracking ? "Mileage map is waiting for a GPS route." : "Interactive mileage map ready for a trip."
    }

    private var todaySummary: some View {
        let tripMiles = currentTripMiles
        let storedToday = mileageLog.totalMiles(on: Date())
        let todayMiles = isScreenshotMode ? 126.37 : storedToday + (locationManager.isTracking ? tripMiles : 0)
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

    private var recentMileageLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT MILEAGE LOG")
                    .sectionHeaderStyle()
                Spacer()
                Button("View All") { showMileageLog = true }
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .buttonStyle(.plain)
            }

            if mileageLog.records.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "car.side.fill")
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Completed and manually entered business trips will appear here.")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .milliCard(padding: 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mileageLog.records.prefix(3).enumerated()), id: \.element.id) { index, record in
                        HStack(spacing: 9) {
                            Image(systemName: record.source.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(record.source == .manual ? MilliColors.warning : MilliColors.cyanGlow)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.white.opacity(0.035)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.platform ?? record.businessPurpose ?? "Business Trip")
                                    .font(MilliFont.bodyMedium)
                                    .foregroundStyle(MilliColors.textPrimary)
                                    .lineLimit(1)
                                Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.textTertiary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(record.distanceMiles.formatted(.number.precision(.fractionLength(1)))) mi")
                                    .font(MilliFont.numericSmall)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(record.deductionAmount.formatted(.currency(code: "USD")))
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.positive)
                            }
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)

                        if index < min(mileageLog.records.count, 3) - 1 {
                            Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 48)
                        }
                    }
                }
                .background(MilliCardBackground(showGlow: true))
            }
        }
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
        if isScreenshotMode { return "00:48:26" }
        guard locationManager.isTracking,
              let startedAt = locationManager.tripStartedAt else {
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

    private func formattedETA(_ interval: TimeInterval) -> String {
        let minutes = max(Int((interval / 60).rounded()), 1)
        if minutes >= 60 {
            return "\(minutes / 60) hr \(minutes % 60) min"
        }
        return "\(minutes) min"
    }

    @MainActor
    private func planRoute() async {
        let query = destinationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        guard let originCoordinate = locationManager.lastLocation?.coordinate else {
            if !locationManager.canTrackLocation {
                locationManager.requestPermission()
                routeMessage = "Allow location access, then try the route again so Milli can calculate directions from your current position."
            } else {
                locationManager.refreshCurrentLocation()
                routeMessage = "Milli is acquiring your current location. Try the route again in a moment."
            }
            return
        }

        isSearchingRoute = true
        defer { isSearchingRoute = false }

        do {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = query
            searchRequest.region = MKCoordinateRegion(
                center: originCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.2, longitudeDelta: 1.2)
            )

            let searchResponse = try await MKLocalSearch(request: searchRequest).start()
            guard let destination = searchResponse.mapItems.first else {
                routeMessage = "Milli couldn't find that destination. Try a fuller street address or place name."
                return
            }

            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
            directionsRequest.destination = destination
            directionsRequest.transportType = .automobile
            directionsRequest.requestsAlternateRoutes = false

            let directionsResponse = try await MKDirections(request: directionsRequest).calculate()
            guard let route = directionsResponse.routes.first else {
                routeMessage = "No driving route was available for that destination."
                return
            }

            destinationItem = destination
            plannedRouteCoordinates = route.polyline.coordinateArray
            plannedRouteDistanceMiles = route.distance / 1_609.344
            plannedRouteETA = route.expectedTravelTime
            updateMapCamera(animated: true)
        } catch {
            routeMessage = "Milli couldn't build that route right now. Check the destination and your connection, then try again."
        }
    }

    private func startNavigationTrip() {
        guard destinationItem != nil, !plannedRouteCoordinates.isEmpty else { return }
        locationManager.startTracking()
        updateMapCamera(animated: true)
    }

    private func clearPlannedRoute() {
        destinationText = ""
        destinationItem = nil
        plannedRouteCoordinates = []
        plannedRouteDistanceMiles = 0
        plannedRouteETA = 0
        updateMapCamera(animated: true)
    }

    private func saveAndStopCurrentTrip() {
        guard locationManager.isTracking else { return }

        let endedAt = Date()
        let startedAt = locationManager.tripStartedAt ?? endedAt
        let miles = locationManager.distanceMiles
        let route = locationManager.routeCoordinates
        let destinationName = destinationItem?.name
        let destinationCoordinate = destinationItem?.placemark.coordinate
        let rate = MileageRate.businessRate(for: startedAt)

        locationManager.stopTracking()

        guard miles > 0.001 else {
            clearPlannedRoute()
            return
        }

        let record = MileageTripRecord(
            id: UUID(),
            source: destinationItem == nil ? .gps : .navigation,
            platform: nil,
            businessPurpose: destinationName.map { "Route to \($0)" } ?? "Business mileage",
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMiles: miles,
            deductionRate: rate,
            startAddress: nil,
            endAddress: destinationName,
            startCoordinate: route.first.map(MileageCoordinate.init),
            endCoordinate: destinationCoordinate.map(MileageCoordinate.init) ?? route.last.map(MileageCoordinate.init),
            routePoints: route.map(MileageCoordinate.init),
            navigationExternalID: nil,
            syncState: .pending
        )

        mileageLog.add(record)
        clearPlannedRoute()
        locationManager.resetCurrentTrip()
    }

    private func updateMapCamera(animated: Bool) {
        let allCoordinates = plannedRouteCoordinates.isEmpty
            ? displayedRecordedRoute
            : plannedRouteCoordinates + displayedRecordedRoute

        let region: MKCoordinateRegion
        if !allCoordinates.isEmpty {
            region = mapRegion(for: allCoordinates)
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

// MARK: - Persistent mileage log

enum MileageTripSource: String, Codable {
    case gps
    case manual
    case navigation

    var icon: String {
        switch self {
        case .gps: return "location.fill"
        case .manual: return "square.and.pencil"
        case .navigation: return "location.north.fill"
        }
    }
}

enum MileageSyncState: String, Codable {
    case pending
    case synced
    case failed
}

struct MileageCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
}

struct MileageTripRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let source: MileageTripSource
    let platform: String?
    let businessPurpose: String?
    let startedAt: Date
    let endedAt: Date
    let distanceMiles: Double
    let deductionRate: Double
    let startAddress: String?
    let endAddress: String?
    let startCoordinate: MileageCoordinate?
    let endCoordinate: MileageCoordinate?
    let routePoints: [MileageCoordinate]
    let navigationExternalID: String?
    var syncState: MileageSyncState

    var deductionAmount: Double {
        distanceMiles * deductionRate
    }
}

@MainActor
final class MileageLogStore: ObservableObject {
    @Published private(set) var records: [MileageTripRecord] = []

    private let fileURL: URL

    init() {
        let fileManager = FileManager.default
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directory = supportURL.appendingPathComponent("Milli", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("mileage-log.json")
        load()
    }

    func add(_ record: MileageTripRecord) {
        records.removeAll { $0.id == record.id }
        records.append(record)
        records.sort { $0.startedAt > $1.startedAt }
        persist()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persist()
    }

    func totalMiles(on date: Date) -> Double {
        records
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: date) }
            .reduce(0) { $0 + $1.distanceMiles }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MileageTripRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded.sorted { $0.startedAt > $1.startedAt }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

// MARK: - Manual Trip Entry

private struct ManualMileageTripSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var tripDate = Date()
    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var milesText = ""
    @State private var purpose = ""
    @State private var selectedPlatform = "Other / Business"

    let onSave: (MileageTripRecord) -> Void

    private let platforms = [
        "Amazon Flex", "Spark Driver", "Uber", "Lyft", "DoorDash",
        "Grubhub", "Instacart", "Roadie", "Shipt", "Other / Business"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MANUAL MILEAGE ENTRY")
                                .sectionHeaderStyle()
                            Text("Add a business trip that wasn't captured automatically.")
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textSecondary)
                        }

                        DatePicker("Trip date", selection: $tripDate)
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(MilliColors.textPrimary)
                            .tint(MilliColors.cyanGlow)
                            .milliCard(padding: 12)

                        VStack(alignment: .leading, spacing: 7) {
                            Text("PLATFORM / PURPOSE")
                                .sectionHeaderStyle()
                            Picker("Platform", selection: $selectedPlatform) {
                                ForEach(platforms, id: \.self) { platform in
                                    Text(platform).tag(platform)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(MilliColors.cyanGlow)

                            TextField("Business purpose (optional)", text: $purpose)
                                .mileageFieldStyle()
                        }
                        .milliCard(padding: 12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("TRIP DETAILS")
                                .sectionHeaderStyle()
                            TextField("Starting address (optional)", text: $startAddress)
                                .mileageFieldStyle()
                            TextField("Destination address (optional)", text: $endAddress)
                                .mileageFieldStyle()
                            TextField("Business miles", text: $milesText)
                                .keyboardType(.decimalPad)
                                .mileageFieldStyle()
                        }
                        .milliCard(padding: 12)

                        if let miles = parsedMiles {
                            HStack {
                                Text("Estimated deduction")
                                    .font(MilliFont.bodySmall)
                                    .foregroundStyle(MilliColors.textSecondary)
                                Spacer()
                                Text((miles * MileageRate.businessRate(for: tripDate)).formatted(.currency(code: "USD")))
                                    .font(MilliFont.numericSmall)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.positive)
                            }
                            .milliCard(padding: 12)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? MilliColors.cyanGlow : MilliColors.textTertiary)
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var parsedMiles: Double? {
        let normalized = milesText.replacingOccurrences(of: ",", with: "")
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool { parsedMiles != nil }

    private func save() {
        guard let miles = parsedMiles else { return }
        let rate = MileageRate.businessRate(for: tripDate)
        let record = MileageTripRecord(
            id: UUID(),
            source: .manual,
            platform: selectedPlatform == "Other / Business" ? nil : selectedPlatform,
            businessPurpose: purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : purpose,
            startedAt: tripDate,
            endedAt: tripDate,
            distanceMiles: miles,
            deductionRate: rate,
            startAddress: startAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : startAddress,
            endAddress: endAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : endAddress,
            startCoordinate: nil,
            endCoordinate: nil,
            routePoints: [],
            navigationExternalID: nil,
            syncState: .pending
        )
        onSave(record)
        dismiss()
    }
}

private extension View {
    func mileageFieldStyle() -> some View {
        self
            .font(MilliFont.bodyMedium)
            .foregroundStyle(MilliColors.textPrimary)
            .tint(MilliColors.cyanGlow)
            .padding(.horizontal, 11)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.035))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                    }
            )
    }
}

// MARK: - Mileage Log

private struct MileageLogSheet: View {
    @ObservedObject var store: MileageLogStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                if store.records.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "car.side")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(MilliColors.cyanGlow)
                        Text("No mileage trips yet")
                            .font(MilliFont.headlineSmall)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("Tracked and manually entered business trips will be stored here.")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                } else {
                    List {
                        ForEach(store.records) { record in
                            HStack(spacing: 10) {
                                Image(systemName: record.source.icon)
                                    .foregroundStyle(MilliColors.cyanGlow)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.platform ?? record.businessPurpose ?? "Business Trip")
                                        .font(MilliFont.bodyMedium)
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(MilliFont.caption)
                                        .foregroundStyle(MilliColors.textTertiary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(record.distanceMiles.formatted(.number.precision(.fractionLength(1)))) mi")
                                        .font(MilliFont.numericSmall)
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Text(record.deductionAmount.formatted(.currency(code: "USD")))
                                        .font(MilliFont.caption)
                                        .foregroundStyle(MilliColors.positive)
                                }
                            }
                            .listRowBackground(MilliColors.cardBackground)
                        }
                        .onDelete(perform: store.delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Mileage Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Navigation Capture Settings

private struct NavigationCaptureSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var acceptNavigationRequests: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("DRIVER APP HANDOFF")
                                .sectionHeaderStyle()
                            Text("Use Milli when a navigation route is handed off to it.")
                                .font(.custom("Sora-Bold", size: 23, relativeTo: .title2))
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("When the operating system or a driver app sends a supported navigation request to Milli, the destination can be loaded into this Mileage screen and tracking can begin with the route.")
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Toggle(isOn: $acceptNavigationRequests) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Accept navigation routes")
                                    .font(MilliFont.bodyMedium)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text("Keep incoming navigation handoff enabled")
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                        }
                        .tint(MilliColors.cyanGlow)
                        .milliCard(padding: 12)

                        VStack(alignment: .leading, spacing: 7) {
                            Label("Regional iOS support", systemImage: "globe.americas.fill")
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("Whether Milli can be selected as the system-wide default navigation app depends on Apple's regional Default Navigation availability and the driver app's handoff behavior. You can always type a destination directly in Milli and track it here.")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .milliCard(padding: 12)
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helpers

private extension MKPolyline {
    var coordinateArray: [CLLocationCoordinate2D] {
        guard pointCount > 0 else { return [] }
        var coordinates = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: pointCount
        )
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

private enum MileageRate {
    /// IRS optional business standard mileage rates for 2026.
    /// Jan 1–Jun 30: $0.725/mi; Jul 1–Dec 31: $0.76/mi.
    static func businessRate(for date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard components.year == 2026 else {
            return 0.76
        }

        if let month = components.month, month >= 7 {
            return 0.76
        }
        return 0.725
    }
}
