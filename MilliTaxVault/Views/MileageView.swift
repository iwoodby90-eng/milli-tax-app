import SwiftUI
import CoreLocation

// MARK: - MileageView
// Native mileage instrumentation matching the approved production reference.
// DEBUG visual-QA launches keep deterministic reference values, while normal app
// launches bind the same presentation directly to LocationManager.

struct MileageView: View {
    var onBack: () -> Void = {}

    @StateObject private var locationManager = LocationManager()

    private var isScreenshotMode: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["MILLI_SCREENSHOT_MODE"] == "1"
        #else
        false
        #endif
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
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "061018"), Color(hex: "07141D"), Color(hex: "041018")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            streetGrid
                .opacity(0.75)

            if isScreenshotMode {
                demoRoutePath
                demoMarkers
            } else if locationManager.routeCoordinates.count >= 2 {
                MileageLiveRouteCanvas(coordinates: locationManager.routeCoordinates)
                    .padding(12)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(MilliColors.cyanGlow.opacity(0.72))
                    Text(locationManager.isTracking ? "Waiting for GPS route…" : "Start a trip to build your route")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
        }
        .frame(height: 246)
        .overlay(alignment: .topTrailing) {
            gpsBadge
                .padding(8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(routeAccessibilityLabel)
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
        .background(Capsule().fill(Color.black.opacity(0.40)))
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
            return "Active trip route overview. GPS locked."
        }
        if locationManager.routeCoordinates.count >= 2 {
            return "Active mileage route with \(locationManager.routeCoordinates.count) recorded GPS points."
        }
        return locationManager.isTracking ? "Mileage tracking is waiting for a GPS route." : "No active mileage route."
    }

    private var streetGrid: some View {
        Canvas { context, size in
            let primary = Color(hex: "183446").opacity(0.65)
            let secondary = Color(hex: "253621").opacity(0.55)
            let tertiary = Color(hex: "102332").opacity(0.72)

            for index in 0..<10 {
                let y = size.height * (0.08 + CGFloat(index) * 0.095)
                var path = Path()
                path.move(to: CGPoint(x: -20, y: y + CGFloat(index % 2) * 8))
                path.addCurve(
                    to: CGPoint(x: size.width + 20, y: y - 18),
                    control1: CGPoint(x: size.width * 0.28, y: y - 14),
                    control2: CGPoint(x: size.width * 0.63, y: y + 11)
                )
                context.stroke(
                    path,
                    with: .color(index % 3 == 0 ? secondary : tertiary),
                    lineWidth: index % 3 == 0 ? 1.0 : 0.65
                )
            }

            for index in 0..<9 {
                let x = size.width * (0.05 + CGFloat(index) * 0.12)
                var path = Path()
                path.move(to: CGPoint(x: x - 20, y: -10))
                path.addCurve(
                    to: CGPoint(x: x + 38, y: size.height + 10),
                    control1: CGPoint(x: x + 22, y: size.height * 0.28),
                    control2: CGPoint(x: x - 18, y: size.height * 0.68)
                )
                context.stroke(path, with: .color(primary), lineWidth: index % 4 == 0 ? 1.0 : 0.6)
            }

            for index in 0..<5 {
                var diagonal = Path()
                diagonal.move(to: CGPoint(x: -15, y: size.height * (0.18 + CGFloat(index) * 0.18)))
                diagonal.addLine(to: CGPoint(x: size.width + 20, y: size.height * (0.06 + CGFloat(index) * 0.19)))
                context.stroke(diagonal, with: .color(Color(hex: "4B4522").opacity(0.42)), lineWidth: 0.7)
            }
        }
    }

    private var demoRoutePath: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                path.move(to: CGPoint(x: w * 0.14, y: h * 0.18))
                path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.29))
                path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.39))
                path.addLine(to: CGPoint(x: w * 0.51, y: h * 0.38))
                path.addLine(to: CGPoint(x: w * 0.63, y: h * 0.51))
                path.addCurve(
                    to: CGPoint(x: w * 0.70, y: h * 0.68),
                    control1: CGPoint(x: w * 0.69, y: h * 0.56),
                    control2: CGPoint(x: w * 0.61, y: h * 0.65)
                )
                path.addLine(to: CGPoint(x: w * 0.79, y: h * 0.77))
                path.addCurve(
                    to: CGPoint(x: w * 0.86, y: h * 0.52),
                    control1: CGPoint(x: w * 0.91, y: h * 0.73),
                    control2: CGPoint(x: w * 0.90, y: h * 0.62)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [MilliColors.cyanGlow, Color(hex: "16C8E9")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: MilliColors.cyanGlow.opacity(0.50), radius: 5)
        }
        .padding(.horizontal, 6)
    }

    private var demoMarkers: some View {
        GeometryReader { geo in
            ZStack {
                startMarker
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.18)
                destinationMarker
                    .position(x: geo.size.width * 0.63, y: geo.size.height * 0.51)
                currentMarker
                    .position(x: geo.size.width * 0.79, y: geo.size.height * 0.77)
            }
        }
    }

    private var startMarker: some View {
        ZStack {
            Circle()
                .fill(MilliColors.cyanGlow.opacity(0.18))
                .frame(width: 25, height: 25)
            Image(systemName: "location.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MilliColors.cyanGlow)
        }
    }

    private var destinationMarker: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "12303B"))
                .frame(width: 23, height: 23)
                .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.55), lineWidth: 1))
            Circle()
                .fill(MilliColors.cyanGlow)
                .frame(width: 7, height: 7)
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.32), radius: 5)
    }

    private var currentMarker: some View {
        ZStack {
            Circle()
                .fill(MilliColors.cyanGlow.opacity(0.12))
                .frame(width: 30, height: 30)
            Circle()
                .stroke(MilliColors.cyanGlow, lineWidth: 3)
                .frame(width: 19, height: 19)
            Circle()
                .fill(MilliColors.cyanGlow)
                .frame(width: 6, height: 6)
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.38), radius: 6)
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
}

// MARK: - Live route projection

private struct MileageLiveRouteCanvas: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Canvas { context, size in
            guard coordinates.count >= 2 else { return }

            let latitudes = coordinates.map(\.latitude)
            let longitudes = coordinates.map(\.longitude)
            guard let minLat = latitudes.min(),
                  let maxLat = latitudes.max(),
                  let minLon = longitudes.min(),
                  let maxLon = longitudes.max()
            else {
                return
            }

            let latSpan = max(maxLat - minLat, 0.000_01)
            let lonSpan = max(maxLon - minLon, 0.000_01)
            let inset: CGFloat = 10
            let drawableWidth = max(size.width - inset * 2, 1)
            let drawableHeight = max(size.height - inset * 2, 1)

            func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
                let xRatio = (coordinate.longitude - minLon) / lonSpan
                let yRatio = (coordinate.latitude - minLat) / latSpan
                return CGPoint(
                    x: inset + drawableWidth * CGFloat(xRatio),
                    y: inset + drawableHeight * CGFloat(1 - yRatio)
                )
            }

            var route = Path()
            route.move(to: point(for: coordinates[0]))
            for coordinate in coordinates.dropFirst() {
                route.addLine(to: point(for: coordinate))
            }

            context.stroke(
                route,
                with: .color(MilliColors.cyanGlow.opacity(0.20)),
                style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                route,
                with: .color(MilliColors.cyanGlow),
                style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
            )

            let start = point(for: coordinates[0])
            let current = point(for: coordinates[coordinates.count - 1])

            context.fill(
                Path(ellipseIn: CGRect(x: start.x - 5, y: start.y - 5, width: 10, height: 10)),
                with: .color(MilliColors.silverBright)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: current.x - 8, y: current.y - 8, width: 16, height: 16)),
                with: .color(MilliColors.cyanGlow.opacity(0.24))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: current.x - 4, y: current.y - 4, width: 8, height: 8)),
                with: .color(MilliColors.cyanGlow)
            )
        }
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
