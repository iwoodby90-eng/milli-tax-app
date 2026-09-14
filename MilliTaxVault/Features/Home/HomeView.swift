import SwiftUI

// MARK: - HomeView
// Canonical Milli home dashboard. The screen deliberately mirrors the approved
// high-fidelity product direction: one clear balance hero, a concise payout
// state, tax confidence, a financial flow, three compact operational metrics,
// and one integrated Milli AI insight. Decorative UI never outranks financial
// information.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                topBar
                spendHero
                latestPayout
                taxConfidenceRow
                allocationTimeline
                operatingMetrics
                aiInsight
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 6)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 12)
        }
        .background(screenBackground)
        .sheet(isPresented: $showNotifications) {
            MilliDetailSheet(title: "Notifications")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Background

    private var screenBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "071116"), Color(hex: "030507"), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.075), .clear],
                center: UnitPoint(x: 0.86, y: 0.08),
                startRadius: 0,
                endRadius: 270
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var topBar: some View {
        HStack(spacing: 12) {
            MilliMMark(size: 30)
                .frame(width: 34, height: 34)

            Spacer()

            VStack(spacing: 1) {
                Text("Good morning")
                    .font(.custom("Sora-Medium", size: 17, relativeTo: .headline))
                    .foregroundStyle(MilliColors.textPrimary)

                Text("MONEY, MADE INTELLIGENT.")
                    .font(.custom("Inter-Medium", size: 7.8, relativeTo: .caption2))
                    .tracking(1.4)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Button {
                showNotifications = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.035))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.09), lineWidth: 0.7)
                        }

                    Image(systemName: "bell")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MilliColors.silverBright)

                    Circle()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: 5, height: 5)
                        .offset(x: 10, y: -10)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .frame(height: 46)
    }

    // MARK: - Available to spend

    private var spendHero: some View {
        Button { navigate?(.accounts) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "142128"), Color(hex: "0A1115"), Color(hex: "050709")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image("home-hero-bg")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.20)
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("AVAILABLE TO SPEND")
                            .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption))
                            .tracking(1.1)
                            .foregroundStyle(MilliColors.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(viewModel.availableToSpend)
                                .font(.custom("Sora-SemiBold", size: 35, relativeTo: .largeTitle))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.70)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Text("AFTER PROTECTED ALLOCATIONS")
                            .font(.custom("Inter-Medium", size: 8, relativeTo: .caption2))
                            .tracking(0.75)
                            .foregroundStyle(MilliColors.textTertiary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(MilliColors.positive)
                                .frame(width: 5, height: 5)
                            Text("Updated just now")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 4)

                    MilliDebitCardMini()
                        .frame(width: 118, height: 80)
                        .rotationEffect(.degrees(-6))
                        .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 10, y: 5)
                }
                .padding(16)
            }
            .frame(height: 156)
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.30), MilliColors.cyanGlow.opacity(0.28), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            }
            .shadow(color: .black.opacity(0.44), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Available to spend \(viewModel.availableToSpend). Open accounts")
    }

    // MARK: - Latest payout

    private var latestPayout: some View {
        Button { navigate?(.vault) } label: {
            HStack(spacing: 11) {
                platformBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text("LATEST PAYOUT")
                        .font(.custom("Inter-SemiBold", size: 8.6, relativeTo: .caption2))
                        .tracking(0.8)
                        .foregroundStyle(MilliColors.textTertiary)

                    Text(viewModel.latestPayout.platformName)
                        .font(.custom("Inter-SemiBold", size: 14, relativeTo: .subheadline))
                        .foregroundStyle(MilliColors.textPrimary)

                    Text(viewModel.latestPayout.dateTime)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(viewModel.latestPayout.amount)
                        .font(.custom("Sora-SemiBold", size: 19, relativeTo: .title3))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.cyanGlow)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("AUTOPILOT")
                    }
                    .font(.custom("Inter-SemiBold", size: 8.2, relativeTo: .caption2))
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.positive)
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 72)
            .background(premiumSurface(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }

    private var platformBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .frame(width: 42, height: 42)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                }

            Image(viewModel.latestPayout.platformAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
        }
    }

    // MARK: - Tax confidence

    private var taxConfidenceRow: some View {
        HStack(spacing: 9) {
            Button { navigate?(.taxVault) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("MILLI TAX VAULT™")
                            .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                            .tracking(0.8)
                            .foregroundStyle(MilliColors.textSecondary)
                        Spacer()
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }

                    Text(viewModel.taxVaultBalance)
                        .font(.custom("Sora-SemiBold", size: 23, relativeTo: .title2))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    Text("Protected for taxes")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.07))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [MilliColors.deepCyan, MilliColors.cyanGlow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.58)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(13)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                .background(premiumSurface(cornerRadius: 17))
            }
            .buttonStyle(.plain)

            Button { navigate?(.taxReadyScore) } label: {
                VStack(spacing: 7) {
                    HStack {
                        Text("TAX READY SCORE™")
                            .font(.custom("Inter-SemiBold", size: 8.2, relativeTo: .caption2))
                            .tracking(0.65)
                            .foregroundStyle(MilliColors.textSecondary)
                        Spacer()
                    }

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.taxReadyScore) / 100)
                            .stroke(
                                LinearGradient(
                                    colors: [MilliColors.deepCyan, Color(hex: "8AF8FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 5)

                        VStack(spacing: 0) {
                            Text("\(viewModel.taxReadyScore)")
                                .font(.custom("Sora-SemiBold", size: 27, relativeTo: .title2))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("ON TRACK")
                                .font(.custom("Inter-SemiBold", size: 7.5, relativeTo: .caption2))
                                .tracking(0.6)
                                .foregroundStyle(MilliColors.positive)
                        }
                    }
                    .frame(width: 76, height: 76)
                }
                .padding(13)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .top)
                .background(premiumSurface(cornerRadius: 17))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Allocation timeline

    private var allocationTimeline: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("FINANCIAL FLOW")
                    .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption))
                    .tracking(0.85)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("LATEST PAYOUT")
                    .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                    .tracking(0.7)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            HStack(alignment: .top, spacing: 0) {
                flowNode(title: "Payout", value: viewModel.latestPayout.amount, accent: MilliColors.cyanGlow)
                flowConnector
                flowNode(title: "Taxes", value: "Protected", accent: MilliColors.positive)
                flowConnector
                flowNode(title: "Spend", value: viewModel.availableToSpend, accent: MilliColors.silverBright)
            }
        }
        .padding(14)
        .background(premiumSurface(cornerRadius: 17))
    }

    private func flowNode(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.78))
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle().stroke(accent, lineWidth: 1.4)
                    }
                Circle()
                    .fill(accent)
                    .frame(width: 4, height: 4)
            }

            Text(title.uppercased())
                .font(.custom("Inter-SemiBold", size: 7.8, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textTertiary)

            Text(value)
                .font(.custom("Sora-Medium", size: 11.5, relativeTo: .caption))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.60)
        }
        .frame(maxWidth: .infinity)
    }

    private var flowConnector: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.48), Color.white.opacity(0.10)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.top, 7)
            .frame(maxWidth: 34)
    }

    // MARK: - Operating metrics

    private var operatingMetrics: some View {
        HStack(spacing: 8) {
            metricTile(
                title: "MILEAGE",
                value: viewModel.mileage,
                detail: "Business miles",
                icon: "location.north.fill",
                accent: MilliColors.cyanGlow,
                destination: .activity
            )

            metricTile(
                title: "QUARTERLY",
                value: viewModel.quarterlyTaxes,
                detail: viewModel.quarterlyDueLabel,
                icon: "calendar.badge.clock",
                accent: MilliColors.silverBright,
                destination: .quarterlyTaxes
            )

            metricTile(
                title: "WEALTH",
                value: "Plan & grow",
                detail: "Future path",
                icon: "chart.line.uptrend.xyaxis",
                accent: MilliColors.positive,
                destination: .wealthOverview
            )
        }
    }

    private func metricTile(
        title: String,
        value: String,
        detail: String,
        icon: String,
        accent: Color,
        destination: ActiveScreen
    ) -> some View {
        Button { navigate?(destination) } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(title)
                        .font(.custom("Inter-SemiBold", size: 7.8, relativeTo: .caption2))
                        .tracking(0.5)
                        .foregroundStyle(MilliColors.textTertiary)
                    Spacer(minLength: 2)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                }

                Text(value)
                    .font(.custom("Sora-SemiBold", size: 13.5, relativeTo: .subheadline))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.60)

                Text(detail)
                    .font(.custom("Inter-Medium", size: 8.5, relativeTo: .caption2))
                    .foregroundStyle(accent.opacity(0.88))
                    .lineLimit(1)
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .background(premiumSurface(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Milli AI insight

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 10) {
                MilliAICharacterView(size: 72, animated: true)
                    .frame(width: 68, height: 76)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text("MILLI AI INSIGHT")
                            .font(.custom("Inter-SemiBold", size: 8.7, relativeTo: .caption2))
                            .tracking(0.75)
                            .foregroundStyle(MilliColors.cyanGlow)
                        Circle()
                            .fill(MilliColors.positive)
                            .frame(width: 4, height: 4)
                    }

                    Text(viewModel.aiInsight)
                        .font(.custom("Inter-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "07151A"), Color(hex: "040607")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.20), lineWidth: 0.75)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared local surface

    private func premiumSurface(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "10191E"), Color(hex: "080C0F"), Color(hex: "040607")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.19), MilliColors.cyanGlow.opacity(0.10), Color.white.opacity(0.025)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: Color.black.opacity(0.40), radius: 10, y: 6)
    }
}

// MARK: - Native Milli card visual
// A lightweight native rendering keeps the dashboard cinematic without relying
// on a raster card plate. It is decorative only and contains no account data.

private struct MilliDebitCardMini: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "707880"), Color(hex: "252B30"), Color(hex: "0A0D10")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            LinearGradient(
                colors: [Color.clear, MilliColors.cyanGlow.opacity(0.90), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 150, height: 2)
            .rotationEffect(.degrees(-31))
            .offset(x: -8, y: 54)

            VStack(alignment: .leading, spacing: 7) {
                MilliMMark(size: 23)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 17, height: 12)
                Spacer()
                Text("MILLI")
                    .font(.custom("Inter-SemiBold", size: 7, relativeTo: .caption2))
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.48))
            }
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 0.7)
        }
    }
}
