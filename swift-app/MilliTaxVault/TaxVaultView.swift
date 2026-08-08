import SwiftUI

// MARK: - TaxVaultView

struct TaxVaultView: View {
    @Environment(\.dismiss) private var dismiss

    private let transactions: [VaultTransaction] = [
        VaultTransaction(title: "Payout Allocation", date: "May 10, 2024", amount: "+$72.91"),
        VaultTransaction(title: "Payout Allocation", date: "May 9, 2024", amount: "+$69.21"),
        VaultTransaction(title: "Manual Transfer", date: "May 8, 2024", amount: "+$250.00"),
        VaultTransaction(title: "Interest Earned", date: "May 7, 2024", amount: "+$1.27"),
        VaultTransaction(title: "Payout Allocation", date: "May 6, 2024", amount: "+$66.11"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    titleSection
                    balanceSection
                    progressRing
                    statPills
                    addToVaultButton
                    transactionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.milliBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        HStack(spacing: 0) {
            Text("MILLI TAX VAULT")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .kerning(1.5)
            Text("\u2122")
                .font(.caption)
                .foregroundColor(.white)
                .baselineOffset(8)
        }
    }

    // MARK: - Balance

    private var balanceSection: some View {
        VStack(spacing: 4) {
            Text("RESERVE BALANCE")
                .font(.caption)
                .foregroundColor(.milliMuted)
                .kerning(1.0)

            Text("$5,284.17")
                .font(.system(size: 46, weight: .bold))
                .foregroundColor(.white)

            Text("23.4% of annual target")
                .font(.caption)
                .foregroundColor(.milliMuted)
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: 0.234)
                .stroke(
                    Color.milliAccent,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 160, height: 160)

            Text("23%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.milliAccent)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Stat Pills

    private var statPills: some View {
        HStack(spacing: 12) {
            statPill(title: "Annual Target", value: "$22,500.00")
            statPill(title: "Target Date", value: "Dec 31, 2024")
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.milliMuted)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.milliCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.milliAccent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Add to Vault Button

    private var addToVaultButton: some View {
        Button(action: {}) {
            Text("Add to Vault")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.milliAccent)
                .cornerRadius(12)
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRANSACTIONS")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.milliMuted)
                    .kerning(1.2)
                Spacer()
                Button("View All") {}
                    .font(.caption)
                    .foregroundColor(.milliAccent)
            }

            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    transactionRow(transaction)
                    if index < transactions.count - 1 {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
            .padding(16)
            .milliCard()
        }
    }

    private func transactionRow(_ transaction: VaultTransaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(transaction.date)
                    .font(.caption)
                    .foregroundColor(.milliMuted)
            }
            Spacer()
            Text(transaction.amount)
                .font(.headline)
                .foregroundColor(.milliGreen)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Transaction Model

struct VaultTransaction: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let amount: String
}

#Preview {
    TaxVaultView()
        .preferredColorScheme(.dark)
}
