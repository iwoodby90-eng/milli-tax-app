import SwiftUI
import Charts

// MARK: - WealthOverviewView
// Canonical wealth hub. One strong portfolio hero, a quiet destination rail and
// consolidated planning surfaces replace the previous grid of independent cards.
// Reference values are restricted to DEBUG screenshot mode so production never
// presents fabricated balances as user data.

struct WealthOverviewView: View {
    var onBack: () -> Void = {}
    var navigate: ((ActiveScreen) -> Void)? = nil

    private static var isVisualFixtureMode: Bool {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        return processInfo.environment["MILLI_SCREENSHOT_MODE"] == "1"
            || processInfo.arguments.contains("-milliScreenshotMode")
        #else
        return false
        #endif
    }

    private var model: WealthOverviewModel? {
        Self.isVisualFixtureMode ? .reference : nil
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                header
                portfolioHero
                destinationRail
                allocationAndProjection
                goalsAndPlanning
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(
            ZStack {
                MilliColors.background.ignoresSafeArea()
                RadialGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.045), Color.clear],
                    center: UnitPoint(x: 0.82, y: 0.12),
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
        )
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text("Wealth")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("BUILD · PLAN · GROW")
                    .font(MilliFont.caption)
                    .tracking(1.45)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            Button { navigate?(.treeOfLife) } label: {
                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.025)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Tree of Life")
        }
    }

    // MARK: Portfolio hero

    private var portfolioHero: some View {
        ZStack(alignment: .topLeading) {
            Image("wealth-hero")
                .resizable()
                .scaledToFill()
                .opacity(0.20)
                .clipped()

            LinearGradient(
                colors: [Color(hex: "0B141A").opacity(0.48), Color.black.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TOTAL NET WORTH")
                        .font(MilliFont.sectionLabel)
                        .tracking(1.15)
                        .foregroundStyle(MilliColors.textSecondary)
                    Spacer()
                    Text(model == nil ? "UNAVAILABLE" : "PREVIEW")
                        .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                        .tracking(0.7)
                        .foregroundStyle(model == nil ? MilliColors.textTertiary : MilliColors.cyanGlow)
                }

                if let model {
                    Text(model.totalNetWorth.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(.custom("Sora-Bold", size: 40, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(model.monthlyChange.formatted(.currency(code: "USD").sign(strategy: .always()).precision(.fractionLength(0)))) this month")
                            .font(MilliFont.bodySmall)
                    }
                    .foregroundStyle(MilliColors.positive)

                    Chart(model.trend) { point in
                        AreaMark(
                            x: .value("Month", point.month),
                            y: .value("Net Worth", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MilliColors.cyanGlow.opacity(0.20), MilliColors.cyanGlow.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)

                        LineMark(
                            x: .value("Month", point.month),
                            y: .value("Net Worth", point.value)
                        )
                        .foregroundStyle(MilliColors.cyanGlow)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel()
                                .foregroundStyle(MilliColors.textTertiary)
                                .font(MilliFont.caption)
                        }
                    }
                    .frame(height: 92)
                } else {
                    Text("—")
                        .font(.custom("Sora-Bold", size: 40, relativeTo: .largeTitle))
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("Connect and classify your financial accounts to build your live wealth view. Milli will not invent portfolio values.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

                    Button { navigate?(.accounts) } label: {
                        HStack(spacing: 6) {
                            Text("Review accounts")
                            Image(systemName: "arrow.right")
                        }
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(MilliColors.cyanGlow)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .padding(17)
        }
        .frame(maxWidth: .infinity, minHeight: model == nil ? 205 : 238)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), MilliColors.cyanGlow.opacity(0.18), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }

    // MARK: Destination rail

    private var destinationRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEALTH TOOLS")
                .sectionHeaderStyle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    destinationButton("Investing", "chart.xyaxis.line", .investing)
                    destinationButton("Retirement", "hourglass", .retirement)
                    destinationButton("Savings", "banknote", .savings)
                    destinationButton("Tree of Life", "tree", .treeOfLife)
                    destinationButton("Reports", "doc.text", .reports)
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func destinationButton(_ title: String, _ icon: String, _ destination: ActiveScreen) -> some View {
        Button { navigate?(destination) } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.025))
                        .frame(width: 42, height: 42)
                        .overlay { Circle().stroke(Color.white.opacity(0.07), lineWidth: 0.7) }
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                Text(title)
                    .font(.custom("Inter-Medium", size: 10.5, relativeTo: .caption))
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 62)
        }
        .buttonStyle(.plain)
    }

    // MARK: Allocation + projection

    private var allocationAndProjection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PORTFOLIO")
                    .sectionHeaderStyle()
                Spacer()
                Text(model == nil ? "Connect accounts to activate" : "Allocation & outlook")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            if let model {
                HStack(spacing: 16) {
                    Chart(model.allocations) { allocation in
                        SectorMark(
                            angle: .value("Value", allocation.value),
                            innerRadius: .ratio(0.69),
                            angularInset: 1.5
                        )
                        .foregroundStyle(allocation.color)
                        .cornerRadius(2)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 126, height: 126)
                    .overlay {
                        VStack(spacing: 1) {
                            Text(compactCurrency(model.totalNetWorth))
                                .font(MilliFont.numericMedium)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("TOTAL")
                                .font(MilliFont.caption)
                                .tracking(0.6)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }

                    VStack(spacing: 9) {
                        ForEach(model.allocations) { allocation in
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(allocation.color)
                                    .frame(width: 7, height: 7)
                                Text(allocation.name)
                                    .font(MilliFont.bodySmall)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Spacer()
                                Text(allocation.share(of: model.totalNetWorth).formatted(.percent.precision(.fractionLength(0))))
                                    .font(MilliFont.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                        }
                    }
                }

                Divider().overlay(Color.white.opacity(0.06))

                HStack(spacing: 0) {
                    projectionMetric("Retirement", compactCurrency(model.retirementProjection), MilliColors.positive)
                    Rectangle().fill(Color.white.opacity(0.07)).frame(width: 1, height: 58)
                    projectionMetric("Future Net Worth", compactCurrency(model.futureNetWorth), MilliColors.cyanGlow)
                    Rectangle().fill(Color.white.opacity(0.07)).frame(width: 1, height: 58)
                    projectionMetric("Monthly", compactCurrency(model.monthlyContributions), MilliColors.silverBright)
                }
            } else {
                HStack(spacing: 11) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(MilliColors.cyanGlow)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Allocation unavailable")
                            .font(MilliFont.headlineSmall)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("Once account data is available, investments, retirement, savings and cash will appear here.")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(15)
        .background(integratedSurface)
    }

    private func projectionMetric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(0.45)
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(value)
                .font(.custom("Sora-SemiBold", size: 14, relativeTo: .subheadline))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
    }

    // MARK: Goals / planning

    private var goalsAndPlanning: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PLANNING")
                    .sectionHeaderStyle()
                Spacer()
                Button { navigate?(.treeOfLife) } label: {
                    Text("Open Tree of Life")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
            }

            if model != nil {
                goalRow("Emergency Reserve", current: 12_800, target: 18_000, icon: "shield.fill")
                goalRow("Home Fund", current: 18_765, target: 50_000, icon: "house.fill")
            } else {
                HStack(spacing: 11) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .foregroundStyle(MilliColors.cyanGlow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Build your future plan")
                            .font(MilliFont.headlineSmall)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("Add life events and goals without fabricating account values.")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private func goalRow(_ title: String, current: Double, target: Double, icon: String) -> some View {
        let progress = target > 0 ? min(max(current / target, 0), 1) : 0

        return VStack(spacing: 7) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 26)

                Text(title)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textPrimary)

                Spacer()

                Text("\(compactCurrency(current)) / \(compactCurrency(target))")
                    .font(MilliFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 3)
    }

    private var integratedSurface: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "0D151A"), Color(hex: "080C0F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.075), lineWidth: 0.7)
            }
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.2fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

private struct WealthAllocation: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color

    func share(of total: Double) -> Double {
        guard total > 0 else { return 0 }
        return value / total
    }
}

private struct WealthTrendPoint: Identifiable {
    let id = UUID()
    let month: String
    let value: Double
}

private struct WealthOverviewModel {
    let allocations: [WealthAllocation]
    let monthlyChange: Double
    let retirementProjection: Double
    let futureNetWorth: Double
    let monthlyContributions: Double
    let trend: [WealthTrendPoint]

    var totalNetWorth: Double {
        allocations.reduce(0) { $0 + $1.value }
    }

    static let reference = WealthOverviewModel(
        allocations: [
            .init(name: "Investments", value: 42_685, color: MilliColors.cyanGlow),
            .init(name: "Retirement", value: 148_320, color: Color(hex: "3276D9")),
            .init(name: "Savings", value: 18_765, color: MilliColors.deepCyan),
            .init(name: "Cash", value: 14_790, color: MilliColors.silver)
        ],
        monthlyChange: 7_250,
        retirementProjection: 1_623_587,
        futureNetWorth: 2_467_892,
        monthlyContributions: 2_850,
        trend: [
            .init(month: "Mar", value: 186_900),
            .init(month: "Apr", value: 190_750),
            .init(month: "May", value: 198_300),
            .init(month: "Jun", value: 204_810),
            .init(month: "Jul", value: 217_310),
            .init(month: "Aug", value: 224_560)
        ]
    )
}

#Preview {
    WealthOverviewView()
        .preferredColorScheme(.dark)
}
