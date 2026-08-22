import SwiftUI

// MARK: - AccountsView
// Canonical connected accounts interface. Replaces legacy VaultView wrapper.

public struct AccountsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accounts: [ConnectedAccount] = ConnectedAccount.seeded
    @State private var showConnectionSetup = false

    private var onBack: () -> Void

    public init(onBack: @escaping () -> Void = {}) {
        self.onBack = onBack
    }

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                totalBalanceCard
                accountsList
                connectionButton
                connectionStatus
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, MilliLayoutSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showConnectionSetup) {
            accountConnectionSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Accounts")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "building.columns")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
        }
    }

    private var totalBalanceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CONNECTED BALANCES")
                .sectionHeaderStyle()
            Text(totalBalance.formatted(.currency(code: "USD")))
                .font(MilliFont.heroNumber)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
            Text("Demo/local account state")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard(padding: 14)
    }

    private var accountsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCOUNTS")
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(account.color.opacity(0.10))
                                .frame(width: 38, height: 38)
                            Image(systemName: account.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(account.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(account.subtitle)
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(account.balance.formatted(.currency(code: "USD")))
                                .font(MilliFont.numericSmall)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(account.status)
                                .font(MilliFont.caption)
                                .foregroundStyle(account.statusColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if index < accounts.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 56)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private var connectionButton: some View {
        Button {
            showConnectionSetup = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Connect Account")
            }
            .font(MilliFont.headlineSmall)
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(MilliColors.cyanGlow)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var connectionStatus: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MilliColors.positive)
                .padding(.top, 1)

            Text("Production account linking is intentionally unavailable until the verified connection provider is configured. Seed balances are clearly isolated from live financial data.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 12)
    }

    private var accountConnectionSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)

                Text("Account Connection Setup")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("Connect Account will be enabled when the production account-linking provider and secure token exchange are configured. This screen does not simulate a successful bank connection.")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Done") {
                    showConnectionSetup = false
                }
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(MilliColors.cyanGlow)
                )
            }
            .padding(24)
        }
    }
}

private struct ConnectedAccount: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let balance: Double
    let icon: String
    let color: Color
    let status: String
    let statusColor: Color

    static let seeded: [ConnectedAccount] = [
        ConnectedAccount(
            name: "Available to Spend",
            subtitle: "Liquid operating balance",
            balance: 1_438.20,
            icon: "wallet.pass.fill",
            color: MilliColors.cyanGlow,
            status: "Demo",
            statusColor: MilliColors.warning
        ),
        ConnectedAccount(
            name: "Milli Tax Vault™",
            subtitle: "Protected tax reserve",
            balance: 5_284.17,
            icon: "lock.shield.fill",
            color: MilliColors.deepCyan,
            status: "Demo",
            statusColor: MilliColors.warning
        ),
        ConnectedAccount(
            name: "External Checking",
            subtitle: "Connection placeholder",
            balance: 2_840.66,
            icon: "building.columns.fill",
            color: MilliColors.silver,
            status: "Not live",
            statusColor: MilliColors.textTertiary
        )
    ]
}
