import SwiftUI

// MARK: - PlanSelectionView — Onboarding Step 4
// Selects the product tier only. Billing/trial activation is intentionally kept
// out of onboarding until the production subscription checkout is connected.

struct PlanSelectionView: View {
    @Binding var selectedPlan: MilliPlan
    var onComplete: () -> Void
    var onBack: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(spacing: 10) {
                    ForEach(MilliPlan.allCases, id: \.self) { plan in
                        planCard(plan: plan)
                    }
                }

                HStack(spacing: 12) {
                    OnboardingBackButton(action: onBack)
                    OnboardingPrimaryButton(title: "Continue", action: onComplete)
                }
                .padding(.top, 4)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, 24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CHOOSE YOUR PLAN")
                .font(MilliFont.sectionLabel)
                .tracking(1.0)
                .foregroundStyle(MilliColors.cyanGlow)

            Text("How much should Milli automate?")
                .font(.custom("Sora-Bold", size: 29, relativeTo: .largeTitle))
                .foregroundStyle(MilliColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Pick the experience that fits your workflow. Billing is confirmed separately when production checkout is connected.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func planCard(plan: MilliPlan) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(plan.rawValue)
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.textPrimary)

                            if plan.isPopular {
                                Text("POPULAR")
                                    .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                                    .tracking(0.6)
                                    .foregroundStyle(MilliColors.cyanGlow)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(MilliColors.cyanGlow.opacity(0.09)))
                            }
                        }

                        Text(plan.monthlyPrice)
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(isSelected ? MilliColors.cyanGlow : Color.white.opacity(0.16), lineWidth: 1.5)
                            .frame(width: 23, height: 23)
                        if isSelected {
                            Circle()
                                .fill(MilliColors.cyanGlow)
                                .frame(width: 13, height: 13)
                                .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 4)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 7) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(MilliColors.cyanGlow)
                                .padding(.top, 2)
                            Text(feature)
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [MilliColors.cyanGlow.opacity(0.075), Color(hex: "0A1116")]
                                : [Color.white.opacity(0.028), Color.white.opacity(0.016)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                            .stroke(isSelected ? MilliColors.cyanGlow.opacity(0.36) : Color.white.opacity(0.065), lineWidth: 0.8)
                    }
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.07) : .clear, radius: 9)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
