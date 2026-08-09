import SwiftUI

struct PayoutsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PayoutsViewModel()
    @State private var selectedSegment = 0
    private let segments = ["All", "Deposits", "Receipts"]

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                MilliPageHeader(title: "Payouts")

                segmentControl

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        autopilotBadge
                        mainPayoutCard
                        payoutBreakdown
                        allocationSection

                        // Stripe subscription status
                        if viewModel.subscriptionTier != "free" {
                            subscriptionBadge
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .task { await viewModel.loadPayouts() }
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
                        Text("\(viewModel.latestPayoutSource) Payout")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(viewModel.latestPayoutDate)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.milliTextSecondary)
                    }
                }

                Text(viewModel.latestPayoutNet)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

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

                breakdownRow(label: "Gross Payout", value: viewModel.latestPayoutGross)
                breakdownRow(label: "Platform", value: viewModel.latestPayoutPlatformFee)
                breakdownRow(label: "Other Adjustments", value: viewModel.latestPayoutAdjustments)

                Divider()
                    .background(Color.milliCardBorder)

                HStack {
                    Text("Net Payout")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(viewModel.latestPayoutNet)
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

                allocationRow(color: .milliGreen, label: "Tax Vault (23%)", amount: viewModel.taxAllocation)
                allocationRow(color: Color(hex: "FFB800"), label: "Mileage Deduction", amount: viewModel.mileageDeduction)
                allocationRow(color: .milliCyan, label: "Available to Spend", amount: viewModel.availableToSpend)
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

    // MARK: - Subscription Badge (Stripe)

    private var subscriptionBadge: some View {
        MilliCard {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "FFB800"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("MILLI \(viewModel.subscriptionTier.uppercased())")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "FFB800"))
                    Text("Autopilot receipts & smart allocation active")
                        .font(.system(size: 12))
                        .foregroundColor(.milliTextSecondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.milliGreen)
            }
        }
    }
}
