import SwiftUI

// MARK: - OnboardingFlowView — Multi-Step Setup Container
// 4 steps: Welcome → Vehicle → Tax Profile → Plan Selection
// Persists data and triggers hasCompletedSetup on completion.

struct OnboardingFlowView: View {
    @State private var currentStep: Int = 0
    @State private var vehicle = VehicleProfile()
    @State private var taxProfile = TaxProfile()
    @State private var selectedPlan: MilliPlan = .pro
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            MilliColors.obsidian.ignoresSafeArea()
            
            // Subtle radial glow
            RadialGradient(
                colors: [MilliColors.cyan.opacity(0.04), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, MilliLayout.screenMargin)
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        VehicleSetupView(
                            vehicle: $vehicle,
                            onNext: { withAnimation { currentStep = 2 } },
                            onBack: { withAnimation { currentStep = 0 } }
                        )
                    case 2:
                        TaxProfileSetupView(
                            taxProfile: $taxProfile,
                            onNext: { withAnimation { currentStep = 3 } },
                            onBack: { withAnimation { currentStep = 1 } }
                        )
                    case 3:
                        PlanSelectionView(
                            selectedPlan: $selectedPlan,
                            onComplete: { saveAndComplete() },
                            onBack: { withAnimation { currentStep = 2 } }
                        )
                    default:
                        welcomeStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<4) { step in
                Capsule()
                    .fill(step <= currentStep ? MilliColors.cyan : Color.white.opacity(0.12))
                    .frame(height: 3)
                    .animation(.easeOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step 0: Welcome
    private var welcomeStep: some View {
        VStack(spacing: MilliSpacing.xxl) {
            Spacer()
            
            // Milli logo mark — chrome ring with M
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [MilliColors.cyan.opacity(0.6), MilliColors.cyan.opacity(0.1), MilliColors.cyan.opacity(0.6)],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                Text("M")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(MilliColors.cyan)
            }
            
            VStack(spacing: MilliSpacing.md) {
                Text("Welcome to Milli")
                    .font(MilliFont.heroBalance)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Let's set up your profile so we can\nmaximize your tax savings from day one.")
                    .font(MilliFont.body)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            OnboardingPrimaryButton(title: "Get Started") {
                withAnimation { currentStep = 1 }
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Save & Complete
    private func saveAndComplete() {
        // Encode and persist vehicle + tax profile
        if let vehicleData = try? JSONEncoder().encode(vehicle) {
            UserDefaults.standard.set(vehicleData, forKey: "onboarding_vehicle")
        }
        if let taxData = try? JSONEncoder().encode(taxProfile) {
            UserDefaults.standard.set(taxData, forKey: "onboarding_taxProfile")
        }
        UserDefaults.standard.set(selectedPlan.rawValue, forKey: "onboarding_plan")
        
        onComplete()
    }
}

// MARK: - Shared Onboarding UI Components

struct OnboardingPrimaryButton: View {
    let title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyan, MilliColors.cyan.opacity(0.8)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: MilliColors.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
    }
}

struct OnboardingBackButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
        }
    }
}

// MARK: - Reusable onboarding form helpers (free functions for use across step views)

func onboardingTextField(label: String, placeholder: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: MilliSpacing.sm) {
        Text(label)
            .font(MilliFont.sectionLabel)
            .foregroundStyle(MilliColors.textSecondary)
        TextField(placeholder, text: text)
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

func onboardingToggle(label: String, isOn: Binding<Bool>) -> some View {
    HStack {
        Text(label)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
        Spacer()
        Toggle("", isOn: isOn)
            .tint(MilliColors.cyan)
            .labelsHidden()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    )
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
