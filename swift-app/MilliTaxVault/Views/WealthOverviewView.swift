import SwiftUI

struct WealthOverviewView: View {
    @State private var netWorth: Double = 12_480.00
    @State private var monthlyChange: Double = 860.00
    @State private var savingsRate: Double = 0.28
    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable { case week = "1W", month = "1M", quarter = "3M", year = "1Y" }

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    MilliPageHeader(title: "Wealth")

                    // Net worth hero
                    netWorthHero

                    // Period picker
                    MilliSegmentedPicker(
                        options: Period.allCases,
                        label: { $0.rawValue },
                        selection: $selectedPeriod
                    )

                    // Chart placeholder
                    chartCard

                    // Wealth breakdown
                    breakdownSection

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Net Worth Hero

    private var netWorthHero: some View {
        DKCard {
            VStack(spacing: 8) {
                Text("NET WORTH")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(MilliPalette.textSecondary)

                Text(milliCurrency(netWorth))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("+\(milliCurrency(monthlyChange)) this month")
                        .font(.system(size: 13))
                }
                .foregroundColor(MilliPalette.positive)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Chart

    private var chartCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Growth")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                // Simple sparkline chart
                WaveShape()
                    .stroke(
                        LinearGradient(
                            colors: [MilliPalette.accent.opacity(0.3), MilliPalette.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(height: 80)
            }
        }
    }

    // MARK: - Breakdown

    private var breakdownSection: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Breakdown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                wealthRow(label: "Tax Vault", amount: 1_648.00, color: MilliPalette.accent)
                wealthRow(label: "Checking", amount: 4_320.00, color: MilliPalette.positive)
                wealthRow(label: "Savings", amount: 6_512.00, color: MilliPalette.warning)
            }
        }
    }

    private func wealthRow(label: String, amount: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(MilliPalette.textSecondary)
            Spacer()
            Text(milliCurrency(amount))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
