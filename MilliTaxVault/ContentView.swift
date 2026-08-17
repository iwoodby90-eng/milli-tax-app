import SwiftUI

// MARK: - ContentView
// Native SwiftUI shell: screen router + persistent sculpted Milli navigation + contextual Milli AI companion.

struct ContentView: View {
    var onLogout: () -> Void = {}

    @State private var selectedTab: MilliTab
    @State private var activeScreen: ActiveScreen

    init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
        let initialScreen = Self.requestedDebugScreen() ?? .home
        _activeScreen = State(initialValue: initialScreen)
        _selectedTab = State(initialValue: initialScreen.debugTab)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MilliColors.background.ignoresSafeArea()

            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            if shouldShowAIOrb {
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

    private var shouldShowAIOrb: Bool {
        switch activeScreen {
        case .milliAI, .expenses, .plans:
            // Expenses owns the bottom-right Add action and Plans owns a large
            // subscription CTA. The global assistant must never obscure a primary control.
            return false
        default:
            return true
        }
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
            MoreMenuView(navigate: navigateTo, onLogout: onLogout)
        }
    }

    private func navigateTo(_ screen: ActiveScreen) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeScreen = screen

            // Primary destinations own the bottom-nav selection. Secondary screens
            // intentionally retain the user's originating primary context; opening
            // Tax Vault from Home should not make the UI claim that More was tapped.
            if let primaryTab = screen.primaryTab {
                selectedTab = primaryTab
            }
        }
    }

    private static func requestedDebugScreen() -> ActiveScreen? {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo

        if let rawValue = processInfo.environment["MILLI_SCREEN"],
           let screen = ActiveScreen(rawValue: rawValue) {
            return screen
        }

        let arguments = processInfo.arguments
        guard arguments.contains("-milliScreenshotMode"),
              let flagIndex = arguments.firstIndex(of: "-milliScreen"),
              arguments.indices.contains(flagIndex + 1)
        else {
            return nil
        }

        return ActiveScreen(rawValue: arguments[flagIndex + 1])
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

    var primaryTab: MilliTab? {
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
            return nil
        }
    }

    var debugTab: MilliTab {
        primaryTab ?? .more
    }
}
