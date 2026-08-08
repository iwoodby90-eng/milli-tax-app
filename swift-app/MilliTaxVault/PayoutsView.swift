import SwiftUI

struct PayoutsView: View {
    @State private var selectedSegment = 0
    private let segments = ["All", "Deposits", "Receipts"]

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                MilliPageHeader(title: "Payouts")

                // Segment control
                segmentControl

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Autopilot badge
                        autopilotBadge

                        // Main payout card
                        mainPayoutCard

                        // Breakdown
                        payoutBreakdown

                        // Allocation
                        allocationSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Segment Control

    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(0..<segments.count, id: \.self) { i in
                Button(action: { withAnimation { selectedSegment = i } }) {
                    VStack(spacing: 6) {
                        Text(segments[i])
                            .font(.system(size: 14, weight: selectedSegment == i ? .semibold : .regular))
                            .foregroundColor(selectedSegment == i ? .white : .milliTextSecondary)
                        Rectangle()
                            .fill(selectedSegment == i ? Color.milliCyan : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    // MARK: - Autopilot Badge

    private var autopilotBadge: some View {
        HStack {
            Text("AUTOPILOT RECEIPT")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.milliCyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.milliCyan.opacity(0.12))
                .cornerRadius(8)
            Spacer()
        }
    }

    // MARK: - Main Payout Card

    private var mainPayoutCard: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Spark icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1E88E5"), Color(hex: "1565C0")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "sparkle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spark Driver\u{2122} Payout")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("May 10, 2024 \u{2022} 9:41 AM")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.milliTextSecondary)
                    }
                }

                Text("$312.64")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                // Status pill
                Text("Automatically processed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.milliGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.milliGreen.opacity(0.12))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Payout Breakdown

    private var payoutBreakdown: some View {
        MilliCard {
            VStack(spacing: 10) {
                Text("PAYOUT BREAKDOWN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                breakdownRow(label: "Gross Payout", value: "$376.65")
                breakdownRow(label: "Platform", value: "-$24.21")
                breakdownRow(label: "Other Adjustments", value: "-$38.80")

                Divider()
                    .background(Color.milliCardBorder)

                HStack {
                    Text("Net Payout")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("$312.64")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.milliCyan)
                }
            }
        }
    }

    private func breakdownRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.milliTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }

    // MARK: - Allocation

    private var allocationSection: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("ALLOCATION")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)

                allocationRow(color: .milliGreen, label: "Tax Vault (23%)", amount: "$72.91")
                allocationRow(color: Color(hex: "FFB800"), label: "Mileage Deduction", amount: "$38.47")
                allocationRow(color: .milliCyan, label: "Available to Spend", amount: "$201.26")
            }
        }
    }

    private func allocationRow(color: Color, label: String, amount: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
            Spacer()
            Text(amount)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
