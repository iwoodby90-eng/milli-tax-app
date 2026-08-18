import SwiftUI

// MARK: - BankConnectionSetupView
// First-time onboarding step for the bank-linked Autopilot contract. The actual
// secure Link/Financial Connections session is supplied by the production backend.

struct BankConnectionSetupView: View {
    @Binding var profile: BankAutopilotProfile
    var onNext: () -> Void
    var onBack: () -> Void
    var onConnectBank: (() -> Void)? = nil

    @State private var showConnectionUnavailable = false

    private let preferredPlatforms: [GigPlatform] = [
        .amazonFlex, .sparkDriver, .uber, .lyft, .doorDash,
        .grubhub, .instacart, .roadie, .shipt
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                intro
                bankCard
                platformDetection
                consentCard

                HStack(spacing: 12) {
                    OnboardingBackButton(action: onBack)
                    OnboardingPrimaryButton(title: "Continue") {
                        onNext()
                    }
                    .opacity(profile.isReadyForAutopilot ? 1 : 0.38)
                    .allowsHitTesting(profile.isReadyForAutopilot)
                }
                .padding(.top, 4)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, 22)
        }
        .alert("Bank connection required", isPresented: $showConnectionUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The production bank-link service is not connected in this build yet. Milli will not pretend a bank account is linked until the secure provider session is live.")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("BANK + PAYOUT DETECTION")
                .font(MilliFont.sectionLabel)
                .tracking(1.0)
                .foregroundStyle(MilliColors.cyanGlow)

            Text("Connect where your gig payouts land.")
                .font(.custom("Sora-Bold", size: 28, relativeTo: .largeTitle))
                .foregroundStyle(MilliColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Milli uses the connected account's transaction feed to identify eligible gig-company payouts, calculate the configured tax reserve, and prepare the matching transfer into Milli Tax Vault™.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bankCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("PAYOUT ACCOUNT")
                    .sectionHeaderStyle()
                Spacer()
                connectionBadge
            }

            if profile.connectionStatus == .connected {
                HStack(spacing: 10) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(MilliColors.cyanGlow.opacity(0.09)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.institutionName.isEmpty ? "Connected bank" : profile.institutionName)
                            .font(MilliFont.headlineSmall)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text(accountSubtitle)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(MilliColors.positive)
                }
            } else {
                Button {
                    if let onConnectBank {
                        onConnectBank()
                    } else {
                        showConnectionUnavailable = true
                    }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Connect Bank Securely")
                            .font(MilliFont.headlineSmall)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(MilliColors.blackGlass)
                    .padding(.horizontal, 13)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(MilliColors.cyanGlow)
                            .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 8)
                    )
                }
                .buttonStyle(.plain)
            }

            Text("Use the checking account where Amazon Flex, Spark, Uber, DoorDash, Instacart, or other gig payouts are deposited.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 13)
    }

    private var platformDetection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("GIG PAYOUT SOURCES")
                    .sectionHeaderStyle()
                Spacer()
                Toggle("", isOn: $profile.autoDetectPlatforms)
                    .labelsHidden()
                    .tint(MilliColors.cyanGlow)
            }

            Text(profile.autoDetectPlatforms
                 ? "Auto-detect is on. Confirm the companies you currently drive or deliver for so Milli can match bank transactions more accurately."
                 : "Choose the companies you want Milli to monitor in the connected payout account.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(preferredPlatforms) { platform in
                    platformButton(platform)
                }
            }
        }
        .milliCard(padding: 13)
    }

    private func platformButton(_ platform: GigPlatform) -> some View {
        let selected = profile.selectedPlatforms.contains(platform)

        return Button {
            if selected {
                profile.selectedPlatforms.remove(platform)
            } else {
                profile.selectedPlatforms.insert(platform)
            }
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(selected ? MilliColors.cyanGlow : Color.white.opacity(0.08))
                    .frame(width: 8, height: 8)
                Text(platform.rawValue)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(selected ? MilliColors.textPrimary : MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selected ? MilliColors.cyanGlow.opacity(0.08) : Color.white.opacity(0.025))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(selected ? MilliColors.cyanGlow.opacity(0.42) : Color.white.opacity(0.06), lineWidth: 0.7)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOPILOT PERMISSIONS")
                .sectionHeaderStyle()

            consentRow(
                title: "Detect gig payouts",
                subtitle: "Allow Milli to read transaction activity from the connected payout account.",
                isOn: $profile.transactionMonitoringConsent
            )

            consentRow(
                title: "Move the tax reserve",
                subtitle: "Authorize Milli to initiate the calculated reserve transfer into Milli Tax Vault™ after an eligible payout is confirmed.",
                isOn: $profile.taxVaultTransferConsent
            )

            if !profile.isReadyForAutopilot {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MilliColors.warning)
                        .padding(.top, 2)
                    Text("Bank connection and both permissions are required before automatic Tax Vault transfers can be enabled.")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .milliCard(padding: 13)
    }

    private func consentRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(subtitle)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(MilliColors.cyanGlow)
        }
    }

    private var connectionBadge: some View {
        let connected = profile.connectionStatus == .connected
        return HStack(spacing: 5) {
            Circle()
                .fill(connected ? MilliColors.positive : MilliColors.warning)
                .frame(width: 5, height: 5)
            Text(connected ? "CONNECTED" : "REQUIRED")
                .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                .tracking(0.6)
                .foregroundStyle(connected ? MilliColors.positive : MilliColors.warning)
        }
    }

    private var accountSubtitle: String {
        let lastFour = profile.accountLastFour.isEmpty ? "" : " •••• \(profile.accountLastFour)"
        return "\(profile.accountName)\(lastFour)"
    }
}
