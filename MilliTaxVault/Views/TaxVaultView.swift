import SwiftUI

// MARK: - TaxVaultView
// Routed Milli Tax Vault™ surface (ContentView → .taxVault).
//
// DATA TRUTH CONTRACT
// -------------------
// This screen owns no financial data of its own. It renders MilliTaxVaultScreen,
// which is driven exclusively by MilliTaxVaultViewModel / the MILLI API: settled
// ledger entries and Plaid-linked account snapshots. The previous seeded
// TaxVaultDisplayModel (a $5,284.17 balance, a $22,800 annual target, a 23%
// reserve rate and four invented payout rows) has been deleted. Until the driver
// connects a bank account through Plaid, no amount is displayed at all.

struct TaxVaultView: View {
    var onBack: () -> Void = {}

    /// Presents the bank-connection flow. Injected by the shell when available.
    var onConnectBank: (() -> Void)?

    @State private var showConnectHelp = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            MilliTaxVaultScreen(
                onConnectBank: onConnectBank ?? { showConnectHelp = true }
            )

            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.top, 8)
            .accessibilityLabel("Back")
        }
        .sheet(isPresented: $showConnectHelp) {
            connectHelpSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var connectHelpSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "building.columns.circle.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                Text("Connect a Bank Account")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Open Accounts & Connections to link your bank securely. Your Tax Vault balance and activity appear here once real transactions arrive. No money moves from this screen.")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Done") { showConnectHelp = false }
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

#Preview {
    // Renders the un-connected state: no fabricated numbers.
    TaxVaultView()
}
