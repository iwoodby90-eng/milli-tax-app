import SwiftUI

// MARK: - HomeView
// Canonical Milli home cockpit. The layout is intentionally hierarchical rather
// than card-heavy: one hero instrument, one consolidated financial status rail,
// a readable allocation timeline, and a compact planning console.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                headerSection
                balanceHero
                financialStatusRail
                financialTimeline
                planningConsole
                aiInsight
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 8)
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                MilliWordmark(fontSize: 29, tracking: 5.4)
                Text("MONEY, MADE INTELLIGENT.")
                    .font(.custom("Inter-Medium", size: 8.5, relativeTo: .caption2))
                    .tracking(1.8)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Button {
                showNotifications = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.035))
                        .frame(width: 39, height: 39)
                        .overlay { Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.7) }
                    Image(systemName: "bell")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MilliColors.silverBright)
                    Circle()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: 5, height: 5)
                        .offset(x: 11, y: -11)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .frame(minHeight: 54)
    }

    // MARK: Balance hero

    private var balanceHero: some View {
        Button { navigate?(.accounts) } label: {
            ZStack(alignment: .topLeading) {
                Image("home-hero-bg")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.24)
                    .clipped()

                LinearGradient(
                    colors: [Color(hex: "0A1116").opacity(0.48), Color.black.opacity(0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AVAILABLE TO SPEND")
                                .font(MilliFont.sectionLabel)
                                .tracking(1.15)
                                .foregroundStyle(MilliColors.textSecondary)
                            Text("After protected allocations")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(MilliColors.positive)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.custom("Inter-SemiBold", size: 9))
                                .tracking(0.8)
                                .foregroundStyle(MilliColors.positive)
                        }
                    }

                    Text(viewModel.availableToSpend)
                        .font(.custom("Sora-Bold", size: 42, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    MilliSparkline(
                        data: viewModel.sparklineData,
                        color: MilliColors.cyanGlow,
                        height: 58,
                        lineWidth: 2.0
                    )

                    HStack {
                        Text("Updated just now")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                        Spacer()
                        HStack(spacing: 5) {
                            Text("Open accounts")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption))
                        .foregroundStyle(MilliColors.cyanGlow)
                    }
                }
                .padding(17)
            }
            .frame(maxWidth: .infinity, minHeight: 182)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.24), MilliColors.cyanGlow.opacity(0.20), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: MilliColors.cyanGlow.opacity(0.05), radius: 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: Consolidated status rail

    private var financialStatusRail: some View {
        VStack(spacing: 0) {
            Button { navigate?(.vault) } label: {
                statusRow(
                    icon: "arrow.down.circle.fill",
                    iconColor: MilliColors.cyanGlow,
                    eyebrow: "LATEST PAYOUT",
                    title: viewModel.latestPayout.platformName,
                    value: viewModel.latestPayout.amount,
                    detail: viewModel.latestPayout.dateTime,
                    trailingBadge: "AUTOPILOT"
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(Color.white.opacity(0.06)).padding(.leading, 54)

            HStack(spacing: 0) {
                Button { navigate?(.taxVault) } label: {
                    compactInstrument(
                        icon: "lock.shield.fill",
                        label: "Tax Vault™",
                        value: viewModel.taxVaultBalance,
                        detail: "23% funded",
                        accent: MilliColors.cyanGlow
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 1, height: 70)

                Button { navigate?(.taxReadyScore) } label: {
                    compactInstrument(
                        icon: "checkmark.seal.fill",
                        label: "Tax Ready™",
                        value: "\(viewModel.taxReadyScore)",
                        detail: "On track",
                        accent: MilliColors.positive
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(integratedSurface)
    }

    private func statusRow(
        icon: String,
        iconColor: Color,
        eyebrow: String,
        title: String,
        value: String,
        detail: String,
        trailingBadge: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.08))
                    .frame(width: 42, height: 42)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(iconColor.opacity(0.18), lineWidth: 0.7)
                    }
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.9)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(value)
                    .font(.custom("Sora-Bold", size: 20))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text(trailingBadge)
                    .font(.custom("Inter-SemiBold", size: 8.5))
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.cyanGlow)
            }
        }
        .padding(14)
    }

    private func compactInstrument(
        icon: String,
        label: String,
        value: String,
        detail: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                Text(label.uppercased())
                    .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                    .tracking(0.6)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Text(value)
                .font(.custom("Sora-Bold", size: 19))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(detail)
                .font(MilliFont.caption)
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    // MARK: Financial Timeline

    private var financialTimeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FINANCIAL TIMELINE")
                        .sectionHeaderStyle()
                    Text("Latest payout allocation")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text("TODAY")
                    .font(.custom("Inter-SemiBold", size: 9))
                    .tracking(0.9)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            timelineRow(
                icon: "arrow.down",
                title: "Payout received",
                detail: viewModel.latestPayout.platformName,
                amount: viewModel.latestPayout.amount,
                color: MilliColors.cyanGlow,
                showsConnector: true
            )
            timelineRow(
                icon: "lock.fill",
                title: "Taxes protected",
                detail: "Milli Tax Vault™ • 25%",
                amount: "-$46.86",
                color: MilliColors.positive,
                showsConnector: true
            )
            timelineRow(
                icon: "checkmark",
                title: "Available after allocation",
                detail: "Autopilot complete",
                amount: "$140.56",
                color: MilliColors.silverBright,
                showsConnector: false
            )
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
    }

    private func timelineRow(
        icon: String,
        title: String,
        detail: String,
        amount: String,
        color: Color,
        showsConnector: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 31, height: 31)
                        .overlay { Circle().stroke(color.opacity(0.42), lineWidth: 0.8) }
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(color)
                }
                if showsConnector {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 18)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 13.5))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Text(amount)
                .font(.custom("Sora-SemiBold", size: 13))
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    // MARK: Planning console

    private var planningConsole: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PLAN & GROW")
                    .sectionHeaderStyle()
                Spacer()
                Button { navigate?(.wealthOverview) } label: {
                    Text("Wealth hub")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            planningRow(
                icon: "calendar.badge.clock",
                title: "Quarterly Taxes",
                value: viewModel.quarterlyTaxes,
                detail: viewModel.quarterlyDueLabel,
                destination: .quarterlyTaxes
            )
            Divider().overlay(Color.white.opacity(0.055)).padding(.leading, 50)
            planningRow(
                icon: "location.north.fill",
                title: "Mileage",
                value: viewModel.mileage,
                detail: "This quarter",
                destination: .activity
            )
            Divider().overlay(Color.white.opacity(0.055)).padding(.leading, 50)
            planningRow(
                icon: "building.columns.fill",
                title: "Retirement",
                value: "$8,420",
                detail: "+$312 this month",
                destination: .retirement
            )
            Divider().overlay(Color.white.opacity(0.055)).padding(.leading, 50)
            planningRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Investing",
                value: "$3,184",
                detail: "+4.8% this year",
                destination: .investing
            )
        }
        .background(integratedSurface)
    }

    private func planningRow(
        icon: String,
        title: String,
        value: String,
        detail: String,
        destination: ActiveScreen
    ) -> some View {
        Button { navigate?(destination) } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 24)

                Text(title)
                    .font(.custom("Inter-SemiBold", size: 13.5))
                    .foregroundStyle(MilliColors.textPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(value)
                        .font(.custom("Sora-SemiBold", size: 13))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(detail)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    // MARK: AI Insight

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 12) {
                MilliAICharacterView(size: 74, animated: true)
                    .frame(width: 74, height: 74)

                VStack(alignment: .leading, spacing: 5) {
                    Text("MILLI AI")
                        .font(.custom("Inter-SemiBold", size: 10))
                        .tracking(1.0)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Insight for you")
                        .font(.custom("Sora-SemiBold", size: 15))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 3)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var integratedSurface: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "0E161B"), Color(hex: "080C0F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.14), MilliColors.cyanGlow.opacity(0.08), Color.white.opacity(0.025)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
            }
    }
}
