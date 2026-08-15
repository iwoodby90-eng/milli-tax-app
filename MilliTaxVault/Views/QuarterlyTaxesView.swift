import SwiftUI

// MARK: - QuarterlyTaxesView
// Native quarterly estimate breakdown and payment-readiness surface.

struct QuarterlyTaxesView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                estimateHero
                breakdown
                projection
                paymentButton
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
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

            Text("Quarterly Taxes")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Text("Q2 2024")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private var estimateHero: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ESTIMATED TAXES")
                .sectionHeaderStyle()
            Text("$1,247.00")
                .font(MilliFont.heroNumber)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
            Text("Due Jun 15, 2024")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard(padding: 14)
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BREAKDOWN")
                .sectionHeaderStyle()

            taxRow(icon: "building.columns", label: "Federal", amount: "$682.00")
            taxRow(icon: "person.crop.circle.badge.checkmark", label: "Self-Employment", amount: "$352.00")
            taxRow(icon: "mappin.and.ellipse", label: "State (MI)", amount: "$213.00")
        }
        .milliCard(padding: 14)
    }

    private func taxRow(icon: String, label: String, amount: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 28, height: 28)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

            Text(label)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Text(amount)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
    }

    private var projection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TAX PROJECTION")
                .sectionHeaderStyle()

            projectionRow("Projected Annual", "$4,988.00", MilliColors.textPrimary)
            projectionRow("Paid to Date", "$1,865.00", MilliColors.positive)
            projectionRow("Remaining", "$3,123.00", MilliColors.cyanGlow)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.37)
                }
            }
            .frame(height: 5)
        }
        .milliCard(padding: 14)
    }

    private func projectionRow(_ label: String, _ amount: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            Spacer()
            Text(amount)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    private var paymentButton: some View {
        Button {} label: {
            Text("Make a Payment")
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
                )
        }
        .buttonStyle(.plain)
    }
}
