import SwiftUI
import Charts

// MARK: - MilliRenderKit
// Shared presentation primitives for Milli's obsidian/chrome/cyan reference
// language: ambient canvas, micro labels, gauges, stat tiles, trend charts and
// the companion banner. Every figure-bearing primitive accepts an optional
// value so an unconnected account renders an honest empty state instead of a
// fabricated number.

// MARK: Ambient canvas

/// Obsidian canvas with the reference's cyan horizon sweep and corner vignette.
struct MilliAmbientBackground: View {
    var body: some View {
        ZStack {
            MilliColors.obsidian

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.92, y: 0.04),
                startRadius: 0,
                endRadius: 320
            )

            RadialGradient(
                colors: [Color(hex: "0D2630").opacity(0.55), Color.clear],
                center: UnitPoint(x: 0.08, y: 0.72),
                startRadius: 0,
                endRadius: 380
            )

            MilliHorizonSweep()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Two thin light arcs echoing the reference's background light streaks.
private struct MilliHorizonSweep: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                sweep(startY: height * 0.62, controlY: height * 0.34, width: width)
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, MilliColors.cyanGlow.opacity(0.22), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 1.2)

                sweep(startY: height * 0.74, controlY: height * 0.50, width: width)
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, MilliColors.deepCyan.opacity(0.16), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 0.8
                    )
                    .blur(radius: 2.0)
            }
        }
    }

    private func sweep(startY: CGFloat, controlY: CGFloat, width: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: -width * 0.1, y: startY))
            path.addQuadCurve(
                to: CGPoint(x: width * 1.1, y: startY - 40),
                control: CGPoint(x: width * 0.5, y: controlY)
            )
        }
    }
}

// MARK: Micro label

/// Uppercase tracked section label used above every figure in the reference.
struct MilliMicroLabel: View {
    let text: String
    var accent: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(MilliFont.sectionLabel)
            .tracking(1.15)
            .foregroundStyle(accent ? MilliColors.cyanGlow : MilliColors.textLabel)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

// MARK: Gauge ring

/// Progress ring with the reference's glowing cyan sweep. `progress` is nil
/// when the underlying figure is not yet sourced, which renders the track only.
struct MilliGaugeRing<Center: View>: View {
    var progress: Double?
    var size: CGFloat = 78
    var lineWidth: CGFloat = 7
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

            if let progress {
                Circle()
                    .trim(from: 0, to: max(0, min(progress, 1)))
                    .stroke(
                        AngularGradient(
                            colors: [MilliColors.deepCyan, MilliColors.cyanGlow, MilliColors.cyanGlow],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 7)
            }

            center()
        }
        .frame(width: size, height: size)
    }
}

extension MilliGaugeRing where Center == MilliGaugeRingLabel {
    init(progress: Double?, value: String, caption: String, size: CGFloat = 78, lineWidth: CGFloat = 7) {
        self.init(progress: progress, size: size, lineWidth: lineWidth) {
            MilliGaugeRingLabel(value: value, caption: caption)
        }
    }
}

/// Default gauge centre: a figure over a two-word caption.
struct MilliGaugeRingLabel: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.custom("Sora-SemiBold", size: 17))
                .monospacedDigit()
                .milliFigure(value)
            Text(caption.uppercased())
                .font(.custom("Inter-SemiBold", size: 7.5))
                .tracking(0.7)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: Stat tile

/// Micro label, figure and caption stacked the way the reference groups
/// secondary metrics into a row of three.
struct MilliStatTile: View {
    let label: String
    let value: String
    var caption: String?
    var accent: Color = MilliColors.textPrimary
    var icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MilliMicroLabel(text: label)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliPlaceholder.isPlaceholder(value) ? MilliColors.textTertiary : accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow.opacity(0.75))
                }
            }

            if let caption {
                Text(caption)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            MilliPlaceholder.isPlaceholder(value)
                ? Text("\(label), unavailable")
                : Text("\(label), \(value)")
        )
    }
}

// MARK: Trend chart

/// A single point on a Milli projection or balance history series.
struct MilliTrendPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Cyan line-and-area chart used for balance history and forecasts. With no
/// points it draws the reference's grid and an explicit empty message instead
/// of an invented curve.
struct MilliTrendChart: View {
    let points: [MilliTrendPoint]
    var height: CGFloat = 108
    var emptyMessage: String = "Connect an account to build this history"
    var showsAxes: Bool = false

    var body: some View {
        Group {
            if points.count >= 2 {
                chart
            } else {
                empty
            }
        }
        .frame(height: height)
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.28), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round))
            .foregroundStyle(MilliColors.cyanGlow)
        }
        .chartXAxis {
            if showsAxes {
                AxisMarks(preset: .aligned) { _ in
                    AxisValueLabel()
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
        }
        .chartYAxis {
            if showsAxes {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                    AxisValueLabel()
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
        }
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
    }

    private var empty: some View {
        ZStack {
            MilliChartGrid()
            Text(emptyMessage)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }
}

/// Faint plot grid shown behind empty charts so the card keeps its structure.
private struct MilliChartGrid: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            Path { path in
                for column in 0...4 {
                    let x = width * CGFloat(column) / 4
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for row in 0...3 {
                    let y = height * CGFloat(row) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.045), lineWidth: 0.6)
        }
    }
}

// MARK: Companion banner

/// The Milli robot with a short speech bubble, as the reference places it
/// beside the wordmark. Copy is guidance only and never states a figure.
struct MilliCompanionBanner: View {
    let title: String
    let message: String
    var imageName: String = "milli-ai-robot"

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 11, relativeTo: .caption))
                    .foregroundStyle(MilliColors.cyanGlow)
                Text(message)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.22), lineWidth: 0.7)
                    )
            )
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: Action pair

/// Two-up action bar matching the reference's "Add to Vault / Quick Estimate"
/// footer.
struct MilliActionPair: View {
    let primaryTitle: String
    let primaryCaption: String
    let primaryIcon: String
    let primaryAction: () -> Void
    let secondaryTitle: String
    let secondaryCaption: String
    let secondaryIcon: String
    let secondaryAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            action(
                title: primaryTitle,
                caption: primaryCaption,
                icon: primaryIcon,
                perform: primaryAction
            )

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 1, height: 42)

            action(
                title: secondaryTitle,
                caption: secondaryCaption,
                icon: secondaryIcon,
                perform: secondaryAction
            )
        }
        .padding(.vertical, 12)
        .background(MilliCardBackground(showGlow: true))
    }

    private func action(
        title: String,
        caption: String,
        icon: String,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(MilliColors.cyanGlow.opacity(0.10))
                            .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.28), lineWidth: 0.7))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(caption)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(caption)")
    }
}

// MARK: - MilliAccountCard
// Brushed-chrome Milli account card face. Shows only verified account details;
// an unlinked card renders masked placeholders instead of invented numbers.

struct MilliAccountCard: View {
    var institution: String?
    var mask: String?
    var isLive: Bool = false

    private var chromeFace: LinearGradient {
        LinearGradient(
            colors: [
                MilliColors.chromeDeep,
                MilliColors.chromeDark,
                MilliColors.chromeMid.opacity(0.9),
                MilliColors.chromeDark,
                Color.black.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(chromeFace)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.clear, MilliColors.cyanGlow.opacity(0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.screen)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    MilliWordmark(fontSize: 21, tracking: 5)
                    Spacer()
                    Text(isLive ? "LIVE" : "NOT LINKED")
                        .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                        .tracking(1.1)
                        .foregroundStyle(isLive ? MilliColors.cyanGlow : MilliColors.chromeLight.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.35))
                                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.6))
                        )
                }

                Spacer(minLength: 10)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.chromeLight, MilliColors.chromeMid, MilliColors.chromeLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 27)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.black.opacity(0.25), lineWidth: 0.7)
                    )

                Spacer(minLength: 10)

                Text("••••  ••••  ••••  \(mask ?? "••••")")
                    .font(.custom("Sora-SemiBold", size: 17, relativeTo: .title3))
                    .tracking(1.6)
                    .foregroundStyle(MilliColors.chromeWhite)

                Spacer(minLength: 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACCOUNT")
                            .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                            .tracking(1)
                            .foregroundStyle(MilliColors.chromeLight.opacity(0.65))
                        Text(institution ?? "Connect a bank to activate")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.chromeWhite.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer()
                    Text("VISA")
                        .font(.custom("Sora-Bold", size: 15, relativeTo: .headline))
                        .tracking(1.4)
                        .foregroundStyle(MilliColors.chromeWhite.opacity(0.9))
                }
            }
            .padding(18)
        }
        .frame(height: 196)
        .shadow(color: Color.black.opacity(0.6), radius: 18, y: 10)
        .shadow(color: MilliColors.cyanGlow.opacity(isLive ? 0.18 : 0.06), radius: 22, y: 0)
        .accessibilityElement(children: .combine)
    }
}
