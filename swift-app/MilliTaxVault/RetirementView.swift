import SwiftUI
import Charts

struct RetirementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showProjection = false
    @State private var showLifeEvents = false
    
    private let currentAge = 34
    private let retirementAge = 62
    private let retirementYear = 2054
    private let contributionPercent = 15.0
    private let estimatedValue = 1_420_000.0
    
    private let projectionData: [(year: Int, portfolio: Double, contributions: Double)] = [
        (2025, 22800, 22800),
        (2030, 98000, 68400),
        (2035, 220000, 114000),
        (2040, 410000, 159600),
        (2045, 690000, 205200),
        (2050, 1050000, 250800),
    ]
    
    private let yearByYear: [(age: Int, year: Int, contributions: Double, projected: Double)] = [
        (35, 2027, 34200, 36500),
        (40, 2032, 79800, 142000),
        (45, 2037, 125400, 298000),
        (50, 2042, 171000, 520000),
        (55, 2047, 216600, 810000),
        (60, 2052, 262200, 1180000),
        (62, 2054, 284820, 1420000),
    ]
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Retirement", showBack: true, onBack: { dismiss() })
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Hero Header
                        MilliCard {
                            VStack(spacing: 8) {
                                Text("You're on track to retire in")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.milliTextSecondary)
                                
                                Text("\(retirementYear)")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.milliCyan.opacity(0.3), radius: 8)
                                
                                Text("at age \(retirementAge)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.milliCyan)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        
                        // Stat Cards
                        HStack(spacing: 12) {
                            MilliCard {
                                VStack(spacing: 6) {
                                    Text("CONTRIBUTION %")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(0.3)
                                        .foregroundColor(.milliTextSecondary)
                                    Text("\(Int(contributionPercent))%")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.milliCyan)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            MilliCard {
                                VStack(spacing: 6) {
                                    Text("EST. VALUE (TODAY $)")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(0.3)
                                        .foregroundColor(.milliTextSecondary)
                                    Text("$1.42M")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.milliSuccess)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Projected Growth Chart
                        MilliCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PROJECTED GROWTH")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                
                                Chart(projectionData, id: \.year) { item in
                                    BarMark(
                                        x: .value("Year", String(item.year)),
                                        y: .value("Portfolio", item.portfolio)
                                    )
                                    .foregroundStyle(Color.milliCyan.gradient)
                                    .cornerRadius(4)
                                    
                                    BarMark(
                                        x: .value("Year", String(item.year)),
                                        y: .value("Contributions", item.contributions)
                                    )
                                    .foregroundStyle(Color.milliCyan.opacity(0.3))
                                    .cornerRadius(4)
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisValueLabel {
                                            if let v = value.as(Double.self) {
                                                Text("$\(Int(v / 1000))K")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.milliTextTertiary)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let v = value.as(String.self) {
                                                Text(v)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.milliTextSecondary)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                
                                // Legend
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.milliCyan).frame(width: 8, height: 8)
                                        Text("Portfolio Value")
                                            .font(.system(size: 11))
                                            .foregroundColor(.milliTextSecondary)
                                    }
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.milliCyan.opacity(0.3)).frame(width: 8, height: 8)
                                        Text("Contributions")
                                            .font(.system(size: 11))
                                            .foregroundColor(.milliTextSecondary)
                                    }
                                }
                            }
                        }
                        
                        // Year-by-Year Projection
                        MilliCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("YEAR-BY-YEAR PROJECTION")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                
                                ForEach(yearByYear, id: \.age) { row in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Age \(row.age) (\(row.year))")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white)
                                            Text("Contributions: $\(formatCompact(row.contributions))")
                                                .font(.system(size: 11))
                                                .foregroundColor(.milliTextSecondary)
                                        }
                                        Spacer()
                                        Text("$\(formatCompact(row.projected))")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.milliCyan)
                                    }
                                    if row.age != yearByYear.last?.age {
                                        Divider().background(Color.milliCardBorder)
                                    }
                                }
                            }
                        }
                        
                        // Navigation Buttons
                        NavigationLink(destination: RetirementProjectionView(), isActive: $showProjection) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14))
                                Text("Adjust Your Plan")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.milliCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.milliCyan.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.milliCyan.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                        
                        NavigationLink(destination: LifeEventsView(), isActive: $showLifeEvents) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 14))
                                Text("Life Events")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.milliTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.milliCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.milliCardBorder, lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.0fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}
