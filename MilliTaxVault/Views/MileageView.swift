import SwiftUI

// MARK: - MileageView
// Native mileage instrumentation matching the approved production reference.
// The overview uses a deterministic SwiftUI route panel instead of embedding MapKit
// so the financial cockpit remains stable in cold launches and CI screenshots.
// Production GPS tracking still belongs to LocationManager/MileageTrackerView.

struct MileageView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                trackingCard
                todaySummary
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
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
            HStack(spacing: 6) {
                Circle()
                    .fill(MilliColors.positive)
                    .frame(width: 7, height: 7)
                    .shadow(color: MilliColors.positive.opacity(0.55), radius: 4)

                Text("Tracking Active")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.positive)
            }
            .padding(.top, 11)

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("18.64")
                        .font(.custom("Sora-Regular", size: 38, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("mi")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Text("Current Trip")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(.top, 12)

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("00:48:26")
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
                    Text("$9.82")
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

            routePath

            startMarker
                .position(x: 36, y: 45)

            destinationMarker
                .position(x: 205, y: 118)

            currentMarker
                .position(x: 148, y: 184)
        }
        .frame(height: 246)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 5) {
                Circle().fill(MilliColors.positive).frame(width: 5, height: 5)
                Text("GPS LOCKED")
                    .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.40)))
            .padding(8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Active trip route overview. GPS locked.")
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
                context.stroke(path, with: .color(index % 3 == 0 ? secondary : tertiary), lineWidth: index % 3 == 0 ? 1.0 : 0.65)
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

    private var routePath: some View {
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
        HStack(spacing: 0) {
            summaryColumn(title: "THIS TRIP", miles: "18.64 mi", value: "$9.82")

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 1, height: 52)

            summaryColumn(title: "TODAY", miles: "126.37 mi", value: "$66.41")
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
}
