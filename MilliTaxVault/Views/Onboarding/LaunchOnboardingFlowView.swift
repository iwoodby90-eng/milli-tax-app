import SwiftUI
import LinkKit

// MARK: - LaunchOnboardingFlowView
// Production six-step setup. The layout is deliberately width-constrained and
// safe-area aware so no onboarding content can drift off-screen on smaller iPhones.

struct LaunchOnboardingFlowView: View {
    @State private var currentStep = 0
    @State private var taxProfile = TaxProfile()
    @State private var bankProfile = BankAutopilotProfile()
    @State private var payoutFrequency: GigPayoutFrequency = .weekly
    @State private var businessType = "Sole Proprietor"
    @State private var incomeBand = "$75,000–$100,000"
    @State private var selectedPlan: MilliPlan = .pro

    @StateObject private var locationManager = LocationManager()
    @StateObject private var plaid = PlaidLinkCoordinator()

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
    private let sidePadding: CGFloat = 20
    private let maxContentWidth: CGFloat = 460

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                onboardingBackground

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, sidePadding)
                        .padding(.top, 8)

                    progressBar
                        .padding(.horizontal, sidePadding)
                        .padding(.top, 10)
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
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                }
                .frame(width: min(proxy.size.width, maxContentWidth))
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.26), value: currentStep)
        .sheet(isPresented: $plaid.isPresentingLink) {
            if let session = plaid.linkSession {
                session.sheet()
            } else {
                ZStack {
                    MilliColors.background.ignoresSafeArea()
                    ProgressView("Preparing secure bank connection…")
                        .tint(MilliColors.cyanGlow)
                        .foregroundStyle(Color.white)
                }
            }
        }
        .alert(
            "Bank connection needs attention",
            isPresented: Binding(
                get: { plaid.errorMessage != nil },
                set: { if !$0 { plaid.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { plaid.errorMessage = nil }
        } message: {
            Text(plaid.errorMessage ?? "Please try again.")
        }
        .onChange(of: plaid.connectedAccount) { _, account in
            guard let account else { return }
            bankProfile.institutionName = account.institutionName ?? "Connected Bank"
            bankProfile.accountName = account.name ?? "Primary Account"
            bankProfile.accountLastFour = account.mask ?? ""
            bankProfile.connectionStatus = .connected
        }
        .onChange(of: plaid.isLoading) { _, loading in
            if loading, bankProfile.connectionStatus != .connected {
                bankProfile.connectionStatus = .connecting
            } else if !loading,
                      !plaid.isConnected,
                      plaid.errorMessage == nil,
                      bankProfile.connectionStatus == .connecting {
                bankProfile.connectionStatus = .notConnected
            }
        }
    }

    // MARK: - Shared layout

    private var header: some View {
        HStack(spacing: 12) {
            MilliWordmark(fontSize: 18, tracking: 4.2)
                .accessibilityLabel("MILLI")

            Spacer(minLength: 8)

            Text("SETUP \(currentStep + 1) OF \(stepCount)")
                .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption2))
                .tracking(1.6)
                .foregroundStyle(Color.white.opacity(0.68))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { step in
                Capsule(style: .continuous)
                    .fill(step <= currentStep ? MilliColors.cyanGlow : Color.white.opacity(0.13))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .shadow(
                        color: step == currentStep ? MilliColors.cyanGlow.opacity(0.36) : .clear,
                        radius: 4
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var onboardingBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "071216").opacity(0.94), MilliColors.background, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.09), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Ellipse()
                    .stroke(MilliColors.cyanGlow.opacity(0.24), lineWidth: 1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 108)
                    .scaleEffect(x: 1.28, y: 1)
                    .offset(y: 60)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }

    private func screenScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                content()
                footerTagline
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, sidePadding)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var footerTagline: some View {
        HStack(spacing: 10) {
            Capsule().fill(MilliColors.cyanGlow.opacity(0.76)).frame(width: 34, height: 1)
            Text("MONEY, MADE INTELLIGENT.")
                .font(.custom("Inter-Medium", size: 8, relativeTo: .caption2))
                .tracking(2.4)
                .foregroundStyle(Color.white.opacity(0.62))
            Capsule().fill(MilliColors.cyanGlow.opacity(0.76)).frame(width: 34, height: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.custom("Sora-SemiBold", size: 12, relativeTo: .subheadline))
            .tracking(2.2)
            .foregroundStyle(MilliColors.cyanGlow)
            .lineLimit(1)
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.custom("Sora-Bold", size: 32, relativeTo: .largeTitle))
            .foregroundStyle(Color.white)
            .lineSpacing(-1)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bodyCopy(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter-Regular", size: 15, relativeTo: .body))
            .foregroundStyle(Color.white.opacity(0.66))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color(hex: "072027").opacity(0.47)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.40), MilliColors.cyanGlow.opacity(0.48)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: MilliColors.cyanGlow.opacity(0.09), radius: 12, y: 5)
    }

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter-SemiBold", size: 11, relativeTo: .caption))
            .tracking(2.5)
            .foregroundStyle(Color.white.opacity(0.68))
    }

    private func primaryButton(_ label: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(label)
                    .font(.custom("Sora-Bold", size: 17, relativeTo: .headline))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .heavy))
            }
            .foregroundStyle(Color(hex: "041014"))
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "16E4F2"), Color(hex: "00CBE4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 0.9)
            }
            .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func next(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.26)) {
            currentStep = min(max(step, 0), stepCount - 1)
        }
    }

    // MARK: - Step 1 — Welcome

    private var welcomeStep: some View {
        screenScroll {
            eyebrow("WELCOME TO MILLI")
            title("Money, made intelligent.")
            bodyCopy("Milli helps gig workers automatically protect taxes, track mileage, and build wealth from every payout — all in one premium financial home.")

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("WHAT MILLI DOES")
                    featureRow(icon: "shield.lefthalf.filled", title: "Protect taxes automatically")
                    featureRow(icon: "location.fill", title: "Track deductible miles")
                    featureRow(icon: "chart.line.uptrend.xyaxis", title: "Build savings, retirement, and investing")
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 11) {
                    cardLabel("READY TO START")
                    Text("Setup only takes a few minutes.")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundStyle(Color.white.opacity(0.65))
                    primaryButton("Begin Setup") { next(1) }
                }
            }
        }
    }

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34)
            Text(title)
                .font(.custom("Inter-Medium", size: 15))
                .foregroundStyle(Color.white.opacity(0.91))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 0.7))
    }

    // MARK: - Step 2 — Tax profile

    private var taxProfileStep: some View {
        screenScroll {
            eyebrow("TAX + PROFILE")
            title("Tell Milli how you file.")
            bodyCopy("Your tax profile helps Milli estimate federal, state, and self-employment taxes accurately from each payout.")

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("FILING STATUS")
                    filingStatusRow(.single, icon: "person.fill")
                    filingStatusRow(.marriedJoint, icon: "person.2.fill")
                    filingStatusRow(.headOfHousehold, icon: "house.fill")
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
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
                    .padding(.top, 2)
                }
            }
        }
    }

    private func filingStatusRow(_ status: TaxProfile.FilingStatus, icon: String) -> some View {
        let selected = taxProfile.filingStatus == status
        return Button {
            taxProfile.filingStatus = status
        } label: {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.82))
                    .frame(width: 26)
                Text(status.rawValue)
                    .font(.custom("Inter-Medium", size: 15))
                    .foregroundStyle(Color.white.opacity(0.91))
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.34))
            }
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 13).fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.022)))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.20), lineWidth: selected ? 1.1 : 0.7))
        }
        .buttonStyle(.plain)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.custom("Inter-Regular", size: 13))
                .foregroundStyle(Color.white.opacity(0.58))
            Spacer(minLength: 8)
            Text(value)
                .font(.custom("Inter-Medium", size: 13))
                .foregroundStyle(Color.white.opacity(0.90))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.62))
        }
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 0.7))
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

    // MARK: - Step 3 — Gig profile

    private var gigProfileStep: some View {
        screenScroll {
            eyebrow("GIG WORK PROFILE")
            title("Who pays you to work?")
            bodyCopy("Choose your active driving or delivery platforms once. Milli uses this profile later for payout matching, mileage insights, and tax estimates.")

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("ACTIVE PLATFORMS")
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)],
                        spacing: 9
                    ) {
                        ForEach(primaryGigPlatforms) { platform in
                            platformTile(platform)
                        }
                    }
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("PAYOUT FREQUENCY")
                    HStack(spacing: 8) {
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
            if selected {
                bankProfile.selectedPlatforms.remove(platform)
            } else {
                bankProfile.selectedPlatforms.insert(platform)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: platformSymbol(platform))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.60))
                    .frame(width: 20)
                Text(platform.rawValue)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(selected ? Color.white : Color.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Spacer(minLength: 2)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.30))
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 13).fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.022)))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.18), lineWidth: selected ? 1.1 : 0.7))
        }
        .buttonStyle(.plain)
    }

    private func platformSymbol(_ platform: GigPlatform) -> String {
        switch platform {
        case .amazonFlex: return "shippingbox.fill"
        case .sparkDriver: return "bolt.fill"
        case .uber: return "car.fill"
        case .doorDash: return "takeoutbag.and.cup.and.straw.fill"
        case .instacart: return "basket.fill"
        case .grubhub: return "fork.knife"
        case .lyft: return "car.side.fill"
        default: return "briefcase.fill"
        }
    }

    private func frequencyPill(_ frequency: GigPayoutFrequency) -> some View {
        let selected = payoutFrequency == frequency
        return Button {
            payoutFrequency = frequency
        } label: {
            VStack(spacing: 5) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.34))
                Text(frequency.rawValue)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(Color.white.opacity(0.88))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 13).fill(selected ? MilliColors.cyanGlow.opacity(0.07) : Color.white.opacity(0.022)))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.18), lineWidth: selected ? 1.1 : 0.7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4 — Bank only

    private var bankStep: some View {
        screenScroll {
            eyebrow("BANK CONNECTION")
            title("Connect your payout account.")
            bodyCopy("Milli uses Plaid to securely connect the bank account where your gig payouts land. Your banking credentials are handled by Plaid and never pass through Milli.")

            bankAccountCard
            connectionAccessCard
            bankPermissionCard

            HStack(spacing: 10) {
                Button("Back") { next(2) }
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(width: 72, height: 56)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.055)))
                    .buttonStyle(.plain)

                Button {
                    next(4)
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.custom("Sora-Bold", size: 16))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(Color(hex: "041014"))
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 15).fill(MilliColors.cyanGlow))
                }
                .buttonStyle(.plain)
                .disabled(!bankProfile.isReadyForAutopilot)
                .opacity(bankProfile.isReadyForAutopilot ? 1 : 0.34)
            }
        }
    }

    private var bankAccountCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    cardLabel("PAYOUT ACCOUNT")
                    Spacer()
                    Text(bankProfile.connectionStatus == .connected ? "CONNECTED" : "REQUIRED")
                        .font(.custom("Inter-SemiBold", size: 10))
                        .foregroundStyle(bankProfile.connectionStatus == .connected ? MilliColors.cyanGlow : Color(hex: "D7AD45"))
                }

                Button {
                    bankProfile.connectionStatus = .connecting
                    plaid.begin()
                } label: {
                    HStack(spacing: 12) {
                        if plaid.isLoading {
                            ProgressView().tint(Color(hex: "041014"))
                        } else {
                            Image(systemName: bankProfile.connectionStatus == .connected ? "checkmark.shield.fill" : "building.columns.fill")
                                .font(.system(size: 20, weight: .bold))
                        }

                        Text(bankProfile.connectionStatus == .connected ? connectedBankTitle : "Connect Bank Securely")
                            .font(.custom("Sora-Bold", size: 16))
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                        Spacer()
                        Image(systemName: bankProfile.connectionStatus == .connected ? "checkmark.circle.fill" : "chevron.right")
                            .font(.system(size: 18, weight: .heavy))
                    }
                    .foregroundStyle(Color(hex: "041014"))
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(RoundedRectangle(cornerRadius: 15).fill(MilliColors.cyanGlow))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.76), lineWidth: 0.9))
                }
                .buttonStyle(.plain)
                .disabled(plaid.isLoading)
            }
        }
    }

    private var connectedBankTitle: String {
        let bank = bankProfile.institutionName.isEmpty ? "Bank" : bankProfile.institutionName
        let mask = bankProfile.accountLastFour.isEmpty ? "" : " ••••\(bankProfile.accountLastFour)"
        return "\(bank)\(mask)"
    }

    private var connectionAccessCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 11) {
                cardLabel("WHAT THE CONNECTION ALLOWS")
                bankCapability("Identify eligible gig payout deposits", icon: "arrow.down.circle.fill")
                bankCapability("Read balances and recent transactions for payout matching", icon: "list.bullet.rectangle.fill")
                bankCapability("Calculate tax protection from matched payouts", icon: "shield.checkered")
                bankCapability("Refresh account data without storing your bank password", icon: "lock.shield.fill")

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Plaid handles bank credentials. Milli receives only the account data you authorize.")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
    }

    private func bankCapability(_ text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 20)
            Text(text)
                .font(.custom("Inter-Medium", size: 13))
                .foregroundStyle(Color.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var bankPermissionCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardLabel("YOUR AUTHORIZATION")

                Toggle("Detect eligible gig payouts in this connected account", isOn: $bankProfile.transactionMonitoringConsent)
                    .font(.custom("Inter-Regular", size: 13))
                    .tint(MilliColors.cyanGlow)

                Toggle("Move calculated tax reserves to Milli Tax Vault™", isOn: $bankProfile.taxVaultTransferConsent)
                    .font(.custom("Inter-Regular", size: 13))
                    .tint(MilliColors.cyanGlow)

                Text("You can change these permissions later in Autopilot settings.")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundStyle(Color.white.opacity(0.52))
            }
            .foregroundStyle(Color.white.opacity(0.82))
        }
    }

    // MARK: - Step 5 — Mileage

    private var mileageStep: some View {
        screenScroll {
            eyebrow("MILEAGE TRACKING")
            title("Track every deductible mile automatically.")
            bodyCopy("Enable location access so Milli can record business trips, route history, and IRS-ready mileage totals while you drive.")

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("LOCATION ACCESS")
                    Text("Allow Always for hands-free trip detection and uninterrupted navigation.")
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                    primaryButton(locationButtonTitle, systemImage: "location.fill") {
                        requestMileageAuthorization()
                    }
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("TRACKING PREVIEW")
                    HStack(spacing: 10) {
                        mileageStat(icon: "road.lanes", label: "TODAY", value: formattedTodayMiles + " mi")
                        mileageStat(icon: "location.circle.fill", label: "STATUS", value: locationManager.canTrackLocation ? "Ready" : "Off")
                    }
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
                .font(.custom("Inter-SemiBold", size: 8))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.56))
            Text(value)
                .font(.custom("Sora-Bold", size: 16))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(MilliColors.cyanGlow.opacity(0.36), lineWidth: 0.8))
    }

    // MARK: - Step 6 — Autopilot

    private var autopilotStep: some View {
        screenScroll {
            eyebrow("MILLI AUTOPILOT")
            title("Turn on automatic tax protection.")
            bodyCopy("Choose how each payout should be divided. Milli can reserve taxes automatically, then optionally route money to savings, retirement, or investing.")

            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel("ALLOCATION SETTINGS")
                    allocationRow(title: "Tax Reserve", icon: "building.columns.fill", enabled: $taxEnabled, percent: $taxPercent)
                    allocationRow(title: "Savings", icon: "piggybank.fill", enabled: $savingsEnabled, percent: $savingsPercent)
                    allocationRow(title: "Retirement", icon: "chart.bar.fill", enabled: $retirementEnabled, percent: $retirementPercent)
                    allocationRow(title: "Investing", icon: "leaf.fill", enabled: $investingEnabled, percent: $investingPercent)
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 8) {
                    cardLabel("AUTOPILOT PREVIEW")
                    receiptRow("Gross Payout", amount: "$187.42", strong: true)
                    receiptRow("Tax Reserve (\(Int(taxPercent))%)", amount: negativeAllocation(187.42, taxEnabled ? taxPercent : 0))
                    receiptRow("Retirement", amount: negativeAllocation(187.42, retirementEnabled ? retirementPercent : 0))
                    receiptRow("Investing", amount: negativeAllocation(187.42, investingEnabled ? investingPercent : 0))
                    receiptRow("Savings", amount: negativeAllocation(187.42, savingsEnabled ? savingsPercent : 0))
                    Divider().overlay(Color.white.opacity(0.24))
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
        percent: Binding<Double>
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.58))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundStyle(Color.white.opacity(0.88))
                Text("\(Int(percent.wrappedValue))%")
                    .font(.custom("Inter-Regular", size: 10))
                    .foregroundStyle(Color.white.opacity(0.48))
            }
            .frame(width: 76, alignment: .leading)

            Slider(value: percent, in: 1...35, step: 1)
                .tint(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.22))
                .disabled(!enabled.wrappedValue)

            Toggle("", isOn: enabled)
                .labelsHidden()
                .scaleEffect(0.78)
                .tint(MilliColors.cyanGlow)
        }
        .padding(.horizontal, 9)
        .frame(height: 50)
        .background(RoundedRectangle(cornerRadius: 12).fill(enabled.wrappedValue ? MilliColors.cyanGlow.opacity(0.05) : Color.white.opacity(0.018)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(enabled.wrappedValue ? MilliColors.cyanGlow.opacity(0.55) : Color.white.opacity(0.15), lineWidth: 0.7))
    }

    private func receiptRow(_ label: String, amount: String, strong: Bool = false, cyan: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.custom(strong ? "Inter-SemiBold" : "Inter-Regular", size: 13))
                .foregroundStyle(Color.white.opacity(strong ? 0.88 : 0.70))
            Spacer()
            Text(amount)
                .font(.custom(strong ? "Sora-Bold" : "Inter-Medium", size: 13))
                .monospacedDigit()
                .foregroundStyle(cyan ? MilliColors.cyanGlow : Color.white.opacity(0.90))
        }
    }

    private func negativeAllocation(_ gross: Double, _ percent: Double) -> String {
        String(format: "-$%.2f", gross * percent / 100)
    }

    private var availableToSpendFormatted: String {
        let totalPercent = (taxEnabled ? taxPercent : 0)
            + (savingsEnabled ? savingsPercent : 0)
            + (retirementEnabled ? retirementPercent : 0)
            + (investingEnabled ? investingPercent : 0)
        return String(format: "$%.2f", max(0, 187.42 * (1 - totalPercent / 100)))
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

private enum GigPayoutFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case mixed = "Mixed"

    var id: String { rawValue }
}
