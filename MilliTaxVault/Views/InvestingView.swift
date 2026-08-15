import SwiftUI
import Charts

// MARK: - InvestingView — Live Portfolio Overview with Market Data
struct InvestingView: View {
    
    @StateObject private var marketVM = MarketDataViewModel()
    
    // Sample portfolio data
    private let portfolioValue = "$62,350"
    private let monthlyReturn = "+7.2%"
    
    private let allocations: [AllocationSlice] = [
        .init(label: "Stocks", percentage: 45, color: Color(hex: "00E5FF")),
        .init(label: "ETFs", percentage: 30, color: Color(hex: "7C4DFF")),
        .init(label: "Crypto", percentage: 15, color: Color(hex: "FF6D00")),
        .init(label: "Cash", percentage: 10, color: Color(hex: "4CAF50")),
    ]
    
    var body: some View {
        VStack(spacing: MilliLayout.sectionGap) {
            // Market Indices Bar
            marketIndicesBar
            
            // Live Market Chart
            LiveMarketChartView(viewModel: marketVM)
            
            // Portfolio Summary Card
            portfolioSummaryCard
            
            // Allocation Breakdown
            allocationCard
            
            // Live Holdings List
            holdingsSection
            
            // AI Insight
            aiInsightCard
        }
        .padding(.horizontal, MilliLayout.screenMargin)
        .padding(.top, 60)
        .onAppear { marketVM.startAutoRefresh() }
        .onDisappear { marketVM.stopAutoRefresh() }
    }
    
    // MARK: - Market Indices Bar
    private var marketIndicesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(marketVM.indices) { idx in
                    indexChip(idx)
                }
            }
        }
    }
    
    private func indexChip(_ index: MarketIndex) -> some View {
        HStack(spacing: 6) {
            Text(index.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
            
            Text(String(format: "%.0f", index.value))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MilliColors.textSecondary)
            
            HStack(spacing: 2) {
                Image(systemName: index.change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 7, weight: .bold))
                Text(String(format: "%.2f%%", abs(index.change)))
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(index.change >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF5252"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: "12141A"))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Portfolio Summary
    private var portfolioSummaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL PORTFOLIO")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.5)
                
                Text(portfolioValue)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MilliColors.cyan)
                    Text(monthlyReturn)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MilliColors.cyan)
                    Text("this month")
                        .font(.system(size: 12))
                        .foregroundStyle(MilliColors.textMuted)
                }
            }
            Spacer()
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
    
    // MARK: - Allocation Breakdown
    private var allocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALLOCATION")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .tracking(0.5)
            
            // Horizontal stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(allocations) { slice in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(slice.color)
                            .frame(width: geo.size.width * CGFloat(slice.percentage) / 100.0)
                    }
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            // Labels
            HStack(spacing: 12) {
                ForEach(allocations) { slice in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 6, height: 6)
                        Text("\(slice.label) \(slice.percentage)%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
    
    // MARK: - Live Holdings
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOLDINGS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            ForEach(marketVM.holdings) { holding in
                holdingRow(holding)
            }
        }
    }
    
    private func holdingRow(_ item: LiveHolding) -> some View {
        HStack(spacing: 10) {
            // Ticker badge
            VStack(spacing: 2) {
                Text(item.ticker.replacingOccurrences(of: "-USD", with: ""))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text(item.name)
                    .font(.system(size: 9))
                    .foregroundStyle(MilliColors.textMuted)
                    .lineLimit(1)
            }
            .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // Mini sparkline
            MiniSparkline(data: item.sparkData, positive: item.change >= 0)
                .frame(width: 50, height: 20)
            
            Spacer()
            
            // Price + change
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatHoldingPrice(item.price))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(String(format: "%@%.1f%%", item.change >= 0 ? "+" : "", item.change))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(item.change >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF5252"))
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, 12)
        .milliSurface()
    }
    
    // MARK: - AI Insight
    private var aiInsightCard: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.1))
                    .frame(width: 32, height: 32)
                Text("M")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(MilliColors.cyan)
            }
            
            Text("Your portfolio is outperforming the S&P 500 by 2.1% this quarter. Consider rebalancing crypto allocation.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, 12)
        .milliSurface()
    }
    
    // MARK: - Helpers
    private func formatHoldingPrice(_ price: Double) -> String {
        if price >= 10000 {
            return "$\(String(format: "%.0f", price))"
        }
        return "$\(String(format: "%.2f", price))"
    }
}

// MARK: - Mini Sparkline
struct MiniSparkline: View {
    let data: [Double]
    let positive: Bool
    
    var body: some View {
        GeometryReader { geo in
            let maxVal = data.max() ?? 1
            let minVal = data.min() ?? 0
            let range = maxVal - minVal == 0 ? 1 : maxVal - minVal
            
            Path { path in
                for (index, value) in data.enumerated() {
                    let x = geo.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let y = geo.size.height * (1 - CGFloat((value - minVal) / range))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(positive ? Color(hex: "4CAF50") : Color(hex: "FF5252"), lineWidth: 1.5)
        }
    }
}

// MARK: - Data Models
struct AllocationSlice: Identifiable {
    let id = UUID()
    let label: String
    let percentage: Int
    let color: Color
}

#Preview {
    ScrollView {
        InvestingView()
    }
    .background(MilliColors.obsidian)
}
