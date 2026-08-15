import SwiftUI

struct MilliTaxVaultScreen: View {
    var body: some View {
        ZStack {
            Color(hex: "0A0A0C").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // MILLI wordmark
                    Text("M I L L I")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(6)
                        .opacity(0.5)

                    Text("MILLI TAX VAULT™")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    // Reserve Balance card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RESERVE BALANCE")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .tracking(1.5)
                                Text("$5,284.17")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)
                                Text("23.4% of annual target")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                                    .frame(width: 64, height: 64)
                                Circle()
                                    .trim(from: 0, to: 0.234)
                                    .stroke(Color(hex: "00E5FF"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 64, height: 64)
                                Text("23%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "00E5FF"))
                            }
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Annual Target")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.5))
                                Text("$22,500")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Target Date")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.5))
                                Text("Dec 31, 2024")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        Button(action: {}) {
                            Text("Add to Vault")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "00E5FF"), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                    // Transactions
                    VStack(spacing: 0) {
                        HStack {
                            Text("TRANSACTIONS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.5))
                                .tracking(1.5)
                            Spacer()
                            Text("View All")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "00E5FF"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                        let txns: [(String, String, String)] = [
                            ("May 10", "Payout Allocation", "+$72.91"),
                            ("May 9", "Payout Allocation", "+$89.21"),
                            ("May 8", "Manual Transfer", "+$250.00"),
                            ("May 7", "Interest Earned", "+$1.27"),
                            ("May 6", "Payout Allocation", "+$86.11")
                        ]
                        ForEach(Array(txns.enumerated()), id: \.offset) { _, t in
                            HStack {
                                Text(t.0)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .frame(width: 48, alignment: .leading)
                                Text(t.1)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(t.2)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "00E5FF"))
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 44)
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
    }
}

#Preview {
    MilliTaxVaultScreen()
}
