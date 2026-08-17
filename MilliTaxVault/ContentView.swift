import SwiftUI

// MARK: - ContentView
// Native SwiftUI shell: screen router + persistent sculpted Milli navigation + contextual Milli AI companion.

struct ContentView: View {
    @State private var selectedTab: MilliTab
    @State private var activeScreen: ActiveScreen

    init() {
        let initialScreen = Self.requestedDebugScreen() ?? .home
        _activeScreen = State(initialValue: initialScreen)
        _selectedTab = State(initialValue: initialScreen.primaryTab)
    }

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
        case .autopilot:
            AutopilotSettingsView(onBack: { navigateTo(.more) })
        case .expenses:
            ExpensesView(onBack: { navigateTo(.more) })
        case .accounts:
            AccountsView(onBack: { navigateTo(.more) })
        case .savings:
            SavingsView(onBack: { navigateTo(.more) })
        case .documents:
            DocumentsView(onBack: { navigateTo(.more) })
        case .plans:
            SubscriptionView(onBack: { navigateTo(.more) })
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
        case .wealthOverview:
            WealthOverviewView(onBack: { navigateTo(.more) })
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
            selectedTab = screen.primaryTab
        }
    }

    private static func requestedDebugScreen() -> ActiveScreen? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-milliScreenshotMode"),
              let flagIndex = arguments.firstIndex(of: "-milliScreen"),
              arguments.indices.contains(flagIndex + 1)
        else {
            return nil
        }

        let rawValue = arguments[flagIndex + 1]
        return ActiveScreen(rawValue: rawValue)
        #else
        return nil
        #endif
    }
}

enum ActiveScreen: String, CaseIterable {
    case home
    case payouts
    case mileage
    case milliCents
    case autopilot
    case expenses
    case accounts
    case savings
    case documents
    case plans
    case taxVault
    case taxReadyScore
    case quarterlyTaxes
    case investing
    case retirement
    case wealthOverview
    case treeOfLife
    case milliAI
    case reports
    case more

    var primaryTab: MilliTab {
        switch self {
        case .home:
            return .home
        case .payouts:
            return .payouts
        case .mileage:
            return .mileage
        case .more:
            return .more
        default:
            return .more
        }
    }
}
