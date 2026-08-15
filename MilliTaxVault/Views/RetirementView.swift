import SwiftUI
import Charts

// MARK: - RetirementView
// Contribution-based retirement projection with a clear target year and stacked growth visualization.

struct RetirementView: View {
    var onBack: () -> Void = {}
    @State private var contribution: Double = 15
    @State private var retirementAge: Double = 62

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                hero
                projectionChart
                planControls
                projectionSummary
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

            Text("Retirement")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 34, height: 34)
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Text("You're on track to retire in")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            Text("2047")
                .font(.custom("Sora-ExtraBold", size: 48, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)

            Text("at age \(Int(retirementAge))")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 0) {
                heroMetric("Contribution", "\(Int(contribution))%", "of income")
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 46)
                heroMetric("Estimated Value", projectedValue, "in today's dollars")
            }
        }
        .milliCard(padding: 14)
    }

    private func heroMetric(_ title: String, _ value: String, _ subtitle: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.positive)
            Text(subtitle)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var projectionChart: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("PROJECTED GROWTH")
                    .sectionHeaderStyle()
                Spacer()
                Text("\(Int(contribution))% contribution • age \(Int(retirementAge))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart(projectionData) { point in
                BarMark(
                    x: .value("Year", point.year),
                    yStart: .value("Start", 0),
                    yEnd: .value("Contributions", point.contributions),
                    width: 8
                )
                .foregroundStyle(Color(hex: "3276D9"))

                BarMark(
                    x: .value("Year", point.year),
                    yStart: .value("Contributions", point.contributions),
                    yEnd: .value("Portfolio", point.portfolio),
                    width: 8
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.positive, Color(hex: "2EA1A7")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 500_000, 1_000_000, 1_500_000, 2_000_000]) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatCompact(amount))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [2025, 2030, 2035, 2040, 2045, 2047]) { _ in
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(height: 210)

            HStack(spacing: 16) {
                legend(Color(hex: "3276D9"), "Total Contributions")
                legend(MilliColors.positive, "Investment Growth")
            }
        }
        .milliCard(padding: 14)
    }

    private func legend(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 6)
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
        }
    }

    private var planControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ADJUST YOUR PLAN")
                .sectionHeaderStyle()

            sliderRow(
                title: "Contribution Percentage",
                value: $contribution,
                range: 0...50,
                suffix: "%"
            )

            sliderRow(
                title: "Retirement Age",
                value: $retirementAge,
                range: 55...70,
                suffix: " years"
            )
        }
        .milliCard(padding: 14)
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(title)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("\(Int(value.wrappedValue))\(suffix)")
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            Slider(value: value, in: range, step: 1)
                .tint(MilliColors.cyanGlow)
        }
    }

    private var projectionSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPDATED PROJECTION")
                .sectionHeaderStyle()

            HStack(spacing: 8) {
                summary("Retirement Year", "2047")
                summary("Estimated Value", projectedValue)
            }
            HStack(spacing: 8) {
                summary("Total Contributions", "$455,100")
                summary("Total Growth", "$1,168,487")
            }
        }
    }

    private func summary(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .milliCard(padding: 10)
    }

    private var projectedValue: String {
        let base = 1_623_587.0
        let contributionFactor = max(contribution, 1) / 15.0
        let ageFactor = max(retirementAge - 54, 1) / 8.0
        let projected = base * contributionFactor * ageFactor
        return projected.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var projectionData: [RetirementProjectionPoint] {
        let years = [2025, 2028, 2031, 2034, 2037, 2040, 2043, 2045, 2047]
        return years.enumerated().map { index, year in
            let progress = Double(index + 1) / Double(years.count)
            let contributionScale = max(contribution, 1) / 15.0
            let total = 60_000 + pow(progress, 1.65) * 1_820_000 * contributionScale
            let contributions = 40_000 + progress * 430_000 * contributionScale
            return RetirementProjectionPoint(year: year, contributions: min(contributions, total), portfolio: total)
        }
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return "$0"
    }
}

private struct RetirementProjectionPoint: Identifiable {
    let id = UUID()
    let year: Int
    let contributions: Double
    let portfolio: Double
}
