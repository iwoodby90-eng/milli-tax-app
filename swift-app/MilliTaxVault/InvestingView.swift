import SwiftUI
import Charts

// MARK: - Investing View

struct InvestingView: View {
    @State private var selectedRange: String = "1M"
    
    private let timeRanges = ["1D", "1W", "1M", "3M", "1Y", "ALL"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                marketTickerPills
                portfolioValueCard
                timeRangeSelector
                candlestickChart
                topHoldingsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.milliBackground)
    }
    
    // MARK: - Market Ticker Pills
    
    private var marketTickerPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                TickerPillView(
                    name: "S&P 500",
                    price: "5,278.40",
                    change: "+1.15%",
                    isPositive: true,
                    sparklinePoints: [0.2, 0.35, 0.3, 0.5, 0.65, 0.8]
                )
                TickerPillView(
                    name: "NASDAQ",
                    price: "16,735.02",
                    change: "+1.35%",
                    isPositive: true,
                    sparklinePoints: [0.1, 0.25, 0.4, 0.35, 0.6, 0.85]
                )
                TickerPillView(
                    name: "DOW JONES",
                    price: "39,134.76",
                    change: "+0.78%",
                    isPositive: true,
                    sparklinePoints: [0.3, 0.28, 0.4, 0.55, 0.5, 0.7]
                )
            }
        }
    }
    
    // MARK: - Portfolio Value Card
    
    private var portfolioValueCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Portfolio Value")
                .font(.caption)
                .foregroundColor(.milliMuted)
            
            Text("$42,685.73")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.white)
            
            Text("+$1,324.67 (3.21%) Today")
                .font(.callout)
                .foregroundColor(.milliGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .milliCard()
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(timeRanges, id: \.self) { range in
                Text(range)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(selectedRange == range ? .milliAccent : .milliMuted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedRange == range
                            ? Color.milliCard
                            : Color.clear
                    )
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedRange = range
                    }
            }
            Spacer()
        }
    }
    
    // MARK: - Candlestick Chart
    
    private var candlestickChart: some View {
        Chart {
            ForEach(MockCandleData.candles) { candle in
                BarMark(
                    x: .value("Date", candle.date),
                    yStart: .value("Open", candle.open),
                    yEnd: .value("Close", candle.close),
                    width: 6
                )
                .foregroundStyle(candle.close >= candle.open ? Color.milliGreen : Color.milliRed)
                
                // Wick
                BarMark(
                    x: .value("Date", candle.date),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high),
                    width: 1
                )
                .foregroundStyle(candle.close >= candle.open ? Color.milliGreen : Color.milliRed)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel()
                    .foregroundStyle(Color.milliMuted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.milliMuted.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.milliMuted)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .frame(height: 200)
        .padding(.vertical, 8)
        
        // LIVE_API_PLACEHOLDER: Replace mock data with TwelveData/Polygon WebSocket
    }
    
    // MARK: - Top Holdings Section
    
    private var topHoldingsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Top Holdings")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("View All")
                    .font(.caption)
                    .foregroundColor(.milliAccent)
            }
            
            ForEach(HoldingData.holdings) { holding in
                HoldingRowView(holding: holding)
            }
        }
    }
}

// MARK: - Ticker Pill View

struct TickerPillView: View {
    let name: String
    let price: String
    let change: String
    let isPositive: Bool
    let sparklinePoints: [CGFloat]
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
                Text(price)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(change)
                    .font(.caption2)
                    .foregroundColor(isPositive ? .milliGreen : .milliRed)
            }
            
            SparklineView(points: sparklinePoints, color: isPositive ? .milliGreen : .milliRed)
                .frame(width: 30, height: 16)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.milliCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Sparkline View

struct SparklineView: View {
    let points: [CGFloat]
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard points.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(points.count - 1)
                let height = geo.size.height
                
                path.move(to: CGPoint(x: 0, y: height * (1 - points[0])))
                for i in 1..<points.count {
                    path.addLine(to: CGPoint(x: stepX * CGFloat(i), y: height * (1 - points[i])))
                }
            }
            .stroke(color, lineWidth: 1.5)
        }
    }
}

// MARK: - Holding Row View

struct HoldingRowView: View {
    let holding: HoldingData
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(holding.avatarColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(holding.ticker)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.name)
                    .font(.callout)
                    .foregroundColor(.white)
                Text(holding.ticker)
                    .font(.caption)
                    .foregroundColor(.milliMuted)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.price)
                    .font(.callout)
                    .foregroundColor(.white)
                Text(holding.change)
                    .font(.caption)
                    .foregroundColor(.milliGreen)
            }
        }
    }
}

// MARK: - Mock Data

struct CandleDataPoint: Identifiable {
    let id = UUID()
    let date: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}

struct MockCandleData {
    static let candles: [CandleDataPoint] = (0..<30).map { i in
        let basePrice = 180.0 + Double(i) * 0.8
        let openVal = basePrice + Double.random(in: -3...3)
        let closeVal = basePrice + Double.random(in: -3...3)
        let highVal = max(openVal, closeVal) + Double.random(in: 0.5...2.5)
        let lowVal = min(openVal, closeVal) - Double.random(in: 0.5...2.5)
        return CandleDataPoint(date: i + 1, open: openVal, high: highVal, low: lowVal, close: closeVal)
    }
}

struct HoldingData: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let price: String
    let change: String
    let avatarColor: Color
    
    static let holdings: [HoldingData] = [
        HoldingData(ticker: "VTI", name: "Vanguard Total Stock Market ETF", price: "$12,685.43", change: "+4.35%", avatarColor: Color(hex: "1A8A7A")),
        HoldingData(ticker: "VOO", name: "Vanguard S&P 500 ETF", price: "$9,742.21", change: "+3.20%", avatarColor: Color(hex: "2E5FA1")),
        HoldingData(ticker: "QQQM", name: "Invesco NASDAQ 100 ETF", price: "$6,521.37", change: "+2.18%", avatarColor: Color(hex: "3A7BC8")),
        HoldingData(ticker: "SCHD", name: "Schwab U.S. Dividend Equity ETF", price: "$3,856.12", change: "+1.25%", avatarColor: Color(hex: "4A9BD4")),
    ]
}

// MARK: - Preview

#Preview {
    InvestingView()
        .preferredColorScheme(.dark)
}
