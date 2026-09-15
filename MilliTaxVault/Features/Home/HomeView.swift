import SwiftUI

// MARK: - HomeView
// Canonical Milli dashboard. The composition is intentionally cinematic and
// dense: a fixed premium header, one dominant financial hero, concise payout
// state, tax confidence, money flow, operating metrics and one integrated Milli
// AI insight. Decorative UI never outranks financial information.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ZStack {
            screenBackground

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 3)
                    .padding(.bottom, 7)

                headerGlint
                    .padding(.horizontal, 28)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        spendHero
                        latestPayout
                        taxConfidenceRow
                        allocationTimeline
                        operatingMetrics
                        aiInsight
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.bottom, MilliSpacing.bottomContentClearance + 10)
                }
            }
        }
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
                colors: [Color(hex: "071015"), Color(hex: "030506"), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.070), .clear],
                center: UnitPoint(x: 0.82, y: 0.08),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.025), .clear],
                center: UnitPoint(x: 0.12, y: 0.02),
                startRadius: 0,
                endRadius: 220
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            MilliMMark(size: 29)
                .frame(width: 34, height: 34)

            Spacer()

            VStack(spacing: 2) {
                Text(greeting)
                    .font(.custom("Sora-Medium", size: 16.5, relativeTo: .headline))
                    .foregroundStyle(MilliColors.textPrimary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(MilliColors.positive)
                        .frame(width: 4, height: 4)
                    Text("AUTOPILOT • PROTECTED")
                        .font(.custom("Inter-SemiBold", size: 7.6, relativeTo: .caption2))
                        .tracking(1.0)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }

            Spacer()

            Button {
                showNotifications = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "182127"), Color(hex: "070A0D"), .black],
                                center: UnitPoint(x: 0.38, y: 0.28),
                                startRadius: 1,
                                endRadius: 24
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.30), Color.white.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.7
                                )
                        }

                    Image(systemName: "bell")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MilliColors.silverBright)

                    Circle()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: 5, height: 5)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.60), radius: 3)
                        .offset(x: 10, y: -10)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .frame(height: 44)
    }

    private var headerGlint: some View {
        LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.13), MilliColors.cyanGlow.opacity(0.20), Color.white.opacity(0.07), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 0.7)
    }

    // MARK: - Available to spend

    private var spendHero: some View {
        Button { navigate?(.accounts) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "162229"), Color(hex: "0A1014"), Color(hex: "030506")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image("home-hero-bg")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.16)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                RadialGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.12), Color.clear],
                    center: UnitPoint(x: 0.88, y: 0.72),
                    startRadius: 0,
                    endRadius: 150
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.clear, Color.black.opacity(0.48)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("AVAILABLE TO SPEND")
                            .font(.custom("Inter-SemiBold", size: 9.4, relativeTo: .caption))
                            .tracking(1.15)
                            .foregroundStyle(MilliColors.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(viewModel.availableToSpend)
                                .font(.custom("Sora-SemiBold", size: 34, relativeTo: .largeTitle))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.70)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Text("AFTER PROTECTED ALLOCATIONS")
                            .font(.custom("Inter-Medium", size: 7.8, relativeTo: .caption2))
                            .tracking(0.76)
                            .foregroundStyle(MilliColors.textTertiary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(MilliColors.positive)
                                .frame(width: 5, height: 5)
                                .shadow(color: MilliColors.positive.opacity(0.45), radius: 3)
                            Text("Updated just now")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 4)

                    MilliDebitCardMini()
                        .frame(width: 120, height: 81)
                        .rotationEffect(.degrees(-6))
                        .shadow(color: .black.opacity(0.55), radius: 12, y: 8)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 10, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .frame(height: 148)
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.34), Color(hex: "707980").opacity(0.16), MilliColors.cyanGlow.opacity(0.24), Color.white.opacity(0.025)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.78
                    )
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.36), Color.white.opacity(0.05), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.8)
                .padding(.horizontal, 20)
            }
            .shadow(color: .black.opacity(0.58), radius: 18, y: 10)
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
                        .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                        .tracking(0.82)
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
                        .font(.custom("Sora-SemiBold", size: 18.5, relativeTo: .title3))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.cyanGlow)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.12), radius: 5)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("AUTOPILOT")
                    }
                    .font(.custom("Inter-SemiBold", size: 8.1, relativeTo: .caption2))
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.positive)
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 68)
            .background(premiumSurface(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var platformBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1B2227"), Color(hex: "070A0D")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                }

            Image(viewModel.latestPayout.platformAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
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
                        .font(.custom("Sora-SemiBold", size: 22.5, relativeTo: .title2))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    Text("Protected for taxes")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.065))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [MilliColors.deepCyan, Color(hex: "8AF8FF")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.58)
                                .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 3)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(13)
                .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
                .background(premiumSurface(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button { navigate?(.taxReadyScore) } label: {
                VStack(spacing: 6) {
                    HStack {
                        Text("TAX READY SCORE™")
                            .font(.custom("Inter-SemiBold", size: 8.2, relativeTo: .caption2))
                            .tracking(0.65)
                            .foregroundStyle(MilliColors.textSecondary)
                        Spacer()
                    }

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.07), lineWidth: 8)

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
                                .font(.custom("Sora-SemiBold", size: 26, relativeTo: .title2))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("ON TRACK")
                                .font(.custom("Inter-SemiBold", size: 7.3, relativeTo: .caption2))
                                .tracking(0.6)
                                .foregroundStyle(MilliColors.positive)
                        }
                    }
                    .frame(width: 72, height: 72)
                }
                .padding(13)
                .frame(maxWidth: .infinity, minHeight: 126, alignment: .top)
                .background(premiumSurface(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Allocation timeline

    private var allocationTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FINANCIAL FLOW")
                    .font(.custom("Inter-SemiBold", size: 9.2, relativeTo: .caption))
                    .tracking(0.85)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("LATEST PAYOUT")
                    .font(.custom("Inter-SemiBold", size: 7.8, relativeTo: .caption2))
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
        .padding(13)
        .background(premiumSurface(cornerRadius: 16))
    }

    private func flowNode(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle().stroke(accent, lineWidth: 1.35)
                    }
                Circle()
                    .fill(accent)
                    .frame(width: 4, height: 4)
                    .shadow(color: accent.opacity(0.55), radius: 2)
            }

            Text(title.uppercased())
                .font(.custom("Inter-SemiBold", size: 7.7, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textTertiary)

            Text(value)
                .font(.custom("Sora-Medium", size: 11.3, relativeTo: .caption))
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
                    colors: [MilliColors.cyanGlow.opacity(0.42), Color.white.opacity(0.09)],
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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.custom("Inter-SemiBold", size: 7.6, relativeTo: .caption2))
                        .tracking(0.5)
                        .foregroundStyle(MilliColors.textTertiary)
                    Spacer(minLength: 2)
                    Image(systemName: icon)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(accent)
                }

                Text(value)
                    .font(.custom("Sora-SemiBold", size: 13.2, relativeTo: .subheadline))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.60)

                Text(detail)
                    .font(.custom("Inter-Medium", size: 8.3, relativeTo: .caption2))
                    .foregroundStyle(accent.opacity(0.86))
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
            .background(premiumSurface(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Milli AI insight

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 9) {
                MilliAICharacterView(size: 64, animated: true)
                    .frame(width: 60, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text("MILLI AI INSIGHT")
                            .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                            .tracking(0.75)
                            .foregroundStyle(MilliColors.cyanGlow)
                        Circle()
                            .fill(MilliColors.positive)
                            .frame(width: 4, height: 4)
                    }

                    Text(viewModel.aiInsight)
                        .font(.custom("Inter-Medium", size: 11.7, relativeTo: .caption))
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
            .padding(.vertical, 6)
            .background(premiumSurface(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared local surface

    private func premiumSurface(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return shape
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "11191D"), location: 0.00),
                        .init(color: Color(hex: "080C0F"), location: 0.48),
                        .init(color: Color(hex: "030506"), location: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RadialGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.045), .clear],
                    center: UnitPoint(x: 0.92, y: 0.05),
                    startRadius: 0,
                    endRadius: 100
                )
                .clipShape(shape)
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color(hex: "808990").opacity(0.09), MilliColors.cyanGlow.opacity(0.09), Color.white.opacity(0.018)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.72
                    )
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.22), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.7)
                .padding(.horizontal, 16)
            }
            .shadow(color: Color.black.opacity(0.48), radius: 11, y: 7)
    }
}

// MARK: - Native Milli card visual
// Decorative only: no account data is encoded into the card artwork.

private struct MilliDebitCardMini: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "8A9298"), location: 0.00),
                            .init(color: Color(hex: "3C4348"), location: 0.32),
                            .init(color: Color(hex: "171C20"), location: 0.68),
                            .init(color: Color(hex: "07090B"), location: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            LinearGradient(
                colors: [Color.clear, MilliColors.cyanGlow.opacity(0.92), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 150, height: 1.6)
            .rotationEffect(.degrees(-31))
            .offset(x: -8, y: 54)

            VStack(alignment: .leading, spacing: 6) {
                MilliMMark(size: 23)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "BFC4C7"), Color(hex: "666D72")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.46), Color(hex: "6D757B").opacity(0.25), MilliColors.cyanGlow.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.65
                )
        }
    }
}
