import SwiftUI
import Charts

struct InvestingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: TimePeriod = .oneMonth
    
    enum TimePeriod: String, CaseIterable {
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case all = "ALL"
    }
    
    private let marketTickers: [(name: String, value: String, change: String)] = [
        ("S&P 500", "5,842.30", "+1.24%"),
        ("NASDAQ", "18,920.15", "+1.68%"),
        ("DOW", "43,112.80", "+0.87%"),
    ]
    
    private let holdings: [(ticker: String, name: String, value: Double, change: Double, color: Color)] = [
        ("VTI", "Vanguard Total Market", 8420.50, 2.14, .milliCyan),
        ("VOO", "Vanguard S&P 500", 6180.30, 1.87, .milliSuccess),
        ("QQQM", "Invesco NASDAQ 100", 4920.80, 2.45, Color(hex: "A855F7")),
        ("SCHD", "Schwab US Dividend", 3280.40, 0.92, .milliWarning),
    ]
    
    private var portfolioValue: Double { holdings.reduce(0) { $0 + $1.value } }
    
    private var chartData: [(index: Int, value: Double)] {
        switch selectedPeriod {
        case .oneDay: return (0..<24).map { (index: $0, value: 22500 + Double.random(in: -200...300)) }
        case .oneWeek: return (0..<7).map { (index: $0, value: 22000 + Double($0) * 50 + Double.random(in: -100...100)) }
        case .oneMonth: return (0..<30).map { (index: $0, value: 21000 + Double($0) * 55 + Double.random(in: -150...150)) }
        case .threeMonths: return (0..<90).map { (index: $0, value: 18000 + Double($0) * 52 + Double.random(in: -200...200)) }
        case .oneYear: return (0..<12).map { (index: $0, value: 14000 + Double($0) * 750 + Double.random(in: -300...300)) }
        case .all: return (0..<24).map { (index: $0, value: 5000 + Double($0) * 780 + Double.random(in: -400...400)) }
        }
    }
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Investing", showBack: true, onBack: { dismiss() })
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Market Ticker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(marketTickers, id: \.name) { ticker in
                                    HStack(spacing: 8) {
                                        Text(ticker.name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.milliTextSecondary)
                                        Text(ticker.value)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Text(ticker.change)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.milliSuccess)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.milliSuccess.opacity(0.12))
                                            .cornerRadius(4)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.milliCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.milliCardBorder, lineWidth: 0.5)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Portfolio Value Card
                        MilliCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PORTFOLIO VALUE")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                
                                Text("$\(String(format: "%.2f", portfolioValue))")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("+$342.80 today")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.milliSuccess)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        
                        // Period Selector
                        HStack(spacing: 4) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Button(action: { selectedPeriod = period }) {
                                    Text(period.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(selectedPeriod == period ? .white : .milliTextSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedPeriod == period ? Color.milliCyan.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Line Chart
                        MilliCard {
                            Chart(chartData, id: \.index) { point in
                                LineMark(
                                    x: .value("Time", point.index),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(Color.milliCyan.gradient)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Time", point.index),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.milliCyan.opacity(0.2), Color.milliCyan.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                            }
                            .chartYAxis(.hidden)
                            .chartXAxis(.hidden)
                            .frame(height: 180)
                        }
                        .padding(.horizontal, 20)
                        
                        // Top Holdings
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TOP HOLDINGS")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.milliTextSecondary)
                                .padding(.leading, 4)
                            
                            ForEach(holdings, id: \.ticker) { holding in
                                MilliCard {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(holding.color)
                                            .frame(width: 10, height: 10)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(holding.ticker)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(holding.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(.milliTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("$\(String(format: "%.2f", holding.value))")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text("+\(String(format: "%.2f", holding.change))%")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.milliSuccess)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
