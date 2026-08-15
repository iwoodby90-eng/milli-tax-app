import SwiftUI
import Charts

// MARK: - TaxReadyScoreView — Screen 6: Tax readiness gauge
// Large circular score | Factors list | Score history chart

struct TaxReadyScoreView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.xl) {
                headerSection
                scoreGauge
                factorsSection
                historyChartSection
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

            Text("Tax Ready Score")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Score Gauge

    private var scoreGauge: some View {
        VStack(spacing: MilliSpacing.md) {
            ZStack {
                // Background arc
                Circle()
                    .stroke(MilliColors.border, lineWidth: 12)
                    .frame(width: 180, height: 180)

                // Score arc
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        AngularGradient(
                            colors: [MilliColors.deepCyan, MilliColors.cyanGlow, MilliColors.positive],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(216)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 4) {
                    Text("85")
                        .font(MilliFont.heroNumber)
                        .foregroundColor(MilliColors.textPrimary)
                    Text("Great")
                        .font(MilliFont.headline)
                        .foregroundColor(MilliColors.positive)
                }
            }

            Text("You're on track for tax season")
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MilliSpacing.md)
    }

    // MARK: - Score Factors

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("SCORE FACTORS")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            ForEach(scoreFactors) { factor in
                factorRow(factor)
            }
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    private func factorRow(_ factor: ScoreFactor) -> some View {
        HStack(spacing: MilliSpacing.md) {
            Circle()
                .fill(factor.statusColor)
                .frame(width: 10, height: 10)

            Text(factor.name)
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()

            Text(factor.status)
                .font(MilliFont.labelLarge)
                .foregroundColor(factor.statusColor)
        }
    }

    // MARK: - Score History Chart

    private var historyChartSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("SCORE HISTORY")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            Chart {
                ForEach(historyData) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", point.month),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow.opacity(0.3), MilliColors.cyanGlow.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(values: [60, 70, 80, 90, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(MilliColors.border)
                    AxisValueLabel()
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(height: 160)
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    // MARK: - Data

    private var scoreFactors: [ScoreFactor] {
        [
            ScoreFactor(name: "Income Tracking", status: "Excellent", statusColor: MilliColors.positive),
            ScoreFactor(name: "Expense Tracking", status: "Good", statusColor: MilliColors.cyanGlow),
            ScoreFactor(name: "Mileage Tracking", status: "Excellent", statusColor: MilliColors.positive),
            ScoreFactor(name: "Tax Payments", status: "Good", statusColor: MilliColors.cyanGlow),
            ScoreFactor(name: "Document Capture", status: "Needs Attention", statusColor: MilliColors.warning),
        ]
    }

    private var historyData: [ScoreHistoryPoint] {
        [
            ScoreHistoryPoint(month: "Jan", score: 72),
            ScoreHistoryPoint(month: "Feb", score: 75),
            ScoreHistoryPoint(month: "Mar", score: 78),
            ScoreHistoryPoint(month: "Apr", score: 80),
            ScoreHistoryPoint(month: "May", score: 83),
            ScoreHistoryPoint(month: "Jun", score: 85),
        ]
    }
}

// MARK: - Models

struct ScoreFactor: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let statusColor: Color
}

struct ScoreHistoryPoint: Identifiable {
    let id = UUID()
    let month: String
    let score: Int
}
