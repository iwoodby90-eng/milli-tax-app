import SwiftUI

struct TaxVaultView: View {
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                MilliPageHeader(title: "MILLI TAX VAULT\u{2122}", showBack: true)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Reserve Balance
                        reserveBalanceCard

                        // Goal Stats
                        goalStatsRow

                        // Add to Vault CTA
                        addToVaultButton

                        // Transactions
                        transactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
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
                    Text("$5,284.17")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("23.4% of annual target")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.milliTextSecondary)
                }

                Spacer()

                CircularProgressView(progress: 0.234, size: 64, lineWidth: 5)
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
                    Text("$22,500.00")
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
                transactionRow(icon: "arrow.down.circle.fill", label: "Payout Allocation", date: "May 10, 2024", amount: "+$72.91")
                transactionRow(icon: "arrow.down.circle.fill", label: "Payout Allocation", date: "May 9, 2024", amount: "+$69.21")
                transactionRow(icon: "arrow.right.circle.fill", label: "Manual Transfer", date: "Jul 2021", amount: "+$250.00")
                transactionRow(icon: "percent", label: "Interest Earned", date: "May 7, 2024", amount: "+$1.27")
                transactionRow(icon: "arrow.down.circle.fill", label: "Payout Allocation", date: "May 6, 2024", amount: "+$86.11")
            }
            .background(Color.milliCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.milliCardBorder, lineWidth: 0.5)
            )
        }
    }

    private func transactionRow(icon: String, label: String, date: String, amount: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.milliCyan.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.milliCyan)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.milliTextSecondary)
            }

            Spacer()

            Text(amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.milliGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
