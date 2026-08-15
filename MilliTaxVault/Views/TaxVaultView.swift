import SwiftUI

// MARK: - TaxVaultView — Screen 5: Reserve Tax Vault
// Hero amount + ring | Annual target | Add to Vault | Recent Activity list

struct TaxVaultView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                heroSection
                annualTargetSection
                addToVaultButton
                recentActivitySection
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button { onBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MilliColors.textSecondary)
            }
            .buttonStyle(.plain)

            Text("RESERVE TAX VAULT")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)
                .tracking(0.5)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Hero Amount + Ring

    private var heroSection: some View {
        VStack(spacing: MilliSpacing.md) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(MilliColors.border, lineWidth: 8)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: 0.23)
                    .stroke(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 4) {
                    Text("$5,284.17")
                        .font(MilliFont.displayMedium)
                        .foregroundColor(MilliColors.cyanGlow)

                    Text("23% of annual target")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MilliSpacing.md)
    }

    // MARK: - Annual Target

    private var annualTargetSection: some View {
        VStack(spacing: 4) {
            Text("ANNUAL TARGET")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            Text("$22,500.00")
                .font(MilliFont.numericMedium)
                .foregroundColor(MilliColors.textPrimary)

            Text("Due Dec 31, 2024")
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .milliCard()
    }

    // MARK: - Add to Vault

    private var addToVaultButton: some View {
        Button {} label: {
            Text("Add to Vault")
                .font(MilliFont.headline)
                .foregroundColor(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .fill(MilliColors.cyanGlow)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("RECENT ACTIVITY")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            ForEach(activityData) { item in
                activityRow(item)
            }

            // View All link
            Button {} label: {
                Text("View All")
                    .font(MilliFont.labelLarge)
                    .foregroundColor(MilliColors.cyanGlow)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }

    private func activityRow(_ item: VaultActivity) -> some View {
        HStack(spacing: MilliSpacing.md) {
            Circle()
                .fill(item.iconColor.opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(item.iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(MilliFont.headlineSmall)
                    .foregroundColor(MilliColors.textPrimary)
                Text(item.date)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textSecondary)
            }

            Spacer()

            Text(item.amount)
                .font(MilliFont.numericSmall)
                .foregroundColor(item.isNegative ? MilliColors.negative : MilliColors.positive)
        }
        .padding(MilliSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                        .stroke(MilliColors.cardBorderGlow, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Data

    private var activityData: [VaultActivity] {
        [
            VaultActivity(title: "Payout Allocation", date: "Jan 16, 2024", amount: "+$72.34", icon: "briefcase.fill", iconColor: MilliColors.orange, isNegative: false),
            VaultActivity(title: "Manual Transfer", date: "Jan 16, 2024", amount: "+$125.00", icon: "arrow.up.circle.fill", iconColor: MilliColors.deepCyan, isNegative: false),
            VaultActivity(title: "Interest Earned", date: "Jan 13, 2024", amount: "+$3.21", icon: "leaf.fill", iconColor: MilliColors.positive, isNegative: false),
            VaultActivity(title: "Quarterly Payment", date: "Jan 14, 2024", amount: "-$1,247.00", icon: "arrow.down.circle.fill", iconColor: MilliColors.negative, isNegative: true),
        ]
    }
}

// MARK: - VaultActivity Model

struct VaultActivity: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let amount: String
    let icon: String
    let iconColor: Color
    let isNegative: Bool
}
