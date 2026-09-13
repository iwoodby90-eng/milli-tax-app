import SwiftUI
import LinkKit

// MARK: - LaunchOnboardingFlowView
// Canonical production setup for Milli. The visual system is deliberately flat
// and cinematic: strong typography, one primary instrument surface per step,
// restrained chrome/cyan detail, and no card-within-card composition.

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
    private let preferredPlatforms: [GigPlatform] = [
        .amazonFlex, .sparkDriver, .uber, .lyft, .doorDash,
        .grubhub, .instacart, .roadie, .shipt
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, sidePadding)
                        .padding(.top, 5)

                    progressRail
                        .padding(.horizontal, sidePadding)
                        .padding(.top, 4)

                    Group {
                        switch currentStep {
                        case 0: welcomeStep
                        case 1: taxStep
                        case 2: gigStep
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
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.24), value: currentStep)
        .sheet(isPresented: $plaid.isPresentingLink) {
            if let session = plaid.linkSession {
                session.sheet()
            } else {
                ZStack {
                    MilliColors.background.ignoresSafeArea()
                    ProgressView("Preparing secure bank connection…")
                        .tint(MilliColors.cyanGlow)
                        .foregroundStyle(MilliColors.textPrimary)
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

    // MARK: Shell

    private var background: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "061015"), Color(hex: "030608"), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.095), Color.clear],
                center: UnitPoint(x: 0.06, y: 0.04),
                startRadius: 0,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    next(currentStep - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MilliColors.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous setup step")
            }

            MilliWordmark(fontSize: 21, tracking: 4.5)

            Spacer()

            Text("\(currentStep + 1) / \(stepCount)")
                .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption2))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(Capsule().fill(Color.white.opacity(0.035)))
        }
        .frame(height: 46)
    }

    private var progressRail: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.075))
                    .frame(height: 2)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(stepCount),
                        height: 2
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.42), radius: 5)
            }
        }
        .frame(height: 8)
    }

    private func screen<Content: View>(
        eyebrow: String,
        title: String,
        body: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(eyebrow)
                        .font(.custom("Inter-SemiBold", size: 10.5, relativeTo: .caption))
                        .tracking(2.0)
                        .foregroundStyle(MilliColors.cyanGlow)

                    Text(title)
                        .font(.custom("Sora-Bold", size: 32, relativeTo: .largeTitle))
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineSpacing(-1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(body)
                        .font(.custom("Inter-Regular", size: 15, relativeTo: .body))
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, sidePadding)
            .padding(.top, 24)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var instrumentPanel: some ShapeStyle {
        LinearGradient(
            colors: [Color(hex: "0D171C"), Color(hex: "070B0E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(instrumentPanel)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.17), MilliColors.cyanGlow.opacity(0.12), Color.white.opacity(0.025)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }
            )
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
            .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
            .tracking(1.55)
            .foregroundStyle(MilliColors.textSecondary)
    }

    private func separator() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.065))
            .frame(height: 1)
    }

    private func primaryButton(_ title: String, icon: String? = nil, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.custom("Sora-SemiBold", size: 15, relativeTo: .headline))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(enabled ? Color(hex: "031013") : MilliColors.textTertiary)
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        enabled
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color(hex: "83F8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color.white.opacity(0.05))
                    )
                    .shadow(color: enabled ? MilliColors.cyanGlow.opacity(0.20) : .clear, radius: 10, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Step 1 — Welcome

    private var welcomeStep: some View {
        screen(
            eyebrow: "WELCOME TO MILLI",
            title: "Your money.\nFinally on autopilot.",
            body: "Set the financial rules once. Milli organizes taxes, mileage, payout detection, and future allocations around the way you actually work."
        ) {
            HStack(alignment: .center, spacing: 16) {
                ChromeEmblemView(size: 76)

                VStack(alignment: .leading, spacing: 5) {
                    Text("MONEY, MADE INTELLIGENT.")
                        .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                        .tracking(1.7)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Six focused steps. Nothing decorative. Everything has a financial purpose.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 6)

            panel {
                VStack(spacing: 0) {
                    capabilityRow(icon: "shield.lefthalf.filled", title: "Protect taxes", detail: "Reserve guidance tied to eligible payouts.")
                    separator().padding(.leading, 44)
                    capabilityRow(icon: "location.fill", title: "Track deductible miles", detail: "Build clean business-mile records while you work.")
                    separator().padding(.leading, 44)
                    capabilityRow(icon: "chart.line.uptrend.xyaxis", title: "Build the future", detail: "Direct money toward goals, retirement, and investing.")
                }
            }

            primaryButton("Begin Setup", icon: "arrowtriangle.right.fill") { next(1) }
        }
    }

    private func capabilityRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 14.5))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(.custom("Inter-Regular", size: 12.5))
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    // MARK: Step 2 — Tax profile

    private var taxStep: some View {
        screen(
            eyebrow: "TAX PROFILE",
            title: "Calibrate your tax protection.",
            body: "Milli uses these inputs to estimate federal, state, and self-employment tax exposure. You can update them whenever your situation changes."
        ) {
            panel {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("FILING STATUS")
                        .padding(.bottom, 8)

                    ForEach(TaxProfile.FilingStatus.allCases, id: \.rawValue) { status in
                        taxStatusRow(status)
                        if status.rawValue != TaxProfile.FilingStatus.allCases.last?.rawValue {
                            separator().padding(.leading, 34)
                        }
                    }

                    separator().padding(.vertical, 12)
                    sectionLabel("PROFILE DETAILS")
                        .padding(.bottom, 6)

                    Menu {
                        ForEach(["Michigan", "California", "Florida", "New York", "Texas", "Other"], id: \.self) { state in
                            Button(state) { taxProfile.state = state }
                        }
                    } label: {
                        valueRow(title: "State of Residence", value: taxProfile.state.isEmpty ? "Select" : taxProfile.state)
                    }

                    separator()

                    Menu {
                        ForEach(["Sole Proprietor", "Single-Member LLC", "S-Corp", "Partnership"], id: \.self) { value in
                            Button(value) { businessType = value }
                        }
                    } label: {
                        valueRow(title: "Business Type", value: businessType)
                    }

                    separator()

                    Menu {
                        ForEach(["Under $30,000", "$30,000–$50,000", "$50,000–$75,000", "$75,000–$100,000", "$100,000+"], id: \.self) { band in
                            Button(band) {
                                incomeBand = band
                                taxProfile.estimatedAnnualIncome = incomeAmount(for: band)
                                taxPercent = estimatedTaxPercent(for: band)
                            }
                        }
                    } label: {
                        valueRow(title: "Expected 2026 Net Income", value: incomeBand)
                    }
                }
            }

            primaryButton("Continue", icon: "checkmark.shield.fill") {
                if taxProfile.state.isEmpty { taxProfile.state = "Michigan" }
                if taxProfile.estimatedAnnualIncome.isEmpty {
                    taxProfile.estimatedAnnualIncome = incomeAmount(for: incomeBand)
                    taxPercent = estimatedTaxPercent(for: incomeBand)
                }
                next(2)
            }
        }
    }

    private func taxStatusRow(_ status: TaxProfile.FilingStatus) -> some View {
        let selected = taxProfile.filingStatus == status
        return Button {
            taxProfile.filingStatus = status
        } label: {
            HStack(spacing: 11) {
                Circle()
                    .stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.22), lineWidth: 1.2)
                    .frame(width: 18, height: 18)
                    .overlay {
                        if selected {
                            Circle().fill(MilliColors.cyanGlow).frame(width: 9, height: 9)
                        }
                    }
                Text(status.rawValue)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundStyle(MilliColors.textPrimary)
                Spacer()
            }
            .frame(height: 45)
        }
        .buttonStyle(.plain)
    }

    private func valueRow(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundStyle(MilliColors.textSecondary)
                Text(value)
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
        }
        .frame(height: 58)
        .contentShape(Rectangle())
    }

    // MARK: Step 3 — Gig work

    private var gigStep: some View {
        screen(
            eyebrow: "GIG WORK PROFILE",
            title: "Tell Milli where income comes from.",
            body: "Select the platforms that pay you. Milli uses this list as a high-confidence filter when matching deposits after your bank is connected."
        ) {
            panel {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        sectionLabel("ACTIVE PLATFORMS")
                        Spacer()
                        Text("\(bankProfile.selectedPlatforms.count) SELECTED")
                            .font(.custom("Inter-SemiBold", size: 8.5))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(preferredPlatforms) { platform in
                            platformButton(platform)
                        }
                    }

                    separator()

                    sectionLabel("PAYOUT CADENCE")

                    HStack(spacing: 6) {
                        ForEach(GigPayoutFrequency.allCases) { frequency in
                            let selected = payoutFrequency == frequency
                            Button {
                                payoutFrequency = frequency
                            } label: {
                                Text(frequency.rawValue)
                                    .font(.custom("Inter-SemiBold", size: 11))
                                    .foregroundStyle(selected ? Color(hex: "031013") : MilliColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(
                                        Capsule()
                                            .fill(selected ? MilliColors.cyanGlow : Color.white.opacity(0.035))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            primaryButton(
                "Continue",
                icon: "briefcase.fill",
                enabled: !bankProfile.selectedPlatforms.isEmpty
            ) { next(3) }
        }
    }

    private func platformButton(_ platform: GigPlatform) -> some View {
        let selected = bankProfile.selectedPlatforms.contains(platform)
        return Button {
            if selected {
                bankProfile.selectedPlatforms.remove(platform)
            } else {
                bankProfile.selectedPlatforms.insert(platform)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selected ? MilliColors.cyanGlow : MilliColors.textTertiary)
                Text(platform.rawValue)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(selected ? MilliColors.cyanGlow.opacity(0.055) : Color.white.opacity(0.018))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(selected ? MilliColors.cyanGlow.opacity(0.28) : Color.white.opacity(0.055), lineWidth: 0.7)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Step 4 — Bank only

    private var bankStep: some View {
        screen(
            eyebrow: "SECURE BANK CONNECTION",
            title: "Connect where your payouts land.",
            body: "Milli uses Plaid to identify eligible gig deposits and power Autopilot. Your bank credentials stay with Plaid — Milli never stores them."
        ) {
            panel {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(MilliColors.cyanGlow.opacity(0.08))
                                .frame(width: 46, height: 46)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(MilliColors.cyanGlow)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(bankProfile.connectionStatus == .connected ? connectedBankTitle : "Payout Account")
                                .font(.custom("Sora-SemiBold", size: 16))
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(bankConnectionDetail)
                                .font(MilliFont.caption)
                                .foregroundStyle(bankProfile.connectionStatus == .connected ? MilliColors.positive : MilliColors.textSecondary)
                        }

                        Spacer()

                        if plaid.isLoading {
                            ProgressView().tint(MilliColors.cyanGlow)
                        } else if bankProfile.connectionStatus == .connected {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(MilliColors.positive)
                        }
                    }

                    separator()

                    bankCapability("Identify deposits from your selected gig platforms", icon: "arrow.down.circle.fill")
                    bankCapability("Match payout activity without storing your password", icon: "lock.shield.fill")
                    bankCapability("Calculate the tax reserve associated with each matched payout", icon: "percent")

                    Button {
                        if bankProfile.connectionStatus == .connected {
                            plaid.reset()
                            bankProfile.connectionStatus = .notConnected
                            bankProfile.institutionName = ""
                            bankProfile.accountName = ""
                            bankProfile.accountLastFour = ""
                        } else {
                            plaid.begin()
                        }
                    } label: {
                        HStack {
                            Image(systemName: bankProfile.connectionStatus == .connected ? "arrow.clockwise" : "link")
                            Text(bankProfile.connectionStatus == .connected ? "Reconnect Account" : "Connect Bank with Plaid")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.custom("Inter-SemiBold", size: 13))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(plaid.isLoading)
                }
            }

            primaryButton(
                "Continue",
                icon: "checkmark.shield.fill",
                enabled: bankProfile.connectionStatus == .connected
            ) { next(4) }
        }
    }

    private var connectedBankTitle: String {
        let bank = bankProfile.institutionName.isEmpty ? "Connected Bank" : bankProfile.institutionName
        let mask = bankProfile.accountLastFour.isEmpty ? "" : " ••••\(bankProfile.accountLastFour)"
        return "\(bank)\(mask)"
    }

    private var bankConnectionDetail: String {
        switch bankProfile.connectionStatus {
        case .connected: return bankProfile.accountName.isEmpty ? "Connected securely" : bankProfile.accountName
        case .connecting: return "Opening secure connection…"
        case .needsAttention: return "Connection needs attention"
        case .notConnected: return "Required for automatic payout detection"
        }
    }

    private func bankCapability(_ text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 19)
            Text(text)
                .font(.custom("Inter-Regular", size: 12.5))
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Step 5 — Mileage

    private var mileageStep: some View {
        screen(
            eyebrow: "MILEAGE INTELLIGENCE",
            title: "Track the miles that earn money.",
            body: "Location access powers business-trip records, live mileage totals, and Milli navigation. Tracking remains under your control."
        ) {
            panel {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 13) {
                        ZStack {
                            Circle()
                                .fill(MilliColors.cyanGlow.opacity(0.08))
                                .frame(width: 48, height: 48)
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(MilliColors.cyanGlow)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Location Access")
                                .font(.custom("Sora-SemiBold", size: 16))
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(locationStatusText)
                                .font(MilliFont.caption)
                                .foregroundStyle(locationManager.canTrackLocation ? MilliColors.positive : MilliColors.textSecondary)
                        }

                        Spacer()

                        Text(formattedTodayMiles + " mi")
                            .font(.custom("Sora-Bold", size: 18))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                    }

                    separator()

                    HStack(spacing: 10) {
                        Image(systemName: "car.side.fill")
                            .foregroundStyle(MilliColors.cyanGlow)
                        Text("Milli starts and stops tracking only when the mileage workflow requires it. You can change permission in iOS Settings at any time.")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        requestMileageAuthorization()
                    } label: {
                        HStack {
                            Text(locationButtonTitle)
                            Spacer()
                            Image(systemName: locationManager.hasAlwaysAuthorization ? "checkmark.circle.fill" : "location.fill")
                        }
                        .font(.custom("Inter-SemiBold", size: 13))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }

            primaryButton("Continue", icon: "arrow.right.circle.fill") { next(5) }
        }
    }

    private var locationButtonTitle: String {
        if locationManager.hasAlwaysAuthorization { return "Always-On Tracking Enabled" }
        if locationManager.canTrackLocation { return "Enable Background Tracking" }
        return "Enable Location Access"
    }

    private var locationStatusText: String {
        if locationManager.hasAlwaysAuthorization { return "Ready for hands-free mileage" }
        if locationManager.canTrackLocation { return "When-in-use access enabled" }
        return "Enable to track deductible mileage"
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

    // MARK: Step 6 — Autopilot

    private var autopilotStep: some View {
        screen(
            eyebrow: "MILLI AUTOPILOT™",
            title: "Decide what every payout does next.",
            body: "Taxes stay first. Optional allocations can then build savings, retirement, and investing automatically as connected financial rails become available."
        ) {
            panel {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        sectionLabel("ALLOCATION RULES")
                        Spacer()
                        Text("$187.42 PREVIEW")
                            .font(.custom("Inter-SemiBold", size: 8.5))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    .padding(.bottom, 8)

                    allocationRow(title: "Tax Reserve", icon: "building.columns.fill", enabled: $taxEnabled, percent: $taxPercent)
                    separator()
                    allocationRow(title: "Savings", icon: "target", enabled: $savingsEnabled, percent: $savingsPercent)
                    separator()
                    allocationRow(title: "Retirement", icon: "chart.bar.fill", enabled: $retirementEnabled, percent: $retirementPercent)
                    separator()
                    allocationRow(title: "Investing", icon: "chart.line.uptrend.xyaxis", enabled: $investingEnabled, percent: $investingPercent)
                }
            }

            panel {
                VStack(alignment: .leading, spacing: 11) {
                    sectionLabel("AUTOPILOT AUTHORIZATION")
                    permissionToggle("Detect eligible gig payouts in my connected account", isOn: $bankProfile.transactionMonitoringConsent)
                    separator()
                    permissionToggle("Prepare the calculated tax reserve for Milli Tax Vault™", isOn: $bankProfile.taxVaultTransferConsent)
                }
            }

            panel {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionLabel("PLAN")
                        Spacer()
                        Text(selectedPlan.onboardingPriceLine)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.cyanGlow)
                    }

                    HStack(spacing: 6) {
                        ForEach(MilliPlan.allCases, id: \.rawValue) { plan in
                            let selected = selectedPlan == plan
                            Button {
                                selectedPlan = plan
                            } label: {
                                VStack(spacing: 2) {
                                    Text(plan.rawValue)
                                        .font(.custom("Inter-SemiBold", size: 12))
                                    Text(plan.monthlyPrice.replacingOccurrences(of: "/mo", with: ""))
                                        .font(.custom("Inter-Regular", size: 9.5))
                                }
                                .foregroundStyle(selected ? Color(hex: "031013") : MilliColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 45)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selected ? MilliColors.cyanGlow : Color.white.opacity(0.025))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    separator()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AVAILABLE AFTER PREVIEW")
                                .font(MilliFont.sectionLabel)
                                .foregroundStyle(MilliColors.textSecondary)
                            Text(availableToSpendFormatted)
                                .font(.custom("Sora-Bold", size: 27))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                        }
                        Spacer()
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                }
            }

            primaryButton(
                "Start 3-Day Trial",
                icon: "paperplane.fill",
                enabled: canFinishSetup
            ) { saveAndComplete() }
        }
    }

    private func allocationRow(title: String, icon: String, enabled: Binding<Bool>, percent: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(enabled.wrappedValue ? MilliColors.cyanGlow : MilliColors.textTertiary)
                    .frame(width: 22)

                Text(title)
                    .font(.custom("Inter-SemiBold", size: 13.5))
                    .foregroundStyle(MilliColors.textPrimary)

                Spacer()

                Text("\(Int(percent.wrappedValue))%")
                    .font(.custom("Sora-SemiBold", size: 12.5))
                    .monospacedDigit()
                    .foregroundStyle(enabled.wrappedValue ? MilliColors.cyanGlow : MilliColors.textTertiary)

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .scaleEffect(0.80)
                    .tint(MilliColors.cyanGlow)
            }

            if enabled.wrappedValue {
                Slider(value: percent, in: 1...35, step: 1)
                    .tint(MilliColors.cyanGlow)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.16), value: enabled.wrappedValue)
    }

    private func permissionToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.custom("Inter-Regular", size: 12.5))
                .foregroundStyle(MilliColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(MilliColors.cyanGlow)
        }
        .padding(.vertical, 4)
    }

    private var canFinishSetup: Bool {
        bankProfile.connectionStatus == .connected
            && bankProfile.transactionMonitoringConsent
            && bankProfile.taxVaultTransferConsent
            && taxEnabled
    }

    private var availableToSpendFormatted: String {
        let totalPercent = (taxEnabled ? taxPercent : 0)
            + (savingsEnabled ? savingsPercent : 0)
            + (retirementEnabled ? retirementPercent : 0)
            + (investingEnabled ? investingPercent : 0)
        return String(format: "$%.2f", max(0, 187.42 * (1 - totalPercent / 100)))
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

    private func estimatedTaxPercent(for band: String) -> Double {
        switch band {
        case "Under $30,000": return 20
        case "$30,000–$50,000": return 23
        case "$50,000–$75,000": return 25
        case "$75,000–$100,000": return 27
        default: return 30
        }
    }

    private func next(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.24)) {
            currentStep = min(max(step, 0), stepCount - 1)
        }
    }

    private func saveAndComplete() {
        guard canFinishSetup else { return }

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
