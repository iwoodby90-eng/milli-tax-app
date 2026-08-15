import SwiftUI

struct ExpensesView: View {
    @State private var selectedTab = 0
    let tabs = ["Expenses", "Receipts"]

    struct Expense: Identifiable {
        let id = UUID()
        let icon: String
        let name: String
        let date: String
        let amount: String
        let color: Color
    }

    let expenses: [Expense] = [
        Expense(icon: "fuelpump.fill", name: "Fuel", date: "May 19, 2024", amount: "$68.42", color: Color(hex: "FF9800")),
        Expense(icon: "wrench.and.screwdriver.fill", name: "Car Maintenance", date: "May 18, 2024", amount: "$89.75", color: Color(hex: "2196F3")),
        Expense(icon: "parkingsign.circle.fill", name: "Tolls & Parking", date: "May 16, 2024", amount: "$24.60", color: Color(hex: "9C27B0")),
        Expense(icon: "drop.fill", name: "Car Wash", date: "May 14, 2024", amount: "$14.00", color: Color(hex: "00BCD4")),
        Expense(icon: "shippingbox.fill", name: "Supplies", date: "May 12, 2024", amount: "$12.35", color: Color(hex: "4CAF50")),
        Expense(icon: "shield.fill", name: "Insurance", date: "May 10, 2024", amount: "$39.45", color: Color(hex: "F44336")),
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
                        Image(systemName: "bell")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Expenses")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }

                    // Segmented tabs
                    HStack(spacing: 0) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Button(action: { selectedTab = i }) {
                                Text(tabs[i])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedTab == i ? .black : Color.white.opacity(0.5))
                                    .padding(.horizontal, 20)
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
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL DEDUCTIONS")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                                .tracking(1)
                            Text("$248.57")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("THIS MONTH")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                                .tracking(1)
                            Text("+12.4%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "00C853"))
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Expense list
                    VStack(spacing: 0) {
                        ForEach(expenses) { e in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(e.color.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: e.icon)
                                        .font(.system(size: 17))
                                        .foregroundColor(e.color)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(e.date)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                                Spacer()
                                Text(e.amount)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 64)
                            Divider().background(Color.white.opacity(0.08))
                        }
                        Button(action: {}) {
                            Text("View All Expenses")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "00E5FF"))
                        }
                        .padding(16)
                    }
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 56, height: 56)
                            .background(Color(hex: "00E5FF"), in: Circle())
                            .shadow(color: Color(hex: "00E5FF").opacity(0.4), radius: 12)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 116)
                }
            }
        }
    }
}

#Preview {
    ExpensesView()
}
