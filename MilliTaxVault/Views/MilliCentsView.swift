import SwiftUI

struct MilliCentsView: View {
    @State private var offerAmount: Double = 32.64

    var netProfit: Double { offerAmount - 4.87 - 6.21 }
    var isProfitable: Bool { netProfit > 0 }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0C").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("M I L L I")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(6)
                        .opacity(0.5)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Milli Cents™")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Offer Analyzer")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "00E5FF"))
                        }
                        Spacer()
                        Text("How it works $")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "00E5FF"))
                    }

                    // Offer amount card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OFFER AMOUNT")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                                .tracking(1.5)
                            Text("$\(offerAmount, specifier: "%.2f")")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(20)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Breakdown
                    VStack(spacing: 0) {
                        ForEach(Array(breakdownRows.enumerated()), id: \.offset) { _, row in
                            HStack {
                                Image(systemName: row.icon)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "00E5FF"))
                                    .frame(width: 28)
                                Text(row.label)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(row.value)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 44)
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Net profit
                    VStack(spacing: 4) {
                        Text("NET PROFIT")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                            .tracking(1.5)
                        Text("$\(netProfit, specifier: "%.2f")")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("PROFIT PER MILE: $0.56")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Go/Pass
                    VStack(spacing: 4) {
                        Text(isProfitable ? "GO" : "PASS")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(isProfitable ? Color(hex: "00C853") : Color.red)
                        Text(isProfitable ? "This offer is profitable." : "This offer is not profitable.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        isProfitable ? Color(hex: "0D2A1A") : Color(hex: "2A0D0D"),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                    Button(action: {}) {
                        Text("Analyze New Offer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "00E5FF"), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
        }
    }

    // MARK: - Data
    private struct BreakdownRow {
        let label: String
        let value: String
        let icon: String
    }

    private var breakdownRows: [BreakdownRow] {
        [
            BreakdownRow(label: "Estimated Miles", value: "24.8 mi", icon: "car"),
            BreakdownRow(label: "Dead Miles", value: "6.4 mi", icon: "road.lanes"),
            BreakdownRow(label: "Return Miles", value: "7.2 mi", icon: "arrow.uturn.left"),
            BreakdownRow(label: "Total Miles", value: "38.4 mi", icon: "point.topleft.down.to.point.bottomright.curvepath"),
            BreakdownRow(label: "Fuel Cost", value: "$4.87", icon: "fuelpump"),
            BreakdownRow(label: "Tax Impact", value: "$6.21", icon: "percent"),
        ]
    }
}

#Preview {
    MilliCentsView()
}
