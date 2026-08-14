import SwiftUI

// MARK: - PlanSelectionView — Onboarding Step 4
// User picks their subscription tier. Starts with 7-day free trial.

struct PlanSelectionView: View {
    @Binding var selectedPlan: MilliPlan
    var onComplete: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MilliSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                    Text("Choose Your Plan")
                        .font(MilliFont.heroNumber)
                        .foregroundStyle(.white)
                    Text("Start with a 7-day free trial. Cancel anytime.")
                        .font(MilliFont.body)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                .padding(.top, MilliSpacing.xxl)
                
                // Plan cards
                VStack(spacing: MilliSpacing.md) {
                    ForEach(MilliPlan.allCases, id: \.self) { plan in
                        planCard(plan: plan)
                    }
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                
                Spacer().frame(height: 60)
                
                // Navigation buttons
                HStack(spacing: MilliSpacing.md) {
                    OnboardingBackButton(action: onBack)
                    OnboardingPrimaryButton(title: "Start Free Trial", action: onComplete)
                }
                .padding(.horizontal, MilliLayout.screenMargin)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func planCard(plan: MilliPlan) -> some View {
        Button(action: { selectedPlan = plan }) {
            VStack(alignment: .leading, spacing: MilliSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(plan.rawValue)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                            if plan.isPopular {
                                Text("POPULAR")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(MilliColors.cyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(MilliColors.cyan.opacity(0.15))
                                    )
                            }
                        }
                        Text(plan.monthlyPrice)
                            .font(.system(size: 14))
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                    Spacer()
                    // Radio indicator
                    ZStack {
                        Circle()
                            .stroke(selectedPlan == plan ? MilliColors.cyan : Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if selectedPlan == plan {
                            Circle()
                                .fill(MilliColors.cyan)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(MilliColors.cyan)
                            Text(feature)
                                .font(.system(size: 13))
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }
                }
            }
            .padding(MilliSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(selectedPlan == plan ? MilliColors.cyan.opacity(0.04) : Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .stroke(selectedPlan == plan ? MilliColors.cyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanSelectionView(
        selectedPlan: .constant(.pro),
        onComplete: {},
        onBack: {}
    )
    .background(MilliColors.obsidian.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
