import SwiftUI

// MARK: - HomeView — Primary dashboard screen (Screen 1)
// Header: MILLI wordmark + bell | Available to Spend hero | Latest Payout
// 2x2 metric grid | AI Insight card

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                heroCard
                latestPayoutRow
                metricGrid
                aiInsightCard
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100) // Clear bottom nav
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header (MILLI wordmark + bell icon)

    private var headerSection: some View {
        HStack {
            // MILLI wordmark — spaced letters, chrome gradient
            Text("M I L L I")
                .font(MilliFont.wordmark)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, MilliColors.cyanGlow.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(1)

            Spacer()

            // Notification bell
            Button {} label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MilliColors.silver)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Hero Card (Available to Spend)

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("Available to Spend")
                .font(MilliFont.labelLarge)
                .foregroundColor(MilliColors.textSecondary)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.availableToSpend)
                        .font(MilliFont.heroNumber)
                        .foregroundColor(MilliColors.cyanGlow)
                        .contentTransition(.numericText())

                    Text("Updated just now")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.textTertiary)
                }

                Spacer()

                // Sparkline + arrow button
                HStack(spacing: 12) {
                    MilliSparkline(
                        data: viewModel.sparklineData,
                        color: MilliColors.cyanGlow,
                        height: 40
                    )
                    .frame(width: 64)

                    // Cyan-filled circle arrow button
                    Button {} label: {
                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(MilliColors.blackGlass)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(MilliSpacing.cardPaddingLarge)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusXl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MilliColors.heroGradientTop, MilliColors.heroGradientBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusXl, style: .continuous)
                        .stroke(MilliColors.cardBorderGlow, lineWidth: 1)
                )
        )
    }

    // MARK: - Latest Payout Row

    private var latestPayoutRow: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("LATEST PAYOUT")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1.0)

            HStack(spacing: MilliSpacing.md) {
                // Walmart/Spark icon circle
                Circle()
                    .fill(Color(hex: "0071CE"))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("$312.64")
                        .font(MilliFont.numericMedium)
                        .foregroundColor(MilliColors.textPrimary)

                    Text("Today, 9:41 AM \u{2022} Spark Driver")
                        .font(MilliFont.bodySmall)
                        .foregroundColor(MilliColors.textSecondary)
                }

                Spacer()
            }
            .milliCard()
        }
    }

    // MARK: - 2x2 Metric Grid

    private var metricGrid: some View {
        VStack(spacing: MilliSpacing.gridGap) {
            HStack(spacing: MilliSpacing.gridGap) {
                taxVaultCard
                taxReadyScoreCard
            }
            HStack(spacing: MilliSpacing.gridGap) {
                quarterlyTaxesCard
                mileageCard
            }
        }
    }

    // Tax Vault card
    private var taxVaultCard: some View {
        Button {
            navigate?(.taxVault)
        } label: {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("MILLI TAX VAULT")
                    .font(MilliFont.label)
                    .foregroundColor(MilliColors.textLabel)
                    .tracking(0.8)

                Text(viewModel.taxVaultBalance)
                    .font(MilliFont.numericMedium)
                    .foregroundColor(MilliColors.cyanGlow)

                Text("23% of annual target")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textSecondary)

                // Mini donut indicator
                ZStack {
                    Circle()
                        .stroke(MilliColors.border, lineWidth: 3)
                        .frame(width: 28, height: 28)
                    Circle()
                        .trim(from: 0, to: 0.23)
                        .stroke(MilliColors.cyanGlow, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .milliCard()
        }
        .buttonStyle(.plain)
    }

    // Tax Ready Score card
    private var taxReadyScoreCard: some View {
        Button {
            navigate?(.taxReadyScore)
        } label: {
            VStack(spacing: MilliSpacing.sm) {
                Text("TAX READY SCORE")
                    .font(MilliFont.label)
                    .foregroundColor(MilliColors.textLabel)
                    .tracking(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(MilliColors.border, lineWidth: 4)
                        .frame(width: 54, height: 54)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.taxReadyScore) / 100.0)
                        .stroke(MilliColors.cyanGlow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(-90))
                    Text("\(viewModel.taxReadyScore)")
                        .font(MilliFont.numericMedium)
                        .foregroundColor(MilliColors.textPrimary)
                }

                Text("Great - You're on track\nfor tax season")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.positive)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .milliCard()
        }
        .buttonStyle(.plain)
    }

    // Quarterly Taxes card
    private var quarterlyTaxesCard: some View {
        Button {
            navigate?(.quarterlyTaxes)
        } label: {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("QUARTERLY TAXES")
                    .font(MilliFont.label)
                    .foregroundColor(MilliColors.textLabel)
                    .tracking(0.8)

                Text(viewModel.quarterlyTaxes)
                    .font(MilliFont.numericMedium)
                    .foregroundColor(MilliColors.cyanGlow)

                Text("Est. due Jun 15, 2024")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .milliCard()
        }
        .buttonStyle(.plain)
    }

    // Mileage card
    private var mileageCard: some View {
        Button {
            navigate?(.mileage)
        } label: {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("MILEAGE")
                    .font(MilliFont.label)
                    .foregroundColor(MilliColors.textLabel)
                    .tracking(0.8)

                HStack(spacing: 6) {
                    Text(viewModel.mileage)
                        .font(MilliFont.numericMedium)
                        .foregroundColor(MilliColors.cyanGlow)
                }

                Image(systemName: "car.fill")
                    .font(.system(size: 18))
                    .foregroundColor(MilliColors.cyanGlow.opacity(0.7))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .milliCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Insight Card

    private var aiInsightCard: some View {
        Button {
            navigate?(.milliAI)
        } label: {
            HStack(spacing: MilliSpacing.md) {
                // Robot avatar
                ZStack {
                    Circle()
                        .fill(MilliColors.cyanGlow.opacity(0.12))
                        .frame(width: 44, height: 44)

                    // Robot face
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1A2E4A"), Color(hex: "0D1B2E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 30, height: 26)
                        .overlay(
                            HStack(spacing: 6) {
                                Circle().fill(MilliColors.cyanGlow).frame(width: 6, height: 6)
                                Circle().fill(MilliColors.cyanGlow).frame(width: 6, height: 6)
                            }
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("MILLI AI INSIGHT")
                        .font(MilliFont.label)
                        .foregroundColor(MilliColors.textLabel)
                        .tracking(0.8)

                    Text(viewModel.aiInsight)
                        .font(MilliFont.bodyMedium)
                        .foregroundColor(MilliColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MilliColors.textTertiary)
            }
            .milliCard(padding: MilliSpacing.cardPaddingLarge)
        }
        .buttonStyle(.plain)
    }
}
