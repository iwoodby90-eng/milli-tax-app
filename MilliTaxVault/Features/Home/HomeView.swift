import SwiftUI

// MARK: - HomeView
// Primary financial cockpit. Layout and density follow the approved
// production reference: Available to Spend → Latest Payout (financial
// receipt) → Milli Tax Vault → Tax Ready Score → Financial Timeline →
// Quarterly Taxes / Mileage / Retirement / Investing → Milli AI.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                availableHero
                latestPayout
                taxVaultSection
                taxReadyScore
                financialTimeline
                moduleGrid
                aiInsight
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.sm)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showNotifications) {
            MilliDetailSheet(title: "Notifications")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private var headerSection: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    showNotifications = true
                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MilliColors.silverBright)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notifications")
                .accessibilityIdentifier("home.notifications")
            }

            MilliWordmark()
        }
        .frame(height: 46)
    }

    // MARK: Available to Spend

    private var availableHero: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("AVAILABLE TO SPEND")
                .font(MilliFont.sectionLabel)
                .tracking(0.9)
                .foregroundColor(MilliColors.textSecondary)

            Text(viewModel.availableToSpend)
                .font(MilliFont.heroBalance)
                .monospacedDigit()
                .foregroundColor(MilliColors.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .accessibilityIdentifier("home.availableToSpend")

            Text("Updated just now")
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.textTertiary)

            ZStack(alignment: .trailing) {
                MilliSparkline(
                    data: viewModel.sparklineData,
                    color: MilliColors.cyanGlow,
                    height: 50,
                    lineWidth: 1.8
                )

                Button {
                    navigate?(.accounts)
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(MilliColors.blackGlass)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(MilliColors.cyanGlow))
                        .shadow(color: MilliColors.cyanGlow.opacity(0.34), radius: 7)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open accounts")
                .accessibilityIdentifier("home.openAccounts")
                .padding(.trailing, 2)
            }
        }
        .padding(MilliSpacing.cardPadding)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(MilliColors.blackGlassSurface)
                // Cyan ambient illumination behind the balance.
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [MilliColors.cyanGlow.opacity(0.14), Color.clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 240
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .stroke(MilliColors.focusedBorder, lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.38), radius: 12, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Available to spend \(viewModel.availableToSpend)")
    }

    // MARK: Latest Payout — financial receipt

    private var latestPayout: some View {
        Button {
            navigate?(.vault)
        } label: {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack {
                    Text("LATEST PAYOUT")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.8)
                        .foregroundColor(MilliColors.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MilliColors.textTertiary)
                }

                HStack(spacing: MilliSpacing.sm) {
                    Image(viewModel.latestPayout.platformAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.latestPayout.amount)
                            .font(MilliFont.numericMedium)
                            .monospacedDigit()
                            .foregroundColor(MilliColors.textPrimary)
                            .lineLimit(1)

                        Text("\(viewModel.latestPayout.dateTime)  ·  \(viewModel.latestPayout.platformName)")
                            .font(MilliFont.caption)
                            .foregroundColor(MilliColors.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Receipt-style posted confirmation. Seeded preview data
                    // is marked as such; production replaces the source.
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(MilliColors.positive)
                            Text("POSTED")
                                .font(MilliFont.label)
                                .tracking(0.6)
                                .foregroundColor(MilliColors.positive)
                        }
                        Text("PREVIEW")
                            .font(MilliFont.label)
                            .tracking(0.6)
                            .foregroundColor(MilliColors.textTertiary)
                    }
                }

                // Receipt perforation divider.
                HStack(spacing: 5) {
                    ForEach(0..<24, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 3, height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            }
            .padding(MilliSpacing.cardPadding)
            .milliSurface()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.latestPayout")
        .accessibilityLabel("Latest payout \(viewModel.latestPayout.amount) from \(viewModel.latestPayout.platformName)")
    }

    // MARK: Milli Tax Vault

    private var taxVaultSection: some View {
        Button {
            navigate?(.taxVault)
        } label: {
            HStack(spacing: MilliSpacing.md) {
                VStack(alignment: .leading, spacing: MilliSpacing.xs) {
                    Text("MILLI TAX VAULT")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.55)
                        .foregroundColor(MilliColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(viewModel.taxVaultBalance)
                        .font(MilliFont.numericMedium)
                        .monospacedDigit()
                        .foregroundColor(MilliColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                        .allowsTightening(true)

                    Text("Set aside automatically from every payout")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textTertiary)
                        .lineLimit(2)
                }
                .layoutPriority(1)

                Spacer(minLength: MilliSpacing.xs)

                progressRing(progress: 0.23, value: nil, size: 44)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(MilliSpacing.cardPadding)
            .milliSurface(hasCyanBorder: true)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.taxVault")
        .accessibilityLabel("Milli Tax Vault balance \(viewModel.taxVaultBalance)")
    }

    // MARK: Tax Ready Score

    private var taxReadyScore: some View {
        Button {
            navigate?(.taxReadyScore)
        } label: {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("TAX READY SCORE")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundColor(MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(spacing: MilliSpacing.sm) {
                    progressRing(
                        progress: CGFloat(viewModel.taxReadyScore) / 100.0,
                        value: "\(viewModel.taxReadyScore)",
                        size: 52
                    )
                    .fixedSize()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(taxReadyLabel)
                            .font(MilliFont.labelLarge)
                            .foregroundColor(MilliColors.positive)
                        Text(taxReadyCaption)
                            .font(MilliFont.caption)
                            .foregroundColor(MilliColors.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(MilliSpacing.cardPadding)
            .milliSurface()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.taxReadyScore")
        .accessibilityLabel("Tax ready score \(viewModel.taxReadyScore), \(taxReadyLabel)")
    }

    private var taxReadyLabel: String {
        switch viewModel.taxReadyScore {
        case 90...: return "Excellent"
        case 75..<90: return "Great"
        case 50..<75: return "Building"
        default: return "Needs attention"
        }
    }

    private var taxReadyCaption: String {
        switch viewModel.taxReadyScore {
        case 75...: return "You're on track for tax season"
        case 50..<75: return "A few items left to secure"
        default: return "Complete your tax profile to improve"
        }
    }

    // MARK: Financial Timeline

    private var financialTimeline: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("FINANCIAL TIMELINE")
                .font(MilliFont.sectionLabel)
                .tracking(0.55)
                .foregroundColor(MilliColors.textSecondary)

            HStack(alignment: .top, spacing: 0) {
                timelineNode(
                    title: "Payout received",
                    detail: viewModel.latestPayout.dateTime,
                    symbol: "arrow.down.circle.fill",
                    active: true
                )

                timelineConnector

                timelineNode(
                    title: "Vault set-aside",
                    detail: viewModel.taxVaultBalance,
                    symbol: "lock.shield.fill",
                    active: true
                )

                timelineConnector

                timelineNode(
                    title: "Quarterly due",
                    detail: viewModel.quarterlyDueLabel,
                    symbol: "calendar.badge.clock",
                    active: false
                )
            }
        }
        .padding(MilliSpacing.cardPadding)
        .milliSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Financial timeline: payout received, vault set-aside \(viewModel.taxVaultBalance), quarterly payment due \(viewModel.quarterlyDueLabel)")
        .accessibilityIdentifier("home.financialTimeline")
    }

    private var timelineConnector: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.45), Color.white.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1.5)
            .frame(maxWidth: .infinity)
            .padding(.top, 11)
            .accessibilityHidden(true)
    }

    private func timelineNode(title: String, detail: String, symbol: String, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? MilliColors.cyanGlow : MilliColors.textTertiary)
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(active ? MilliColors.cyanGlow.opacity(0.14) : Color.white.opacity(0.05))
                )

            Text(title)
                .font(MilliFont.labelLarge)
                .foregroundColor(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(MilliFont.caption)
                .foregroundColor(MilliColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Module grid — Quarterly Taxes / Mileage / Retirement / Investing

    private var moduleGrid: some View {
        VStack(spacing: MilliSpacing.gridGap) {
            HStack(spacing: MilliSpacing.gridGap) {
                moduleTile(
                    title: "QUARTERLY TAXES",
                    value: viewModel.quarterlyTaxes,
                    caption: viewModel.quarterlyDueLabel,
                    symbol: "calendar.badge.clock",
                    screen: .quarterlyTaxes,
                    identifier: "home.quarterlyTaxes"
                )

                moduleTile(
                    title: "MILEAGE",
                    value: viewModel.mileage,
                    caption: "This quarter",
                    symbol: "car.fill",
                    screen: .activity,
                    identifier: "home.mileage"
                )
            }

            HStack(spacing: MilliSpacing.gridGap) {
                // Navigation tiles only — no invented balances for
                // retirement or investing until authoritative data lands.
                navigationTile(
                    title: "RETIREMENT",
                    caption: "Open retirement plan",
                    symbol: "leaf.fill",
                    screen: .retirement,
                    identifier: "home.retirement"
                )

                navigationTile(
                    title: "INVESTING",
                    caption: "Open investing",
                    symbol: "chart.line.uptrend.xyaxis",
                    screen: .investing,
                    identifier: "home.investing"
                )
            }
        }
    }

    private func moduleTile(
        title: String,
        value: String,
        caption: String,
        symbol: String,
        screen: ActiveScreen,
        identifier: String
    ) -> some View {
        Button {
            navigate?(screen)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundColor(MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(value)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundColor(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                HStack(spacing: 4) {
                    Text(caption)
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textTertiary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MilliColors.cyanGlow)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .padding(MilliSpacing.cardPadding)
            .milliSurface()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(title) \(value)")
    }

    private func navigationTile(
        title: String,
        caption: String,
        symbol: String,
        screen: ActiveScreen,
        identifier: String
    ) -> some View {
        Button {
            navigate?(screen)
        } label: {
            HStack(spacing: MilliSpacing.sm) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MilliColors.cyanGlow)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(MilliColors.cyanGlow.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MilliFont.labelLarge)
                        .foregroundColor(MilliColors.textPrimary)
                        .lineLimit(1)

                    Text(caption)
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MilliColors.textTertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
            .padding(MilliSpacing.cardPadding)
            .milliSurface()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(title)
    }

    // MARK: Shared progress ring

    private func progressRing(progress: CGFloat, value: String?, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.09), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if let value {
                Text(value)
                    .font(.custom("Sora-SemiBold", size: 12))
                    .foregroundColor(MilliColors.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: Milli AI insight

    private var aiInsight: some View {
        Button {
            navigate?(.milliAI)
        } label: {
            HStack(spacing: MilliSpacing.sm) {
                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 0.7)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("MILLI AI INSIGHT")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.7)
                        .foregroundColor(MilliColors.cyanGlow)

                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodyMedium)
                        .foregroundColor(MilliColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MilliColors.cyanGlow)
            }
            .padding(MilliSpacing.cardPadding)
            .milliSurface()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.aiInsight")
        .accessibilityLabel("Milli AI insight: \(viewModel.aiInsight)")
    }
}
