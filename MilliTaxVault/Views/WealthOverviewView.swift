import SwiftUI
import Charts

struct WealthOverviewView: View {
    struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let color: Color
    }

    let slices: [Slice] = [
        Slice(name: "Investments", value: 19, color: Color(hex: "00E5FF")),
        Slice(name: "Retirement", value: 66, color: Color(hex: "2196F3")),
        Slice(name: "Savings", value: 8, color: Color(hex: "9C27B0")),
        Slice(name: "Cash", value: 7, color: Color.gray),
    ]

    let breakdown: [(String, String)] = [
        ("Investments", "$42,685"),
        ("Retirement", "$148,320"),
        ("Savings Goals", "$18,765"),
        ("Cash", "$14,790"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Net worth
                VStack(spacing: 8) {
                    Text("Total Net Worth")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.5))
                    Text("$224,560")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("+$7,250 (3.33%) this month")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "00C853"))

                    // Donut chart
                    Chart(slices) { s in
                        SectorMark(
                            angle: .value("Value", s.value),
                            innerRadius: .ratio(0.6)
                        )
                        .foregroundStyle(s.color)
                    }
                    .frame(height: 160)

                    // Legend
                    HStack(spacing: 16) {
                        ForEach(slices) { s in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(s.color)
                                    .frame(width: 8, height: 8)
                                Text(s.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                // Breakdown
                VStack(spacing: 0) {
                    ForEach(Array(breakdown.enumerated()), id: \.offset) { _, row in
                        HStack {
                            Text(row.0)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            Text(row.1)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
                .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))

                // Projections
                VStack(alignment: .leading, spacing: 8) {
                    Text("RETIREMENT PROJECTION")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(1.5)
                    Text("$1,623,587")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("FUTURE NET WORTH AT 65")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(1.5)
                        .padding(.top, 8)
                    Text("$2,467,892")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "00E5FF"))
                    Text("MONTHLY INVESTED")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(1.5)
                        .padding(.top, 8)
                    Text("$2,850 across all accounts")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 100)
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    WealthOverviewView()
        .background(Color(hex: "0A0A0C"))
}
