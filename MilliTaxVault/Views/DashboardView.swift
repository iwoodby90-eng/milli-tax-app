import SwiftUI

struct DashboardView: View {
    @State private var balanceVisible = true
    
    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // MARK: Header
                    headerSection
                    
                    // MARK: Hero - Available to Spend
                    heroCard
                    
                    // MARK: Latest Payout
                    latestPayoutCard
                    
                    // MARK: Side-by-side row
                    taxVaultAndScoreRow
                    
                    // MARK: Financial Timeline
                    financialTimelineSection
                    
                    // MARK: Bottom strip
                    bottomStripRow
                    
                    Spacer().frame(height: 100)
                }
            }
            
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.xs) {
            HStack {
                Text("milli")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .italic()
                    .foregroundStyle(Color(hex: "00E5FF"))
                    .tracking(1)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                    Circle()
                        .fill(Color(hex: "00E5FF"))
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
            .padding(.horizontal, MilliSpacing.xl)
            .padding(.top, MilliSpacing.lg)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning, Ian")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("Here's your financial overview")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(.horizontal, MilliSpacing.xl)
        }
    }
    
    // MARK: - Hero Card
    private var heroCard: some View {
        HStack(spacing: MilliSpacing.lg) {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack(spacing: 6) {
                    Text("Available to Spend")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Button(action: { balanceVisible.toggle() }) {
                        Image(systemName: balanceVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "8E92A0"))
                    }
                }
                
                Text(balanceVisible ? "$24,560.00" : "••••••")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Text("Milli Checking •••• 4587")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
            }
            
            Spacer()
            
            MilliMetalCard(size: CGSize(width: 140, height: 90))
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color(hex: "00E5FF").opacity(0.08), radius: 12)
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Latest Payout Card
    private var latestPayoutCard: some View {
        VStack(spacing: MilliSpacing.md) {
            // Header
            HStack {
                Text("Latest Payout")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            
            HStack(alignment: .top, spacing: MilliSpacing.lg) {
                // Left column
                VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                    Text("Gross Payout")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Text("$8,750.00")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Text("May 23, 2025")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
                
                Spacer()
                
                // Right column - line items
                VStack(alignment: .trailing, spacing: 6) {
                    payoutLineItem("Net Payout", "$6,862.50", .white)
                    payoutLineItem("Taxes", "-$1,312.50", Color(hex: "FF3B30"))
                    payoutLineItem("Milli Tax Vault\u{2122}", "-$575.00", Color(hex: "00E5FF"))
                    Divider().background(Color.white.opacity(0.1))
                    payoutLineItem("Total", "$8,750.00", .white)
                }
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func payoutLineItem(_ label: String, _ amount: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E92A0"))
            Spacer()
            Text(amount)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Tax Vault & Score Row
    private var taxVaultAndScoreRow: some View {
        HStack(spacing: MilliSpacing.md) {
            // Tax Vault
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "00E5FF"))
                
                Text("Milli Tax Vault\u{2122}")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                Text("$15,230.40")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("+ $575.00 this month")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "34C759"))
                
                ProgressView(value: 0.76)
                    .tint(Color(hex: "00E5FF"))
                
                Text("2025 Tax Goal: $20,000")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(MilliSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .frame(maxWidth: .infinity)
            
            // Tax Ready Score
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("Tax Ready Score\u{2122}")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: 0.85)
                        .stroke(Color(hex: "00E5FF"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    Text("85")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                .frame(maxWidth: .infinity)
                
                Text("Excellent")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "34C759"))
                
                Text("Updated today")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(MilliSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Financial Timeline
    private var financialTimelineSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            HStack {
                Text("Financial Timeline")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("View all")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            
            timelineRow(month: "JUN", day: "15", icon: "building.columns.fill", title: "Estimated Tax Payment", amount: "$1,240.00")
            timelineRow(month: "SEP", day: "15", icon: "doc.text.fill", title: "Q3 Estimated Tax", amount: "$1,310.00")
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func timelineRow(month: String, day: String, icon: String, title: String, amount: String) -> some View {
        HStack(spacing: MilliSpacing.md) {
            // Date badge
            VStack(spacing: 2) {
                Text(month)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                Text(day)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color(hex: "00E5FF").opacity(0.12))
            )
            
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "8E92A0"))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
        }
        .padding(.vertical, MilliSpacing.sm)
    }
    
    // MARK: - Bottom Strip
    private var bottomStripRow: some View {
        HStack(spacing: MilliSpacing.sm) {
            bottomStripItem(icon: "speedometer", value: "1,247 mi", label: "This month", detail: "+$672.38", detailColor: Color(hex: "00E5FF"))
            bottomStripItem(icon: "leaf.fill", value: "$62,350", label: "Total Balance", detail: "+7.2%", detailColor: Color(hex: "34C759"))
            bottomStripItem(icon: "chart.line.uptrend.xyaxis", value: "$28,410", label: "Total Balance", detail: "+5.6%", detailColor: Color(hex: "34C759"))
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func bottomStripItem(icon: String, value: String, label: String, detail: String, detailColor: Color) -> some View {
        VStack(alignment: .leading, spacing: MilliSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "8E92A0"))
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "8E92A0"))
            
            HStack(spacing: 2) {
                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(detailColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundStyle(detailColor)
            }
        }
        .padding(MilliSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DashboardView()
}
