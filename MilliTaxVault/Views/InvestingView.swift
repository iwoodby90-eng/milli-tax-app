import SwiftUI
import Charts

// MARK: - InvestingView
// Institutional market surface backed only by real OHLC observations from
// MarketDataViewModel. No synthetic portfolio balances, holdings values, or
// fallback candles are presented as user data.

struct InvestingView: View {
    var onBack: () -> Void = {}

    @StateObject private var market = MarketDataViewModel()
    @State private var selectedPeriod: ChartPeriod = .oneMonth

    // Interactive candle window. Pinch changes the number of bars visible;
    // horizontal drag pans through the loaded observations.
    @State private var visibleCandleCount = 38
    @State private var chartEndIndex: Int? = nil
    @State private var magnificationBaseCount: Int? = nil
    @State private var dragBaseEndIndex: Int? = nil

    private let tickers = ["VOO", "AAPL", "NVDA", "QQQ", "BTC-USD"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                marketStrip
                marketCard
                watchlist
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .onAppear {
            market.startAutoRefresh()
            loadMarketChart(resetViewport: true)
        }
        .onDisappear {
            market.stopAutoRefresh()
        }
        .onChange(of: market.candles.count) { _, newCount in
            guard newCount > 0 else { return }
            if chartEndIndex == nil || chartEndIndex! > newCount {
                chartEndIndex = newCount
            }
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

            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
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

            if index.isLive {
                HStack(spacing: 3) {
                    Image(systemName: index.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(String(format: "%+.2f%%", index.change))
                }
                .font(MilliFont.caption)
                .foregroundStyle(changeColor)
            } else {
                Text("Connecting")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
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

    private var marketCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LIVE MARKET")
                        .sectionHeaderStyle()

                    Text(market.feedStatus == .live ? marketPriceText : "—")
                        .font(MilliFont.heroNumber)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .contentTransition(.numericText())

                    if market.feedStatus == .live {
                        HStack(spacing: 4) {
                            Image(systemName: market.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(String(format: "%+.2f%%", market.percentChange))
                        }
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(market.priceChange >= 0 ? MilliColors.positive : MilliColors.negative)
                    }
                }

                Spacer()
                feedBadge
            }

            Divider().overlay(Color.white.opacity(0.055))

            tickerControl
            periodControl
            chartToolbar

            marketChart
                .frame(height: 270)

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
                    resetChartViewport()
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
                    loadMarketChart(resetViewport: true)
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

    private var chartToolbar: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(market.selectedTicker == "BTC-USD" ? "BTC / USD" : market.selectedTicker)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
                Text("Pinch to zoom · drag to pan")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            zoomButton(systemName: "minus.magnifyingglass", accessibility: "Zoom out") {
                zoomChart(out: true)
            }
            zoomButton(systemName: "plus.magnifyingglass", accessibility: "Zoom in") {
                zoomChart(out: false)
            }
            zoomButton(systemName: "arrow.counterclockwise", accessibility: "Reset chart zoom") {
                resetChartViewport()
            }
        }
    }

    private func zoomButton(systemName: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.14), lineWidth: 0.6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }

    @ViewBuilder
    private var marketChart: some View {
        if market.feedStatus == .live, !visibleCandles.isEmpty {
            Chart {
                ForEach(visibleCandles) { candle in
                    RuleMark(
                        x: .value("Time", candle.time),
                        yStart: .value("Low", candle.low),
                        yEnd: .value("High", candle.high)
                    )
                    .foregroundStyle(candle.isUp ? MilliColors.cyanGlow : Color.white.opacity(0.92))
                    .lineStyle(StrokeStyle(lineWidth: 1.45, lineCap: .round))

                    RectangleMark(
                        x: .value("Time", candle.time),
                        yStart: .value("Open", min(candle.open, candle.close)),
                        yEnd: .value("Close", max(candle.open, candle.close)),
                        width: 8
                    )
                    .foregroundStyle(
                        candle.isUp
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white, MilliColors.silver],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .cornerRadius(1.4)
                }

                RuleMark(y: .value("Last Price", market.currentPrice))
                    .foregroundStyle(MilliColors.cyanGlow.opacity(0.62))
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
                            colors: [Color.white.opacity(0.020), Color.black.opacity(0.16)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.08), lineWidth: 0.6)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
                        .foregroundStyle(Color.white.opacity(0.075))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.16))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactMarketPrice(amount))
                                .font(.custom("Inter-Medium", size: 9, relativeTo: .caption2))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [2, 6]))
                        .foregroundStyle(Color.white.opacity(0.045))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(chartDateLabel(date))
                                .font(.custom("Inter-Medium", size: 9, relativeTo: .caption2))
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(chartMagnificationGesture)
            .simultaneousGesture(chartPanGesture)
            .accessibilityLabel("Live OHLC candlestick chart. Cyan candles closed at or above open. White candles closed below open. Pinch to zoom and drag horizontally to pan.")
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
                            Button("Retry") { loadMarketChart(resetViewport: true) }
                                .font(MilliFont.labelLarge)
                                .foregroundStyle(MilliColors.cyanGlow)
                        }
                    }
                }
        }
    }

    private var watchlist: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MARKET WATCHLIST")
                    .sectionHeaderStyle()
                Spacer()
                Text("LIVE WHEN AVAILABLE")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(market.holdings.enumerated()), id: \.element.id) { index, holding in
                    HStack(spacing: 9) {
                        Circle()
                            .fill(MilliColors.cyanGlow.opacity(0.09))
                            .frame(width: 30, height: 30)
                            .overlay {
                                Text(displayTicker(holding.ticker).prefix(2))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(MilliColors.cyanGlow)
                            }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(displayTicker(holding.ticker))
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(holding.name)
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if holding.isLive {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(livePriceText(holding.price))
                                    .font(MilliFont.numericSmall)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(String(format: "%+.2f%%", holding.change))
                                    .font(MilliFont.caption)
                                    .foregroundStyle(holding.change >= 0 ? MilliColors.positive : MilliColors.negative)
                            }
                        } else {
                            Text("—")
                                .font(MilliFont.numericSmall)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)

                    if index < market.holdings.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 51)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private var visibleCandles: [LiveOHLCCandle] {
        let candles = market.candles
        guard !candles.isEmpty else { return [] }

        let count = min(max(visibleCandleCount, minimumVisibleCandles), candles.count)
        let proposedEnd = chartEndIndex ?? candles.count
        let end = min(max(proposedEnd, count), candles.count)
        let start = max(0, end - count)
        return Array(candles[start..<end])
    }

    private var minimumVisibleCandles: Int { 8 }

    private var chartMagnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let base = magnificationBaseCount ?? visibleCandleCount
                if magnificationBaseCount == nil {
                    magnificationBaseCount = visibleCandleCount
                }
                let adjusted = Int((Double(base) / max(scale, 0.25)).rounded())
                setVisibleCandleCount(adjusted)
            }
            .onEnded { _ in
                magnificationBaseCount = nil
            }
    }

    private var chartPanGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height), !market.candles.isEmpty else { return }
                let base = dragBaseEndIndex ?? (chartEndIndex ?? market.candles.count)
                if dragBaseEndIndex == nil {
                    dragBaseEndIndex = base
                }
                let pointsPerCandle: CGFloat = 11
                let delta = Int((value.translation.width / pointsPerCandle).rounded())
                let minimumEnd = min(visibleCandleCount, market.candles.count)
                chartEndIndex = min(max(base - delta, minimumEnd), market.candles.count)
            }
            .onEnded { _ in
                dragBaseEndIndex = nil
            }
    }

    private func zoomChart(out: Bool) {
        let factor = out ? 1.35 : 0.72
        setVisibleCandleCount(Int((Double(visibleCandleCount) * factor).rounded()))
    }

    private func setVisibleCandleCount(_ requested: Int) {
        guard !market.candles.isEmpty else {
            visibleCandleCount = max(requested, minimumVisibleCandles)
            return
        }
        let clamped = min(max(requested, minimumVisibleCandles), market.candles.count)
        visibleCandleCount = clamped
        let currentEnd = chartEndIndex ?? market.candles.count
        chartEndIndex = min(max(currentEnd, clamped), market.candles.count)
    }

    private func resetChartViewport() {
        visibleCandleCount = defaultVisibleCandleCount
        chartEndIndex = market.candles.isEmpty ? nil : market.candles.count
        magnificationBaseCount = nil
        dragBaseEndIndex = nil
    }

    private var defaultVisibleCandleCount: Int {
        switch selectedPeriod {
        case .oneDay: return 48
        case .oneWeek: return 42
        case .oneMonth: return 38
        case .threeMonths: return 46
        case .oneYear: return 50
        case .all: return 52
        }
    }

    private func loadMarketChart(resetViewport: Bool) {
        if resetViewport {
            visibleCandleCount = defaultVisibleCandleCount
            chartEndIndex = nil
        }
        market.fetchChart(
            for: market.selectedTicker,
            interval: selectedPeriod.interval,
            range: selectedPeriod.range
        )
    }

    private var chartYDomain: ClosedRange<Double> {
        guard let low = visibleCandles.map(\.low).min(),
              let high = visibleCandles.map(\.high).max(),
              high >= low else {
            return 0...1
        }

        let spread = max(high - low, max(high * 0.0025, 0.01))
        let padding = spread * 0.10
        return (low - padding)...(high + padding)
    }

    private var marketPriceText: String {
        livePriceText(market.currentPrice)
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

    private func livePriceText(_ value: Double) -> String {
        if value >= 10_000 {
            return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    private func compactMarketPrice(_ value: Double) -> String {
        if value >= 10_000 { return String(format: "$%.1fK", value / 1_000) }
        if value >= 1_000 { return String(format: "$%.0f", value) }
        return String(format: "$%.2f", value)
    }

    private func displayTicker(_ ticker: String) -> String {
        ticker == "BTC-USD" ? "BTC" : ticker
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
