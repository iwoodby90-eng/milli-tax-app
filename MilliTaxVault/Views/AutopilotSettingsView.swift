import SwiftUI

// MARK: - AutopilotSettingsView
// Canonical allocation settings interface using deterministic AutopilotEngine and Money math.
// Governs: Gross Payout = Taxes Protected + Retirement + Investing + Savings + Available to Spend + Explicit Fees.

public struct AutopilotSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("taxReservePercent") private var taxPercent: Double = 23
    @AppStorage("retirementEnabled") private var retirementEnabled: Bool = true
    @AppStorage("retirementPercent") private var retirementPercent: Double = 5
    @AppStorage("investingEnabled") private var investingEnabled: Bool = false
    @AppStorage("investingPercent") private var investingPercent: Double = 0
    @AppStorage("savingsEnabled") private var savingsEnabled: Bool = true
    @AppStorage("savingsPercent") private var savingsPercent: Double = 3
    @State private var examplePayout: Double = 312.45

    private var onBack: () -> Void

    public init(onBack: @escaping () -> Void = {}) {
        self.onBack = onBack
    }

    private var optionalAllocationTotal: Double {
        (retirementEnabled ? retirementPercent : 0) +
        (investingEnabled ? investingPercent : 0) +
        (savingsEnabled ? savingsPercent : 0)
    }

    private var config: AutopilotConfiguration {
        AutopilotConfiguration(
            isEnabled: true,
            taxReserveRate: Decimal(string: String(format: "%.2f", taxPercent / 100)) ?? Decimal(string: "0.23")!,
            retirementRate: retirementEnabled ? (Decimal(string: String(format: "%.2f", retirementPercent / 100)) ?? .zero) : .zero,
            investingRate: investingEnabled ? (Decimal(string: String(format: "%.2f", investingPercent / 100)) ?? .zero) : .zero,
            emergencySavingsRate: savingsEnabled ? (Decimal(string: String(format: "%.2f", savingsPercent / 100)) ?? .zero) : .zero
        )
    }

    private var allocation: AutopilotAllocationResult {
        AutopilotEngine.allocate(
            grossPayout: Money(double: examplePayout),
            config: config
        )
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                heroStatusCard
                taxProtectionCard
                optionalAllocations
                payoutPreview
                safetyNotice
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, MilliLayoutSpacing.bottomContentClearance)
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

            Text("Autopilot Settings")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
        }
    }

    private var heroStatusCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AUTOPILOT ALLOCATION ENGINE")
                    .sectionHeaderStyle()
                Spacer()
                Text("DETERMINISTIC")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(MilliColors.cyanGlow.opacity(0.12))
                    )
            }

            Text("Every verified payout is allocated automatically according to your strict financial rules.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
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

            previewRow("Milli Tax Vault™", allocation.taxReserve, MilliColors.cyanGlow)
            previewRow("Retirement", allocation.retirement, MilliColors.positive)
            previewRow("Investing", allocation.investing, Color(hex: "7C8CFF"))
            previewRow("Savings", allocation.savings, MilliColors.deepCyan)

            Divider().overlay(Color.white.opacity(0.07))

            HStack {
                Text("AVAILABLE TO SPEND")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text(allocation.availableToSpend.formattedCurrency())
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .milliCard(padding: 14)
    }

    private func previewRow(_ title: String, _ amount: Money, _ color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            Spacer()
            Text(amount.formattedCurrency())
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
    }

    private var safetyNotice: some View {
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

#Preview {
    AutopilotSettingsView()
        .preferredColorScheme(.dark)
}
