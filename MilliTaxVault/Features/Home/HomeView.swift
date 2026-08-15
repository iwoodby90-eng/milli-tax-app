import SwiftUI

// MARK: - HomeView — Primary dashboard screen
// Matches the 12-screen master reference: hero card with sparkline,
// latest payout row, 2x2 metric grid, AI insight card.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

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

    // MARK: - Header (MILLI wordmark + icons)

    private var headerSection: some View {
        HStack {
            Spacer()

            // MILLI wordmark — chrome gradient
            Text("MILLI")
                .font(MilliFont.wordmark())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "00D4FF").opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(2)

            Spacer()

            // Notification bell
            Button {} label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MilliColors.textSecondary)
            }
            .buttonStyle(.plain)

            // Profile avatar
            Button {} label: {
                Circle()
                    .fill(MilliColors.cardBackgroundElevated)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MilliColors.textSecondary)
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Hero Card (Available to Spend)

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("AVAILABLE TO SPEND")
                .font(MilliFont.label())
                .foregroundColor(MilliColors.textLabel)
                .tracking(1.2)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.availableToSpend)
                        .font(MilliFont.numericLarge())
                        .foregroundColor(MilliColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("Updated just now")
                        .font(MilliFont.bodySmall())
                        .foregroundColor(MilliColors.textTertiary)
                }

                Spacer()

                // Sparkline + arrow button
                HStack(spacing: 12) {
                    MilliSparkline(
                        data: viewModel.sparklineData,
                        color: MilliColors.cyan,
                        height: 40
                    )
                    .frame(width: 60)

                    // Cyan-filled circle arrow button
                    Button {} label: {
                        Circle()
                            .fill(MilliColors.cyan)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(MilliColors.background)
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
                        .stroke(MilliColors.border, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Latest Payout Row

    private var latestPayoutRow: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("LATEST PAYOUT")
                .font(MilliFont.label())
                .foregroundColor(MilliColors.textLabel)
                .tracking(1.0)

            HStack(spacing: MilliSpacing.md) {
                // Platform logo circle
                Circle()
                    .fill(Color(hex: "1E40AF"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(viewModel.latestPayout.platformInitial)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                // Platform name + date
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.latestPayout.platformName)
                        .font(MilliFont.headlineSmall())
                        .foregroundColor(MilliColors.textPrimary)

                    Text(viewModel.latestPayout.dateTime)
                        .font(MilliFont.bodySmall())
                        .foregroundColor(MilliColors.textSecondary)
                }

                Spacer()

                // Amount
                Text(viewModel.latestPayout.amount)
                    .font(MilliFont.numericMedium())
                    .foregroundColor(MilliColors.positive)
            }
            .milliCard()
        }
    }

    // MARK: - 2x2 Metric Grid

    private var metricGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: MilliSpacing.gridGap),
                GridItem(.flexible(), spacing: MilliSpacing.gridGap)
            ],
            spacing: MilliSpacing.gridGap
        ) {
            taxVaultCard
            taxReadyScoreCard
            quarterlyTaxesCard
            mileageCard
        }
    }

    // Tax Vault card
    private var taxVaultCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("MILLI TAX VAULT\u{2122}")
                .font(MilliFont.label())
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            Text(viewModel.taxVaultBalance)
                .font(MilliFont.numericMedium())
                .foregroundColor(MilliColors.textPrimary)

            Text("22% of annual target")
                .font(MilliFont.bodySmall())
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }

    // Tax Ready Score card — with progress ring
    private var taxReadyScoreCard: some View {
        VStack(spacing: MilliSpacing.sm) {
            Text("TAX READY SCORE\u{2122}")
                .font(MilliFont.label())
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                // Background ring
                Circle()
                    .stroke(MilliColors.border, lineWidth: 4)
                    .frame(width: 52, height: 52)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.taxReadyScore) / 100.0)
                    .stroke(MilliColors.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                // Score number
                Text("\(viewModel.taxReadyScore)")
                    .font(MilliFont.numericMedium())
                    .foregroundColor(MilliColors.textPrimary)
            }

            Text("Great")
                .font(MilliFont.labelLarge())
                .foregroundColor(MilliColors.positive)
        }
        .frame(maxWidth: .infinity)
        .milliCard()
    }

    // Quarterly Taxes card
    private var quarterlyTaxesCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("QUARTERLY TAXES")
                .font(MilliFont.label())
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            Text(viewModel.quarterlyTaxes)
                .font(MilliFont.numericMedium())
                .foregroundColor(MilliColors.textPrimary)

            Text("Est. due Jun 15, 2025")
                .font(MilliFont.bodySmall())
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }

    // Mileage card
    private var mileageCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("MILEAGE")
                .font(MilliFont.label())
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            Text(viewModel.mileage)
                .font(MilliFont.numericMedium())
                .foregroundColor(MilliColors.textPrimary)

            Text("This quarter")
                .font(MilliFont.bodySmall())
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliCard()
    }

    // MARK: - AI Insight Card

    private var aiInsightCard: some View {
        HStack(spacing: MilliSpacing.md) {
            // Robot icon
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "cpu")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MilliColors.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("MILLI AI INSIGHT")
                    .font(MilliFont.label())
                    .foregroundColor(MilliColors.textLabel)
                    .tracking(0.8)

                Text(viewModel.aiInsight)
                    .font(MilliFont.bodyMedium())
                    .foregroundColor(MilliColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MilliColors.textTertiary)
        }
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }
}
