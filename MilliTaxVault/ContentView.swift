import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Screen content — each screen fills the available space
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
            .safeAreaInset(edge: .bottom) {
                // Reserve space for the sculpted nav bar so content doesn't hide behind it
                Color.clear.frame(height: MilliLayout.bottomNavHeight)
            }
            
            // Sculpted Bel Air dashboard navigation bar — hardware-feel, always on top
            MilliBottomBar(selectedTab: $selectedTab)
        }
        .background(MilliColors.obsidian)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Transfers View (Mileage)
struct TransfersView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliLayout.sectionGap) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("M I L L I")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(2)
                            Spacer()
                        }
                        Text("Mileage")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Track your drives automatically.")
                            .font(.system(size: 14))
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                    .padding(.horizontal, MilliLayout.screenMargin)
                    .padding(.top, MilliLayout.lg)
                    
                    // Stat cards
                    VStack(spacing: MilliLayout.sectionGap) {
                        mileageStatCard(icon: "car.fill", title: "This Quarter", value: "2,345 mi", subtitle: "$1,548 deduction")
                        mileageStatCard(icon: "calendar", title: "This Month", value: "847 mi", subtitle: "$559 deduction")
                    }
                    .padding(.horizontal, MilliLayout.screenMargin)
                }
            }
            
            MilliAIOrb()
                .padding(.trailing, 14)
                .padding(.bottom, 8)
        }
    }
    
    private func mileageStatCard(icon: String, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(MilliColors.cyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Text(value)
                    .font(MilliFont.cardValue)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(MilliFont.metadata)
                    .foregroundStyle(MilliColors.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(MilliColors.textMuted)
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
}

// MARK: - More Menu View
struct MoreMenuView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliLayout.sectionGap) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("M I L L I")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(2)
                            Spacer()
                        }
                        Text("More")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, MilliLayout.screenMargin)
                    .padding(.top, MilliLayout.lg)
                    
                    // Menu items
                    VStack(spacing: 1) {
                        menuRow(icon: "gearshape.fill", title: "Settings")
                        menuRow(icon: "person.fill", title: "Profile")
                        menuRow(icon: "doc.text.fill", title: "Tax Documents")
                        menuRow(icon: "questionmark.circle.fill", title: "Support")
                        menuRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out")
                    }
                    .padding(.horizontal, MilliLayout.screenMargin)
                }
            }
            
            MilliAIOrb()
                .padding(.trailing, 14)
                .padding(.bottom, 8)
        }
    }
    
    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 24)
            Text(title)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(MilliColors.textMuted)
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, 14)
        .milliSurface()
    }
}

#Preview {
    ContentView()
}
