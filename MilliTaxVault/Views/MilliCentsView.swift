import SwiftUI

// MARK: - MilliCentsView
// Gig-offer profitability analyzer. This is NOT round-up or spare-change investing.
// Recommendation is calculated from offer economics; the user cannot manually pick GO/MAYBE/NO.

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
                offerAnalysisCard
                decisionCard
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

            VStack(spacing: 1) {
                Text("Milli Cents™")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Offer Analyzer")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.025)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About Milli Cents")
        }
        .frame(minHeight: 38)
    }

    private var offerAnalysisCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                Text("OFFER AMOUNT")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.85)
                    .foregroundStyle(MilliColors.textSecondary)

                Text(currency(offer.offerAmount))
                    .font(.custom("Sora-SemiBold", size: 31, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.cyanGlow)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.055), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider().overlay(MilliColors.cyanGlow.opacity(0.15))

            analysisRow(label: "Estimated Miles", value: number(offer.estimatedMiles))
            divider
            analysisRow(label: "Dead Miles", value: number(offer.deadMiles))
            divider
            analysisRow(label: "Return Miles", value: number(offer.returnMiles))
            divider
            analysisRow(label: "Total Miles", value: number(totalMiles), emphasized: true)
            divider
            analysisRow(label: "Fuel Cost", value: currency(offer.fuelCost))
            divider
            analysisRow(label: "Tax Impact", value: currency(offer.taxImpact))
        }
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0C1720"), Color(hex: "071014")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.75)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offer amount \(currency(offer.offerAmount)), total distance \(miles(totalMiles)), fuel cost \(currency(offer.fuelCost)), estimated tax impact \(currency(offer.taxImpact))")
    }

    private var divider: some View {
        Divider()
            .overlay(Color.white.opacity(0.055))
            .padding(.horizontal, 12)
    }

    private func analysisRow(label: String, value: String, emphasized: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(emphasized ? MilliFont.bodyMedium : MilliFont.bodySmall)
                .foregroundStyle(emphasized ? MilliColors.textPrimary : MilliColors.textSecondary)

            Spacer()

            Text(value)
                .font(emphasized ? MilliFont.numericSmall : MilliFont.bodyMedium)
                .monospacedDigit()
                .foregroundStyle(emphasized ? MilliColors.textPrimary : MilliColors.textPrimary)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, emphasized ? 9 : 8)
    }

    private var decisionCard: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("NET PROFIT")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)

                Text(currency(netProfit))
                    .font(.custom("Sora-Bold", size: 36, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundStyle(recommendation.color)
                    .contentTransition(.numericText())
                    .shadow(color: recommendation.color.opacity(0.18), radius: 6)

                Text("\(currency(profitPerMile)) per mile")
                    .font(MilliFont.bodySmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Divider()
                .overlay(recommendation.color.opacity(0.22))

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(recommendation.color)
                        .frame(width: 38, height: 38)
                        .shadow(color: recommendation.color.opacity(0.28), radius: 8)

                    Image(systemName: recommendation.symbol)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MilliColors.blackGlass)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(recommendation.title)
                        .font(.custom("Sora-Bold", size: 34, relativeTo: .largeTitle))
                        .foregroundStyle(recommendation.color)
                        .shadow(color: recommendation.color.opacity(0.16), radius: 5)

                    Text(recommendation.shortMessage)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                calculationPill("\(number(totalMiles)) mi total")
                calculationPill("\(currency(offer.fuelCost)) fuel")
                calculationPill("\(currency(offer.taxImpact)) tax")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [recommendation.color.opacity(0.13), Color(hex: "07130F"), MilliColors.cardBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(recommendation.color.opacity(0.72), lineWidth: 1.05)
                }
                .shadow(color: recommendation.color.opacity(0.12), radius: 14)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net profit \(currency(netProfit)), \(currency(profitPerMile)) per mile. Milli recommendation \(recommendation.title). \(recommendation.message)")
    }

    private func calculationPill(_ text: String) -> some View {
        Text(text)
            .font(MilliFont.caption)
            .foregroundStyle(MilliColors.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.035))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.045), lineWidth: 0.6)
                    }
            )
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }

    private func miles(_ value: Double) -> String {
        "\(number(value)) miles"
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
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

    var shortMessage: String {
        switch self {
        case .go: return "Profitable Offer"
        case .maybe: return "Borderline Offer"
        case .no: return "Not Profitable"
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
        case .go: return "checkmark"
        case .maybe: return "exclamationmark"
        case .no: return "xmark"
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
