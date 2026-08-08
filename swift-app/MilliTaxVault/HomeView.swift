import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: MILLI wordmark + bell
                HStack {
                    Spacer()
                    Text("MILLI")
                        .font(.system(size: 20, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.milliChrome1, Color.white, Color.milliChrome1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Available to Spend
                        availableToSpendCard

                        // Latest Payout
                        latestPayoutCard

                        // Two-column stats row 1
                        HStack(spacing: 12) {
                            taxVaultStatCard
                            taxReadyScoreCard
                        }

                        // Two-column stats row 2
                        HStack(spacing: 12) {
                            quarterlyTaxesCard
                            mileageStatCard
                        }

                        // Milli AI Insight
                        milliAIInsightCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Available to Spend

    private var availableToSpendCard: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AVAILABLE TO SPEND")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.milliCyan)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.milliTextTertiary)
                }

                Text("$1,365.42")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                HStack {
                    Text("Updated just now")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.milliTextSecondary)
                    Spacer()
                    // Sparkline
                    WaveShape()
                        .stroke(Color.milliCyan.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 60, height: 20)
                }
            }
        }
    }

    // MARK: - Latest Payout

    private var latestPayoutCard: some View {
        MilliCard {
            HStack(spacing: 12) {
                // Spark icon placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1E88E5"), Color(hex: "1565C0")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("LATEST PAYOUT")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    Text("$312.64")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Today, 9:41 AM \u{2022} Spark Driver\u{2122}")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.milliTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.milliTextTertiary)
            }
        }
    }

    // MARK: - Tax Vault Stat

    private var taxVaultStatCard: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("MILLI TAX VAULT\u{2122}")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                Text("$5,284.17")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("23% of annual target")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.milliTextSecondary)
            }
        }
    }

    // MARK: - Tax Ready Score

    private var taxReadyScoreCard: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("TAX READY SCORE\u{2122}")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)

                HStack {
                    Text("85")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.milliCyan.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        Circle()
                            .trim(from: 0, to: 0.85)
                            .stroke(Color.milliCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                    }
                }

                Text("Great - You're on track")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.milliGreen)
            }
        }
    }

    // MARK: - Quarterly Taxes

    private var quarterlyTaxesCard: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("QUARTERLY TAXES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                Text("$1,247.00")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("Est. due Jun 15, 2024")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.milliTextSecondary)
            }
        }
    }

    // MARK: - Mileage Stat

    private var mileageStatCard: some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("MILEAGE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                Text("2,345 mi")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("This quarter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.milliTextSecondary)
            }
        }
    }

    // MARK: - Milli AI Insight

    private var milliAIInsightCard: some View {
        MilliCard {
            HStack(spacing: 12) {
                Image(systemName: "cpu")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.milliCyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MILLI AI INSIGHT")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.milliCyan)
                    Text("You're on pace to save $3,421 in taxes this year.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.milliTextTertiary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.milliCyan.opacity(0.3), lineWidth: 0.5)
        )
    }
}
