import SwiftUI

// MARK: - HomeView
// Reference-locked financial command center. Production values still come from
// HomeViewModel; the premium reference layout never invents financial truth.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                header
                spendHero
                primaryGrid
                financialTimeline
                secondaryGrid
                aiInsight
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 12)
        }
        .background(referenceBackground)
        .sheet(isPresented: $showNotifications) {
            MilliDetailSheet(title: "Notifications")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var referenceBackground: some View {
        ZStack {
            MilliColors.obsidian.ignoresSafeArea()
            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.055), .clear],
                center: UnitPoint(x: 0.82, y: 0.04),
                startRadius: 0,
                endRadius: 330
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            MilliWordmark(fontSize: 25)
                .frame(maxWidth: 154, alignment: .leading)

            Spacer()

            HStack(spacing: 8) {
                Image("milli-ai-robot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 7)

                Button {
                    showNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MilliColors.silverBright)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.035)))
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.7))

                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .frame(width: 7, height: 7)
                            .shadow(color: MilliColors.cyanGlow, radius: 3)
                            .offset(x: -2, y: 2)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notifications")
            }
        }
        .frame(height: 48)
    }

    private var spendHero: some View {
        Button { navigate?(.accounts) } label: {
            ZStack(alignment: .trailing) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Text("AVAILABLE TO SPEND")
                            .font(MilliFont.sectionLabel)
                            .tracking(1.05)
                            .foregroundStyle(MilliColors.textSecondary)
                        ProvenanceTag(label: viewModel.provenance)
                    }

                    Text(viewModel.availableToSpend)
                        .font(.custom("Sora-Bold", size: 38, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(viewModel.provenance == .unavailable
                         ? "Connect verified accounts"
                         : "From connected accounts")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)

                    Spacer(minLength: 46)
                }
                .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
                .padding(16)

                MilliMetalCard(size: CGSize(width: 136, height: 86))
                    .rotationEffect(.degrees(-4))
                    .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 10, x: 0, y: 6)
                    .padding(.trailing, 10)
                    .offset(y: 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "171C21"), Color(hex: "090D11")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.42), MilliColors.cyanGlow.opacity(0.20), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    }
                    .shadow(color: .black.opacity(0.66), radius: 18, y: 10)
            )
        }
        .buttonStyle(.plain)
    }

    private var primaryGrid: some View {
        HStack(alignment: .stretch, spacing: 9) {
            latestPayoutCard
                .frame(maxWidth: .infinity)
            taxVaultCard
                .frame(maxWidth: .infinity)
            taxReadyCard
                .frame(maxWidth: .infinity)
        }
    }

    private var latestPayoutCard: some View {
        Button { navigate?(.vault) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("LATEST PAYOUT")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.65)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Spacer()
                }

                if let payout = viewModel.latestPayout {
                    Image(payout.platformAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 27)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(payout.amount)
                        .font(MilliFont.numericSmall)
                        .foregroundStyle(MilliColors.positive)
                    Text(payout.platformName)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                } else {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(MilliColors.chromeMid)
                        .frame(height: 28)
                    Text("Unavailable")
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Connect payout account")
                        .font(.custom("Inter-Regular", size: 9, relativeTo: .caption2))
                        .foregroundStyle(MilliColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .frame(minHeight: 138, alignment: .topLeading)
            .milliCard(padding: 11)
        }
        .buttonStyle(.plain)
    }

    private var taxVaultCard: some View {
        Button { navigate?(.taxVault) } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("MILLI TAX VAULT™")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .minimumScaleFactor(0.72)

                Text(viewModel.taxVaultBalance)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)

                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(MilliColors.chromeDeep)
                        .frame(width: 54, height: 47)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(MilliColors.precisionChromeEdge, lineWidth: 0.8)
                        )
                    Image("MilliMLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 27)
                }
                .frame(maxWidth: .infinity)

                Text(viewModel.taxVaultProgress == nil ? "Reserve not yet available" : "Protected tax funds")
                    .font(.custom("Inter-Regular", size: 9, relativeTo: .caption2))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .frame(minHeight: 138, alignment: .topLeading)
            .milliCard(padding: 11)
        }
        .buttonStyle(.plain)
    }

    private var taxReadyCard: some View {
        Button { navigate?(.taxReadyScore) } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text("TAX READY SCORE™")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.55)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.taxReadyScore ?? 0) / 100)
                        .stroke(
                            AngularGradient(
                                colors: [MilliColors.deepCyan, MilliColors.cyanGlow, Color.white],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 6)

                    Text(viewModel.taxReadyScore.map(String.init) ?? "—")
                        .font(.custom("Sora-Bold", size: 23, relativeTo: .title2))
                        .foregroundStyle(MilliColors.textPrimary)
                }
                .frame(width: 66, height: 66)
                .frame(maxWidth: .infinity)

                Text(viewModel.taxReadyScore == nil ? "Complete your tax profile" : "You're on track")
                    .font(.custom("Inter-Regular", size: 9, relativeTo: .caption2))
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(2)
            }
            .frame(minHeight: 138, alignment: .topLeading)
            .milliCard(padding: 11)
        }
        .buttonStyle(.plain)
    }

    private var financialTimeline: some View {
        Button { navigate?(.quarterlyTaxes) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("FINANCIAL TIMELINE")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.85)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Spacer()
                    Text("See timeline")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(MilliColors.textTertiary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.13)).frame(height: 1)
                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .frame(width: 12, height: 12)
                            .shadow(color: MilliColors.cyanGlow.opacity(0.60), radius: 5)
                        ForEach(1..<5, id: \.self) { index in
                            Circle()
                                .fill(Color(hex: "A6ADB3"))
                                .frame(width: 8, height: 8)
                                .position(
                                    x: geo.size.width * CGFloat(index) / 4.0,
                                    y: geo.size.height / 2
                                )
                        }
                    }
                }
                .frame(height: 14)

                HStack {
                    timelineMetric("NOW", viewModel.latestPayout?.amount ?? "—", "Income")
                    Spacer()
                    timelineMetric("TAXES", viewModel.quarterlyTaxes, "Est. taxes")
                    Spacer()
                    timelineMetric("MILES", viewModel.mileage, "Business")
                }
            }
            .milliCard(padding: 12)
        }
        .buttonStyle(.plain)
    }

    private func timelineMetric(_ date: String, _ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(date)
                .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                .tracking(0.6)
                .foregroundStyle(MilliColors.cyanGlow)
            Text(value)
                .font(.custom("Sora-SemiBold", size: 11, relativeTo: .caption))
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.custom("Inter-Regular", size: 8, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textTertiary)
        }
    }

    private var secondaryGrid: some View {
        HStack(alignment: .stretch, spacing: 9) {
            miniCard(
                title: "MILEAGE SNAPSHOT",
                value: viewModel.mileage,
                detail: viewModel.mileage == "Unavailable" ? "No tracked mileage yet" : "This period",
                icon: "car.fill",
                screen: .activity
            )

            miniCard(
                title: "RETIRE & INVEST",
                value: "Future you",
                detail: "Planning & wealth",
                icon: "leaf.fill",
                screen: .wealthOverview
            )

            Button { navigate?(.treeOfLife) } label: {
                VStack(alignment: .leading, spacing: 7) {
                    Text("WEALTH TREE")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.55)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Image("tree-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 8)
                    Text("Build wealth. Create legacy.")
                        .font(.custom("Inter-Regular", size: 9, relativeTo: .caption2))
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
                .milliCard(padding: 10)
            }
            .buttonStyle(.plain)
        }
    }

    private func miniCard(title: String, value: String, detail: String, icon: String, screen: ActiveScreen) -> some View {
        Button { navigate?(screen) } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .minimumScaleFactor(0.72)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MilliColors.silverBright)
                    .frame(height: 30)
                Text(value)
                    .font(.custom("Sora-SemiBold", size: 15, relativeTo: .body))
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(detail)
                    .font(.custom("Inter-Regular", size: 9, relativeTo: .caption2))
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .milliCard(padding: 10)
        }
        .buttonStyle(.plain)
    }

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 10) {
                Image("milli-ai-robot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("MILLI AI INSIGHT")
                            .font(MilliFont.sectionLabel)
                            .tracking(0.75)
                            .foregroundStyle(MilliColors.cyanGlow)
                        ProvenanceTag(label: viewModel.provenance)
                    }
                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }
            .milliCard(padding: 11)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
