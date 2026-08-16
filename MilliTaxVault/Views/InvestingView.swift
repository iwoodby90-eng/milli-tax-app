import SwiftUI
import Charts

// MARK: - InvestingView
// Institutional-style market surface with deterministic OHLC candlesticks and holdings.

struct InvestingView: View {
    var onBack: () -> Void = {}
    @State private var selectedPeriod: ChartPeriod = .oneMonth

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                marketStrip
                portfolioCard
                holdings
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

            Text("Investing")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                Image(systemName: "bell")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(MilliColors.textSecondary)
        }
    }

    private var marketStrip: some View {
        HStack(spacing: 6) {
            marketTile("S&P 500", "5,278.40", "+1.15%")
            marketTile("NASDAQ", "16,735.02", "+1.35%")
            marketTile("DOW JONES", "39,134.76", "+0.78%")
        }
    }

    private func marketTile(_ name: String, _ value: String, _ change: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
            HStack(spacing: 4) {
                Text(change)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.positive)
                Spacer(minLength: 0)
                MiniMarketSparkline()
                    .frame(width: 32, height: 12)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                }
        )
    }

    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PORTFOLIO VALUE")
                .sectionHeaderStyle()

            Text("$42,685.73")
                .font(MilliFont.heroNumber)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)

            Text("▲ $1,324.67 (3.20%) Today")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.positive)

            periodControl

            candlestickChart
                .frame(height: 235)
        }
        .milliCard(padding: 14)
    }

    private var periodControl: some View {
        HStack(spacing: 2) {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.label)
                        .font(MilliFont.caption)
                        .foregroundStyle(selectedPeriod == period ? MilliColors.textPrimary : MilliColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color.white.opacity(0.09) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var candlestickChart: some View {
        Chart(ohlcData) { candle in
            RuleMark(
                x: .value("Day", candle.day),
                yStart: .value("Low", candle.low),
                yEnd: .value("High", candle.high)
            )
            .foregroundStyle(candle.isUp ? MilliColors.positive : MilliColors.negative)
            .lineStyle(StrokeStyle(lineWidth: 1))

            RectangleMark(
                x: .value("Day", candle.day),
                yStart: .value("Body low", min(candle.open, candle.close)),
                yEnd: .value("Body high", max(candle.open, candle.close)),
                width: 7
            )
            .foregroundStyle(candle.isUp ? MilliColors.positive : MilliColors.negative)
            .cornerRadius(1)
        }
        .chartYScale(domain: 4700...5450)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [4800, 5000, 5200, 5400]) { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.045))
                AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: [1, 6, 11, 16, 21]) { value in
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text(chartDateLabel(day))
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                }
            }
        }
    }

    private var holdings: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TOP HOLDINGS")
                    .sectionHeaderStyle()
                Spacer()
                Text("View All")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(spacing: 0) {
                ForEach(Array(holdingData.enumerated()), id: \.element.id) { index, holding in
                    HStack(spacing: 9) {
                        Circle()
                            .fill(holding.color)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text(holding.symbol.prefix(2))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(holding.symbol)
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(holding.name)
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(holding.value)
                                .font(MilliFont.numericSmall)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(holding.change)
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.positive)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)

                    if index < holdingData.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 49)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private func chartDateLabel(_ day: Int) -> String {
        switch day {
        case 1: return "Apr 21"
        case 6: return "Apr 28"
        case 11: return "May 5"
        case 16: return "May 12"
        default: return "May 19"
        }
    }

    private var ohlcData: [OHLCCandle] {
        [
            .init(day: 1, open: 4950, high: 5060, low: 4880, close: 5010),
            .init(day: 2, open: 5010, high: 5050, low: 4820, close: 4875),
            .init(day: 3, open: 4880, high: 4960, low: 4770, close: 4830),
            .init(day: 4, open: 4835, high: 5000, low: 4800, close: 4975),
            .init(day: 5, open: 4970, high: 5060, low: 4930, close: 5035),
            .init(day: 6, open: 5030, high: 5110, low: 5005, close: 5085),
            .init(day: 7, open: 5080, high: 5180, low: 5060, close: 5150),
            .init(day: 8, open: 5150, high: 5260, low: 5120, close: 5225),
            .init(day: 9, open: 5220, high: 5300, low: 5160, close: 5255),
            .init(day: 10, open: 5260, high: 5315, low: 5190, close: 5210),
            .init(day: 11, open: 5205, high: 5260, low: 5120, close: 5150),
            .init(day: 12, open: 5150, high: 5225, low: 5070, close: 5110),
            .init(day: 13, open: 5110, high: 5255, low: 5080, close: 5215),
            .init(day: 14, open: 5215, high: 5290, low: 5170, close: 5265),
            .init(day: 15, open: 5260, high: 5320, low: 5210, close: 5290),
            .init(day: 16, open: 5290, high: 5370, low: 5255, close: 5345),
            .init(day: 17, open: 5340, high: 5390, low: 5290, close: 5320),
            .init(day: 18, open: 5320, high: 5380, low: 5260, close: 5280),
            .init(day: 19, open: 5280, high: 5360, low: 5260, close: 5340),
            .init(day: 20, open: 5340, high: 5390, low: 5300, close: 5360),
            .init(day: 21, open: 5360, high: 5410, low: 5320, close: 5378)
        ]
    }

    private var holdingData: [Holding] {
        [
            .init(symbol: "VTI", name: "Vanguard Total Stock Market ETF", value: "$12,663.43", change: "+3.15%", color: Color(hex: "C23A36")),
            .init(symbol: "VOO", name: "Vanguard S&P 500 ETF", value: "$9,742.21", change: "+3.20%", color: Color(hex: "D64B45")),
            .init(symbol: "QQQM", name: "Invesco NASDAQ 100 ETF", value: "$6,521.37", change: "+2.18%", color: Color(hex: "248BEA")),
            .init(symbol: "SCHD", name: "Schwab U.S. Dividend Equity ETF", value: "$3,865.12", change: "+1.25%", color: Color(hex: "0CA6D8"))
        ]
    }
}

private struct MiniMarketSparkline: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height * 0.75))
                p.addLine(to: CGPoint(x: geo.size.width * 0.20, y: geo.size.height * 0.60))
                p.addLine(to: CGPoint(x: geo.size.width * 0.35, y: geo.size.height * 0.68))
                p.addLine(to: CGPoint(x: geo.size.width * 0.52, y: geo.size.height * 0.30))
                p.addLine(to: CGPoint(x: geo.size.width * 0.68, y: geo.size.height * 0.46))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.12))
            }
            .stroke(MilliColors.positive, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
    }
}

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

private struct OHLCCandle: Identifiable {
    let id = UUID()
    let day: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    var isUp: Bool { close >= open }
}

struct Holding: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let value: String
    let change: String
    let color: Color
}
