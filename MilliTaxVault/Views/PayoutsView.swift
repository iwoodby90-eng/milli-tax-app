import SwiftUI

// MARK: - PayoutsView
// Banking-grade payout history powered by live Stripe Financial Connections & Plaid Link bank aggregation.
// Automatically pulls real-time direct deposits and gig payouts with verified financial receipts.

struct PayoutsView: View {
    @StateObject private var bankService = BankConnectionService.shared
    @State private var selectedFilter: PayoutFilter = .all
    @State private var selectedPayout: VerifiedPayout?
    @State private var showBankConnectSheet = false
    @State private var showManagePlatformsSheet = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                header
                bankConnectionCard
                filterControl
                payoutList
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(item: $selectedPayout) { payout in
            FinancialReceiptSheet(payout: payout)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBankConnectSheet) {
            BankConnectionSheet(service: bankService)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showManagePlatformsSheet) {
            GigPlatformManagerSheet(service: bankService)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 4) {
            Text("Payouts")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)
            
            Text("Total \(currency(bankService.totalPayoutsAmount))")
                .font(MilliFont.bodyMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(MilliCardBackground(showGlow: true))
    }

    // MARK: - Bank Connection Card
    private var bankConnectionCard: some View {
        VStack(spacing: 10) {
            if let bank = bankService.connectedBank {
                // Connected Bank State
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "0C252E"))
                            .frame(width: 42, height: 42)
                            .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.35), lineWidth: 1))

                        Image(systemName: bank.provider.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(bank.institutionName)
                                .font(.custom("Sora-SemiBold", size: 14))
                                .foregroundStyle(MilliColors.textPrimary)

                            Text("•••• \(bank.accountMask)")
                                .font(.custom("Inter-Regular", size: 12))
                                .foregroundStyle(MilliColors.textSecondary)
                        }

                        HStack(spacing: 6) {
                            // LAUNCH P0: no "STRIPE SECURED" claim without a
                            // live provider connection; show CACHED instead.
                            Text(bank.isLive ? bank.provider.badgeTitle : "CACHED")
                                .font(.custom("Inter-Bold", size: 9))
                                .tracking(0.4)
                                .foregroundStyle(bank.isLive ? MilliColors.positive : MilliColors.textTertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(bank.isLive ? MilliColors.positive.opacity(0.12) : MilliColors.textTertiary.opacity(0.10)))

                            if bankService.isSyncing {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                    Text("Syncing...")
                                        .font(.custom("Inter-Regular", size: 10))
                                        .foregroundStyle(MilliColors.cyanGlow)
                                }
                            } else {
                                Text("Synced \(timeAgo(bank.lastSyncedAt))")
                                    .font(.custom("Inter-Regular", size: 10))
                                    .foregroundStyle(MilliColors.textTertiary)
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button {
                            bankService.syncTransactions()
                        } label: {
                            Label("Sync Payouts Now", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button {
                            showManagePlatformsSheet = true
                        } label: {
                            Label("Manage Gig Platforms", systemImage: "car.2.fill")
                        }

                        Button {
                            showBankConnectSheet = true
                        } label: {
                            Label("Switch Bank Account", systemImage: "arrow.left.arrow.right")
                        }

                        Divider()

                        Button(role: .destructive) {
                            bankService.disconnectBank()
                        } label: {
                            Label("Disconnect Bank", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(MilliColors.cyanGlow.opacity(0.85))
                            .padding(6)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0C1A22"), Color(hex: "060E12")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                                .stroke(MilliColors.cyanGlow.opacity(0.30), lineWidth: 0.8)
                        }
                )
            } else {
                // Not Connected Bank State
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(MilliColors.cyanGlow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect Bank via Stripe or Plaid")
                                .font(.custom("Sora-SemiBold", size: 14))
                                .foregroundStyle(MilliColors.textPrimary)

                            Text("Pull live direct deposits and automate tax vault allocations.")
                                .font(.custom("Inter-Regular", size: 11))
                                .foregroundStyle(MilliColors.textSecondary)
                        }

                        Spacer()
                    }

                    Button {
                        showBankConnectSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "building.columns.fill")
                            Text("Connect Bank Account")
                        }
                        .font(.custom("Inter-SemiBold", size: 13))
                        .foregroundStyle(MilliColors.blackGlass)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(MilliColors.cyanGlow)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .fill(MilliColors.graphiteSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                                .stroke(MilliColors.focusedBorder, lineWidth: 0.75)
                        }
                )
            }
        }
    }

    // MARK: - Filter Control
    private var filterControl: some View {
        HStack(spacing: 4) {
            ForEach(PayoutFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(selectedFilter == filter ? MilliColors.blackGlass : MilliColors.cyanGlow.opacity(0.84))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? MilliColors.cyanGlow : Color.clear)
                                .shadow(
                                    color: selectedFilter == filter ? MilliColors.cyanGlow.opacity(0.25) : .clear,
                                    radius: 7
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(hex: "0C252E"))
                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 0.7))
        )
    }

    // MARK: - Payout List
    @ViewBuilder
    private var payoutList: some View {
        if filteredPayouts.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(MilliColors.textTertiary)
                Text("No payouts in this view")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                
                if bankService.connectedBank == nil {
                    Button("Connect Bank to Sync Payouts") {
                        showBankConnectSheet = true
                    }
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(MilliColors.cyanGlow)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .milliCard()
        } else {
            LazyVStack(spacing: 8) {
                ForEach(filteredPayouts) { payout in
                    Button {
                        selectedPayout = payout
                    } label: {
                        payoutRow(payout)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filteredPayouts: [VerifiedPayout] {
        switch selectedFilter {
        case .all:
            return bankService.payouts
        case .thisWeek:
            return bankService.payouts.filter(\.isThisWeek)
        case .pending:
            return bankService.payouts.filter(\.isPending)
        }
    }

    private func payoutRow(_ payout: VerifiedPayout) -> some View {
        HStack(spacing: 12) {
            platformMark(payout)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(payout.platform)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)

                    if payout.isPending {
                        Text("PENDING")
                            .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                            .tracking(0.5)
                            .foregroundStyle(MilliColors.warning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(MilliColors.warning.opacity(0.12)))
                    }
                }

                HStack(spacing: 4) {
                    Text(payout.dateLabel)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)

                    Text("• ACH ···\(payout.bankMask)")
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(currency(payout.grossAmount))")
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)

                // LAUNCH P0: no "protected" claim without backend authority.
                Text("CACHED")
                    .font(.custom("Inter-Medium", size: 10))
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.7)
                }
        )
    }

    private func platformMark(_ payout: VerifiedPayout) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(payout.platformColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(payout.platformColor.opacity(0.35), lineWidth: 0.75)
                }

            if let asset = payout.assetName, UIImage(named: asset) != nil {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                Text(payout.platformInitial)
                    .font(.custom("Sora-Bold", size: 15))
                    .foregroundStyle(payout.platformColor)
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}

// MARK: - Financial Receipt Sheet

// MARK: - FinancialReceiptSheet (state-contract receipt)
// LAUNCH P0: the legacy receipt celebrated unconfirmed transactions
// ("Taxes Protected", "Settled via Autopilot") from client-side data with no
// backend authority. It now renders through the state contract: a locally
// cached payout record without backend confirmation is CACHED, never
// POSTED/PROTECTED/SETTLED. Production payouts are empty until a real
// provider is connected, so this path is effectively dormant.

struct FinancialReceiptSheet: View {
    let payout: AutopilotPayout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Receipt state must match actual authority.
                    HStack {
                        PayoutStateBadge(state: payout.state)
                        Spacer()
                        ProvenanceTag(label: payout.provenance)
                    }

                    receiptCard

                    if payout.state.isFailureBranch {
                        failureGuidance
                    }

                    // Tax Vault rule: no "Tax Protected" treatment until
                    // authoritative allocation succeeds.
                    if payout.state == .allocated {
                        Text("Tax Vault allocation confirmed by the backend. Funds are protected.")
                            .font(.custom("Inter-Regular", size: 11))
                            .foregroundStyle(MilliColors.positive)
                    } else {
                        Text("Funds remain part of the operating balance until the Tax Vault allocation is confirmed.")
                            .font(.custom("Inter-Regular", size: 11))
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.vertical, 16)
            }
            .background(MilliColors.background.ignoresSafeArea())
            .navigationTitle("Financial Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }

    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            receiptLine("Payout ID", payout.id)
            receiptLine("Platform", payout.platform)
            receiptLine("Gross amount", centsString(payout.grossAmountCents))
            receiptLine("State", payout.state.receiptHeadline)
            if let date = payout.detectedAt {
                receiptLine("Detected", date.formatted(date: .abbreviated, time: .shortened))
            }
            if let date = payout.allocatedAt {
                receiptLine("Allocated", date.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(Color(hex: "0C1A22"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.25), lineWidth: 0.8)
                )
        )
    }

    private var failureGuidance: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("This payout needs attention", systemImage: "exclamationmark.circle")
                .font(.custom("Sora-SemiBold", size: 13))
                .foregroundStyle(MilliColors.warning)
            Text(failureMessage)
                .font(.custom("Inter-Regular", size: 12))
                .foregroundStyle(MilliColors.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.warning.opacity(0.08))
        )
    }

    private var failureMessage: String {
        switch payout.state {
        case .failed: return "The automatic tax allocation failed. The funds stay in the operating balance; nothing was moved."
        case .returned: return "The payout was returned by the provider. No funds were allocated."
        case .reversed: return "A previously posted allocation was reversed by the backend."
        case .actionRequired: return "The provider requires additional information before this payout can be processed."
        case .unavailable: return "Payout details are temporarily unavailable from the provider."
        default: return ""
        }
    }

    private func receiptLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.custom("Inter-Medium", size: 10))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textTertiary)
            Spacer()
            Text(value)
                .font(.custom("Inter-SemiBold", size: 12))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
    }

    private func centsString(_ cents: Int64) -> String {
        String(format: "$%.2f", Double(cents) / 100)
    }
}

// MARK: - Bank Connection Sheet

private struct BankConnectionSheet: View {
    @ObservedObject var service: BankConnectionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider: BankConnectionProvider = .stripeFinancialConnections
    @State private var selectedInstitution: BankInstitution = BankInstitution.standardInstitutions[0]
    @State private var accountMask: String = "4821"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    providerSelector
                    institutionList
                    accountNumberField
                    connectButton
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.vertical, 16)
            }
            .background(MilliColors.background.ignoresSafeArea())
            .navigationTitle("Connect Bank Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }

    private var providerSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONNECTION METHOD")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 8) {
                ForEach(BankConnectionProvider.allCases) { provider in
                    Button {
                        selectedProvider = provider
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: provider.iconName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(selectedProvider == provider ? MilliColors.cyanGlow : MilliColors.textSecondary)

                            Text(provider.rawValue)
                                .font(.custom("Inter-Medium", size: 11))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(selectedProvider == provider ? MilliColors.textPrimary : MilliColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedProvider == provider {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(hex: "0C252E"))
                                } else {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(MilliColors.graphiteSurface)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedProvider == provider ? MilliColors.cyanGlow : Color.white.opacity(0.06), lineWidth: 1)
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var institutionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELECT FINANCIAL INSTITUTION")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 6) {
                ForEach(BankInstitution.standardInstitutions) { inst in
                    Button {
                        selectedInstitution = inst
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: inst.logoIcon)
                                .font(.system(size: 16))
                                .foregroundStyle(selectedInstitution == inst ? MilliColors.cyanGlow : MilliColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.white.opacity(0.04)))

                            Text(inst.name)
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundStyle(MilliColors.textPrimary)

                            Spacer()

                            if selectedInstitution == inst {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MilliColors.cyanGlow)
                            }
                        }
                        .padding(12)
                        .background(
                            Group {
                                if selectedInstitution == inst {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(hex: "0C2028"))
                                } else {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(MilliColors.graphiteSurface)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selectedInstitution == inst ? MilliColors.cyanGlow.opacity(0.4) : Color.white.opacity(0.04), lineWidth: 0.8)
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var accountNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST 4 DIGITS OF ACCOUNT")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            TextField("4821", text: $accountMask)
                .keyboardType(.numberPad)
                .font(.custom("Sora-SemiBold", size: 16))
                .foregroundStyle(MilliColors.textPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MilliColors.graphiteSurface)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
        }
    }

    private var connectButton: some View {
        Button {
            service.connectBank(institution: selectedInstitution, provider: selectedProvider, accountMask: accountMask.isEmpty ? "4821" : accountMask)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                if service.isConnecting {
                    ProgressView()
                } else {
                    Image(systemName: "lock.shield.fill")
                    Text("Authenticate & Connect via \(selectedProvider == .stripeFinancialConnections ? "Stripe" : "Plaid")")
                }
            }
            .font(.custom("Inter-SemiBold", size: 14))
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MilliColors.cyanGlow)
            )
        }
        .buttonStyle(.plain)
        .disabled(service.isConnecting)
    }
}

// MARK: - Gig Platform Manager Sheet

private struct GigPlatformManagerSheet: View {
    @ObservedObject var service: BankConnectionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("CONNECTED GIG PLATFORMS")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundStyle(MilliColors.textSecondary)

                    VStack(spacing: 8) {
                        ForEach(service.linkedPlatforms) { platform in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(hex: platform.primaryColorHex).opacity(0.2))
                                        .frame(width: 36, height: 36)

                                    if let asset = platform.assetName, UIImage(named: asset) != nil {
                                        Image(asset)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Text(String(platform.name.prefix(1)))
                                            .font(.custom("Sora-Bold", size: 14))
                                            .foregroundStyle(Color(hex: platform.primaryColorHex))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(platform.name)
                                        .font(.custom("Inter-SemiBold", size: 14))
                                        .foregroundStyle(MilliColors.textPrimary)

                                    Text(platform.isConnected ? "Auto-syncing direct deposits" : "Disconnected")
                                        .font(.custom("Inter-Regular", size: 11))
                                        .foregroundStyle(platform.isConnected ? MilliColors.positive : MilliColors.textTertiary)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { platform.isConnected },
                                    set: { _ in service.togglePlatform(id: platform.id) }
                                ))
                                .tint(MilliColors.cyanGlow)
                                .labelsHidden()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(MilliColors.graphiteSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 0.8)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.vertical, 16)
            }
            .background(MilliColors.background.ignoresSafeArea())
            .navigationTitle("Gig Platform Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }
}

// MARK: - PayoutFilter Enum

private enum PayoutFilter: String, CaseIterable {
    case all
    case thisWeek
    case pending

    var title: String {
        switch self {
        case .all: return "All"
        case .thisWeek: return "This Week"
        case .pending: return "Pending"
        }
    }
}
