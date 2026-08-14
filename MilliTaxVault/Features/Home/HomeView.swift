import SwiftUI
import Charts

// MARK: - HomeView — Pixel-Fidelity Reference Implementation
// Matches the approved production reference exactly.
// Dense, cinematic, precision-accented fintech dashboard.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSparkline = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MilliLayout.sectionGap) {
                    // MARK: Header — MILLI wordmark + bell
                    headerSection
                    
                    // MARK: Hero — Available to Spend
                    heroCard
                    
                    // MARK: Latest Payout — compact horizontal
                    latestPayoutCard
                    
                    // MARK: 2x2 Metric Grid
                    metricGrid
                    
                    // MARK: Milli AI Insight
                    insightCard
                    
                    // Bottom spacer for nav clearance
                    Spacer()
                        .frame(height: MilliLayout.bottomNavHeight + 20)
                }
                .padding(.top, 8)
            }
            
            // MARK: Milli AI Orb — floating bottom-right
            milliAIOrbOverlay
        }
        .background(MilliColors.obsidian.ignoresSafeArea())
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            // MILLI wordmark — brand asset
            Image("MilliWordmark")
                .resizable()
                .scaledToFit()
                .frame(height: 18)
            
            Spacer()
            
            // Bell icon
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MilliColors.textSecondary)
                
                Circle()
                    .fill(MilliColors.cyan)
                    .frame(width: 6, height: 6)
                    .offset(x: 2, y: -1)
            }
        }
        .padding(.horizontal, MilliLayout.screenMargin)
        .padding(.top, 4)
    }
    
    // MARK: - Hero Card (Available to Spend)
    private var heroCard: some View {
        HStack(spacing: 0) {
            // Left content
            VStack(alignment: .leading, spacing: MilliLayout.metadataGap) {
                Text("AVAILABLE TO SPEND")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.5)
                
                Text(viewModel.spendableBalance.formattedAmount)
                    .font(MilliFont.heroBalance)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                Text(viewModel.spendableBalance.lastUpdated)
                    .font(MilliFont.metadata)
                    .foregroundStyle(MilliColors.textMuted)
                
                // Sparkline
                MilliSparkline(data: viewModel.spendableBalance.cashflowData)
                    .frame(height: 36)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Right — cyan action circle
            ZStack {
                Circle()
                    .fill(MilliColors.cyan)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MilliColors.obsidian)
            }
            .padding(.trailing, 2)
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV + 2)
        .milliSurface(hasCyanBorder: true)
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    // MARK: - Latest Payout Card (compact horizontal)
    private var latestPayoutCard: some View {
        HStack(spacing: 10) {
            // Left content
            VStack(alignment: .leading, spacing: MilliLayout.metadataGap) {
                Text("LATEST PAYOUT")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.5)
                
                Text(viewModel.latestPayout.formattedAmount)
                    .font(MilliFont.subHeroNumber)
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Text(viewModel.latestPayout.timestamp)
                        .font(MilliFont.metadata)
                        .foregroundStyle(MilliColors.textMuted)
                    
                    Text("•")
                        .font(MilliFont.metadata)
                        .foregroundStyle(MilliColors.textMuted)
                    
                    Text(viewModel.latestPayout.source)
                        .font(MilliFont.metadata)
                        .foregroundStyle(MilliColors.textMuted)
                }
            }
            
            Spacer()
            
            // Source icon (Walmart/Spark)
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "1A2030"))
                    .frame(width: 36, height: 36)
                
                Image(systemName: viewModel.latestPayout.sourceIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MilliColors.cyan)
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    // MARK: - 2x2 Metric Grid
    private var metricGrid: some View {
        VStack(spacing: MilliLayout.gridGap) {
            // Top row
            HStack(spacing: MilliLayout.gridGap) {
                // Milli Tax Vault
                MilliMetricCard(
                    title: "Milli Tax Vault",
                    value: viewModel.taxVault.formattedBalance,
                    subtitle: viewModel.taxVault.annualRate,
                    icon: "building.columns.fill"
                )
                
                // Tax Ready Score — with progress ring
                taxReadyScoreCard
            }
            
            // Bottom row
            HStack(spacing: MilliLayout.gridGap) {
                // Quarterly Taxes
                MilliMetricCard(
                    title: "Quarterly Taxes",
                    value: viewModel.quarterlyTax.formattedAmount,
                    subtitle: viewModel.quarterlyTax.dueDate,
                    icon: "doc.text.fill"
                )
                
                // Mileage
                MilliMetricCard(
                    title: "Mileage",
                    value: viewModel.mileage.formattedMiles,
                    subtitle: viewModel.mileage.period,
                    icon: "car.fill"
                )
            }
        }
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    // MARK: - Tax Ready Score (special layout with ring)
    private var taxReadyScoreCard: some View {
        VStack(alignment: .leading, spacing: MilliLayout.metadataGap + 2) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MilliColors.cyan)
                Text("TAX READY SCORE")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.6)
            }
            
            HStack(spacing: 8) {
                MilliProgressRing(
                    score: viewModel.taxReadyScore.score,
                    maxScore: viewModel.taxReadyScore.maxScore,
                    label: viewModel.taxReadyScore.label,
                    size: 44,
                    lineWidth: 4
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.taxReadyScore.score)")
                        .font(MilliFont.cardValue)
                        .foregroundStyle(.white)
                    
                    Text(viewModel.taxReadyScore.label)
                        .font(MilliFont.metadata)
                        .foregroundStyle(MilliColors.positive)
                }
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliSurface()
    }
    
    // MARK: - AI Insight
    private var insightCard: some View {
        MilliInsightCard(text: viewModel.aiInsight.text)
            .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    // MARK: - Milli AI Orb Overlay
    private var milliAIOrbOverlay: some View {
        MilliAIOrb()
            .padding(.trailing, 14)
            .padding(.bottom, MilliLayout.bottomNavHeight + 8)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        VStack(spacing: 0) {
            HomeView()
            MilliBottomBar(selectedTab: .constant(.home))
        }
    }
    .preferredColorScheme(.dark)
}
