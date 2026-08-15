import SwiftUI
import Charts

// MARK: - TaxReadyScoreView
// Readiness instrument: score, contributing factors, and trend history.

struct TaxReadyScoreView: View {
    var onBack: () -> Void = {}

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
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        AngularGradient(
                            colors: [MilliColors.deepCyan, MilliColors.cyanGlow, MilliColors.positive],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 8)

                VStack(spacing: 1) {
                    Text("85")
                        .font(.custom("Sora-ExtraBold", size: 42, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Great")
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.positive)
                }
            }
            .frame(width: 176, height: 176)

            Text("You're on track for tax season")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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

                        Text(factor.name)
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textPrimary)

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
            .init(name: "Income Tracking", status: "Excellent", color: MilliColors.positive, icon: "dollarsign.circle.fill"),
            .init(name: "Expense Tracking", status: "Good", color: MilliColors.positive, icon: "receipt.fill"),
            .init(name: "Mileage Tracking", status: "Excellent", color: MilliColors.positive, icon: "car.fill"),
            .init(name: "Tax Payments", status: "Good", color: MilliColors.positive, icon: "building.columns.fill"),
            .init(name: "Document Capture", status: "Needs Attention", color: MilliColors.warning, icon: "doc.text.fill")
        ]
    }

    private var historyData: [ScoreHistoryPoint] {
        [
            .init(month: "Jan", score: 68), .init(month: "Feb", score: 72),
            .init(month: "Mar", score: 78), .init(month: "Apr", score: 82),
            .init(month: "May", score: 85), .init(month: "Jun", score: 85)
        ]
    }
}

private struct ScoreFactor: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let color: Color
    let icon: String
}

private struct ScoreHistoryPoint: Identifiable {
    let id = UUID()
    let month: String
    let score: Int
}
