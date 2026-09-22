import SwiftUI

// MARK: - QuarterlyTaxesView
// Estimated-payment breakdown for the current federal schedule.
//
// Every figure comes from MilliFinancialSnapshot: the user's declared tax
// profile through QuarterlyTaxEstimator for liability, their recorded
// deductions, and the verified payout ledger for what is already reserved.
// Without a tax profile the screen states what is missing instead of
// presenting a sample estimate.

struct QuarterlyTaxesView: View {
    var onBack: () -> Void = {}

    private let estimate = QuarterlyTaxDisplayModel.reference
    private var showsReferenceData: Bool { ReferenceDataPolicy.allowsDemoReferenceData }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                if showsReferenceData {
                    estimateHero
                    breakdown
                    projection
                } else {
                    unavailableState
                }
                paymentAction
            }
        }
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
            .accessibilityLabel("Back")

            Spacer()

            Text("Quarterly Taxes")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            ProvenanceTag(label: ReferenceDataPolicy.provenance)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.07))
                    .frame(width: 58, height: 58)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text("Your quarterly estimate is not available yet")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(
                "Complete your tax profile and connect verified income data. Milli will calculate " +
                "the estimate from authenticated records instead of displaying reference numbers."
            )
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .milliCard(padding: 18)
    }

    private var estimateHero: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                MilliMicroLabel(text: "Estimated payment", accent: true)

                Text(MilliFigureFormat.currency(snapshot.quarterlyLiability))
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .milliFigure(MilliFigureFormat.currency(snapshot.quarterlyLiability))

                Text(dueCaption)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer(minLength: 0)

            MilliGaugeRing(
                progress: snapshot.reserveProgress,
                value: MilliFigureFormat.percent(snapshot.reserveProgress),
                caption: "Funded",
                size: 72,
                lineWidth: 6.5
            )
        }
        .milliCard(padding: 14)
    }

    private var dueCaption: String {
        guard let due = snapshot.nextEstimatedPaymentDue else {
            return "Add your tax profile to see the next due date"
        }
        return "Due \(MilliFigureFormat.date(due))"
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            MilliMicroLabel(text: "Annual breakdown", accent: true)

            taxRow(
                icon: "building.columns",
                label: "Federal income tax",
                value: MilliFigureFormat.currency(decimalValue(\.federalIncomeTax))
            )
            taxRow(
                icon: "person.crop.circle.badge.checkmark",
                label: "Self-employment tax",
                value: MilliFigureFormat.currency(decimalValue(\.selfEmploymentTax))
            )
            taxRow(
                icon: "minus.circle",
                label: "Qualified business income deduction",
                value: MilliFigureFormat.currency(decimalValue(\.qbiDeduction))
            )
            taxRow(
                icon: "percent",
                label: "Effective rate",
                value: MilliFigureFormat.percent(snapshot.effectiveRate)
            )

            if snapshot.annualEstimate == nil {
                Text("Complete your tax profile so Milli can estimate from your own income and filing status. State tax is not modelled.")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard(padding: 14)
    }

    private func decimalValue(_ keyPath: KeyPath<QuarterlyTaxEstimator.Estimate, Decimal>) -> Double? {
        guard let estimate = snapshot.annualEstimate else { return nil }
        return NSDecimalNumber(decimal: estimate[keyPath: keyPath]).doubleValue
    }

    private func taxRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 28, height: 28)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

            Text(label)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 4)

            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .milliFigure(value)
        }
    }

    private var reserveProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            MilliMicroLabel(text: "Reserve against liability", accent: true)

            progressRow("Annual liability", MilliFigureFormat.currency(snapshot.annualLiability), MilliColors.textPrimary)
            progressRow("Reserved to date", MilliFigureFormat.currency(snapshot.reservedForTaxes), MilliColors.positive)
            progressRow("Remaining", MilliFigureFormat.currency(snapshot.remainingToGoal), MilliColors.cyanGlow)

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
                        .frame(width: geo.size.width * (snapshot.reserveProgress ?? 0))
                }
            }
            .frame(height: 5)
            .accessibilityHidden(true)
        }
        .milliCard(padding: 14)
    }

    private func progressRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            Spacer()
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliPlaceholder.isPlaceholder(value) ? MilliColors.textTertiary : color)
        }
        .accessibilityElement(children: .combine)
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
                        .fill(MilliColors.elevated)
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
}

#Preview {
    QuarterlyTaxesView()
}


private struct QuarterlyTaxDisplayModel {
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

    static let reference = QuarterlyTaxDisplayModel(
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
