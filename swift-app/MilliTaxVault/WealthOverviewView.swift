import SwiftUI
import Charts

struct WealthOverviewView: View {
    @Environment(\.dismiss) private var dismiss

    private let netWorth: Double = 48_620.00
    private let monthChange: Double = 2_340.00

    private let allocations: [(label: String, value: Double, color: Color)] = [
        ("Investments", 22802.0, MilliPalette.accent),
        ("Retirement", 14200.0, Color(red: 0.23, green: 0.51, blue: 0.96)),
        ("Savings Goals", 8400.0, Color(red: 0.66, green: 0.33, blue: 0.97)),
        ("Cash", 3218.0, MilliPalette.cardBorder),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                heroCard
                donutCard
                projectionCards
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Wealth Overview")
    }

    // MARK: - Hero

    private var heroCard: some View {
        DKCard {
            VStack(spacing: 8) {
                Text("Total Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(MilliPalette.textSecondary)
                Text(milliCurrency(netWorth))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(MilliPalette.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text("+\(milliCurrency(monthChange)) this month")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(MilliPalette.positive)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Donut

    private var donutCard: some View {
        DKCard {
            VStack(spacing: 16) {
                Chart(allocations, id: \.label) { seg in
                    SectorMark(angle: .value("Amount", seg.value), innerRadius: .ratio(0.62), angularInset: 2)
                        .foregroundStyle(seg.color)
                }
                .frame(height: 180)

                VStack(spacing: 8) {
                    ForEach(allocations, id: \.label) { seg in
                        HStack(spacing: 10) {
                            Circle().fill(seg.color).frame(width: 10, height: 10)
                            Text(seg.label)
                                .font(.caption)
                                .foregroundStyle(MilliPalette.textPrimary)
                            Spacer()
                            Text(milliCurrency(seg.value))
                                .font(.caption)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Projections

    private var projectionCards: some View {
        VStack(spacing: 10) {
            projectionRow(icon: "chart.line.uptrend.xyaxis", title: "Retirement Projection", subtitle: "Projected at age 65", value: "$1.42M", color: MilliPalette.positive)
            projectionRow(icon: "target", title: "Savings Goals", subtitle: "3 goals on track", value: "$8,400", color: Color(red: 0.66, green: 0.33, blue: 0.97))
            projectionRow(icon: "arrow.up.forward.circle.fill", title: "Monthly Progress", subtitle: "Invested across all accounts", value: "$1,850", color: MilliPalette.accent)

            DKCard {
                VStack(spacing: 6) {
                    Text("Future Net Worth")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text("$1,680,000")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(MilliPalette.accent)
                        .shadow(color: MilliPalette.accent.opacity(0.3), radius: 8)
                    Text("Projected at age 65")
                        .font(.caption2)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func projectionRow(icon: String, title: String, subtitle: String, value: String, color: Color) -> some View {
        DKCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
                        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(MilliPalette.textPrimary)
                    }
                    Text(subtitle).font(.caption2).foregroundStyle(MilliPalette.textSecondary)
                }
                Spacer()
                Text(value).font(.headline).foregroundStyle(color)
            }
        }
    }
}
