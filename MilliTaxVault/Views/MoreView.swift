import SwiftUI

struct MoreView: View {
    @State private var showTaxVault = false
    @State private var showMilliCents = false
    @State private var showExpenses = false
    @State private var showReports = false

    struct MenuItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let color: Color
    }

    let items: [MenuItem] = [
        MenuItem(icon: "lock.shield.fill", title: "Milli Tax Vault™", color: Color(hex: "00E5FF")),
        MenuItem(icon: "bolt.fill", title: "Milli Cents™", color: Color(hex: "FFD700")),
        MenuItem(icon: "doc.text.fill", title: "Expenses", color: Color(hex: "4CAF50")),
        MenuItem(icon: "chart.bar.fill", title: "Reports", color: Color(hex: "2196F3")),
        MenuItem(icon: "gearshape.fill", title: "Settings", color: Color.gray),
    ]

    var body: some View {
        ZStack {
            Color(hex: "0A0A0C").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Text("M I L L I")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(6)
                        .opacity(0.5)
                        .padding(.bottom, 8)
                    Text("More")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 20)

                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            Button(action: {
                                if item.title == "Milli Tax Vault™" { showTaxVault = true }
                                else if item.title == "Milli Cents™" { showMilliCents = true }
                                else if item.title == "Expenses" { showExpenses = true }
                                else if item.title == "Reports" { showReports = true }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(item.color.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: item.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(item.color)
                                    }
                                    Text(item.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.white.opacity(0.3))
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 64)
                            }
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
        }
        .sheet(isPresented: $showTaxVault) { MilliTaxVaultScreen() }
        .sheet(isPresented: $showMilliCents) { MilliCentsView() }
        .sheet(isPresented: $showExpenses) { ExpensesView() }
        .sheet(isPresented: $showReports) { ReportsView() }
    }
}

#Preview {
    MoreView()
}
