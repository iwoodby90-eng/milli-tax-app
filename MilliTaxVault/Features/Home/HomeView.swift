import SwiftUI

// MARK: - HomeView
// Canonical Milli dashboard. The composition follows the approved premium
// financial-OS direction: one dominant balance instrument, one consolidated
// status surface, a readable payout allocation timeline, and restrained AI.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                headerSection
                balanceHero
                latestPayout
                financialStatusRail
                financialTimeline
                planningConsole
                aiInsight
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 6)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 10)
        }
        .background(dashboardBackground)
        .sheet(isPresented: $showNotifications) {
            MilliDetailSheet(title: "Notifications")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var dashboardBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            LinearGradient(
                colors: [Color(hex: "071116").opacity(0.82), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.055), Color.clear],
                center: UnitPoint(x: 0.94, y: 0.12),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }

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
        .frame(height: 50)
    }

    private var balanceHero: some View {
        Button { navigate?(.accounts) } label: {
            ZStack(alignment: .topLeading) {
                Image("home-hero-bg")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 198)
                    .clipped()
                    .opacity(0.30)

                LinearGradient(
                    colors: [Color(hex: "0A171D").opacity(0.36), Color.black.opacity(0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
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
                        .font(.custom("Sora-Bold", size: 40, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    MilliSparkline(
                        data: viewModel.sparklineData,
                        color: MilliColors.cyanGlow,
                        height: 48,
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
                .padding(16)
            }
            .frame(height: 198)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.24), MilliColors.cyanGlow.opacity(0.22), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: MilliColors.cyanGlow.opacity(0.06), radius: 18, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var latestPayout: some View {
        Button { navigate?(.vault) } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MilliColors.cyanGlow.opacity(0.08))
                        .frame(width: 43, height: 43)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MilliColors.cyanGlow.opacity(0.19), lineWidth: 0.7)
                        }
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("LATEST PAYOUT")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.85)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text(viewModel.latestPayout.platformName)
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(viewModel.latestPayout.dateTime)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(viewModel.latestPayout.amount)
                        .font(.custom("Sora-Bold", size: 20))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("AUTOPILOT")
                        .font(.custom("Inter-SemiBold", size: 8.5))
                        .tracking(0.55)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 78)
            .background(integratedSurface)
        }
        .buttonStyle(.plain)
    }

    private var financialStatusRail: some View {
        HStack(spacing: 0) {
            statusMetric(icon: "lock.shield.fill", label: "Tax Vault™", value: viewModel.taxVaultBalance, detail: "Protected", accent: MilliColors.cyanGlow, destination: .taxVault)
            statusDivider
            statusMetric(icon: "checkmark.seal.fill", label: "Tax Ready™", value: "\(viewModel.taxReadyScore)", detail: "On track", accent: MilliColors.positive, destination: .taxReadyScore)
            statusDivider
            statusMetric(icon: "location.north.fill", label: "Mileage", value: viewModel.mileage, detail: "Quarter", accent: MilliColors.silverBright, destination: .activity)
        }
        .padding(.vertical, 12)
        .background(integratedSurface)
    }

    private var statusDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(width: 1, height: 62)
    }

    private func statusMetric(icon: String, label: String, value: String, detail: String, accent: Color, destination: ActiveScreen) -> some View {
        Button { navigate?(destination) } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(label.uppercased())
                        .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                        .tracking(0.45)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(1)
                }

                Text(value)
                    .font(.custom("Sora-SemiBold", size: 14.5))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)

                Text(detail)
                    .font(.custom("Inter-Medium", size: 9, relativeTo: .caption2))
                    .foregroundStyle(accent)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
    }

    private var financialTimeline: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
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

            timelineRow(icon: "arrow.down", title: "Payout received", detail: viewModel.latestPayout.platformName, amount: viewModel.latestPayout.amount, color: MilliColors.cyanGlow, showsConnector: true)
            timelineRow(icon: "lock.fill", title: "Taxes protected", detail: "Milli Tax Vault™", amount: "Protected", color: MilliColors.positive, showsConnector: true)
            timelineRow(icon: "checkmark", title: "Available after allocation", detail: "Autopilot complete", amount: viewModel.availableToSpend, color: MilliColors.silverBright, showsConnector: false)
        }
        .padding(15)
        .background(integratedSurface)
    }

    private func timelineRow(icon: String, title: String, detail: String, amount: String, color: Color, showsConnector: Bool) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.72))
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
                .font(.custom("Sora-SemiBold", size: 12.5))
                .monospacedDigit()
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
        }
    }

    private var planningConsole: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PLAN & GROW")
                    .sectionHeaderStyle()
                Spacer()
                Button { navigate?(.wealthOverview) } label: {
                    HStack(spacing: 4) {
                        Text("Wealth hub")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.cyanGlow)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
            .padding(.bottom, 7)

            planningRow(icon: "calendar.badge.clock", title: "Quarterly Taxes", value: viewModel.quarterlyTaxes, detail: viewModel.quarterlyDueLabel, destination: .quarterlyTaxes)
            Divider().overlay(Color.white.opacity(0.055)).padding(.leading, 50)
            planningRow(icon: "point.3.filled.connected.trianglepath.dotted", title: "Tree of Life", value: "Plan future", detail: "Life events & wealth path", destination: .treeOfLife)
        }
        .background(integratedSurface)
    }

    private func planningRow(icon: String, title: String, value: String, detail: String, destination: ActiveScreen) -> some View {
        Button { navigate?(destination) } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Inter-SemiBold", size: 13.5))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(detail)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer()

                Text(value)
                    .font(.custom("Sora-SemiBold", size: 12.5))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 11) {
                MilliAICharacterView(size: 80, animated: true)
                    .frame(width: 72, height: 82)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MILLI AI")
                        .font(.custom("Inter-SemiBold", size: 9.5))
                        .tracking(1.0)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Insight for you")
                        .font(.custom("Sora-SemiBold", size: 14.5))
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 3)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "071318"), Color.black.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.13), lineWidth: 0.7)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    private var integratedSurface: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: "0D161B"), Color(hex: "070B0E")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.14), MilliColors.cyanGlow.opacity(0.08), Color.white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.7)
            }
    }
}
