import SwiftUI
import Charts

struct WealthView: View {
    @State private var selectedTimeFilter: String = "1M"
    private let timeFilters = ["1W", "1M", "3M", "1Y", "ALL"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - MILLI Wordmark
                VStack(spacing: 6) {
                    Text("MILLI")
                        .font(.system(size: 28, weight: .black))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Money, Made Intelligent.")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.cyan)
                }
                .padding(.top, 20)
                
                // MARK: - Available to Spend
                VStack(spacing: 8) {
                    Text("AVAILABLE TO SPEND")
                        .sectionHeaderStyle()
                    
                    Text("$1,365.42")
                        .font(MilliFont.heroNumber)
                        .foregroundColor(.white)
                    
                    Text("+$312.64 today")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MilliColors.green)
                }
                
                // MARK: - Sparkline
                MilliSparkline(data: SampleData.sparklineData, height: 60)
                    .padding(.horizontal, 8)
                
                // MARK: - Stat Tiles
                HStack(spacing: 12) {
                    StatTile(label: "Tax Vault", value: "$1,648", color: MilliColors.cyan)
                    StatTile(label: "Quarterly Taxes", value: "$1,247", color: MilliColors.amber)
                }
                
                // MARK: - Time Filter Row
                HStack(spacing: 8) {
                    ForEach(timeFilters, id: \.self) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimeFilter = filter
                            }
                        } label: {
                            Text(filter)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTimeFilter == filter ? .white : MilliColors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeFilter == filter ? MilliColors.cyan.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedTimeFilter == filter ? MilliColors.cyan.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                
                // MARK: - Net Worth Growth
                VStack(alignment: .leading, spacing: 12) {
                    Text("NET WORTH GROWTH")
                        .sectionHeaderStyle()
                        .padding(.leading, 4)
                    
                    MilliAreaChart(data: SampleData.chartData, height: 200)
                        .milliCard()
                }
                
                // MARK: - Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("BREAKDOWN")
                        .sectionHeaderStyle()
                        .padding(.leading, 4)
                    
                    MilliCard {
                        VStack(spacing: 0) {
                            ForEach(Array(SampleData.breakdownItems.enumerated()), id: \.element.id) { index, item in
                                BreakdownRow(item: item)
                                
                                if index < SampleData.breakdownItems.count - 1 {
                                    Divider()
                                        .background(Color(white: 0.15))
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.secondaryText)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }
}

// MARK: - Breakdown Row

struct BreakdownRow: View {
    let item: BreakdownItem
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 2)
                .fill(item.color)
                .frame(width: 4, height: 32)
            
            Text(item.label)
                .font(MilliFont.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("$\(item.amount, specifier: "%.0f")")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
