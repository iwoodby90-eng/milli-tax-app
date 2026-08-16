import SwiftUI

// MARK: - SubscriptionView
// Native plan selection surface for Milli's confirmed Basic / Pro / Elite tiers.
// The UI does not claim a purchase occurred until production billing is connected.

struct SubscriptionView: View {
    var onBack: () -> Void = {}

    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var showBillingSetup = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                planHero
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

            Text("Choose how much Milli automates")
                .font(MilliFont.headline)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Every plan keeps taxes and mileage at the center. Higher tiers add more preparation and automation around wealth and filing.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .milliCard(padding: 14)
    }

    private var planSelector: some View {
        HStack(spacing: 7) {
            ForEach(SubscriptionPlan.allCases) { plan in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedPlan = plan
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(plan.title)
                            .font(MilliFont.labelLarge)
                            .foregroundStyle(selectedPlan == plan ? MilliColors.blackGlass : MilliColors.textPrimary)
                        Text(plan.price)
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(selectedPlan == plan ? MilliColors.blackGlass : plan.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(selectedPlan == plan ? plan.accent : MilliColors.graphiteSurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(selectedPlan == plan ? plan.accent : Color.white.opacity(0.06), lineWidth: 0.8)
                            }
                            .shadow(color: selectedPlan == plan ? plan.accent.opacity(0.18) : .clear, radius: 8)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(plan.title), \(plan.price) per month")
            }
        }
    }

    private var selectedPlanDetails: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedPlan.title.uppercased())
                        .font(MilliFont.sectionLabel)
                        .tracking(1.0)
                        .foregroundStyle(selectedPlan.accent)
                    Text(selectedPlan.price)
                        .font(MilliFont.numericLarge)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                }
                Spacer()
                Text("/ month")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Divider().overlay(Color.white.opacity(0.06))

            ForEach(Array(selectedPlan.features.enumerated()), id: \.offset) { _, feature in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedPlan.accent)
                        .padding(.top, 1)
                    Text(feature)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }

            if selectedPlan == .basic {
                tierNote("Tax filing remains manual. Milli provides calculations, records and guidance.")
            } else if selectedPlan == .pro {
                tierNote("Milli can help prepare tax paperwork, but tax filing is not represented as automatic on Pro.")
            } else {
                tierNote("Elite filing and quarterly-payment automation require verified production tax/payment partners before they can be enabled.")
            }
        }
        .milliCard(padding: 14)
    }

    private func tierNote(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(MilliColors.textTertiary)
                .padding(.top, 1)
            Text(text)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }

    private var billingAction: some View {
        Button {
            showBillingSetup = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                Text("Continue with \(selectedPlan.title)")
            }
            .font(MilliFont.headlineSmall)
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(selectedPlan.accent)
                    .shadow(color: selectedPlan.accent.opacity(0.20), radius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var billingDisclosure: some View {
        Text("Plan selection is functional locally; subscription checkout is intentionally deferred until the production billing integration is connected. No charge is initiated from this build.")
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
                    .foregroundStyle(selectedPlan.accent)

                Text("Billing Integration Required")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("\(selectedPlan.title) is selected at \(selectedPlan.price) per month. Production checkout will be enabled when the billing provider, entitlement validation and App Store subscription configuration are connected.")
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
                        .fill(selectedPlan.accent)
                )
            }
            .padding(24)
        }
    }
}

private enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case basic
    case pro
    case elite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: return "Basic"
        case .pro: return "Pro"
        case .elite: return "Elite"
        }
    }

    var price: String {
        switch self {
        case .basic: return "$19.99"
        case .pro: return "$29.99"
        case .elite: return "$49.99"
        }
    }

    var accent: Color {
        switch self {
        case .basic: return MilliColors.silver
        case .pro: return MilliColors.cyanGlow
        case .elite: return MilliColors.warning
        }
    }

    var features: [String] {
        switch self {
        case .basic:
            return [
                "Automatic tax-reserve guidance for every payout",
                "GPS mileage tracking and deduction records",
                "Quarterly tax estimates and deadline tracking",
                "Income, expense and mileage reports",
                "Tax numbers and guidance while you file manually"
            ]
        case .pro:
            return [
                "Everything in Basic",
                "Retirement planning and contribution projections",
                "Investing access and portfolio views",
                "Wealth Overview and long-term planning tools",
                "Tax-document preparation assistance"
            ]
        case .elite:
            return [
                "Everything in Pro",
                "Annual tax-filing automation when the production filing partner is connected",
                "Quarterly tax-payment automation when the verified payment rail is connected",
                "Automated retirement and investing allocation options",
                "Elite filing/document workflow and priority financial automation"
            ]
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
