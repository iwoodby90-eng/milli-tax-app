import SwiftUI
import Charts

// MARK: - WealthOverviewView
// Primary wealth hub: one premium surface for investing, retirement, savings,
// longer-term planning, and the payout flows that fund them.

struct WealthOverviewView: View {
    var onBack: () -> Void = {}
    var navigate: ((ActiveScreen) -> Void)? = nil

    private let model = WealthOverviewModel.reference

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                wealthDestinations
                netWorthHero
                allocationCard
                projectionCard
                goalsCard
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

            Image(systemName: "chart.pie.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
        }
    }

    private var wealthDestinations: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEALTH HUB")
                .sectionHeaderStyle()

            HStack(spacing: 7) {
                destinationTile(
                    title: "Investing",
                    subtitle: "Markets & portfolio",
                    icon: "chart.xyaxis.line",
                    destination: .investing
                )
                destinationTile(
                    title: "Retirement",
                    subtitle: "Projection & 401(k)",
                    icon: "hourglass.bottomhalf.filled",
                    destination: .retirement
                )
            }

            HStack(spacing: 7) {
                destinationTile(
                    title: "Savings",
                    subtitle: "Goals & reserves",
                    icon: "banknote.fill",
                    destination: .savings
                )
                destinationTile(
                    title: "Payouts",
                    subtitle: "Fund the future",
                    icon: "arrow.down.circle.fill",
                    destination: .vault
                )
            }

            HStack(spacing: 7) {
                destinationTile(
                    title: "Tree of Life",
                    subtitle: "Life-event planning",
                    icon: "point.3.filled.connected.trianglepath.dotted",
                    destination: .treeOfLife
                )
                destinationTile(
                    title: "Reports",
                    subtitle: "Track progress",
                    icon: "doc.text.magnifyingglass",
                    destination: .reports
                )
            }
        }
        .milliCard(padding: 12)
    }

    private func destinationTile(
        title: String,
        subtitle: String,
        icon: String,
        destination: ActiveScreen
    ) -> some View {
        Button {
            navigate?(destination)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(MilliColors.cyanGlow.opacity(0.08))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.025))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.055), lineWidth: 0.6)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    private var netWorthHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOTAL NET WORTH")
                .sectionHeaderStyle()

            // Reference-board values are DEMO placeholders (30-screen spec,
            // data-truth rule) — labeled, never presented as authoritative.
            ProvenanceTag(label: .demo)

            Text(model.totalNetWorth.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(MilliFont.heroNumber)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)

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
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Net Worth", point.value)
                )
                .foregroundStyle(MilliColors.cyanGlow)
                .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 82)
        }
        .milliCard(padding: 14)
    }

    private var allocationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEALTH ALLOCATION")
                .sectionHeaderStyle()

            HStack(spacing: 14) {
                Chart(model.allocations) { allocation in
                    SectorMark(
                        angle: .value("Value", allocation.value),
                        innerRadius: .ratio(0.67),
                        angularInset: 1.5
                    )
                    .foregroundStyle(allocation.color)
                    .cornerRadius(2)
                }
                .chartLegend(.hidden)
                .frame(width: 120, height: 120)
                .overlay {
                    VStack(spacing: 1) {
                        Text("TOTAL")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                        Text(compactCurrency(model.totalNetWorth))
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                    }
                }

                VStack(spacing: 7) {
                    ForEach(model.allocations) { allocation in
                        HStack(spacing: 7) {
                            Circle()
                                .fill(allocation.color)
                                .frame(width: 7, height: 7)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(allocation.name)
                                    .font(MilliFont.bodySmall)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(allocation.value.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                    .font(MilliFont.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                            Spacer()
                            Text(allocation.share(of: model.totalNetWorth).formatted(.percent.precision(.fractionLength(0))))
                                .font(MilliFont.caption)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
        }
        .milliCard(padding: 14)
    }

    private var projectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FUTURE WEALTH")
                    .sectionHeaderStyle()
                Spacer()
                Text("MODERATE")
                    .font(MilliFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            HStack(spacing: 8) {
                projectionMetric("Retirement Value (Projection)", compactCurrency(model.retirementProjection), MilliColors.positive)
                projectionMetric("Future Net Worth (Projection)", compactCurrency(model.futureNetWorth), MilliColors.cyanGlow)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MONTHLY CONTRIBUTIONS")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("Across retirement, investing and savings")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text(model.monthlyContributions.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
        }
        .milliCard(padding: 14)
    }

    private func projectionMetric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(MilliFont.sectionLabel)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.055), lineWidth: 0.6)
                }
        )
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("CURRENT GOALS")
                .sectionHeaderStyle()

            goalRow("Emergency Reserve", current: 12_800, target: 18_000, icon: "shield.fill")
            goalRow("Home Fund", current: 18_765, target: 50_000, icon: "house.fill")
        }
        .milliCard(padding: 14)
    }

    private func goalRow(_ title: String, current: Double, target: Double, icon: String) -> some View {
        let progress = target > 0 ? min(max(current / target, 0), 1) : 0

        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

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
