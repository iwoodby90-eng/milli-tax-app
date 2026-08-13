import SwiftUI

struct InvestingView: View {
    @State private var balanceVisible = true
    @State private var selectedTimeFilter = "1D"
    let timeFilters = ["1D", "1W", "1M", "1Y", "All"]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // MARK: Header
                    headerSection
                    
                    // MARK: Hero
                    heroCard
                    
                    // MARK: Market Overview
                    marketOverviewCard
                    
                    // MARK: Today's Gain + Buying Power
                    gainAndBuyingRow
                    
                    // MARK: Watchlist + Asset Allocation
                    watchlistAndAllocationRow
                    
                    // MARK: Milli AI Insight
                    aiInsightCard
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliAICompanion()
        }
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("milli")
                    .font(.system(size: 22, weight: .bold))
                    .italic()
                    .foregroundStyle(Color(hex: "00E5FF"))
                    .tracking(1)
                Spacer()
                
                HStack(spacing: 4) {
                    Text("All Accounts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: "121620")))
            }
            
            Text("Investing")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Track. Analyze. Grow.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .padding(.horizontal, MilliSpacing.xl)
        .padding(.top, MilliSpacing.lg)
    }
    
    // MARK: - Hero Card
    private var heroCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack(spacing: 6) {
                    Text("Total Portfolio Value")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Button(action: { balanceVisible.toggle() }) {
                        Image(systemName: balanceVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "8E92A0"))
                    }
                }
                
                Text(balanceVisible ? "$124,560.00" : "••••••")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "34C759"))
                    Text("+$2,340.50 (1.91%) today")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "34C759"))
                }
            }
            
            Spacer()
            
            MilliMetalCard(size: CGSize(width: 140, height: 90))
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Market Overview
    private var marketOverviewCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            // Header
            HStack {
                Text("Market Overview")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "34C759"))
                        .frame(width: 6, height: 6)
                    Text("Live")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "34C759"))
                }
                
                Spacer()
                
                Text("5,321.41")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "00E5FF").opacity(0.12)))
            }
            
            Text("S&P 500 · SPX")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E92A0"))
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("5,321.41")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("+24.39 (0.46%)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "34C759"))
            }
            
            // Candlestick chart
            candlestickChart
                .frame(height: 160)
            
            // Time filter pills
            HStack(spacing: MilliSpacing.sm) {
                ForEach(timeFilters, id: \.self) { filter in
                    Text(filter)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(selectedTimeFilter == filter ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(selectedTimeFilter == filter ? Color(hex: "00E5FF") : Color.clear, lineWidth: 1)
                                .background(Capsule().fill(selectedTimeFilter == filter ? Color(hex: "00E5FF").opacity(0.1) : .clear))
                        )
                        .onTapGesture { selectedTimeFilter = filter }
                }
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private var candlestickChart: some View {
        Canvas { context, size in
            let barCount = 30
            let barWidth: CGFloat = size.width / CGFloat(barCount) * 0.6
            let gap: CGFloat = size.width / CGFloat(barCount) * 0.4
            let minPrice: CGFloat = 5100
            let maxPrice: CGFloat = 5350
            let priceRange = maxPrice - minPrice
            
            // Y-axis labels
            let yLabels: [CGFloat] = [5100, 5150, 5200, 5250, 5300, 5350]
            for label in yLabels {
                let y = size.height - ((label - minPrice) / priceRange) * size.height
                var gridLine = Path()
                gridLine.move(to: CGPoint(x: 0, y: y))
                gridLine.addLine(to: CGPoint(x: size.width - 40, y: y))
                context.stroke(gridLine, with: .color(.white.opacity(0.03)), lineWidth: 0.5)
                context.draw(Text("\(Int(label))").font(.system(size: 10)).foregroundColor(Color(hex: "8E92A0")), at: CGPoint(x: size.width - 18, y: y))
            }
            
            // Generate candlesticks with upward trend
            var basePrice: CGFloat = 5140
            for i in 0..<barCount {
                let x = CGFloat(i) * (barWidth + gap) + gap / 2
                let trend: CGFloat = CGFloat(i) * 5.5
                let noise = CGFloat.random(in: -15...15)
                let open = basePrice + trend + noise
                let close = open + CGFloat.random(in: -12...18)
                let high = max(open, close) + CGFloat.random(in: 2...10)
                let low = min(open, close) - CGFloat.random(in: 2...10)
                
                let isGreen = close > open
                let color: Color = isGreen ? Color(hex: "34C759") : Color(hex: "FF3B30")
                
                let bodyTop = size.height - ((max(open, close) - minPrice) / priceRange) * size.height
                let bodyBottom = size.height - ((min(open, close) - minPrice) / priceRange) * size.height
                let wickTop = size.height - ((high - minPrice) / priceRange) * size.height
                let wickBottom = size.height - ((low - minPrice) / priceRange) * size.height
                
                // Wick
                var wick = Path()
                wick.move(to: CGPoint(x: x + barWidth / 2, y: wickTop))
                wick.addLine(to: CGPoint(x: x + barWidth / 2, y: wickBottom))
                context.stroke(wick, with: .color(Color(hex: "8E92A0").opacity(0.6)), lineWidth: 1)
                
                // Body
                let bodyRect = CGRect(x: x, y: bodyTop, width: barWidth, height: max(bodyBottom - bodyTop, 1))
                context.fill(Path(bodyRect), with: .color(color))
                
                basePrice = close > 5100 ? basePrice : 5140
            }
        }
    }
    
    // MARK: - Gain & Buying Power
    private var gainAndBuyingRow: some View {
        HStack(spacing: MilliSpacing.md) {
            // Today's Gain/Loss
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("Today's Gain/Loss")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                Text("+$2,340.50")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "34C759"))
                
                Text("1.91%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "34C759"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "34C759").opacity(0.12)))
                
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "34C759")).frame(width: 6, height: 6)
                    Text("Market opened")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
            }
            .padding(MilliSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
            
            // Buying Power
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("Buying Power")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                Text("$8,750.00")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Available to invest")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                // Coin stack
                HStack(spacing: -4) {
                    ForEach(0..<3, id: \.self) { i in
                        ZStack {
                            Circle()
                                .fill(Color(hex: "1A1F2E"))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(Color(hex: "00E5FF").opacity(0.4), lineWidth: 1))
                            Text("M")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color(hex: "00E5FF"))
                        }
                    }
                }
            }
            .padding(MilliSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Watchlist & Allocation
    private var watchlistAndAllocationRow: some View {
        HStack(alignment: .top, spacing: MilliSpacing.md) {
            // Watchlist
            VStack(alignment: .leading, spacing: MilliSpacing.md) {
                HStack {
                    Text("Watchlist")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("View all")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                
                watchlistRow(ticker: "AAPL", name: "Apple Inc.", price: "$192.58", change: "+1.35%", isPositive: true, color: Color(hex: "4A90D9"))
                watchlistRow(ticker: "TSLA", name: "Tesla Inc.", price: "$178.65", change: "-0.85%", isPositive: false, color: Color(hex: "E31937"))
                watchlistRow(ticker: "NVDA", name: "NVIDIA", price: "$950.02", change: "+2.35%", isPositive: true, color: Color(hex: "76B900"))
            }
            .padding(MilliSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
            
            // Asset Allocation
            VStack(alignment: .leading, spacing: MilliSpacing.md) {
                HStack {
                    Text("Asset Allocation")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("View all")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                
                // Donut chart
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: 0.65, to: 0.85)
                        .stroke(Color(hex: "00E5FF"), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: 0.85, to: 0.95)
                        .stroke(Color(hex: "8E92A0"), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: 0.95, to: 1.0)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                .frame(maxWidth: .infinity)
                
                // Legend
                VStack(alignment: .leading, spacing: 4) {
                    allocationLegend(color: .blue, label: "Stocks", pct: "65%")
                    allocationLegend(color: Color(hex: "00E5FF"), label: "ETFs", pct: "20%")
                    allocationLegend(color: Color(hex: "8E92A0"), label: "Cash", pct: "10%")
                    allocationLegend(color: .purple, label: "Crypto", pct: "5%")
                }
            }
            .padding(MilliSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func watchlistRow(ticker: String, name: String, price: String, change: String, isPositive: Bool, color: Color) -> some View {
        HStack(spacing: MilliSpacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(ticker.prefix(1)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                Text(ticker)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(name)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "8E92A0"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                Text(price)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(change)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isPositive ? Color(hex: "34C759") : Color(hex: "FF3B30"))
            }
        }
    }
    
    private func allocationLegend(color: Color, label: String, pct: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "8E92A0"))
            Spacer()
            Text(pct)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - AI Insight
    private var aiInsightCard: some View {
        HStack(spacing: MilliSpacing.lg) {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "00E5FF"))
                    Text("Milli AI Insight")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                
                Text("Tech sector momentum is strong. Your exposure is aligned with growth trends and positioned for long-term compounding.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("AI Confidence: High")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            
            // Robot orb
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1F2E"))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color(hex: "00E5FF").opacity(0.3), lineWidth: 1))
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: "00E5FF")).frame(width: 5, height: 5)
                    Circle().fill(Color(hex: "00E5FF")).frame(width: 5, height: 5)
                }
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color(hex: "00E5FF"), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
}

#Preview {
    InvestingView()
}
