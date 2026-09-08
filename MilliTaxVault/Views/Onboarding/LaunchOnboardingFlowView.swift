import SwiftUI
import LinkKit

// MARK: - LaunchOnboardingFlowView
// Release-candidate onboarding flow. It preserves the approved six-step native
// setup while replacing the placeholder bank gate with the real Render -> Plaid
// Link -> Render token exchange path.

struct LaunchOnboardingFlowView: View {
    @State private var currentStep = 0
    @State private var vehicle = VehicleProfile()
    @State private var taxProfile = TaxProfile()
    @State private var bankProfile = BankAutopilotProfile()
    @State private var selectedPlan: MilliPlan = .pro

    @State private var retirementEnabled = true
    @State private var investingEnabled = false
    @State private var savingsEnabled = true
    @State private var retirementPercent = 5.0
    @State private var investingPercent = 0.0
    @State private var savingsPercent = 3.0

    var onComplete: () -> Void

    private let stepCount = 6

    private var taxPercent: Double {
        let income = taxProfile.annualIncomeAmount ?? 55_000
        switch income {
        case ..<30_000: return 20
        case ..<60_000: return 23
        case ..<100_000: return 27
        default: return 30
        }
    }

    var body: some View {
        ZStack {
            setupBackground

            VStack(spacing: 0) {
                setupHeader
                    .padding(.horizontal, MilliLayout.screenMargin)
                    .padding(.top, 10)

                progressBar
                    .padding(.horizontal, MilliLayout.screenMargin)
                    .padding(.top, 10)

                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        VehicleSetupView(
                            vehicle: $vehicle,
                            onNext: { move(to: 2) },
                            onBack: { move(to: 0) }
                        )
                    case 2:
                        TaxProfileSetupView(
                            taxProfile: $taxProfile,
                            onNext: { move(to: 3) },
                            onBack: { move(to: 1) }
                        )
                    case 3:
                        PlaidBankConnectionSetupView(
                            profile: $bankProfile,
                            onNext: { move(to: 4) },
                            onBack: { move(to: 2) }
                        )
                    case 4:
                        PlanSelectionView(
                            selectedPlan: $selectedPlan,
                            onComplete: { move(to: 5) },
                            onBack: { move(to: 3) }
                        )
                    case 5:
                        autopilotStep
                    default:
                        welcomeStep
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .animation(.easeInOut(duration: 0.28), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var setupHeader: some View {
        HStack {
            MilliWordmark(fontSize: 17, tracking: 3.8)
            Spacer()
            Text("SETUP \(currentStep + 1) OF \(stepCount)")
                .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                .tracking(0.8)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(height: 28)
    }

    private var progressBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<stepCount, id: \.self) { step in
                Capsule(style: .continuous)
                    .fill(step <= currentStep ? MilliColors.cyanGlow : Color.white.opacity(0.10))
                    .frame(height: 3)
                    .shadow(color: step == currentStep ? MilliColors.cyanGlow.opacity(0.30) : .clear, radius: 3)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 26)

            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.055))
                    .frame(width: 156, height: 156)
                    .blur(radius: 16)

                Circle()
                    .fill(Color.black.opacity(0.80))
                    .frame(width: 126, height: 126)
                    .overlay {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [MilliColors.chromeDark, MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeWhite, MilliColors.chromeDark],
                                    center: .center
                                ),
                                lineWidth: 5
                            )
                    }

                Circle()
                    .stroke(MilliColors.cyanGlow.opacity(0.70), style: StrokeStyle(lineWidth: 2, dash: [3, 4]))
                    .frame(width: 104, height: 104)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.34), radius: 7)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .blendMode(.screen)
            }

            VStack(spacing: 10) {
                Text("BUILD YOUR FINANCIAL PROFILE")
                    .font(MilliFont.sectionLabel)
                    .tracking(1.0)
                    .foregroundStyle(MilliColors.cyanGlow)

                Text("Set Milli up around\nhow you actually work.")
                    .font(.custom("Sora-Bold", size: 31, relativeTo: .largeTitle))
                    .foregroundStyle(MilliColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-1)

                Text("We'll configure your vehicle, tax profile, connected payout account, gig sources, product tier, and Autopilot preferences before you enter Milli.")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
            }
            .padding(.top, 24)

            Spacer(minLength: 24)

            OnboardingPrimaryButton(title: "Begin Setup") {
                move(to: 1)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.bottom, 34)
        }
    }

    private var autopilotStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("MILLI AUTOPILOT™")
                        .font(MilliFont.sectionLabel)
                        .tracking(1.0)
                        .foregroundStyle(MilliColors.cyanGlow)

                    Text("Choose what happens after every payout.")
                        .font(.custom("Sora-Bold", size: 28, relativeTo: .largeTitle))
                        .foregroundStyle(MilliColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Once the connected account reports an eligible gig payout, Milli identifies the source, applies your tax profile, and prepares the matching Tax Vault reserve automatically.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                taxProtectionRow

                onboardingAllocationControl(
                    title: "Retirement",
                    subtitle: "Build long-term retirement wealth",
                    icon: "building.columns.fill",
                    color: MilliColors.positive,
                    enabled: $retirementEnabled,
                    percent: $retirementPercent
                )

                onboardingAllocationControl(
                    title: "Investing",
                    subtitle: "Direct part of each payout toward investing",
                    icon: "chart.line.uptrend.xyaxis",
                    color: MilliColors.deepCyan,
                    enabled: $investingEnabled,
                    percent: $investingPercent
                )

                onboardingAllocationControl(
                    title: "Savings",
                    subtitle: "Fund active savings goals automatically",
                    icon: "target",
                    color: MilliColors.deepCyan,
                    enabled: $savingsEnabled,
                    percent: $savingsPercent
                )

                onboardingAllocationPreview

                HStack(spacing: 12) {
                    OnboardingBackButton { move(to: 4) }
                    OnboardingPrimaryButton(title: "Enter Milli") {
                        saveAndComplete()
                    }
                }
                .padding(.top, 2)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, 22)
        }
    }

    private var taxProtectionRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 36, height: 36)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.09)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Tax Protection")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("On • estimated reserve \(Int(taxPercent))% from your current tax profile")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MilliColors.positive)
        }
        .milliCard(padding: 12)
    }

    private func onboardingAllocationControl(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        enabled: Binding<Bool>,
        percent: Binding<Double>
    ) -> some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(color.opacity(0.09)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(subtitle)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer(minLength: 6)

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(color)
            }

            if enabled.wrappedValue {
                HStack(spacing: 10) {
                    Slider(value: percent, in: 1...25, step: 1)
                        .tint(color)
                    Text("\(Int(percent.wrappedValue))%")
                        .font(MilliFont.numericSmall)
                        .monospacedDigit()
                        .foregroundStyle(color)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
        .animation(.easeInOut(duration: 0.16), value: enabled.wrappedValue)
        .milliCard(padding: 12)
    }

    private var onboardingAllocationPreview: some View {
        let examplePayout = 200.0
        let result = AutopilotAllocationEngine.allocate(
            payout: examplePayout,
            settings: AutopilotAllocationSettings(
                taxPercent: taxPercent,
                retirementEnabled: retirementEnabled,
                retirementPercent: retirementPercent,
                investingEnabled: investingEnabled,
                investingPercent: investingPercent,
                savingsEnabled: savingsEnabled,
                savingsPercent: savingsPercent
            )
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("$200 PAYOUT PREVIEW")
                    .sectionHeaderStyle()
                Spacer()
                Text("Available \(result.availableToSpend.formatted(.currency(code: "USD")))")
                    .font(MilliFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }

            GeometryReader { geo in
                let total = max(result.grossPayout, 1)
                HStack(spacing: 2) {
                    allocationBar(width: geo.size.width * result.taxReserve / total, color: MilliColors.cyanGlow)
                    allocationBar(width: geo.size.width * result.retirement / total, color: MilliColors.positive)
                    allocationBar(width: geo.size.width * result.investing / total, color: MilliColors.deepCyan)
                    allocationBar(width: geo.size.width * result.savings / total, color: MilliColors.deepCyan)
                    allocationBar(width: geo.size.width * result.availableToSpend / total, color: Color.white.opacity(0.18))
                }
            }
            .frame(height: 7)
        }
        .milliCard(padding: 11)
    }

    private func allocationBar(width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: max(width, 0), height: 7)
    }

    private var setupBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.05), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    private func move(to step: Int) {
        withAnimation(.easeInOut(duration: 0.28)) {
            currentStep = min(max(step, 0), stepCount - 1)
        }
    }

    private func saveAndComplete() {
        guard bankProfile.isReadyForAutopilot else { return }

        if let vehicleData = try? JSONEncoder().encode(vehicle) {
            UserDefaults.standard.set(vehicleData, forKey: "onboarding_vehicle")
        }
        if let taxData = try? JSONEncoder().encode(taxProfile) {
            UserDefaults.standard.set(taxData, forKey: "onboarding_taxProfile")
        }
        if let bankData = try? JSONEncoder().encode(bankProfile) {
            UserDefaults.standard.set(bankData, forKey: "onboarding_bankAutopilotProfile")
        }
        UserDefaults.standard.set(selectedPlan.rawValue, forKey: "onboarding_plan")

        UserDefaults.standard.set(retirementEnabled, forKey: "milliAutopilotRetirementEnabled")
        UserDefaults.standard.set(investingEnabled, forKey: "milliAutopilotInvestingEnabled")
        UserDefaults.standard.set(savingsEnabled, forKey: "milliAutopilotSavingsEnabled")
        UserDefaults.standard.set(retirementPercent, forKey: "milliAutopilotRetirementPercent")
        UserDefaults.standard.set(investingPercent, forKey: "milliAutopilotInvestingPercent")
        UserDefaults.standard.set(savingsPercent, forKey: "milliAutopilotSavingsPercent")

        onComplete()
    }
}

// MARK: - Real bank-link setup

private struct PlaidBankConnectionSetupView: View {
    @Binding var profile: BankAutopilotProfile
    var onNext: () -> Void
    var onBack: () -> Void

    @StateObject private var plaid = PlaidLinkCoordinator()

    private let preferredPlatforms: [GigPlatform] = [
        .amazonFlex, .sparkDriver, .uber, .lyft, .doorDash,
        .grubhub, .instacart, .roadie, .shipt
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("BANK + PAYOUT DETECTION")
                        .font(MilliFont.sectionLabel)
                        .tracking(1.0)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Connect where your gig payouts land.")
                        .font(.custom("Sora-Bold", size: 28, relativeTo: .largeTitle))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Milli uses Plaid to securely connect the account where your gig deposits land. Your banking credentials are handled by Plaid and never pass through Milli.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("PAYOUT ACCOUNT").sectionHeaderStyle()
                        Spacer()
                        Text(profile.connectionStatus == .connected ? "CONNECTED" : "REQUIRED")
                            .font(MilliFont.caption)
                            .foregroundStyle(profile.connectionStatus == .connected ? MilliColors.positive : MilliColors.warning)
                    }

                    Button {
                        profile.connectionStatus = .connecting
                        plaid.begin()
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "building.columns.fill")
                            Text(bankButtonTitle)
                            Spacer()
                            if plaid.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(MilliColors.blackGlass)
                            } else {
                                Image(systemName: profile.connectionStatus == .connected ? "checkmark.seal.fill" : "chevron.right")
                            }
                        }
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.blackGlass)
                        .padding(.horizontal, 13)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 11).fill(MilliColors.cyanGlow))
                    }
                    .buttonStyle(.plain)
                    .disabled(plaid.isLoading || plaid.isPresentingLink)

                    if profile.connectionStatus == .connected {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(MilliColors.positive)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(profile.institutionName.isEmpty ? "Connected bank" : profile.institutionName)
                                    .font(MilliFont.bodyMedium)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(accountSummary)
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                        }
                    }
                }
                .milliCard(padding: 13)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("GIG PAYOUT SOURCES").sectionHeaderStyle()
                        Spacer()
                        Toggle("", isOn: $profile.autoDetectPlatforms)
                            .labelsHidden()
                            .tint(MilliColors.cyanGlow)
                    }

                    Text("Confirm the companies you drive or deliver for. Auto-detect uses this as a high-confidence filter when matching bank deposits.")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(preferredPlatforms) { platform in
                            let selected = profile.selectedPlatforms.contains(platform)
                            Button {
                                if selected {
                                    profile.selectedPlatforms.remove(platform)
                                } else {
                                    profile.selectedPlatforms.insert(platform)
                                }
                            } label: {
                                HStack(spacing: 7) {
                                    Circle()
                                        .fill(selected ? MilliColors.cyanGlow : Color.white.opacity(0.08))
                                        .frame(width: 8, height: 8)
                                    Text(platform.rawValue)
                                        .font(MilliFont.bodySmall)
                                        .foregroundStyle(selected ? MilliColors.textPrimary : MilliColors.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(selected ? MilliColors.cyanGlow.opacity(0.08) : Color.white.opacity(0.025))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .milliCard(padding: 13)

                VStack(alignment: .leading, spacing: 10) {
                    Text("AUTOPILOT PERMISSIONS").sectionHeaderStyle()
                    onboardingToggle(label: "Detect gig payouts", isOn: $profile.transactionMonitoringConsent)
                    onboardingToggle(label: "Move calculated tax reserve to Milli Tax Vault™", isOn: $profile.taxVaultTransferConsent)
                }
                .milliCard(padding: 13)

                HStack(spacing: 12) {
                    OnboardingBackButton(action: onBack)
                    OnboardingPrimaryButton(title: "Continue", action: onNext)
                        .opacity(profile.isReadyForAutopilot ? 1 : 0.38)
                        .allowsHitTesting(profile.isReadyForAutopilot)
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, 22)
        }
        .sheet(isPresented: $plaid.isPresentingLink) {
            if let session = plaid.linkSession {
                session.sheet()
            } else {
                ProgressView("Opening Plaid…")
                    .tint(MilliColors.cyanGlow)
                    .preferredColorScheme(.dark)
            }
        }
        .onChange(of: plaid.connectedAccount?.id) { _, _ in
            guard let account = plaid.connectedAccount else { return }
            profile.connectionStatus = .connected
            profile.institutionName = account.institutionName ?? "Connected bank"
            profile.accountName = account.name ?? "Payout account"
            profile.accountLastFour = account.mask ?? ""
        }
        .onChange(of: plaid.isPresentingLink) { _, isPresenting in
            if !isPresenting,
               !plaid.isLoading,
               plaid.connectedAccount == nil,
               profile.connectionStatus == .connecting {
                profile.connectionStatus = .notConnected
            }
        }
        .alert(
            "Bank connection issue",
            isPresented: Binding(
                get: { plaid.errorMessage != nil },
                set: { visible in
                    if !visible { plaid.errorMessage = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                plaid.errorMessage = nil
                if profile.connectionStatus != .connected {
                    profile.connectionStatus = .needsAttention
                }
            }
        } message: {
            Text(plaid.errorMessage ?? "Milli couldn't open Plaid Link.")
        }
    }

    private var bankButtonTitle: String {
        if plaid.isLoading { return "Preparing Secure Connection…" }
        return profile.connectionStatus == .connected ? "Bank Connected" : "Connect Bank Securely"
    }

    private var accountSummary: String {
        let name = profile.accountName.isEmpty ? "Payout account" : profile.accountName
        guard !profile.accountLastFour.isEmpty else { return name }
        return "\(name) •••• \(profile.accountLastFour)"
    }
}

#Preview {
    LaunchOnboardingFlowView(onComplete: {})
}
