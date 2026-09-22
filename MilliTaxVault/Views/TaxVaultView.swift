import SwiftUI

// MARK: - TaxVaultView
// Milli Tax Vault™ reserve surface, built to the obsidian/chrome reference:
// wordmark and companion, vault hero, quarterly + reserve two-up, verified
// activity, and a two-up action footer.
//
// Every figure is derived by MilliFinancialSnapshot from verified payouts and
// the user's own tax profile. Nothing is seeded: with no connected bank the
// screen renders its unavailable states, and money movement stays behind an
// explicit funding-source setup rather than pretending a transfer occurred.

struct TaxVaultView: View {
    var onBack: () -> Void = {}

    @StateObject private var bankService = BankConnectionService.shared
    @State private var showTransferSetup = false
    @State private var showEstimateDetail = false

    private var snapshot: MilliFinancialSnapshot { MilliFinancialSnapshot.current() }

    var body: some View {
        ZStack {
            MilliAmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    brandRow
                    vaultHero
                    twoUpRow
                    recentActivity
                    actionFooter
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.top, 4)
                .padding(.bottom, MilliSpacing.bottomContentClearance)
            }
        }
        .sheet(isPresented: $showTransferSetup) {
            transferSetupSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEstimateDetail) {
            MilliDetailSheet(title: "Quick Estimate")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Brand row

    private var brandRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.04)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                MilliWordmark(fontSize: 26, tracking: 4.2)
            }

            Spacer(minLength: 6)

            MilliCompanionBanner(
                title: "Milli AI",
                message: "Taxes don't have to be stressful. I'll keep your reserve on pace."
            )
            .frame(maxWidth: 190)
        }
        .padding(.top, 2)
    }

    // MARK: Vault hero

    private var vaultHero: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MILLI TAX VAULT™")
                    .font(.custom("Sora-SemiBold", size: 16, relativeTo: .headline))
                    .tracking(0.6)
                    .foregroundStyle(MilliColors.cyanGlow)

                Text("Taxes. Set aside. Stay ahead.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)

                MilliMicroLabel(text: "Vault balance")
                    .padding(.top, 6)

                Text(MilliFigureFormat.currency(snapshot.reservedForTaxes))
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .milliFigure(MilliFigureFormat.currency(snapshot.reservedForTaxes))

                Text(vaultProvenanceCaption)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 0)

            Image("tax-vault-hero")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 12)
                .accessibilityHidden(true)
        }
        .milliCard(padding: 14)
    }

    private var vaultProvenanceCaption: String {
        guard snapshot.isBankConnected else {
            return "Connect a bank to start reserving from verified payouts"
        }
        guard snapshot.hasPayouts else {
            return "Awaiting the first verified payout"
        }
        return "Withheld from \(snapshot.payouts.count) verified payouts"
    }

    // MARK: Quarterly + reserve stack

    private var twoUpRow: some View {
        VStack(spacing: MilliSpacing.gridGap) {
            quarterlyCard
            reserveCard
        }
    }

    private var quarterlyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            MilliMicroLabel(text: "Quarterly taxes", accent: true)

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    MilliMicroLabel(text: "Next due date")
                    Text(MilliFigureFormat.date(snapshot.nextEstimatedPaymentDue))
                        .font(MilliFont.numericMedium)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .milliFigure(MilliFigureFormat.date(snapshot.nextEstimatedPaymentDue))
                    Text(snapshot.nextEstimatedPaymentPeriod.map { "\($0) estimated taxes" } ?? "IRS schedule")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer(minLength: 0)

                MilliGaugeRing(
                    progress: snapshot.reserveProgress,
                    value: MilliFigureFormat.percent(snapshot.reserveProgress),
                    caption: "Funded",
                    size: 58,
                    lineWidth: 5.5
                )
            }

            Divider().overlay(Color.white.opacity(0.06))

            figureRow("Estimated liability", MilliFigureFormat.currency(snapshot.annualLiability))
            figureRow("Amount reserved", MilliFigureFormat.currency(snapshot.reservedForTaxes))
            figureRow(
                "Remaining to goal",
                MilliFigureFormat.currency(snapshot.remainingToGoal),
                accent: MilliColors.cyanGlow
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard(padding: 13)
    }

    private var reserveCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            MilliMicroLabel(text: "Reserve progress", accent: true)

            Text("Stay consistent. Stay protected.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)

            figureBlock("Annual projection", MilliFigureFormat.currency(snapshot.annualLiability))
            figureBlock("Total reserved", MilliFigureFormat.currency(snapshot.reservedForTaxes))

            MilliMicroLabel(text: "Year progress")
            Text(MilliFigureFormat.percent(snapshot.yearProgress))
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)

            MilliTrendChart(
                points: reserveHistory,
                height: 54,
                emptyMessage: "Reserve history appears after your first payout"
            )

            Text(reserveGuidance)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard(padding: 13)
    }

    /// Cumulative reserve over the verified payout ledger. The chart stays
    /// empty until every payout has an authoritative backend allocation amount.
    private var reserveHistory: [MilliTrendPoint] {
        let ordered = Array(snapshot.payouts.reversed())
        guard ordered.count >= 2 else { return [] }

        let allocations = ordered.compactMap { payout -> Double? in
            guard let cents = payout.stateContractProjection.taxAllocatedCents else { return nil }
            return Double(cents) / 100.0
        }
        guard allocations.count == ordered.count else { return [] }

        var running = 0.0
        let calendar = Calendar.current
        return allocations.enumerated().compactMap { index, amount in
            running += amount
            guard let date = calendar.date(
                byAdding: .day,
                value: index - ordered.count,
                to: Date()
            ) else {
                return nil
            }
            return MilliTrendPoint(date: date, value: running)
        }
    }

    private var reserveGuidance: String {
        guard let progress = snapshot.reserveProgress else {
            return "Add your tax profile and connect a bank to pace this reserve."
        }
        return progress >= snapshot.yearProgress
            ? "On track to meet your annual tax obligation."
            : "Behind the pace of the year — consider raising your reserve rate."
    }

    private func figureRow(_ label: String, _ value: String, accent: Color = MilliColors.textPrimary) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
            Spacer(minLength: 4)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliPlaceholder.isPlaceholder(value) ? MilliColors.textTertiary : accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    private func figureBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            MilliMicroLabel(text: label)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .milliFigure(value)
        }
    }

    // MARK: Recent activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MilliMicroLabel(text: "Recent activity", accent: true)
                Spacer()
                Text("Verified payouts only")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            if snapshot.hasPayouts {
                VStack(spacing: 0) {
                    let entries = snapshot.recentPayouts(limit: 4)
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, payout in
                        activityRow(payout)
                        if index < entries.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.055))
                                .padding(.leading, 46)
                        }
                    }
                }
                .background(MilliCardBackground(showGlow: true))
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(MilliColors.textTertiary)
                    Text("No vault activity yet")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("Reserve entries appear as verified payouts land.")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(MilliCardBackground(showGlow: false))
            }
        }
    }

    private func activityRow(_ payout: VerifiedPayout) -> some View {
        let allocatedAmount = payout.stateContractProjection.taxAllocatedCents.map { Double($0) / 100.0 }

        return HStack(spacing: 10) {
            Image(systemName: "arrow.down.left")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(MilliColors.cyanGlow.opacity(0.09))
                        .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.22), lineWidth: 0.7))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(allocatedAmount == nil ? "Payout from \(payout.platform)" : "Reserved from \(payout.platform)")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                Text(payout.dateLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(
                    allocatedAmount.map {
                        $0.formatted(.currency(code: "USD").sign(strategy: .always()))
                    } ?? MilliPlaceholder.value
                )
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(allocatedAmount == nil ? MilliColors.textTertiary : MilliColors.positive)
                Text("of \(payout.grossAmount.formatted(.currency(code: "USD")))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    // MARK: Footer

    private var actionFooter: some View {
        MilliActionPair(
            primaryTitle: "Add to Vault",
            primaryCaption: "Transfer funds in",
            primaryIcon: "arrow.down.circle",
            primaryAction: { showTransferSetup = true },
            secondaryTitle: "Quick Estimate",
            secondaryCaption: "Update your projection",
            secondaryIcon: "function",
            secondaryAction: { showEstimateDetail = true }
        )
    }

    private var transferSetupSheet: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "building.columns.circle.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)

                VStack(spacing: 6) {
                    Text("Connect a Funding Source")
                        .font(MilliFont.screenTitle)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Vault transfers become available after a production funding account is connected and verified. No money is moved from this setup screen.")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button("Done") {
                    showTransferSetup = false
                }
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(MilliColors.cyanGlow)
                )
            }
            .padding(24)
        }
    }
}

#Preview {
    TaxVaultView()
}
