import SwiftUI
import Combine

struct PayoutsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PayoutsViewModel()
    @State private var selectedSegment: PayoutSegment = .all

    enum PayoutSegment: String, CaseIterable {
        case all = "All"
        case deposits = "Deposits"
        case receipts = "Receipts"
    }

    private let mockPayouts: [(source: String, amount: Double, date: String, status: String)] = [
        ("Spark Driver\u{2122}", 312.64, "Aug 10, 2026", "Processed"),
        ("DoorDash", 186.40, "Aug 8, 2026", "Processed"),
        ("Uber Eats", 94.20, "Aug 6, 2026", "Processed"),
        ("Spark Driver\u{2122}", 278.90, "Aug 4, 2026", "Processed"),
        ("Instacart", 142.15, "Aug 2, 2026", "Processed"),
        ("Spark Driver\u{2122}", 345.22, "Jul 30, 2026", "Processed"),
    ]

    private var weekTotal: Double { mockPayouts.prefix(3).reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                MilliSegmentedPicker(
                    options: PayoutSegment.allCases,
                    label: { $0.rawValue },
                    selection: $selectedSegment
                )
                summaryCard
                payoutsList
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Payouts")
        .task { await viewModel.loadPayouts() }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("This Week's Deposits")
                    .font(.caption)
                    .foregroundStyle(MilliPalette.textSecondary)
                Text(milliCurrency(weekTotal))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(MilliPalette.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text("+8.2% vs last week")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(MilliPalette.positive)
            }
        }
    }

    // MARK: - Payouts List

    private var payoutsList: some View {
        VStack(spacing: 10) {
            ForEach(Array(mockPayouts.enumerated()), id: \.offset) { _, payout in
                DKCard {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(MilliPalette.accent.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(MilliPalette.accent)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(payout.source)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text(payout.date)
                                .font(.caption2)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(milliCurrency(payout.amount))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text(payout.status)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(MilliPalette.positive)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(MilliPalette.positive.opacity(0.12)))
                        }
                    }
                }
            }
        }
    }
}
