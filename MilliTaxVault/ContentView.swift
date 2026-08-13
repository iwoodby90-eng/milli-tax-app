import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Screen content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .activity:
                    ActivityView()
                case .home:
                    HomeView()
                case .transfers:
                    TransfersView()
                case .more:
                    MoreMenuView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Nav bar
            MilliNavBar(selectedTab: $selectedTab)
        }
        .background(MilliColor.obsidian)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Transfers View
struct TransfersView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("milli")
                                .font(.system(size: 22, weight: .bold))
                                .italic()
                                .foregroundStyle(Color(hex: "00E5FF"))
                                .tracking(1)
                            Spacer()
                        }
                        Text("Transfers")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Move money instantly.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "8E92A0"))
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    .padding(.top, MilliSpacing.lg)
                    
                    // Quick Actions
                    HStack(spacing: MilliSpacing.md) {
                        transferAction(icon: "arrow.up.circle.fill", label: "Send", color: Color(hex: "00E5FF"))
                        transferAction(icon: "arrow.down.circle.fill", label: "Request", color: Color(hex: "34C759"))
                        transferAction(icon: "building.columns.fill", label: "To Vault", color: Color(hex: "F4B73B"))
                        transferAction(icon: "chart.line.uptrend.xyaxis", label: "Invest", color: Color(hex: "4A90D9"))
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // Recent Transfers
                    VStack(alignment: .leading, spacing: MilliSpacing.md) {
                        HStack {
                            Text("Recent Transfers")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("View all")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "00E5FF"))
                        }
                        
                        transferRow(icon: "building.columns.fill", title: "Tax Vault Deposit", subtitle: "Auto-save 15%", amount: "-$575.00", time: "Today", color: Color(hex: "00E5FF"))
                        transferRow(icon: "arrow.up", title: "Sent to Chase", subtitle: "External transfer", amount: "-$2,000.00", time: "Yesterday", color: Color(hex: "8E92A0"))
                        transferRow(icon: "arrow.down", title: "Uber Payout", subtitle: "Direct deposit", amount: "+$1,240.00", time: "May 22", color: Color(hex: "34C759"))
                    }
                    .padding(MilliSpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .fill(Color(hex: "121620"))
                            .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    )
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // Scheduled
                    VStack(alignment: .leading, spacing: MilliSpacing.md) {
                        Text("Scheduled")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: MilliSpacing.md) {
                            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                                Text("Auto Tax Vault")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("15% of each payout")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "8E92A0"))
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "34C759"))
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "34C759"))
                            }
                        }
                        .padding(MilliSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: MilliRadius.medium)
                                .fill(Color(hex: "0D1117"))
                                .overlay(RoundedRectangle(cornerRadius: MilliRadius.medium).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        )
                        
                        HStack(spacing: MilliSpacing.md) {
                            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                                Text("Invest Spare Change")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("Round-up to nearest $1")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "8E92A0"))
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "34C759"))
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "34C759"))
                            }
                        }
                        .padding(MilliSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: MilliRadius.medium)
                                .fill(Color(hex: "0D1117"))
                                .overlay(RoundedRectangle(cornerRadius: MilliRadius.medium).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        )
                    }
                    .padding(MilliSpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .fill(Color(hex: "121620"))
                            .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    )
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliAICompanion()
        }
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
    
    private func transferAction(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func transferRow(icon: String, title: String, subtitle: String, amount: String, time: String, color: Color) -> some View {
        HStack(spacing: MilliSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(amount.hasPrefix("+") ? Color(hex: "34C759") : .white)
                Text(time)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
        }
        .padding(.vertical, MilliSpacing.sm)
    }
}

// MARK: - More Menu View
struct MoreMenuView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("milli")
                                .font(.system(size: 22, weight: .bold))
                                .italic()
                                .foregroundStyle(Color(hex: "00E5FF"))
                                .tracking(1)
                            Spacer()
                        }
                        Text("More")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Everything else.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "8E92A0"))
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    .padding(.top, MilliSpacing.lg)
                    
                    // Feature grid
                    VStack(spacing: MilliSpacing.md) {
                        HStack(spacing: MilliSpacing.md) {
                            moreMenuItem(icon: "leaf.fill", title: "Retirement", subtitle: "Plan your future", color: Color(hex: "34C759"))
                            moreMenuItem(icon: "chart.line.uptrend.xyaxis", title: "Investing", subtitle: "Track portfolio", color: Color(hex: "4A90D9"))
                        }
                        HStack(spacing: MilliSpacing.md) {
                            moreMenuItem(icon: "car.fill", title: "Mileage", subtitle: "Track & deduct", color: Color(hex: "F4B73B"))
                            moreMenuItem(icon: "m.circle.fill", title: "MilliCents", subtitle: "Earn rewards", color: Color(hex: "00E5FF"))
                        }
                        HStack(spacing: MilliSpacing.md) {
                            moreMenuItem(icon: "building.columns.fill", title: "Tax Vault", subtitle: "Auto-save taxes", color: Color(hex: "00E5FF"))
                            moreMenuItem(icon: "gearshape.fill", title: "Settings", subtitle: "Account & prefs", color: Color(hex: "8E92A0"))
                        }
                    }
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    // Account section
                    VStack(alignment: .leading, spacing: MilliSpacing.md) {
                        Text("Account")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "8E92A0"))
                            .tracking(1.5)
                            .textCase(.uppercase)
                        
                        accountRow(icon: "person.fill", title: "Profile")
                        accountRow(icon: "bell.fill", title: "Notifications")
                        accountRow(icon: "lock.fill", title: "Security")
                        accountRow(icon: "questionmark.circle.fill", title: "Help & Support")
                        accountRow(icon: "doc.text.fill", title: "Legal")
                    }
                    .padding(MilliSpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .fill(Color(hex: "121620"))
                            .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    )
                    .padding(.horizontal, MilliSpacing.xl)
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliAICompanion()
        }
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
    
    private func moreMenuItem(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .padding(MilliSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
    
    private func accountRow(icon: String, title: String) -> some View {
        HStack(spacing: MilliSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "8E92A0"))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .padding(.vertical, MilliSpacing.sm)
    }
}
