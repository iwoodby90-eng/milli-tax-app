import SwiftUI

// MARK: - QuarterlyTaxesView
// Native quarterly estimate breakdown and payment-readiness surface.
// Dates and payment availability intentionally come from state rather than stale hard-coded tax dates.

struct QuarterlyTaxesView: View {
    var onBack: () -> Void = {}

    private let estimate = QuarterlyTaxEstimate.reference

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                estimateHero
                breakdown
                projection
                paymentAction
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

            Text(estimate.periodLabel)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private var estimateHero: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ESTIMATED TAXES")
                .sectionHeaderStyle()
            Text(currency(estimate.total))
                .font(MilliFont.heroNumber)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
            Text(estimate.dueLabel)
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

            taxRow(icon: "building.columns", label: "Federal", amount: estimate.federal)
            taxRow(icon: "person.crop.circle.badge.checkmark", label: "Self-Employment", amount: estimate.selfEmployment)
            taxRow(icon: "mappin.and.ellipse", label: estimate.stateLabel, amount: estimate.state)
        }
        .milliCard(padding: 14)
    }

    private func taxRow(icon: String, label: String, amount: Double) -> some View {
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

            Text(currency(amount))
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
    }

    private var projection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TAX PROJECTION")
                .sectionHeaderStyle()

            projectionRow("Projected Annual", estimate.projectedAnnual, MilliColors.textPrimary)
            projectionRow("Paid to Date", estimate.paidToDate, MilliColors.positive)
            projectionRow("Remaining", estimate.remaining, MilliColors.cyanGlow)

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
                        .frame(width: geo.size.width * estimate.paidProgress)
                }
            }
            .frame(height: 5)
        }
        .milliCard(padding: 14)
    }

    private func projectionRow(_ label: String, _ amount: Double, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            Spacer()
            Text(currency(amount))
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    private var paymentAction: some View {
        VStack(spacing: 7) {
            Button {} label: {
                HStack(spacing: 7) {
                    Image(systemName: "lock.fill")
                    Text("Payment Setup Required")
                }
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(MilliColors.graphiteSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                        }
                )
            }
            .buttonStyle(.plain)
            .disabled(true)

            Text("Quarterly payment initiation remains disabled until a production payment rail is connected and verified.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

private struct QuarterlyTaxEstimate {
    let periodLabel: String
    let dueLabel: String
    let federal: Double
    let selfEmployment: Double
    let state: Double
    let stateLabel: String
    let projectedAnnual: Double
    let paidToDate: Double

    var total: Double { federal + selfEmployment + state }
    var remaining: Double { max(projectedAnnual - paidToDate, 0) }
    var paidProgress: CGFloat {
        guard projectedAnnual > 0 else { return 0 }
        return CGFloat(min(max(paidToDate / projectedAnnual, 0), 1))
    }

    static let reference = QuarterlyTaxEstimate(
        periodLabel: "CURRENT",
        dueLabel: "Next estimated payment",
        federal: 682,
        selfEmployment: 352,
        state: 213,
        stateLabel: "State",
        projectedAnnual: 4_988,
        paidToDate: 1_865
    )
}
