import SwiftUI

// MARK: - ContentView
// Native SwiftUI shell: screen router + persistent sculpted Milli navigation + contextual Milli AI companion.

struct ContentView: View {
    @Binding private var pendingNavigationRequest: NavigationHandoffRequest?
    var onLogout: () -> Void = {}

    @State private var selectedTab: MilliTab
    @State private var activeScreen: ActiveScreen

    init(
        pendingNavigationRequest: Binding<NavigationHandoffRequest?> = .constant(nil),
        onLogout: @escaping () -> Void = {}
    ) {
        _pendingNavigationRequest = pendingNavigationRequest
        self.onLogout = onLogout

        let debugScreen = Self.requestedDebugScreen()
        let initialScreen: ActiveScreen = pendingNavigationRequest.wrappedValue != nil
            ? .activity
            : (debugScreen ?? .home)

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
                    .padding(.trailing, 8)
                    .padding(.bottom, aiBottomClearance)
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
                    case .vault:
                        activeScreen = .vault
                    case .activity:
                        activeScreen = .activity
                    case .wealth:
                        activeScreen = .wealthOverview
                    case .cockpit:
                        activeScreen = .cockpit
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            routePendingNavigationRequestIfNeeded()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            routePendingNavigationRequestIfNeeded()
        }
    }

    private var shouldShowAIOrb: Bool {
        activeScreen != .milliAI
    }

    private var aiBottomClearance: CGFloat {
        switch activeScreen {
        case .expenses, .plans:
            return MilliSpacing.bottomNavHeight + 52
        default:
            return MilliSpacing.bottomNavHeight + 2
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch activeScreen {
        case .home:
            HomeView(navigate: navigateTo)
        case .vault:
            PayoutsView()
        case .activity:
            MileageView(onBack: { navigateTo(.home) })
        case .milliCents:
            MilliCentsView(onBack: { navigateTo(.home) })
        case .autopilot:
            AutopilotSettingsView(onBack: { navigateTo(.cockpit) })
        case .expenses:
            ExpensesView(onBack: { navigateTo(.cockpit) })
        case .accounts:
            AccountsView(onBack: { navigateTo(.cockpit) })
        case .savings:
            SavingsView(onBack: { navigateTo(.wealthOverview) })
        case .documents:
            DocumentsView(onBack: { navigateTo(.cockpit) })
        case .plans:
            SubscriptionView(onBack: { navigateTo(.cockpit) })
        case .taxVault:
            TaxVaultView(onBack: { navigateTo(.home) })
        case .taxReadyScore:
            TaxReadyScoreView(onBack: { navigateTo(.home) })
        case .quarterlyTaxes:
            QuarterlyTaxesView(onBack: { navigateTo(.home) })
        case .investing:
            InvestingView(onBack: { navigateTo(.wealthOverview) })
        case .retirement:
            RetirementView(onBack: { navigateTo(.wealthOverview) })
        case .wealthOverview:
            WealthOverviewView(
                onBack: { navigateTo(.home) },
                navigate: navigateTo
            )
        case .treeOfLife:
            TreeOfLifeView(onBack: { navigateTo(.wealthOverview) })
        case .milliAI:
            MilliAIView(
                onBack: { navigateTo(.home) },
                navigate: navigateTo
            )
        case .reports:
            ReportsView(onBack: { navigateTo(.cockpit) })
        case .cockpit:
            MoreMenuView(navigate: navigateTo, onLogout: onLogout)
        }
    }

    private func routePendingNavigationRequestIfNeeded() {
        guard pendingNavigationRequest != nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            activeScreen = .activity
            selectedTab = .activity
        }
    }

    private func navigateTo(_ screen: ActiveScreen) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeScreen = screen
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
    case vault
    case activity
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
    case cockpit

    var primaryTab: MilliTab? {
        switch self {
        case .home:
            return .home
        case .vault:
            return .vault
        case .activity:
            return .activity
        case .wealthOverview:
            return .wealth
        case .cockpit:
            return .cockpit
        default:
            return nil
        }
    }

    var debugTab: MilliTab {
        switch self {
        case .investing, .retirement, .savings, .treeOfLife:
            return .wealth
        default:
            return primaryTab ?? .cockpit
        }
    }
}
