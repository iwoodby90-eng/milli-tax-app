import SwiftUI
import StoreKit

// MARK: - SubscriptionView
// Plan management for Milli's Basic / Pro / Elite tiers. First-time onboarding
// owns the one-time three-day trial; this screen reflects that state, wires StoreKit 2
// in-app purchases, handles transaction verification, restores purchases, and manages App Store Pay.

struct SubscriptionView: View {
    var onBack: () -> Void = {}

    @StateObject private var storeKit = StoreKitService.shared
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

    private var isSubscribedViaAppStore: Bool {
        !storeKit.purchasedProductIDs.isEmpty
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
                restoreAction
                billingDisclosure
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showBillingSetup) {
            billingSetupSheet
                .presentationDetents([.medium, .large])
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

            Text("Plans & Subscriptions")
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
        if isSubscribedViaAppStore {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.positive)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(MilliColors.positive.opacity(0.10)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("APPLE APP STORE ACTIVE")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(MilliColors.positive)
                    Text("Subscribed to \(storeKit.activePlan?.rawValue ?? selectedPlan.rawValue) via Apple In-App Purchase")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .milliCard(padding: 11)
        } else if let trialState {
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
                Text(storeKit.formattedPrice(for: plan).replacingOccurrences(of: "/mo", with: ""))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
            }
            .foregroundStyle(isSelected ? MilliColors.blackGlass : MilliColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? accent : MilliColors.graphiteSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? accent.opacity(0.40) : Color.white.opacity(0.06), lineWidth: 0.8)
                    }
                    .shadow(color: isSelected ? accent.opacity(0.20) : .clear, radius: 7)
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedPlanDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedPlan.rawValue.uppercased())
                    .font(MilliFont.headline)
                    .foregroundStyle(MilliColors.textPrimary)
                Spacer()
                Text(storeKit.formattedPrice(for: selectedPlan))
                    .font(MilliFont.headline)
                    .foregroundStyle(accent(for: selectedPlan))
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(selectedPlan.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent(for: selectedPlan))
                            .padding(.top, 1)
                        Text(feature)
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
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
                if storeKit.isPurchasing {
                    ProgressView()
                        .tint(MilliColors.blackGlass)
                } else {
                    Image(systemName: "apple.logo")
                    Text("Subscribe with Apple Pay — \(storeKit.formattedPrice(for: selectedPlan))")
                }
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
        .disabled(storeKit.isPurchasing)
    }

    private var restoreAction: some View {
        Button {
            Task {
                await storeKit.restorePurchases()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                Text("Restore App Store Purchases")
                    .font(MilliFont.caption)
            }
            .foregroundStyle(MilliColors.textSecondary)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var billingDisclosure: some View {
        VStack(spacing: 4) {
            Text("Subscriptions renew automatically monthly through your Apple App Store account. Cancel anytime in Apple ID Subscriptions Settings at least 24 hours before the renewal date.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)

            if let error = storeKit.errorMessage {
                Text(error)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.warning)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }

    private var billingSetupSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(MilliColors.textPrimary)

                Text("Apple App Store Subscription")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("\(selectedPlan.rawValue) is ready for purchase at \(storeKit.formattedPrice(for: selectedPlan)). Your subscription includes a 3-day introductory free trial before regular monthly billing commences.")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task {
                        do {
                            _ = try await storeKit.purchase(plan: selectedPlan)
                            showBillingSetup = false
                        } catch {
                            storeKit.errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if storeKit.isPurchasing {
                            ProgressView()
                                .tint(MilliColors.blackGlass)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm with Apple Pay")
                        }
                    }
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.blackGlass)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(accent(for: selectedPlan))
                    )
                }
                .buttonStyle(.plain)
                .disabled(storeKit.isPurchasing)

                Button("Close") {
                    showBillingSetup = false
                }
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textTertiary)
                .padding(.top, 4)
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
