import SwiftUI
import LinkKit

// MARK: - LaunchOnboardingFlowView
// Six-screen production onboarding reconstructed from the approved MILLI visual
// reference. All controls remain native SwiftUI and the bank step uses live
// Plaid Link through Milli's backend.

struct LaunchOnboardingFlowView: View {
    @State private var currentStep = 0
    @State private var taxProfile = TaxProfile()
    @State private var bankProfile = BankAutopilotProfile()
    @State private var payoutFrequency: GigPayoutFrequency = .weekly
    @State private var businessType = "Sole Proprietor"
    @State private var incomeBand = "$75,000–$100,000"
    @State private var selectedPlan: MilliPlan = .pro

    @StateObject private var locationManager = LocationManager()

    @State private var taxEnabled = true
    @State private var savingsEnabled = false
    @State private var retirementEnabled = false
    @State private var investingEnabled = false
    @State private var taxPercent = 25.0
    @State private var savingsPercent = 3.0
    @State private var retirementPercent = 5.0
    @State private var investingPercent = 2.0

    var onComplete: () -> Void

    private let stepCount = 6
    private let sidePadding: CGFloat = 28

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)

                progressBar
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 11)
                    .padding(.bottom, 8)

                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: taxProfileStep
                    case 2: gigProfileStep
                    case 3: bankStep
                    case 4: mileageStep
                    case 5: autopilotStep
                    default: welcomeStep
                    }
                }
                .id(currentStep)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.28), value: currentStep)
    }

    // MARK: Shared chrome

    private var header: some View {
        HStack(alignment: .center) {
            Image("milli_wordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 46, alignment: .leading)
                .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 10)
                .accessibilityLabel("MILLI")

            Spacer()

            Text("SETUP \(currentStep + 1) OF \(stepCount)")
                .font(.custom("Inter-SemiBold", size: 12, relativeTo: .caption))
                .tracking(2.2)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .frame(height: 50)
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<stepCount, id: \.self) { step in
                Capsule(style: .continuous)
                    .fill(step <= currentStep ? MilliColors.cyanGlow : Color.white.opacity(0.14))
                    .frame(height: 6)
                    .shadow(
                        color: step <= currentStep ? MilliColors.cyanGlow.opacity(0.45) : .clear,
                        radius: 6
                    )
            }
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            Color(hex: "07090B").ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(hex: "071216").opacity(0.96),
                    Color(hex: "07090B"),
                    Color.black.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.10), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 370
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Ellipse()
                    .stroke(MilliColors.cyanGlow.opacity(0.34), lineWidth: 1)
                    .frame(width: 520, height: 130)
                    .blur(radius: 0.4)
                    .offset(y: 72)
            }
            .ignoresSafeArea()
        }
    }

    private func screenScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                content()
                footerTagline
            }
            .padding(.horizontal, sidePadding)
            .padding(.top, 20)
            .padding(.bottom, 26)
        }
    }

    private var footerTagline: some View {
        HStack(spacing: 11) {
            Capsule().fill(MilliColors.cyanGlow.opacity(0.82)).frame(width: 42, height: 1)
            Text("MONEY, MADE INTELLIGENT.")
                .font(.custom("Inter-Medium", size: 8, relativeTo: .caption2))
                .tracking(3.0)
                .foregroundStyle(Color.white.opacity(0.68))
            Capsule().fill(MilliColors.cyanGlow.opacity(0.82)).frame(width: 42, height: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.custom("Sora-SemiBold", size: 14, relativeTo: .subheadline))
            .tracking(2.4)
            .foregroundStyle(MilliColors.cyanGlow)
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.custom("Sora-Bold", size: 37, relativeTo: .largeTitle))
            .foregroundStyle(Color.white)
            .lineSpacing(-2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bodyCopy(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter-Regular", size: 16, relativeTo: .body))
            .foregroundStyle(Color.white.opacity(0.66))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.055), Color(hex: "072027").opacity(0.54)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.72), MilliColors.cyanGlow.opacity(0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: MilliColors.cyanGlow.opacity(0.13), radius: 16, y: 6)
    }

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter-SemiBold", size: 13, relativeTo: .caption))
            .tracking(3.0)
            .foregroundStyle(Color.white.opacity(0.72))
    }

    private func primaryButton(_ label: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .bold))
                }
                Text(label)
                    .font(.custom("Sora-Bold", size: 18, relativeTo: .headline))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .heavy))
            }
            .foregroundStyle(Color(hex: "041014"))
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "16E4F2"), Color(hex: "00CBE4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.white.opacity(0.88), lineWidth: 1)
            )
            .shadow(color: MilliColors.cyanGlow.opacity(0.36), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func next(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.28)) {
            currentStep = min(max(step, 0), stepCount - 1)
        }
    }

    // MARK: Step 1 — Welcome

    private var welcomeStep: some View {
        screenScroll {
            eyebrow("WELCOME TO MILLI")
            title("Money, made\nintelligent.")
            bodyCopy("Milli helps gig workers automatically protect taxes, track mileage, and build wealth from every payout — all in one premium financial home.")

            glassCard {
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel("WHAT MILLI DOES")
                    featureRow(icon: "shield.lefthalf.filled", title: "Protect taxes automatically")
                    featureRow(icon: "location.fill", title: "Track deductible miles")
                    featureRow(icon: "chart.line.uptrend.xyaxis", title: "Build savings, retirement, and investing")
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 13) {
                    cardLabel("READY TO START")
                    Text("Setup only takes a few minutes.")
                        .font(.custom("Inter-Regular", size: 15))
                        .foregroundStyle(Color.white.opacity(0.66))
                    primaryButton("Begin Setup") { next(1) }
                }
            }
        }
    }

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 40)
            Text(title)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundStyle(Color.white.opacity(0.92))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.035))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.22), lineWidth: 0.7))
        )
    }

    // MARK: Step 2 — Tax + Profile

    private var taxProfileStep: some View {
        screenScroll {
            eyebrow("TAX + PROFILE")
            title("Tell Milli how you file.")
            bodyCopy("Your tax profile helps Milli estimate federal, state, and self-employment taxes accurately from each payout.")

            glassCard {
                VStack(alignment: .leading, spacing: 11) {
                    cardLabel("FILING STATUS")
                    filingStatusRow(.single, icon: "person.fill")
                    filingStatusRow(.marriedJoint, icon: "person.2.fill")
                    filingStatusRow(.headOfHousehold, icon: "house.fill")
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 11) {
                    cardLabel("PROFILE DETAILS")

                    Menu {
                        ForEach(["Michigan", "California", "Florida", "New York", "Texas", "Other"], id: \.self) { state in
                            Button(state) { taxProfile.state = state }
                        }
                    } label: {
                        detailRow(label: "State of Residence", value: taxProfile.state.isEmpty ? "Select" : taxProfile.state)
                    }

                    Menu {
                        ForEach(["Sole Proprietor", "Single-Member LLC", "S-Corp", "Partnership"], id: \.self) { value in
                            Button(value) { businessType = value }
                        }
                    } label: {
                        detailRow(label: "Business Type", value: businessType)
                    }

                    Menu {
                        ForEach(["Under $30,000", "$30,000–$50,000", "$50,000–$75,000", "$75,000–$100,000", "$100,000+"], id: \.self) { band in
                            Button(band) {
                                incomeBand = band
                                taxProfile.estimatedAnnualIncome = incomeAmount(for: band)
                            }
                        }
                    } label: {
                        detailRow(label: "Expected 2026 Net Income", value: incomeBand)
                    }

                    primaryButton("Save Tax Profile", systemImage: "doc.text") {
                        if taxProfile.state.isEmpty { taxProfile.state = "Michigan" }
                        if taxProfile.estimatedAnnualIncome.isEmpty { taxProfile.estimatedAnnualIncome = "87500" }
                        next(2)
                    }
                    .padding(.top, 3)
                }
            }
        }
    }

    private func filingStatusRow(_ status: TaxProfile.FilingStatus, icon: String) -> some View {
        let selected = taxProfile.filingStatus == status
        return Button {
            taxProfile.filingStatus = status
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.88))
                    .frame(width: 28)
                Text(status.rawValue)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundStyle(Color.white.opacity(0.92))
                Spacer()
                Circle()
                    .fill(selected ? MilliColors.cyanGlow : .clear)
                    .frame(width: 19, height: 19)
                    .overlay(Circle().stroke(selected ? Color.black : Color.white.opacity(0.42), lineWidth: 1.5))
                    .shadow(color: selected ? MilliColors.cyanGlow.opacity(0.65) : .clear, radius: 7)
            }
            .padding(.horizontal, 15)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.025))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.26), lineWidth: selected ? 1.2 : 0.7)
            )
        }
        .buttonStyle(.plain)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundStyle(Color.white.opacity(0.60))
            Spacer()
            Text(value)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundStyle(Color.white.opacity(0.92))
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.028)))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.22), lineWidth: 0.7))
    }

    private func incomeAmount(for band: String) -> String {
        switch band {
        case "Under $30,000": return "25000"
        case "$30,000–$50,000": return "40000"
        case "$50,000–$75,000": return "62500"
        case "$75,000–$100,000": return "87500"
        default: return "125000"
        }
    }

    // MARK: Step 3 — Gig profile

    private var gigProfileStep: some View {
        screenScroll {
            eyebrow("GIG WORK PROFILE")
            title("Who pays you to work?")
            bodyCopy("Choose the platforms you drive or deliver for so Milli can tailor payout matching, mileage insights, and tax estimates.")

            glassCard {
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel("ACTIVE PLATFORMS")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(primaryGigPlatforms) { platform in
                            platformTile(platform)
                        }
                    }
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel("PAYOUT FREQUENCY")
                    HStack(spacing: 10) {
                        ForEach(GigPayoutFrequency.allCases) { frequency in
                            frequencyPill(frequency)
                        }
                    }
                }
            }

            primaryButton("Continue") { next(3) }
        }
    }

    private var primaryGigPlatforms: [GigPlatform] {
        [.amazonFlex, .sparkDriver, .uber, .doorDash, .instacart, .grubhub, .lyft]
    }

    private func platformTile(_ platform: GigPlatform) -> some View {
        let selected = bankProfile.selectedPlatforms.contains(platform)
        return Button {
            if selected { bankProfile.selectedPlatforms.remove(platform) }
            else { bankProfile.selectedPlatforms.insert(platform) }
        } label: {
            HStack(spacing: 9) {
                platformIcon(platform)
                Text(platform.rawValue)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundStyle(Color.white.opacity(0.90))
                    .lineLimit(1)
                Spacer(minLength: 2)
                Circle()
                    .fill(selected ? MilliColors.cyanGlow : .clear)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.35), lineWidth: 1))
                    .overlay {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(Color(hex: "041014"))
                        }
                    }
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.025)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.23), lineWidth: selected ? 1.2 : 0.7))
            .shadow(color: selected ? MilliColors.cyanGlow.opacity(0.18) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func platformIcon(_ platform: GigPlatform) -> some View {
        switch platform {
        case .amazonFlex:
            Image("amazon-flex-icon").resizable().scaledToFit().frame(width: 28, height: 28)
        case .sparkDriver:
            Image("spark-driver-icon").resizable().scaledToFit().frame(width: 28, height: 28)
        case .uber:
            Image("uber-icon").resizable().scaledToFit().frame(width: 28, height: 28)
        case .doorDash:
            Image("doordash-icon").resizable().scaledToFit().frame(width: 28, height: 28)
        case .instacart:
            Image("instacart-icon").resizable().scaledToFit().frame(width: 28, height: 28)
        case .lyft:
            Text("lyft").font(.system(size: 13, weight: .black)).foregroundStyle(Color(hex: "FF00BF")).frame(width: 28)
        case .grubhub:
            Image(systemName: "fork.knife").foregroundStyle(Color(hex: "FF6B00")).frame(width: 28)
        default:
            Image(systemName: "briefcase.fill").foregroundStyle(MilliColors.cyanGlow).frame(width: 28)
        }
    }

    private func frequencyPill(_ frequency: GigPayoutFrequency) -> some View {
        let selected = payoutFrequency == frequency
        return Button {
            payoutFrequency = frequency
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(selected ? MilliColors.cyanGlow : .clear)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.42), lineWidth: 1.2))
                Text(frequency.rawValue)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundStyle(Color.white.opacity(0.90))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.025)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.23), lineWidth: selected ? 1.2 : 0.7))
        }
        .buttonStyle(.plain)
    }

    // MARK: Step 4 — live Plaid bank link

    private var bankStep: some View {
        PlaidReferenceBankStep(
            profile: $bankProfile,
            sidePadding: sidePadding,
            onBack: { next(2) },
            onNext: { next(4) }
        )
    }

    // MARK: Step 5 — mileage

    private var mileageStep: some View {
        screenScroll {
            eyebrow("MILEAGE TRACKING")
            title("Track every deductible\nmile automatically.")
            bodyCopy("Enable always-on mileage tracking so Milli records business trips, route history, and IRS-ready totals in the background.")

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("LOCATION ACCESS")
                    Text("Allow Always for hands-free trip detection.")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundStyle(Color.white.opacity(0.64))
                    primaryButton(locationButtonTitle, systemImage: "location.fill") {
                        requestMileageAuthorization()
                    }
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        cardLabel("TODAY’S TRIP PREVIEW")
                        Spacer()
                        Text("SEE DETAILS")
                            .font(.custom("Inter-SemiBold", size: 10))
                            .tracking(1.2)
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    RoutePreviewCard()
                        .frame(height: 142)

                    HStack(spacing: 8) {
                        mileageStat(icon: "road.lanes", label: "BUSINESS MILES", value: formattedTodayMiles)
                        mileageStat(icon: "car.fill", label: "TRIPS", value: "—")
                        mileageStat(icon: "clock.fill", label: "DRIVE TIME", value: "—")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "car.circle.fill")
                            .font(.system(size: 33))
                            .foregroundStyle(Color.white.opacity(0.90))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRIMARY VEHICLE")
                                .font(.custom("Inter-SemiBold", size: 9))
                                .tracking(2.0)
                                .foregroundStyle(Color.white.opacity(0.60))
                            Text("Add primary vehicle")
                                .font(.custom("Inter-Medium", size: 15))
                                .foregroundStyle(Color.white.opacity(0.90))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.white.opacity(0.65))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 58)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.025)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.22), lineWidth: 0.7))
                }
            }

            primaryButton("Continue") { next(5) }
        }
    }

    private var locationButtonTitle: String {
        locationManager.hasAlwaysAuthorization ? "Always-On Tracking Enabled" : "Enable Always-On Tracking"
    }

    private var formattedTodayMiles: String {
        String(format: "%.1f", locationManager.todayDistanceMiles)
    }

    private func requestMileageAuthorization() {
        if locationManager.hasAlwaysAuthorization { return }
        if locationManager.canTrackLocation {
            locationManager.requestBackgroundPermission()
        } else {
            locationManager.requestPermission()
        }
    }

    private func mileageStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
            Text(label)
                .font(.custom("Inter-SemiBold", size: 7))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.58))
                .lineLimit(1)
            Text(value)
                .font(.custom("Sora-Bold", size: 18))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(MilliColors.cyanGlow.opacity(0.48), lineWidth: 0.8))
    }

    // MARK: Step 6 — Autopilot

    private var autopilotStep: some View {
        screenScroll {
            eyebrow("MILLI AUTOPILOT")
            title("Turn on automatic\ntax protection.")
            bodyCopy("Choose how each payout should be divided. Milli can reserve taxes automatically, then optionally route money to savings, retirement, or investing.")

            glassCard {
                VStack(alignment: .leading, spacing: 11) {
                    cardLabel("ALLOCATION SETTINGS")
                    allocationRow(title: "Tax Reserve", icon: "building.columns.fill", enabled: $taxEnabled, percent: $taxPercent, accent: MilliColors.cyanGlow)
                    allocationRow(title: "Savings", icon: "piggybank.fill", enabled: $savingsEnabled, percent: $savingsPercent, accent: Color.white.opacity(0.72))
                    allocationRow(title: "Retirement", icon: "chart.bar.fill", enabled: $retirementEnabled, percent: $retirementPercent, accent: Color.white.opacity(0.72))
                    allocationRow(title: "Investing", icon: "leaf.fill", enabled: $investingEnabled, percent: $investingPercent, accent: Color.white.opacity(0.72))
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 8) {
                    cardLabel("AUTOPILOT PREVIEW")
                    receiptRow("Gross Payout", amount: "$187.42", strong: true)
                    receiptRow("Tax Reserve (\(Int(taxPercent))%)", amount: negativeAllocation(187.42, taxEnabled ? taxPercent : 0))
                    receiptRow("Retirement (\(Int(retirementPercent))%)", amount: negativeAllocation(187.42, retirementEnabled ? retirementPercent : 0))
                    receiptRow("Investing (\(Int(investingPercent))%)", amount: negativeAllocation(187.42, investingEnabled ? investingPercent : 0))
                    receiptRow("Savings (\(Int(savingsPercent))%)", amount: negativeAllocation(187.42, savingsEnabled ? savingsPercent : 0))
                    Divider().overlay(Color.white.opacity(0.30))
                    receiptRow("Available to Spend", amount: availableToSpendFormatted, strong: true, cyan: true)
                }
            }

            primaryButton("Start 3-Day Trial", systemImage: "paperplane.fill") {
                saveAndComplete()
            }
        }
    }

    private func allocationRow(
        title: String,
        icon: String,
        enabled: Binding<Bool>,
        percent: Binding<Double>,
        accent: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.78))
                .frame(width: 28)

            Text(title)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundStyle(Color.white.opacity(0.92))
                .frame(width: 88, alignment: .leading)

            Slider(value: percent, in: 1...35, step: 1)
                .tint(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.26))
                .disabled(!enabled.wrappedValue)

            Text("\(Int(percent.wrappedValue))%")
                .font(.custom("Sora-SemiBold", size: 14))
                .monospacedDigit()
                .foregroundStyle(Color.white.opacity(0.92))
                .frame(width: 36, alignment: .trailing)

            Toggle("", isOn: enabled)
                .labelsHidden()
                .scaleEffect(0.80)
                .tint(accent)
        }
        .padding(.horizontal, 10)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 13).fill(enabled.wrappedValue ? MilliColors.cyanGlow.opacity(0.055) : Color.white.opacity(0.02)))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(enabled.wrappedValue ? MilliColors.cyanGlow.opacity(0.82) : Color.white.opacity(0.18), lineWidth: 0.8))
    }

    private func receiptRow(_ label: String, amount: String, strong: Bool = false, cyan: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.custom(strong ? "Inter-SemiBold" : "Inter-Regular", size: 14))
                .foregroundStyle(Color.white.opacity(strong ? 0.88 : 0.74))
            Spacer()
            Text(amount)
                .font(.custom(strong ? "Sora-Bold" : "Inter-Medium", size: 14))
                .monospacedDigit()
                .foregroundStyle(cyan ? MilliColors.cyanGlow : Color.white.opacity(0.92))
        }
    }

    private func negativeAllocation(_ gross: Double, _ percent: Double) -> String {
        let amount = gross * percent / 100
        return String(format: "-$%.2f", amount)
    }

    private var availableToSpendFormatted: String {
        let totalPercent = (taxEnabled ? taxPercent : 0)
            + (savingsEnabled ? savingsPercent : 0)
            + (retirementEnabled ? retirementPercent : 0)
            + (investingEnabled ? investingPercent : 0)
        let available = max(0, 187.42 * (1 - totalPercent / 100))
        return String(format: "$%.2f", available)
    }

    private func saveAndComplete() {
        guard bankProfile.connectionStatus == .connected else { return }

        if let taxData = try? JSONEncoder().encode(taxProfile) {
            UserDefaults.standard.set(taxData, forKey: "onboarding_taxProfile")
        }
        if let bankData = try? JSONEncoder().encode(bankProfile) {
            UserDefaults.standard.set(bankData, forKey: "onboarding_bankAutopilotProfile")
        }

        UserDefaults.standard.set(payoutFrequency.rawValue, forKey: "onboarding_payoutFrequency")
        UserDefaults.standard.set(businessType, forKey: "onboarding_businessType")
        UserDefaults.standard.set(selectedPlan.rawValue, forKey: "onboarding_plan")
        UserDefaults.standard.set(taxEnabled, forKey: "milliAutopilotTaxEnabled")
        UserDefaults.standard.set(taxPercent, forKey: "milliAutopilotTaxPercent")
        UserDefaults.standard.set(savingsEnabled, forKey: "milliAutopilotSavingsEnabled")
        UserDefaults.standard.set(savingsPercent, forKey: "milliAutopilotSavingsPercent")
        UserDefaults.standard.set(retirementEnabled, forKey: "milliAutopilotRetirementEnabled")
        UserDefaults.standard.set(retirementPercent, forKey: "milliAutopilotRetirementPercent")
        UserDefaults.standard.set(investingEnabled, forKey: "milliAutopilotInvestingEnabled")
        UserDefaults.standard.set(investingPercent, forKey: "milliAutopilotInvestingPercent")

        MilliTrialState.activateIfNeeded(plan: selectedPlan)
        onComplete()
    }
}

// MARK: - Plaid reference screen

private struct PlaidReferenceBankStep: View {
    @Binding var profile: BankAutopilotProfile
    let sidePadding: CGFloat
    let onBack: () -> Void
    let onNext: () -> Void

    @StateObject private var plaid = PlaidLinkCoordinator()

    private let platforms: [GigPlatform] = [.amazonFlex, .sparkDriver, .uber, .doorDash, .instacart, .lyft]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("BANK + PAYOUT DETECTION")
                    .font(.custom("Sora-SemiBold", size: 14))
                    .tracking(2.4)
                    .foregroundStyle(MilliColors.cyanGlow)

                Text("Connect where your\ngig payouts land.")
                    .font(.custom("Sora-Bold", size: 37, relativeTo: .largeTitle))
                    .foregroundStyle(Color.white)
                    .lineSpacing(-2)

                Text("Milli uses Plaid to securely connect the account where your gig deposits land. Your banking credentials are handled by Plaid and never pass through Milli.")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundStyle(Color.white.opacity(0.66))
                    .lineSpacing(4)

                bankCard
                sourcesCard
                permissionsCard

                HStack(spacing: 12) {
                    Button("Back", action: onBack)
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .frame(width: 72, height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))

                    Button(action: onNext) {
                        HStack {
                            Text("Continue")
                                .font(.custom("Sora-Bold", size: 17))
                            Spacer()
                            Image(systemName: "chevron.right").fontWeight(.bold)
                        }
                        .foregroundStyle(Color(hex: "041014"))
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(MilliColors.cyanGlow))
                    }
                    .buttonStyle(.plain)
                    .disabled(!profile.isReadyForAutopilot)
                    .opacity(profile.isReadyForAutopilot ? 1 : 0.38)
                }

                HStack(spacing: 11) {
                    Capsule().fill(MilliColors.cyanGlow.opacity(0.82)).frame(width: 42, height: 1)
                    Text("MONEY, MADE INTELLIGENT.")
                        .font(.custom("Inter-Medium", size: 8))
                        .tracking(3)
                        .foregroundStyle(Color.white.opacity(0.68))
                    Capsule().fill(MilliColors.cyanGlow.opacity(0.82)).frame(width: 42, height: 1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, sidePadding)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $plaid.isPresentingLink) {
            if let session = plaid.linkSession {
                session.sheet()
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView("Preparing secure bank connection…")
                        .tint(MilliColors.cyanGlow)
                        .foregroundStyle(Color.white)
                }
            }
        }
        .alert("Bank connection needs attention", isPresented: Binding(
            get: { plaid.errorMessage != nil },
            set: { if !$0 { plaid.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { plaid.errorMessage = nil }
        } message: {
            Text(plaid.errorMessage ?? "Please try again.")
        }
        .onChange(of: plaid.connectedAccount) { _, account in
            guard let account else { return }
            profile.institutionName = account.institutionName ?? "Connected Bank"
            profile.accountName = account.name ?? "Primary Account"
            profile.accountLastFour = account.mask ?? ""
            profile.connectionStatus = .connected
        }
        .onChange(of: plaid.isLoading) { _, loading in
            if loading, profile.connectionStatus != .connected {
                profile.connectionStatus = .connecting
            } else if !loading, !plaid.isConnected, plaid.errorMessage == nil, profile.connectionStatus == .connecting {
                profile.connectionStatus = .notConnected
            }
        }
    }

    private var bankCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PAYOUT ACCOUNT")
                    .font(.custom("Inter-SemiBold", size: 13))
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.72))
                Spacer()
                Text(profile.connectionStatus == .connected ? "CONNECTED" : "REQUIRED")
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(profile.connectionStatus == .connected ? MilliColors.cyanGlow : Color(hex: "D7AD45"))
            }

            Button {
                profile.connectionStatus = .connecting
                plaid.begin()
            } label: {
                HStack(spacing: 13) {
                    if plaid.isLoading {
                        ProgressView().tint(Color(hex: "041014"))
                    } else {
                        Image(systemName: profile.connectionStatus == .connected ? "checkmark.shield.fill" : "building.columns.fill")
                            .font(.system(size: 22, weight: .bold))
                    }

                    Text(profile.connectionStatus == .connected ? connectedTitle : "Connect Bank Securely")
                        .font(.custom("Sora-Bold", size: 17))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: profile.connectionStatus == .connected ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 20, weight: .heavy))
                }
                .foregroundStyle(Color(hex: "041014"))
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(RoundedRectangle(cornerRadius: 17).fill(MilliColors.cyanGlow))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.white.opacity(0.88), lineWidth: 1))
                .shadow(color: MilliColors.cyanGlow.opacity(0.36), radius: 14, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(plaid.isLoading)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "08181D").opacity(0.86)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.48), lineWidth: 1))
    }

    private var connectedTitle: String {
        let bank = profile.institutionName.isEmpty ? "Bank" : profile.institutionName
        let mask = profile.accountLastFour.isEmpty ? "" : " ••••\(profile.accountLastFour)"
        return "\(bank)\(mask)"
    }

    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GIG PAYOUT SOURCES")
                    .font(.custom("Inter-SemiBold", size: 13))
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.72))
                Spacer()
                Toggle("", isOn: $profile.autoDetectPlatforms)
                    .labelsHidden()
                    .tint(MilliColors.cyanGlow)
            }

            Text("Confirm the companies you drive or deliver for. Auto-detect uses this as a high-confidence filter when matching bank deposits.")
                .font(.custom("Inter-Regular", size: 14))
                .foregroundStyle(Color.white.opacity(0.62))
                .lineSpacing(3)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(platforms) { platform in
                    let selected = profile.selectedPlatforms.contains(platform)
                    Button {
                        if selected { profile.selectedPlatforms.remove(platform) }
                        else { profile.selectedPlatforms.insert(platform) }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(selected ? MilliColors.cyanGlow : Color.white.opacity(0.08))
                                .frame(width: 9, height: 9)
                            Text(platform.rawValue)
                                .font(.custom("Inter-Medium", size: 13))
                                .foregroundStyle(selected ? Color.white : Color.white.opacity(0.62))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 11)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 13).fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.025)))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.18), lineWidth: selected ? 1.1 : 0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "08181D").opacity(0.86)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(MilliColors.cyanGlow.opacity(0.40), lineWidth: 1))
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOPILOT PERMISSIONS")
                .font(.custom("Inter-SemiBold", size: 11))
                .tracking(2.3)
                .foregroundStyle(Color.white.opacity(0.65))

            Toggle("Detect eligible gig payouts in the connected account", isOn: $profile.transactionMonitoringConsent)
                .font(.custom("Inter-Regular", size: 13))
                .tint(MilliColors.cyanGlow)

            Toggle("Move calculated tax reserves to Milli Tax Vault™", isOn: $profile.taxVaultTransferConsent)
                .font(.custom("Inter-Regular", size: 13))
                .tint(MilliColors.cyanGlow)
        }
        .foregroundStyle(Color.white.opacity(0.80))
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.035)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.18), lineWidth: 0.7))
    }
}

private enum GigPayoutFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case mixed = "Mixed"
    var id: String { rawValue }
}

private struct RoutePreviewCard: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "08151B"))

                ForEach(0..<8, id: \.self) { index in
                    Path { path in
                        let y = geometry.size.height * CGFloat(index + 1) / 9
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y - CGFloat(index % 3) * 7))
                    }
                    .stroke(Color.white.opacity(0.055), lineWidth: 1)
                }

                Path { path in
                    path.move(to: CGPoint(x: 22, y: geometry.size.height * 0.78))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width * 0.46, y: geometry.size.height * 0.56),
                        control1: CGPoint(x: geometry.size.width * 0.18, y: geometry.size.height * 0.72),
                        control2: CGPoint(x: geometry.size.width * 0.31, y: geometry.size.height * 0.84)
                    )
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width - 30, y: geometry.size.height * 0.26),
                        control1: CGPoint(x: geometry.size.width * 0.62, y: geometry.size.height * 0.28),
                        control2: CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height * 0.58)
                    )
                }
                .stroke(MilliColors.cyanGlow, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .shadow(color: MilliColors.cyanGlow.opacity(0.70), radius: 7)

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(MilliColors.cyanGlow, lineWidth: 4))
                    .position(x: 22, y: geometry.size.height * 0.78)

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(MilliColors.cyanGlow, lineWidth: 4))
                    .position(x: geometry.size.width - 30, y: geometry.size.height * 0.26)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MilliColors.cyanGlow.opacity(0.45), lineWidth: 0.8))
    }
}
