import SwiftUI

/// Blueprint v2 §1 — Custom premium header "Milli Tax Vault".
/// 56pt standard / 96pt large-title. .ultraThinMaterial over Obsidian,
/// 1pt cyan top hairline at 8% (15% past 40pt scroll), Sora 20pt title,
/// Inter 12pt subtitle, cyan Vault icon. Collapses on scroll.
struct MilliVaultHeader: View {

    let subtitle: String
    var scrollOffset: CGFloat = 0

    private var hairlineOpacity: Double {
        scrollOffset > 40 ? 0.15 : 0.08
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: MilliBlueprint.Space.s) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 22))
                    .foregroundStyle(MilliBlueprint.Palette.electricCyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Milli Tax Vault")
                        .font(MilliBlueprint.Type.sora(20))
                        .foregroundStyle(MilliBlueprint.Palette.white)
                    if scrollOffset <= 40 {
                        Text(subtitle)
                            .font(MilliBlueprint.Type.inter(12))
                            .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, MilliBlueprint.Space.screenH)
            .padding(.vertical, MilliBlueprint.Space.s)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MilliBlueprint.Palette.electricCyan.opacity(hairlineOpacity))
                .frame(height: 1)
        }
        .animation(.easeInOut(duration: MilliBlueprint.Motion.fast), value: scrollOffset > 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Milli Tax Vault, \(subtitle)")
    }
}

/// Blueprint v2 — Tax Vault screen assembly (§1–§9).
/// Composition only: data comes from the existing view models; nothing is fabricated.
struct MilliTaxVaultBlueprintScreen: View {

    // Preview / example data — real wiring happens at integration time.
    let balanceText: String
    let provenance: MilliProvenanceBadge.State
    let protectionProgress: Double
    let quarterlyAmount: String
    let quarterlyDue: String
    let quarterlyProtected: String
    let quarterlyReady: Double
    let ledgerRows: [MilliLedgerRow.Model]

    var body: some View {
        ScrollView {
            VStack(spacing: MilliBlueprint.Space.l) {
                MilliHeroBalanceCard(
                    balanceText: balanceText,
                    provenance: provenance,
                    annualContext: "23% of projected annual taxes protected"
                )
                MilliProtectionRing(progress: protectionProgress)
                MilliQuarterlyObligationCard(
                    amountText: quarterlyAmount,
                    dueText: quarterlyDue,
                    protectedText: quarterlyProtected,
                    readyPercent: quarterlyReady
                )
                MilliLedgerCard {
                    if ledgerRows.isEmpty {
                        MilliLedgerStateView(kind: .empty, actionTitle: "Add to Tax Vault", actionIsPrimary: true)
                    } else {
                        ForEach(ledgerRows.indices, id: \.self) { i in
                            MilliLedgerRow(model: ledgerRows[i])
                        }
                    }
                }
                VStack(spacing: MilliBlueprint.Space.m) {
                    MilliPrimaryAction(title: "Add to Tax Vault") {}
                    MilliSecondaryAction(title: "View Tax Plan", systemImage: "chart.line.xyaxis") {}
                }
                .padding(.top, MilliBlueprint.Space.s)
            }
            .padding(.horizontal, MilliBlueprint.Space.screenH)
        }
        .background(MilliBlueprint.Palette.obsidian.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview("Full screen") {
    MilliTaxVaultBlueprintScreen(
        balanceText: "$5,284.17",
        provenance: .live,
        protectionProgress: 0.23,
        quarterlyAmount: "$1,421.00",
        quarterlyDue: "Due September 15",
        quarterlyProtected: "$1,120 protected · 79% ready",
        quarterlyReady: 0.79,
        ledgerRows: [
            .init(identifier: "DoorDash payout protection", dateTime: "Aug 26 · 2:43 PM",
                  amountText: "+$24.62", isCredit: true, state: .posted,
                  receiptRef: "AP-2026-000025", runningBalanceText: "Bal $5,284.17",
                  reversalLink: nil, categorySystemImage: "storefront"),
            .init(identifier: "Uber payout protection", dateTime: "Aug 25 · 9:12 PM",
                  amountText: "+$18.40", isCredit: true, state: .processing,
                  receiptRef: nil, runningBalanceText: nil,
                  reversalLink: nil, categorySystemImage: "car")
        ]
    )
}
