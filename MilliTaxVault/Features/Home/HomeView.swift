import SwiftUI

// MARK: - HomeView
// Primary financial cockpit, reconstructed against the MILLI Deviation/
// Acceptance Spec v1 (Aug 28, 2026), section 3: four-tier hierarchy with two
// surface families.
//   Tier 1 (hero): elevated graphite surface — #17202B -> #0B1116 vertical
//     gradient, cyan edge light, specular top highlight, floating shadow.
//   Tier 2 (metric tiles / list rows): recessed black-glass — Obsidian fill,
//     inner shadow, 0.5pt white 5% border, inset into the background.
//   Tier 3: section labels — cyan, Inter 10 uppercase, 1pt tracking.
//   Tier 4: background — Obsidian with ambient cyan bloom behind the hero.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                headerSection
                availableHero
                latestPayout
                metricGrid
                aiInsight
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(
            ZStack {
                MilliColors.background
                // Ambient cyan bloom behind the hero tier.
                RadialGradient(
                    colors: [
                        MilliColors.cyanGlow.opacity(0.10),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.18),
                    startRadius: 10,
                    endRadius: 260
                )
            }
            .ignoresSafeArea()
        )
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
            }

            MilliWordmark()
        }
        .frame(height: 46)
    }

    // MARK: Available to Spend — Tier 1 elevated graphite hero

    private var availableHero: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("AVAILABLE TO SPEND")
                .font(MilliFont.sectionLabel)
                .tracking(1)
                .foregroundColor(MilliColors.cyanGlow.opacity(0.9))

            Text(viewModel.availableToSpend)
                .font(MilliFont.heroBalance)
                .monospacedDigit()
                .foregroundColor(MilliColors.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.82)

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
                .padding(.trailing, 2)
            }
        }
        .padding(14)
        .background(
            // Tier 1: elevated graphite surface.
            RoundedRectangle(cornerRadius: MilliSpacing.radiusXl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "17202B"), Color(hex: "0B1116")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            // Cyan edge light.
            RoundedRectangle(cornerRadius: MilliSpacing.radiusXl, style: .continuous)
                .stroke(MilliColors.cyanGlow.opacity(0.22), lineWidth: 0.8)
        )
        .overlay(
            // Specular top highlight.
            RoundedRectangle(cornerRadius: MilliSpacing.radiusXl, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.07), location: 0.0),
                            .init(color: Color.clear, location: 0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.42), radius: 14, y: 6)
    }

    // MARK: Latest payout — Tier 2 recessed row

    private var latestPayout: some View {
        Button {
            navigate?(.vault)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LATEST PAYOUT")
                        .font(MilliFont.sectionLabel)
                        .tracking(1)
                        .foregroundColor(MilliColors.cyanGlow.opacity(0.75))
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

                Spacer(minLength: 8)

                Image(viewModel.latestPayout.platformAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                    }
                }
                .milliRecessedCard()
            }
            .buttonStyle(.plain)
    }

    // MARK: Metric grid — Tier 2 recessed black-glass tiles

    private var metricGrid: some View {
        VStack(spacing: MilliSpacing.gridGap) {
            HStack(spacing: MilliSpacing.gridGap) {
                taxVaultTile
                taxReadyTile
            }
            HStack(spacing: MilliSpacing.gridGap) {
                quarterlyTile
                mileageTile
            }
        }
    }

    private var taxVaultTile: some View {
        Button { navigate?(.taxVault) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("MILLI TAX VAULT™")
                    .font(MilliFont.sectionLabel)
                    .tracking(1)
                    .foregroundColor(MilliColors.cyanGlow.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(alignment: .center, spacing: 7) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.taxVaultBalance)
                            .font(MilliFont.numericMedium)
                            .monospacedDigit()
                            .foregroundColor(MilliColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.66)
                            .allowsTightening(true)
                        Text("23% of annual target")
                            .font(MilliFont.caption)
                            .foregroundColor(MilliColors.textTertiary)
                            .lineLimit(2)
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 0)
                    progressRing(progress: 0.23, value: nil, size: 34)
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
            .milliRecessedCard()
        }
        .buttonStyle(.plain)
    }

    private var taxReadyTile: some View {
        Button { navigate?(.taxReadyScore) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("TAX READY SCORE™")
                    .font(MilliFont.sectionLabel)
                    .tracking(1)
                    .foregroundColor(MilliColors.cyanGlow.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(spacing: 8) {
                    progressRing(
                        progress: CGFloat(viewModel.taxReadyScore) / 100,
                        value: "\(viewModel.taxReadyScore)",
                        size: 44
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Great")
                            .font(MilliFont.labelLarge)
                            .foregroundColor(MilliColors.positive)
                        Text("You're on track\nfor tax season")
                            .font(MilliFont.caption)
                            .foregroundColor(MilliColors.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
            .milliRecessedCard()
        }
        .buttonStyle(.plain)
    }

    private var quarterlyTile: some View {
        Button { navigate?(.quarterlyTaxes) } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text("QUARTERLY TAXES")
                    .font(MilliFont.sectionLabel)
                    .tracking(1)
                    .foregroundColor(MilliColors.cyanGlow.opacity(0.75))
                Text(viewModel.quarterlyTaxes)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundColor(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                HStack(spacing: 5) {
                    Text(viewModel.quarterlyDueLabel)
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textTertiary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MilliColors.cyanGlow)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
            .milliRecessedCard()
        }
        .buttonStyle(.plain)
    }

    private var mileageTile: some View {
        Button { navigate?(.activity) } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text("MILEAGE")
                    .font(MilliFont.sectionLabel)
                    .tracking(1)
                    .foregroundColor(MilliColors.cyanGlow.opacity(0.75))
                Text(viewModel.mileage)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundColor(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                HStack {
                    Text("This quarter")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textTertiary)
                    Spacer()
                    Image(systemName: "car.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MilliColors.cyanGlow)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
            .milliRecessedCard()
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

    // MARK: AI Insight — Tier 2 recessed

    private var aiInsight: some View {
        Button { navigate?(.milliAI) } label: {
            HStack(spacing: 10) {
                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 0.7)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("MILLI AI INSIGHT")
                        .font(MilliFont.sectionLabel)
                        .tracking(1)
                        .foregroundColor(MilliColors.cyanGlow)
                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodySmall)
                        .foregroundColor(MilliColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MilliColors.cyanGlow)
            }
            .milliRecessedCard(padding: 12)
        }
        .buttonStyle(.plain)
    }
}
