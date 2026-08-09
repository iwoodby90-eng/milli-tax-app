import SwiftUI

struct TaxVaultView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TaxVaultViewModel()

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                MilliPageHeader(title: "MILLI TAX VAULT\u{2122}", showBack: true)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        reserveBalanceCard
                        goalStatsRow

                        // Plaid bank connection section
                        if viewModel.hasBanksConnected {
                            connectedBanksSection
                        } else {
                            connectBankCTA
                        }

                        addToVaultButton
                        transactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .task { await viewModel.loadVault() }
    }

    // MARK: - Reserve Balance

    private var reserveBalanceCard: some View {
        MilliCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RESERVE BALANCE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    Text(viewModel.balanceDisplay)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.goalPercentDisplay)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.milliTextSecondary)
                }

                Spacer()

                CircularProgressView(progress: viewModel.goalPercent, size: 64, lineWidth: 5)
            }
        }
    }

    // MARK: - Goal Stats Row

    private var goalStatsRow: some View {
        HStack(spacing: 12) {
            MilliCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ANNUAL TARGET")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    Text(viewModel.annualTarget)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            MilliCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TARGET DATE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    Text("Dec 31, 2024")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Connected Banks (Plaid)

    private var connectedBanksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CONNECTED BANKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                Spacer()
                Button(action: { Task { await viewModel.syncTransactions() } }) {
                    HStack(spacing: 4) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.milliCyan)
                        }
                        Text(viewModel.isSyncing ? "Syncing..." : "Sync")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.milliCyan)
                    }
                }
            }

            ForEach(viewModel.connectedBanks) { bank in
                MilliCard {
                    HStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.milliCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bank.institutionName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            if let synced = bank.lastSynced {
                                Text("Last synced: \(synced)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.milliTextSecondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.milliGreen)
                    }
                }
            }

            Button(action: { Task { await viewModel.startBankLink() } }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                    Text("Add Another Bank")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.milliCyan)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Connect Bank CTA (Plaid)

    private var connectBankCTA: some View {
        MilliCard {
            VStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.milliCyan)

                Text("Connect Your Bank")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Link your bank account to automatically track deposits and allocate taxes.")
                    .font(.system(size: 12))
                    .foregroundColor(.milliTextSecondary)
                    .multilineTextAlignment(.center)

                Button(action: { Task { await viewModel.startBankLink() } }) {
                    HStack {
                        if viewModel.isLinkingBank {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text("Connect with Plaid")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.milliCyan)
                    .cornerRadius(10)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Add to Vault Button

    private var addToVaultButton: some View {
        Button(action: {}) {
            Text("Add to Vault")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.milliCyan)
                .cornerRadius(12)
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRANSACTIONS")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                Spacer()
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.milliCyan)
                }
            }

            VStack(spacing: 0) {
                ForEach(viewModel.displayTransactions) { transaction in
                    transactionRow(transaction)
                }
            }
            .background(Color.milliCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.milliCardBorder, lineWidth: 0.5)
            )
        }
    }

    private func transactionRow(_ transaction: VaultTransaction) -> some View {
        let icon: String = {
            switch transaction.type {
            case "interest": return "percent"
            case "manual": return "arrow.right.circle.fill"
            default: return "arrow.down.circle.fill"
            }
        }()

        return HStack(spacing: 12) {
            Circle()
                .fill(Color.milliCyan.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.milliCyan)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(transaction.date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.milliTextSecondary)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.milliGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
