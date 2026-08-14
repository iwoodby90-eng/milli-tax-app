import SwiftUI

// MARK: - VehicleSetupView — Onboarding Step 2
// Collects vehicle year/make/model and usage type.

struct VehicleSetupView: View {
    @Binding var vehicle: VehicleProfile
    var onNext: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MilliSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                    Text("Your Vehicle")
                        .font(MilliFont.heroNumber)
                        .foregroundStyle(.white)
                    Text("We'll use this to calculate your mileage deductions.")
                        .font(MilliFont.body)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                .padding(.top, MilliSpacing.xxl)
                
                // Form fields
                VStack(spacing: MilliSpacing.lg) {
                    onboardingTextField(label: "Year", placeholder: "2024", text: $vehicle.year)
                        .keyboardType(.numberPad)
                    onboardingTextField(label: "Make", placeholder: "Honda", text: $vehicle.make)
                    onboardingTextField(label: "Model", placeholder: "Accord", text: $vehicle.model)
                    onboardingTextField(label: "Current Odometer", placeholder: "45,000", text: $vehicle.odometerReading)
                        .keyboardType(.numberPad)
                    
                    // Vehicle use selector
                    VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                        Text("Vehicle Use")
                            .font(MilliFont.sectionLabel)
                            .foregroundStyle(MilliColors.textSecondary)
                        
                        HStack(spacing: MilliSpacing.sm) {
                            ForEach(VehicleProfile.VehicleUse.allCases, id: \.self) { use in
                                Button(action: { vehicle.vehicleUse = use }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: use.icon)
                                            .font(.system(size: 12))
                                        Text(use.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundStyle(vehicle.vehicleUse == use ? .white : MilliColors.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(vehicle.vehicleUse == use ? MilliColors.cyan.opacity(0.15) : Color.clear)
                                            .overlay(
                                                Capsule()
                                                    .stroke(vehicle.vehicleUse == use ? MilliColors.cyan : Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                
                Spacer().frame(height: 60)
                
                // Navigation buttons
                HStack(spacing: MilliSpacing.md) {
                    OnboardingBackButton(action: onBack)
                    OnboardingPrimaryButton(title: "Continue", action: onNext)
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    VehicleSetupView(
        vehicle: .constant(VehicleProfile()),
        onNext: {},
        onBack: {}
    )
    .background(MilliColors.obsidian.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
