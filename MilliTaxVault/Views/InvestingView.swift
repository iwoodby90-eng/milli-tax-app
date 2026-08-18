import SwiftUI
import Charts

// MARK: - InvestingView
// Reference-driven institutional market surface. Every candle comes from the
// external OHLC transport in MarketDataViewModel; no random or synthetic chart
// points are drawn when the market feed is unavailable.

struct InvestingView: View {
    var onBack: () -> Void = {}

    @StateObject private var market = MarketDataViewModel()
    @State private var selectedPeriod: ChartPeriod = .oneMonth

    private let tickers = ["VOO", "AAPL", "NVDA", "QQQ", "BTC-USD"]

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
        .onAppear {
            market.startAutoRefresh()
            loadMarketChart()
        }
        .onDisappear {
            market.stopAutoRefresh()
        }
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

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                Image(systemName: "bell")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(MilliColors.textSecondary)
        }
    }

    private var marketStrip: some View {
        HStack(spacing: 6) {
            ForEach(market.indices) { index in
                marketTile(index)
            }
        }
    }

    private func marketTile(_ index: MarketIndex) -> some View {
        let changeColor = index.change >= 0 ? MilliColors.positive : MilliColors.negative

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(index.name)
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Circle()
                    .fill(index.isLive ? MilliColors.cyanGlow : MilliColors.textTertiary)
                    .frame(width: 4, height: 4)
            }

            Text(index.isLive ? index.value.formatted(.number.precision(.fractionLength(2))) : "—")
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 3) {
                if index.isLive {
                    Image(systemName: index.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(String(format: "%+.2f%%", index.change))
                } else {
                    Text("Connecting")
                }
            }
            .font(MilliFont.caption)
            .foregroundStyle(index.isLive ? changeColor : MilliColors.textTertiary)
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(index.isLive ? MilliColors.cyanGlow.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 0.6)
                }
        )
    }

    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("PORTFOLIO VALUE")
                        .sectionHeaderStyle()

                    Text("$42,685.73")
                        .font(MilliFont.heroNumber)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("▲ $1,324.67 (3.20%) Today")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.positive)
                }

                Spacer()
                feedBadge
            }

            Divider().overlay(Color.white.opacity(0.055))

            tickerControl
            periodControl
            marketHeader

            marketChart
                .frame(height: 238)

            HStack(spacing: 7) {
                Circle()
                    .fill(feedColor)
                    .frame(width: 5, height: 5)

                Text(marketTimestamp)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text("OHLC · 10s refresh")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .milliCard(padding: 14)
    }

    private var feedBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(feedColor)
                .frame(width: 5, height: 5)
            Text(feedText)
                .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                .tracking(0.45)
                .foregroundStyle(feedColor)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Capsule().fill(feedColor.opacity(0.09)))
    }

    private var tickerControl: some View {
        HStack(spacing: 3) {
            ForEach(tickers, id: \.self) { ticker in
                Button {
                    market.switchTicker(ticker)
                } label: {
                    Text(ticker == "BTC-USD" ? "BTC" : ticker)
                        .font(MilliFont.caption)
                        .foregroundStyle(market.selectedTicker == ticker ? MilliColors.blackGlass : MilliColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(market.selectedTicker == ticker ? MilliColors.cyanGlow : Color.white.opacity(0.035))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var periodControl: some View {
        HStack(spacing: 2) {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                    loadMarketChart()
                } label: {
                    Text(period.label)
                        .font(MilliFont.caption)
                        .foregroundStyle(selectedPeriod == period ? MilliColors.textPrimary : MilliColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color.white.opacity(0.085) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var marketHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(market.selectedTicker == "BTC-USD" ? "BTC / USD" : market.selectedTicker)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)

                Text(market.feedStatus == .live ? marketPriceText : "—")
                    .font(MilliFont.numericLarge)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .contentTransition(.numericText())
            }

            Spacer()

            if market.feedStatus == .live {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: market.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%+.2f%%", market.percentChange))
                    }
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(market.priceChange >= 0 ? MilliColors.positive : MilliColors.negative)

                    Text(selectedPeriod.label)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            } else if market.feedStatus == .loading {
                ProgressView()
                    .controlSize(.small)
                    .tint(MilliColors.cyanGlow)
            }
        }
    }

    @ViewBuilder
    private var marketChart: some View {
        if market.feedStatus == .live, !market.candles.isEmpty {
            Chart {
                ForEach(market.candles) { candle in
                    RuleMark(
                        x: .value("Time", candle.time),
                        yStart: .value("Low", candle.low),
                        yEnd: .value("High", candle.high)
                    )
                    .foregroundStyle(candle.isUp ? MilliColors.positive : MilliColors.negative)
                    .lineStyle(StrokeStyle(lineWidth: 1.05, lineCap: .round))

                    RectangleMark(
                        x: .value("Time", candle.time),
                        yStart: .value("Open", min(candle.open, candle.close)),
                        yEnd: .value("Close", max(candle.open, candle.close)),
                        width: 5
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: candle.isUp
                                ? [MilliColors.positive.opacity(0.98), MilliColors.positive.opacity(0.66)]
                                : [MilliColors.negative.opacity(0.98), MilliColors.negative.opacity(0.66)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(0.9)
                }

                RuleMark(y: .value("Last Price", market.currentPrice))
                    .foregroundStyle(MilliColors.cyanGlow.opacity(0.68))
                    .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                    .annotation(position: .trailing, alignment: .center, spacing: 3) {
                        Text(compactMarketPrice(market.currentPrice))
                            .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.blackGlass)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(MilliColors.cyanGlow)
                            )
                    }
            }
            .chartYScale(domain: chartYDomain)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.018), Color.black.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.white.opacity(0.035), lineWidth: 0.5)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [2, 5]))
                        .foregroundStyle(Color.white.opacity(0.055))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactMarketPrice(amount))
                                .font(.custom("Inter-Medium", size: 8, relativeTo: .caption2))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [2, 6]))
                        .foregroundStyle(Color.white.opacity(0.035))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(chartDateLabel(date))
                                .font(.custom("Inter-Medium", size: 8, relativeTo: .caption2))
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.018))
                .overlay {
                    if market.feedStatus == .loading {
                        VStack(spacing: 7) {
                            ProgressView().tint(MilliColors.cyanGlow)
                            Text("Connecting to live OHLC market data")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(MilliColors.textTertiary)
                            Text("Live market data unavailable")
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textSecondary)
                            Text("Milli will not substitute simulated candles.")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                            Button("Retry") {
                                loadMarketChart()
                            }
                            .font(MilliFont.labelLarge)
                            .foregroundStyle(MilliColors.cyanGlow)
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

    private func loadMarketChart() {
        market.fetchChart(
            for: market.selectedTicker,
            interval: selectedPeriod.interval,
            range: selectedPeriod.range
        )
    }

    private var chartYDomain: ClosedRange<Double> {
        guard let low = market.candles.map(\.low).min(),
              let high = market.candles.map(\.high).max(),
              high >= low
        else {
            return 0...1
        }

        let spread = max(high - low, max(high * 0.0025, 0.01))
        let padding = spread * 0.12
        return (low - padding)...(high + padding)
    }

    private var marketPriceText: String {
        if market.currentPrice >= 10_000 {
            return market.currentPrice.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        }
        return market.currentPrice.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    private var marketTimestamp: String {
        if let marketTime = market.latestMarketTimestamp {
            return "Market bar \(marketTime.formatted(date: .omitted, time: .shortened))"
        }
        if market.feedStatus == .unavailable {
            return "No live market update"
        }
        return "Connecting…"
    }

    private var feedText: String {
        switch market.feedStatus {
        case .loading: return "CONNECTING"
        case .live: return "LIVE DATA"
        case .unavailable: return "OFFLINE"
        }
    }

    private var feedColor: Color {
        switch market.feedStatus {
        case .loading: return MilliColors.warning
        case .live: return MilliColors.cyanGlow
        case .unavailable: return MilliColors.textTertiary
        }
    }

    private func compactMarketPrice(_ value: Double) -> String {
        if value >= 10_000 {
            return String(format: "$%.1fK", value / 1_000)
        }
        if value >= 1_000 {
            return String(format: "$%.0f", value)
        }
        return String(format: "$%.2f", value)
    }

    private func chartDateLabel(_ date: Date) -> String {
        switch selectedPeriod {
        case .oneDay:
            return date.formatted(date: .omitted, time: .shortened)
        case .oneWeek:
            return date.formatted(.dateTime.weekday(.abbreviated).hour())
        default:
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
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

    var interval: String {
        switch self {
        case .oneDay: return "5m"
        case .oneWeek: return "15m"
        case .oneMonth: return "1h"
        case .threeMonths: return "1d"
        case .oneYear: return "1d"
        case .all: return "1wk"
        }
    }

    var range: String {
        switch self {
        case .oneDay: return "1d"
        case .oneWeek: return "5d"
        case .oneMonth: return "1mo"
        case .threeMonths: return "3mo"
        case .oneYear: return "1y"
        case .all: return "5y"
        }
    }
}

struct Holding: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let value: String
    let change: String
    let color: Color
}
