import SwiftUI
import Charts

// MARK: - InvestingView
// Institutional market surface backed only by real OHLC observations from
// MarketDataViewModel. Trading is routed through Milli's authenticated backend;
// broker credentials must never be embedded in the iOS client.

struct InvestingView: View {
    var onBack: () -> Void = {}

    @StateObject private var market = MarketDataViewModel()
    @StateObject private var brokerage = BrokerageTradingService()
    @State private var selectedPeriod: ChartPeriod = .oneMonth
    @State private var visibleCandleCount = 24
    @State private var chartEndIndex: Int? = nil
    @State private var magnificationBaseCount: Int? = nil
    @State private var dragBaseEndIndex: Int? = nil
    @State private var tradeSide: BrokerageOrderSide = .buy
    @State private var showTradeTicket = false

    private let tickers = ["VOO", "AAPL", "NVDA", "QQQ", "BTC-USD"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                marketStrip
                marketCard
                tradeActions
                watchlist
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .onAppear {
            market.startAutoRefresh()
            brokerage.refreshAvailability()
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
        .sheet(isPresented: $showTradeTicket) {
            BrokerageTradeTicket(
                symbol: displayTicker(market.selectedTicker),
                marketPrice: market.feedStatus == .live ? market.currentPrice : nil,
                initialSide: tradeSide,
                service: brokerage
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
                .frame(height: 330)

            HStack(spacing: 7) {
                Circle().fill(feedColor).frame(width: 5, height: 5)
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

    private var tradeActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TRADE")
                    .sectionHeaderStyle()
                Spacer()
                Text(brokerageStatusLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(brokerageStatusColor)
            }

            HStack(spacing: 8) {
                tradeButton(title: "Buy", icon: "plus", side: .buy, fill: MilliColors.cyanGlow)
                tradeButton(title: "Sell", icon: "minus", side: .sell, fill: Color.white)
            }

            Text("Orders are submitted only through a verified brokerage account. Milli does not simulate fills or hold broker credentials in the app.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 12)
    }

    private func tradeButton(title: String, icon: String, side: BrokerageOrderSide, fill: Color) -> some View {
        Button {
            tradeSide = side
            showTradeTicket = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text("\(title) \(displayTicker(market.selectedTicker))")
                    .font(MilliFont.labelLarge)
            }
            .foregroundStyle(side == .buy ? MilliColors.blackGlass : MilliColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(side == .buy ? fill : Color.white.opacity(0.055))
                    .overlay {
                        if side == .sell {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        }
                    }
            )
        }
        .buttonStyle(.plain)
        .disabled(market.selectedTicker == "BTC-USD")
        .opacity(market.selectedTicker == "BTC-USD" ? 0.42 : 1)
    }

    private var feedBadge: some View {
        HStack(spacing: 4) {
            Circle().fill(feedColor).frame(width: 5, height: 5)
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
                        .background(Capsule().fill(selectedPeriod == period ? Color.white.opacity(0.085) : Color.clear))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chartToolbar: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(displayTicker(market.selectedTicker))
                        .font(MilliFont.sectionLabel)
                        .tracking(0.8)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("\(visibleCandles.count) bars")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                Text("Pinch to zoom · drag to pan")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()
            zoomButton(systemName: "minus.magnifyingglass", accessibility: "Zoom out") { zoomChart(out: true) }
            zoomButton(systemName: "plus.magnifyingglass", accessibility: "Zoom in") { zoomChart(out: false) }
            zoomButton(systemName: "arrow.counterclockwise", accessibility: "Reset chart zoom") { resetChartViewport() }
        }
    }

    private func zoomButton(systemName: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.05)).overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 0.7)))
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
                    .foregroundStyle(candle.isUp ? MilliColors.cyanGlow : Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 2.0, lineCap: .round))

                    RectangleMark(
                        x: .value("Time", candle.time),
                        yStart: .value("Open", min(candle.open, candle.close)),
                        yEnd: .value("Close", max(candle.open, candle.close)),
                        width: 12
                    )
                    .foregroundStyle(
                        candle.isUp
                            ? AnyShapeStyle(LinearGradient(colors: [MilliColors.cyanGlow, MilliColors.cyanGlow, MilliColors.deepCyan], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(LinearGradient(colors: [Color.white, MilliColors.silverBright, MilliColors.silver], startPoint: .top, endPoint: .bottom))
                    )
                    .cornerRadius(1.8)
                }

                RuleMark(y: .value("Last Price", market.currentPrice))
                    .foregroundStyle(MilliColors.cyanGlow.opacity(0.75))
                    .lineStyle(StrokeStyle(lineWidth: 1.05, dash: [5, 4]))
                    .annotation(position: .trailing, alignment: .center, spacing: 3) {
                        Text(compactMarketPrice(market.currentPrice))
                            .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.blackGlass)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(MilliColors.cyanGlow))
                    }
            }
            .chartYScale(domain: chartYDomain)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(LinearGradient(colors: [MilliColors.cardBackground, Color.black.opacity(0.32)], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.12), lineWidth: 0.7)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.55, dash: [3, 5]))
                        .foregroundStyle(Color.white.opacity(0.10))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.65))
                        .foregroundStyle(Color.white.opacity(0.20))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactMarketPrice(amount))
                                .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [3, 7]))
                        .foregroundStyle(Color.white.opacity(0.055))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(chartDateLabel(date))
                                .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
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
                Text("MARKET WATCHLIST").sectionHeaderStyle()
                Spacer()
                Text("LIVE WHEN AVAILABLE")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(market.holdings.enumerated()), id: \.element.id) { index, holding in
                    Button {
                        market.switchTicker(holding.ticker)
                        resetChartViewport()
                    } label: {
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
                                Text("—").font(MilliFont.numericSmall).foregroundStyle(MilliColors.textTertiary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)

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

    private var minimumVisibleCandles: Int { 6 }

    private var chartMagnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let base = magnificationBaseCount ?? visibleCandleCount
                if magnificationBaseCount == nil { magnificationBaseCount = visibleCandleCount }
                let adjusted = Int((Double(base) / max(scale, 0.25)).rounded())
                setVisibleCandleCount(adjusted)
            }
            .onEnded { _ in magnificationBaseCount = nil }
    }

    private var chartPanGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height), !market.candles.isEmpty else { return }
                let base = dragBaseEndIndex ?? (chartEndIndex ?? market.candles.count)
                if dragBaseEndIndex == nil { dragBaseEndIndex = base }
                let pointsPerCandle: CGFloat = 13
                let delta = Int((value.translation.width / pointsPerCandle).rounded())
                let minimumEnd = min(visibleCandleCount, market.candles.count)
                chartEndIndex = min(max(base - delta, minimumEnd), market.candles.count)
            }
            .onEnded { _ in dragBaseEndIndex = nil }
    }

    private func zoomChart(out: Bool) {
        let factor = out ? 1.30 : 0.72
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
        case .oneDay: return 24
        case .oneWeek: return 22
        case .oneMonth: return 20
        case .threeMonths: return 24
        case .oneYear: return 28
        case .all: return 30
        }
    }

    private func loadMarketChart(resetViewport: Bool) {
        if resetViewport {
            visibleCandleCount = defaultVisibleCandleCount
            chartEndIndex = nil
        }
        market.fetchChart(for: market.selectedTicker, interval: selectedPeriod.interval, range: selectedPeriod.range)
    }

    private var chartYDomain: ClosedRange<Double> {
        guard let low = visibleCandles.map(\.low).min(),
              let high = visibleCandles.map(\.high).max(),
              high >= low else { return 0...1 }
        let spread = max(high - low, max(high * 0.0025, 0.01))
        let padding = spread * 0.08
        return (low - padding)...(high + padding)
    }

    private var marketPriceText: String { livePriceText(market.currentPrice) }

    private var marketTimestamp: String {
        if let marketTime = market.latestMarketTimestamp {
            return "Market bar \(marketTime.formatted(date: .omitted, time: .shortened))"
        }
        return market.feedStatus == .unavailable ? "No live market update" : "Connecting…"
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

    private var brokerageStatusLabel: String {
        switch brokerage.availability {
        case .checking: return "CHECKING"
        case .available: return "BROKERAGE READY"
        case .setupRequired: return "SETUP REQUIRED"
        case .unavailable: return "UNAVAILABLE"
        }
    }

    private var brokerageStatusColor: Color {
        switch brokerage.availability {
        case .available: return MilliColors.positive
        case .checking: return MilliColors.warning
        case .setupRequired, .unavailable: return MilliColors.textTertiary
        }
    }

    private func livePriceText(_ value: Double) -> String {
        if value >= 10_000 { return value.formatted(.currency(code: "USD").precision(.fractionLength(0))) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    private func compactMarketPrice(_ value: Double) -> String {
        if value >= 10_000 { return String(format: "$%.1fK", value / 1_000) }
        if value >= 1_000 { return String(format: "$%.0f", value) }
        return String(format: "$%.2f", value)
    }

    private func displayTicker(_ ticker: String) -> String { ticker == "BTC-USD" ? "BTC" : ticker }

    private func chartDateLabel(_ date: Date) -> String {
        switch selectedPeriod {
        case .oneDay: return date.formatted(date: .omitted, time: .shortened)
        case .oneWeek: return date.formatted(.dateTime.weekday(.abbreviated).hour())
        default: return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

// MARK: - Trade ticket

private struct BrokerageTradeTicket: View {
    @Environment(\.dismiss) private var dismiss
    let symbol: String
    let marketPrice: Double?
    let service: BrokerageTradingService

    @State private var side: BrokerageOrderSide
    @State private var quantityMode: BrokerageQuantityMode = .dollars
    @State private var orderType: BrokerageOrderType = .market
    @State private var amountText = ""
    @State private var limitPriceText = ""
    @State private var errorMessage: String?
    @State private var submittedOrder: BrokerageOrderResponse?
    @State private var isSubmitting = false

    init(symbol: String, marketPrice: Double?, initialSide: BrokerageOrderSide, service: BrokerageTradingService) {
        self.symbol = symbol
        self.marketPrice = marketPrice
        self.service = service
        _side = State(initialValue: initialSide)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        instrumentHeader
                        sideSelector
                        quantitySelector
                        amountEntry
                        orderTypeSelector
                        if orderType == .limit { limitPriceEntry }
                        orderSummary
                        submitButton
                        disclosure
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Trade \(symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var instrumentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(symbol)
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("US equity")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(marketPrice.map { priceText($0) } ?? "—")
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text(marketPrice == nil ? "Live quote unavailable" : "Reference market price")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .milliCard(padding: 12)
    }

    private var sideSelector: some View {
        Picker("Side", selection: $side) {
            ForEach(BrokerageOrderSide.allCases, id: \.self) { value in
                Text(value.displayName).tag(value)
            }
        }
        .pickerStyle(.segmented)
    }

    private var quantitySelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ORDER SIZE").sectionHeaderStyle()
            Picker("Quantity", selection: $quantityMode) {
                ForEach(BrokerageQuantityMode.allCases, id: \.self) { value in
                    Text(value.displayName).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var amountEntry: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(quantityMode == .dollars ? "Dollar amount" : "Shares")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            TextField(quantityMode == .dollars ? "$0.00" : "0", text: $amountText)
                .keyboardType(.decimalPad)
                .font(MilliFont.numericLarge)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(MilliColors.cardBackground).overlay(RoundedRectangle(cornerRadius: 11).stroke(MilliColors.border, lineWidth: 0.7)))
        }
    }

    private var orderTypeSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ORDER TYPE").sectionHeaderStyle()
            Picker("Order Type", selection: $orderType) {
                ForEach(BrokerageOrderType.allCases, id: \.self) { value in
                    Text(value.displayName).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var limitPriceEntry: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Limit price")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            TextField("$0.00", text: $limitPriceText)
                .keyboardType(.decimalPad)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(MilliColors.cardBackground).overlay(RoundedRectangle(cornerRadius: 11).stroke(MilliColors.border, lineWidth: 0.7)))
        }
    }

    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REVIEW").sectionHeaderStyle()
            summaryRow("Action", "\(side.displayName) \(symbol)")
            summaryRow("Order", orderType.displayName)
            summaryRow(quantityMode == .dollars ? "Amount" : "Shares", amountDisplay)
            if orderType == .limit { summaryRow("Limit", limitDisplay) }
            if let errorMessage {
                Text(errorMessage)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.negative)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let submittedOrder {
                Text("Order \(submittedOrder.status.uppercased())")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.positive)
            }
        }
        .milliCard(padding: 12)
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(MilliFont.bodySmall).foregroundStyle(MilliColors.textSecondary)
            Spacer()
            Text(value).font(MilliFont.bodySmall).foregroundStyle(MilliColors.textPrimary)
        }
    }

    private var submitButton: some View {
        Button {
            submitOrder()
        } label: {
            HStack(spacing: 7) {
                if isSubmitting { ProgressView().tint(side == .buy ? MilliColors.blackGlass : MilliColors.textPrimary) }
                Text(submitTitle)
                    .font(MilliFont.labelLarge)
            }
            .foregroundStyle(side == .buy ? MilliColors.blackGlass : MilliColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(side == .buy ? MilliColors.cyanGlow : Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSubmitting)
        .opacity(canSubmit ? 1 : 0.45)
    }

    private var disclosure: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Brokerage account required")
                .font(MilliFont.labelLarge)
                .foregroundStyle(MilliColors.textSecondary)
            Text("Trading must be provided through an approved broker-dealer integration. Market orders may execute at a different price than the quote shown. Limit orders may not execute. Milli will not show a successful trade unless the brokerage backend accepts the order.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
    }

    private var parsedLimit: Double? {
        Double(limitPriceText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
    }

    private var canSubmit: Bool {
        guard let amount = parsedAmount, amount > 0 else { return false }
        if orderType == .limit {
            guard let limit = parsedLimit, limit > 0 else { return false }
        }
        if case .available = service.availability { return true }
        return false
    }

    private var submitTitle: String {
        switch service.availability {
        case .available: return "Review & Submit \(side.displayName)"
        case .checking: return "Checking brokerage account"
        case .setupRequired: return "Brokerage Setup Required"
        case .unavailable: return "Trading Unavailable"
        }
    }

    private var amountDisplay: String {
        guard let amount = parsedAmount else { return "—" }
        return quantityMode == .dollars ? amount.formatted(.currency(code: "USD")) : String(format: "%.4f", amount)
    }

    private var limitDisplay: String {
        guard let limit = parsedLimit else { return "—" }
        return limit.formatted(.currency(code: "USD"))
    }

    private func submitOrder() {
        guard let amount = parsedAmount, amount > 0 else { return }
        let request = BrokerageOrderRequest(
            symbol: symbol,
            side: side,
            type: orderType,
            quantityMode: quantityMode,
            amount: amount,
            limitPrice: orderType == .limit ? parsedLimit : nil,
            clientOrderID: UUID().uuidString
        )

        errorMessage = nil
        submittedOrder = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                submittedOrder = try await service.submit(request)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func priceText(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(value >= 10_000 ? 0 : 2)))
    }
}

// MARK: - Brokerage transport

enum BrokerageOrderSide: String, Codable, CaseIterable {
    case buy
    case sell
    var displayName: String { rawValue.capitalized }
}

enum BrokerageOrderType: String, Codable, CaseIterable {
    case market
    case limit
    var displayName: String { rawValue.capitalized }
}

enum BrokerageQuantityMode: String, Codable, CaseIterable {
    case dollars
    case shares
    var displayName: String { self == .dollars ? "Dollars" : "Shares" }
}

struct BrokerageOrderRequest: Codable {
    let symbol: String
    let side: BrokerageOrderSide
    let type: BrokerageOrderType
    let quantityMode: BrokerageQuantityMode
    let amount: Double
    let limitPrice: Double?
    let clientOrderID: String
}

struct BrokerageOrderResponse: Codable {
    let id: String
    let clientOrderID: String?
    let symbol: String
    let side: String
    let status: String
    let submittedAt: Date?
}

enum BrokerageAvailability: Equatable {
    case checking
    case available
    case setupRequired
    case unavailable(String)
}

enum BrokerageTradingError: LocalizedError {
    case notConfigured
    case missingSession
    case invalidResponse
    case rejected(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Brokerage trading is not configured for this build."
        case .missingSession: return "Sign in again before submitting a trade."
        case .invalidResponse: return "Milli could not verify the brokerage response."
        case .rejected(let message): return message
        }
    }
}

@MainActor
final class BrokerageTradingService: ObservableObject {
    @Published private(set) var availability: BrokerageAvailability = .checking
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        refreshAvailability()
    }

    func refreshAvailability() {
        guard backendBaseURL != nil else {
            availability = .setupRequired
            return
        }
        availability = .available
    }

    func submit(_ order: BrokerageOrderRequest) async throws -> BrokerageOrderResponse {
        guard let baseURL = backendBaseURL else { throw BrokerageTradingError.notConfigured }
        guard let token = UserDefaults.standard.string(forKey: "milli_backend_access_token"), !token.isEmpty else {
            throw BrokerageTradingError.missingSession
        }

        var request = URLRequest(url: baseURL.appending(path: "api/brokerage/orders"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(order.clientOrderID, forHTTPHeaderField: "Idempotency-Key")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(order)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BrokerageTradingError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                ?? "The brokerage rejected this order."
            throw BrokerageTradingError.rejected(message)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(BrokerageOrderResponse.self, from: data) else {
            throw BrokerageTradingError.invalidResponse
        }
        return decoded
    }

    private var backendBaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "MILLI_API_BASE_URL") as? String,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return URL(string: raw)
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
