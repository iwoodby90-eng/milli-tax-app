import SwiftUI

struct MilliCentsView: View {
    @State private var balanceVisible = true
    @State private var selectedCategory = "All"
    let categories = ["All", "Shopping", "Gas", "Food", "Travel"]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // MARK: Header
                    headerSection
                    
                    // MARK: Hero - MilliCents Balance
                    heroCard
                    
                    // MARK: Earning Rate
                    earningRateCard
                    
                    // MARK: Category Filter
                    categoryFilter
                    
                    // MARK: Recent Earnings
                    recentEarningsSection
                    
                    // MARK: Redemption Options
                    redemptionSection
                    
                    // MARK: AI Insight
                    aiInsightCard
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliAICompanion()
        }
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("milli")
                    .font(.system(size: 22, weight: .bold))
                    .italic()
                    .foregroundStyle(Color(hex: "00E5FF"))
                    .tracking(1)
                Spacer()
                
                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "F4B73B"))
                    Text("12-day streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "121620")))
            }
            
            Text("MilliCents")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Earn. Stack. Redeem.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .padding(.horizontal, MilliSpacing.xl)
        .padding(.top, MilliSpacing.lg)
    }
    
    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(spacing: MilliSpacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                    HStack(spacing: 6) {
                        Text("MilliCents Balance")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "8E92A0"))
                        Button(action: { balanceVisible.toggle() }) {
                            Image(systemName: balanceVisible ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "8E92A0"))
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(balanceVisible ? "14,280" : "••••••")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(.white)
                        if balanceVisible {
                            Text("MC")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "00E5FF"))
                        }
                    }
                    
                    Text(balanceVisible ? "= $142.80 value" : "")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "34C759"))
                        Text("+1,840 MC this month")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "34C759"))
                    }
                }
                
                Spacer()
                
                // Coin stack visual
                coinStackView
            }
            
            // Quick action buttons
            HStack(spacing: MilliSpacing.md) {
                quickActionButton(icon: "arrow.up.circle.fill", label: "Redeem", color: Color(hex: "00E5FF"))
                quickActionButton(icon: "gift.fill", label: "Boost", color: Color(hex: "F4B73B"))
                quickActionButton(icon: "chart.bar.fill", label: "History", color: Color(hex: "8E92A0"))
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color(hex: "00E5FF").opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color(hex: "00E5FF").opacity(0.08), radius: 12)
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private var coinStackView: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(Color(hex: "1A1F2E"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "00E5FF").opacity(0.4), lineWidth: 1)
                        )
                    Text("M")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                .offset(x: CGFloat(i) * 4 - 8, y: CGFloat(i) * -6)
            }
        }
        .frame(width: 60, height: 80)
    }
    
    private func quickActionButton(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MilliSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.medium)
                .fill(Color(hex: "0D1117"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.medium).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
    
    // MARK: - Earning Rate
    private var earningRateCard: some View {
        HStack(spacing: MilliSpacing.lg) {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("Current Earning Rate")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("3x")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(Color(hex: "00E5FF"))
                    Text("MC per $1")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
                
                Text("Elite tier (10x on gas)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "F4B73B"))
            }
            
            Spacer()
            
            // Progress to next tier
            VStack(spacing: MilliSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 5)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(Color(hex: "00E5FF"), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("72%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("to Platinum")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MilliSpacing.sm) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(selectedCategory == category ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(selectedCategory == category ? Color(hex: "00E5FF") : Color.white.opacity(0.1), lineWidth: 1)
                                .background(Capsule().fill(selectedCategory == category ? Color(hex: "00E5FF").opacity(0.1) : .clear))
                        )
                        .onTapGesture { selectedCategory = category }
                }
            }
            .padding(.horizontal, MilliSpacing.xl)
        }
    }
    
    // MARK: - Recent Earnings
    private var recentEarningsSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            HStack {
                Text("Recent Earnings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("View all")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            
            earningRow(icon: "fuelpump.fill", category: "Shell Gas Station", time: "Today, 2:30 PM", amount: "+120 MC", bonus: "10x Gas Bonus", color: Color(hex: "F4B73B"))
            earningRow(icon: "cart.fill", category: "Target", time: "Today, 11:15 AM", amount: "+45 MC", bonus: nil, color: Color(hex: "FF3B30"))
            earningRow(icon: "fork.knife", category: "Chipotle", time: "Yesterday, 7:45 PM", amount: "+28 MC", bonus: nil, color: Color(hex: "8E92A0"))
            earningRow(icon: "airplane", category: "United Airlines", time: "Yesterday, 10:00 AM", amount: "+890 MC", bonus: "Travel 5x", color: Color(hex: "4A90D9"))
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func earningRow(icon: String, category: String, time: String, amount: String, bonus: String?, color: Color) -> some View {
        HStack(spacing: MilliSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(time)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                if let bonus = bonus {
                    Text(bonus)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "F4B73B"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "F4B73B").opacity(0.12)))
                }
            }
        }
        .padding(.vertical, MilliSpacing.sm)
    }
    
    // MARK: - Redemption
    private var redemptionSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            Text("Redeem MilliCents")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MilliSpacing.md) {
                    redemptionCard(icon: "dollarsign.circle.fill", title: "Cash Back", subtitle: "Direct to account", rate: "100 MC = $1.00", color: Color(hex: "00E5FF"))
                    redemptionCard(icon: "building.columns.fill", title: "Tax Vault", subtitle: "Boost your vault", rate: "100 MC = $1.25", color: Color(hex: "34C759"))
                    redemptionCard(icon: "chart.line.uptrend.xyaxis", title: "Invest", subtitle: "Auto-invest", rate: "100 MC = $1.10", color: Color(hex: "4A90D9"))
                    redemptionCard(icon: "gift.fill", title: "Gift Cards", subtitle: "100+ brands", rate: "100 MC = $1.05", color: Color(hex: "F4B73B"))
                }
            }
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func redemptionCard(icon: String, title: String, subtitle: String, rate: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E92A0"))
            
            Text(rate)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "00E5FF"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "00E5FF").opacity(0.1)))
        }
        .padding(MilliSpacing.lg)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
    
    // MARK: - AI Insight
    private var aiInsightCard: some View {
        HStack(spacing: MilliSpacing.lg) {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "00E5FF"))
                    Text("Milli AI Tip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                
                Text("Fill up at Shell this week for 10x MilliCents. At your current pace, you'll hit Platinum tier by next month.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1F2E"))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color(hex: "00E5FF").opacity(0.3), lineWidth: 1))
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "00E5FF")).frame(width: 4, height: 4)
                    Circle().fill(Color(hex: "00E5FF")).frame(width: 4, height: 4)
                }
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color(hex: "00E5FF"), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
}

#Preview {
    MilliCentsView()
}
