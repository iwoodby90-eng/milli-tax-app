import SwiftUI

// MARK: - TaxVaultView
// Compact premium reserve-account presentation with auditable ledger.

struct TaxVaultView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                reserveHero
                targetRow
                addButton
                transactions
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
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
            }

            Text("MILLI TAX VAULT™")
                .font(MilliFont.headlineSmall)
                .tracking(1.0)
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
                Text("$5,284.17")
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text("23.4% of annual target")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 4)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: 0.234)
                    .stroke(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("23%")
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
            metric("ANNUAL TARGET", "$22,500.00")
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 42)
            metric("TARGET DATE", "Dec 31, 2024")
        }
        .milliCard(padding: 12)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addButton: some View {
        Button {} label: {
            Text("Add to Vault")
                .font(MilliFont.headlineSmall)
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

    private var transactions: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TRANSACTIONS")
                    .sectionHeaderStyle()
                Spacer()
                Button {} label: {
                    Text("View All")
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(Array(activityData.enumerated()), id: \.element.id) { index, item in
                    transactionRow(item)
                    if index < activityData.count - 1 {
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
                Text(item.date)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Text(item.amount)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(item.isNegative ? MilliColors.negative : MilliColors.positive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var activityData: [VaultActivity] {
        [
            VaultActivity(title: "Payout Allocation", date: "May 10, 2024", amount: "+$72.91", icon: "arrow.down.to.line", iconColor: MilliColors.cyanGlow, isNegative: false),
            VaultActivity(title: "Payout Allocation", date: "May 9, 2024", amount: "+$69.21", icon: "arrow.down.to.line", iconColor: MilliColors.cyanGlow, isNegative: false),
            VaultActivity(title: "Manual Transfer", date: "May 8, 2024", amount: "+$250.00", icon: "arrow.left.arrow.right", iconColor: MilliColors.deepCyan, isNegative: false),
            VaultActivity(title: "Interest Earned", date: "May 7, 2024", amount: "+$1.27", icon: "plus.circle.fill", iconColor: MilliColors.positive, isNegative: false),
            VaultActivity(title: "Quarterly Payment", date: "Apr 15, 2024", amount: "-$1,247.00", icon: "building.columns.fill", iconColor: MilliColors.negative, isNegative: true)
        ]
    }
}

struct VaultActivity: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let amount: String
    let icon: String
    let iconColor: Color
    let isNegative: Bool
}
