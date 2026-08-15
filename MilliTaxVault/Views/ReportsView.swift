import SwiftUI
import Charts

struct ReportsView: View {
    var onBack: () -> Void = {}
    @State private var selectedTab = 1
    let tabs = ["Overview", "Deductions", "Trips"]

    struct MonthData: Identifiable {
        let id = UUID()
        let month: String
        let value: Double
    }

    let chartData: [MonthData] = [
        MonthData(month: "Jan", value: 420),
        MonthData(month: "Feb", value: 680),
        MonthData(month: "Mar", value: 540),
        MonthData(month: "Apr", value: 890),
        MonthData(month: "May", value: 720),
        MonthData(month: "Jun", value: 600),
    ]

    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let amount: String
        let pct: String
        let color: Color
    }

    let categories: [Category] = [
        Category(name: "Fuel", amount: "$1,286.45", pct: "45.2%", color: Color(hex: "00E5FF")),
        Category(name: "Car Maintenance", amount: "$642.17", pct: "22.6%", color: Color(hex: "2196F3")),
        Category(name: "Insurance", amount: "$389.45", pct: "13.7%", color: Color(hex: "9C27B0")),
        Category(name: "Tolls & Parking", amount: "$246.30", pct: "8.6%", color: Color(hex: "FF9800")),
        Category(name: "Other", amount: "$278.80", pct: "9.9%", color: Color(hex: "4CAF50")),
    ]

    var body: some View {
        ZStack {
            Color(hex: "0A0A0C").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("M I L L I")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(6)
                            .opacity(0.5)
                        Spacer()
                    }
                    Text("Reports")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Tabs
                    HStack(spacing: 0) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Button(action: { selectedTab = i }) {
                                Text(tabs[i])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedTab == i ? .black : Color.white.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedTab == i ? Color(hex: "00E5FF") : Color.clear,
                                        in: Capsule()
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(4)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 20))

                    // Summary
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text("TOTAL DEDUCTIONS")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.5))
                            Text("$2,843.17")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        VStack(spacing: 2) {
                            Text("VS LAST YEAR")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.5))
                            Text("+8.7%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "00C853"))
                        }
                        .frame(maxWidth: .infinity)
                        VStack(spacing: 2) {
                            Text("DEDUCTION RATE")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.5))
                            Text("28.4%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Chart
                    Chart(chartData) { d in
                        BarMark(
                            x: .value("Month", d.month),
                            y: .value("Amount", d.value)
                        )
                        .foregroundStyle(Color(hex: "00E5FF").gradient)
                    }
                    .frame(height: 160)
                    .padding(16)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Categories
                    VStack(spacing: 0) {
                        Text("TOP DEDUCTION CATEGORIES")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                        ForEach(categories) { c in
                            HStack {
                                Circle()
                                    .fill(c.color)
                                    .frame(width: 10, height: 10)
                                Text(c.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(c.amount)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(c.pct)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Export
                    HStack(spacing: 12) {
                        ForEach(["Export PDF", "Export CSV", "Share Report"], id: \.self) { label in
                            Button(action: {}) {
                                Text(label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
        }
    }
}

#Preview {
    ReportsView()
}
