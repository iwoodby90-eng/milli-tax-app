import SwiftUI

// MARK: - MilliCentsView
// Gig-offer profitability analyzer. This is NOT round-up or spare-change investing.

struct MilliCentsView: View {
    var onBack: () -> Void = {}
    @State private var recommendation: OfferRecommendation = .go

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
        }
    }

    private var offerCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OFFER AMOUNT")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
                Text("$32.64")
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(MilliColors.textSecondary)
        }
        .milliCard(padding: 14)
    }

    private var analysisCard: some View {
        VStack(spacing: 0) {
            analysisRow(icon: "point.topleft.down.to.point.bottomright.curvepath", label: "ESTIMATED MILES", value: "24.8 mi")
            divider
            analysisRow(icon: "arrow.trianglehead.2.clockwise.rotate.90", label: "DEAD MILES", value: "6.4 mi")
            divider
            analysisRow(icon: "arrow.uturn.backward", label: "RETURN MILES", value: "7.2 mi")
            divider
            analysisRow(icon: "road.lanes", label: "TOTAL MILES", value: "38.4 mi")
            divider
            analysisRow(icon: "fuelpump.fill", label: "FUEL COST", value: "$4.87")
            divider
            analysisRow(icon: "building.columns.fill", label: "TAX IMPACT", value: "$6.21")
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
                    .foregroundStyle(MilliColors.positive)
                Spacer()
                Text("$21.56")
                    .font(MilliFont.numericLarge)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.positive)
            }

            Divider().overlay(Color.white.opacity(0.06))

            HStack {
                Text("PROFIT PER MILE")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("$0.56")
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
                Text("RECOMMENDATION")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
            }

            Text(recommendation.title)
                .font(.custom("Sora-ExtraBold", size: 36, relativeTo: .largeTitle))
                .foregroundStyle(recommendation.color)
                .shadow(color: recommendation.color.opacity(0.18), radius: 5)

            Text(recommendation.message)
                .font(MilliFont.bodySmall)
                .foregroundStyle(recommendation.color)

            HStack(spacing: 8) {
                ForEach(OfferRecommendation.allCases, id: \.self) { state in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            recommendation = state
                        }
                    } label: {
                        Text(state.title)
                            .font(MilliFont.labelLarge)
                            .foregroundStyle(recommendation == state ? state.color : MilliColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(recommendation == state ? state.color.opacity(0.10) : Color.white.opacity(0.02))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 3)
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
    }
}

enum OfferRecommendation: CaseIterable {
    case go, maybe, no

    var title: String {
        switch self {
        case .go: return "GO"
        case .maybe: return "MAYBE"
        case .no: return "NO"
        }
    }

    var message: String {
        switch self {
        case .go: return "This offer is profitable."
        case .maybe: return "This offer is borderline. Check traffic and return miles."
        case .no: return "This offer is not profitable enough to accept."
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
