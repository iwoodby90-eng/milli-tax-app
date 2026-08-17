import SwiftUI

// MARK: - OnboardingFlowView — Native five-step setup
// Welcome → Vehicle → Tax Profile → Plan → Milli Autopilot™
// Persists the local setup contract used by the current native prototype.

struct OnboardingFlowView: View {
    @State private var currentStep = 0
    @State private var vehicle = VehicleProfile()
    @State private var taxProfile = TaxProfile()
    @State private var selectedPlan: MilliPlan = .pro

    @State private var retirementEnabled = true
    @State private var investingEnabled = false
    @State private var savingsEnabled = true
    @State private var retirementPercent = 5.0
    @State private var investingPercent = 0.0
    @State private var savingsPercent = 3.0

    var onComplete: () -> Void

    private let stepCount = 5
    private let taxPercent = 23.0

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
                        PlanSelectionView(
                            selectedPlan: $selectedPlan,
                            onComplete: { move(to: 4) },
                            onBack: { move(to: 2) }
                        )
                    case 4:
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
            Text("MILLI")
                .font(.custom("Sora-Bold", size: 17, relativeTo: .headline))
                .tracking(3.8)
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeWhite],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

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
                    .animation(.easeOut(duration: 0.25), value: currentStep)
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

                Text("We'll configure your vehicle, tax profile, product tier, and Autopilot allocation preferences before you enter the financial cockpit.")
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

                    Text("Tax protection stays on. Optional allocations can be changed later from the Autopilot control center.")
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
                    color: Color(hex: "7C8CFF"),
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
                    OnboardingBackButton { move(to: 3) }
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
                Text("Always on • current planning rate \(Int(taxPercent))%")
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
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                    allocationBar(width: geo.size.width * result.investing / total, color: Color(hex: "7C8CFF"))
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
        if let vehicleData = try? JSONEncoder().encode(vehicle) {
            UserDefaults.standard.set(vehicleData, forKey: "onboarding_vehicle")
        }
        if let taxData = try? JSONEncoder().encode(taxProfile) {
            UserDefaults.standard.set(taxData, forKey: "onboarding_taxProfile")
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

// MARK: - Shared Onboarding UI Components

struct OnboardingPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Text(title.uppercased())
                    .font(.custom("Sora-SemiBold", size: 14, relativeTo: .headline))
                    .tracking(0.55)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, Color(hex: "0BB8D6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 9)
            )
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MilliColors.textPrimary)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.035))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                        }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

func onboardingTextField(label: String, placeholder: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: MilliSpacing.sm) {
        Text(label)
            .font(MilliFont.sectionLabel)
            .foregroundStyle(MilliColors.textSecondary)
        TextField(placeholder, text: text)
            .font(MilliFont.bodyMedium)
            .foregroundStyle(MilliColors.textPrimary)
            .tint(MilliColors.cyanGlow)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.035))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                    }
            )
    }
}

func onboardingToggle(label: String, isOn: Binding<Bool>) -> some View {
    HStack {
        Text(label)
            .font(MilliFont.bodyMedium)
            .foregroundStyle(MilliColors.textPrimary)
        Spacer()
        Toggle("", isOn: isOn)
            .tint(MilliColors.cyanGlow)
            .labelsHidden()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 11)
    .background(
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(Color.white.opacity(0.03))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
            }
    )
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
