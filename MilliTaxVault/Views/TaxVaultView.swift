import SwiftUI

// MARK: - TaxVaultView
// Compact premium reserve-account presentation matching the approved Milli reference.
// Production money movement remains explicit: the transfer control opens setup
// until a verified funding rail is connected rather than pretending a transfer occurred.

struct TaxVaultView: View {
    var onBack: () -> Void = {}

    @State private var showTransferSetup = false

    private let vault = TaxVaultDisplayModel.reference

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                reserveHero
                targetRow
                addButton
                recentActivity
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showTransferSetup) {
            transferSetupSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        ZStack {
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
                Button {} label: {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notifications")
            }

            Text("Milli Tax Vault™")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(height: 40)
    }

    private var reserveHero: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("RESERVE BALANCE")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(currency(vault.balance))
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text("\(progressPercentText) of annual target")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 4)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: vault.progress)
                    .stroke(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 7)
                Text(progressPercentText)
                    .font(.custom("Sora-SemiBold", size: 17))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            .frame(width: 78, height: 78)
        }
        .milliCard(padding: 14)
    }

    private var targetRow: some View {
        HStack(spacing: 0) {
            metric("ANNUAL TARGET", currency(vault.annualTarget), subtitle: "Tax reserve goal")
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 48)
            metric("CURRENT RESERVE RATE", "\(Int(vault.reserveRate * 100))%", subtitle: "Applied to payouts")
        }
        .milliCard(padding: 12)
    }

    private func metric(_ title: String, _ value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(subtitle)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var addButton: some View {
        Button {
            showTransferSetup = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("Add to Vault")
                    .font(MilliFont.headlineSmall)
            }
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, Color(hex: "03B8DC")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT ACTIVITY")
                    .sectionHeaderStyle()
                Spacer()
                Text("AUDIT LEDGER")
                    .font(MilliFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(vault.activity.enumerated()), id: \.element.id) { index, item in
                    transactionRow(item)
                    if index < vault.activity.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.055))
                            .padding(.leading, 46)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
        .padding(.top, 2)
    }

    private func transactionRow(_ item: VaultActivity) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(item.iconColor)
                .frame(width: 30, height: 30)
                .background(Circle().fill(item.iconColor.opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(item.dateLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Text(item.amount.formatted(.currency(code: "USD").sign(strategy: .always())))
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(item.amount < 0 ? MilliColors.negative : MilliColors.positive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var transferSetupSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "building.columns.circle.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)

                VStack(spacing: 6) {
                    Text("Connect a Funding Source")
                        .font(MilliFont.screenTitle)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Vault transfers will become available after a production funding account is connected and verified. No money is moved from this setup screen.")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button("Done") {
                    showTransferSetup = false
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

    private var progressPercentText: String {
        "\(Int((Double(vault.progress) * 100).rounded()))%"
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

private struct TaxVaultDisplayModel {
    let balance: Double
    let annualTarget: Double
    let reserveRate: Double
    let activity: [VaultActivity]

    var progress: CGFloat {
        guard annualTarget > 0 else { return 0 }
        return CGFloat(min(max(balance / annualTarget, 0), 1))
    }

    static var reference: TaxVaultDisplayModel {
        TaxVaultDisplayModel(
            balance: 5_284.17,
            annualTarget: 22_800,
            reserveRate: 0.23,
            activity: [
                VaultActivity(title: "Amazon Flex", dateLabel: "Today, 2:34 PM", amount: 43.11, icon: "shippingbox.fill", iconColor: MilliColors.cyanGlow),
                VaultActivity(title: "Spark Driver", dateLabel: "Today, 10:12 AM", amount: 36.06, icon: "sparkles", iconColor: Color(hex: "4E8CFF")),
                VaultActivity(title: "DoorDash", dateLabel: "Yesterday", amount: 21.70, icon: "bag.fill", iconColor: MilliColors.negative),
                VaultActivity(title: "Quarterly Tax Payment", dateLabel: "Previous quarter", amount: -1_247.00, icon: "building.columns.fill", iconColor: MilliColors.negative)
            ]
        )
    }
}

struct VaultActivity: Identifiable {
    let id = UUID()
    let title: String
    let dateLabel: String
    let amount: Double
    let icon: String
    let iconColor: Color
}
