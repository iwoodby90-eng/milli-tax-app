import SwiftUI
import Charts

// MARK: - InvestingView — Screen 8: Portfolio + market tickers
// Market tickers | Portfolio value + chart | Top holdings

struct InvestingView: View {
    var onBack: () -> Void = {}
    @State private var selectedPeriod: ChartPeriod = .oneMonth

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                marketTickersRow
                portfolioHero
                chartSection
                topHoldingsSection
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

            Text("Investing")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Market Tickers

    private var marketTickersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MilliSpacing.sm) {
                tickerChip(name: "S&P 500", value: "$5,278.40", change: "+1.15%")
                tickerChip(name: "NASDAQ", value: "16,735.02", change: "+1.02%")
                tickerChip(name: "DOW JONES", value: "39,134.76", change: "+0.78%")
            }
        }
    }

    private func tickerChip(name: String, value: String, change: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericSmall)
                .foregroundColor(MilliColors.textPrimary)
            Text(change)
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.positive)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                        .stroke(MilliColors.cardBorderGlow, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Portfolio Hero

    private var portfolioHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PORTFOLIO VALUE")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            Text("$42,685.73")
                .font(MilliFont.heroNumber)
                .foregroundColor(MilliColors.cyanGlow)

            Text("+$1,324.67 (3.20%) Today")
                .font(MilliFont.bodySmall)
                .foregroundColor(MilliColors.positive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(spacing: MilliSpacing.md) {
            // Period tabs
            HStack(spacing: 0) {
                ForEach(ChartPeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.label)
                            .font(MilliFont.label)
                            .foregroundColor(selectedPeriod == period ? MilliColors.cyanGlow : MilliColors.textTertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedPeriod == period ?
                                    Capsule().fill(MilliColors.cyanGlow.opacity(0.12)) :
                                    Capsule().fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Chart
            Chart {
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow.opacity(0.2), MilliColors.cyanGlow.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 140)
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    // MARK: - Top Holdings

    private var topHoldingsSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            HStack {
                Text("TOP HOLDINGS")
                    .font(MilliFont.label)
                    .foregroundColor(MilliColors.textLabel)
                    .tracking(0.8)
                Spacer()
                Button {} label: {
                    Text("View All")
                        .font(MilliFont.labelLarge)
                        .foregroundColor(MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
            }

            ForEach(holdingsData) { holding in
                holdingRow(holding)
            }
        }
    }

    private func holdingRow(_ holding: Holding) -> some View {
        HStack(spacing: MilliSpacing.md) {
            Circle()
                .fill(holding.dotColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(holding.name)
                    .font(MilliFont.headlineSmall)
                    .foregroundColor(MilliColors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.value)
                    .font(MilliFont.numericSmall)
                    .foregroundColor(MilliColors.textPrimary)
                Text(holding.change)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.positive)
            }
        }
        .padding(MilliSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                        .stroke(MilliColors.cardBorderGlow, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Data

    private var chartData: [ChartPoint] {
        (0..<30).map { i in
            ChartPoint(day: i, value: 40000 + Double.random(in: -500...2500) + Double(i) * 80)
        }
    }

    private var holdingsData: [Holding] {
        [
            Holding(name: "Vanguard S&P 500 ETF", value: "$19,242.21", change: "+1.58%", dotColor: MilliColors.cyanGlow),
            Holding(name: "iShares Core MSCI ETF", value: "$9,421.21", change: "+2.07%", dotColor: MilliColors.deepCyan),
            Holding(name: "ODOM AMZN100 ETF", value: "$6,521.37", change: "+0.15%", dotColor: MilliColors.positive),
            Holding(name: "Schwab U.S. Dividend Equity ETF", value: "$3,495.12", change: "+1.89%", dotColor: MilliColors.orange),
        ]
    }
}

// MARK: - Supporting Types

enum ChartPeriod: CaseIterable {
    case oneDay, oneWeek, oneMonth, threeMonths, oneYear, all

    var label: String {
        switch self {
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .oneYear: return "1Y"
        case .all: return "ALL"
        }
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let day: Int
    let value: Double
}

struct Holding: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let change: String
    let dotColor: Color
}
