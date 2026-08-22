import SwiftUI

// MARK: - SubscriptionView
// Canonical StoreKit 2 subscription interface. Replaces legacy CockpitView wrapper.

public struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var selectedPlan: MilliPlan = .pro
    @State private var showBillingSetup = false

    private var onBack: () -> Void

    public init(onBack: @escaping () -> Void = {}) {
        self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                statusCard
                planSelector
                selectedPlanDetails
                billingAction
                restoreAction
                billingDisclosure
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, MilliLayoutSpacing.bottomContentClearance)
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

            Text("Subscription")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CURRENT MEMBERSHIP")
                    .sectionHeaderStyle()
                Spacer()
                Text(storeKit.currentTierBadge)
                    .font(MilliFont.caption)
                    .foregroundStyle(storeKit.hasActiveSubscription ? MilliColors.cyanGlow : MilliColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill((storeKit.hasActiveSubscription ? MilliColors.cyanGlow : MilliColors.warning).opacity(0.12))
                    )
            }

            Text(storeKit.statusDescription)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .milliCard(padding: 14)
    }

    private var planSelector: some View {
        HStack(spacing: 8) {
            ForEach(MilliPlan.allCases, id: \.self) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: MilliPlan) -> some View {
        let isSelected = plan == selectedPlan
        let accent = accent(for: plan)

        return Button {
            selectedPlan = plan
        } label: {
            VStack(spacing: 6) {
                if plan.isPopular {
                    Text("POPULAR")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(MilliColors.cyanGlow.opacity(0.15)))
                } else {
                    Text(" ")
                        .font(MilliFont.caption)
                        .padding(.vertical, 2)
                }

                Text(plan.rawValue)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)

                Text(storeKit.formattedPrice(for: plan))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(accent)

                Text(plan.trialLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MilliColors.cardBackground)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MilliColors.graphiteSurface)
                    }
                }
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
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
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
