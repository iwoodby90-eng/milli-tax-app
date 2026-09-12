import SwiftUI

// MARK: - HomeView
// Primary Milli financial cockpit. Full-width, high-fidelity composition based on
// the approved dashboard hierarchy: spendable cash, latest payout, Tax Vault,
// Tax Ready Score, Financial Timeline, quarterly tax, mileage, retirement,
// investing, then Milli AI insight.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                headerSection
                availableHero
                latestPayout
                primaryMetricGrid
                financialTimeline
                operationsGrid
                wealthGrid
                aiInsight
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 12)
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
                MilliWordmark(fontSize: 30, tracking: 5.8)
                Text("MONEY, MADE INTELLIGENT.")
                    .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                    .tracking(1.7)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Button {
                showNotifications = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.045))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.7)
                        }
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.silverBright)
                    Circle()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: 6, height: 6)
                        .offset(x: 11, y: -11)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.60), radius: 3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
    }

    // MARK: Available to Spend

    private var availableHero: some View {
        Button {
            navigate?(.accounts)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AVAILABLE TO SPEND")
                            .font(MilliFont.sectionLabel)
                            .tracking(1.1)
                            .foregroundStyle(MilliColors.textSecondary)
                        Text("After protected allocations")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
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
                    .font(.custom("Sora-Bold", size: 43, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                ZStack(alignment: .bottomTrailing) {
                    MilliSparkline(
                        data: viewModel.sparklineData,
                        color: MilliColors.cyanGlow,
                        height: 62,
                        lineWidth: 2.1
                    )

                    HStack(spacing: 7) {
                        Text("Updated just now")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "031013"))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(MilliColors.cyanGlow))
                            .shadow(color: MilliColors.cyanGlow.opacity(0.32), radius: 7)
                    }
                }
            }
            .padding(17)
            .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
            .background(heroCardBackground)
        }
        .buttonStyle(.plain)
    }

    private var heroCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "101C22"), Color(hex: "081014"), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.24), MilliColors.cyanGlow.opacity(0.22), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            }
            .shadow(color: .black.opacity(0.46), radius: 16, y: 8)
            .shadow(color: MilliColors.cyanGlow.opacity(0.055), radius: 18)
    }

    // MARK: Latest payout

    private var latestPayout: some View {
        Button {
            navigate?(.vault)
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.035))
                        .frame(width: 52, height: 52)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                        }

                    Image(viewModel.latestPayout.platformAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 3) {
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

                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.latestPayout.amount)
                        .font(.custom("Sora-Bold", size: 20))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text("AUTOPILOT")
                            .font(.custom("Inter-SemiBold", size: 8.5))
                            .tracking(0.5)
                    }
                    .foregroundStyle(MilliColors.cyanGlow)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: Primary metrics

    private var primaryMetricGrid: some View {
        HStack(spacing: 10) {
            taxVaultTile
            taxReadyTile
        }
    }

    private var taxVaultTile: some View {
        Button { navigate?(.taxVault) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                    Spacer()
                    progressRing(progress: 0.23, value: nil, size: 36)
                }

                Text("MILLI TAX VAULT™")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(viewModel.taxVaultBalance)
                    .font(.custom("Sora-Bold", size: 22))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                Text("23% of annual target")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    private var taxReadyTile: some View {
        Button { navigate?(.taxReadyScore) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MilliColors.positive)
                    Spacer()
                    progressRing(
                        progress: CGFloat(viewModel.taxReadyScore) / 100,
                        value: "\(viewModel.taxReadyScore)",
                        size: 44
                    )
                }

                Text("TAX READY SCORE™")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text("Great")
                    .font(.custom("Sora-Bold", size: 21))
                    .foregroundStyle(MilliColors.positive)

                Text("On track for tax season")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(2)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: Financial Timeline

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

            timelineRow(
                icon: "arrow.down.circle.fill",
                title: "Payout received",
                detail: "Amazon Flex",
                amount: "$187.42",
                color: MilliColors.cyanGlow,
                showsConnector: true
            )
            timelineRow(
                icon: "lock.shield.fill",
                title: "Taxes protected",
                detail: "Milli Tax Vault™ • 25%",
                amount: "-$46.86",
                color: MilliColors.positive,
                showsConnector: true
            )
            timelineRow(
                icon: "checkmark.circle.fill",
                title: "Available to spend",
                detail: "Allocation complete",
                amount: "$140.56",
                color: MilliColors.silverBright,
                showsConnector: false
            )
        }
        .padding(15)
        .background(dashboardCardBackground)
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
                        .fill(color.opacity(0.10))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle().stroke(color.opacity(0.26), lineWidth: 0.7)
                        }
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
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

    // MARK: Operations and wealth

    private var operationsGrid: some View {
        HStack(spacing: 10) {
            quarterlyTile
            mileageTile
        }
    }

    private var quarterlyTile: some View {
        Button { navigate?(.quarterlyTaxes) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                Text("QUARTERLY TAXES")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(viewModel.quarterlyTaxes)
                    .font(.custom("Sora-Bold", size: 20))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Text(viewModel.quarterlyDueLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    private var mileageTile: some View {
        Button { navigate?(.activity) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                Text("MILEAGE")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(viewModel.mileage)
                    .font(.custom("Sora-Bold", size: 20))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("This quarter")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    private var wealthGrid: some View {
        HStack(spacing: 10) {
            wealthTile(
                title: "RETIREMENT",
                value: "$8,420",
                detail: "+$312 this month",
                icon: "building.columns.fill",
                color: MilliColors.positive,
                destination: .retirement
            )
            wealthTile(
                title: "INVESTING",
                value: "$3,184",
                detail: "+4.8% this year",
                icon: "chart.line.uptrend.xyaxis",
                color: MilliColors.cyanGlow,
                destination: .investing
            )
        }
    }

    private func wealthTile(
        title: String,
        value: String,
        detail: String,
        icon: String,
        color: Color,
        destination: ActiveScreen
    ) -> some View {
        Button { navigate?(destination) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(value)
                    .font(.custom("Sora-Bold", size: 20))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    private func progressRing(progress: CGFloat, value: String?, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.09), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if let value {
                Text(value)
                    .font(.custom("Sora-SemiBold", size: 12))
                    .foregroundStyle(MilliColors.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: AI Insight

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 13) {
                MilliAICharacterView(size: 62, animated: true)
                    .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("MILLI AI INSIGHT")
                            .font(MilliFont.sectionLabel)
                            .tracking(0.75)
                            .foregroundStyle(MilliColors.cyanGlow)
                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .frame(width: 4, height: 4)
                            .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 3)
                    }
                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(dashboardCardBackground)
        }
        .buttonStyle(.plain)
    }

    private var dashboardCardBackground: some View {
        RoundedRectangle(cornerRadius: 19, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "10191E"), Color(hex: "080D10")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), MilliColors.cyanGlow.opacity(0.10), Color.white.opacity(0.035)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: .black.opacity(0.34), radius: 10, y: 5)
    }
}
