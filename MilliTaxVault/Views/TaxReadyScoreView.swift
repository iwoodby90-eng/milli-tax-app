import SwiftUI
import Charts

// MARK: - TaxReadyScoreView
// Premium readiness instrument matching the approved Milli reference. The hero
// remains derived from the underlying factor scores so production services can
// replace the seeded factors without redesigning the view.

struct TaxReadyScoreView: View {
    var onBack: () -> Void = {}

    private var score: Int {
        guard !factors.isEmpty else { return 0 }
        return Int((Double(factors.reduce(0) { $0 + $1.score }) / Double(factors.count)).rounded())
    }

    private var readiness: ReadinessState {
        ReadinessState(score: score)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                scoreGauge
                factorList
                history
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

            Text("Tax Ready Score™")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 34, height: 34)
        }
    }

    private var scoreGauge: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 11)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [MilliColors.deepCyan, MilliColors.cyanGlow, readiness.color],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 8)

                VStack(spacing: 1) {
                    Text("\(score)")
                        .font(.custom("Sora-Bold", size: 42, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(readiness.title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(readiness.color)
                }
            }
            .frame(width: 176, height: 176)

            Text(readiness.message)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tax Ready Score \(score) out of 100. \(readiness.title). \(readiness.message)")
    }

    private var factorList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCORE FACTORS")
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                ForEach(Array(factors.enumerated()), id: \.element.id) { index, factor in
                    HStack(spacing: 9) {
                        Image(systemName: factor.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(factor.color)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(factor.color.opacity(0.09)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(factor.name)
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(factor.detail)
                                .font(MilliFont.caption)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Spacer()

                        Text(factor.status)
                            .font(MilliFont.caption)
                            .foregroundStyle(factor.color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    if index < factors.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 46)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SCORE HISTORY")
                    .sectionHeaderStyle()
                Spacer()
                Text("Last 6 months")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart(historyData) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(MilliColors.cyanGlow)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.8))

                PointMark(
                    x: .value("Month", point.month),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(MilliColors.cyanGlow)
                .symbolSize(18)
            }
            .chartYScale(domain: 60...100)
            .chartYAxis {
                AxisMarks(values: [60, 70, 80, 90, 100]) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(height: 145)
        }
        .milliCard(padding: 14)
    }

    private var factors: [ScoreFactor] {
        [
            .init(name: "Income Tracking", detail: "6 / 6 income sources connected", score: 96, icon: "dollarsign.circle.fill"),
            .init(name: "Expenses Categorized", detail: "94% categorized", score: 84, icon: "receipt.fill"),
            .init(name: "Mileage Tracking", detail: "100% tracking enabled", score: 94, icon: "car.fill"),
            .init(name: "Quarterly Taxes", detail: "On time", score: 82, icon: "building.columns.fill"),
            .init(name: "Documents Captured", detail: "12 / 12 expected", score: 69, icon: "doc.text.fill")
        ]
    }

    private var historyData: [ScoreHistoryPoint] {
        let scores = [68, 72, 78, 82, 84, score]
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return scores.enumerated().map { index, value in
            let monthsBack = scores.count - 1 - index
            let date = calendar.date(byAdding: .month, value: -monthsBack, to: Date()) ?? Date()
            return ScoreHistoryPoint(month: formatter.string(from: date), score: value)
        }
    }
}

private struct ScoreFactor: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let score: Int
    let icon: String

    var status: String {
        switch score {
        case 90...: return "Excellent"
        case 80..<90: return "Good"
        case 70..<80: return "Fair"
        default: return "Needs Attention"
        }
    }

    var color: Color {
        switch score {
        case 80...: return MilliColors.positive
        case 70..<80: return MilliColors.warning
        default: return MilliColors.warning
        }
    }
}

private struct ReadinessState {
    let score: Int

    var title: String {
        switch score {
        case 90...: return "Excellent"
        case 80..<90: return "Great"
        case 70..<80: return "Good"
        case 60..<70: return "Fair"
        default: return "Needs Attention"
        }
    }

    var message: String {
        switch score {
        case 80...: return "You're on track for tax season"
        case 70..<80: return "A few improvements can strengthen your tax readiness"
        default: return "Review the factors below to improve your tax readiness"
        }
    }

    var color: Color {
        switch score {
        case 80...: return MilliColors.positive
        case 60..<80: return MilliColors.warning
        default: return MilliColors.negative
        }
    }
}

private struct ScoreHistoryPoint: Identifiable {
    let id = UUID()
    let month: String
    let score: Int
}
