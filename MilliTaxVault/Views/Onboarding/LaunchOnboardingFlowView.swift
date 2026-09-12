import SwiftUI
import LinkKit

// MARK: - LaunchOnboardingFlowView
// Six-step production setup. This surface intentionally uses the same visual
// language as Milli's approved high-fidelity onboarding: full-width composition,
// chrome/cyan instrumentation, layered glass, strong hierarchy, and no miniature
// width-constrained presentation on iPhone.

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
    private let sidePadding: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                onboardingBackground

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, sidePadding)
                        .padding(.top, 6)

                    progressBar
                        .padding(.horizontal, sidePadding)
                        .padding(.top, 8)
                        .padding(.bottom, 2)

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
                .frame(width: proxy.size.width)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
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

    // MARK: - Shared shell

    private var header: some View {
        HStack(spacing: 12) {
            MilliWordmark(fontSize: 22, tracking: 4.8)
                .accessibilityLabel("MILLI")

            Spacer(minLength: 10)

            HStack(spacing: 6) {
                Circle()
                    .fill(MilliColors.cyanGlow)
                    .frame(width: 5, height: 5)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.7), radius: 4)

                Text("STEP \(currentStep + 1) / \(stepCount)")
                    .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.045))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { step in
                Capsule(style: .continuous)
                    .fill(
                        step <= currentStep
                        ? LinearGradient(
                            colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.10), Color.white.opacity(0.06)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: step == currentStep ? 5 : 4)
                    .shadow(
                        color: step == currentStep ? MilliColors.cyanGlow.opacity(0.45) : .clear,
                        radius: 5
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var onboardingBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "071116"), Color(hex: "05090C"), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.12), .clear],
                center: UnitPoint(x: 0.08, y: 0.08),
                startRadius: 0,
                endRadius: 330
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.035), .clear],
                center: UnitPoint(x: 0.88, y: 0.44),
                startRadius: 0,
                endRadius: 260
            )
            .ignoresSafeArea()
        }
    }

    private func stageScroll<Content: View>(
        icon: String,
        eyebrow: String,
        title: String,
        body: String,
        usesM: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                stageHero(icon: icon, eyebrow: eyebrow, title: title, body: body, usesM: usesM)
                content()
                footerTagline
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, sidePadding)
            .padding(.top, 16)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func stageHero(
        icon: String,
        eyebrow: String,
        title: String,
        body: String,
        usesM: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.72))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            MilliColors.chromeDark,
                                            MilliColors.chromeWhite,
                                            MilliColors.chromeMid,
                                            MilliColors.chromeWhite,
                                            MilliColors.chromeDark
                                        ],
                                        center: .center
                                    ),
                                    lineWidth: 3.5
                                )
                        }
                        .shadow(color: .black.opacity(0.55), radius: 12, y: 6)

                    Circle()
                        .stroke(MilliColors.cyanGlow.opacity(0.65), lineWidth: 1.5)
                        .frame(width: 60, height: 60)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.32), radius: 6)

                    if usesM {
                        MilliMMark()
                            .frame(width: 38, height: 38)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "A9FBFF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(eyebrow)
                        .font(.custom("Sora-SemiBold", size: 11, relativeTo: .subheadline))
                        .tracking(2.0)
                        .foregroundStyle(MilliColors.cyanGlow)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(MilliColors.positive)
                            .frame(width: 5, height: 5)
                        Text("SECURE SETUP")
                            .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                            .tracking(1.2)
                            .foregroundStyle(Color.white.opacity(0.46))
                    }
                }
            }

            Text(title)
                .font(.custom("Sora-Bold", size: 35, relativeTo: .largeTitle))
                .foregroundStyle(Color.white)
                .lineSpacing(-1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(body)
                .font(.custom("Inter-Regular", size: 15.5, relativeTo: .body))
                .foregroundStyle(Color.white.opacity(0.66))
                .lineSpacing(3.2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footerTagline: some View {
        HStack(spacing: 10) {
            Capsule().fill(MilliColors.cyanGlow.opacity(0.65)).frame(maxWidth: 42).frame(height: 1)
            Text("MONEY, MADE INTELLIGENT.")
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(2.3)
                .foregroundStyle(Color.white.opacity(0.50))
            Capsule().fill(MilliColors.cyanGlow.opacity(0.65)).frame(maxWidth: 42).frame(height: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.065), Color(hex: "081A20").opacity(0.74), Color.black.opacity(0.34)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.34), MilliColors.cyanGlow.opacity(0.26), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    }
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 88, height: 1)
                            .padding(.top, 1)
                    }
                    .shadow(color: .black.opacity(0.50), radius: 18, y: 9)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.055), radius: 15, y: 4)
            )
    }

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter-SemiBold", size: 10.5, relativeTo: .caption))
            .tracking(2.1)
            .foregroundStyle(Color.white.opacity(0.61))
    }

    private func primaryButton(
        _ label: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }
                Text(label)
                    .font(.custom("Sora-Bold", size: 16, relativeTo: .headline))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy))
            }
            .foregroundStyle(Color(hex: "031013"))
            .padding(.horizontal, 19)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "7AF6FF"), Color(hex: "00E5FF"), Color(hex: "00B4C2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.70), lineWidth: 0.85)
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 14, y: 5)
            )
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
        stageScroll(
            icon: "sparkles",
            eyebrow: "WELCOME TO MILLI",
            title: "Your financial autopilot starts here.",
            body: "Set up taxes, mileage, banking, and automatic allocations once. Milli turns each gig payout into an organized financial workflow.",
            usesM: true
        ) {
            glassCard {
                VStack(alignment: .leading, spacing: 11) {
                    cardLabel("WHAT MILLI WILL HANDLE")
                    featureRow(icon: "shield.lefthalf.filled", title: "Protect taxes automatically", detail: "Reserve from eligible payouts before money gets spent.")
                    featureRow(icon: "location.fill", title: "Track deductible miles", detail: "Build IRS-ready mileage records while you work.")
                    featureRow(icon: "chart.line.uptrend.xyaxis", title: "Build wealth intentionally", detail: "Route money toward savings, retirement, and investing.")
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        cardLabel("READY TO BEGIN")
                        Spacer()
                        Text("~3 MIN")
                            .font(.custom("Inter-SemiBold", size: 9))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    Text("Six focused steps. Every choice can be changed later in Settings.")
                        .font(.custom("Inter-Regular", size: 13.5))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                    primaryButton("Begin Setup", systemImage: "arrowtriangle.right.fill") { next(1) }
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.20), lineWidth: 0.7)
                    }
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 14.5))
                    .foregroundStyle(Color.white.opacity(0.93))
                Text(detail)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundStyle(Color.white.opacity(0.52))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 0.7))
    }

    // MARK: - Step 2 — Tax profile

    private var taxProfileStep: some View {
        stageScroll(
            icon: "building.columns.fill",
            eyebrow: "TAX + PROFILE",
            title: "Tell Milli how you file.",
            body: "Your filing profile calibrates federal, state, and self-employment tax estimates for every protected payout."
        ) {
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

                    primaryButton("Save Tax Profile", systemImage: "checkmark.shield.fill") {
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
                ZStack {
                    Circle()
                        .fill(selected ? MilliColors.cyanGlow.opacity(0.10) : Color.white.opacity(0.035))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.74))
                }
                Text(status.rawValue)
                    .font(.custom("Inter-Medium", size: 14.5))
                    .foregroundStyle(Color.white.opacity(0.91))
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.27))
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? MilliColors.cyanGlow.opacity(0.055) : Color.white.opacity(0.018)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? MilliColors.cyanGlow.opacity(0.70) : Color.white.opacity(0.12), lineWidth: selected ? 1.0 : 0.7))
        }
        .buttonStyle(.plain)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.custom("Inter-SemiBold", size: 8.5))
                    .tracking(0.7)
                    .foregroundStyle(Color.white.opacity(0.42))
                Text(value)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundStyle(Color.white.opacity(0.91))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow.opacity(0.78))
        }
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.12), lineWidth: 0.7))
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
        stageScroll(
            icon: "car.side.fill",
            eyebrow: "GIG WORK PROFILE",
            title: "Who pays you to work?",
            body: "Choose the platforms you use. Milli uses this profile to recognize deposits, interpret mileage, and organize payout activity."
        ) {
            glassCard {
                VStack(alignment: .leading, spacing: 11) {
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

            primaryButton("Continue", systemImage: "checkmark.circle.fill") { next(3) }
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: platformSymbol(platform))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.56))
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.25))
                }
                Text(platform.rawValue)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(selected ? Color.white : Color.white.opacity(0.66))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? MilliColors.cyanGlow.opacity(0.055) : Color.white.opacity(0.02)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? MilliColors.cyanGlow.opacity(0.70) : Color.white.opacity(0.11), lineWidth: selected ? 1.0 : 0.7))
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
            VStack(spacing: 6) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? MilliColors.cyanGlow : Color.white.opacity(0.28))
                Text(frequency.rawValue)
                    .font(.custom("Inter-SemiBold", size: 11.5))
                    .foregroundStyle(Color.white.opacity(0.88))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? MilliColors.cyanGlow.opacity(0.055) : Color.white.opacity(0.02)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? MilliColors.cyanGlow.opacity(0.70) : Color.white.opacity(0.11), lineWidth: selected ? 1.0 : 0.7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4 — Bank

    private var bankStep: some View {
        stageScroll(
            icon: "building.columns.fill",
            eyebrow: "BANK CONNECTION",
            title: "Connect your payout account.",
            body: "Plaid securely connects the account where your gig income lands. Milli never receives or stores your bank password."
        ) {
            bankAccountCard
            connectionAccessCard
            bankPermissionCard

            HStack(spacing: 10) {
                Button("Back") { next(2) }
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(width: 78, height: 58)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.045)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 0.7))
                    .buttonStyle(.plain)

                Button {
                    next(4)
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.custom("Sora-Bold", size: 16))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(Color(hex: "041014"))
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "7AF6FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!bankProfile.isReadyForAutopilot)
                .opacity(bankProfile.isReadyForAutopilot ? 1 : 0.32)
            }
        }
    }

    private var bankAccountCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    cardLabel("PAYOUT ACCOUNT")
                    Spacer()
                    HStack(spacing: 5) {
                        Circle()
                            .fill(bankProfile.connectionStatus == .connected ? MilliColors.positive : Color(hex: "D7AD45"))
                            .frame(width: 5, height: 5)
                        Text(bankProfile.connectionStatus == .connected ? "CONNECTED" : "REQUIRED")
                            .font(.custom("Inter-SemiBold", size: 9))
                            .foregroundStyle(bankProfile.connectionStatus == .connected ? MilliColors.positive : Color(hex: "D7AD45"))
                    }
                }

                Button {
                    bankProfile.connectionStatus = .connecting
                    plaid.begin()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.16))
                                .frame(width: 38, height: 38)
                            if plaid.isLoading {
                                ProgressView().tint(Color(hex: "041014"))
                            } else {
                                Image(systemName: bankProfile.connectionStatus == .connected ? "checkmark.shield.fill" : "building.columns.fill")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bankProfile.connectionStatus == .connected ? connectedBankTitle : "Connect Bank Securely")
                                .font(.custom("Sora-Bold", size: 15))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(bankProfile.connectionStatus == .connected ? "Payout account ready" : "Powered by Plaid")
                                .font(.custom("Inter-Medium", size: 10))
                                .opacity(0.66)
                        }

                        Spacer()
                        Image(systemName: bankProfile.connectionStatus == .connected ? "checkmark.circle.fill" : "arrow.right")
                            .font(.system(size: 17, weight: .heavy))
                    }
                    .foregroundStyle(Color(hex: "041014"))
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "86F8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.68), lineWidth: 0.8))
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
                        .foregroundStyle(Color.white.opacity(0.58))
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
            VStack(alignment: .leading, spacing: 13) {
                cardLabel("YOUR AUTHORIZATION")

                Toggle("Detect eligible gig payouts in this connected account", isOn: $bankProfile.transactionMonitoringConsent)
                    .font(.custom("Inter-Regular", size: 13))
                    .tint(MilliColors.cyanGlow)

                Divider().overlay(Color.white.opacity(0.07))

                Toggle("Move calculated tax reserves to Milli Tax Vault™", isOn: $bankProfile.taxVaultTransferConsent)
                    .font(.custom("Inter-Regular", size: 13))
                    .tint(MilliColors.cyanGlow)

                Text("You can change these permissions later in Autopilot settings.")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundStyle(Color.white.opacity(0.48))
            }
            .foregroundStyle(Color.white.opacity(0.82))
        }
    }

    // MARK: - Step 5 — Mileage

    private var mileageStep: some View {
        stageScroll(
            icon: "location.fill",
            eyebrow: "MILEAGE INTELLIGENCE",
            title: "Track every deductible mile.",
            body: "Enable location access so Milli can build clean business-trip records, route history, and mileage totals while you drive."
        ) {
            glassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        cardLabel("LOCATION ACCESS")
                        Spacer()
                        Text(locationManager.hasAlwaysAuthorization ? "READY" : "REQUIRED")
                            .font(.custom("Inter-SemiBold", size: 9))
                            .foregroundStyle(locationManager.hasAlwaysAuthorization ? MilliColors.positive : Color(hex: "D7AD45"))
                    }
                    Text("Allow Always for hands-free trip detection and uninterrupted navigation.")
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .fixedSize(horizontal: false, vertical: true)
                    primaryButton(locationButtonTitle, systemImage: "location.fill") {
                        requestMileageAuthorization()
                    }
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 11) {
                    cardLabel("TRACKING PREVIEW")
                    HStack(spacing: 10) {
                        mileageStat(icon: "road.lanes", label: "TODAY", value: formattedTodayMiles + " mi")
                        mileageStat(icon: "location.circle.fill", label: "STATUS", value: locationManager.canTrackLocation ? "Ready" : "Off")
                    }
                }
            }

            primaryButton("Continue", systemImage: "arrow.right.circle.fill") { next(5) }
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
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
            Text(label)
                .font(.custom("Inter-SemiBold", size: 8.5))
                .tracking(0.9)
                .foregroundStyle(Color.white.opacity(0.48))
            Text(value)
                .font(.custom("Sora-Bold", size: 17))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(MilliColors.cyanGlow.opacity(0.24), lineWidth: 0.8))
    }

    // MARK: - Step 6 — Autopilot

    private var autopilotStep: some View {
        stageScroll(
            icon: "bolt.shield.fill",
            eyebrow: "MILLI AUTOPILOT™",
            title: "Put every payout to work.",
            body: "Protect taxes first, then optionally route part of each eligible payout toward savings, retirement, or investing."
        ) {
            glassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        cardLabel("ALLOCATION SETTINGS")
                        Spacer()
                        HStack(spacing: 5) {
                            Circle().fill(MilliColors.positive).frame(width: 5, height: 5)
                            Text("LIVE PREVIEW")
                                .font(.custom("Inter-SemiBold", size: 8.5))
                                .foregroundStyle(MilliColors.positive)
                        }
                    }
                    allocationRow(title: "Tax Reserve", icon: "building.columns.fill", enabled: $taxEnabled, percent: $taxPercent)
                    allocationRow(title: "Savings", icon: "piggybank.fill", enabled: $savingsEnabled, percent: $savingsPercent)
                    allocationRow(title: "Retirement", icon: "chart.bar.fill", enabled: $retirementEnabled, percent: $retirementPercent)
                    allocationRow(title: "Investing", icon: "leaf.fill", enabled: $investingEnabled, percent: $investingPercent)
                }
            }

            glassCard {
                VStack(alignment: .leading, spacing: 9) {
                    cardLabel("AUTOPILOT RECEIPT")
                    receiptRow("Gross Payout", amount: "$187.42", strong: true)
                    receiptRow("Tax Reserve (\(Int(taxPercent))%)", amount: negativeAllocation(187.42, taxEnabled ? taxPercent : 0))
                    receiptRow("Retirement", amount: negativeAllocation(187.42, retirementEnabled ? retirementPercent : 0))
                    receiptRow("Investing", amount: negativeAllocation(187.42, investingEnabled ? investingPercent : 0))
                    receiptRow("Savings", amount: negativeAllocation(187.42, savingsEnabled ? savingsPercent : 0))
                    Divider().overlay(Color.white.opacity(0.18))
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
        VStack(spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.48))
                    .frame(width: 22)

                Text(title)
                    .font(.custom("Inter-SemiBold", size: 13))
                    .foregroundStyle(Color.white.opacity(0.88))

                Spacer()

                Text("\(Int(percent.wrappedValue))%")
                    .font(.custom("Sora-Bold", size: 12))
                    .monospacedDigit()
                    .foregroundStyle(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.38))

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .scaleEffect(0.78)
                    .tint(MilliColors.cyanGlow)
            }

            Slider(value: percent, in: 1...35, step: 1)
                .tint(enabled.wrappedValue ? MilliColors.cyanGlow : Color.white.opacity(0.16))
                .disabled(!enabled.wrappedValue)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 13).fill(enabled.wrappedValue ? MilliColors.cyanGlow.opacity(0.045) : Color.white.opacity(0.016)))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(enabled.wrappedValue ? MilliColors.cyanGlow.opacity(0.34) : Color.white.opacity(0.09), lineWidth: 0.7))
    }

    private func receiptRow(_ label: String, amount: String, strong: Bool = false, cyan: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.custom(strong ? "Inter-SemiBold" : "Inter-Regular", size: 13))
                .foregroundStyle(Color.white.opacity(strong ? 0.90 : 0.68))
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
