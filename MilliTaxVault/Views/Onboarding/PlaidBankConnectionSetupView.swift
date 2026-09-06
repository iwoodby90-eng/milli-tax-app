import SwiftUI
import LinkKit

// MARK: - Plaid-powered required bank onboarding step
// Fetches a one-time Link token from MILLI's backend, presents native Plaid Link,
// exchanges the returned public token server-side, then hydrates the connected
// account snapshot. Plaid access tokens never enter the iOS process.

struct PlaidBankConnectionSetupView: View {
    @Binding var profile: BankAutopilotProfile
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var linkSession: PlaidLinkSession?
    @State private var isPresentingLink = false
    @State private var isPreparingLink = false
    @State private var connectionError: String?

    private let preferredPlatforms: [GigPlatform] = [
        .amazonFlex, .sparkDriver, .uber, .lyft, .doorDash,
        .grubhub, .instacart, .roadie, .shipt
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("BANK + PAYOUT DETECTION")
                        .font(MilliFont.sectionLabel)
                        .tracking(1.0)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Connect where your gig payouts land.")
                        .font(.custom("Sora-Bold", size: 28, relativeTo: .largeTitle))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Milli securely connects through Plaid, then monitors the connected account for eligible gig-company payouts so the matching Tax Vault reserve can be calculated automatically.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                payoutAccountCard
                gigSourcesCard
                permissionsCard

                HStack(spacing: 12) {
                    OnboardingBackButton(action: onBack)
                    OnboardingPrimaryButton(title: "Continue", action: onNext)
                        .opacity(profile.isReadyForAutopilot ? 1 : 0.38)
                        .allowsHitTesting(profile.isReadyForAutopilot)
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, 22)
        }
        .sheet(isPresented: $isPresentingLink) {
            if let linkSession {
                linkSession.sheet()
            } else {
                ProgressView("Preparing secure bank connection…")
                    .tint(MilliColors.cyanGlow)
                    .preferredColorScheme(.dark)
            }
        }
        .alert("Bank connection needs attention", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                connectionError = nil
            }
        } message: {
            Text(connectionError ?? "Please try again.")
        }
    }

    private var payoutAccountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PAYOUT ACCOUNT").sectionHeaderStyle()
                Spacer()
                Text(statusLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(statusColor)
            }

            Button {
                Task { await prepareAndOpenPlaid() }
            } label: {
                HStack(spacing: 10) {
                    if isPreparingLink || profile.connectionStatus == .connecting {
                        ProgressView()
                            .tint(MilliColors.blackGlass)
                            .controlSize(.small)
                    } else {
                        Image(systemName: profile.connectionStatus == .connected ? "checkmark.shield.fill" : "building.columns.fill")
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(profile.connectionStatus == .connected ? connectedBankTitle : "Connect Bank with Plaid")
                            .font(MilliFont.headlineSmall)
                        if profile.connectionStatus == .connected {
                            Text("Plaid verified • transaction sync enabled")
                                .font(MilliFont.caption)
                                .opacity(0.72)
                        }
                    }

                    Spacer()
                    Image(systemName: profile.connectionStatus == .connected ? "checkmark.seal.fill" : "chevron.right")
                }
                .foregroundStyle(MilliColors.blackGlass)
                .padding(.horizontal, 13)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 11).fill(MilliColors.cyanGlow))
            }
            .buttonStyle(.plain)
            .disabled(isPreparingLink || profile.connectionStatus == .connecting)

            HStack(spacing: 7) {
                Image(systemName: "lock.shield.fill")
                Text("Secured by Plaid • Milli never sees or stores your bank password")
            }
            .font(MilliFont.caption)
            .foregroundStyle(MilliColors.textTertiary)
        }
        .milliCard(padding: 13)
    }

    private var gigSourcesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("GIG PAYOUT SOURCES").sectionHeaderStyle()
                Spacer()
                Toggle("", isOn: $profile.autoDetectPlatforms)
                    .labelsHidden()
                    .tint(MilliColors.cyanGlow)
            }

            Text("Confirm the companies you drive or deliver for. Auto-detect uses this as a high-confidence filter when matching bank deposits.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(preferredPlatforms) { platform in
                    let selected = profile.selectedPlatforms.contains(platform)
                    Button {
                        if selected { profile.selectedPlatforms.remove(platform) }
                        else { profile.selectedPlatforms.insert(platform) }
                    } label: {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(selected ? MilliColors.cyanGlow : Color.white.opacity(0.08))
                                .frame(width: 8, height: 8)
                            Text(platform.rawValue)
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(selected ? MilliColors.textPrimary : MilliColors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(selected ? MilliColors.cyanGlow.opacity(0.08) : Color.white.opacity(0.025))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .milliCard(padding: 13)
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOPILOT PERMISSIONS").sectionHeaderStyle()
            onboardingToggle(label: "Detect gig payouts", isOn: $profile.transactionMonitoringConsent)
            onboardingToggle(label: "Move calculated tax reserve to Milli Tax Vault™", isOn: $profile.taxVaultTransferConsent)
        }
        .milliCard(padding: 13)
    }

    private var statusLabel: String {
        switch profile.connectionStatus {
        case .notConnected: return "REQUIRED"
        case .connecting: return "CONNECTING"
        case .connected: return "CONNECTED"
        case .needsAttention: return "ATTENTION"
        }
    }

    private var statusColor: Color {
        switch profile.connectionStatus {
        case .connected: return MilliColors.positive
        case .connecting: return MilliColors.cyanGlow
        case .notConnected, .needsAttention: return MilliColors.warning
        }
    }

    private var connectedBankTitle: String {
        let institution = profile.institutionName.isEmpty ? "Bank" : profile.institutionName
        let account = profile.accountName.isEmpty ? "Checking" : profile.accountName
        let mask = profile.accountLastFour.isEmpty ? "" : " ••••\(profile.accountLastFour)"
        return "\(institution) \(account)\(mask)"
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { connectionError != nil },
            set: { if !$0 { connectionError = nil } }
        )
    }

    @MainActor
    private func prepareAndOpenPlaid() async {
        guard !isPreparingLink else { return }

        isPreparingLink = true
        profile.connectionStatus = .connecting
        connectionError = nil

        do {
            let linkToken = try await PlaidAPIClient.shared.createLinkToken()
            let configuration = LinkTokenConfiguration(
                token: linkToken,
                onSuccess: { success in
                    isPresentingLink = false
                    Task { @MainActor in
                        await completePlaidConnection(success)
                    }
                },
                onExit: { exit in
                    isPresentingLink = false
                    isPreparingLink = false
                    if let error = exit.error {
                        profile.connectionStatus = .needsAttention
                        connectionError = error.displayMessage ?? error.errorMessage
                    } else if profile.connectionStatus != .connected {
                        profile.connectionStatus = .notConnected
                    }
                },
                onEvent: nil,
                onLoad: {
                    isPreparingLink = false
                }
            )

            linkSession = try Plaid.createPlaidLinkSession(configuration: configuration)
            isPresentingLink = true
        } catch {
            isPreparingLink = false
            profile.connectionStatus = .needsAttention
            connectionError = error.localizedDescription
        }
    }

    @MainActor
    private func completePlaidConnection(_ success: LinkSuccess) async {
        isPreparingLink = true
        profile.connectionStatus = .connecting

        do {
            guard let publicToken = success.publicToken else {
                throw PlaidAPIClient.ClientError.invalidResponse
            }

            let institutionID = success.metadata.institution?.id
            let institutionName = success.metadata.institution?.name

            try await PlaidAPIClient.shared.exchangePublicToken(
                publicToken,
                institutionID: institutionID,
                institutionName: institutionName
            )

            let accounts = try await PlaidAPIClient.shared.fetchAccounts()
            let preferred = accounts.first(where: { account in
                let subtype = account.subtype?.lowercased() ?? ""
                return subtype.contains("checking")
            }) ?? accounts[0]

            profile.institutionName = preferred.institutionName ?? institutionName ?? "Connected Bank"
            profile.accountName = preferred.name ?? "Primary Account"
            profile.accountLastFour = preferred.mask ?? ""
            profile.connectionStatus = .connected
            isPreparingLink = false
        } catch {
            isPreparingLink = false
            profile.connectionStatus = .needsAttention
            connectionError = error.localizedDescription
        }
    }
}
