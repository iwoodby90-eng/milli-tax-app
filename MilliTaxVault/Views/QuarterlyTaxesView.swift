import SwiftUI

// MARK: - QuarterlyTaxesView — Screen 7: Estimated taxes breakdown
// Hero amount + due date | Breakdown | Projection | Make a Payment button

struct QuarterlyTaxesView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                heroSection
                breakdownSection
                projectionSection
                makePaymentButton
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

            Text("ESTIMATED TAXES Q2 2024")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)
                .tracking(0.5)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: MilliSpacing.sm) {
            Text("$1,247.00")
                .font(MilliFont.heroNumber)
                .foregroundColor(MilliColors.cyanGlow)

            Text("Due Jun 15, 2024")
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MilliSpacing.lg)
    }

    // MARK: - Breakdown

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("BREAKDOWN")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            breakdownRow(label: "Federal", amount: "$682.00")
            breakdownRow(label: "Self-Employment", amount: "$352.00")
            breakdownRow(label: "State (MI)", amount: "$213.00")
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    private func breakdownRow(label: String, amount: String) -> some View {
        HStack {
            Text(label)
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()

            Text(amount)
                .font(MilliFont.numericSmall)
                .foregroundColor(MilliColors.textPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Tax Projection

    private var projectionSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("TAX PROJECTION")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            projectionRow(label: "Projected Annual", amount: "$4,988.00", color: MilliColors.textPrimary)
            projectionRow(label: "Paid to Date", amount: "$1,665.00", color: MilliColors.positive)
            projectionRow(label: "Remaining", amount: "$3,123.00", color: MilliColors.cyanGlow)
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    private func projectionRow(label: String, amount: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textSecondary)

            Spacer()

            Text(amount)
                .font(MilliFont.numericSmall)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Make a Payment Button

    private var makePaymentButton: some View {
        Button {} label: {
            Text("Make a Payment")
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
}
