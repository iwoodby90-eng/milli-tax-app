import SwiftUI

// MARK: - TaxProfileSetupView — Onboarding Step 3
// Collects filing status, income, self-employment, multiple vehicles.

struct TaxProfileSetupView: View {
    @Binding var taxProfile: TaxProfile
    var onNext: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MilliSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                    Text("Tax Profile")
                        .font(MilliFont.heroNumber)
                        .foregroundStyle(.white)
                    Text("This helps Milli estimate your deductions accurately.")
                        .font(MilliFont.body)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                .padding(.top, MilliSpacing.xxl)
                
                // Filing status
                VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                    Text("Filing Status")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textSecondary)
                    
                    VStack(spacing: MilliSpacing.sm) {
                        ForEach(TaxProfile.FilingStatus.allCases, id: \.self) { status in
                            Button(action: { taxProfile.filingStatus = status }) {
                                HStack {
                                    Text(status.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(taxProfile.filingStatus == status ? .white : MilliColors.textSecondary)
                                    Spacer()
                                    if taxProfile.filingStatus == status {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(MilliColors.cyan)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(taxProfile.filingStatus == status ? MilliColors.cyan.opacity(0.08) : Color.white.opacity(0.03))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(taxProfile.filingStatus == status ? MilliColors.cyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                
                // Income field
                onboardingTextField(label: "Estimated Annual Income", placeholder: "$75,000", text: $taxProfile.estimatedAnnualIncome)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, MilliLayout.screenMargin)
                
                // Toggles
                VStack(spacing: MilliSpacing.md) {
                    onboardingToggle(label: "Self-Employed / 1099", isOn: $taxProfile.isSelfEmployed)
                    onboardingToggle(label: "Multiple Vehicles", isOn: $taxProfile.hasMultipleVehicles)
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
    TaxProfileSetupView(
        taxProfile: .constant(TaxProfile()),
        onNext: {},
        onBack: {}
    )
    .background(MilliColors.obsidian.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
