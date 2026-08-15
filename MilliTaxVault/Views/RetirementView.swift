import SwiftUI
import Charts

// MARK: - RetirementView — Screen 9: Retirement projection
// Hero: retire year + age | Stats row | Projected growth chart with legend

struct RetirementView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.xl) {
                headerSection
                heroSection
                statsRow
                projectedGrowthChart
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button { onBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MilliColors.textSecondary)
            }
            .buttonStyle(.plain)

            Text("Retirement")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: MilliSpacing.sm) {
            Text("You're on track to retire in")
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textSecondary)

            Text("2047")
                .font(.custom("Sora-ExtraBold", size: 56, relativeTo: .largeTitle))
                .foregroundColor(MilliColors.cyanGlow)

            Text("at age 62")
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MilliSpacing.xl)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        VStack(spacing: MilliSpacing.md) {
            HStack(spacing: MilliSpacing.gridGap) {
                statCard(label: "Contribution", value: "12%", sublabel: "of income")
                statCard(label: "Estimated Value", value: "$1.52M", sublabel: "in 2047")
            }
            HStack(spacing: MilliSpacing.gridGap) {
                statCard(label: "Current Value", value: "$134,580", sublabel: "")
                Spacer()
            }
        }
    }

    private func statCard(label: String, value: String, sublabel: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .foregroundColor(MilliColors.cyanGlow)
            if !sublabel.isEmpty {
                Text(sublabel)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }

    // MARK: - Projected Growth Chart

    private var projectedGrowthChart: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("PROJECTED GROWTH")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            Chart {
                // Total projection line
                ForEach(totalProjectionData) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Value", point.value),
                        series: .value("Series", "Total")
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Investment growth line
                ForEach(investmentGrowthData) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Value", point.value),
                        series: .value("Series", "Investment")
                    )
                    .foregroundStyle(MilliColors.deepCyan)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Contributions line
                ForEach(contributionsData) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Value", point.value),
                        series: .value("Series", "Contributions")
                    )
                    .foregroundStyle(MilliColors.positive)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 500000, 1000000, 1500000]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4]))
                        .foregroundStyle(MilliColors.border)
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(formatLargeNumber(v))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [2024, 2030, 2035, 2040, 2047]) { value in
                    AxisValueLabel()
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: MilliSpacing.lg) {
                legendItem(color: MilliColors.cyanGlow, label: "Total ($1.52M)")
                legendItem(color: MilliColors.deepCyan, label: "Growth ($1.03M)")
                legendItem(color: MilliColors.positive, label: "Contributions ($490K)")
            }
            .font(MilliFont.caption)
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(MilliColors.textSecondary)
        }
    }

    private func formatLargeNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return "$\(value / 1_000_000)M"
        } else if value >= 1_000 {
            return "$\(value / 1_000)K"
        } else if value == 0 {
            return "$0"
        }
        return "$\(value)"
    }

    // MARK: - Chart Data

    private var totalProjectionData: [RetirementPoint] {
        let years = stride(from: 2024, through: 2047, by: 1)
        return years.map { year in
            let progress = Double(year - 2024) / 23.0
            let value = 134580 + progress * progress * 1_385_420
            return RetirementPoint(year: year, value: value)
        }
    }

    private var investmentGrowthData: [RetirementPoint] {
        let years = stride(from: 2024, through: 2047, by: 1)
        return years.map { year in
            let progress = Double(year - 2024) / 23.0
            let value = 80000 + progress * progress * 950_000
            return RetirementPoint(year: year, value: value)
        }
    }

    private var contributionsData: [RetirementPoint] {
        let years = stride(from: 2024, through: 2047, by: 1)
        return years.map { year in
            let progress = Double(year - 2024) / 23.0
            let value = 54580 + progress * 435_420
            return RetirementPoint(year: year, value: value)
        }
    }
}

// MARK: - Model

struct RetirementPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
}
