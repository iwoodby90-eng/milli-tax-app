import SwiftUI

// MARK: - ContentView — Root container with tab routing and nav bar

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    @State private var showAIChat = false
    @State private var activeScreen: ActiveScreen = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating AI Orb — bottom right, above nav
            if activeScreen != .milliAI {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MilliAIOrb {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                activeScreen = .milliAI
                            }
                        }
                        .padding(.trailing, MilliSpacing.screenHorizontal)
                        .padding(.bottom, 88)
                    }
                }
            }

            // Bottom nav bar
            MilliNavBar(selectedTab: $selectedTab) {
                // M Dial tap — navigate home
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .home
                    activeScreen = .home
                }
            }
            .onChange(of: selectedTab) { _, newTab in
                withAnimation(.easeInOut(duration: 0.25)) {
                    switch newTab {
                    case .home:
                        activeScreen = .home
                    case .payouts:
                        activeScreen = .payouts
                    case .mDial:
                        activeScreen = .home
                    case .more:
                        activeScreen = .more
                    }
                }
            }
        }
        .background(MilliColors.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Screen Content Router

    @ViewBuilder
    private var screenContent: some View {
        switch activeScreen {
        case .home:
            HomeView(navigate: navigateTo)
        case .payouts:
            PayoutsView()
        case .mileage:
            MileageView(onBack: { activeScreen = .home })
        case .milliCents:
            MilliCentsView(onBack: { activeScreen = .home })
        case .taxVault:
            TaxVaultView(onBack: { activeScreen = .home })
        case .taxReadyScore:
            TaxReadyScoreView(onBack: { activeScreen = .home })
        case .quarterlyTaxes:
            QuarterlyTaxesView(onBack: { activeScreen = .home })
        case .investing:
            InvestingView(onBack: { activeScreen = .more })
        case .retirement:
            RetirementView(onBack: { activeScreen = .more })
        case .treeOfLife:
            TreeOfLifeView(onBack: { activeScreen = .more })
        case .milliAI:
            MilliAIView(onBack: { activeScreen = .home })
        case .reports:
            ReportsView(onBack: { activeScreen = .more })
        case .more:
            MoreMenuView(navigate: navigateTo)
        }
    }

    private func navigateTo(_ screen: ActiveScreen) {
        withAnimation(.easeInOut(duration: 0.25)) {
            activeScreen = screen
        }
    }
}

// MARK: - Active Screen Enum

enum ActiveScreen {
    case home
    case payouts
    case mileage
    case milliCents
    case taxVault
    case taxReadyScore
    case quarterlyTaxes
    case investing
    case retirement
    case treeOfLife
    case milliAI
    case reports
    case more
}
