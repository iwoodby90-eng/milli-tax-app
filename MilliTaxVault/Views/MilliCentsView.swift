import SwiftUI

// MARK: - MilliCentsView — Screen 4: Offer Analyzer
// Header | Offer amount | Stats grid | Add to Vault | Net Profit | GO button

struct MilliCentsView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                offerAmountSection
                statsGrid
                addToVaultButton
                netProfitCard
                goButton
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

            Text("Milli Cents\u{2122} Offer Analyzer")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Offer Amount

    private var offerAmountSection: some View {
        VStack(spacing: 6) {
            Text("OFFER AMOUNT")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            Text("$32.64")
                .font(MilliFont.heroNumber)
                .foregroundColor(MilliColors.cyanGlow)
        }
        .frame(maxWidth: .infinity)
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    // MARK: - Stats Grid (3x2)

    private var statsGrid: some View {
        VStack(spacing: MilliSpacing.sm) {
            HStack(spacing: MilliSpacing.gridGap) {
                statCell(label: "Estimated Miles", value: "24.8")
                statCell(label: "Dead Miles", value: "6.4")
            }
            HStack(spacing: MilliSpacing.gridGap) {
                statCell(label: "Return Miles", value: "7.2")
                statCell(label: "Total Miles", value: "38.4")
            }
            HStack(spacing: MilliSpacing.gridGap) {
                statCell(label: "Fuel Cost", value: "$4.87", valueColor: MilliColors.warning)
                statCell(label: "Tax Impact", value: "$6.21", valueColor: MilliColors.cyanGlow)
            }
        }
    }

    private func statCell(label: String, value: String, valueColor: Color = MilliColors.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }

    // MARK: - Add to Vault Button

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

    // MARK: - Net Profit Card

    private var netProfitCard: some View {
        VStack(spacing: 6) {
            Text("NET PROFIT")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            Text("$21.56")
                .font(MilliFont.numericLarge)
                .foregroundColor(MilliColors.positive)

            Text("$0.56 per mile")
                .font(MilliFont.bodySmall)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    // MARK: - GO Button

    private var goButton: some View {
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                VStack(spacing: 2) {
                    Text("GO")
                        .font(MilliFont.headline)
                    Text("Profitable Offer")
                        .font(MilliFont.caption)
                }
            }
            .foregroundColor(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.positive, Color(hex: "00D68F")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
