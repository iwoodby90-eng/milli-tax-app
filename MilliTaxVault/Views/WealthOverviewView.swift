import SwiftUI
import Charts

// MARK: - WealthOverviewView
// Primary wealth hub: one premium surface for investing, retirement, savings,
// longer-term planning, and the payout flows that fund them.

struct WealthOverviewView: View {
    var onBack: () -> Void = {}
    var navigate: ((ActiveScreen) -> Void)? = nil

    @StateObject private var retirement = RetirementPlanningStore()

    // Net worth is only what Milli can actually account for: balances on
    // retirement accounts the user opened or rolled over. Nothing is inferred.
    private var allocations: [WealthAllocation] {
        var rows: [WealthAllocation] = []
        if let milli = retirement.milliAccount, milli.balance > 0 {
            rows.append(WealthAllocation(name: milli.planType, value: milli.balance, color: MilliColors.cyanGlow))
        }
        for account in retirement.mergedAccounts where account.balance > 0 {
            rows.append(
                WealthAllocation(
                    name: "\(account.custodianName) \(account.accountType)",
                    value: account.balance,
                    color: MilliColors.deepCyan
                )
            )
        }
        return rows
    }

    private var totalNetWorth: Double? {
        allocations.isEmpty ? nil : allocations.reduce(0) { $0 + $1.value }
    }

    private var monthlyContributions: Double? {
        let monthly = retirement.annualIncome * (retirement.contributionPercent / 100) / 12
        return monthly > 0 ? monthly : nil
    }

    private var projection: RetirementProjection? {
        RetirementProjectionCalculator.calculate(
            profile: retirement.snapshot,
            consolidatedBalance: totalNetWorth ?? 0
        )
    }

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

#Preview {
    WealthOverviewView()
        .preferredColorScheme(.dark)
}
