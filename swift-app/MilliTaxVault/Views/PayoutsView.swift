import SwiftUI

struct PayoutsView: View {
    @State private var payouts: [Payout] = [
        Payout(source: "Spark Driver\u{2122}", date: "Aug 10, 2026", amount: 312.64, savingsSetAside: 78.16, platform: "walmart", status: "processed"),
        Payout(source: "DoorDash", date: "Aug 8, 2026", amount: 186.40, savingsSetAside: 46.60, platform: "doordash", status: "processed"),
        Payout(source: "Instacart", date: "Aug 6, 2026", amount: 94.20, savingsSetAside: 23.55, platform: "instacart", status: "processed"),
        Payout(source: "Spark Driver\u{2122}", date: "Aug 3, 2026", amount: 287.96, savingsSetAside: 72.00, platform: "walmart", status: "processed"),
    ]
    @State private var selectedPeriod: TimePeriod = .week

    enum TimePeriod: String, CaseIterable { case week = "Week", month = "Month", quarter = "Quarter" }

    var totalEarnings: Double { payouts.reduce(0) { $0 + $1.amount } }
    var totalSetAside: Double { payouts.reduce(0) { $0 + $1.savingsSetAside } }

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    MilliPageHeader(title: "Activity")

                    // Period picker
                    MilliSegmentedPicker(
                        options: TimePeriod.allCases,
                        label: { $0.rawValue },
                        selection: $selectedPeriod
                    )

                    // Earnings hero
                    earningsHero

                    // Payout list
                    payoutList

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    private var earningsHero: some View {
        DKCard {
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("EARNED")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(MilliPalette.textSecondary)
                        Text(milliCurrency(totalEarnings))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    VStack(spacing: 4) {
                        Text("SET ASIDE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(MilliPalette.textSecondary)
                        Text(milliCurrency(totalSetAside))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(MilliPalette.accent)
                    }
                }
                .frame(maxWidth: .infinity)

                // Mini sparkline
                WaveShape()
                    .stroke(MilliPalette.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(height: 30)
                    .opacity(0.6)
            }
            .padding(.vertical, 8)
        }
    }

    private var payoutList: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Payouts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                ForEach(payouts) { payout in
                    payoutRow(payout)
                    if payout.id != payouts.last?.id {
                        Divider().background(MilliPalette.cardBorder)
                    }
                }
            }
        }
    }

    private func payoutRow(_ payout: Payout) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliPalette.positive.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(MilliPalette.positive)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(payout.source)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(payout.date)
                    .font(.system(size: 11))
                    .foregroundColor(MilliPalette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(milliCurrency(payout.amount, fraction: 2))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("-\(milliCurrency(payout.savingsSetAside, fraction: 2)) tax")
                    .font(.system(size: 10))
                    .foregroundColor(MilliPalette.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
