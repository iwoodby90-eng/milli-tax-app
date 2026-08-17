import SwiftUI
import Charts

// MARK: - RetirementView
// Contribution-based retirement projection with a dynamic target year and
// deterministic compound-growth model. The seeded profile is isolated so it can
// be replaced by the authenticated retirement profile without changing the view.

struct RetirementView: View {
    var onBack: () -> Void = {}

    @State private var contribution: Double = 15
    @State private var retirementAge: Double = 62

    private let profile = RetirementProfile.reference

    private var projection: RetirementProjection {
        RetirementProjectionCalculator.calculate(
            profile: profile,
            contributionPercent: contribution,
            retirementAge: retirementAge
        )
    }

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

            Text("\(projection.retirementYear)")
                .font(.custom("Sora-Bold", size: 48, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .contentTransition(.numericText())

            Text("at age \(Int(retirementAge))")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 0) {
                heroMetric("Contribution", "\(Int(contribution))%", "of income")
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 46)
                heroMetric("Estimated Value", compactCurrency(projection.endingBalance), "projected")
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECTED GROWTH")
                        .sectionHeaderStyle()
                    Text("Moderate scenario")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text("\(Int(contribution))% • age \(Int(retirementAge))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart {
                ForEach(projection.points) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Total Projection", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow.opacity(0.23), MilliColors.cyanGlow.opacity(0.015)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Total Projection", point.balance),
                        series: .value("Series", "Total Projection")
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .lineStyle(StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Investment Growth", point.investmentGrowth),
                        series: .value("Series", "Investment Growth")
                    )
                    .foregroundStyle(Color(hex: "19AFC4"))
                    .lineStyle(StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Contributions", point.totalContributions),
                        series: .value("Series", "Your Contributions")
                    )
                    .foregroundStyle(Color(hex: "3276D9"))
                    .lineStyle(StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXScale(domain: chartYearDomain)
            .chartYScale(domain: 0...chartMaximum)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactCurrency(amount))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text(String(year))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 210)

            HStack(spacing: 12) {
                legend(MilliColors.cyanGlow, "Total Projection")
                legend(Color(hex: "19AFC4"), "Investment Growth")
                legend(Color(hex: "3276D9"), "Contributions")
            }
        }
        .milliCard(padding: 14)
    }

    private var chartYearDomain: ClosedRange<Int> {
        let first = projection.points.first?.year ?? projection.retirementYear - 10
        let last = projection.points.last?.year ?? projection.retirementYear
        return first...max(last, first + 1)
    }

    private var chartMaximum: Double {
        max(projection.endingBalance * 1.08, 1)
    }

    private func legend(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(title)
                .font(.custom("Inter-Regular", size: 8.2, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var planControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ADJUST YOUR PLAN")
                .sectionHeaderStyle()

            sliderRow(
                title: "Contribution Percentage",
                value: $contribution,
                range: 1...30,
                suffix: "%"
            )

            sliderRow(
                title: "Retirement Age",
                value: $retirementAge,
                range: Double(profile.currentAge + 5)...75,
                suffix: ""
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
                summary("Retirement Year", "\(projection.retirementYear)")
                summary("Estimated Value", compactCurrency(projection.endingBalance))
            }
            HStack(spacing: 8) {
                summary("Total Contributions", compactCurrency(projection.totalContributions))
                summary("Total Growth", compactCurrency(projection.totalGrowth))
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
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .milliCard(padding: 10)
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.2fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

private struct RetirementProfile {
    let currentAge: Int
    let currentBalance: Double
    let annualIncome: Double
    let annualReturn: Double

    static let reference = RetirementProfile(
        currentAge: 41,
        currentBalance: 86_420,
        annualIncome: 74_000,
        annualReturn: 0.07
    )
}

private struct RetirementProjection {
    let retirementYear: Int
    let endingBalance: Double
    let totalContributions: Double
    let totalGrowth: Double
    let points: [RetirementProjectionPoint]
}

private struct RetirementProjectionPoint: Identifiable {
    let id = UUID()
    let year: Int
    let totalContributions: Double
    let balance: Double

    var investmentGrowth: Double {
        max(balance - totalContributions, 0)
    }
}

private enum RetirementProjectionCalculator {
    static func calculate(
        profile: RetirementProfile,
        contributionPercent: Double,
        retirementAge: Double
    ) -> RetirementProjection {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let targetAge = max(Int(retirementAge.rounded()), profile.currentAge + 1)
        let yearsToRetirement = targetAge - profile.currentAge
        let retirementYear = currentYear + yearsToRetirement

        let monthlyContribution = profile.annualIncome * (contributionPercent / 100) / 12
        let monthlyRate = pow(1 + profile.annualReturn, 1.0 / 12.0) - 1
        let totalMonths = max(yearsToRetirement * 12, 1)

        var balance = profile.currentBalance
        var contributed = profile.currentBalance
        var annualPoints: [RetirementProjectionPoint] = []

        for month in 1...totalMonths {
            balance = balance * (1 + monthlyRate) + monthlyContribution
            contributed += monthlyContribution

            if month % 12 == 0 || month == totalMonths {
                let yearOffset = Int(ceil(Double(month) / 12.0))
                annualPoints.append(
                    RetirementProjectionPoint(
                        year: currentYear + yearOffset,
                        totalContributions: contributed,
                        balance: balance
                    )
                )
            }
        }

        // Keep the chart dense but legible on iPhone by sampling at most ~10 annual points.
        let strideSize = max(annualPoints.count / 9, 1)
        var sampled = Array(annualPoints.enumerated().compactMap { index, point in
            index % strideSize == 0 ? point : nil
        })
        if let final = annualPoints.last, sampled.last?.year != final.year {
            sampled.append(final)
        }

        let totalGrowth = max(balance - contributed, 0)

        return RetirementProjection(
            retirementYear: retirementYear,
            endingBalance: balance,
            totalContributions: contributed,
            totalGrowth: totalGrowth,
            points: sampled
        )
    }
}
