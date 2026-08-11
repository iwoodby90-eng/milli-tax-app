import SwiftUI
import Combine

struct TaxVaultView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TaxVaultViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                heroCard
                quarterlyGoalCard
                addToVaultButton
                transactionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Tax Vault")
        .task { await viewModel.loadVault() }
    }

    // MARK: - Hero

    private var heroCard: some View {
        DKCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reserve Balance")
                        .font(.subheadline)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text(viewModel.balanceDisplay)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(MilliPalette.textPrimary)
                    Text(viewModel.goalPercentDisplay)
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                Spacer()
                MilliProgressRing(progress: viewModel.goalPercent, lineWidth: 10)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text("\(Int(viewModel.goalPercent * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MilliPalette.accent)
                    )
            }
        }
    }

    // MARK: - Quarterly Goal

    private var quarterlyGoalCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("This Quarter's Goal")
                    .font(.headline)
                    .foregroundStyle(MilliPalette.textPrimary)
                HStack {
                    Text("Target")
                        .font(.subheadline)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Spacer()
                    Text(viewModel.annualTarget)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MilliPalette.accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MilliPalette.cardBorder)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MilliPalette.accent)
                            .frame(width: geo.size.width * viewModel.goalPercent, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    // MARK: - Add to Vault

    private var addToVaultButton: some View {
        Button(action: {}) {
            Text("Add to Vault")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: MilliPalette.radius).fill(MilliPalette.accent))
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .foregroundStyle(MilliPalette.textPrimary)

            ForEach(viewModel.displayTransactions) { transaction in
                DKCard {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(MilliPalette.accent.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: iconForType(transaction.type))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MilliPalette.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(transaction.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text(transaction.date)
                                .font(.caption2)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                        Spacer()
                        Text(transaction.formattedAmount)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MilliPalette.positive)
                    }
                }
            }
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "interest": return "percent"
        case "manual": return "arrow.right.circle.fill"
        default: return "arrow.down.circle.fill"
        }
    }
}
