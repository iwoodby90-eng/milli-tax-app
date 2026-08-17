import SwiftUI

// MARK: - SubscriptionView
// Plan management for Milli's Basic / Pro / Elite tiers. First-time onboarding
// owns the one-time three-day trial; this screen reflects that state without
// inventing StoreKit purchases or resetting the trial when a user changes selection.

struct SubscriptionView: View {
    var onBack: () -> Void = {}

    @State private var selectedPlan: MilliPlan
    @State private var showBillingSetup = false

    init(onBack: @escaping () -> Void = {}) {
        self.onBack = onBack
        let rawPlan = UserDefaults.standard.string(forKey: "onboarding_plan") ?? MilliPlan.pro.rawValue
        _selectedPlan = State(initialValue: MilliPlan(rawValue: rawPlan) ?? .pro)
    }

    private var trialState: MilliTrialState? {
        MilliTrialState.current()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                planHero
                trialStatusCard
                planSelector
                selectedPlanDetails
                billingAction
                billingDisclosure
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showBillingSetup) {
            billingSetupSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Plans")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "crown.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MilliColors.warning)
                .frame(width: 34, height: 34)
        }
    }

    private var planHero: some View {
        VStack(spacing: 8) {
            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .blendMode(.screen)

            Text("Choose how much Milli automates")
                .font(MilliFont.headline)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Every new Milli account starts with one 3-day free trial of the plan selected during first-time onboarding.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .milliCard(padding: 14)
    }

    @ViewBuilder
    private var trialStatusCard: some View {
        if let trialState {
            HStack(spacing: 10) {
                Image(systemName: trialState.isActive ? "sparkles" : "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(trialState.isActive ? MilliColors.cyanGlow : MilliColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill((trialState.isActive ? MilliColors.cyanGlow : MilliColors.textTertiary).opacity(0.08)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(trialState.isActive ? "3-DAY FREE TRIAL ACTIVE" : "FREE TRIAL COMPLETED")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(trialState.isActive ? MilliColors.cyanGlow : MilliColors.textSecondary)
                    Text(trialState.isActive
                         ? "\(trialState.plan.rawValue) trial ends \(trialState.endsAt.formatted(date: .abbreviated, time: .shortened))"
                         : "The one-time \(trialState.plan.rawValue) trial has ended")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .milliCard(padding: 11)
        } else {
            HStack(spacing: 9) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(MilliColors.cyanGlow)
                Text("Your 3-day free trial begins after first-time onboarding is completed.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer(minLength: 0)
            }
            .milliCard(padding: 11)
        }
    }

    private var planSelector: some View {
        HStack(spacing: 7) {
            ForEach(MilliPlan.allCases, id: \.self) { plan in
                planButton(plan)
            }
        }
    }

    private func planButton(_ plan: MilliPlan) -> some View {
        let isSelected = selectedPlan == plan
        let accent = accent(for: plan)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedPlan = plan
            }
        } label: {
            VStack(spacing: 4) {
                Text(plan.rawValue)
                    .font(MilliFont.labelLarge)
                Text(plan.monthlyPrice.replacingOccurrences(of: "/mo", with: ""))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
            }
            .foregroundStyle(isSelected ? MilliColors.blackGlass : MilliColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? accent : MilliColors.graphiteSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(isSelected ? accent : Color.white.opacity(0.06), lineWidth: 0.8)
                    }
                    .shadow(color: isSelected ? accent.opacity(0.18) : .clear, radius: 8)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.rawValue), \(plan.monthlyPrice)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectedPlanDetails: some View {
        let accent = accent(for: selectedPlan)

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedPlan.rawValue.uppercased())
                        .font(MilliFont.sectionLabel)
                        .tracking(1.0)
                        .foregroundStyle(accent)
                    Text(selectedPlan.monthlyPrice)
                        .font(MilliFont.numericLarge)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                }
                Spacer()
                if selectedPlan.isPopular {
                    Text("POPULAR")
                        .font(MilliFont.caption)
                        .tracking(0.5)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }

            Divider().overlay(Color.white.opacity(0.06))

            ForEach(selectedPlan.features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                        .padding(.top, 1)
                    Text(feature)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(MilliColors.textTertiary)
                    .padding(.top, 1)
                Text(planNote(selectedPlan))
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .milliCard(padding: 14)
    }

    private var billingAction: some View {
        Button {
            showBillingSetup = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                Text("Manage \(selectedPlan.rawValue)")
            }
            .font(MilliFont.headlineSmall)
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(accent(for: selectedPlan))
                    .shadow(color: accent(for: selectedPlan).opacity(0.20), radius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var billingDisclosure: some View {
        Text("The selected plan and local trial state are persisted in the app. Actual App Store subscription purchase, renewal, cancellation, and introductory-offer eligibility require StoreKit products and App Store Connect configuration before release.")
            .font(MilliFont.caption)
            .foregroundStyle(MilliColors.textTertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
    }

    private var billingSetupSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(accent(for: selectedPlan))

                Text("StoreKit Setup Required")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("\(selectedPlan.rawValue) is selected at \(selectedPlan.monthlyPrice). Milli will only initiate a real subscription when the matching StoreKit product and App Store introductory offer are configured. This build does not fake a purchase or restart the free trial.")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Done") {
                    showBillingSetup = false
                }
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(accent(for: selectedPlan))
                )
            }
            .padding(24)
        }
    }

    private func accent(for plan: MilliPlan) -> Color {
        switch plan {
        case .basic: return MilliColors.silver
        case .pro: return MilliColors.cyanGlow
        case .elite: return MilliColors.warning
        }
    }

    private func planNote(_ plan: MilliPlan) -> String {
        switch plan {
        case .basic:
            return "Basic provides calculations, tracking, reports, and guidance; the user files taxes manually."
        case .pro:
            return "Pro adds retirement, investing, and tax-document preparation assistance; filing is not represented as automatic."
        case .elite:
            return "Elite annual filing and quarterly-payment automation require verified production tax and payment partners before execution can be enabled."
        }
    }
}

// Legacy compatibility wrapper while the old profile cockpit is retired.
struct CockpitView: View {
    var body: some View {
        SubscriptionView()
    }
}

#Preview {
    SubscriptionView()
        .preferredColorScheme(.dark)
}
