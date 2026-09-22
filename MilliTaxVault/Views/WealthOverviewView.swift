import SwiftUI
import Charts

// MARK: - WealthOverviewView
// Primary wealth hub: one premium surface for investing, retirement, savings,
// longer-term planning, and the payout flows that fund them.

struct WealthOverviewView: View {
    var onBack: () -> Void = {}
    var navigate: ((ActiveScreen) -> Void)? = nil

    private let model = WealthOverviewModel.reference
    private var showsReferenceData: Bool { ReferenceDataPolicy.allowsDemoReferenceData }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                wealthDestinations
                if showsReferenceData {
                    netWorthHero
                    allocationCard
                    projectionCard
                    goalsCard
                } else {
                    unavailableDataCard
                }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background { MilliAmbientBackground() }
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

            ProvenanceTag(label: ReferenceDataPolicy.provenance)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private var unavailableDataCard: some View {
        VStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.07))
                    .frame(width: 62, height: 62)
                Image(systemName: "chart.pie")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text("Your wealth picture starts with verified accounts")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(
                "Connect investing, retirement, savings, and cash accounts to build net worth and " +
                "projections from real balances. Reference portfolio values stay confined to demo captures."
            )
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .milliCard(padding: 18)
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

            Text(MilliFigureFormat.wholeCurrency(totalNetWorth))
                .font(MilliFont.heroNumber)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)

            Text(
                totalNetWorth == nil
                ? "Open or connect an account and your net worth appears here."
                : "Balances from your connected retirement accounts."
            )
            .font(MilliFont.bodySmall)
            .foregroundStyle(MilliColors.textSecondary)

            MilliTrendChart(
                points: [],
                height: 82,
                emptyMessage: "Net worth history builds as balances update"
            )
        }
        .milliCard(padding: 14)
    }

    private var allocationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEALTH ALLOCATION")
                .sectionHeaderStyle()

            if allocations.isEmpty {
                Text("No accounts connected yet.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 84)
            } else {
            HStack(spacing: 14) {
                Chart(allocations) { allocation in
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
                        Text(MilliFigureFormat.wholeCurrency(totalNetWorth))
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                    }
                }

                VStack(spacing: 7) {
                    ForEach(allocations) { allocation in
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
                            Text(allocation.share(of: totalNetWorth ?? 0).formatted(.percent.precision(.fractionLength(0))))
                                .font(MilliFont.caption)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textTertiary)
                        }
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
                Text("\(Int(retirement.annualReturnPercent))% ASSUMED")
                    .font(MilliFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            HStack(spacing: 8) {
                projectionMetric(
                    "Retirement Value",
                    MilliFigureFormat.wholeCurrency(projection?.endingBalance),
                    MilliColors.positive
                )
                projectionMetric(
                    "Contributed",
                    MilliFigureFormat.wholeCurrency(projection?.totalContributions),
                    MilliColors.cyanGlow
                )
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
                Text(MilliFigureFormat.wholeCurrency(monthlyContributions))
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

            Text("Goals you create in Savings show their progress here.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .milliCard(padding: 14)
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
