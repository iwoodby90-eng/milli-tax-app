import SwiftUI
import Charts

// MARK: - Retirement View

struct RetirementView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                statPills
                projectedGrowthSection
                yearByYearSection
                adjustPlanButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.milliBackground)
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        VStack(spacing: 8) {
            Text("You're on track to retire in")
                .font(.callout)
                .foregroundColor(.milliMuted)
            
            Text("2047")
                .font(.system(size: 64, weight: .black))
                .foregroundColor(.white)
            
            Text("at age 62")
                .font(.title3)
                .foregroundColor(.milliMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .milliCard()
    }
    
    // MARK: - Stat Pills
    
    private var statPills: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Contribution")
                    .font(.caption)
                    .foregroundColor(.milliMuted)
                Text("15% of income")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .milliCard()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated Value")
                    .font(.caption)
                    .foregroundColor(.milliMuted)
                Text("$1,623,587")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("in today's dollars")
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .milliCard()
        }
    }
    
    // MARK: - Projected Growth Section
    
    private var projectedGrowthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projected Growth")
                .font(.headline)
                .foregroundColor(.white)
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.milliAccent)
                        .frame(width: 12, height: 12)
                    Text("Portfolio Value")
                        .font(.caption)
                        .foregroundColor(.milliMuted)
                }
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.milliMuted)
                        .frame(width: 12, height: 12)
                    Text("Total Contributions")
                        .font(.caption)
                        .foregroundColor(.milliMuted)
                }
            }
            
            // Stacked Bar Chart
            Chart {
                ForEach(RetirementChartData.projections) { item in
                    BarMark(
                        x: .value("Year", item.year),
                        y: .value("Contributions", item.contributions)
                    )
                    .foregroundStyle(Color.milliMuted.opacity(0.6))
                    
                    BarMark(
                        x: .value("Year", item.year),
                        y: .value("Growth", item.growth)
                    )
                    .foregroundStyle(Color.milliAccent)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.milliMuted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.milliMuted.opacity(0.2))
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text("$\(intVal / 1000)K")
                                .font(.caption2)
                                .foregroundStyle(Color.milliMuted)
                        }
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Year by Year Section
    
    private var yearByYearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Year-by-Year Projection")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("View All")
                    .font(.caption)
                    .foregroundColor(.milliAccent)
            }
            
            // Table Header
            HStack {
                Text("Year")
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
                    .frame(width: 50, alignment: .leading)
                Text("Age")
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
                    .frame(width: 40, alignment: .leading)
                Text("Portfolio Value")
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Annual Contribution")
                    .font(.caption2)
                    .foregroundColor(.milliMuted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            
            // Rows
            ForEach(yearByYearData, id: \.year) { row in
                HStack {
                    Text(row.year)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 50, alignment: .leading)
                    Text(row.age)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 40, alignment: .leading)
                    Text(row.portfolioValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.annualContribution)
                        .font(.caption)
                        .foregroundColor(.milliMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.milliCard.opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Adjust Plan Button
    
    private var adjustPlanButton: some View {
        NavigationLink(destination: RetirementProjectionView()) {
            HStack {
                Text("Adjust Your Plan")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.milliAccent)
                Image(systemName: "arrow.right")
                    .font(.callout)
                    .foregroundColor(.milliAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .milliCard()
        }
    }
    
    // MARK: - Year By Year Data
    
    private var yearByYearData: [YearProjectionRow] {
        [
            YearProjectionRow(year: "2025", age: "40", portfolioValue: "$18,540", annualContribution: "$18,540"),
            YearProjectionRow(year: "2030", age: "45", portfolioValue: "$63,972", annualContribution: "$37,500"),
            YearProjectionRow(year: "2035", age: "50", portfolioValue: "$134,231", annualContribution: "$61,500"),
        ]
    }
}

// MARK: - Supporting Types

struct YearProjectionRow {
    let year: String
    let age: String
    let portfolioValue: String
    let annualContribution: String
}

struct RetirementProjectionData: Identifiable {
    let id = UUID()
    let year: String
    let contributions: Int
    let growth: Int
}

struct RetirementChartData {
    static let projections: [RetirementProjectionData] = [
        RetirementProjectionData(year: "2025", contributions: 18540, growth: 0),
        RetirementProjectionData(year: "2030", contributions: 26472, growth: 37500),
        RetirementProjectionData(year: "2035", contributions: 72731, growth: 61500),
        RetirementProjectionData(year: "2040", contributions: 135089, growth: 106500),
        RetirementProjectionData(year: "2045", contributions: 221734, growth: 179500),
        RetirementProjectionData(year: "2047", contributions: 276432, growth: 219400),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RetirementView()
    }
    .preferredColorScheme(.dark)
}
