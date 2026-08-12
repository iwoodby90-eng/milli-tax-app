import SwiftUI

struct TaxVaultView: View {
    @StateObject private var vm = TaxVaultViewModel()

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    MilliPageHeader(title: "Tax Vault")

                    // Vault balance hero
                    vaultHero

                    // Progress ring card
                    progressCard

                    // Transactions
                    transactionsSection

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        .task { await vm.loadVault() }
    }

    // MARK: - Vault Hero

    private var vaultHero: some View {
        DKCard {
            VStack(spacing: 8) {
                Text("VAULT BALANCE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(MilliPalette.textSecondary)

                Text(vm.balanceDisplay)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(vm.goalPercentDisplay)
                    .font(.system(size: 13))
                    .foregroundColor(MilliPalette.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        DKCard {
            HStack(spacing: 20) {
                MilliProgressRing(progress: vm.goalPercent, lineWidth: 10)
                    .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Quarterly Goal")
                            .font(.system(size: 11))
                            .foregroundColor(MilliPalette.textSecondary)
                        Text(vm.annualTarget)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Remaining")
                            .font(.system(size: 11))
                            .foregroundColor(MilliPalette.textSecondary)
                        Text(milliCurrency(max(0, vm.quarterlyGoal - vm.balance)))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(MilliPalette.warning)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Transfers")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("See All")
                        .font(.system(size: 12))
                        .foregroundColor(MilliPalette.accent)
                }

                ForEach(vm.displayTransactions) { tx in
                    transactionRow(tx)
                    if tx.id != vm.displayTransactions.last?.id {
                        Divider().background(MilliPalette.cardBorder)
                    }
                }
            }
        }
    }

    private func transactionRow(_ tx: VaultTransaction) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(txColor(tx.type).opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: txIcon(tx.type))
                    .font(.system(size: 14))
                    .foregroundColor(txColor(tx.type))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(tx.date)
                    .font(.system(size: 11))
                    .foregroundColor(MilliPalette.textSecondary)
            }
            Spacer()
            Text(tx.formattedAmount)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(MilliPalette.positive)
        }
        .padding(.vertical, 4)
    }

    private func txIcon(_ type: String) -> String {
        switch type {
        case "auto": return "arrow.triangle.2.circlepath"
        case "manual": return "arrow.up.circle.fill"
        case "interest": return "sparkles"
        default: return "circle.fill"
        }
    }

    private func txColor(_ type: String) -> Color {
        switch type {
        case "auto": return MilliPalette.accent
        case "manual": return MilliPalette.positive
        case "interest": return MilliPalette.warning
        default: return MilliPalette.textSecondary
        }
    }
}
