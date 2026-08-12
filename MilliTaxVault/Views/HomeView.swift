import SwiftUI
import Charts

struct HomeView: View {
    // Sparkline sample data
    let sparkData: [Double] = [820, 910, 870, 1050, 980, 1120, 1095, 1200, 1180, 1280, 1310, 1365]
    @State private var animateChart = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    
                    // MARK: Top Bar
                    HStack {
                        Spacer()
                        // MILLI Wordmark
                        Text("MILLI")
                            .font(.system(size: 26, weight: .black))
                            .tracking(6)
                            .foregroundStyle(LinearGradient(
                                colors: [.white, Color(white: 0.75), .white],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundStyle(MilliColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    .padding(.top, MilliSpacing.lg)
                    
                    // MARK: Available to Spend Hero
                    VStack(spacing: MilliSpacing.sm) {
                        HStack {
                            Text("AVAILABLE TO SPEND")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(MilliColor.textMuted)
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(MilliColor.textMuted)
                            Spacer()
                        }
                        
                        HStack(alignment: .bottom, spacing: MilliSpacing.sm) {
                            Text("$1,365.42")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                            Spacer()
                        }
                        
                        Text("Updated just now")
                            .font(.system(size: 12))
                            .foregroundStyle(MilliColor.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Sparkline
                        if #available(iOS 16.0, *) {
                            Chart {
                                ForEach(Array(sparkData.enumerated()), id: \.offset) { i, val in
                                    AreaMark(
                                        x: .value("t", i),
                                        yStart: .value("base", sparkData.min()! - 50),
                                        yEnd: .value("val", animateChart ? val : sparkData[0])
                                    )
                                    .foregroundStyle(LinearGradient(
                                        colors: [MilliColor.cyan.opacity(0.25), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                                    
                                    LineMark(
                                        x: .value("t", i),
                                        y: .value("val", animateChart ? val : sparkData[0])
                                    )
                                    .foregroundStyle(MilliColor.cyan)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    .shadow(color: MilliColor.cyan.opacity(0.5), radius: 4)
                                }
                            }
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .frame(height: 70)
                            .animation(.easeInOut(duration: 1.2), value: animateChart)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    .onAppear { animateChart = true }
                    
                    // MARK: Latest Payout Card
                    VStack(alignment: .leading, spacing: MilliSpacing.md) {
                        MilliSectionHeader(title: "Latest Payout")
                        
                        HStack(spacing: MilliSpacing.lg) {
                            // Platform icon placeholder
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "0F2545"))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(MilliColor.cyan)
                                    .font(.system(size: 18))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spark Driver\u{2122}")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(MilliColor.textPrimary)
                                Text("Today, 9:41 AM")
                                    .font(.system(size: 12))
                                    .foregroundStyle(MilliColor.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$312.64")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(MilliColor.textPrimary)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(MilliColor.positive)
                                        .frame(width: 6, height: 6)
                                    Text("Processed")
                                        .font(.system(size: 11))
                                        .foregroundStyle(MilliColor.positive)
                                }
                            }
                        }
                    }
                    .milliCard()
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // MARK: Tax Vault + Tax Ready Score
                    HStack(spacing: MilliSpacing.md) {
                        // Tax Vault Card
                        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                            HStack {
                                Text("MILLI TAX VAULT\u{2122}")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(0.8)
                                    .foregroundStyle(MilliColor.textMuted)
                                Image(systemName: "info.circle")
                                    .font(.system(size: 9))
                                    .foregroundStyle(MilliColor.textMuted)
                            }
                            Text("$5,284.17")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                            Text("23% of annual target")
                                .font(.system(size: 11))
                                .foregroundStyle(MilliColor.cyan)
                        }
                        .milliCard(padding: MilliSpacing.lg)
                        .frame(maxWidth: .infinity)
                        
                        // Tax Ready Score Card
                        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                            HStack {
                                Text("TAX READY SCORE\u{2122}")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(0.8)
                                    .foregroundStyle(MilliColor.textMuted)
                                Image(systemName: "info.circle")
                                    .font(.system(size: 9))
                                    .foregroundStyle(MilliColor.textMuted)
                            }
                            Text("85")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.cyan)
                            Text("Great")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MilliColor.positive)
                            Text("On track for tax season")
                                .font(.system(size: 10))
                                .foregroundStyle(MilliColor.textMuted)
                                .lineLimit(2)
                        }
                        .milliCard(padding: MilliSpacing.lg)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // MARK: Quarterly Taxes + Mileage
                    HStack(spacing: MilliSpacing.md) {
                        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                            Text("QUARTERLY TAXES")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(0.8)
                                .foregroundStyle(MilliColor.textMuted)
                            Text("$1,247.00")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                            Text("Est. due Jun 15")
                                .font(.system(size: 11))
                                .foregroundStyle(MilliColor.warning)
                        }
                        .milliCard(padding: MilliSpacing.lg)
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                            Text("MILEAGE")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(0.8)
                                .foregroundStyle(MilliColor.textMuted)
                            Text("2,345 mi")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                            Text("This quarter")
                                .font(.system(size: 11))
                                .foregroundStyle(MilliColor.textSecondary)
                        }
                        .milliCard(padding: MilliSpacing.lg)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // MARK: Milli AI Insight
                    HStack(spacing: MilliSpacing.lg) {
                        // AI orb mini
                        ZStack {
                            Circle()
                                .fill(MilliColor.cyan.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(MilliColor.cyan.opacity(0.4), lineWidth: 1))
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 18))
                                .foregroundStyle(MilliColor.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MILLI AI INSIGHT")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(MilliColor.cyan)
                            Text("You\u{2019}re on pace to save $3,421 in taxes this year.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(MilliColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MilliColor.cyan)
                    }
                    .milliCardCyan()
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // Bottom safe area
                    Spacer().frame(height: 100)
                }
            }
            
            // Floating AI Orb
            MilliAIOrb()
                .padding(.trailing, 20)
                .padding(.bottom, 110)
        }
        .background(MilliColor.obsidian.ignoresSafeArea())
    }
}
