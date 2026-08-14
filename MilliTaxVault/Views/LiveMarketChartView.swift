import SwiftUI
import Charts

// MARK: - LiveMarketChartView — Real-time market chart with ticker switching
struct LiveMarketChartView: View {
    @ObservedObject var viewModel: MarketDataViewModel
    
    private let tickers = ["AAPL", "VOO", "BTC-USD", "NVDA", "QQQ"]
    private let tickerLabels = ["AAPL", "VOO", "BTC", "NVDA", "QQQ"]
    
    @State private var livePulse: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Ticker Picker
            tickerSelector
            
            // Price Header
            priceHeader
            
            // Live Chart
            chartView
            
            // Last Updated
            lastUpdatedRow
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface(hasCyanBorder: true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                livePulse = true
            }
        }
    }
    
    // MARK: - Ticker Selector
    private var tickerSelector: some View {
        HStack(spacing: 4) {
            ForEach(Array(zip(tickers, tickerLabels)), id: \.0) { ticker, label in
                Button(action: {
                    viewModel.switchTicker(ticker)
                }) {
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
    
    // MARK: - Price Header
    private var priceHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatPrice(viewModel.currentPrice))
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                HStack(spacing: 6) {
                    Image(systemName: viewModel.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(viewModel.priceChange >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF5252"))
                    
                    Text(String(format: "%@%.2f", viewModel.priceChange >= 0 ? "+" : "", viewModel.priceChange))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(viewModel.priceChange >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF5252"))
                    
                    Text(String(format: "(%@%.2f%%)", viewModel.percentChange >= 0 ? "+" : "", viewModel.percentChange))
                        .font(.system(size: 12))
                        .foregroundStyle(viewModel.percentChange >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF5252"))
                }
            }
            
            Spacer()
            
            // LIVE badge
            HStack(spacing: 4) {
                Circle()
                    .fill(MilliColors.cyan)
                    .frame(width: 6, height: 6)
                    .opacity(livePulse ? 1.0 : 0.3)
                
                Text("LIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(MilliColors.cyan)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(MilliColors.cyan.opacity(0.1))
                    .overlay(Capsule().stroke(MilliColors.cyan.opacity(0.3), lineWidth: 0.5))
            )
        }
    }
    
    // MARK: - Chart
    private var chartView: some View {
        Group {
            if viewModel.chartPoints.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.02))
                    .frame(height: 180)
                    .overlay(
                        ProgressView()
                            .tint(MilliColors.cyan)
                    )
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
    }
    
    // MARK: - Last Updated
    private var lastUpdatedRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 9))
                .foregroundStyle(MilliColors.textMuted)
                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
            
            Text("Last updated: \(formatTimestamp(viewModel.lastUpdated))")
                .font(.system(size: 10))
                .foregroundStyle(MilliColors.textMuted)
            
            Spacer()
        }
    }
    
    // MARK: - Formatters
    private func formatPrice(_ price: Double) -> String {
        if price >= 10000 {
            return "$\(String(format: "%.0f", price))"
        } else if price >= 100 {
            return "$\(String(format: "%.2f", price))"
        }
        return "$\(String(format: "%.2f", price))"
    }
    
    private func formatCompactPrice(_ val: Double) -> String {
        if val >= 10000 {
            return "$\(String(format: "%.0fK", val / 1000))"
        }
        return "$\(String(format: "%.0f", val))"
    }
    
    private func formatTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mma"
        return fmt.string(from: date).lowercased()
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
}

#Preview {
    LiveMarketChartView(viewModel: MarketDataViewModel())
        .padding()
        .background(MilliColors.obsidian)
}
