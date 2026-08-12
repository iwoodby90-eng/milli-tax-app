import SwiftUI

struct TaxVaultView: View {
    @State private var ringProgress: CGFloat = 0
    let targetProgress: CGFloat = 0.23
    
    let transactions: [(String, String, String)] = [
        ("Payout Allocation", "May 10, 2024", "+$72.91"),
        ("Payout Allocation", "May 9, 2024", "+$89.21"),
        ("Manual Transfer", "May 8, 2024", "+$250.00"),
        ("Interest Earned", "May 7, 2024", "+$1.27"),
        ("Payout Allocation", "May 6, 2024", "+$88.11"),
    ]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xxl) {
                    
                    // Header
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(MilliColor.textPrimary)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("MILLI TAX VAULT\u{2122}")
                                .font(.system(size: 16, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(MilliColor.textPrimary)
                        }
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(MilliColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    .padding(.top, MilliSpacing.lg)
                    
                    // Reserve Balance + Ring
                    VStack(spacing: MilliSpacing.xxl) {
                        VStack(spacing: MilliSpacing.sm) {
                            Text("RESERVE BALANCE")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(MilliColor.textMuted)
                            Text("$5,284.17")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                            HStack(spacing: MilliSpacing.sm) {
                                Text("23%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(MilliColor.cyan)
                                Text("\u{00B7}")
                                    .foregroundStyle(MilliColor.textMuted)
                                Text("23.4% of annual target")
                                    .font(.system(size: 14))
                                    .foregroundStyle(MilliColor.textSecondary)
                            }
                        }
                        
                        // Progress Ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 12)
                                .frame(width: 180, height: 180)
                            
                            Circle()
                                .trim(from: 0, to: ringProgress)
                                .stroke(
                                    AngularGradient(
                                        colors: [MilliColor.cyan, MilliColor.cyan.opacity(0.5)],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 180, height: 180)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: MilliColor.cyan.opacity(0.6), radius: 8)
                                .animation(.easeInOut(duration: 1.4), value: ringProgress)
                            
                            VStack(spacing: 4) {
                                Text("23%")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(MilliColor.cyan)
                                Text("saved")
                                    .font(.system(size: 13))
                                    .foregroundStyle(MilliColor.textSecondary)
                            }
                        }
                        .onAppear { ringProgress = targetProgress }
                    }
                    
                    // Annual Target row
                    HStack(spacing: MilliSpacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ANNUAL TARGET")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1)
                                .foregroundStyle(MilliColor.textMuted)
                            Text("$22,500.00")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                        }
                        .milliCard(padding: MilliSpacing.lg)
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TARGET DATE")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1)
                                .foregroundStyle(MilliColor.textMuted)
                            Text("Dec 31, 2024")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(MilliColor.textPrimary)
                        }
                        .milliCard(padding: MilliSpacing.lg)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // Add to Vault Button
                    Button(action: {}) {
                        Text("Add to Vault")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MilliColor.obsidian)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(MilliColor.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: MilliRadius.large))
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // Transactions
                    VStack(spacing: 0) {
                        MilliSectionHeader(title: "Transactions", trailing: "View All")
                            .padding(.bottom, MilliSpacing.lg)
                        
                        ForEach(Array(transactions.enumerated()), id: \.offset) { i, tx in
                            HStack(spacing: MilliSpacing.lg) {
                                ZStack {
                                    Circle()
                                        .fill(MilliColor.cyan.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: tx.0 == "Interest Earned" ? "sparkles" : "arrow.triangle.2.circlepath")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(MilliColor.cyan)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.0)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(MilliColor.textPrimary)
                                    Text(tx.1)
                                        .font(.system(size: 12))
                                        .foregroundStyle(MilliColor.textSecondary)
                                }
                                Spacer()
                                Text(tx.2)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(MilliColor.positive)
                            }
                            .padding(.vertical, MilliSpacing.md)
                            
                            if i < transactions.count - 1 {
                                Divider()
                                    .background(MilliColor.border)
                            }
                        }
                    }
                    .milliCard()
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliAIOrb()
                .padding(.trailing, 20)
                .padding(.bottom, 110)
        }
        .background(MilliColor.obsidian.ignoresSafeArea())
    }
}
