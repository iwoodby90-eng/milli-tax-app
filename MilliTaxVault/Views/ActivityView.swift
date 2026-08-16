import SwiftUI

// MARK: - AutopilotSettingsView
// Milli Autopilot™ is the payout allocation control center. Taxes are always on;
// retirement, investing and savings are user-controlled. Settings persist locally
// with AppStorage until authenticated profile sync is connected.

struct AutopilotSettingsView: View {
    var onBack: () -> Void = {}

    @AppStorage("milliAutopilotRetirementEnabled") private var retirementEnabled = true
    @AppStorage("milliAutopilotInvestingEnabled") private var investingEnabled = false
    @AppStorage("milliAutopilotSavingsEnabled") private var savingsEnabled = true

    @AppStorage("milliAutopilotRetirementPercent") private var retirementPercent = 5.0
    @AppStorage("milliAutopilotInvestingPercent") private var investingPercent = 0.0
    @AppStorage("milliAutopilotSavingsPercent") private var savingsPercent = 3.0

    private let taxPercent = 23.0
    private let examplePayout = 312.64

    private var retirementAllocation: Double {
        retirementEnabled ? examplePayout * retirementPercent / 100 : 0
    }

    private var investingAllocation: Double {
        investingEnabled ? examplePayout * investingPercent / 100 : 0
    }

    private var savingsAllocation: Double {
        savingsEnabled ? examplePayout * savingsPercent / 100 : 0
    }

    private var taxAllocation: Double {
        examplePayout * taxPercent / 100
    }

    private var availableToSpend: Double {
        max(examplePayout - taxAllocation - retirementAllocation - investingAllocation - savingsAllocation, 0)
    }

    private var optionalAllocationTotal: Double {
        (retirementEnabled ? retirementPercent : 0)
        + (investingEnabled ? investingPercent : 0)
        + (savingsEnabled ? savingsPercent : 0)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                statusHero
                taxProtectionCard
                optionalAllocations
                payoutPreview
                productDisclosure
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

            VStack(spacing: 1) {
                Text("Milli Autopilot™")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Every payout, on Autopilot.")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
        }
    }

    private var statusHero: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 62, height: 62)
                Circle()
                    .stroke(MilliColors.cyanGlow.opacity(0.42), lineWidth: 1.2)
                    .frame(width: 62, height: 62)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.24), radius: 7)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle().fill(MilliColors.positive).frame(width: 6, height: 6)
                    Text("AUTOPILOT READY")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.8)
                        .foregroundStyle(MilliColors.positive)
                }

                Text("Taxes protected first")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("Optional wealth allocations follow your settings below.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .milliCard(padding: 14)
    }

    private var taxProtectionCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.10))
                    .frame(width: 42, height: 42)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("TAX PROTECTION")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.65)
                    .foregroundStyle(MilliColors.textSecondary)
                Text("Always On")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Current planning rate: \(Int(taxPercent))%")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(MilliColors.positive)
        }
        .milliCard(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tax protection always on. Current planning rate \(Int(taxPercent)) percent")
    }

    private var optionalAllocations: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("OPTIONAL ALLOCATIONS")
                    .sectionHeaderStyle()
                Spacer()
                Text("\(Int(optionalAllocationTotal))% total")
                    .font(MilliFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textTertiary)
            }

            allocationControl(
                title: "Retirement",
                subtitle: "Build long-term retirement wealth",
                icon: "building.columns.fill",
                color: MilliColors.positive,
                enabled: $retirementEnabled,
                percent: $retirementPercent
            )

            allocationControl(
                title: "Investing",
                subtitle: "Direct a portion toward your portfolio",
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "7C8CFF"),
                enabled: $investingEnabled,
                percent: $investingPercent
            )

            allocationControl(
                title: "Savings",
                subtitle: "Fund your active savings goals",
                icon: "target",
                color: MilliColors.deepCyan,
                enabled: $savingsEnabled,
                percent: $savingsPercent
            )
        }
    }

    private func allocationControl(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        enabled: Binding<Bool>,
        percent: Binding<Double>
    ) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(color.opacity(0.09)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(subtitle)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(color)
            }

            if enabled.wrappedValue {
                VStack(spacing: 6) {
                    HStack {
                        Text("Contribution")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                        Spacer()
                        Text("\(Int(percent.wrappedValue))%")
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(color)
                    }

                    Slider(value: percent, in: 1...25, step: 1)
                        .tint(color)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: enabled.wrappedValue)
        .milliCard(padding: 12)
    }

    private var payoutPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAYOUT PREVIEW")
                        .sectionHeaderStyle()
                    Text("Example payout")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text(examplePayout.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }

            Divider().overlay(Color.white.opacity(0.06))

            previewRow("Milli Tax Vault™", taxAllocation, MilliColors.cyanGlow)
            previewRow("Retirement", retirementAllocation, MilliColors.positive)
            previewRow("Investing", investingAllocation, Color(hex: "7C8CFF"))
            previewRow("Savings", savingsAllocation, MilliColors.deepCyan)

            Divider().overlay(Color.white.opacity(0.07))

            HStack {
                Text("AVAILABLE TO SPEND")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text(availableToSpend.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .milliCard(padding: 14)
    }

    private func previewRow(_ title: String, _ amount: Double, _ color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            Spacer()
            Text(amount.formatted(.currency(code: "USD")))
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(amount == 0 ? MilliColors.textTertiary : MilliColors.textPrimary)
        }
    }

    private var productDisclosure: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(MilliColors.textTertiary)
                .padding(.top, 1)
            Text("These controls persist your allocation preferences locally in this build. Actual payout detection, money movement, investment orders, savings transfers, and retirement contributions require their verified production integrations before Autopilot can execute them.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 11)
    }
}

// Legacy compatibility wrapper while the old duplicate Activity dashboard is retired.
struct ActivityView: View {
    var body: some View {
        AutopilotSettingsView()
    }
}

#Preview {
    AutopilotSettingsView()
        .preferredColorScheme(.dark)
}
