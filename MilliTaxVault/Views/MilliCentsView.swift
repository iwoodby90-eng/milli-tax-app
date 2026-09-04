import SwiftUI

// MARK: - MilliCentsView
// Autonomous Gig-Offer Profitability Analyzer & Telemetry Engine.
// Supports both Manual Offer Entry (instant custom calculations) and Live Gig Driving Platform Connections
// (DoorDash, Uber, Lyft, Spark Driver, Amazon Flex, Instacart, Grubhub).

struct MilliCentsView: View {
    var onBack: () -> Void = {}

    @State private var mode: MilliCentsMode = .manualCalculator
    @State private var selectedPlatform: String = "DoorDash"
    @State private var offerAmount: Double = 32.64
    @State private var estimatedMiles: Double = 24.8
    @State private var deadMiles: Double = 6.4
    @State private var returnMiles: Double = 7.2
    @State private var gasPrice: Double = 3.85
    @State private var vehicleMpg: Double = 26.0
    @State private var effectiveTaxRate: Double = 0.25

    @State private var showInfo = false
    @State private var showPlatformConnectSheet = false
    @State private var liveIncomingOffers: [LiveGigOffer] = LiveGigOffer.sampleLiveOffers

    // Domain model — the view renders this; it never re-implements the math.
    private var analyzer: MilliCentsAnalyzer {
        MilliCentsAnalyzer(
            input: MilliCentsOfferInput(
                offerAmount: offerAmount,
                estimatedMiles: estimatedMiles,
                deadMiles: deadMiles,
                returnMiles: returnMiles,
                gasPricePerGallon: gasPrice,
                vehicleMpg: vehicleMpg,
                effectiveTaxRate: effectiveTaxRate
            )
        )
    }

    // Computed Economics (delegated to MilliCentsAnalyzer)
    private var totalMiles: Double { analyzer.totalMiles }

    private var fuelCost: Double { analyzer.fuelCost }

    private var irsStandardDeduction: Double { analyzer.irsStandardDeduction }

    private var taxablePortion: Double { analyzer.taxablePortion }

    private var taxImpact: Double { analyzer.taxImpact }

    private var netProfit: Double { analyzer.netProfit }

    private var profitPerMile: Double { analyzer.profitPerMile }

    private var recommendation: OfferRecommendation {
        switch analyzer.verdict {
        case .go: return .go
        case .maybe: return .maybe
        case .skip: return .skip
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                header
                modeSegmentedControl

                if mode == .manualCalculator {
                    manualInputCard
                    offerEconomicsCard
                    decisionCard
                } else {
                    platformSyncStatusCard
                    liveOffersList
                }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showInfo) {
            MilliCentsInfoSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlatformConnectSheet) {
            GigPlatformConnectSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header
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
                Text("Offer Analyzer & Profit Engine")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Button {
                showInfo = true
            } label: {
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

    // MARK: - Mode Segmented Control
    private var modeSegmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(MilliCentsMode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        mode = item
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(item.title)
                            .font(MilliFont.labelLarge)
                    }
                    .foregroundStyle(mode == item ? MilliColors.blackGlass : MilliColors.cyanGlow.opacity(0.84))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        Capsule()
                            .fill(mode == item ? MilliColors.cyanGlow : Color.clear)
                            .shadow(color: mode == item ? MilliColors.cyanGlow.opacity(0.25) : .clear, radius: 7)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(MilliColors.cardBackground)
                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 0.7))
        )
    }

    // MARK: - Manual Input Card
    private var manualInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MANUAL OFFER INPUTS")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.75)
                    .foregroundStyle(MilliColors.textSecondary)
                
                Spacer()
                
                // Platform picker menu
                Menu {
                    ForEach(["DoorDash", "Uber Eats", "Lyft", "Spark Driver", "Amazon Flex", "Instacart", "Grubhub"], id: \.self) { plat in
                        Button(plat) { selectedPlatform = plat }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPlatform)
                            .font(.custom("Inter-SemiBold", size: 12))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(MilliColors.cyanGlow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(MilliColors.cardBackground))
                }
            }

            VStack(spacing: 10) {
                sliderInputRow(
                    label: "Offer Payout Amount",
                    valueText: String(format: "$%.2f", offerAmount),
                    slider: Slider(value: $offerAmount, in: 3.0...120.0, step: 0.25)
                )

                sliderInputRow(
                    label: "Estimated Trip Distance",
                    valueText: String(format: "%.1f mi", estimatedMiles),
                    slider: Slider(value: $estimatedMiles, in: 0.5...60.0, step: 0.1)
                )

                sliderInputRow(
                    label: "Dead Miles (to pickup)",
                    valueText: String(format: "%.1f mi", deadMiles),
                    slider: Slider(value: $deadMiles, in: 0.0...25.0, step: 0.1)
                )

                sliderInputRow(
                    label: "Return Miles (to zone)",
                    valueText: String(format: "%.1f mi", returnMiles),
                    slider: Slider(value: $returnMiles, in: 0.0...30.0, step: 0.1)
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.75)
                }
        )
    }

    private func sliderInputRow<S: View>(label: String, valueText: String, slider: S) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(label)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text(valueText)
                    .font(.custom("Sora-SemiBold", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            slider
                .tint(MilliColors.cyanGlow)
        }
    }

    // MARK: - Offer Economics Card (Matching Reference Image 7)
    private var offerEconomicsCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                Text("OFFER AMOUNT")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.85)
                    .foregroundStyle(MilliColors.textSecondary)

                Text(currency(offerAmount))
                    .font(.custom("Sora-SemiBold", size: 32, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.cyanGlow)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider().overlay(MilliColors.cyanGlow.opacity(0.2))

            analysisRow(label: "Estimated Miles", value: String(format: "%.1f mi", estimatedMiles))
            divider
            analysisRow(label: "Dead Miles", value: String(format: "%.1f mi", deadMiles))
            divider
            analysisRow(label: "Return Miles", value: String(format: "%.1f mi", returnMiles))
            divider
            analysisRow(label: "Total Miles", value: String(format: "%.1f mi", totalMiles), emphasized: true)
            divider
            analysisRow(label: "Fuel Cost (est. @ $3.85/gal)", value: currency(fuelCost))
            divider
            analysisRow(label: "IRS Mileage Deduction ($0.67/mi)", value: String(format: "$%.2f", irsStandardDeduction))
            divider
            analysisRow(label: "Tax Impact", value: currency(taxImpact))
        }
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MilliColors.cardBackground, MilliColors.cardBackground],
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
                .foregroundStyle(emphasized ? MilliColors.cyanGlow : MilliColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, emphasized ? 10 : 8)
    }

    // MARK: - Decision Card (Matching Reference Image 7 with GO Pill)
    private var decisionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Decision Pill
                Text(recommendation.title)
                    .font(.custom("Sora-Bold", size: 20))
                    .foregroundStyle(recommendation.titleColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(recommendation.pillBackground)
                            .shadow(color: recommendation.glowColor, radius: 10)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("NET PROFIT")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(MilliColors.textSecondary)

                    Text(currency(netProfit))
                        .font(.custom("Sora-Bold", size: 24))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.positive)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("PER MILE")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(MilliColors.textSecondary)

                    Text(String(format: "$%.2f/mi", profitPerMile))
                        .font(.custom("Sora-SemiBold", size: 16))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                }
            }

            HStack(spacing: 6) {
                calculationPill("\(String(format: "%.1f", totalMiles)) mi total")
                calculationPill("\(currency(fuelCost)) fuel")
                calculationPill("\(currency(taxImpact)) tax")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [recommendation.cardBackground, MilliColors.cardBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(recommendation.borderColor, lineWidth: 1.0)
                }
        )
    }

    private func calculationPill(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter-Medium", size: 11))
            .foregroundStyle(MilliColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.04)))
    }

    // MARK: - Platform Sync Status Card (Live Mode)
    private var platformSyncStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(MilliColors.positive.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MilliColors.positive)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Gig Telemetry Active")
                        .font(.custom("Sora-SemiBold", size: 14))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("DoorDash, Uber & Spark Driver connected and syncing live offers.")
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer()

                Button {
                    showPlatformConnectSheet = true
                } label: {
                    Text("Manage")
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(MilliColors.cardBackground))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.75)
                }
        )
    }

    // MARK: - Live Offers List
    private var liveOffersList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVE INCOMING GIG OFFERS")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 8) {
                ForEach(liveIncomingOffers) { liveOffer in
                    Button {
                        // Populate manual calculator with live offer
                        selectedPlatform = liveOffer.platform
                        offerAmount = liveOffer.amount
                        estimatedMiles = liveOffer.estimatedMiles
                        deadMiles = liveOffer.deadMiles
                        returnMiles = liveOffer.returnMiles
                        mode = .manualCalculator
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: liveOffer.colorHex).opacity(0.18))
                                    .frame(width: 40, height: 40)
                                Text(String(liveOffer.platform.prefix(1)))
                                    .font(.custom("Sora-Bold", size: 16))
                                    .foregroundStyle(Color(hex: liveOffer.colorHex))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(liveOffer.platform)
                                        .font(.custom("Sora-SemiBold", size: 14))
                                        .foregroundStyle(MilliColors.textPrimary)

                                    Text(liveOffer.timeLabel)
                                        .font(.custom("Inter-Regular", size: 10))
                                        .foregroundStyle(MilliColors.textTertiary)
                                }

                                Text("\(String(format: "%.1f", liveOffer.totalMiles)) mi total • \(liveOffer.destinationZone)")
                                    .font(.custom("Inter-Regular", size: 11))
                                    .foregroundStyle(MilliColors.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "$%.2f", liveOffer.amount))
                                    .font(.custom("Sora-Bold", size: 15))
                                    .foregroundStyle(MilliColors.positive)

                                Text(liveOffer.recommendationTag)
                                    .font(.custom("Inter-Bold", size: 9))
                                    .foregroundStyle(liveOffer.recommendationColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(liveOffer.recommendationColor.opacity(0.12)))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MilliColors.graphiteSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 0.8)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}

// MARK: - Enums & Models for MilliCents

public enum MilliCentsMode: String, CaseIterable, Identifiable {
    case manualCalculator
    case livePlatformSync

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .manualCalculator: return "Manual Offer Entry"
        case .livePlatformSync: return "Live Platform Sync"
        }
    }

    public var icon: String {
        switch self {
        case .manualCalculator: return "slider.horizontal.3"
        case .livePlatformSync: return "antenna.radiowaves.left.and.right"
        }
    }
}

public enum OfferRecommendation {
    case go
    case maybe
    case skip

    public var title: String {
        switch self {
        case .go: return "GO"
        case .maybe: return "MAYBE"
        case .skip: return "SKIP"
        }
    }

    public var titleColor: Color {
        switch self {
        case .go: return MilliColors.blackGlass
        case .maybe: return MilliColors.blackGlass
        case .skip: return .white
        }
    }

    public var pillBackground: Color {
        switch self {
        case .go: return MilliColors.cyanGlow
        case .maybe: return MilliColors.warning
        case .skip: return MilliColors.negative
        }
    }

    public var glowColor: Color {
        switch self {
        case .go: return MilliColors.cyanGlow.opacity(0.4)
        case .maybe: return MilliColors.warning.opacity(0.3)
        case .skip: return MilliColors.negative.opacity(0.3)
        }
    }

    public var cardBackground: Color {
        switch self {
        case .go: return MilliColors.cardBackground
        case .maybe: return MilliColors.cardBackground
        case .skip: return MilliColors.cardBackground
        }
    }

    public var borderColor: Color {
        switch self {
        case .go: return MilliColors.cyanGlow.opacity(0.4)
        case .maybe: return MilliColors.warning.opacity(0.4)
        case .skip: return MilliColors.negative.opacity(0.4)
        }
    }
}

public struct LiveGigOffer: Identifiable {
    public let id: String
    public let platform: String
    public let colorHex: String
    public let amount: Double
    public let estimatedMiles: Double
    public let deadMiles: Double
    public let returnMiles: Double
    public let destinationZone: String
    public let timeLabel: String
    public let recommendationTag: String
    public let recommendationColor: Color

    public var totalMiles: Double { estimatedMiles + deadMiles + returnMiles }

    public static let sampleLiveOffers: [LiveGigOffer] = [
        .init(id: "LGO-1", platform: "DoorDash", colorHex: "FF3008", amount: 32.64, estimatedMiles: 24.8, deadMiles: 6.4, returnMiles: 7.2, destinationZone: "Lincoln Park → River North", timeLabel: "Just now", recommendationTag: "GO (HIGH PROFIT)", recommendationColor: MilliColors.cyanGlow),
        .init(id: "LGO-2", platform: "Spark Driver", colorHex: "0071DC", amount: 48.50, estimatedMiles: 18.2, deadMiles: 3.1, returnMiles: 4.5, destinationZone: "Walmart Supercenter Batch", timeLabel: "2m ago", recommendationTag: "GO (OPTIMAL)", recommendationColor: MilliColors.cyanGlow),
        .init(id: "LGO-3", platform: "Uber Eats", colorHex: "000000", amount: 11.25, estimatedMiles: 14.2, deadMiles: 5.0, returnMiles: 8.0, destinationZone: "Suburbs Delivery", timeLabel: "5m ago", recommendationTag: "SKIP (LOW $/MI)", recommendationColor: MilliColors.negative),
        .init(id: "LGO-4", platform: "Amazon Flex", colorHex: "FF9900", amount: 92.00, estimatedMiles: 42.0, deadMiles: 8.5, returnMiles: 10.0, destinationZone: "3-Hour Logistics Block", timeLabel: "8m ago", recommendationTag: "GO (STRONG BLOCK)", recommendationColor: MilliColors.cyanGlow),
        .init(id: "LGO-5", platform: "Instacart", colorHex: "16844A", amount: 24.00, estimatedMiles: 16.5, deadMiles: 4.0, returnMiles: 6.0, destinationZone: "Costco Heavy Batch", timeLabel: "11m ago", recommendationTag: "MAYBE", recommendationColor: MilliColors.warning)
    ]
}

// MARK: - Gig Platform Connect Sheet

private struct GigPlatformConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var platforms = [
        ("DoorDash Driver", "bag.fill", Color(hex: "FF3008"), true),
        ("Uber Driver", "car.fill", Color(hex: "000000"), true),
        ("Walmart Spark Driver", "sparkles", Color(hex: "0071DC"), true),
        ("Amazon Flex", "cube.box.fill", Color(hex: "FF9900"), true),
        ("Instacart Shopper", "cart.fill", Color(hex: "16844A"), true),
        ("Lyft Driver", "steeringwheel", Color(hex: "FF00BF"), false),
        ("Grubhub for Drivers", "fork.knife", Color(hex: "C44724"), false)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("CONNECT DRIVING PLATFORMS")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(MilliColors.textSecondary)

                    VStack(spacing: 8) {
                        ForEach(0..<platforms.count, id: \.self) { idx in
                            HStack(spacing: 12) {
                                Image(systemName: platforms[idx].1)
                                    .font(.system(size: 16))
                                    .foregroundStyle(platforms[idx].2)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.white.opacity(0.04)))

                                Text(platforms[idx].0)
                                    .font(.custom("Inter-Medium", size: 14))
                                    .foregroundStyle(MilliColors.textPrimary)

                                Spacer()

                                Toggle("", isOn: $platforms[idx].3)
                                    .tint(MilliColors.cyanGlow)
                                    .labelsHidden()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(MilliColors.graphiteSurface)
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(MilliColors.background.ignoresSafeArea())
            .navigationTitle("Platform Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }
}

// MARK: - Info Sheet

private struct MilliCentsInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How Milli Cents™ Works")
                        .font(MilliFont.headlineMedium)
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("Unlike traditional round-up apps, Milli Cents is a gig-offer telemetry and profitability engine. It computes real take-home profit by accounting for all miles (trip + deadhead + return), current gas prices, vehicle fuel economy, and standard IRS mileage deductions ($0.67/mi).")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Decision Benchmarks:")
                            .font(.custom("Sora-SemiBold", size: 14))
                            .foregroundStyle(MilliColors.cyanGlow)

                        Text("• GO: Profit >= $18 and >= $0.50/mi after all fuel and tax deductions.")
                        Text("• MAYBE: Marginal profit between $8–$17.")
                        Text("• SKIP: Payout fails to cover deadhead miles, return fuel, and vehicle depreciation.")
                    }
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .padding(12)
                    .background(MilliColors.graphiteSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(16)
            }
            .background(MilliColors.background.ignoresSafeArea())
            .navigationTitle("About Milli Cents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }
}
