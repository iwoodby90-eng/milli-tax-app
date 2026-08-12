import SwiftUI

// MARK: - Tab Model (4-Tab Bel Air Cockpit + Center M Home)

enum MilliTab: Int, CaseIterable {
    case vault, wealth, home, activity, cockpit

    var title: String {
        switch self {
        case .vault: return "Vault"
        case .wealth: return "Wealth"
        case .home: return "Home"
        case .activity: return "Activity"
        case .cockpit: return "Cockpit"
        }
    }

    var icon: String {
        switch self {
        case .vault: return "lock.shield.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"
        case .home: return "house.fill"
        case .activity: return "bolt.fill"
        case .cockpit: return "gauge.with.dots.needle.67percent"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var tab: MilliTab = .home
    @State private var showAI = false

    var body: some View {
        ZStack(alignment: .bottom) {
            MilliPalette.background.ignoresSafeArea()

            NavigationStack {
                Group {
                    switch tab {
                    case .home: HomeView()
                    case .vault: TaxVaultView()
                    case .wealth: WealthOverviewView()
                    case .activity: PayoutsView()
                    case .cockpit: MoreView()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }

            // Floating Milli AI Orb (bottom-right, always visible)
            floatingAIOrb

            // Bel Air Cockpit Navigation
            BottomNavBar(selection: $tab) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    tab = .home
                }
            }
        }
        .sheet(isPresented: $showAI) { MilliAIView() }
    }

    // MARK: - Floating AI Companion

    private var floatingAIOrb: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button { showAI = true } label: {
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MilliPalette.accent.opacity(0.3),
                                        MilliPalette.accent.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 18,
                                    endRadius: 32
                                )
                            )
                            .frame(width: 56, height: 56)

                        // Core orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [MilliPalette.accent, MilliPalette.accent.opacity(0.7)],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: MilliPalette.accent.opacity(0.7), radius: 12)

                        // Sparkle icon
                        Image(systemName: "sparkles")
                            .foregroundStyle(.black)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 96)
            }
        }
    }
}
