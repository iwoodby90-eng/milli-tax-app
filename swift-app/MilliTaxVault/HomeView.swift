import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                header
                availableToSpendCard
                latestPayoutCard
                taxVaultSummaryCard
                quarterlyTaxCard
                quickActionsRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .task { await viewModel.loadDashboard() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Text("MILLI")
                .font(.system(size: 20, weight: .bold))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.milliChrome1, .white, Color.milliChrome1],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 17))
                    .foregroundColor(MilliPalette.textPrimary)
            }
        }
    }

    // MARK: - Available to Spend Hero

    private var availableToSpendCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Available to Spend")
                    .font(.subheadline)
                    .foregroundStyle(MilliPalette.textSecondary)
                Text(viewModel.availableToSpend)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(MilliPalette.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text("+$24.80 today")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(MilliPalette.positive)
            }
        }
    }

    // MARK: - Latest Payout

    private var latestPayoutCard: some View {
        DKCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MilliPalette.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MilliPalette.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Latest Payout")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text(viewModel.latestPayoutAmount)
                        .font(.headline)
                        .foregroundStyle(MilliPalette.textPrimary)
                    Text("\(viewModel.latestPayoutDate) \u{2022} Spark Driver\u{2122}")
                        .font(.caption2)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(MilliPalette.textSecondary)
            }
        }
    }

    // MARK: - Tax Vault Summary

    private var taxVaultSummaryCard: some View {
        DKCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tax Vault")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text(viewModel.vaultBalance)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(MilliPalette.textPrimary)
                    Text("\(viewModel.vaultGoalPercent)% of quarterly goal")
                        .font(.caption2)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                Spacer()
                MilliProgressRing(progress: Double(viewModel.vaultGoalPercent) / 100.0, lineWidth: 8)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("\(viewModel.vaultGoalPercent)%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MilliPalette.accent)
                    )
            }
        }
    }

    // MARK: - Quarterly Tax

    private var quarterlyTaxCard: some View {
        DKCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quarterly Tax Due")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text(viewModel.quarterlyEstimate)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(MilliPalette.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("38 days")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MilliPalette.accent)
                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickActionButton(icon: "plus.circle.fill", label: "Add Payout")
            quickActionButton(icon: "car.fill", label: "Track Trip")
            quickActionButton(icon: "building.columns.fill", label: "View Vault")
        }
    }

    private func quickActionButton(icon: String, label: String) -> some View {
        DKCard(padding: 12) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(MilliPalette.accent)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(MilliPalette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
