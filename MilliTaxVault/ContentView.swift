import SwiftUI

// MARK: - ContentView
// Native SwiftUI shell: screen router + persistent sculpted Milli navigation + contextual Milli AI companion.

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    @State private var activeScreen: ActiveScreen = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            MilliColors.background.ignoresSafeArea()

            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            if activeScreen != .milliAI {
                HStack {
                    Spacer()
                    MilliAIOrb {
                        navigateTo(.milliAI)
                    }
                    .padding(.trailing, 10)
                    .padding(.bottom, MilliSpacing.bottomNavHeight - 4)
                }
                .allowsHitTesting(true)
            }

            MilliNavBar(selectedTab: $selectedTab) {
                selectedTab = .home
                navigateTo(.home)
            }
            .onChange(of: selectedTab) { _, newTab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    switch newTab {
                    case .home:
                        activeScreen = .home
                    case .payouts:
                        activeScreen = .payouts
                    case .mDial:
                        activeScreen = .home
                    case .mileage:
                        activeScreen = .mileage
                    case .more:
                        activeScreen = .more
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch activeScreen {
        case .home:
            HomeView(navigate: navigateTo)
        case .payouts:
            PayoutsView()
        case .mileage:
            MileageView(onBack: { navigateTo(.home) })
        case .milliCents:
            MilliCentsView(onBack: { navigateTo(.home) })
        case .expenses:
            ExpensesView(onBack: { navigateTo(.more) })
        case .taxVault:
            TaxVaultView(onBack: { navigateTo(.home) })
        case .taxReadyScore:
            TaxReadyScoreView(onBack: { navigateTo(.home) })
        case .quarterlyTaxes:
            QuarterlyTaxesView(onBack: { navigateTo(.home) })
        case .investing:
            InvestingView(onBack: { navigateTo(.more) })
        case .retirement:
            RetirementView(onBack: { navigateTo(.more) })
        case .treeOfLife:
            TreeOfLifeView(onBack: { navigateTo(.more) })
        case .milliAI:
            MilliAIView(
                onBack: { navigateTo(.home) },
                navigate: navigateTo
            )
        case .reports:
            ReportsView(onBack: { navigateTo(.more) })
        case .more:
            MoreMenuView(navigate: navigateTo)
        }
    }

    private func navigateTo(_ screen: ActiveScreen) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeScreen = screen
            switch screen {
            case .home:
                selectedTab = .home
            case .payouts:
                selectedTab = .payouts
            case .mileage:
                selectedTab = .mileage
            case .more:
                selectedTab = .more
            default:
                break
            }
        }
    }
}

enum ActiveScreen {
    case home
    case payouts
    case mileage
    case milliCents
    case expenses
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
