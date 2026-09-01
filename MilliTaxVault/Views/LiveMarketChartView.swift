import SwiftUI
import UIKit
import Charts

// MARK: - LiveMarketChartView
// Real market chart with explicit loading/live/unavailable state.

struct LiveMarketChartView: View {
    @ObservedObject var viewModel: MarketDataViewModel

    private let tickers = ["AAPL", "VOO", "BTC-USD", "NVDA", "QQQ"]
    private let tickerLabels = ["AAPL", "VOO", "BTC", "NVDA", "QQQ"]

    @State private var livePulse = false

    var body: some View {
        VStack(spacing: 12) {
            tickerSelector
            priceHeader
            chartView
            lastUpdatedRow
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface(hasCyanBorder: true)
        .onAppear {
            if !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    livePulse = true
                }
            }
        }
    }

    private var tickerSelector: some View {
        HStack(spacing: 4) {
            ForEach(Array(zip(tickers, tickerLabels)), id: \.0) { ticker, label in
                Button {
                    viewModel.switchTicker(ticker)
                } label: {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(viewModel.selectedTicker == ticker ? MilliColors.obsidian : MilliColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.selectedTicker == ticker
                            ? Capsule().fill(MilliColors.cyan)
                            : Capsule().fill(Color.white.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var priceHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.feedStatus == .live ? formatPrice(viewModel.currentPrice) : "—")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if viewModel.feedStatus == .live {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(changeColor)

                        Text(String(format: "%@%.2f", viewModel.priceChange >= 0 ? "+" : "", viewModel.priceChange))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(changeColor)

                        Text(String(format: "(%@%.2f%%)", viewModel.percentChange >= 0 ? "+" : "", viewModel.percentChange))
                            .font(.system(size: 12))
                            .foregroundStyle(changeColor)
                    }
                } else {
                    Text(viewModel.feedStatus == .loading ? "Connecting to market feed…" : "Market feed unavailable")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textMuted)
                }
            }

            Spacer()
            feedBadge
        }
    }

    private var feedBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(feedColor)
                .frame(width: 6, height: 6)
                .opacity(viewModel.feedStatus == .live ? (livePulse ? 1 : 0.35) : 1)

            Text(feedLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(feedColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(feedColor.opacity(0.10))
                .overlay(Capsule().stroke(feedColor.opacity(0.28), lineWidth: 0.5))
        )
    }

    @ViewBuilder
    private var chartView: some View {
        if viewModel.feedStatus == .loading {
            chartPlaceholder {
                ProgressView().tint(MilliColors.cyan)
            }
        } else if viewModel.feedStatus == .unavailable || viewModel.chartPoints.isEmpty {
            chartPlaceholder {
                VStack(spacing: 7) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MilliColors.textMuted)
                    Text("Live market data unavailable")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textMuted)
                    Button("Retry") {
                        viewModel.fetchChart(for: viewModel.selectedTicker)
                    }
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        } else {
            Chart(viewModel.chartPoints) { point in
                AreaMark(
                    x: .value("Time", point.time),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.cyan.opacity(0.3), MilliColors.cyan.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(MilliColors.cyan)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatTime(date))
                                .font(.system(size: 8))
                                .foregroundStyle(MilliColors.textMuted)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatCompactPrice(val))
                                .font(.system(size: 8))
                                .foregroundStyle(MilliColors.textMuted)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
    }

    private func chartPlaceholder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.02))
            .frame(height: 180)
            .overlay(content())
    }

    private var lastUpdatedRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 9))
                .foregroundStyle(MilliColors.textMuted)
                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                .animation(
                    viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                    value: viewModel.isLoading
                )

            Text(lastUpdatedText)
                .font(.system(size: 10))
                .foregroundStyle(MilliColors.textMuted)

            Spacer()
        }
    }

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdated else {
            return viewModel.feedStatus == .unavailable ? "No live update available" : "Connecting…"
        }
        return "Last updated: \(formatTimestamp(date))"
    }

    private var feedLabel: String {
        switch viewModel.feedStatus {
        case .loading: return "CONNECTING"
        case .live: return "LIVE"
        case .unavailable: return "OFFLINE"
        }
    }

    private var feedColor: Color {
        switch viewModel.feedStatus {
        case .loading: return MilliColors.warning
        case .live: return MilliColors.cyan
        case .unavailable: return MilliColors.textMuted
        }
    }

    private var changeColor: Color {
        viewModel.priceChange >= 0 ? MilliColors.positive : MilliColors.negative
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 10_000 {
            return "$\(String(format: "%.0f", price))"
        }
        return "$\(String(format: "%.2f", price))"
    }

    private func formatCompactPrice(_ value: Double) -> String {
        if value >= 10_000 {
            return "$\(String(format: "%.0fK", value / 1000))"
        }
        return "$\(String(format: "%.0f", value))"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    LiveMarketChartView(viewModel: MarketDataViewModel())
        .padding()
        .background(MilliColors.obsidian)
}
