import SwiftUI
import MapKit

// MARK: - MileageView
// Live mileage instrumentation matching the approved production reference.

struct MileageView: View {
    var onBack: () -> Void = {}

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
        span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
    )

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                trackingCard
                todaySummary
                recentTrips
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Mileage Tracking")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                HStack(spacing: 6) {
                    Circle().fill(MilliColors.positive).frame(width: 6, height: 6)
                    Text("Tracking Active")
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(MilliColors.positive)
                }
            }

            Spacer()

            Text("LIVE")
                .font(MilliFont.sectionLabel)
                .tracking(0.8)
                .foregroundStyle(MilliColors.cyanGlow)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(MilliColors.cyanGlow.opacity(0.10)))
        }
        .padding(.bottom, 2)
    }

    private var trackingCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE TRIP MILES")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(MilliColors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("18.64")
                            .font(.custom("Sora-ExtraBold", size: 34, relativeTo: .largeTitle))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("mi")
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text("DEDUCTION")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("$9.82")
                        .font(MilliFont.numericMedium)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                }
            }
            .padding(14)

            Divider().overlay(Color.white.opacity(0.06))

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DURATION")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("00:48:26")
                        .font(MilliFont.numericSmall)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(MilliColors.positive).frame(width: 6, height: 6)
                    Text("GPS locked")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            map
        }
        .background(MilliCardBackground(showGlow: true))
    }

    private var map: some View {
        ZStack {
            Map(coordinateRegion: .constant(region))
                .frame(height: 260)
                .colorScheme(.dark)
                .allowsHitTesting(false)

            // Visual route overlay used only as presentation on top of the live MapKit surface.
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: w * 0.12, y: h * 0.78))
                    path.addCurve(
                        to: CGPoint(x: w * 0.42, y: h * 0.56),
                        control1: CGPoint(x: w * 0.20, y: h * 0.74),
                        control2: CGPoint(x: w * 0.32, y: h * 0.61)
                    )
                    path.addCurve(
                        to: CGPoint(x: w * 0.66, y: h * 0.44),
                        control1: CGPoint(x: w * 0.52, y: h * 0.52),
                        control2: CGPoint(x: w * 0.57, y: h * 0.42)
                    )
                    path.addCurve(
                        to: CGPoint(x: w * 0.86, y: h * 0.22),
                        control1: CGPoint(x: w * 0.73, y: h * 0.43),
                        control2: CGPoint(x: w * 0.80, y: h * 0.30)
                    )
                }
                .stroke(MilliColors.cyanGlow, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .shadow(color: MilliColors.cyanGlow.opacity(0.5), radius: 5)

                Circle()
                    .fill(MilliColors.cyanGlow)
                    .frame(width: 10, height: 10)
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.78)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .position(x: geo.size.width * 0.86, y: geo.size.height * 0.22)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Label("Customer", systemImage: "location.fill")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.62)))
                .padding(10)
        }
    }

    private var todaySummary: some View {
        HStack(spacing: MilliSpacing.gridGap) {
            summaryTile(title: "THIS TRIP", miles: "18.64 mi", value: "$9.82")
            summaryTile(title: "TODAY", miles: "126.37 mi", value: "$66.41")
        }
    }

    private func summaryTile(title: String, miles: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(MilliColors.textSecondary)
            Text(miles)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
            Text(value)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.cyanGlow)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }

    private var recentTrips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT TRIPS")
                    .sectionHeaderStyle()
                Spacer()
                Text("View All")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            recentTrip("Spark Driver", "12.4 mi", "$6.55", "Today • 7:18 AM")
            recentTrip("DoorDash", "8.7 mi", "$4.59", "Yesterday • 6:42 PM")
        }
        .padding(.top, 2)
    }

    private func recentTrip(_ platform: String, _ miles: String, _ deduction: String, _ date: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(date)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(miles)
                    .font(MilliFont.numericSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(deduction)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.positive)
            }
        }
        .milliCard(padding: 11)
    }
}
