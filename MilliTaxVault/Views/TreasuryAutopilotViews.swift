import SwiftUI

// MARK: - Treasury Autopilot UI (Launch P0)
// Authoritative user experience for the Stripe Treasury Autopilot flow.
// SwiftUI does not determine financial truth: every state shown here is
// rendered from the backend/provider state contract (PayoutStateContract).
// Canonical nav is untouched — this module lives above it.

// MARK: - State Badge

struct PayoutStateBadge: View {
    let state: PayoutState

    private var title: String { state.receiptHeadline }
    private var color: Color {
        switch state {
        case .detected: return MilliColors.textSecondary
        case .processing: return MilliColors.cyanGlow
        case .allocated: return MilliColors.positive
        case .failed, .returned, .reversed, .actionRequired, .unavailable: return MilliColors.warning
        }
    }
    private var icon: String {
        switch state {
        case .detected: return "dot.radiowaves.left.and.right"
        case .processing: return "arrow.triangle.2.circlepath"
        case .allocated: return "checkmark.shield.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .returned: return "arrow.uturn.left.circle.fill"
        case .reversed: return "arrow.uturn.right.circle.fill"
        case .actionRequired: return "person.crop.circle.badge.exclamationmark"
        case .unavailable: return "minus.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(title.uppercased())
                .font(.custom("Inter-Bold", size: 9))
                .tracking(0.4)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.12)))
        .accessibilityLabel(title)
    }
}

// MARK: - Provenance Label

struct ProvenanceTag: View {
    let label: ProvenanceLabel

    var body: some View {
        Text(label.rawValue)
            .font(.custom("Inter-Bold", size: 8))
            .tracking(0.5)
            .foregroundStyle(MilliColors.textTertiary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().stroke(MilliColors.textTertiary.opacity(0.4), lineWidth: 0.6))
            .accessibilityLabel("Data provenance: \(label.rawValue)")
    }
}

// MARK: - Payout Row

struct AutopilotPayoutRow: View {
    let payout: AutopilotPayout

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cardBackground)
                    .frame(width: 38, height: 38)
                Text(String(payout.platform.prefix(1)))
                    .font(.custom("Sora-Bold", size: 14))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(payout.platform)
                    .font(.custom("Sora-SemiBold", size: 14))
                    .foregroundStyle(MilliColors.textPrimary)
                PayoutStateBadge(state: payout.state)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(centsString(payout.grossAmountCents))
                    .font(.custom("Sora-SemiBold", size: 14))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                ProvenanceTag(label: payout.provenance)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
        )
        .accessibilityElement(children: .combine)
    }

    private func centsString(_ cents: Int64) -> String {
        String(format: "$%.2f", Double(cents) / 100)
    }
}

// MARK: - Connect Earnings / Autopilot Setup

struct AutopilotSetupView: View {
    @ObservedObject var store: TreasuryAutopilotStore
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                header

                // Open/Activate MILLI Financial Account
                FinancialAccountCard(status: store.accountStatus)

                // Payout Routing / Autopilot toggle — reflects backend config.
                autopilotCard

                // Incoming payouts
                payoutList
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
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
            Text("Autopilot")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)
            Spacer()
            ProvenanceTag(label: store.provenance)
                .padding(.trailing, 34)
        }
    }

    private var autopilotCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYOUT ROUTING")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Autopilot Allocation")
                        .font(.custom("Sora-SemiBold", size: 14))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Estimated taxes are allocated to the Tax Vault automatically. Only the confirmed remainder becomes Available to Spend.")
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(MilliColors.textSecondary)
                }
                Spacer()
                // Reflects backend configuration; not a client-side promise.
                Toggle("", isOn: Binding(
                    get: { store.autopilot.isEnabled },
                    set: { _ in } // server-authoritative; no local mutation
                ))
                .tint(MilliColors.cyanGlow)
                .labelsHidden()
                .accessibilityLabel("Autopilot allocation enabled")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
        )
    }

    @ViewBuilder
    private var payoutList: some View {
        if store.payouts.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(MilliColors.textTertiary)
                Text(store.provenance == .unavailable
                     ? "Payout data unavailable"
                     : "No payouts detected yet")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                Text("Connect your earnings to route gig payouts into your MILLI Financial Account.")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundStyle(MilliColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .milliCard()
        } else {
            LazyVStack(spacing: 8) {
                ForEach(store.payouts) { payout in
                    AutopilotPayoutRow(payout: payout)
                }
            }
        }
    }
}

// MARK: - Financial Account Card (Open / Activate)

struct FinancialAccountCard: View {
    let status: FinancialAccountStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MILLI Financial Account")
                        .font(.custom("Sora-SemiBold", size: 14))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(statusText)
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(MilliColors.textSecondary)
                }
                Spacer()
                statusBadge
            }

            if status == .notOpened || status == .pendingActivation {
                Button {
                    // Activation is a backend flow; the UI only routes to it.
                } label: {
                    Text(status == .notOpened ? "Open Financial Account" : "Finish Activation")
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
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
        )
        .accessibilityElement(children: .contain)
    }

    private var statusText: String {
        switch status {
        case .notOpened: return "Not opened. Open your MILLI Financial Account to receive gig payouts."
        case .pendingActivation: return "Activation pending with the provider."
        case .active: return "Active. Incoming payouts are routed automatically."
        case .restricted: return "Restricted. Some flows are limited by the provider."
        case .closed: return "Closed."
        case .unavailable: return "Account status unavailable."
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let text: String
        let color: Color
        switch status {
        case .notOpened: text = "NOT OPENED"; color = MilliColors.textTertiary
        case .pendingActivation: text = "PENDING"; color = MilliColors.cyanGlow
        case .active: text = "ACTIVE"; color = MilliColors.positive
        case .restricted: text = "RESTRICTED"; color = MilliColors.warning
        case .closed: text = "CLOSED"; color = MilliColors.textTertiary
        case .unavailable: text = "UNAVAILABLE"; color = MilliColors.textTertiary
        }
        return Text(text)
            .font(.custom("Inter-Bold", size: 9))
            .tracking(0.4)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - External Bank Connection

struct ExternalBankConnectionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("External Bank Connection")
                        .font(.custom("Sora-SemiBold", size: 14))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Move funds between your MILLI Financial Account and an external bank.")
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(MilliColors.textSecondary)
                }
                Spacer()
            }
            Button {
                // Connection flow is backend/provider-driven.
            } label: {
                Text("Connect External Bank")
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
        )
    }
}

// MARK: - Account / Routing Details

struct AccountRoutingDetailsCard: View {
    let accountMask: String?
    let routingNumber: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACCOUNT / ROUTING DETAILS")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            HStack {
                detail("Account", accountMask.map { "•••• \($0)" } ?? "Unavailable")
                Spacer()
                detail("Routing", routingNumber ?? "Unavailable")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
        )
        .accessibilityElement(children: .combine)
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.custom("Inter-Medium", size: 9))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textTertiary)
            Text(value)
                .font(.custom("Inter-SemiBold", size: 13))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
    }
}
