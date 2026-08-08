import SwiftUI
import Charts

// MARK: - Wealth Overview View

struct WealthOverviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                donutChartSection
                statCardsGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.milliBackground)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total Net Worth")
                .font(.caption)
                .foregroundColor(.milliMuted)
            
            Text("$224,560")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
            
            Text("+$7,250 (3.33%) this month")
                .font(.callout)
                .foregroundColor(.milliGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .milliCard()
    }
    
    // MARK: - Donut Chart Section
    
    private var donutChartSection: some View {
        VStack(spacing: 16) {
            // Donut Chart using SectorMark
            Chart(WealthSegment.segments) { segment in
                SectorMark(
                    angle: .value("Amount", segment.value),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(segment.color)
                .cornerRadius(4)
            }
            .frame(height: 180)
            
            // Legend - 2x2 Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(WealthSegment.segments) { segment in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(segment.color)
                            .frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(segment.label)
                                .font(.caption2)
                                .foregroundColor(.milliMuted)
                            Text(segment.formattedValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .milliCard()
    }
    
    // MARK: - Stat Cards Grid
    
    private var statCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCardView(
                title: "Retirement Projection",
                value: "$1,623,587",
                subtitle: "Projected at age 62",
                icon: "chart.line.uptrend.xyaxis",
                showTrendLine: true
            )
            
            StatCardView(
                title: "Savings Goals",
                value: "$18,765",
                subtitle: "3 goals on track",
                icon: "target",
                showTrendLine: false
            )
            
            StatCardView(
                title: "Monthly Progress",
                value: "$2,850",
                subtitle: "Invested across all accounts",
                icon: "chart.bar.fill",
                showTrendLine: false
            )
            
            StatCardView(
                title: "Future Net Worth",
                value: "$2,467,892",
                subtitle: "Projected at age 65",
                icon: "chart.line.uptrend.xyaxis",
                showTrendLine: true
            )
        }
    }
}

// MARK: - Stat Card View

struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let showTrendLine: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
                Spacer()
                if showTrendLine {
                    MiniTrendLineView()
                        .frame(width: 28, height: 14)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.milliAccent)
                }
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.milliMuted)
                .lineLimit(2)
        }
        .padding(14)
        .milliCard()
    }
}

// MARK: - Mini Trend Line View

struct MiniTrendLineView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let points: [CGFloat] = [0.6, 0.4, 0.5, 0.3, 0.35, 0.15, 0.1]
                let stepX = geo.size.width / CGFloat(points.count - 1)
                let height = geo.size.height
                
                path.move(to: CGPoint(x: 0, y: height * points[0]))
                for i in 1..<points.count {
                    path.addLine(to: CGPoint(x: stepX * CGFloat(i), y: height * points[i]))
                }
            }
            .stroke(Color.milliGreen, lineWidth: 1.5)
        }
    }
}

// MARK: - Wealth Segment Data

struct WealthSegment: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    let formattedValue: String
    
    static let segments: [WealthSegment] = [
        WealthSegment(label: "Investments", value: 42685, color: .milliAccent, formattedValue: "$42,685"),
        WealthSegment(label: "Retirement", value: 148320, color: Color(hex: "2E5FA1"), formattedValue: "$148,320"),
        WealthSegment(label: "Savings Goals", value: 18765, color: Color(hex: "8B5CF6"), formattedValue: "$18,765"),
        WealthSegment(label: "Cash", value: 14790, color: Color(hex: "6B7280"), formattedValue: "$14,790"),
    ]
}

// MARK: - Preview

#Preview {
    WealthOverviewView()
        .preferredColorScheme(.dark)
}
