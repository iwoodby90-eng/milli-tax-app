import SwiftUI

// MARK: - TaxVaultView
// Premium Tax Vault surface. The visual hierarchy follows the approved Milli
// design language while remaining explicit about authority: reference balances
// are presentation fixtures and no transfer is represented as completed unless
// a verified production rail confirms it.

struct TaxVaultView: View {
    var onBack: () -> Void = {}

    @State private var showTransferSetup = false
    @State private var showNotifications = false

    private let vault = TaxVaultDisplayModel.reference

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                reserveHero
                ledgerSection
                actionGrid
                complianceFooter
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 8)
        }
        .background(screenBackground)
        .sheet(isPresented: $showTransferSetup) {
            transferSetupSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotifications) {
            MilliDetailSheet(title: "Notifications")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var screenBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            LinearGradient(
                colors: [Color(hex: "071116"), Color(hex: "030507"), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.060), Color.clear],
                center: UnitPoint(x: 0.82, y: 0.10),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            MilliMMark(size: 27)
                .frame(width: 31, height: 31)

            Spacer()

            VStack(spacing: 1) {
                Text("Milli Tax Vault™")
                    .font(.custom("Sora-SemiBold", size: 16.5, relativeTo: .headline))
                    .foregroundStyle(MilliColors.textPrimary)
                Text("PROTECT · PREPARE · PAY")
                    .font(.custom("Inter-SemiBold", size: 7.8, relativeTo: .caption2))
                    .tracking(1.0)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            Button {
                showNotifications = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.035))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bell")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MilliColors.silverBright)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .frame(height: 44)
    }

    private var reserveHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("VAULT BALANCE")
                            .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                            .tracking(0.85)
                            .foregroundStyle(MilliColors.textSecondary)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }

                    Text(currency(vault.balance))
                        .font(.custom("Sora-SemiBold", size: 35, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("Set aside for taxes")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)

                    Text("Planning reserve rate: \(Int(vault.reserveRate * 100))%")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer(minLength: 4)

                reserveRing
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.deepCyan, Color(hex: "8AF8FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * vault.progress)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.24), radius: 3)
                }
            }
            .frame(height: 5)

            HStack {
                Text("\(progressPercentText) of annual target")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("Target \(currency(vault.annualTarget))")
                    .font(MilliFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .padding(16)
        .background(heroSurface)
    }

    private var reserveRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: vault.progress)
                .stroke(
                    LinearGradient(
                        colors: [MilliColors.deepCyan, Color(hex: "8AF8FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 6)

            VStack(spacing: 0) {
                Text(progressPercentText)
                    .font(.custom("Sora-SemiBold", size: 22, relativeTo: .title3))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text("RESERVED")
                    .font(.custom("Inter-SemiBold", size: 7.5, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.cyanGlow)
            }
        }
        .frame(width: 88, height: 88)
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AUDITABLE LEDGER")
                        .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption))
                        .tracking(0.75)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("Recent reserve activity")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
            .padding(.horizontal, 13)
            .padding(.top, 13)
            .padding(.bottom, 7)

            ForEach(Array(vault.activity.enumerated()), id: \.element.id) { index, item in
                transactionRow(item)
                if index < vault.activity.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.055))
                        .padding(.leading, 52)
                }
            }
        }
        .background(MilliCardBackground(showGlow: true))
    }

    private func transactionRow(_ item: VaultActivity) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(item.iconColor.opacity(0.09))
                    .frame(width: 33, height: 33)
                    .overlay {
                        Circle().stroke(item.iconColor.opacity(0.22), lineWidth: 0.7)
                    }
                Image(systemName: item.icon)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(item.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.custom("Inter-SemiBold", size: 13, relativeTo: .footnote))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(item.dateLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Text(item.amount.formatted(.currency(code: "USD").sign(strategy: .always())))
                .font(.custom("Sora-SemiBold", size: 13, relativeTo: .subheadline))
                .monospacedDigit()
                .foregroundStyle(item.amount < 0 ? MilliColors.negative : MilliColors.cyanGlow)
        }
        .padding(.horizontal, 13)
        .frame(height: 58)
        .accessibilityElement(children: .combine)
    }

    private var actionGrid: some View {
        HStack(spacing: 9) {
            Button {
                showTransferSetup = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(MilliColors.cyanGlow)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(MilliColors.textTertiary)
                    }

                    Text("TRANSFER / ADD FUNDS")
                        .font(.custom("Inter-SemiBold", size: 8.2, relativeTo: .caption2))
                        .tracking(0.55)
                        .foregroundStyle(MilliColors.textSecondary)

                    Text("Add to Vault")
                        .font(.custom("Sora-SemiBold", size: 16, relativeTo: .headline))
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("Production rail required")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                .padding(13)
                .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading)
                .background(MilliCardBackground(showGlow: true))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MilliColors.silverBright)
                    Spacer()
                }

                Text("ANNUAL TARGET")
                    .font(.custom("Inter-SemiBold", size: 8.2, relativeTo: .caption2))
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.textSecondary)

                Text(currency(vault.annualTarget))
                    .font(.custom("Sora-SemiBold", size: 18, relativeTo: .title3))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Reserve goal")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading)
            .background(MilliCardBackground(showGlow: false))
        }
    }

    private var complianceFooter: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("SAFETY & ACCOUNTABILITY")
                    .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                    .tracking(0.65)
                    .foregroundStyle(MilliColors.textSecondary)

                Text("Milli separates planning from confirmed money movement. Reserve status changes only after authoritative backend confirmation.")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(13)
        .background(MilliCardBackground(showGlow: false))
    }

    private var transferSetupSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                ChromeEmblemView(size: 58)

                VStack(spacing: 6) {
                    Text("Connect a Funding Source")
                        .font(MilliFont.screenTitle)
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("Vault transfers become available after a production funding account is connected and verified. No money is moved from this setup screen.")
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
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
            .padding(24)
        }
    }

    private var heroSurface: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "152128"), Color(hex: "0A1014"), Color(hex: "050708")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), MilliColors.cyanGlow.opacity(0.20), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: .black.opacity(0.48), radius: 14, y: 8)
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
