import SwiftUI
import Charts

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ReportTab = .deductions
    @State private var showExportAlert = false
    
    enum ReportTab: String, CaseIterable {
        case overview = "Overview"
        case deductions = "Deductions"
        case trips = "Trips"
    }
    
    private let monthlyDeductions: [(month: String, amount: Double)] = [
        ("Jan", 420), ("Feb", 510), ("Mar", 680), ("Apr", 590), ("May", 720), ("Jun", 840)
    ]
    
    private let topCategories: [(name: String, amount: Double, percent: Double)] = [
        ("Fuel", 1842.50, 34.2),
        ("Car Maintenance", 1120.00, 20.8),
        ("Insurance", 852.00, 15.8),
        ("Tolls & Parking", 486.30, 9.0),
        ("Other", 1089.20, 20.2),
    ]
    
    private let mockTrips: [(date: String, miles: Double, earnings: Double)] = [
        ("Aug 9, 2026", 42.3, 68.50),
        ("Aug 8, 2026", 38.1, 52.00),
        ("Aug 7, 2026", 55.8, 84.20),
        ("Aug 6, 2026", 29.4, 41.00),
        ("Aug 5, 2026", 61.2, 92.75),
        ("Aug 4, 2026", 33.7, 48.30),
        ("Aug 3, 2026", 47.9, 71.00),
    ]
    
    private var totalDeductionsYTD: Double { monthlyDeductions.reduce(0) { $0 + $1.amount } }
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Reports", showBack: true, onBack: { dismiss() })
                
                // Tab Picker
                HStack(spacing: 0) {
                    ForEach(ReportTab.allCases, id: \.self) { tab in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                            VStack(spacing: 6) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedTab == tab ? .milliCyan : .milliTextSecondary)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.milliCyan : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                
                ScrollView(.vertical, showsIndicators: false) {
                    switch selectedTab {
                    case .overview: overviewContent
                    case .deductions: deductionsContent
                    case .trips: tripsContent
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Coming Soon", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("PDF and CSV export will be available in a future update.")
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewContent: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(label: "Net Earnings", value: "$12,480", icon: "dollarsign.circle.fill")
                statCard(label: "Tax Saved", value: "$3,390", icon: "leaf.fill")
                statCard(label: "Miles YTD", value: "8,420", icon: "car.fill")
            }
            
            MilliCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YEAR-TO-DATE SUMMARY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gross Income")
                                .font(.system(size: 13))
                                .foregroundColor(.milliTextSecondary)
                            Text("$18,640")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Effective Tax Rate")
                                .font(.system(size: 13))
                                .foregroundColor(.milliTextSecondary)
                            Text("18.2%")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.milliCyan)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }
    
    private func statCard(label: String, value: String, icon: String) -> some View {
        MilliCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.milliCyan)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.milliTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Deductions Tab
    
    private var deductionsContent: some View {
        VStack(spacing: 16) {
            // Total YTD
            MilliCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("TOTAL DEDUCTIONS YTD")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.milliTextSecondary)
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("+8.3% vs last year")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.milliSuccess)
                    }
                    
                    Text("$\(String(format: "%.2f", totalDeductionsYTD))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Deduction Rate: 28.9%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.milliCyan)
                }
            }
            
            // Bar Chart
            MilliCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MONTHLY DEDUCTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    
                    Chart(monthlyDeductions, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(Color.milliCyan.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("$\(Int(v))")
                                        .font(.system(size: 10))
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
                                        .font(.system(size: 10))
                                        .foregroundColor(.milliTextSecondary)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
            
            // Top Categories
            MilliCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("TOP DEDUCTION CATEGORIES")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    
                    ForEach(Array(topCategories.enumerated()), id: \.offset) { _, cat in
                        HStack {
                            Text(cat.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("$\(String(format: "%.2f", cat.amount))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(String(format: "%.1f", cat.percent))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.milliTextSecondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                        if cat.name != topCategories.last?.name {
                            Divider().background(Color.milliCardBorder)
                        }
                    }
                }
            }
            
            // Export Buttons
            HStack(spacing: 12) {
                Button(action: { showExportAlert = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 14))
                        Text("Export PDF")
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
                
                Button(action: { showExportAlert = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 14))
                        Text("Export CSV")
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }
    
    // MARK: - Trips Tab
    
    private var tripsContent: some View {
        VStack(spacing: 12) {
            ForEach(Array(mockTrips.enumerated()), id: \.offset) { _, trip in
                MilliCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.date)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Text("\(String(format: "%.1f", trip.miles)) miles")
                                .font(.system(size: 12))
                                .foregroundColor(.milliTextSecondary)
                        }
                        
                        Spacer()
                        
                        Text("+$\(String(format: "%.2f", trip.earnings))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.milliSuccess)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }
}
