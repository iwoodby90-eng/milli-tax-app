import SwiftUI

// MARK: - MilliCentsView
// Gig-offer profitability analyzer. This is NOT round-up or spare-change investing.
// Recommendation is calculated from the offer economics; the user cannot manually pick GO/MAYBE/NO.

struct MilliCentsView: View {
    var onBack: () -> Void = {}

    @State private var offer = GigOfferAnalysis.reference

    private var totalMiles: Double {
        offer.estimatedMiles + offer.deadMiles + offer.returnMiles
    }

    private var netProfit: Double {
        max(0, offer.offerAmount - offer.fuelCost - offer.taxImpact)
    }

    private var profitPerMile: Double {
        guard totalMiles > 0 else { return 0 }
        return netProfit / totalMiles
    }

    private var recommendation: OfferRecommendation {
        OfferRecommendation.evaluate(profitPerMile: profitPerMile, netProfit: netProfit)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                offerCard
                analysisCard
                profitCard
                recommendationCard
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack(alignment: .top) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("Milli Cents™")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Offer Analyzer")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About Milli Cents")
        }
    }

    private var offerCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OFFER AMOUNT")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(currency(offer.offerAmount))
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("ANALYZING")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.65)
                    .foregroundStyle(MilliColors.cyanGlow)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
        }
        .milliCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offer amount \(currency(offer.offerAmount))")
    }

    private var analysisCard: some View {
        VStack(spacing: 0) {
            analysisRow(icon: "point.topleft.down.to.point.bottomright.curvepath", label: "ESTIMATED MILES", value: miles(offer.estimatedMiles))
            divider
            analysisRow(icon: "arrow.trianglehead.2.clockwise.rotate.90", label: "DEAD MILES", value: miles(offer.deadMiles))
            divider
            analysisRow(icon: "arrow.uturn.backward", label: "RETURN MILES", value: miles(offer.returnMiles))
            divider
            analysisRow(icon: "road.lanes", label: "TOTAL MILES", value: miles(totalMiles))
            divider
            analysisRow(icon: "fuelpump.fill", label: "FUEL COST", value: currency(offer.fuelCost))
            divider
            analysisRow(icon: "building.columns.fill", label: "TAX IMPACT", value: currency(offer.taxImpact))
        }
        .background(MilliCardBackground(showGlow: true))
    }

    private var divider: some View {
        Divider()
            .overlay(Color.white.opacity(0.055))
            .padding(.leading, 46)
    }

    private func analysisRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.035)))

            Text(label)
                .font(MilliFont.sectionLabel)
                .tracking(0.45)
                .foregroundStyle(MilliColors.textSecondary)

            Spacer()

            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var profitCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("NET PROFIT")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(recommendation.color)
                Spacer()
                Text(currency(netProfit))
                    .font(MilliFont.numericLarge)
                    .monospacedDigit()
                    .foregroundStyle(recommendation.color)
                    .contentTransition(.numericText())
            }

            Divider().overlay(Color.white.opacity(0.06))

            HStack {
                Text("PROFIT PER MILE")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text(currency(profitPerMile))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
        }
        .milliCard(padding: 14)
    }

    private var recommendationCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("MILLI RECOMMENDATION")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()

                Image(systemName: recommendation.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(recommendation.color)
            }

            Text(recommendation.title)
                .font(.custom("Sora-Bold", size: 38, relativeTo: .largeTitle))
                .foregroundStyle(recommendation.color)
                .shadow(color: recommendation.color.opacity(0.18), radius: 5)

            Text(recommendation.message)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                calculationPill("$\(String(format: "%.2f", profitPerMile))/mi")
                calculationPill("\(String(format: "%.1f", totalMiles)) mi total")
                calculationPill("\(currency(netProfit)) net")
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [recommendation.color.opacity(0.09), MilliColors.cardBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(recommendation.color.opacity(0.52), lineWidth: 0.9)
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Milli recommendation \(recommendation.title). \(recommendation.message)")
    }

    private func calculationPill(_ text: String) -> some View {
        Text(text)
            .font(MilliFont.caption)
            .foregroundStyle(MilliColors.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.035))
            )
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }

    private func miles(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(1)))) mi"
    }
}

private struct GigOfferAnalysis {
    let offerAmount: Double
    let estimatedMiles: Double
    let deadMiles: Double
    let returnMiles: Double
    let fuelCost: Double
    let taxImpact: Double

    static let reference = GigOfferAnalysis(
        offerAmount: 32.64,
        estimatedMiles: 24.8,
        deadMiles: 6.4,
        returnMiles: 7.2,
        fuelCost: 4.87,
        taxImpact: 6.21
    )
}

enum OfferRecommendation: CaseIterable {
    case go, maybe, no

    static func evaluate(profitPerMile: Double, netProfit: Double) -> OfferRecommendation {
        guard netProfit > 0 else { return .no }
        if profitPerMile >= 0.50 { return .go }
        if profitPerMile >= 0.25 { return .maybe }
        return .no
    }

    var title: String {
        switch self {
        case .go: return "GO"
        case .maybe: return "MAYBE"
        case .no: return "NO"
        }
    }

    var message: String {
        switch self {
        case .go: return "This offer clears Milli's current profitability threshold."
        case .maybe: return "Borderline economics. Review traffic, wait time, and return distance before accepting."
        case .no: return "This offer does not clear Milli's current profitability threshold."
        }
    }

    var symbol: String {
        switch self {
        case .go: return "checkmark.circle.fill"
        case .maybe: return "exclamationmark.triangle.fill"
        case .no: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .go: return MilliColors.positive
        case .maybe: return MilliColors.warning
        case .no: return MilliColors.negative
        }
    }
}
