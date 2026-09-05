import SwiftUI

// MARK: - ContentView
// Native SwiftUI shell: screen router + persistent sculpted Milli navigation + contextual Milli AI companion.

struct ContentView: View {
    @Binding private var pendingNavigationRequest: NavigationHandoffRequest?
    var onLogout: () -> Void = {}

    @StateObject private var milliPresence = MilliPresence()
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
                .environmentObject(milliPresence)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            if shouldShowAIOrb {
                HStack {
                    Spacer()
                    MilliAIOrb(presence: milliPresence) {
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
            .environmentObject(milliPresence)
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

            if milliPresence.state == .celebration {
                MilliCelebrationOverlay(presence: milliPresence)
                    .id(milliPresence.celebrationNonce)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(100)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: milliPresence.state)
        .onAppear {
            routePendingNavigationRequestIfNeeded()
        }
        .onChange(of: pendingNavigationRequest?.id) { _, _ in
            routePendingNavigationRequestIfNeeded()
        }
    }

    private var shouldShowAIOrb: Bool {
        activeScreen != .milliAI && milliPresence.state != .celebration
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
        milliPresence.setState(.navigating, message: "Navigation request received")
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

// MARK: - Signature celebration

private struct MilliCelebrationOverlay: View {
    @ObservedObject var presence: MilliPresence
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(animate ? 0.20 : 0)
                    .ignoresSafeArea()

                if !reduceMotion {
                    MilliConfettiCannon(origin: CGPoint(x: 0, y: 0), direction: .downRight, canvasSize: proxy.size, animate: animate)
                    MilliConfettiCannon(origin: CGPoint(x: proxy.size.width, y: 0), direction: .downLeft, canvasSize: proxy.size, animate: animate)
                }

                VStack(spacing: 18) {
                    Spacer()

                    MilliAICharacterView(
                        size: min(proxy.size.width * 0.36, 150),
                        animated: true,
                        presenceState: .celebration
                    )
                    .scaleEffect(animate ? 1 : 0.70)
                    .opacity(animate ? 1 : 0)

                    VStack(spacing: 6) {
                        Text(presence.celebrationTitle ?? "WAY TO GO!")
                            .font(.custom("Sora-Bold", size: 25, relativeTo: .title2))
                            .foregroundStyle(MilliColors.textPrimary)
                            .multilineTextAlignment(.center)

                        if let detail = presence.celebrationDetail {
                            Text(detail)
                                .font(MilliFont.bodyMedium)
                                .foregroundStyle(MilliColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(MilliColors.cardBackground.opacity(0.94))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(MilliColors.cyanGlow.opacity(0.44), lineWidth: 1)
                            }
                            .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 22)
                    )
                    .padding(.horizontal, 28)

                    Spacer()
                        .frame(height: max(proxy.safeAreaInsets.bottom + 118, 140))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if reduceMotion {
                animate = true
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                    animate = true
                }
            }
        }
    }
}

private struct MilliConfettiCannon: View {
    enum Direction { case downRight, downLeft }

    let origin: CGPoint
    let direction: Direction
    let canvasSize: CGSize
    let animate: Bool

    private let particles = Array(0..<26)

    var body: some View {
        ZStack {
            ForEach(particles, id: \.self) { index in
                let spread = Double(index % 9) - 4
                let distance = CGFloat(150 + (index % 7) * 22)
                let downward = CGFloat(120 + (index % 6) * 26)
                let sign: CGFloat = direction == .downRight ? 1 : -1

                Capsule(style: .continuous)
                    .fill(index.isMultiple(of: 3) ? MilliColors.cyanGlow : (index.isMultiple(of: 2) ? MilliColors.chromeWhite : MilliColors.silverBright))
                    .frame(width: CGFloat(4 + index % 4), height: CGFloat(8 + index % 5))
                    .rotationEffect(.degrees(animate ? Double(index * 73) : spread * 4))
                    .position(
                        x: origin.x + (animate ? sign * (distance + CGFloat(spread * 7)) : sign * 8),
                        y: origin.y + (animate ? downward : 8)
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.25).delay(Double(index % 5) * 0.025), value: animate)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
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
