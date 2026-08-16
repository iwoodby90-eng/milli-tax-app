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
                Text("PROJECTED GROWTH")
                    .sectionHeaderStyle()
                Spacer()
                Text("\(Int(contribution))% • age \(Int(retirementAge))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart(projection.points) { point in
                BarMark(
                    x: .value("Year", point.year),
                    yStart: .value("Start", 0),
                    yEnd: .value("Contributions", point.totalContributions),
                    width: 8
                )
                .foregroundStyle(Color(hex: "3276D9"))

                BarMark(
                    x: .value("Year", point.year),
                    yStart: .value("Contributions", point.totalContributions),
                    yEnd: .value("Portfolio", point.balance),
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
                AxisMarks(position: .leading) { value in
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
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
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

            HStack(spacing: 16) {
                legend(Color(hex: "3276D9"), "Contributions")
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

        // Keep the chart dense but legible on iPhone by sampling at most ~9 annual points.
        let strideSize = max(annualPoints.count / 8, 1)
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
